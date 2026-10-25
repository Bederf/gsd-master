# ADR-000: Why GSD Master v3.4 Was Not Released

- **Status:** Accepted
- **Date:** 2026-07-08
- **Superseded by:** The Mission Controller / Runtime / Execution Engine architecture (developed 2026-07)
- **Related:** `docs/execution-contract-specification-v1.0.md`

## Context

A local working copy of GSD Master advanced to `version: 3.4.0` (unpushed). It added a
"Karpathy calibration" cluster:

- a **Calibration Preamble** that reads four agent instruction files and *patches missing
  bullets* before every phase run;
- a `karpathy-sync` argument mode (audit + patch instruction files, then stop);
- an `agent_config_map` (Agent → instruction file → calibrated);
- a `karpathy_ten_rules` block;
- a `**Calibration:**` field injected into the Step 11 Execution Contract.

Concurrently, we developed a broader architecture in which GSD Master is explicitly the
**Execution Engine** — bounded above by the **Mission Controller** (goal → engine selection →
run a phase → receive a contract → decide continue/stop) and below by the **Runtime** (the
agent harness: Claude Code, Codex, OpenCode, and their instruction files).

Re-evaluating the v3.4 working copy against that architecture produced an architectural audit
(see below). The audit's central finding was not about Karpathy at all:

> **v3.4 was not an evolution of GSD. It was the beginning of runtime concerns leaking
> into the execution engine.**

That is precisely the drift the new architecture exists to prevent.

## Decision

- **Do not release v3.4.**
- **Freeze GSD Master at v3.3.0 = Stable Reference Implementation.**
- **v3.4 = Abandoned Working Branch (never released).** Not "failed," not "bad" — *superseded
  by a better architecture.* A normal outcome in mature software engineering.
- Keep the local v3.4 working copy (`~/.claude/skills/gsd-master`) as an experimental branch
  **only** for possible future mining of the calibration idea — but if any of it survives, it
  belongs in the **Runtime** layer, never inside the execution engine.
- The next real artifacts are: (1) this ADR, (2) the Execution Contract Specification v1.0,
  (3) the Execution Contract JSON Schema derived from that spec, (4) the Mission Controller MVP.

## Audit Summary (evidence-based)

The 577-line diff showed v3.4 is **not purely additive**: it both adds the calibration cluster
and **removes ~15 sections of v3.3 maturity** — including the structured Execution Contract
fields (`codex_review`, `greploop_review`) that the new architecture actually wants to promote
to a schema.

### Additions — classified

| Addition | Bucket | Verdict |
|----------|--------|---------|
| `version: 3.4.0` + `karpathy-sync` hint | metadata | Discard from GSD (freeze at 3.3.0) |
| "What v3.4 adds" blurb | docs | Discard |
| `agent_config_map` (hardcodes consumer-specific instruction paths) | **Runtime** | Runtime config, not GSD. Re-introduces consumer-specific paths into a project-agnostic skill. |
| `karpathy_ten_rules` block | **Runtime** | Already live in CLAUDE.md files. GSD should reference, not embed (duplication → drift). |
| `karpathy-sync` usage + routing | **Runtime** | Standalone calibration tool, not phase orchestration. |
| **Calibration Preamble** (mutates instruction files every run) | **Runtime (high-risk)** | Must not live in an execution engine. Mutating global agent config as a side effect of every phase is Runtime self-modification. |
| "Calibration Patch Applied" status + checkboxes | **Runtime** | Consequence of the preamble. Discard from GSD. |
| `**Calibration:**` field in Execution Contract | **Leaks Runtime → Contract** | Discard. The contract must report execution state only. |

### Removals (v3.3 content dropped by v3.4) — all classified as **GSD, KEEP in v3.3**

| Removed v3.3 content | Why it matters |
|----------------------|----------------|
| §8.4 `codex_review` structured object | Seed for the Execution Contract Schema. v3.4 deleting it is a regression vs. our goal. |
| §9.6 `greploop_review` structured object | Same — core contract schema material. |
| `<examples>` (4 traces + counter-examples) | Defensive-patterns docs; valuable. |
| §9.3 Greploop detailed loop + PR body + comment templates | Operational maturity. |
| Extra `<rationalizations>` (wave reconciliation, supervised≠tested, success_criteria staleness) | Valuable guidance. |
| Improvement-mode report template | Valuable. |
| Step 10.2 commit/push + decision-log detail; Step 9.0 PR creation detail | Operational maturity. |
| Step renumbering (failure points lowered) | Freeze at v3.3 numbers (matches "do not renumber" gotcha). |

**Conclusion:** the entire v3.4 addition cluster is **Runtime**, not GSD; none of it belongs in
the Mission Controller either. Meanwhile v3.4 silently dropped mature, valuable GSD content, so
remote v3.3 is *richer and more correct* than local v3.4.

## Key Architectural Principle (established by this ADR)

> **Execution Contracts describe the work.**
> **Runtime describes the environment.**
>
> Those two should never be mixed.

The `**Calibration:**` field (a Runtime concern) appearing inside the Execution Contract is the
concrete counterexample this principle forbids. Enforcing it prevents a large class of future
coupling between "what was built" and "what agent/rules were active when it was built."

## Consequences

- GitHub `main` stays at `v3.3.0` — the Stable Reference Implementation.
- Six months from now, when someone asks "why isn't there a v3.4?", this record answers with
  evidence rather than memory.
- The Execution Contract Schema (Option C's one pulled-forward v3.4 item) is sourced from
  **v3.3's §8.4 + §9.6**, not from the v3.4 working copy.
- Engineering effort moves to the layer above GSD (Mission Controller MVP), validating the
  architecture before any further execution-engine change.
