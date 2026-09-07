# Architecture notes

## Why this app shape, specifically

A single Spring Boot CRUD app teaches you almost nothing about networking - it's
one process, one IP, done. OrderFlow has just enough moving parts to force
real decisions:

- **Multiple independently-deployable services** -> Service-to-service
  networking, DNS, load balancing across replicas.
- **A message broker** -> async decoupling, and a genuine reason to care
  about distributed tracing later (a synchronous call chain is boring to
  trace; a queue-mediated one is not).
- **Per-service databases** -> the private-connectivity problem (nobody
  should expose Cloud SQL/Azure DB on a public IP), and a reason to learn
  Private Service Connect / Private Endpoints properly instead of skimming
  past them.
- **A single ingress point (API Gateway + Ingress)** -> edge networking:
  TLS termination, WAF, path-based routing - the layer most "cloud
  networking" job interviews actually probe.

## What's deliberately left out (for now)

- **No service mesh yet** - mTLS and traffic splitting are Stage 6. Adding
  Istio on day one means you learn Istio's opinions instead of Kubernetes'.
- **No Eureka/Config Server** - in Kubernetes, the platform *is* your
  service registry (K8s DNS + Services) and config layer (ConfigMaps/Secrets).
  Bolting on a Netflix-OSS stack on top would teach you to fight the
  platform instead of use it.
- **No multi-region** - get comfortable within one region/VPC before
  reasoning about cross-region latency and data residency.

## Request flow, end to end

1. Browser -> Ingress (GCE HTTP(S) LB / AGIC) -> `ui` Service -> nginx serves
   the React bundle, or proxies `/api/*` onward.
2. `/api/*` -> `api-gateway` Service -> Spring Cloud Gateway routes by path
   to `order-service` or `inventory-service`.
3. `order-service` writes to its Postgres schema, then publishes
   `order.created` to the `order.events` topic exchange in RabbitMQ.
4. `inventory-service` and `notification-service` each own a queue bound to
   that exchange - they consume independently, at their own pace, and
   neither knows the other exists.

## Failure-mode exercises worth doing on purpose

- Scale `order-service` to 0 replicas while the UI is open - watch the
  Ingress/Gateway health checks route around it.
- Kill `rabbitmq` - orders still get created (order-service's DB write
  succeeds), but inventory/notifications stop updating until it's back.
  This is exactly the kind of partial-failure behavior synchronous-only
  architectures don't expose you to.
- Apply a restrictive `NetworkPolicy` (Stage 2/6 exercise, not yet in this
  repo) blocking `ui` from talking directly to `order-service`, forcing all
  traffic through `api-gateway` - a good hands-on lesson in defense in depth.
