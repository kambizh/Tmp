# 0004. Interface-first design for the ledger and queue packages

**Status:** accepted
**Date:** 2026-02-01
**Deciders:** Kambiz (founder)

## Context

Two components in the collector's data path are expected to change
implementation before the architecture stabilizes:

- **The queue** that buffers received events between the HTTP handler and
  the ledger writer. KB-101 (Slice 1–3) needs only a simple in-memory
  channel-based queue to prove the pipeline. KB-102 is explicitly scoped as
  a queue *swap* — almost certainly to something disk-backed or otherwise
  durable, so that events survive a collector restart rather than living
  only in process memory.
- **The ledger** that persists events durably. ADR-0001 commits to immudb,
  but ADR-0003 already establishes that the specific backend could change
  (fork or otherwise), and independently, the write pattern itself (one
  write per event vs. batched transactions) is not yet decided and will be
  tuned against the p99 < 500ms target once real load data exists.

Writing the webhook handler and writer goroutine directly against a
concrete queue type or a concrete immudb client would mean every consumer of
those types needs to change when KB-102 lands or the ledger write pattern is
tuned — and it would make both packages effectively untestable without a
running immudb instance or a real channel wired end-to-end.

## Decision

Define `Queue` and `Ledger` as **Go interfaces** in `internal/queue` and
`internal/ledger` respectively, before their concrete implementations are
built out. KB-101 ships a minimal in-memory channel-based `Queue`
implementation behind the interface. The `Ledger` interface is stubbed in
KB-101 with no real implementation yet — KB-201/202 fill it in against
immudb. All other code (the webhook handler, the writer goroutine, `main.go`
wiring) depends on the interface type, never on the concrete
implementation's package.

```go
// internal/queue/queue.go — the shape other packages depend on
type Queue interface {
    Enqueue(ctx context.Context, event []byte) error
    Dequeue(ctx context.Context) ([]byte, error)
}

// internal/ledger/ledger.go — stubbed now, implemented in KB-201/202
type Ledger interface {
    Append(ctx context.Context, event Event) error
}
```

## Alternatives considered

**Build directly against the concrete in-memory queue and defer an
interface until KB-102 actually needs one ("YAGNI").** Rejected for this
specific pair of components. YAGNI is usually the right default in Go — the
language's convention is "accept interfaces, return structs," introduced at
the point of actual need, not speculatively. The queue and ledger are an
exception because the *need* is not speculative: it's already a named,
scheduled story (KB-102) with a known reason (durability), not a guess about
possible future requirements. Interface-first here is responding to a
decision already made, not predicting one.

**Design a single interface covering both queueing and persistence.**
Rejected. Queueing (transient, in-process, backpressure-oriented) and
ledger writes (durable, cryptographically verified, potentially slower) are
different concerns with different failure semantics — a full queue should
apply backpressure or reject; a ledger write failure should retry or
dead-letter. Merging them into one interface would force one failure
handling policy onto two problems that need different ones.

## Consequences

**Good:**
- KB-102 becomes a localized change: implement a new type satisfying
  `Queue`, swap it in `main.go`'s wiring, done. No changes to the HTTP
  handler.
- KB-201/202 can proceed in parallel with — or after — other work without
  blocking on the webhook handler being "finished," since the handler
  already only depends on the `Ledger` interface.
- Both the webhook handler and writer goroutine become trivially testable
  with in-memory fakes satisfying the interfaces, with no immudb instance or
  real concurrency required in unit tests.

**Bad / accepted risk:**
- Designing an interface before its second implementation exists carries
  real risk of guessing the wrong shape — Go's own standard library guidance
  is that interfaces are best discovered from real usage, not designed
  upfront in the abstract. This is accepted here specifically because KB-102
  and KB-201/202 are known, scheduled, near-term work, not speculative
  future needs — the interface has two real implementations in view, not
  zero.
- A small amount of indirection cost (interface dispatch, slightly more
  ceremony in `main.go` wiring) for what is, in KB-101 Slice 1–3, a single
  concrete implementation. Judged worth it given how soon the second
  implementation lands.

## Related
- KB-101 (Slice 1: channel-based `Queue`; `Ledger` stubbed, unimplemented)
- KB-102 (queue swap — the reason `Queue` is an interface)
- KB-201, KB-202 (ledger interface and immudb implementation)
- ADR-0001, ADR-0003 (why the ledger's concrete backend is itself not fixed)
- **TODO:** once KB-102 lands, add an ADR recording which queue backend was
  chosen (e.g. disk-backed WAL, embedded key-value store, or similar) and
  why — that choice doesn't exist yet.
