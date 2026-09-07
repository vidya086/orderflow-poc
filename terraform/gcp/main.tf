terraform {
  required_version = ">= 1.6"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Do this AFTER your first successful `terraform apply` with local state:
  # 1. gsutil mb -l <region> gs://<your-unique-bucket-name>
  # 2. gsutil versioning set on gs://<your-unique-bucket-name>   (state history + safety net)
  # 3. Uncomment below, fill in the bucket name, then: terraform init -migrate-state
  # backend "gcs" {
  #   bucket = "TODO-your-tfstate-bucket"
  #   prefix = "orderflow/gcp"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ---------------------------------------------------------------------------
# Networking - mirrors exactly what you built by hand in Stage 2
# ---------------------------------------------------------------------------

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.network_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }
}

resource "google_compute_router" "router" {
  name    = "${var.network_name}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.network_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Deny-by-default is the VPC's actual default (custom-mode VPCs have no
# implicit allow-ingress rule) - these three are the explicit allows that
# replace what the "default" auto VPC would have hidden from you.
resource "google_compute_firewall" "allow_internal" {
  name      = "${var.network_name}-allow-internal"
  network   = google_compute_network.vpc.id
  direction = "INGRESS"

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr, var.pods_cidr, var.services_cidr]
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name      = "${var.network_name}-allow-iap-ssh"
  network   = google_compute_network.vpc.id
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # Google's fixed IAP TCP forwarding range
}

resource "google_compute_firewall" "allow_gclb_health_checks" {
  name      = "${var.network_name}-allow-gclb-health-checks"
  network   = google_compute_network.vpc.id
  direction = "INGRESS"

  allow {
    protocol = "tcp"
  }

  # Google's fixed, documented health-check source ranges - same for every project
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
}

# ---------------------------------------------------------------------------
# Private services access for Cloud SQL (the VPC peering you built by hand)
# ---------------------------------------------------------------------------

resource "google_compute_global_address" "private_service_range" {
  name          = "google-managed-services-${var.network_name}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_range.name]
}

# ---------------------------------------------------------------------------
# GKE - zonal (not regional!) deliberately. A regional cluster replicates
# num_nodes PER ZONE, which is what blew through the SSD_TOTAL_GB quota
# the first time this was built by hand. Zonal = predictable node count.
# ---------------------------------------------------------------------------

resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.master_authorized_cidr
      display_name = "admin"
    }
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  remove_default_node_pool = true
  initial_node_count       = 1

  depends_on = [google_compute_router_nat.nat]
}

resource "google_container_node_pool" "primary_nodes" {
  name     = "${var.cluster_name}-pool"
  location = var.zone
  cluster  = google_container_cluster.primary.name

  node_count = var.node_count

  node_config {
    machine_type = var.node_machine_type
    disk_size_gb = var.node_disk_size_gb
    disk_type    = "pd-standard"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }
}

# ---------------------------------------------------------------------------
# Artifact Registry
# ---------------------------------------------------------------------------

resource "google_artifact_registry_repository" "orderflow" {
  location      = var.region
  repository_id = "orderflow"
  format        = "DOCKER"
}

# ---------------------------------------------------------------------------
# Cloud SQL - private IP only, same edition/tier combo you had to discover
# by hand (Enterprise Plus is now the API default and doesn't support
# db-f1-micro; Enterprise edition still does).
# ---------------------------------------------------------------------------

resource "google_sql_database_instance" "postgres" {
  name             = "orderflow-postgres"
  database_version = "POSTGRES_16"
  region           = var.region

  settings {
    tier    = var.db_tier
    edition = "ENTERPRISE"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }
  }

  deletion_protection = false # convenience for a learning project - flip to true once this matters

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_database" "orderdb" {
  name     = "orderdb"
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_database" "inventorydb" {
  name     = "inventorydb"
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "order_user" {
  name     = "order_user"
  instance = google_sql_database_instance.postgres.name
  password = var.order_db_password
}

resource "google_sql_user" "inventory_user" {
  name     = "inventory_user"
  instance = google_sql_database_instance.postgres.name
  password = var.inventory_db_password
}
