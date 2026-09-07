# Learning Roadmap: Local -> GCP -> Azure

Each stage has one primary concept. Don't move to the next until you can explain *why* the stage's pieces exist, not just that the commands worked.

## Stage 0 — Run it locally (Docker Compose)
**Goal:** understand the app's service boundaries and messaging before any cloud is involved.
- `docker compose up`, watch the RabbitMQ management UI as orders flow through.
- Kill inventory-service mid-flight, see messages queue up, restart it, watch it drain. This is *why* async decoupling matters — internalize it before adding network latency and cloud failure modes on top.

## Stage 1 — GKE basics (no fancy networking yet)
**Goal:** get comfortable with core K8s objects and GCP's managed control plane.
- Create a GKE **Autopilot** cluster (`gcloud container clusters create-auto`) — Google manages nodes, you focus on workloads first.
- Build images, push to **Artifact Registry**.
- Apply `k8s/base/*` — Deployments, Services (ClusterIP), ConfigMaps, Secrets.
- Use `kubectl port-forward` to reach services before any Ingress exists.
- Learn: liveness/readiness probes (already wired to Spring Actuator `/actuator/health/{live,ready}`), resource requests/limits, `kubectl logs -f`, `kubectl exec`.

## Stage 2 — Real GCP networking
**Goal:** this is the core of what you're here for.
- Switch to **GKE Standard** with a **VPC-native cluster**: custom VPC, custom subnet, secondary IP ranges for Pods and Services (alias IPs — GCP's answer to "how do hundreds of pods get routable IPs without an SDN overlay").
- **Cloud NAT**: private nodes need it to pull images / reach the internet without public IPs.
- **Firewall rules**: default-deny, then explicit allow rules by tag/service account — least privilege instead of the wide-open default network.
- **Cloud SQL**: move Postgres out of the cluster. Compare two connection patterns:
  - Cloud SQL Auth Proxy as a sidecar container (mTLS, no VPC peering needed)
  - Private IP via VPC peering (lower latency, more networking to configure)
- **Ingress**: GKE's native Ingress backed by Cloud Load Balancing, with a Google-managed TLS cert. Apply `k8s/stage1-gke/ingress.yaml`. Learn the difference between an L4 LoadBalancer Service and an L7 Ingress.
- Stretch: **Cloud Armor** in front of the Ingress (WAF rules, rate limiting).

## Stage 3 — Infrastructure as Code
**Goal:** stop clicking, start declaring.
- `terraform/gcp/` has a skeleton: VPC + subnet + secondary ranges, GKE cluster, Artifact Registry, Cloud SQL. Fill in the TODOs.
- Remote state in a GCS bucket with locking.
- Run `terraform plan` against what you built by hand in Stage 2 and reconcile the drift — the single best exercise for understanding what each console click actually did.

## Stage 4 — CI/CD
**Goal:** builds and deploys stop being manual.
- GitHub Actions (or Cloud Build): on push -> build image -> push to Artifact Registry -> `kubectl apply` or `helm upgrade`.
- Stretch: move to GitOps with **ArgoCD** — the cluster pulls desired state from git instead of a pipeline pushing to it. Different trust model, worth understanding both.

## Stage 5 — Observability
- Prometheus + Grafana via Helm, or GKE **Managed Prometheus**. All services already expose `/actuator/prometheus`.
- OpenTelemetry tracing across the async boundary (HTTP -> RabbitMQ -> HTTP) piped to Cloud Trace — distributed tracing is far more interesting once a message queue breaks the request chain.
- Centralized logs in Cloud Logging, structured JSON logging from Spring Boot.
- This is also where Redis earns its place: add response caching to Inventory Service's read endpoint and watch latency/hit-rate in Grafana.

## Stage 6 — Service mesh / advanced networking
- Istio (or Anthos Service Mesh): mTLS between services, traffic splitting for canary releases of order-service, circuit breaking.
- Multi-cluster / multi-region if you want to go further.

## Stage 7 — Replicate on Azure (AKS)
**Goal:** map every GCP concept to its Azure equivalent and understand where the model actually differs, not just where the button labels differ.

| Concept | GCP | Azure |
|---|---|---|
| Cluster | GKE (Autopilot/Standard) | AKS |
| Cluster networking | VPC-native (alias IPs) | Azure CNI vs kubenet |
| Image registry | Artifact Registry | ACR |
| Managed Postgres | Cloud SQL | Azure Database for PostgreSQL Flexible Server |
| Private DB access | Private IP / peering / Auth Proxy | Private Endpoint / VNet integration |
| L7 ingress + LB | GKE Ingress + Cloud Load Balancing | AGIC (Application Gateway Ingress Controller) |
| Egress NAT | Cloud NAT | Azure NAT Gateway |
| Secrets | Secret Manager | Key Vault (+ CSI driver) |
| IaC | Terraform (`google` provider) | Terraform (`azurerm`) or Bicep |
| CI/CD | Cloud Build / GH Actions | Azure DevOps / GH Actions |

Do this stage by literally redoing Stage 2 and Stage 3 against `az` and the `azurerm` Terraform provider, side by side with your GCP notes. The differences — especially the CNI networking model and how Private DNS/Private Endpoints compare to GCP's Private Service Connect — are where the real "pro-level" understanding comes from.

## Stage 8 — Stretch goals
- HPA/VPA/Cluster Autoscaler, and load-test with k6 or Locust to actually trigger them.
- Cost comparison: same workload, GCP bill vs Azure bill.
- Disaster recovery drills: Cloud SQL / Azure DB point-in-time restore.
- External Secrets Operator pulling from Secret Manager/Key Vault instead of static K8s Secrets.
