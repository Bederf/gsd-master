# ADR-002: Implementation Drift Reversion — Installed Skill vs. Canonical Architecture

- **Status:** Accepted
- **Date:** 2026-07-21
- **Reaffirms (does not supersede):** `ADR-000-why-v3.4-not-released.md`
- **Related:** `ARCHITECTURAL-INVARIANTS.md` (Invariant 07), `M1-ACCEPTANCE-CRITERIA.md`,
  `../docs/execution-contract-specification-v1.0.md`, `MILESTONES.md`

## Context

ADR-000 (2026-07-08) froze GSD Master at `v3.3.0` and explicitly rejected a "Karpathy
calibration" cluster — a Calibration Preamble that patches agent instruction files before every
phase run, a `karpathy-sync` argument mode, an `agent_config_map`, a `karpathy_ten_rules` block,
and a `**Calibration:**` field injected into the Step 11 Execution Contract — as Runtime state
leaking into the Execution Engine, in violation of Invariant 07. `M1-ACCEPTANCE-CRITERIA.md`
(same day) reaffirmed this at AC-3, naming the `**Calibration:**` field specifically. The
Execution Contract Specification v1.0 (same day) lists "Calibration status, instruction-file gap
matrices, `karpathy-sync` output" in its out-of-scope section by name.

On 2026-07-21, a routine skill hygiene pass on the deployed copy at
`~/.claude/skills/gsd-master/SKILL.md` found it running `version: 3.4.2` — containing exactly
the rejected cluster, including the `**Calibration:**` Execution Contract field ADR-000 and AC-3
name directly. The file's last modification date (2026-07-20) postdates every document in this
ADR trail, including `MILESTONES.md` and `RFC-0001-mission-policy.md`, both touched that same
day — so this was not a stale leftover predating the freeze; it was actively maintained after,
and in contradiction of, the decision.

## Investigation

Before treating this as grounds to revert, four questions were checked against the full ADR
trail (both this repo's and the separate project-level `adr-006-gsd-master-architecture.md`) and
the live project (scheduled tasks, hooks, settings):

1. **Does ADR-000 still align with the later documents?** Yes. `M1-ACCEPTANCE-CRITERIA.md`,
   the Execution Contract Spec, and `MILESTONES.md` (2026-07-20) all still treat `v3.3.0` as the
   frozen M1 reference implementation. `RFC-0001` (2026-07-20) addresses a distinct concept
   (Mission Policy) and reinforces the same runtime/execution boundary rather than reopening it.
2. **Was the cluster intentionally abandoned, or did implementation simply continue unaware?**
   Intentionally abandoned — ADR-000's own decision text says so directly. The actual planned
   "v3.4 candidates" recorded in `CHECKLIST-v3.3.md` and the v3.3 ship log (troubleshooting/
   anti-pattern sections, CI linting, persona split, JSON schema) never included calibration.
3. **Did any later document supersede ADR-000 without a new ADR?** No. `adr-006` (ratified
   2026-07-17, project-level) defines Radix/GSD Master/GSD Engine/Runtime/Forge/Vault ownership
   constitutionally but never mentions calibration and never references or overrides ADR-000 or
   Invariant 07.
4. **Are there hidden dependencies on the deployed v3.4.2 calibration flow?** None found. No
   scheduled task, hook, or `settings.json` entry invokes `karpathy-sync`. The only reference
   found (`GSD_SYSTEM_DISCOVERY.md`) is descriptive documentation of the drifted state itself,
   not a consumer depending on it.

All four checks reinforce ADR-000. Nothing found changes its conclusion.

## Decision

- **ADR-000 remains authoritative.** This ADR does not supersede it — it reaffirms it and
  records that the deployed skill diverged from it without any ratifying decision.
- **The installed skill is reverted** to canonical `v3.3.0` parity with this repo, removing the
  Calibration Preamble, `karpathy-sync` mode, `agent_config_map`, `karpathy_ten_rules` block, and
  the `**Calibration:**` Execution Contract field.
- **Non-behavioral hygiene is preserved** where it still applies to v3.3 content (e.g. extracting
  changelog/history into a `references/` file, a trigger-focused frontmatter description).
  Anything that existed only to document the now-removed v3.4 cluster is deleted, not kept.
- **Calibration is not re-designed here.** If an agent-instruction-sync capability is still
  wanted, it does not belong in GSD Master's execution engine. It would need its own design at
  the Runtime/Provider layer (see `ADR-000`'s own note: "if any of it survives, it belongs in the
  Runtime layer, never inside the execution engine") — starting as a new RFC, not a silent
  reintroduction into the skill.

## Governance principle (new)

> Implementation changes do not supersede architecture. When an implementation and an accepted
> ADR diverge without a ratified architectural decision authorizing the divergence, the ADR
> remains authoritative until explicitly replaced by a new ADR.

## Consequences

- `~/.claude/skills/gsd-master/SKILL.md` returns to `v3.3.0` parity with this repo, closing the
  drift.
- The ADR trail now documents not only why v3.4 was rejected (ADR-000) but that the rejection was
  tested against a real deployed violation and held (this ADR) — evidence for the next time
  implementation and architecture disagree.
- No calibration functionality ships in GSD Master until it is redesigned at the correct layer.
