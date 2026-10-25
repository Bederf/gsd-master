# RFC-0001: Mission Policy

- **Status:** Draft — for review (not yet an ADR)
- **Date:** 2026-07-20
- **Related:** `ADR-000-why-v3.4-not-released.md`, `ARCHITECTURAL-INVARIANTS.md` (Invariant 07),
  `../docs/execution-contract-specification-v1.0.md`, `M1-ACCEPTANCE-CRITERIA.md` (Mock-First M2
  Entry Rule), `../docs/adaptive-execution-profiles-implementation-reference.md` (working
  implementation of the general problem this RFC names — see "Related implementation" below)

## Purpose

This RFC defines a single concept: **Mission Policy**. It does not propose a schema, field names,
or a persistence format — those are ADR-level decisions that may follow if this concept survives
review. This is an architectural concept note, not an implementation spec.

## Context

ADR-000 established that a Mission Controller sits above the Execution Engine, and drew a hard
boundary (Invariant 07): the Execution Contract — the interface between the two — carries *only*
execution state (what was attempted, produced, verified). It carries no Runtime state, and no
information about *how much rigor was requested* for the work it describes.

That leaves a gap. Something has to decide how much rigor a given mission receives — how large a
budget, how strict the verification, how conservative the risk tolerance — before the Execution
Engine is ever invoked. ADR-003 (LoopState v1) anticipated this: it defines `budget` fields
(`tokens_limit`, `time_limit_seconds`, `phase_retries_limit`) but leaves them null, noting
explicitly that "enforcement is roadmap-later." Nothing in the architecture today decides what
value belongs in those fields, or governs any rigor dimension beyond budget (verification depth,
review requirements, risk tolerance, autonomy level).

Mission Policy names that missing decision.

## What is Mission Policy?

This RFC proposes Mission Policy as a name for controller-owned execution constraints — the
answer to "how much rigor should this mission receive" — expressed as concrete, consumable
constraints, not as a label.

Whether Mission Policy is a new artifact sitting beside LoopState's existing `budget` object, or
simply the generalization of `budget` itself (budget as the first-shipped dimension of a broader
`policy`), is an open question this RFC does not resolve — see "What this RFC does not decide"
below. Either way, it is not a new architectural *layer*: it is data owned by the Mission
Controller, positioned wherever the controller's other execution-constraint data already lives.

## Who owns it?

The Mission Controller. This follows directly from ADR-003's producer rule for LoopState
("Producer: Mission Controller only. Execution Engines never write LoopState") — Mission Policy is
the same kind of artifact: a controller-owned decision about the mission, not a product of
execution.

No Execution Engine may define, compute, or default a Mission Policy value. If an engine needs to
know "should I run the deep-review path," it learns that only because whatever it was invoked with
already encodes that requirement as work to perform — never because it consulted a policy or a
level flag directly, and never via the Execution Contract, which is the engine's *output*, not
something it receives (see "Who consumes it?" below). This preserves the Mock-First M2 Entry Rule
(`M1-ACCEPTANCE-CRITERIA.md`): a Mission Controller with Mission Policy logic embedded in it must
still contain zero Execution-Engine-specific logic, and must still be swappable across a Mock
Execution Engine, GSD Master, or any future engine without change.

## Who may mutate it?

The Mission Controller only, and only at mission boundaries the controller itself governs —
mission creation, and points where the controller already has authority to alter mission state
(e.g. resuming after a pause). This mirrors LoopState's mutability model: mutable by design,
atomically rewritten by its sole producer, never touched mid-phase by the engine executing that
phase.

Mission Policy is not renegotiated by an Execution Engine mid-phase. If a mission's policy needs
to change (more budget, stricter review), that is a controller-level decision, made at a boundary
— the same way `pause.reason: budget` already models "engine hit a limit, controller decides what
happens next" in LoopState today.

## Who consumes it?

The Mission Controller — to determine the constraints under which it invokes an Execution Engine,
and to populate the constraint fields (budget and others) already anticipated in LoopState.

Note precisely what this does *not* mean. The Execution Contract itself is Execution-Engine
output — its owner layer is GSD Master, consumed by the Mission Controller (see the Execution
Contract Specification) — not something the Mission Controller constructs or hands downward.
Mission Policy therefore does not shape the Contract; it shapes whatever the controller uses to
invoke the engine in the first place. The current ADRs do not name or specify that invocation-side
interface at all — only the return-side Contract is specified. Defining that invocation artifact
is out of scope for this RFC.

What the current architecture does establish is the receiving end: the Execution Engine never
consumes Mission Policy directly, by the same logic Invariant 07 already applies to Runtime state.
An engine that branched on policy would stop being a deterministic execution engine and become a
policy engine — the exact failure ADR-000 identifies in v3.4. Whatever channel eventually carries
policy-derived instructions into the engine, the engine's behavior must remain describable without
reference to Mission Policy, only to the concrete work requested.

## What is explicitly not Mission Policy?

- **Runtime environment state** — agent identity, loaded instruction files, model configuration,
  cache state, sandbox configuration. Forbidden by Invariant 07 regardless of layer.
- **The Execution Contract** — output describing completed work, not input describing intended
  rigor. These are the two ends of one execution; a Mission Policy is consumed *before* a Contract
  is produced, never merged with it.
- **A label or preset name** — "mini," "medi," "maxi," or any other named template, is a request
  that *produces* a Mission Policy. It is not the policy itself, and need not be persisted once
  the concrete policy it selects has been recorded. A mission's actual constraints must remain
  meaningful even if the meaning of a named preset changes later.
- **Mission knowledge** — the goal and roadmap themselves, which ADR-003 already places in the
  vault, not in controller-owned execution state. Policy governs *how* a mission is run, not *what*
  it is trying to achieve.

## What this RFC does not decide

- Which concrete dimensions Mission Policy contains (budget, verification depth, review
  requirements, risk tolerance, autonomy, or others).
- Whether Mission Policy is one unified object or a family of related, independently-owned policy
  types (budget policy, verification policy, autonomy policy, ...) with potentially different
  lifecycles.
- Its relationship to ADR-003's `budget` object specifically: whether Mission Policy is a new
  artifact sitting beside `budget`, or `budget` generalized into it (`budget: {...}` evolving
  toward `policy: {budget: {...}, verification: {...}, ...}`).
- Whether policy is mission-scoped (one policy for the whole mission), phase-scoped (may vary per
  phase in `phases[]`), or hierarchical. This RFC makes no assertion here.
- Whether/how policy may be escalated between retry attempts of the same phase
  (`phases[].attempts`). Not addressed by this RFC.
- Whether/how policy composes across delegated or nested missions. Explicitly out of scope for
  this RFC, not merely unaddressed.
- Where Mission Policy is persisted, or whether it extends LoopState, lives beside it, or is a new
  artifact.
- Named templates/presets and what each one resolves to.
- Any schema, field name, or serialization format.

Those are ADR-level questions, to be taken up only if this concept survives review.

## Related implementation

A concrete, deployed consumer instance of the general problem this RFC names — "how much rigor
should a unit of work receive" — exists in a consumer repository's GSD Engine (`.gsd-engine/`),
under the name **Adaptive Execution Profiles** (design doc in the consumer project's vault;
implementation reference:
`../docs/adaptive-execution-profiles-implementation-reference.md` in this repo). It assigns a
`small`/`medium`/`large` profile to a unit of work via a dedicated `assess-execution-profile`
capability, with forward-only escalation (never de-escalates once raised) and a full evidence
trail on every change — directly analogous to this RFC's framing that a named preset ("mini,"
"medi," "maxi") "is a request that *produces* a Mission Policy. It is not the policy itself."

**Structural difference worth naming, not resolving here:** in that consumer implementation, profile
assessment is a capability the *Execution Engine itself* requests and owns as session metadata —
not a Mission-Controller-owned decision made before the engine is invoked, as this RFC specifies
under "Who owns it?" above. The Engine does not currently branch its own behavior on the profile
value (verified directly against the code: no capability-loading changes are wired to profile
level today — profile is stored and reported, not consumed), so it has not crossed into "policy
engine" territory ADR-000 and this RFC warn against. But the *ownership* boundary differs from
what's proposed here regardless. Whether RFC-0002 (Controller → Engine invocation artifact, per
`MILESTONES.md`'s Tracked Gaps) treats this as prior art to generalize toward a controller-owned
version, or as an example of engine-side placement that Invariant 07 would require relocating
before any promotion to ADR, is an open question for RFC-0002 to resolve — not asserted either
way here.

## Open questions for review

The load-bearing question is not "is Mission Policy one object or several" — it's whether
controller-owned execution constraints beyond budget deserve first-class architectural treatment
at all. That's the only claim this RFC actually makes.

The strongest counter-argument found during review: ADR-003 already owns controller-managed
execution constraints — budget is simply the first one it shipped, with its `*_limit` fields
already reserved and currently null. The general design instinct to prefer evolving an existing
abstraction over introducing a parallel one suggests Mission Policy could just be `budget`
generalized, not a new primitive sitting beside it. This RFC deliberately does not resolve that;
resolving it is follow-on design work, or a follow-up RFC, not this one.

Everything else in this RFC — ownership, mutation, and consumption boundaries, and what is
explicitly not policy — holds regardless of how that question is eventually answered.
