---
name: gsd-precheck-gate
version: 1.0.0
description: Project-local precheck gate for GSD phase execution.
---

# GSD Precheck Gate

Use this gate before architecture challenge or implementation for a phase.

## Procedure

1. Read the phase specification and its declared dependencies.
2. Inspect the repository paths and contracts named by the phase.
3. Search the plans, specifications, tests, and existing implementation for
   each suspected concern.
4. Return only concerns that are novel and not already addressed by the phase
   artifacts.
5. Classify each result as `NOVEL`, `ALREADY_ADDRESSED`, or `NOT_APPLICABLE`.

## Output

Return a bounded report containing:

```text
NOVEL_COUNT: <number>
ALREADY_ADDRESSED_COUNT: <number>
NOT_APPLICABLE_COUNT: <number>

NOVEL_ISSUES:
- id: PRECHECK-001
  classification: architecture | requirement | implementation | dependency
  evidence: <path and heading or line>
  impact: <plain-language consequence>
  recommendation: <bounded next action>
```

Do not authorize implementation, approve policy, dismiss a requirement, or
replace independent verification. A concern that requires an owner decision
must be returned with its evidence and remain unresolved until governed
authority confirms it.
