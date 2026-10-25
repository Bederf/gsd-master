# GSD Master Run Audit and Skill Optimizer

## Purpose

Audit each GSD Master execution against the applicable requirements and the
run transcript. The audit answers: what was required, what action the agent
took, and what transcript evidence proves the action happened. Use the audit
history to identify recurring skill gaps and propose improvements. Auditing is
read-only; it never edits the skill or changes the current run's outcome.

## Per-run audit

After execution closeout, locate the transcript for the run using the runtime's
session/transcript reference. Write the audit to:

```text
.gsd-engine/runs/{run_id}.audit.json
```

Use requirements from the approved phase specification, applicable project
governance, and GSD Master mandatory execution criteria. Do not treat optional
suggestions as mandatory requirements. Normalize each requirement into a
stable ID and preserve its source path and section/line when available.

For every requirement, inspect the transcript for an agent action and its
result. An intention, plan, or claim of completion is not proof that an action
occurred. Acceptable evidence identifies a transcript message/turn and
summarizes the observable action and result. Do not copy secrets or large
transcript excerpts into the audit.

Assign exactly one status per requirement:

- `satisfied`: transcript evidence shows the required action and outcome.
- `partially_satisfied`: some required action occurred, but a condition or
  result is missing.
- `not_satisfied`: the transcript shows the action was skipped, failed, or
  contradicted.
- `not_applicable`: the requirement's documented condition did not apply;
  record that condition and evidence.
- `unverifiable`: the transcript or necessary evidence is unavailable or
  ambiguous. Never infer success from the execution contract alone.

Record requirement text or concise normalized wording, source, status,
severity (`critical`, `high`, `medium`, or `low`), transcript evidence
reference, observed action/result, and gap rationale. Derive severity from the
authoritative source and consequences of omission; record the rationale when
classifying a requirement as critical. Summarize counts by status and identify
high-severity unmet requirements.
Link the audit path from the per-run record and append a `transcript_audited`
event to the run index. If transcript access is unavailable, still write an
audit with status `unverifiable`, explain why, and close out the run without
pretending the audit passed.

Example:

```json
{
  "schema": "gsd-master-run-audit.v1",
  "run_id": "<run_id>",
  "transcript_ref": "<runtime session or transcript reference>",
  "audited_at": "<ISO-8601 UTC>",
  "overall_status": "gaps_found",
  "summary": {
    "satisfied": 8,
    "partially_satisfied": 1,
    "not_satisfied": 1,
    "not_applicable": 2,
    "unverifiable": 0
  },
  "requirements": [
    {
      "requirement_id": "phase.ac.03",
      "requirement": "Run the focused tests for changed code",
      "source": "00-GSD-Phases/Phase-265.md#Acceptance Criteria",
      "severity": "high",
      "status": "satisfied",
      "transcript_evidence": ["turn-142", "turn-147"],
      "observed_action": "Ran the focused backend test module; all tests passed.",
      "gap": null
    }
  ]
}
```

Do not let a failed requirement audit silently rewrite or retroactively change
the execution result. The execution record reports what happened; the audit
reports whether required actions were evidenced. Link both in the run record.

## Skill optimizer

Run the optimizer when invoked with `improvement-candidate:`. It may analyze
one audit or a set of audits from `.gsd-engine/runs/`. Prefer repeated,
evidence-backed gaps over a single unusual failure. Distinguish a skill
instruction defect from project-specific policy, unavailable tools, missing
authority, or an implementation mistake. Cite run IDs, requirement IDs, and
transcript evidence in each finding.

### Performance evaluation

For a collection of runs, produce a performance evaluation as well as any
improvement proposals. Group results by the `skill_version` recorded at run
time, argument mode, and comparable scope class. Include every invocation in
the population, including blocked, failed, and incomplete runs; report
unavailable transcripts instead of silently dropping them.

Calculate and report these measures separately:

- **Audit coverage:** runs with a transcript audit / all runs in the group.
- **Evidence-backed compliance:** satisfied requirements / all auditable,
  applicable requirements (`satisfied + partially_satisfied + not_satisfied`).
- **Full-compliance run rate:** auditable runs with every applicable
  requirement marked `satisfied` / all auditable runs.
- **Critical miss rate:** auditable runs with at least one critical
  `not_satisfied` requirement / all auditable runs.
- **Run outcome distribution:** completed, blocked, failed, and incomplete
  counts divided by all runs.

Show the numerator, denominator, and unverifiable/not-applicable counts for
each measure. Do not combine these into one opaque score. Treat fewer than 10
auditable runs in a comparison group as preliminary evidence; state the sample
size and do not claim a reliable trend. This is a reporting threshold, not a
pass/fail quality target.

When comparing skill versions, compare only stable requirement IDs whose
meaning and applicability did not change. Show new, removed, or materially
revised requirements separately. Stratify by argument mode and scope where
possible so a shift in workload is not mistaken for a skill improvement.
Report the exact date range, versions, included/excluded run IDs, and reasons
for exclusions. A version change is not evidence of improvement by itself.

Write evaluations to:

```text
.gsd-engine/runs/evaluations/gsd-master-{version}-{from}-{to}.json
```

The evaluation must reference the source run and audit IDs, metric counts,
comparison basis, limitations, and observed regressions. Use replay of the
same eligible transcript set as a controlled before/after check when a proposed
change alters audit or requirement interpretation; keep live-run outcomes as
separate evidence. Never improve measured compliance by weakening, deleting,
or reclassifying requirements without an explicit approved policy change.

Return a proposed optimization report containing:

1. Performance evaluation metrics, sample sizes, date range, versions, and
   limitations.
2. Audits and runs analyzed, including unavailable or excluded records.
3. Recurring requirement gaps, frequency, severity, and supporting evidence.
4. Likely cause, with confidence and competing explanations.
5. A bounded proposed skill change, affected section, and expected effect.
6. Risks, compatibility/version impact, and verification criteria.

Do not edit `SKILL.md`, policies, or provider configuration during optimization.
An authorized maintainer reviews the proposal, applies an accepted change,
updates `SKILL.md` semver and `references/CHANGELOG.md`, verifies the new
behavior, and commits the complete versioned change. Keep rejected proposals
and rationale as audit evidence where the project maintains an improvement
decision log.

## Operational queries

List runs and audits with:

```bash
find .gsd-engine/runs -maxdepth 1 -type f -name '*.json' -print | sort
rg '"status"|"overall_status"|"requirement_id"' .gsd-engine/runs
```

The JSONL index is the event timeline; per-run JSON is the current run record;
the `.audit.json` file is the requirement-by-requirement transcript assessment.
