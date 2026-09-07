# OrderFlow — Enterprise Hosting POC

A deliberately small but "real" order-processing system, built as a **learning vehicle for enterprise-grade cloud hosting and networking** on GCP first, then Azure — not a production product.

## What it is

```
UI (React) -> API Gateway (Spring Cloud Gateway) -> Order Service (Spring Boot + Postgres)
                                                   -> Inventory Service (Spring Boot + Postgres)
Order Service --publishes--> RabbitMQ --> Inventory Service (decrements stock)
                                       --> Notification Service (simulates email)
```

- **UI**: React SPA, talks only to the API Gateway.
- **API Gateway**: Spring Cloud Gateway — single ingress point, routes `/api/orders/**` and `/api/inventory/**`.
- **Order Service**: owns its own Postgres schema, publishes `order.created` events.
- **Inventory Service**: owns its own Postgres schema, consumes `order.created`, decrements stock.
- **Notification Service**: stateless consumer, simulates sending a confirmation email.
- **RabbitMQ**: async decoupling between services — the thing that makes this more than a CRUD demo, and what makes distributed tracing/observability in later stages actually interesting.
- **Redis**: wired in but unused until the caching exercise in Stage 5 of the roadmap.

This intentionally does **not** use Eureka/Config Server. In Kubernetes, service discovery and config are platform concerns (K8s DNS, ConfigMaps/Secrets) — learning that distinction instead of bolting on a Netflix-OSS stack is part of the point.

## How to use this repo

Read `docs/ROADMAP.md` first — it's the actual curriculum. Everything is staged so each step teaches one concrete cloud/networking concept before you add the next layer of complexity. Don't jump to Kubernetes on day one; run Stage 0 locally so you understand what the app *is* before you fight a cluster over it.

## Quick start (Stage 0 — local)

```bash
docker compose up --build
# UI:               http://localhost:5173
# API Gateway:       http://localhost:8080
# RabbitMQ mgmt UI:  http://localhost:15672 (guest/guest)
```

## Repo layout

```
services/           Spring Boot services (order, inventory, notification, gateway)
ui/                 React frontend
db-init/            Postgres init script (per-service DB + user)
docker-compose.yml  Stage 0: local, no cloud involved
k8s/base/           Stage 1+: plain Kubernetes manifests (cloud-agnostic)
k8s/stage1-gke/     GKE-specific bits (Ingress annotations, etc.) — Azure equivalents come in Stage 7
terraform/gcp/      Stage 3: IaC for the GCP networking + GKE + Cloud SQL layer
docs/               Roadmap + architecture notes
```

Requires locally: Java 21, Maven, Docker/Docker Compose, then later `gcloud`, `kubectl`, `terraform`, `az`.

**Note:** this was scaffolded in a sandboxed environment without access to Maven Central, so the Java wasn't compiled here — treat it as a correct, complete skeleton and run `mvn clean package` yourself as the first step before touching Docker or Kubernetes.
