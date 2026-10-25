# GSD Master — Changelog & Resolved History

This skill is a deployed mirror of the canonical repo `~/gsd-master` (see
`CHECKLIST-v3.3.md`'s file-locations table). Version history, ADRs, and
the full architectural trail live there — this file is a short pointer,
not a duplicate.

## v3.4.0-preview.1 — 2026-10-16

- Prepared the skill package for an independent public developer preview.
- Added public lifecycle, security, conduct, attribution and example materials.
- Removed consumer-specific reviewer and secret-manager configuration from the
  public skill surface; projects now provide those bindings through their own
  provider registry.
- Added deterministic public-package validation and CI configuration.

## Unreleased — ReviewCycle integration

- Added explicit `review-cycle.v1` references to the GSD execution contract,
  review evidence, and bounded correction-loop instructions.
- Clarified that cycle 3 escalates/stops and that reviewer `PASS` routes to
  Forge rather than directly completing the task.
- Added the explicit four-part completion gate: passing review, focused tests,
  zero unresolved blockers, and passed Forge verification.
- Added mandatory per-run lessons-learned evidence using `gsd-learning.v1`,
  with proposed-only improvement candidates and governed adoption.

## v3.3.4 — Canonical phase specification integration

- Added canonical `phase-specification.v1` sidecar resolution and fail-closed
  validation before phase execution.
- Bound phase runs and derived artifacts to the immutable specification identity
  tuple `(phase_id, specification_id, version, specification_hash)`.
- Removed `plan:` as a specification-gate bypass; draft intent must first become
  a validated phase specification.
- Defined phase-gate authorization for one-shot execution without intermediate
  permission prompts, while preserving Core acceptance authority.

## v3.3.3 (2026-09-15)

- Added version- and mode-aware GSD Master performance metrics, sample-size
  limits, and comparable-version evaluation guidance to the Skill Optimizer.
- Added controlled replay guidance and regression reporting so optimization
  does not reward weakened requirements.

## v3.3.2 (2026-09-15)

- Added per-invocation run records and an append-only JSONL event index under
  `.gsd-engine/runs/`, covering all argument modes and terminal outcomes.
- Added transcript-based requirement audits with explicit evidence/statuses and
  an evidence-backed optimizer that proposes changes without self-editing.
- Run records identify the skill version and source commit and link to the
  execution contract, review evidence, lessons learned, and transcript audit.

## v3.3.0 (current — canonical, frozen)

Stable Reference Implementation. What v3.3 added over v3.2:

1. Step 0.5 specification validation: requires 6 fields (problem, AC,
   deps, gate, trade-offs, version) + pre-flight dependency check.
2. `plan:` argument mode — skips phase file discovery for pre-reviewed
   specs.
3. Old Step 3 (validate-phase skill) removed — merged into Step 0.5.
4. Heartbeat system removed (had no consumer).
5. Read-only guard for Greploop (auto-skips if no GitHub token).
6. Mandatory scope-adaptive review (always runs when files changed).
7. Test harness scaffolding (auto-detect + run + baseline diff).
8. Documentation + git push step (auto-commit vault docs).

## v3.4 — attempted, never released

A local working copy advanced to `v3.4.0` (unpushed), adding a
"Karpathy calibration" cluster: a Calibration Preamble that patches
agent instruction files before every phase run, a `karpathy-sync`
argument mode, an `agent_config_map`, a `karpathy_ten_rules` block, and
a `**Calibration:**` field injected into the Step 11 Execution
Contract.

An architectural audit rejected it: the cluster mixed Runtime state
(which agent, which rules were loaded) into the Execution Engine,
violating Invariant 07 ("Execution artifacts must never expose runtime
implementation details"). The working copy had also silently dropped
mature v3.3 content (structured `codex_review`/`greploop_review`
objects, the `<examples>` block, PR-body templates) — a regression,
not an evolution. Full rationale: `~/gsd-master/adr/ADR-000-why-v3.4-not-released.md`.

**Decision:** do not release v3.4. GSD Master stays frozen at v3.3.0.
If any calibration concept survives, it belongs at the Runtime/Provider
layer (e.g. CLAUDE.md tooling), never as an execution-engine step or
Execution Contract field.

On 2026-07-20 this deployed skill was found to have drifted to
`v3.4.2` anyway, containing the rejected cluster — an unauthorized
implementation drift, not a re-decision. `~/gsd-master/adr/ADR-002-implementation-drift-reversion.md`
(2026-07-21) reaffirmed ADR-000 and directed this revert back to
v3.3.0 parity.

## Patches on frozen v3.3.0

Bugfixes only — no new steps, no scope changes to the Execution Engine. Version
frontmatter stays `3.3.0`; these are corrections to existing step behavior, not
evolution (Invariant 08 still applies to anything that isn't a plain bugfix).

- **2026-08-02 (Phase 265, consumer repository):** Step 6.2's original
  `pytest backend/tests/ -q --tb=short --timeout=120 2>&1 | tail -5` ran an
  entire ~7000-test backend suite in a single process. Observed result: 25
  minutes runtime and a pytest INTERNALERROR (`AST constructor recursion depth
  mismatch`) crashing the run itself, plus the `| tail -5` truncation silently
  discarding the FAILED/ERROR test list needed to tell phase regressions apart
  from pre-existing failures. Step 6.2 rewritten to: (1) run only tests
  targeted at the phase's changed files first, (2) batch any full-suite check
  per subdirectory as separate background processes redirected to files
  (never one process, never `tail`-truncated), (3) explicitly cross-reference
  failures against changed files before treating a pre-existing failure count
  as a phase blocker.

- **2026-09-02:** Step 7 routing clarified as registry-driven and factual. Added
  elective frontend creation routing for `design-taste-frontend`, retained
  Impeccable as the frontend review/polish provider, and defined mandatory
  `gsd-review-evidence.v1` output recording selected, skipped, and executed
  providers with evidence references.
- **2026-09-02:** Documented the provider-neutral independent reviewer boundary,
  fresh-context requirement, three-cycle correction loop, and external secret
  injection via `ANTHROPIC_API_KEY`. GSD remains the completion gate; the
  reviewer cannot edit, merge, deploy, or approve production.

## Full ADR trail

`~/gsd-master/adr/`:
- `ADR-000-why-v3.4-not-released.md` — why v3.4 wasn't released
- `ARCHITECTURAL-INVARIANTS.md` — Invariant 07 (runtime leakage), Invariant 08 (prefer evolution over proliferation)
- `M1-ACCEPTANCE-CRITERIA.md` — M1 architectural acceptance gate
- `MILESTONES.md` — M1/M2 milestone tracking
- `RFC-0001-mission-policy.md` — Mission Policy concept (draft)
- `ADR-002-implementation-drift-reversion.md` — this reversion
