---
name: gsd-research-phase
version: 1.0.0
description: Native GSD research workflow for read-only phase investigation and evidence collection.
---

# GSD Research Phase

Use this workflow for pure research or investigation of a phase before planning.
It is the native implementation of the `gsd:research-phase` routing declared by
GSD Master. It replaces no other stage and authorizes nothing.

## Request

A research request must be phase- or vault-bound and must supply:

- the phase identity or the vault path to resolve it;
- the research question or investigation objective.

A request without a resolvable phase, or that supplies a research topic detached
from a phase, is rejected as `INCOMPLETE`.

## Procedure

1. **Resolve the phase.** Locate the canonical phase artifact and its
   `phase-specification.v1` sidecar through the configured vault root. Do not
   fall back to `.planning/` or to any legacy command surface. A missing or
   unreadable sidecar is a terminal `BLOCKED` outcome, not a degraded run.

2. **Bind specification identity.** Capture and preserve the tuple
   `(phase_id, specification_id, version, specification_hash)`. If the computed
   specification hash differs from the declared hash, stop with `BLOCKED` and
   record the mismatch. Never rewrite the sidecar to reconcile it.

3. **Validate before discovery.** Validate the sidecar against
   `phase-specification.v1`. An invalid specification terminates the run before
   any discovery work begins.

4. **Collect evidence read-only.** Inspect the repository, phase artifacts,
   contracts, tests, and governance records named by the phase. Collect findings
   with exact source paths, line references, or headings. Treat every inspected
   artifact as read-only.

5. **Estimate dependencies before implementation.** Identify what implementation
   would require, and record it as a dependency finding — not as authorization.

6. **Classify every statement.** Each output statement must be classified as one
   of:

   - `FINDING` — supported by an inspected source reference;
   - `ASSUMPTION` — asserted without direct evidence;
   - `UNKNOWN` — not determinable from available evidence;
   - `RECOMMENDATION` — a proposed next action, marked advisory.

   A statement without a source reference must not be classified `FINDING`.

7. **Preserve provenance.** Record for each finding: the source path, the line
   reference or heading, the inspection method, and the classification.

8. **Write only approved artifacts.** Permitted writes are the research output
   artifact and the run/audit records. No source, contract, manifest, phase
   artifact, or governance record may be modified. Any attempted mutation is a
   terminal `BLOCKED` outcome and must be recorded as such.

9. **Stop at every gate.** Terminate with `BLOCKED` at any owner decision, Core
   gate, or implementation authorization boundary. Research completion never
   implies or satisfies an authorization gate.

10. **Emit a typed terminal outcome.** Exactly one of:

    - `COMPLETE` — investigation finished; findings recorded with provenance;
    - `BLOCKED` — a gate, mutation attempt, hash mismatch, or missing artifact
      stopped the run;
    - `INCOMPLETE` — the request was unresolvable or the evidence was
      insufficient to finish.

    `COMPLETE` describes the investigation only. It does not assert readiness,
    correctness, approval, or authorization to implement.

## Output

Return a bounded research report containing:

```text
OUTCOME: COMPLETE | BLOCKED | INCOMPLETE

SPECIFICATION_IDENTITY:
  phase_id: <id>
  specification_id: <id>
  version: <version>
  specification_hash: <sha256>

FINDINGS:
- id: RESEARCH-001
  classification: FINDING | ASSUMPTION | UNKNOWN | RECOMMENDATION
  statement: <bounded statement>
  source: <path and line or heading>
  method: <inspection method>

GATES_ENCOUNTERED:
- id: <gate reference>
  status: STOPPED | NOT_REACHED

MUTATION_ATTEMPTS: <count>
```

## Prohibited

- Falling back to `.planning/`, a legacy standalone research command, or any
  external research workflow.
- Inferring implementation authorization from research completion.
- Modifying any source, contract, manifest, phase artifact, or governance record.
- Presenting an `ASSUMPTION` or `UNKNOWN` as a `FINDING`.
- Continuing past an owner, Core, or implementation authorization gate.

## Authority

This workflow collects evidence and produces advisory findings. It does not
grant implementation authority, approve policy, qualify a capability, or replace
independent verification. Recommendations remain advisory until a separate
governed authorization is recorded.
