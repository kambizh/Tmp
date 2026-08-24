# Architecture Decision Records

An ADR is a short, dated record of one architectural decision: the situation
that forced a choice, the options that were on the table, which one was
picked, and what that choice costs later. It is not a design document — it's
a record of *why the design isn't something else*.

## Why ADRs, and why they come before the HLD

The HLD tells a reader what the system is. It cannot easily tell them why it
isn't the three other things it could have been — that context lives in a
moment of decision, not in a description of the end state. Six months from
now, "why didn't we just use S3 with object lock?" is a question you will
get from a design partner's security team, and the honest answer needs to
already exist in writing, dated to before you knew how the decision played
out.

They're also the fastest way to practice architectural thinking, because the
format forces the same four moves every time: name the forces in tension,
list what you rejected, commit, state the cost. Do that a dozen times and it
stops being a template you fill in and starts being how you think.

## Format

Each ADR is a single markdown file, numbered sequentially, named
`NNNN-short-title.md`. Once merged, an ADR is **immutable** — if a decision
changes, write a new ADR that supersedes the old one and mark the old one's
status accordingly. Never edit history in place; the fact that you believed
something different in October 2025 is itself useful information.

```markdown
# NNNN. Title (a decision, not a topic — "Use immudb", not "Storage layer")

**Status:** proposed | accepted | superseded by NNNN | deprecated
**Date:** YYYY-MM-DD
**Deciders:** who was in the room

## Context
What situation forced this decision? What constraints were non-negotiable
(cost, timeline, your own skill level, a customer requirement)? Write this
as if the reader knows nothing about how it turned out.

## Decision
The one sentence a busy person needs. Then the reasoning.

## Alternatives considered
Every option that was seriously on the table, and the specific reason each
one lost. "We considered X" with no reason is not an ADR, it's a list.

## Consequences
**Good:**
**Bad / accepted risk:**
What does this decision make harder later? Naming that up front is the
entire point of the exercise.

## Related
Links to other ADRs, Jira epics, or code this decision touches.
```

## Index

| # | Title | Status | Date |
|---|---|---|---|
| [0001](0001-immudb-over-custom-blockchain.md) | Use immudb instead of a custom blockchain for the storage layer | accepted | 2025-10-28 |
| [0002](0002-webhook-over-file-tailing.md) | Webhook receiver instead of node-level file tailing | accepted | 2026-01-15 |
| [0003](0003-fork-immudb-apache2.md) | Maintain an Apache 2.0 fork of immudb | accepted | 2025-10-28 |
| [0004](0004-interface-first-ledger-and-queue.md) | Interface-first design for the ledger and queue packages | accepted | 2026-02-01 |
| [0005](0005-separate-metrics-port.md) | Serve Prometheus metrics on a separate port from the webhook | accepted | 2026-02-10 |
| [0006](0006-defer-tls-to-slice-4.md) | Defer TLS/mTLS to KB-101 Slice 4 rather than Slice 1 | accepted | 2026-02-10 |

**TODO (later):** as KB-102 (queue swap), KB-201/202 (ledger), and KB-104
(canonical schema) land, add ADRs for: the specific queue backend chosen for
KB-102, the immudb write pattern (per-event vs batched transactions), and the
canonical event schema's stability guarantees. Write each one *before* the
implementation, not after — that's what makes the founder design review on
KB-104 meaningful rather than a formality.
