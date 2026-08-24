# 0002. Webhook receiver instead of node-level file tailing

**Status:** accepted
**Date:** 2026-01-15
**Deciders:** Kambiz (founder)

## Context

The earliest prototype (the Python-based Day 1 proof of concept) captured
Kubernetes audit events by tailing the audit log file that the API server
writes to disk on the control-plane node — the standard approach for
self-managed clusters running `kube-apiserver` with `--audit-log-path` set.
It's simple, well-understood, and got a working demo running fast.

The problem surfaces the moment the target customer runs a managed
Kubernetes service — EKS, GKE, or AKS — which is the deployment target
stated explicitly in KBlock's go-to-market (Phase 1 ecosystem targets). On
managed control planes, the cloud provider **runs the API server for you**
and does not expose the control-plane node's filesystem. There is no node to
tail a file on. File-tailing isn't a worse option for this market — it's not
an option at all.

## Decision

Implement audit capture as an **HTTPS webhook receiver** that the
Kubernetes API server's built-in audit webhook backend
(`--audit-webhook-config-file`) POSTs `audit.k8s.io/v1` `EventList` batches
to, rather than tailing a log file.

This is KB-101, and it's the architecture the current codebase implements.

## Alternatives considered

**Continue file-tailing, restrict to self-managed clusters (kubeadm, k3s,
bare metal).** Rejected as the primary architecture. It would work, but it
excludes EKS/GKE/AKS by construction — the exact environments the business
plan targets first. File-tailing could still return later as an *additional*
ingestion path for self-managed clusters (this is explicitly out of scope
for KB-101 and tracked separately as KB-105, "managed-K8s ingestion" /
alternate ingestion paths), but it cannot be the only path.

**Sidecar or DaemonSet reading the audit log via a shared volume.** Same
fundamental blocker as file-tailing on managed clusters: there's no
node-level access to the control plane's audit log when the provider runs
it. A DaemonSet on the *worker* nodes has no visibility into control-plane
audit events at all — it would need the provider to expose the log some
other way, which is precisely what the webhook backend already does in a
standard, documented, provider-agnostic way.

**Cloud-provider-specific audit log export (e.g. AWS CloudTrail/EKS control
plane logs to CloudWatch, GKE Cloud Audit Logs).** Rejected as the sole
mechanism, though worth revisiting as a Phase 2+ "cloud provider adapter"
(already on the longer-term roadmap). Each provider has a different export
format, different latency characteristics, and different auth model — three
integrations to build and maintain instead of one, and the built-in
Kubernetes audit webhook mechanism already provides a single standard
interface that works identically across all three clouds and self-managed
clusters alike.

## Consequences

**Good:**
- One ingestion mechanism works identically across EKS, GKE, AKS, and
  self-managed clusters — the API server's audit webhook backend is a
  standard Kubernetes feature, not a provider extension.
- No dependency on node-level filesystem access, which also means no
  DaemonSet with elevated node permissions — a smaller footprint to justify
  in a customer's security review.
- Matches how the Kubernetes project itself expects audit backends to be
  built; this is a supported, documented extension point rather than a
  workaround.

**Bad / accepted risk:**
- **The webhook sits in the API server's critical path.** If `kblock-collector`
  responds slowly, it can stall the API server's own request handling —
  this is precisely why KB-101's acceptance criteria include the p99 <
  500ms target and why the HTTP server was built with explicit timeouts
  from Slice 1 rather than added later.
- **Availability requirement is stricter than file-tailing.** A file-tailer
  can fall behind and catch up; depending on the API server's audit webhook
  failure policy (`failurePolicy: Ignore` vs `Block`), a webhook outage can
  mean either silently missed events or a degraded API server. The
  `failurePolicy` choice and its tradeoffs need to be documented explicitly
  for customers deploying this — **TODO:** cover this in the HLD's failure
  modes section and in customer-facing setup docs.
- Requires TLS (and eventually mTLS) from day one for any real deployment,
  since the API server will refuse to call an insecure webhook backend in
  most cluster configurations. Slice 1 deferred this (see ADR-0006) but it
  is not optional for production.

## Related
- KB-101 (this decision is the architecture KB-101 implements)
- KB-105 (managed-K8s ingestion nuances — explicitly out of scope for
  KB-101, tracked separately)
- ADR-0006 (why TLS was deferred to Slice 4, not skipped)
- **TODO:** ADR for the eventual cloud-provider adapter approach, once
  Phase 2+ work on GKE/EKS/AKS-specific integrations begins.
