# 0005. Serve Prometheus metrics on a separate port from the webhook

**Status:** accepted
**Date:** 2026-02-10
**Deciders:** Kambiz (founder)

## Context

KB-101's acceptance criteria require Prometheus metrics (received/sec,
rejected, queue depth). The straightforward approach is registering a
`/metrics` handler on the same `http.Server` and port that serves `/audit` —
it's one fewer port to expose and configure, and it's how many small
services do it by default.

KBlock's webhook, however, sits in the Kubernetes API server's request path
(ADR-0002) — its availability characteristics and its exposure surface are
not those of an ordinary internal service.

## Decision

Run metrics on a **separate `http.Server` bound to its own port**
(`KBLOCK_METRICS_ADDR`, default `:9090`), distinct from the webhook port
(`KBLOCK_LISTEN_ADDR`, default `:8443`). This is implemented in
`internal/webhook/server.go`'s `Config` validation, which explicitly rejects
identical addresses for the two ports.

## Alternatives considered

**Single server, `/metrics` alongside `/audit`.** Rejected on two grounds:

- *Operational blast radius.* If the webhook path is saturated, slow, or
  wedged — the exact failure mode KB-101's p99 target exists to prevent —
  Prometheus should still be able to scrape metrics to diagnose *why*.
  Sharing a listener means one failure mode blinds the operator to its own
  cause at the moment visibility matters most.
- *Exposure surface.* The webhook port must be reachable by the Kubernetes
  API server and, in production, requires client certificate verification
  (mTLS — see ADR-0006). The metrics port should be reachable only by an
  in-cluster Prometheus. Putting both behind one listener means one
  `NetworkPolicy` and one TLS posture has to satisfy two different trust
  requirements — either the metrics port inherits mTLS it doesn't need,
  or the webhook port's exposure is loosened to accommodate metrics
  scraping. Separate ports allow separate, correctly-scoped
  `NetworkPolicy` objects.

## Consequences

**Good:**
- Metrics remain scrapeable during a webhook-path incident — the case where
  they matter most.
- Clean separation of trust boundaries: `deploy/helm` can apply
  different `NetworkPolicy` rules per port without any code change.
- Matches the Prometheus ecosystem convention (most exporters and services
  run metrics on a dedicated port) — familiar to any SRE evaluating the
  deployment.

**Bad / accepted risk:**
- Two ports to expose, configure, and document instead of one — slightly
  more surface area in the Helm chart and in customer-facing setup
  instructions.
- Two `http.Server` instances to manage lifecycle for (bind, shutdown) in
  `main.go`, rather than one. Handled by extending the same
  `signal.NotifyContext` + graceful shutdown pattern already established in
  Slice 1 to both servers.

## Related
- KB-101 Slice 3 (Prometheus metrics implementation — not yet built)
- `internal/config/config.go` (`Validate()` already rejects identical
  `ListenAddr`/`MetricsAddr`, anticipating this ADR)
- **TODO:** `deploy/helm` `NetworkPolicy` templates, once the Helm chart
  work (KB-701) begins — this ADR is the reason those two ports get
  different policies.
