# RFC-0003: Review Provider Architecture

- **Status:** Draft — for review (not yet an ADR)
- **Date:** 2026-08-02
- **Related:** `ADR-000-why-v3.4-not-released.md`, `ADR-003-pre-flight-symmetry-and-argument-classification.md`,
  `ARCHITECTURAL-INVARIANTS.md` (Invariant 07, Invariant 08)
- **Naming note:** Raised in review as "ADR-004." Filed as an RFC instead, matching this
  repo's own convention that RFC-0001 established: a document that poses an open
  architectural question without resolving it is "Draft — for review (not yet an ADR)," not
  an ADR. `ADR-004` is not yet spoken for and remains available for whatever decision follows
  this RFC, once made. `RFC-0002` is already reserved (`MILESTONES.md`, Controller → Engine
  invocation artifact) for an unrelated topic, so this is `RFC-0003`.

## Purpose

This RFC names a single finding: **this repo (the Praxis reference implementation) and at
least one deployment of it have architecturally diverged on how Step 7 review is performed**,
and asks whether that divergence should be resolved by evolving the reference implementation
toward the deployment, or left as legitimate downstream extension. It does not propose a
schema, a provider contract, or an implementation. Those are ADR-level questions that follow
only if this RFC's central question resolves toward "yes, generalize this."

## Context

`ADR-003` (this repo) mirrored two pre-flight/routing improvements found during a real phase
execution against a deployment of this skill, and deliberately left out a third category:
herdr as a tracked, live-checked dependency; a `DEGRADED` provider status; richer
`Finding.source` reporting; and a consolidated Session Capability Report.

The reason wasn't that those ideas were rejected on their merits. It's that they don't attach
to anything in this repo. Checked directly against both `SKILL.md` files:

```
Praxis Reference (this repo)              Deployment observed
─────────────────────────────             ─────────────────────────────
Step 7: Paranoid Review                    Step 7: Review Orchestrator
  Task(subagent_type="general-purpose")      selects providers by classification
  single hardcoded reviewer                  dispatches in parallel (Herdr)
  no provider concept                        Finding schema w/ confidence, source
                                              disposition model (5 states)
(no Step 0.6 at all)                       Step 0.6: Dependency Governance
                                              skill-manifest.yaml
                                              live tool/infra discovery
                                              compatibility matrix
```

This is not "the deployment forgot to sync a bugfix." It's a materially different Step 7 and
an entirely additional step (0.6) that this repo has no equivalent of. The deployment evolved
a capability/provider architecture for review; this repo has not adopted it.

**The finding this RFC is actually about is the drift itself, not any one missing feature.**
An unrecorded architecture gap between a reference implementation and a real deployment is
exactly the failure mode `ADR-002` already had to correct once (a deployed skill silently
running rejected v3.4 content). This is not that — nothing here was rejected, and the
deployment's evolution was apparently deliberate and locally reasoned (it was checked against
Invariant 07/08 before being extended further, per the source decision this RFC is drawn
from) — but an unexamined, un-decided gap of this size between "the methodology" and "the
methodology as actually run" is worth naming on its own terms before any more implementation
happens on either side.

## Open questions for review

This RFC does not answer these. It asks whether they're the right questions, and whether
resolving them is worth doing before either repo's Step 7 changes again.

1. **Should Praxis support pluggable review providers**, or is a single, well-specified
   reviewer sufficient for the reference implementation, with pluggability treated as a
   legitimate deployment-specific extension that need never generalize back?

2. **Should review be provider-neutral** — i.e., should the *reference* methodology define an
   interface (inputs, outputs, disposition model) that named providers implement, the way the
   observed deployment already does — or is naming a provider architecture itself premature
   generalization (Invariant 08's "prefer evolution over proliferation" test cuts both ways:
   maybe Step 7 doesn't need a provider concept at all yet)?

3. **Is Herdr transport or methodology?** The observed deployment treats Herdr as pure
   dispatch infrastructure a provider is agnostic to (parallel pane execution). If Praxis ever
   specifies a provider architecture, does it name Herdr specifically, name an abstract
   "parallel execution backend" concept Herdr happens to satisfy today, or say nothing about
   transport at all and leave it fully to the deployment?

4. **Is dependency governance part of Praxis Core?** Step 0.6 (skill-manifest, live
   discovery, compatibility matrix) doesn't exist in this repo. Is "what does GSD Master
   depend on, and is it actually present" a reference-implementation concern, or is it
   inherently deployment-specific (every deployment's dependency set differs) and therefore
   doesn't belong in the methodology itself?

5. **What is the minimum OSS implementation**, if any of the above resolve toward "yes, this
   belongs in Praxis"? A full provider registry and orchestrator is a large addition to a
   repo whose own ADR-011-equivalent posture (methodology frozen, defect-correction only)
   argues for minimalism. Is there a smaller shape — e.g., Step 7 stays single-provider but
   gains an explicit extension point, without a full registry/dispatch/aggregation layer —
   that satisfies whatever the answer to (1) and (2) turns out to be, without importing the
   full weight of the deployment's version wholesale?

## What this RFC does not decide

- Whether any provider contract, `Finding` schema, or disposition model ships in this repo.
- Whether Step 0.6 (or any dependency-governance step) is added here.
- Whether Herdr, or any named execution backend, is referenced by this repo at all.
- Timing or sequencing of implementation — this RFC's only claim is that the question should
  be decided before implementation resumes on this front, not that it must be decided
  urgently or on any particular schedule.
- Whether the deployment's existing implementation should change as a result of this RFC's
  outcome. A "no, don't generalize" answer here does not imply the deployment did anything
  wrong — extensions that stay downstream and are individually reasoned against Invariant
  07/08 (as the source decision for this RFC was) are exactly what a frozen reference
  implementation is supposed to permit.

## Non-goal

This RFC is not a request to make this repo match a deployment. Matching is one possible
outcome if the answer to (1)/(2) is yes; it is not assumed. The equally valid outcome is: the
reference implementation stays a single-provider Paranoid Review by design, dependency
governance stays a deployment concern by design, and this drift is recorded as *intentional
divergence, reviewed and accepted* rather than *unexamined drift* — which is itself a
legitimate and sufficient resolution to this RFC.

## Strongest counter-argument found during drafting

Provider pluggability and dependency governance are both real, working, already-battle-tested
in the observed deployment. The case for generalizing them here is strong on capability
grounds. The case against: this repo is explicitly a *reference* implementation whose value is
partly its minimalism and legibility — every deployment-specific concern that migrates in
(what tools are installed, which transport dispatches providers) makes the reference harder to
read as "the smallest complete methodology" and easier to read as "one deployment's actual
stack, generalized." Invariant 08 already warns against this shape of mistake in the abstract;
this RFC is the concrete case it should be tested against.

## Next step

If this RFC's central question is judged worth resolving now: a follow-up ADR (next available
number, `ADR-004`) should answer questions 1-5 directly, informed by this RFC and by asking
whether the deployment's own accumulated evidence (real usage, real Invariant-07/08 review
already performed on the extension) constitutes sufficient grounds, or whether the reference
implementation should reach its own independent conclusion.

If judged not worth resolving now: this RFC stands as the record that the drift was noticed,
considered, and consciously left as accepted divergence — which itself closes the finding
without requiring any code or spec change in this repo.
