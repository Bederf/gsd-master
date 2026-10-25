# ADR-003: Pre-Flight Conflict Symmetry and Argument-Shape Classification

- **Status:** Proposed
- **Date:** 2026-08-02
- **Related:** `ARCHITECTURAL-INVARIANTS.md` (Invariant 07, Invariant 08), `MILESTONES.md`
  (ADR numbering convention)
- **Scope note:** This ADR mirrors a subset of a larger project-level decision drafted
  against a downstream deployment of GSD Master with local, not-yet-upstreamed extensions
  (Step 0.6 Dependency Governance, a pluggable Review Orchestrator replacing Step 7's
  Paranoid Review). Only the portion that applies to this repo's current v3.3.0 baseline is
  mirrored here — see "Not Adopted / Not Applicable" below for what was deliberately left out
  and why.

## Context

Two gaps were found during a real phase execution against a deployment of this skill:

1. **Step 0.5's pre-flight check (0.5.3) is asymmetric.** It verifies that declared
   *dependency* paths (codebase scope files, migrations, external services, frontend
   components) exist. It has no check that paths listed under a phase's "Files to create"
   do *not* already exist. In the observed run, a phase spec called for creating a service
   file that already existed — git-tracked, tested, implementing a different design than the
   spec assumed. Nothing in Step 0.5 caught this; it surfaced only because the write
   operation itself refused to overwrite an unread file, and was resolved by an ad hoc stop
   to ask the user, not by any designed gate.

2. **Step 0's argument routing has no branch for "the argument is shaped like a phase number
   but its content is actually inline spec text."** The observed invocation was a full phase
   specification pasted directly under a phase number that turned out to already belong to a
   different, unrelated phase. Step 0.5's field-validation happened to catch the resulting
   problem, but only because it separately validates file identity for an unrelated reason —
   Step 0 itself has no classification step for this input shape at all.

## Invariant Compliance

Both changes are Step 0 / Step 0.5 pre-flight logic — they execute before any phase work
exists, and neither produces or modifies an Execution Contract field. Invariant 07
("execution artifacts must never expose runtime implementation details") governs what the
engine reports *about completed work*; pre-flight validation is not that. No compliance
concern for either item.

## Decision

### 1. Step 0.5.3 gains a symmetric "files to create must not conflict" pre-flight

Classified into two distinct conflict types, because they warrant different resolutions and
conflating them risks an incoherent resolution (e.g. "extend" makes no sense for a collision
with an unrelated phase's identity, only for a collision with an unrelated file's content):

- **`step0.5_preflight_file_conflict`** — a path under "Files to create" already exists.
  Resolution options presented to the user: `EXTEND_EXISTING | REPLACE_EXISTING | ABORT`.
- **`step0.5_preflight_identity_conflict`** — the phase number/artifact root already refers
  to different, unrelated content. Resolution options: `RENAME_PHASE | MERGE_INTENT | ABORT`.

### 2. Step 0 gains an argument-shape classification pass

Before committing to a routing mode, classify the argument's actual content as one of
`phase_number | phase_file_path | inline_spec_markdown | plan_description |
improvement_description`. If the detected type disagrees with the mode implied by the
argument's literal shape (e.g. argument looks like a bare phase number but its content is a
full spec document), confirm with the user before proceeding, rather than silently inferring
one mode and relying on a downstream step to catch the mismatch by coincidence.

## Concrete Diffs

### `SKILL.md` — Step 0.5.3

```markdown
// Before

## 0.5.3: Validate Dependencies (Pre-Flight)

For each dependency declared in section 3:
- **Codebase scope file path** → check file exists at path
- **DB migration** → check migration file exists in `supabase/migrations/`
- **External service** → check credentials/config exist
- **Frontend component** → check component file exists at path

// After

## 0.5.3: Validate Dependencies (Pre-Flight)

For each dependency declared in section 3:
- **Codebase scope file path** → check file exists at path
- **DB migration** → check migration file exists in `supabase/migrations/`
- **External service** → check credentials/config exist
- **Frontend component** → check component file exists at path

For each path listed under "Files to create" in section 3 (Codebase Scope):
- Check the path does NOT already exist.
- If it DOES exist → `step0.5_preflight_file_conflict`. Report the existing file's git
  history and test coverage if any. Ask the user: `EXTEND_EXISTING | REPLACE_EXISTING |
  ABORT` — never silently proceed with either.

Separately, before resolving the phase file path in 0.5.1: if the resolved artifact root
already contains phase content whose subject matter does not match this invocation's
described work → `step0.5_preflight_identity_conflict`. Ask the user: `RENAME_PHASE |
MERGE_INTENT | ABORT`.
```

### `SKILL.md` — Step 0

```markdown
// Before

# Step 0: Route by argument type

**If argument starts with "improvement-candidate:"**
→ Jump to **Improvement Mode** (Step 13)

**If argument starts with "plan:"**
→ ...

**If argument is a phase number:**
→ Continue to **Step 0.5** (spec validation)

// After

# Step 0: Route by argument type

**Classify argument content first**, independent of its literal shape: `phase_number |
phase_file_path | inline_spec_markdown | plan_description | improvement_description`. If the
argument looks like a bare phase number but its content is clearly a full spec document (has
its own headings, is not just digits), confirm with the user which mode is intended before
proceeding — do not silently assume phase-number mode and rely on Step 0.5 to catch a
resulting mismatch as a side effect of an unrelated check.

**If argument starts with "improvement-candidate:"**
→ Jump to **Improvement Mode** (Step 13)

**If argument starts with "plan:"**
→ ...

**If argument is a phase number:**
→ Continue to **Step 0.5** (spec validation)
```

## Not Adopted / Not Applicable to This Repo's Current Baseline

The full project-level decision this ADR is drawn from also proposed: (a) tracking `herdr` as
a live-checked infrastructure dependency, (b) a `DEGRADED` provider status plus richer
`Finding.source` reporting when a review provider's declared execution backend is
unavailable, and (c) a consolidated Step 0.6 "Session Capability Report."

None of these transplant here as written, because this repo's `SKILL.md` does not yet have
the infrastructure they extend:

- There is no Step 0.6 (Dependency Governance) in this repo at all — it exists only in the
  downstream deployment this ADR was drawn from.
- Step 7 here is still the single hardcoded "Paranoid Review" (`subagent_type:
  "general-purpose"`, no provider abstraction, no `Finding` schema, no `execution_backend`
  field, no herdr dispatch layer documented). The pluggable Review Orchestrator these items
  extend does not exist in this repo's v3.3.0 baseline.

Item (a)-(c) are not rejected on the merits — they were reasoned through against Invariant
07/08 in the source decision and found compliant, as extensions of primitives that exist
*downstream*. But mirroring them here would describe a Step 0.6 and a provider schema this
repo doesn't have, which is a more consequential move than a defect-correction ADR should
make unilaterally. Whether to upstream Step 0.6 Dependency Governance and the pluggable
Review Orchestrator (i.e., ratify the downstream evolution into this canonical repo) is a
separate, larger architectural decision — outside this ADR's scope, and not implied by it.

## Consequences

- Phase specs can no longer silently collide with pre-existing implementations or unrelated
  phase identities — both surface at Step 0.5, before any wave executes, with an explicit
  user decision required.
- Step 0 gains one classification pass before phase-file resolution, closing the gap that let
  a mismatched invocation reach Step 0.5 by accident rather than by design.
- This ADR does not close the gap between this repo and its downstream deployment regarding
  Dependency Governance or pluggable review providers — that gap is now explicitly named
  (see "Not Adopted" above) rather than left implicit, which is itself the point: an
  unrecorded architecture drift between canonical and deployed copies is exactly the failure
  mode ADR-002 already had to correct once.

## Review Trigger

Reopen if the two-conflict-type classification proves insufficient for a real collision case
not covered by `file_conflict`/`identity_conflict`, or when a future ADR proposes upstreaming
Step 0.6 Dependency Governance and/or the pluggable Review Orchestrator — at that point, the
herdr/`DEGRADED`-status/Session-Capability-Report items deferred here should be revisited as
their own ADR against the then-current baseline, not silently folded into this one.
