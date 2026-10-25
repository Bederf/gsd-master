# Milestones — GSD Master / Mission Controller

Declares project milestones. The closure of M1 is the point at which GSD Master is considered
**architecturally complete** (not feature-complete): its boundaries are clear, its interfaces are
specified, and the work above it is identified.

Related: `ADR-000-why-v3.4-not-released.md`, `ARCHITECTURAL-INVARIANTS.md`,
`../docs/execution-contract-specification-v1.0.md`.

---

## M1 — Stable Execution Engine ✅ COMPLETE (2026-07-08)

GSD Master is frozen as the Stable Reference Implementation (v3.3.0).

Definition of done:

- [x] **Stable architecture** — Execution Engine / Mission Controller / Runtime boundaries defined.
- [x] **Stable interfaces** — Execution Contract specified (v1.0 draft).
- [x] **ADRs exist** — ADR-000 records the v3.4 non-release decision.
- [x] **Execution Contract defined** — language-neutral spec, sourced from v3.3 §8.4 / §9.6.
- [x] **Public release frozen** — GitHub `main` stays at v3.3.0; local v3.4 kept only as experimental branch.
- [x] **Runtime separated** — calibration / agent-config / instruction-file concerns identified as Runtime, excluded from the engine (Invariant 07).
- [x] **Mission layer identified** — the layer above GSD Master is named and scoped.

Outcome: GSD Master has reached its **1.0 architecture**. It is a mature execution engine; the
interesting engineering work now shifts above it.

---

## M2 — Mission Controller 🔜 NEXT

Build the layer above GSD Master.

Scope (MVP):

- Accept a goal.
- Select GSD Master as the execution engine.
- Run one phase.
- Receive an Execution Contract (per the v1.0 spec).
- Decide whether to continue or stop.

Purpose: validate that the Mission Controller ↔ GSD Master boundary works as designed — the
highest-risk assumption in the architecture. This is the validation step that determines what
(real) content v3.4 should eventually contain.

Prerequisite bindings (derived from the spec, not before it):

1. `execution_contract.schema.json` — JSON Schema
2. Python dataclass
3. Pydantic model (if a validator is needed)
4. TypeScript interface

---

## ADR Numbering Convention

ADR numbers may be reserved by accepted planning documents before the ADR file itself exists —
this file's own Tracked Gaps entry below reserves `ADR-001` for the Execution Contract
Specification's eventual promotion from DRAFT to accepted (an M2 action per
`M1-ACCEPTANCE-CRITERIA.md`'s Entry Rule). A reserved number is not available for an unrelated
decision, even though no file occupies it yet. (This rule exists because `ADR-002` — originally
drafted as `ADR-001` — collided with this exact reservation and had to be renumbered.)

## Tracked Gaps (not yet scheduled)

- **Controller → Engine invocation artifact.** The Execution Contract (reserved `ADR-001` once
  promoted) specifies the Engine → Controller return path. The Controller → Engine invocation
  path has no first-class architectural artifact equivalent to the Execution Contract in the
  return direction. Resolution is owned by the future **RFC-0002 (Mission Controller)**, which
  shall establish the existence, ownership, and lifecycle of the invocation artifact without
  defining its concrete schema at this stage. Surfaced during adversarial review of
  `RFC-0001-mission-policy.md` (2026-07-20), which needs this artifact to route Mission Policy
  into an engine invocation but explicitly leaves defining it out of scope. Whether it becomes an
  `Execution Request`, a `Mission Request`, or stays unnamed is RFC-0002's decision to make on its
  own merits — not introduced accidentally by another RFC.

- **Review Provider Architecture.** This repo's Step 7 is a single hardcoded Paranoid Review; at
  least one deployment of this skill has instead evolved a pluggable review-provider
  architecture (provider registry, Finding schema, disposition model) plus a Step 0.6
  Dependency Governance step this repo has no equivalent of. Whether either belongs in the
  reference implementation — pluggable providers, provider-neutral review, Herdr as transport
  vs. methodology, dependency governance as core vs. deployment-specific — is posed but not
  resolved by **RFC-0003 (Review Provider Architecture)** (2026-08-02). `ADR-004` is reserved
  for whichever resolution follows, if RFC-0003's central question resolves toward "yes,
  generalize this" rather than "accepted intentional divergence." Not available for an
  unrelated decision in the meantime, per the ADR Numbering Convention above.

## Milestone rule

A milestone closes on **architectural** completeness, not feature completeness. M1 closed because
the boundaries were clear and disciplined stopping was exercised — not because GSD Master ran out
of features to add.
