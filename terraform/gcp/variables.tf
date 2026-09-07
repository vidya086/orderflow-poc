variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  type    = string
  default = "asia-south1"
}

variable "zone" {
  description = "Zonal cluster, deliberately - see the ROADMAP note on regional vs zonal clusters and node-count-per-zone quota."
  type        = string
  default     = "asia-south1-a"
}

variable "cluster_name" {
  type    = string
  default = "orderflow-gke"
}

variable "network_name" {
  type    = string
  default = "orderflow-vpc"
}

variable "subnet_cidr" {
  type    = string
  default = "10.10.0.0/20"
}

variable "pods_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "services_cidr" {
  type    = string
  default = "10.30.0.0/20"
}

variable "master_ipv4_cidr" {
  type    = string
  default = "172.16.0.0/28"
}

variable "master_authorized_cidr" {
  description = "Your IP, as x.x.x.x/32 - controls who can reach the GKE control plane API. Get yours with: curl -s ifconfig.me"
  type        = string
}

variable "node_count" {
  type    = number
  default = 2
}

variable "node_machine_type" {
  type    = string
  default = "e2-medium"
}

variable "node_disk_size_gb" {
  description = "Kept small and on pd-standard deliberately - personal-tier GCP projects have a low SSD_TOTAL_GB regional quota; pd-standard doesn't draw from it."
  type        = number
  default     = 30
}

variable "db_tier" {
  type    = string
  default = "db-f1-micro"
}

variable "order_db_password" {
  type      = string
  sensitive = true
  default   = "order_pass"
}

variable "inventory_db_password" {
  type      = string
  sensitive = true
  default   = "inventory_pass"
}
