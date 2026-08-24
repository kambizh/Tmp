# 0006. Defer TLS/mTLS to KB-101 Slice 4 rather than Slice 1

**Status:** accepted
**Date:** 2026-02-10
**Deciders:** Kambiz (founder)

## Context

KB-101's acceptance criteria explicitly require an HTTPS endpoint with mTLS
support — this is not optional for the finished story. The question this
ADR addresses is purely sequencing: KB-101 was broken into four vertical
slices (see the project's slice plan) to keep each slice small enough to
learn from and to leave a clean stopping point if interrupted. TLS and mTLS
touch certificate loading, `tls.Config` construction, client certificate
verification, and testing against both — a meaningfully separate concern
from getting the server's HTTP lifecycle (routing, timeouts, graceful
shutdown) correct first.

The risk in deferring it is obvious and worth naming directly: it would be
easy to let "Slice 4" quietly become "later," and ship something that never
actually satisfies the acceptance criteria.

## Decision

Slice 1 runs **plaintext HTTP**, explicitly logged as such
(`"tls", false` in the startup log line in `internal/webhook/server.go`).
TLS with certificate loading lands in Slice 2/3 groundwork as needed, and
full mTLS with client certificate verification is Slice 4, completing KB-101
against its actual acceptance criteria. KB-101 is **not considered done**
until Slice 4 ships — Slice 1 is progress toward it, not a substitute for
it.

## Alternatives considered

**Build TLS into Slice 1 from the start.** Rejected for sequencing reasons
only, not because it's wrong to want. Mixing certificate handling into the
first slice — while also learning Go's package system, `net/http`, and
goroutines/channels for the first time — was judged likely to produce a
slice that does two things adequately rather than one thing solidly. The
server lifecycle (timeouts, graceful shutdown, routing) is the foundation
everything else sits on; getting that right first, with tests, was
prioritized over sequencing completeness.

**Skip mTLS, ship TLS-only as "good enough."** Rejected outright — not
seriously considered as a real alternative, but worth recording because
it's a plausible shortcut under time pressure. mTLS is an explicit KB-101
acceptance criterion, not a nice-to-have, and it exists precisely because
this is a *compliance* product: an unauthenticated or server-auth-only
webhook endpoint accepting audit events is itself a finding in a security
review, quite apart from what the endpoint's own purpose is.

## Consequences

**Good:**
- Slice 1 stayed focused and reviewable: server lifecycle, config, graceful
  shutdown, all covered by tests, in one sitting.
- The plaintext state is loud, not silent — logged explicitly at startup —
  so it cannot be mistaken for a finished, production-ready state by
  accident.

**Bad / accepted risk:**
- **KB-101 is not actually done** by any definition that matters to a
  customer until Slice 4 ships. If Slice 4 slips, KBlock has a webhook
  receiver that cannot be safely pointed at a real cluster. This must stay
  visible in the Jira board and in this repo's README, not just in this
  ADR — **TODO:** confirm the README's "Roadmap within KB-101" table
  (already present) keeps Slice 4 marked incomplete until it genuinely
  ships, and don't let Slice 1–3 completion read as "KB-101 done."
- Anyone testing against a real Kubernetes cluster before Slice 4 will find
  the API server refuses to call an insecure webhook backend under most
  cluster audit-webhook configurations — expected, not a bug, but worth
  stating so it isn't mistaken for one.

## Related
- KB-101 (parent story; this ADR only concerns internal slice ordering)
- ADR-0002 (webhook architecture — the reason TLS/mTLS is required at all)
- `internal/webhook/server.go` startup log (`"tls", false`) — the explicit,
  loud signal referenced above
- **TODO:** once Slice 4 ships, update this ADR's status note (not the
  content — ADRs are immutable — but add a follow-up ADR or a dated note in
  the index) confirming KB-101 is genuinely complete against all five
  acceptance criteria, including the load-test question tracked separately.
