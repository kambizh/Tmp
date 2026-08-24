# KBlock — High-Level Design

| | |
|---|---|
| **Status** | Living document — reflects state as of KB-101 Slice 1 |
| **Version** | 0.1 |
| **Last updated** | 2026-08-24 |
| **Owner** | Kambiz (founder) |
| **Audience** | You (as the acting solution architect, learning the discipline); eventually a design partner's platform/security team |

## How to use this document

This describes the system as a **compliance evidence pipeline**, not as a
list of Go packages. If you're looking for package internals, read the code
— it's commented for exactly that. This document exists to answer questions
the code cannot: what does the system promise, where are the trust
boundaries, what happens when a dependency fails, and what are we
deliberately *not* promising yet.

Every architectural *decision* referenced here is recorded in full in
`docs/adr/` — this document states the shape that resulted from those
decisions; the ADRs state why it's this shape and not another one.

---

## 1. Purpose and scope

### 1.1 What KBlock is

KBlock captures Kubernetes audit events and stores them in a way that makes
tampering *detectable*, so that audit evidence used for SOC 2, ISO 27001,
HIPAA, and PCI-DSS compliance can be independently verified rather than
taken on trust.

### 1.2 What this document covers

The **capture and storage pipeline** — the path from "something happens in
a Kubernetes cluster" to "a cryptographically verifiable record exists."
This is Epics E1–E2 (Event Ingestion, and the ledger write path) of the
13-epic backlog. It does not yet cover the compliance dashboard, the AI
layer, multi-tenancy, or the eventual SaaS platform (Phase 3–5 vision) —
those get their own HLD sections as they move from vision to backlog.

### 1.3 Non-goals (explicit, not just omissions)

- **Filtering which events to capture** — KB-103, a separate concern from
  ingestion.
- **Proving no event was ever dropped before capture** — see §6, Threat
  Model Summary. This is a fundamental limitation of the architecture, not
  a missing feature.
- **Multi-region / multi-cluster federation** — out of scope for the
  current phase; every cluster runs its own collector today.

---

## 2. System context

TODO(architecture-diagram): **C4 Level 1 (System Context) diagram.** Shows
KBlock as a single box, with these actors/systems around it:
- Kubernetes API server (pushes audit events in)
- Platform engineer / Priya persona (configures the webhook, deploys KBlock)
- Compliance officer / auditor (eventually queries evidence — Phase 3+, not
  yet built)
- immudb (the storage dependency KBlock talks to)
- Prometheus (scrapes KBlock's metrics)
Draw this once the collector actually talks to immudb (post KB-202) — right
now the "system" box is mostly the collector talking to nothing but a queue.

**In words, until the diagram exists:** a platform engineer configures their
cluster's API server to send audit events to KBlock's webhook. KBlock
normalizes and writes them to an immutable ledger. Nothing external reads
from KBlock yet — that's the dashboard/query layer, not yet built. KBlock is
currently a one-way sink, not a two-way system.

---

## 3. Goals and quality attributes

These are the properties the architecture is judged against. Where a goal
traces to a specific Jira acceptance criterion, it's noted — that traceability
is deliberate, so this document stays anchored to real commitments rather
than aspirational adjectives.

| Attribute | Requirement | Source |
|---|---|---|
| **Integrity** | A written record cannot be altered without the alteration being detectable | Core value prop; ADR-0001 |
| **Availability (webhook)** | p99 response < 500ms at 1,000 events/sec | KB-101 AC2 |
| **Resilience** | Malformed input rejected with 400, logged, **never crashes the process** | KB-101 AC3 |
| **Observability** | Prometheus metrics: received/sec, rejected, queue depth | KB-101 AC4 |
| **Portability** | Works identically on EKS, GKE, AKS, and self-managed clusters | ADR-0002 |
| **Auditability of the system itself** | Every non-trivial architecture decision is recorded (ADRs) | This effort |

**TODO(later):** once load-testing exists (see open question in §8), add
measured numbers here alongside the targets — a design partner will ask
"what have you actually measured," not just "what do you target."

---

## 4. Architecture overview

TODO(architecture-diagram): **C4 Level 2 (Container) diagram** — this is the
most important diagram in this document and should be built next, once
Slice 3/4 land and the shape below is fully real rather than partly stubbed.
It should show:
- `kblock-collector` (the Go binary, this repo) as one deployable unit
- its two exposed ports (webhook :8443, metrics :9090 — ADR-0005)
- the internal pipeline stages as sub-components within that one box:
  webhook handler → queue → writer goroutine → ledger client
- immudb as an external container (separate deployment, possibly separate
  Pod/StatefulSet)
- Prometheus as an external container scraping :9090

**In words, until the diagram exists — the request path:**

```
Kubernetes API server
        │  HTTPS POST /audit  (EventList batch)
        ▼
┌─────────────────────────────────────────────────────┐
│  kblock-collector                                    │
│                                                       │
│   webhook handler  →  queue  →  writer goroutine     │
│   (internal/webhook)  (internal/queue)  (internal/ledger) │
│                                                       │
│   :9090/metrics  ←──────── (Prometheus scrapes)       │
└─────────────────────────────────────────────────────┘
        │  Ledger.Append(event)
        ▼
     immudb
```

**Current implementation status of each stage** (kept current — update this
table as slices land, don't let it drift):

| Stage | Package | Status |
|---|---|---|
| HTTP receive, routing, graceful shutdown | `internal/webhook` | ✅ Slice 1 |
| Canonical event schema, EventList parsing | `internal/audit` | ⬜ Slice 2 |
| Malformed-input rejection, metrics | `internal/metrics` | ⬜ Slice 3 |
| TLS / mTLS | `internal/webhook` (tls.go) | ⬜ Slice 4 |
| In-memory queue | `internal/queue` | ⬜ Slice 4 (interface defined, ADR-0004) |
| Durable queue swap | `internal/queue` | ⬜ KB-102 |
| Ledger write to immudb | `internal/ledger` | ⬜ KB-201/202 |

---

## 5. Component responsibilities

A short paragraph per component — the "what is this thing's one job"
question every component should have a crisp answer to.

**Webhook handler (`internal/webhook`).** Terminates HTTP(S), enforces
timeouts and request size limits, and is the only component that speaks the
Kubernetes audit webhook protocol. Its job ends at "valid-looking bytes,
handed to the queue" — it does not itself understand the audit event schema.

**Canonical event schema (`internal/audit`, KB-104).** Defines KBlock's own
internal representation of an audit event, independent of the Kubernetes
`audit.k8s.io/v1` wire format. This indirection matters: it's what lets
KBlock later ingest audit events from Falco, Vault, or other sources (per
the integration vision) without every downstream component needing to know
about each source format. This is flagged in the backlog as the
hardest-to-change artifact for good reason — everything downstream depends
on its shape.

**Queue (`internal/queue`).** Decouples "received over HTTP" from "written
to the ledger," so a slow or momentarily unavailable ledger doesn't stall
the HTTP response and blow the p99 target. Interface-first per ADR-0004.

**Ledger (`internal/ledger`).** The only component that talks to immudb (or
whatever satisfies the `Ledger` interface). Owns retry/backoff behavior on
write failure — **TODO(design, KB-201/202):** that retry policy isn't
decided yet. Decide and document it before implementation, not during.

**Metrics (`internal/metrics`).** Exposes operational state — throughput,
rejection rate, queue depth — without being on the request path that those
metrics describe (ADR-0005).

---

## 6. Trust boundaries and security architecture summary

TODO(architecture-diagram): **Trust boundary diagram** — draw the cluster
boundary, the collector's Pod boundary, and the API-server-to-collector
network hop with its TLS/mTLS annotation once Slice 4 lands. This is the
diagram a security reviewer will actually study.

**In words, until the diagram exists:**

- The webhook endpoint is the system's only external-facing surface today.
  Post-Slice-4, it requires mTLS — the API server must present a client
  certificate the collector verifies (ADR-0006). Until Slice 4, this
  endpoint is plaintext HTTP and **must not** be pointed at a real cluster
  (ADR-0006 states this explicitly, and it's worth restating here because
  this is the document most likely to be read out of order).
- The metrics endpoint is a separate trust boundary from the webhook —
  intended to be reachable only by an in-cluster Prometheus, never
  externally (ADR-0005).
- **A full threat model is a separate, planned document** — see §9. This
  section is a summary, not a substitute for it.

### 6.1 The single most important limitation to state out loud

KBlock proves that **a record, once written, has not been altered or
deleted.** It does not — and structurally cannot, given this architecture —
prove that **every event that occurred was captured**. A compromised or
misconfigured collector, a `failurePolicy: Ignore` audit webhook
configuration silently dropping events during an outage, or an attacker with
control-plane access disabling the audit webhook entirely, all sit *before*
the point where KBlock's guarantees begin.

This is not a flaw to fix quietly — it's a boundary to state precisely,
because a sophisticated buyer's security team will find it themselves if
KBlock doesn't say it first, and finding it themselves costs more trust than
reading it plainly stated here.

---

## 7. Deployment topology

TODO(architecture-diagram): **Deployment diagram** — Kubernetes Deployment
for `kblock-collector`, Service objects for both ports, NetworkPolicy
boundaries (ADR-0005), and immudb's own deployment topology (single instance
today; HA replication is on the longer-term roadmap and explicitly not
designed yet). Build this alongside KB-701 (Helm chart), not before — it'll
be more accurate written against a real chart than speculated ahead of one.

**Known today:** single-replica collector per cluster, talking to a single
immudb instance. No HA story yet for either — **this is an open question,
not a decision**, tracked in §8.

---

## 8. Open questions and risks

Honest list — these are the things a solution architect should be able to
name without being asked, not just the things that have been solved.

- **Load verification (KB-101 AC2).** No load-test harness exists yet. The
  500ms p99 @ 1k events/sec target is a design target, not a measured
  result. Decide: dedicated Slice 5, or measure during KB-802a against a
  real partner cluster. Leaning toward the harness — see the reasoning
  already captured when Slice 1 shipped.
- **Ledger write failure policy.** If immudb is briefly unreachable, does
  the writer goroutine retry indefinitely, retry with a cap then
  dead-letter, or apply backpressure to the queue until it's full and then
  reject new events? This has real product consequences (silently dropping
  vs. visibly stalling the API server) and isn't decided. Needs its own ADR
  before KB-202 implementation, not after.
- **immudb HA.** Single instance today. What happens to write availability
  if that instance is down? Longer-term roadmap mentions "HA immudb
  replication" but there's no design yet.
- **Audit webhook `failurePolicy`.** Kubernetes lets the cluster operator
  choose whether a webhook failure blocks API requests or is silently
  ignored. KBlock's setup documentation needs to state the tradeoff
  explicitly rather than leaving it to the customer to discover — this is a
  customer-facing decision, not just an internal one.
- **Multi-source ingestion.** The integration vision (Falco, Kyverno,
  Vault, Cosign) implies `internal/audit`'s canonical schema needs to
  represent non-Kubernetes-native events eventually. KB-104's design review
  should at least consider this shape, even though only `audit.k8s.io/v1`
  is in scope now — retrofitting a schema to accommodate sources you didn't
  originally design for is expensive.

---

## 9. Related and planned documents

| Document | Status | Purpose |
|---|---|---|
| `docs/adr/` | ✅ started | Why each architectural decision was made, and what it costs |
| This HLD | ✅ v0.1 | System shape, boundaries, and open questions |
| **TSD** (Technical Specification Document) | ⬜ planned, next | Concrete contracts: event schema, webhook API, ledger/queue interfaces, config surface, metrics catalogue, error taxonomy |
| **Threat model** | ⬜ planned | Formal STRIDE-style (or similar) analysis; §6 here is a summary pointer to it, not a replacement |
| Compliance control mapping | ⬜ deferred until real auditor input exists | Maps SOC 2 / ISO 27001 / HIPAA / PCI-DSS controls to KBlock capabilities — a sales artifact as much as an architecture one |

**Deliberately not planned as separate documents:** a low-level design (the
code's comment density serves that purpose while the codebase is this size)
and a functional spec (the 52-story Jira backlog already is one — writing
it twice is copying, not designing).
