# 0003. Maintain an Apache 2.0 fork of immudb

**Status:** accepted
**Date:** 2025-10-28
**Deciders:** Kambiz (founder)

## Context

ADR-0001 commits KBlock's core storage layer to immudb, a third-party open
source project maintained by Codenotary. Open source license terms are not
permanent — the industry has repeated examples of projects relicensing away
from permissive terms once a project becomes commercially significant
(Elastic's move away from Apache 2.0, MongoDB's SSPL, HashiCorp's BSL are the
most-cited cases). immudb is currently Apache 2.0, but KBlock is now betting
its core value proposition on a dependency it does not control.

This is a real risk specifically *because* ADR-0001 was the right call —
avoiding it would mean not using immudb at all, which reopens the "build a
custom blockchain" problem this decision was trying to avoid.

## Decision

Fork immudb into `github.com/kblock-io/immudb` at the current Apache 2.0
license snapshot, tag the fork to mark that snapshot
(`kblock-apache2-backup-YYYY-MM-DD`), and document the fork's purpose. Use
the **official upstream immudb by default**; treat the fork as a **backup
plan**, not the primary dependency, unless and until a relicensing event
forces a switch.

```go
// go.mod — default
require github.com/codenotary/immudb v1.9.5

// go.mod — only if upstream relicenses or is abandoned
require github.com/kblock-io/immudb v1.9.5-kblock
```

## Alternatives considered

**Do nothing; accept upstream license risk.** Rejected. The cost of forking
now (an afternoon: fork, tag, document) is negligible compared to the cost of
discovering a relicensing event after KBlock has paying customers depending
on the storage layer, at which point switching becomes a scramble under
customer pressure rather than a calm one-line `go.mod` change.

**Vendor immudb's source directly into the KBlock repo instead of a
separate fork.** Rejected. A separate fork can be kept in sync with upstream
via normal git remote tooling and clearly signals "this is a pinned copy of
someone else's project," whereas vendored source blurs into "this is
KBlock's code" over time and complicates attributing/contributing changes
back upstream.

**Switch to a different storage backend now to avoid the dependency
entirely.** Rejected — see ADR-0001. There is no other backend that provides
the same tamper-evidence primitives without KBlock owning the cryptographic
correctness burden itself.

## Consequences

**Good:**
- Business continuity: if Codenotary relicenses immudb or the project goes
  unmaintained, KBlock has a guaranteed-available Apache 2.0 codebase to
  build from, with zero scramble.
- A credible answer to a customer's or investor's diligence question ("what
  happens if immudb changes its license?") that exists *before* the
  question is asked.
- Contributing improvements back upstream (the stated default posture) is
  good-faith community behavior and plausibly useful for the eventual
  Codenotary partnership conversation on the roadmap.

**Bad / accepted risk:**
- **Ongoing maintenance cost.** A fork that silently drifts from upstream is
  worse than no fork — it becomes an unpatched, unaudited dependency that
  nobody is tracking. This decision creates a recurring task ("sync fork
  with upstream") that needs an actual cadence, not just a one-time
  action. **TODO:** define that cadence explicitly (e.g. "check upstream
  monthly, or immediately on any immudb CVE") once there's time to commit to
  process, and put it in the maintenance runbook — not before, because an
  unenforced policy is worse than an honestly-absent one.
- The fork itself does not protect against a *security* vulnerability
  discovered in the currently-forked version — only against a *license*
  change. Those are different risks and this ADR addresses only the second
  one.

## Related
- ADR-0001 (immudb as the storage layer — this ADR exists because of that
  decision)
- **TODO:** once the fork-sync cadence is defined, link the runbook here.
