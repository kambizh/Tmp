# 0001. Use immudb instead of a custom blockchain for the storage layer

**Status:** accepted
**Date:** 2025-10-28
**Deciders:** Kambiz (founder)

## Context

KBlock's core value proposition is transforming mutable Kubernetes audit logs
into cryptographically verifiable, tamper-evident evidence for compliance
frameworks (SOC 2, ISO 27001, HIPAA, PCI-DSS). That requires a storage layer
with three properties: **immutability** (once written, a record cannot be
altered without detection), **independent verifiability** (a customer or
their auditor can confirm integrity without trusting KBlock's word for it),
and **cryptographic proof of the entire history**, not just individual
records — an auditor needs to know nothing was *deleted*, not only that
nothing was *edited*.

The early framing of this problem — first-principles, before any storage
research — was "build a blockchain": a hash-linked chain of blocks, each
containing a batch of audit events, replicated across nodes for tamper
resistance. That's the instinctive answer when the requirement is phrased as
"tamper-proof," and it's the wrong one for a pre-revenue solo project with a
6-month validation window.

## Decision

Use **immudb** (https://github.com/codenotary/immudb) as the storage layer,
accessed through its Go SDK, rather than building a custom blockchain-style
ledger.

immudb is a purpose-built immutable database that already provides a
Merkle-tree-backed structure with cryptographic proofs of inclusion and
consistency, client-side verification (`immudb`'s SDK lets a caller verify a
record's proof without trusting the server), and standard database ergonomics
(SQL-like queries, ACID transactions) on top of that guarantee. In effect, it
is the tamper-evidence primitive KBlock needs, already built, tested, and
running in production elsewhere.

## Alternatives considered

**Custom blockchain (hash-linked blocks, custom consensus or none).**
Rejected. Building a correct, secure Merkle/hash-chain implementation is a
multi-month effort on its own — before touching Kubernetes integration,
storage, querying, or compliance reporting. As a solo founder validating
demand on a 6-month clock, that timeline is the whole runway. It also means
KBlock would be responsible for the correctness of its own cryptographic
primitives, which is precisely the kind of claim a security-conscious buyer
will want independently audited — and an unaudited home-grown scheme is a
harder sell than a widely-deployed open-source one.

**AWS QLDB.** Rejected — discontinued by AWS (end-of-life announced), and it
was cloud-native to a single provider, which conflicts with the multi-cloud
target (EKS/GKE/AKS). Notably, QLDB's discontinuation is itself part of
KBlock's market thesis: it left a gap for a portable, cloud-agnostic
equivalent.

**IBM Blockchain / Hyperledger Fabric.** Rejected. Enterprise-grade
distributed ledger platforms bring consensus protocols, peer/orderer
topologies, and channel management that are true blockchain overhead —
appropriate when multiple mutually-distrusting organizations need shared
write access to one ledger. KBlock's actual requirement is single-writer,
tamper-evident storage that a third party can *verify*, not a
multi-party consensus system. Reaching for Fabric would be solving a
harder problem than the one that exists, at a much higher operational cost
(a Fabric network is itself a significant piece of infrastructure to run and
secure).

**Plain PostgreSQL/S3 with application-level hashing.** Considered briefly,
not seriously pursued. It's possible to hand-roll hash chains over rows in a
normal database, but then KBlock is back to owning the cryptographic
correctness problem from the "custom blockchain" option, just implemented
less rigorously, with no independent verification story for the customer.

## Consequences

**Good:**
- Saves an estimated 3–6 months versus building and hardening a custom
  ledger, which for a part-time solo founder is close to the entire
  validation budget.
- immudb is open source (Apache 2.0) and has existing production usage,
  which is a more credible answer in a security review than "we built our
  own."
- SQL-like query surface means the eventual dashboard and NL-query features
  (Phase 3 vision) sit on familiar query patterns rather than a bespoke
  ledger API.
- Client-side verification is a genuine differentiator to say out loud to a
  buyer: "you don't have to trust our server, you can verify the proof
  yourself."

**Bad / accepted risk:**
- **Vendor/project dependency risk.** KBlock's core promise now depends on
  a third-party project's continued existence, license terms, and security
  posture. Mitigated by ADR-0003 (Apache 2.0 fork), but the mitigation is
  itself operational overhead (keeping a fork in sync).
- **Threat model gap this decision does NOT close:** immudb protects
  *records once written* from undetected tampering. It says nothing about
  whether every event that occurred was actually written — a compromised or
  malicious collector could simply not forward an event, and immudb would
  have no way to know. This must be treated as a first-class item in the
  threat model document, not an implementation detail.
- Adds a real (if well-scoped) dependency to the request path: KBlock's
  availability is now coupled to immudb's. KB-201/202 need to define
  failure behavior (queue and retry vs. reject) if immudb is briefly
  unreachable — see the interface-first decision in ADR-0004.

## Related
- ADR-0003 (fork immudb under Apache 2.0)
- ADR-0004 (interface-first ledger design)
- KB-201, KB-202 (ledger interface and immudb implementation)
- **TODO:** link the threat model document once written — the "collector
  can silently drop events" gap belongs there, not just here.
