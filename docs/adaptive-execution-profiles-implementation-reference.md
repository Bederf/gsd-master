# GSD Adaptive Execution Profiles — Capability Stack Reference

> **Provenance note (this repo only):** this document describes a working implementation that
> lives entirely in a *different* consumer repository under `.gsd-engine/`. Nothing
> below is code in `gsd-master`; every file path in this document (`.gsd-engine/`, `.runtime/`,
> `docs/`, `tests/`) is relative to that other repo, not this one. It's placed here, per
> `MILESTONES.md`'s governance layering (RFC = proposal, ADR = ratified decision, `docs/` =
> implementation reference), as evidence for `RFC-0001-mission-policy.md` and the future
> `RFC-0002` — see the cross-reference added there. It is **not** an ADR or RFC of this repo, and
> is not proposing that any of `gsd-master`'s own architecture change.

**Audience:** an engineer picking up this code for the first time — how to call it, how it fits together, and every contract involved.

**Status:** all six capabilities were reported as implemented and tested in that consumer
repository. The design source is maintained in the consumer project's vault. This document
describes that external implementation for architectural context; it is not a bundled runtime
or a public dependency of GSD Master.

---

## 1. What this is

The GSD Engine (`.gsd-engine/`) is a Minimum Viable Orchestrator: a session state machine (`session.py`), a capability→provider Registry (`registry.py`/`registry.yaml`), a Dispatcher that resolves and invokes providers (`dispatcher.py`), and an append-only EventBus (`event_bus.py`) that persists everything to `.runtime/store.db`. `engine.py` ties these together.

Before this work, the Engine could only do one thing: dispatch a DAG of tasks to `.runtime/runtime.py` for execution (`execute_dag`). This work added **six new capabilities** that sit around that execution step — the process of figuring out *how much ceremony a task deserves*, *what the task actually is*, *how to break it down*, *how to translate that into something executable*, *whether the result is any good*, and *whether the work is demonstrably done*:

```
User Request
     │
     ▼
assess_execution_profile   — how much process does this deserve? (small/medium/large)
     │
     ▼
clarify_requirements       — what are we building? (objective, assumptions, open questions)
     │
     ▼
plan_work                  — what's the task breakdown, in what order?
     │
     ▼
implement                  — translate the plan into an executable DAG
     │
     ▼
execute_dag                — (pre-existing) actually run it, via .runtime/runtime.py
     │
     ▼
review                     — does the evidence show good work? (findings, severity)
     │
     ▼
verify                     — does the evidence show *complete* work? (the constitutional gate)
```

Every new capability is a **pure Python function** with no side effects, no filesystem access, no Registry/Dispatcher access of its own. Each is registered once in `registry.yaml`, dispatched through `Dispatcher.dispatch()`, and called from `Engine` via one wrapper method per capability. None of them changes the Engine's lifecycle state machine — the state machine is exactly what it was before this work (`idle → planning → executing → completing → closed`).

---

## 2. Architecture invariants (hold these, don't relitigate them)

These were the actual design decisions made and tested during implementation — not just aspirations:

1. **Layer Purity.** A capability provider never calls another capability provider, never imports the Dispatcher/Registry, never imports another provider's module. `implement.py` doesn't know `execute_dag` exists. `review.py` doesn't know `implement.py`'s DAG schema. The only thing that composes capabilities is the **Engine** (or whoever is driving it — currently a human/agent, calling `engine.X()` methods in sequence). This is verified structurally: `grep "profile ==" .gsd-engine/engine.py` returns nothing — the Engine never branches on a capability's *output value* to decide what to do next; it only ever dispatches by *name*.

2. **"Caller pre-joins, provider judges."** Every capability that needs data from an earlier capability's output receives it *already extracted and correlated* by the caller — never by reaching into another capability's raw internal schema itself. `review` doesn't parse `implement`'s DAG node shape; the caller flattens `implement`'s verification results into `review`'s `verification_outcomes` shape first. This is what keeps every provider a one-file, no-dependencies pure function.

3. **Forward-only, no de-escalation** (Adaptive Execution Profiles' own core rule, sec 4.3). Once a session's profile escalates (e.g. small → large), it never drops back down automatically. A later assessment recommending a smaller profile is recorded (confidence tracking updates) but does not change `session.profile`. Manual operator override is the only thing that can lower it — see §5.

4. **Auto-derive from objective evidence; only ask for genuine judgment calls.** `review` doesn't ask the caller to restate "did the required verification pass" — it reads that fact directly from `implement`'s evidence and derives a `blocker` finding itself. `verify`'s two structural gates (`review_status`, `execution_blockers`) work the same way. The caller is only asked for things a machine can't determine: qualitative review findings, and (by explicit design decision, see §7) whether each acceptance criterion was actually satisfied.

5. **Runtime Boundary invariant** (`.runtime/` is a separate, older subsystem this work now reads from for the first time): `.runtime/` is an execution substrate, not an orchestration component. GSD code may **read** execution state from `.runtime/store.db` (via `TaskStore` getters) to attach evidence to `execute_dag`'s result. It must never modify runtime scheduling, mutate DAG semantics, or write to the store — only `.runtime/runtime.py` owns writes to `.runtime/store.db`. This is enforced by construction: `dispatcher.py` only ever calls read-only `TaskStore` getters (`get_all_tasks`, `get_verification_results`, `get_artifacts_by_run`, `find_latest_run_by_dag_path`), never `create_task`/`record_*`/etc.

6. **Evidence, not artifacts.** No capability writes a file to disk as its "output." Every result is a plain dict, returned to the caller and published as a session event via `EventBus`. The event stream (persisted in `.runtime/store.db`'s `events` table) *is* the durable audit trail — there is no separate report file to keep in sync.

---

## 3. Quick start

```python
import sys
sys.path.insert(0, ".gsd-engine")   # mirrors how `python3 .gsd-engine/engine.py` auto-adds this dir

from engine import Engine

engine = Engine(".gsd-engine/registry.yaml")
engine.start()   # session: idle -> planning

profile = engine.assess_profile({
    "factors": {
        "scope": {"level": "medium", "reason": "renames a field across 2 endpoints"},
        "blast_radius": {"level": "low", "reason": "scoped to the equipment API"},
        "risk": {"level": "low", "reason": "trivially reversible"},
        "dependencies": {"level": "low", "reason": "no external deps"},
        "architecture_impact": {"level": "low", "reason": "no new patterns"},
    }
})
print(profile["profile"], profile["confidence_label"])   # e.g. "small" "medium"

# ... clarify_requirements, plan_work, implement, execute_dag, review, verify — see §6

summary = engine.complete()   # session: -> completing -> closed, persisted to .gsd-engine/sessions/<id>.json
```

Every capability method on `Engine` follows the same shape: `engine.<capability>(work_input: dict) -> dict`. None of them require `engine.execute()` — that method is reserved for `execute_dag` specifically (it's the one capability that transitions the session to `"executing"`, because it's the one capability doing real, time-consuming work).

---

## 4. Full worked example — every capability, in order

This is the realistic end-to-end flow. Each step's `work_input` is built from **the previous step's own output** — nothing is invented here; every value below traces back to a field defined in §6.

```python
engine = Engine(".gsd-engine/registry.yaml")
engine.start()

# 1. ASSESS — how much process does this deserve?
profile = engine.assess_profile({
    "factors": {
        "scope": {"level": "medium", "reason": "auth token refresh, 2 endpoints"},
        "blast_radius": {"level": "low", "reason": "scoped to auth module"},
        "risk": {"level": "medium", "reason": "misconfiguration could break sessions"},
        "dependencies": {"level": "low", "reason": "no external deps"},
        "architecture_impact": {"level": "low", "reason": "uses existing auth patterns"},
    }
})
# -> {"profile": "medium", "confidence": {...}, "confidence_label": "...", "recommendations": [...]}

# 2. CLARIFY — what are we building?
clarified = engine.clarify_requirements({
    "stated_objective": "Add automatic token refresh before expiry",
    "known_facts": ["Current tokens expire after 1h with no refresh path"],
    "assumptions_proposed": [
        {"assumption": "Refresh endpoint already exists server-side", "basis": "confirmed in API docs"}
    ],
    "open_questions": [],   # empty list -> readiness == "sufficient"
})
# -> {"clarified_objective": "...", "assumptions": [...], "questions": [], "readiness": "sufficient", ...}

# If clarified["readiness"] == "insufficient", clarified["questions"] tells you exactly what to ask
# before proceeding — and, per AEP's escalation contract, this is also a trigger for re-assessing
# the profile:
if clarified["readiness"] == "insufficient":
    engine.assess_profile(new_factors, trigger="clarification_complete", evidence="scope grew")

# 3. PLAN — task breakdown, in dependency order
plan = engine.plan_work({
    "clarified_objective": clarified["clarified_objective"],
    "tasks_proposed": [
        {
            "id": "refresh-logic", "description": "Implement token refresh before expiry",
            "depends_on": [], "estimated_effort": "medium", "systems_touched": ["auth-service"],
            "reversibility": "easy", "architecture_impact": False, "architecture_impact_reason": None,
        },
        {
            "id": "tests", "description": "Add refresh-path tests",
            "depends_on": ["refresh-logic"], "estimated_effort": "low", "systems_touched": ["auth-service"],
            "reversibility": "easy", "architecture_impact": False, "architecture_impact_reason": None,
        },
    ],
})
# -> {"plan": [...ordered tasks...], "total_estimated_effort": "medium", "cross_system": False, ...}

# 4. IMPLEMENT — translate the plan into an executable DAG
#    (the caller adds execution-level specifics plan_work deliberately didn't produce)
translated = engine.implement({
    "tasks": [
        {
            "id": "refresh-logic", "description": "Implement token refresh before expiry",
            "depends_on": [], "cwd": "<consumer-repository>", "agent": "claude",
            "expected_outputs": ["backend/app/services/auth_refresh.py"],
            "verification": [{"command": "pytest backend/tests/test_auth_refresh.py", "name": "tests_pass", "required": True}],
        },
        {
            "id": "tests", "description": "Add refresh-path tests",
            "depends_on": ["refresh-logic"], "cwd": "<consumer-repository>", "agent": "claude",
            "expected_outputs": ["backend/tests/test_auth_refresh.py"],
            "verification": [{"command": "pytest backend/tests/test_auth_refresh.py -v", "name": "test_file_runs", "required": True}],
        },
    ],
})
# -> {"dag": {"nodes": [...]}, "task_count": 2, "readiness": "ready_to_execute", ...}

# 5. EXECUTE — actually run it (pre-existing capability, now evidence-enriched)
execution = engine.execute("execute_dag", {"dag": translated["dag"]})
# -> {"status": "completed", "returncode": 0, "stdout": "...", "stderr": "...",
#     "run_id": "...", "tasks": [...], "artifacts": [...], "verification": [...], "blockers": []}

# 6. REVIEW — does the evidence show good work?
#    Caller pre-joins execution["verification"] (raw store rows) with each task's declared
#    "required" flag from translated["dag"]["nodes"], into review's flat input shape:
verification_outcomes = [
    {
        "task_id": v["task_id"], "check_name": v["check_name"],
        "required": next(n["verification"][0]["required"] for n in translated["dag"]["nodes"]
                          if n["id"] == next(t["dag_node_id"] for t in execution["tasks"] if t["id"] == v["task_id"])),
        "passed": bool(v["passed"]), "output": v.get("output"),
    }
    for v in execution["verification"]
]
review_result = engine.review({
    "verification_outcomes": verification_outcomes,
    "execution_blockers": [
        {"task_id": t["id"], "failure_type": t["failure_type"], "error": t["error"]}
        for t in execution["blockers"]
    ],
    "findings_proposed": [
        # anything a human/agent reviewer noticed that no verification command could catch
    ],
})
# -> {"findings": [...], "severity_summary": {...}, "review_status": "approved"|"changes_required", ...}

# 7. VERIFY — the constitutional gate: is the work demonstrably complete?
verdict = engine.verify({
    "review_status": review_result["review_status"],
    "execution_blockers": [
        {"task_id": t["id"], "failure_type": t["failure_type"], "error": t["error"]}
        for t in execution["blockers"]
    ],
    "acceptance_criteria": [
        {"id": "AC-1", "description": "Tokens refresh automatically before expiry",
         "satisfied": True, "evidence_ref": "refresh-logic"},
        {"id": "AC-2", "description": "Refresh path is tested",
         "satisfied": True, "evidence_ref": "tests"},
    ],
    "session_context": {"session_id": engine.session.session_id, "profile": engine.session.profile},
})
# -> {"verified": True/False, "missing_evidence": [...], "completion_record": {...}}

if verdict["verified"]:
    summary = engine.complete()   # only now does the orchestrator decide the session is done
else:
    print(verdict["missing_evidence"])   # exactly what's missing, and why
```

Note the pattern in steps 6–7: **nothing auto-chains**. `implement` doesn't call `execute_dag`. `review` doesn't call `verify`. Every step is a deliberate call by whoever is orchestrating (today: a human or agent driving the Engine; the architecture leaves room for the Engine itself to do this later without any of the capability code changing).

---

## 5. Session model — profile as metadata, not state

`session.py`'s `SessionStateMachine` carries the *lifecycle* (`state`, `history`) exactly as before, plus new, orthogonal fields:

```python
session.profile                  # None | "small" | "medium" | "large"
session.profile_confidence        # {"small": float, "medium": float, "large": float} | None
session.profile_confidence_label  # "low" | "medium" | "high" | None
session.profile_history           # [] -> list of escalation/override evidence records
```

- `session.apply_profile_assessment(assessment, trigger, evidence, requested_by)` — called by `Engine.assess_profile()`. Escalates (`PROFILES = ["small", "medium", "large"]`, index comparison) only if the new profile ranks *higher* than the current one; otherwise updates confidence tracking only and returns `None` (no escalation record fabricated).
- `session.override_profile(profile, requested_by)` — called by `Engine.override_profile()`. Always authoritative: the operator can set *any* profile, including a lower one (unlike automatic assessment, which can never de-escalate). Emits a `profile_mismatch_warning` if the chosen profile doesn't match what the last assessment recommended.

`VALID_TRANSITIONS` in `session.py` is byte-for-byte what it was before this work — that's the thing every capability's tests assert never changes:

```python
VALID_TRANSITIONS = {
    "idle": ["planning"],
    "planning": ["executing", "closed"],
    "executing": ["completing", "planning"],
    "completing": ["closed"],
    "closed": [],
}
```

---

## 6. Capability reference

Every entry below: capability name (as passed to `dispatcher.dispatch()` / used as the `Engine` method name), registered provider, source file, exact input/output contract, and the error type raised on invalid input.

### 6.1 `assess_execution_profile`

- **Provider:** `profile_assessor` · **File:** `.gsd-engine/profile_assessment.py` · **Error:** `ProfileAssessmentError`
- **What it does:** deterministic 5-factor rubric → recommended profile + confidence distribution. Not NLP — the caller supplies each factor's level already assessed.

**Input:**
```python
{"factors": {
    "scope": {"level": "low"|"medium"|"high", "reason": str},
    "blast_radius": {...}, "risk": {...}, "dependencies": {...}, "architecture_impact": {...},
}}
```

**Output:**
```python
{
    "profile": "small"|"medium"|"large",
    "confidence": {"small": float, "medium": float, "large": float},   # sums to ~1.0
    "confidence_label": "low"|"medium"|"high",
    "factors": {...},   # echoed back
    "recommendations": [str, ...],   # "clarify: X is ambiguous — <reason>" for each "medium"-level factor
}
```

Scoring: each factor level → score (low=0, medium=1, high=2), normalized to a 0–1 weight, then a softmax-like distance-from-profile-center formula (`SHARPNESS = 6.0`) produces the confidence distribution. `HIGH_CONFIDENCE_THRESHOLD = 0.75`, `MEDIUM_CONFIDENCE_THRESHOLD = 0.5` — documented in the source as **implementation constants, not architectural decisions** (a richer/LLM-backed provider could use entirely different numbers without the Engine changing).

### 6.2 `clarify_requirements`

- **Provider:** `requirements_clarifier` · **File:** `.gsd-engine/clarify_requirements.py` · **Error:** `ClarifyRequirementsError`
- **What it does:** decides whether enough is known to proceed, and if not, exactly what to ask — without asking unnecessary questions.

**Input:**
```python
{
    "stated_objective": str,               # required, non-empty
    "known_facts": [str, ...],             # optional, default []
    "assumptions_proposed": [{"assumption": str, "basis": str}, ...],   # optional, default []
    "open_questions": [{"question": str, "blocking": bool}, ...],       # optional, default []
}
```

**Output:**
```python
{
    "clarified_objective": str,     # == stated_objective (this capability doesn't invent understanding)
    "known_facts": [...],
    "assumptions": [...],           # == assumptions_proposed, passed through as evidence
    "ambiguities": [...],           # == open_questions, all of them (blocking and non-blocking)
    "questions": [str, ...],        # only the *blocking* ones — what to actually ask right now
    "readiness": "sufficient"|"insufficient",
    "readiness_reason": str,        # literally "Requirements sufficiently understood. Proceed to planning." when clean
}
```

### 6.3 `plan_work`

- **Provider:** `work_planner` · **File:** `.gsd-engine/plan_work.py` · **Error:** `PlanWorkError`
- **What it does:** validates a task-dependency graph (duplicate ids / unknown deps / cycles all rejected, never silently coped with), topologically orders it, and rolls up factual metrics. **Never** judges whether the plan warrants profile escalation — that's `assess_execution_profile`'s job alone (Layer Purity).

**Input:**
```python
{
    "clarified_objective": str,     # required, non-empty
    "tasks_proposed": [
        {
            "id": str, "description": str, "depends_on": [str, ...],
            "estimated_effort": "low"|"medium"|"high",
            "systems_touched": [str, ...],
            "reversibility": "easy"|"moderate"|"hard",
            "architecture_impact": bool,
            "architecture_impact_reason": str | None,
        }, ...
    ],   # required, non-empty
}
```

**Output:**
```python
{
    "plan": [...tasks, topologically ordered...],
    "task_count": int,
    "total_estimated_effort": "low"|"medium"|"high",   # max() across tasks — asymmetric on purpose,
                                                         # same over-estimate-is-safe bias as AEP's no-de-escalation rule
    "systems_touched": [str, ...],   # deduped union, sorted
    "cross_system": bool,             # len(systems_touched) > 1
    "architecture_impact_detected": bool,
    "architecture_impact_reasons": [str, ...],
    "readiness": "ready_to_implement",   # always, once validation passes — invalid graphs raise, not "return invalid"
    "readiness_reason": str,
}
```

Graph validation (`_topological_order` shared with `implement.py` via `dag_utils.topological_order` — Kahn's algorithm, `DependencyCycleError` on any node that can't be ordered) rejects: duplicate task ids, `depends_on` referencing an unknown id, dependency cycles.

### 6.4 `implement`

- **Provider:** `dag_translator` · **File:** `.gsd-engine/implement.py` · **Error:** `ImplementError`
- **What it does:** **pure translator, not an executor.** Takes plan-work's task breakdown, augmented by the caller with execution-level specifics (`cwd`, `agent`, `verification`, `expected_outputs`) that `plan_work` deliberately didn't produce, and emits DAG nodes in `execute_dag`'s exact schema. It never runs anything and has zero Dispatcher/Registry access — running happens via a *separate* call to `engine.execute("execute_dag", {"dag": result["dag"]})`.

**Input:**
```python
{"tasks": [
    {
        "id": str, "description": str, "depends_on": [str, ...],
        "cwd": str,                              # required, non-empty
        "agent": "claude"|"codex"|"opencode",    # required
        "inputs": [str, ...],                    # optional, default []
        "expected_outputs": [str, ...],          # required, non-empty
        "verification": [{"command": str, "name": str, "required": bool}, ...],   # required, non-empty
        "retry_policy": {"max_attempts": int, "strategy": str, "on_exhausted": str},   # optional
    }, ...
]}
```

**Output:**
```python
{
    "dag": {"nodes": [
        {
            "id": str, "label": str, "description": str, "depends_on": [...],
            "inputs": [...], "expected_outputs": [...], "cwd": str, "agent": str,
            "verification": [...], "retry_policy": {...},
        }, ...
    ]},   # hand this directly to engine.execute("execute_dag", {"dag": result["dag"]}) — no further translation
    "task_count": int,
    "readiness": "ready_to_execute",
    "readiness_reason": str,
}
```

`retry_policy` defaults to `{"max_attempts": 1, "strategy": "same_worker", "on_exhausted": "blocked"}` if omitted — the same literal default `.runtime/runtime.py` and `dispatcher._default_dag()` already use.

### 6.5 `execute_dag` (pre-existing, now evidence-enriched)

- **Provider:** `runtime` · **Dispatch path:** `Dispatcher._dispatch_to_runtime()` (subprocess to `.runtime/runtime.py`) · **File:** `.gsd-engine/dispatcher.py`
- **Not a new capability** — pre-existing. What changed: its return value now carries the evidence that `.runtime/store.db` already recorded but was previously discarded.

**Input:** `{"dag": {"nodes": [...]}}` (defaults to a placeholder single-node DAG if omitted — see `_default_dag()`)

**Output** (fields marked NEW were added by this work; everything else is unchanged):
```python
{
    "status": "completed"|"failed", "returncode": int, "stdout": str, "stderr": str,   # pre-existing
    "run_id": str | None,                # NEW — resolved via TaskStore.find_latest_run_by_dag_path()
    "tasks": [{"id", "run_id", "dag_node_id", "status", "agent", "failure_type", "error", "attempt", ...}, ...],   # NEW
    "artifacts": [{"id", "task_id", "path", "sha256", "size_bytes", "created_at",
                    "produced_by": {"capability": "execute_dag", "provider": "runtime",
                                     "session_id": str, "timestamp": str}}, ...],   # NEW, with provenance
    "verification": [{"task_id", "check_name", "passed" (0/1), "output", "duration_ms", ...}, ...],   # NEW
    "blockers": [...tasks with status in ("blocked", "failed")...],   # NEW
}
```

**Provenance design decision:** artifact provenance (`capability`/`provider`/`session_id`/`timestamp`) is attached at this GSD layer, on the in-memory dict — **not** as a `.runtime/store.db` schema migration. Migrating the `artifacts` table would mean GSD code writing into Runtime's owned schema, which the Runtime Boundary invariant (§2.5) explicitly rules out. Same durable-evidence goal, no boundary violation.

Two read-only methods were added to `.runtime/store.py`'s `TaskStore` (no existing method touched, no schema change):
```python
store.get_artifacts_by_run(run_id) -> list[dict]          # the artifacts table had no reader at all before this
store.find_latest_run_by_dag_path(dag_path) -> str | None  # correlates a specific execute_dag call to its run
```

### 6.6 `review`

- **Provider:** `evidence_reviewer` · **File:** `.gsd-engine/review.py` · **Error:** `ReviewError`
- **What it does:** auto-derives blocking findings from `execute_dag`'s objective evidence (no restatement needed) and merges in whatever a reviewer flags qualitatively. Never mutates artifacts — pure aggregation.

**Input:**
```python
{
    "verification_outcomes": [
        {"task_id": str, "check_name": str, "required": bool, "passed": bool, "output": str | None}, ...
    ],   # optional, default [] — caller pre-joins execute_dag's raw verification rows with each
         # node's declared "required" flag from implement's DAG (see §4 step 6 for the exact join)
    "execution_blockers": [
        {"task_id": str, "failure_type": str, "error": str | None}, ...
    ],   # optional, default [] — straight from execute_dag's "blockers" list
    "findings_proposed": [
        {"description": str, "severity": "blocker"|"major"|"minor"|"advisory", "category": str,
         "evidence_ref": str | None}, ...
    ],   # optional, default [] — qualitative findings no verification command could catch
}
# At least one of the three must be non-empty, or ReviewError("nothing to review").
```

**Output:**
```python
{
    "findings": [
        {"description": str, "severity": ..., "category": str, "evidence_ref": str | None,
         "source": "verification"|"execution"|"reviewer"},   # traces every finding back to where it came from
        ...
    ],
    "severity_summary": {"blocker": int, "major": int, "minor": int, "advisory": int},
    "review_status": "approved"|"changes_required",   # "changes_required" iff any finding has severity "blocker"
    "review_status_reason": str,
}
```

Auto-derivation rules: a `required=True, passed=False` verification outcome → `severity: "blocker"`. A `required=False, passed=False` outcome → `severity: "advisory"` (surfaced, never blocking). Every `execution_blocker` → `severity: "blocker"`. **Only `blocker` severity gates approval** — `major` findings are surfaced but don't block; that distinction is exactly what "blocker" is for (documented as an implementation constant, `BLOCKING_SEVERITIES = ("blocker",)`, not an architectural rule).

### 6.7 `verify`

- **Provider:** `completion_verifier` · **File:** `.gsd-engine/verify.py` · **Error:** `VerifyError`
- **What it does:** the constitutional gate. One question: does the collected evidence demonstrate the work is complete?

**Input:**
```python
{
    "review_status": "approved"|"changes_required",    # required — straight from review's output
    "execution_blockers": [{"task_id": str, "failure_type": str, "error": str | None}, ...],   # optional, default []
    "acceptance_criteria": [
        {"id": str, "description": str, "satisfied": bool, "evidence_ref": str | None}, ...
    ],   # required, non-empty — caller-resolved and trusted (see design decision below)
    "session_context": {"session_id": str, "profile": str | None},   # optional, embedded in completion_record only
}
```

**Output:**
```python
{
    "verified": bool,
    "missing_evidence": [
        {"reason": "review_not_approved"|"execution_blocked"|"criterion_unsatisfied", "detail": str}, ...
    ],   # empty iff verified
    "completion_record": {
        "session_id": str | None, "profile": str | None, "review_status": str,
        "criteria_total": int, "criteria_satisfied": int, "execution_blockers": int,
        "verified": bool, "verified_at": str (ISO 8601),
    },
}
```

**The constitutional-gate behavior, precisely:** `verified` is `False` if `review_status != "approved"`, **or** `execution_blockers` is non-empty, **or** any acceptance criterion has `satisfied: False` — **regardless of what the other inputs say**. You cannot pass `verify` by asserting every acceptance criterion `satisfied: True` while `review_status` is `"changes_required"`; both conditions are checked independently and both must clear.

**Design decision on trust:** each acceptance criterion's `satisfied` value is trusted from the caller, not independently re-derived by `verify` from raw evidence (a deliberate choice over a richer alternative where `verify` would understand typed checks like `artifact_exists` — rejected as premature coupling/complexity for a first version; see the scoping discussion in project history if you need the full rationale).

---

## 7. Event taxonomy

Every event is published via `EventBus.publish(event_type, session_id, data)` and takes this shape:

```python
{
    "schema": "gsd.event.v1", "event_id": str (uuid4), "event_type": str,
    "timestamp": str (ISO 8601), "publisher": "engine", "session_id": str,
    "correlation_id": str,   # == session_id
    "data": dict,
}
```

Persisted to `.runtime/store.db`'s `events` table if that file exists (silently no-ops otherwise — never raises).

| Event type | Emitted by | Data |
|---|---|---|
| `gsd:session:started` | `Engine.start()` | `{"registry": ...}` |
| `gsd:session:completed` | `Engine.complete()` | `{"state_history": [...]}` |
| `gsd:task:dispatched` / `gsd:task:completed` | `Dispatcher._dispatch_in_process()` / `_dispatch_to_runtime()` | `{"capability", "provider", "status"?, "error"?}` |
| `gsd:profile:assessed` | `Engine.assess_profile()` | `{"assessment": <full assess_execution_profile output>}` |
| `gsd:profile:escalated` | `Engine.assess_profile()`, only when escalation occurs | full evidence record (§5) |
| `gsd:profile:override` | `Engine.override_profile()` | override evidence record |
| `gsd:profile:mismatch_warning` | `Engine.override_profile()`, only when the override disagrees with the last recommendation | `{"recommended_profile", "selected_profile", "confidence", ...}` |
| `gsd:requirements:clarified` | `Engine.clarify_requirements()` | full `clarify_requirements` output |
| `gsd:plan:created` | `Engine.plan_work()` | full `plan_work` output |
| `gsd:implement:translated` | `Engine.implement()` | full `implement` output |
| `gsd:review:completed` | `Engine.review()` | full `review` output |
| `gsd:verify:completed` | `Engine.verify()` | full `verify` output |

---

## 8. Extending the system

**To add a new capability** (following the exact pattern of the six above):
1. Write a pure function `capability_name(work_input: dict) -> dict` in a new `.gsd-engine/<name>.py` file, with a matching `<Name>Error(Exception)`. No Dispatcher/Registry/filesystem access inside it.
2. Register a provider for it in `registry.yaml` (`name`, `description`, `capabilities: [capability_name]`, `version`, `status: active`).
3. Add one `if capability == "capability_name": return self._dispatch_in_process(...)` branch in `Dispatcher.dispatch()`.
4. Add one `Engine.capability_name(work_input)` method that calls `self.dispatcher.dispatch(...)` and publishes one factual event. Do **not** call `self.session.transition(...)` unless the capability is genuinely doing real execution work (only `execute_dag` does today).
5. Add `"capability_name"` to `MODULE_NAMES` in `tests/_gsd_engine_harness.py`, write `tests/test_gsd_<name>.py` with one test per AC you defined before writing the code.

**To swap a provider** (e.g. replace the heuristic `assess_execution_profile` with an LLM-backed one later): change only the `registry.yaml` entry's `name`/`version` and the corresponding branch in `Dispatcher.dispatch()` to import the new module — the `Engine` method, the event names, and every caller of `engine.assess_profile()` are unaffected. This was verified directly: `test_ac6_provider_swap_needs_no_engine_change` in `test_gsd_clarify_requirements.py` and `test_gsd_plan_work.py` construct a `Dispatcher` against a registry with the provider renamed/re-versioned and confirm dispatch still succeeds unchanged.

---

## 9. Testing

**Harness:** `tests/_gsd_engine_harness.py` provides `gsd_engine_modules()`, a context manager that loads every `.gsd-engine/*.py` module fresh, and `started_engine(m, tmp_path)`, an `Engine` past `start()` with its event bus redirected off the real `.runtime/store.db` (so tests never pollute production data). It's a context manager rather than a plain import because `.gsd-engine` modules use bare imports (`from session import ...`) that need `.gsd-engine` on `sys.path` — the harness adds it, then **removes it and restores `sys.modules`** on exit, so generic names like `session`/`registry`/`dispatcher` never leak into the rest of the pytest run.

```python
from tests._gsd_engine_harness import gsd_engine_modules, started_engine, GSD_ENGINE_DIR

def test_something(tmp_path):
    with gsd_engine_modules() as m:
        engine = started_engine(m, tmp_path)
        result = engine.plan_work({...})
        assert result["readiness"] == "ready_to_implement"
```

**Run everything:**
```bash
python3 -m pytest tests/test_gsd_execution_profiles.py tests/test_gsd_clarify_requirements.py \
    tests/test_gsd_plan_work.py tests/test_gsd_implement.py tests/test_gsd_execute_dag_evidence.py \
    tests/test_gsd_review.py tests/test_gsd_verify.py tests/test_gsd_registry.py -q
# 48 passed
```

**Test file → capability map:**

| File | Covers |
|---|---|
| `test_gsd_registry.py` | Pre-existing `Registry` contract (unchanged) |
| `test_gsd_execution_profiles.py` | `assess_execution_profile` + session escalation/override (AC-1..7 + manual override) |
| `test_gsd_clarify_requirements.py` | `clarify_requirements` (AC-1..7) |
| `test_gsd_plan_work.py` | `plan_work` (AC-1..7) |
| `test_gsd_implement.py` | `implement` translation (AC-1..7) |
| `test_gsd_execute_dag_evidence.py` | `Dispatcher._read_evidence()` — seeds a real `TaskStore`, asserts tasks/artifacts/verification/blockers/provenance are correlated correctly |
| `test_gsd_review.py` | `review` (AC-1..7, including the specific claim that a required verification failure auto-derives a blocker without caller restatement) |
| `test_gsd_verify.py` | `verify` (AC-1..7, including the specific claim that the constitutional gate overrides satisfied criteria) |

Every capability's ACs were defined **before** the code was written (see the scoping conversation for each), and every test file's docstring lists exactly which AC each test proves.

---

## 10. File map

```
.gsd-engine/
  session.py               Lifecycle state machine + profile metadata (Adaptive Execution Profiles)
  registry.py               Registry — unchanged, capability -> provider resolution
  registry.yaml              Provider list — 6 new entries added, nothing existing changed
  event_bus.py               EventBus — unchanged
  dispatcher.py               Dispatcher — 5 new capability branches, evidence enrichment for execute_dag
  engine.py                    Engine — 7 new methods (assess_profile, override_profile, clarify_requirements,
                                 plan_work, implement, review, verify), none touch the state machine except
                                 the pre-existing execute()/execute_dag path
  dag_utils.py                 Shared Kahn's-algorithm topological ordering (plan_work + implement)
  profile_assessment.py        assess_execution_profile capability
  clarify_requirements.py      clarify_requirements capability
  plan_work.py                 plan_work capability
  implement.py                 implement capability (pure translator)
  review.py                    review capability
  verify.py                    verify capability

.runtime/
  store.py                     +2 read-only methods: get_artifacts_by_run(), find_latest_run_by_dag_path()
                                 (everything else in this file is untouched — this is the only file outside
                                 .gsd-engine/ that this work modified)

tests/
  _gsd_engine_harness.py       Shared module-loading harness for all gsd-engine tests
  test_gsd_execution_profiles.py
  test_gsd_clarify_requirements.py
  test_gsd_plan_work.py
  test_gsd_implement.py
  test_gsd_execute_dag_evidence.py
  test_gsd_review.py
  test_gsd_verify.py
```

---

## 11. Explicitly out of scope (don't assume these exist)

- **No LLM-backed provider for any capability.** Every one of the six is a deterministic heuristic. `assess_execution_profile`'s docstring and `clarify_requirements`'/`plan_work`'s design notes are explicit that this is a first-iteration provider — swappable per §8, not upgraded.
- **No auto-chaining.** The Engine never calls one capability as a result of another's output. Every step in §4 is a deliberate call by the orchestrator. Building an orchestrator that does this automatically (state-machine-driven or otherwise) is future work, not present in this codebase.
- **No `clarify-requirements`→`assess_execution_profile` re-triggering.** The architecture document names "clarification completes" as a profile re-assessment trigger (sec 5.1), but the *wiring* of that trigger — i.e., code that automatically calls `assess_profile` after `clarify_requirements` returns — does not exist. The capability composition in §4 shows this being done manually by the caller.
- **`verify` does not independently check acceptance criteria** against raw evidence (§6.7 design decision) — it trusts caller assertions.
- **No new provider transport.** Every capability provider added is an in-process pure Python function. There is still no mechanism in `Dispatcher` for calling out to an external LLM/API as part of capability resolution — only `execute_dag` uses a subprocess, and that's pre-existing.
