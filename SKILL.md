---
name: gsd-master
alias: gsd:master
version: 3.4.0-preview.1
description: Orchestrates multi-file, multi-plan implementation phases end-to-end — spec validation, wave execution, mandatory Review Orchestrator + Codex validation, test harness, and autonomous Greploop PR review. Use for phase work spanning 4+ files across backend+frontend, new DB tables/services/external integrations, security- or physical-impact code, or any PR-targeted work needing autonomous review. Also runs skill self-improvement analysis (`improvement-candidate:`). Do not use for single-file fixes, README/config tweaks, known-issue debugging, or pure research — those are lighter-weight tasks this pipeline is deliberately too heavy for. See references/CHANGELOG.md for version history.
argument-hint: "<phase-number|plan:<description>|improvement-candidate:<description>>"
config:
  vault_path: "vault"                   # Phase file root (override via env: GSD_VAULT_PATH)
  phase_specification_suffix: ".specification.json" # Canonical phase-specification.v1 sidecar
  phase_specification_validator: "development-platform-core" # Core validator; fail closed if unavailable
  precheck_skill_path: "skills/gsd/precheck-gate.md"  # External precheck skill (optional)
  research_skill_path: "skills/gsd/research-phase.md"  # Native research workflow
  default_model: "gpt-4o"               # Codex default (override via env: GSD_CODEX_MODEL)
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Task
  - Agent
  - TodoWrite
  - AskUserQuestion
  - Skill
---

<objective>
Phase orchestration and governed project-building lifecycle. The skill consumes
the platform-core `gsd-session-governance.v1` envelope so intent capture,
Small/Medium/Large profile selection, execution, verification, and closeout are
one GSD lifecycle rather than a separate conversation mode. Step 0.5
canonical `phase-specification.v1` validation gates every phase before scope triage; Greploop
autonomous PR review + fixing runs after Codex validation. See
`references/CHANGELOG.md` for what each version added.

**Full Pipeline:**
Step 0: Argument routing → Step 0.5: Spec validation → Step 0.6: Dependency governance
         ↓
Steps 1-6: Orchestration (DAG, waves, test harness)
         ↓
Step 7: Review Orchestrator (selects providers by change classification, dispatches in parallel, aggregates disposition)
         ↓
Step 8: Codex validation → Step 9: Greploop
         ↓
Step 10: Documentation & Deployment → Step 11: Execution contract
</objective>

<design_to_implementation_boundary>
GSD governs the engineering lifecycle; the project governs its own domain
invariants and approval vocabulary. Do not require exhaustive implementation
specification when the remaining questions are repository-level mechanics that
can be safely resolved and verified during bounded implementation.

Use this lifecycle:

```text
CONTRACT / REQUIREMENTS
        ↓
DESIGN
        ↓
DESIGN REVIEW
        ↓
PROJECT-APPROPRIATE IMPLEMENTATION AUTHORIZATION
        ↓
BOUNDED IMPLEMENTATION
        ↓
TEST / VERIFY
        ↓
INDEPENDENT IMPLEMENTATION REVIEW
```

Classify review findings before routing them:

- **Architecture/requirement blocker** — the intended behavior, boundary, or
  requirement is unresolved; return to design or requirements.
- **Implementation defect** — the approved design is clear but the change is
  incorrect or incomplete; fix the implementation and re-verify.
- **Implementation detail** — a repository-level choice needed to realize an
  approved design; resolve it within the bounded implementation, record the
  choice, and verify it.

Design approval does not imply one universal authorization token. Before
production-affecting implementation, the project must provide whatever
explicit implementation authorization its governance model requires. GSD
must not invent or impose a project-specific token.
</design_to_implementation_boundary>

<mandatory_owner_decision_gates>
When a mandatory owner-decision gate is reached, generate a guided
owner-decision request rather than only reporting a blocker. First search the
authoritative project sources available in the execution context for existing
decisions, including the phase/design artifact, project governance documents,
the declared decision log, and relevant implementation or review evidence.
Use exact paths, section or heading names, line numbers when available, and a
concise summary as provenance for every material claim.

**Normative rule:** “When a mandatory owner-decision gate is reached, generate
a guided owner-decision request rather than only reporting a blocker. Explain
why each decision matters, present the evidence and provenance, provide
recommended options where appropriate, describe the consequences of each
option, and accept plain-language answers. Never invent or silently approve
policy. After the owner answers, record the decision with provenance and
continue all work within the approved scope without intermediate approval
pauses.”

For each decision, distinguish explicitly between:

- **proposal** — an owner response suggests a change but does not yet alter
  canonical authority;
- **confirmed decision** — an authoritative source records a sufficiently specific,
  applicable decision;
- **superseding decision** — the owner explicitly confirms that the response
  replaces a named canonical decision and the canonical source is updated or
  references the replacement with attribution;
- **deferred decision** — the owner explicitly postpones the decision and the
  affected work remains blocked or bounded accordingly;
- **incomplete** — a source addresses the topic but leaves a required choice,
  scope, owner, or condition unspecified;
- **conflicting** — authoritative sources prescribe materially different
  choices or conditions; and
- **absent** — no authoritative decision was found.

An owner response that conflicts with a canonical authority source is a
**proposal** until the owner explicitly confirms that it supersedes that
source. A project artifact MUST NOT silently override a canonical authority
source.

Before recording a superseding decision in a project artifact:

1. Identify the canonical authority source.
2. Ask whether the owner intends to supersede it.
3. Update the canonical source or reference the superseding decision there with
   attributable owner identity, decision date, version or revision identity,
   scope, rationale, and the superseded reference.
4. Reconcile the project artifact against the canonical source.
5. Re-run the applicable independent review after the artifact changes.
6. Only then proceed to the owner gate or implementation.

Explain each unresolved decision in plain language: what must be decided, why
it matters, what work it affects, and what remains safe to do while it is
unresolved. Provide a recommended safe option when the evidence supports one,
clearly label it as a recommendation, and describe the consequences of each
available option. Never invent a decision, provenance, owner authority, or
approval. Never silently approve a policy or infer approval from silence.

Use this reusable request format:

```text
## Owner decision required

### Decision N — <plain-language title>

Evidence status: confirmed | incomplete | conflicting | absent

Owner response classification: proposal | confirmed decision | superseding decision | deferred decision

Why this matters:
<plain-language impact and the work affected>

Evidence found:
<source path, section or heading, line number when available, and concise summary>

Recommended option:
<recommendation, clearly marked as a recommendation; say "No recommendation" when evidence is insufficient>

Options:
1. Approve: <meaning and consequence>
2. Modify: <what must be specified>
3. Defer: <what work remains blocked and what safe work may continue>

Reply in plain language, for example:
“Approve 1, modify 2 to ..., defer 3.”
```

Accept a plain-language response; the owner must not need to know YAML, policy
terminology, or an internal decision schema. Translate the response into the
project's governed decision format without changing its meaning. Preserve the
owner's wording or a faithful normalized form, decision status, timestamp,
actor identity, scope, and exact evidence/provenance references. Record any
remaining ambiguity instead of resolving it by assumption.

After the owner answers, validate that the answer is within the owner's
authority and that it does not cross a separately protected boundary. Then
classify the response as proposal, confirmed decision, superseding decision,
or deferred decision. Never record a superseding decision in a derived project
artifact alone. For a superseding decision, complete the canonical-source,
owner-confirmation, attribution, reconciliation, and independent-review steps
above before proceeding. Record the decision with provenance and continue all
implementation, testing, review, documentation, and commit work covered by
the approved scope without requesting intermediate approval. Stop only when
the owner has not answered, the answer is ambiguous, the decision remains
outside the agent's authority, the required supersession steps are incomplete,
or execution would cross a separately protected boundary. A technical blocker
list may accompany this request, but it must not replace the guided request.
</mandatory_owner_decision_gates>

<triggers>
**Use GSD Master when:**
- Phase spans 4+ files across backend + frontend
- New DB tables, services, or external API integrations
- Security-sensitive or physical-impact code (auth, payments, device control)
- Multi-plan execution with waves + reconciliation needed
- PR-targeted work needing Greploop autonomous review

**Do NOT use GSD Master for:**
- Single-file bug fixes or typo corrections
- README updates, dependency bumps, config tweaks
- Debugging a known issue (use `gsd:debug` instead)
- Pure research or investigation (use `gsd:research-phase` instead)
- Trivial work where Lightweight mode still feels heavy

**Argument mode quick-pick:**
- Have a phase number? → `{number}` mode (full validation pipeline)
- Have a draft intent? → `plan:{description}` (creates a phase specification; Step 0.5 still applies)
- Skill is misbehaving? → `improvement-candidate:{description}` (Step 13)
</triggers>

<execution_context>
@{precheck_skill_path}
</execution_context>

<context>
Argument: $ARGUMENTS

**Argument modes:**
- `{number}` → Phase engineering and execution (e.g., `211`, `208`)
- `plan:{description}` → Draft intent mode; creates a phase specification and MUST pass the same phase gate before execution
- `improvement-candidate:{description}` → Skill self-improvement (e.g., `improvement-candidate: precheck gate is slow`)

**Artifact root:**
1. `${GSD_VAULT_PATH:-$HOME/.gsd-vault}/00-GSD-Phases/Phase-{arg}.md`
   — canonical project vault
2. If missing, stop and report the missing authority artifact.

**Canonical semantic contract:**
Alongside the human-readable phase artifact, resolve:

```text
${GSD_VAULT_PATH:-$HOME/.gsd-vault}/00-GSD-Phases/Phase-{arg}.specification.json
```

The sidecar MUST validate as `phase-specification.v1`. It is authoritative for
intent, scope, requirements, acceptance criteria, evidence contracts, task
intent, dependencies, verification, independent review, convergence,
remediation, acceptance authority, workflow identity, and provenance. The
Markdown phase file is explanatory context and may not redefine those facts.

**Blocker path:** project-declared `${GSD_VAULT_PATH}/01-Control/blockers.md`.
If the project does not declare a vault/control root, stop and report the
missing authority path.
</context>

<process>
# Step 0: Route by argument type

## 0.0: Start a Run Record

Every invocation, including `plan:`, `improvement-candidate:`, and invocations
that stop during validation, must be recorded before routing or other work.
Follow `references/run-audit-optimizer.md` for the run schema and transcript
audit process.
Resolve the project root from the current project context and create:

```text
.gsd-engine/runs/{run_id}.json
.gsd-engine/runs/index.jsonl
```

Generate `run_id` as a UTC timestamp with a random UUID suffix so concurrent
runs cannot collide. Immediately write the per-run JSON record with
`status: "running"`, `started_at` (UTC ISO-8601), argument mode, phase number
or a short plan label, `skill_id`, `skill_version`, `skill_hash`, and the
current GSD Master Git commit when available. Compute `skill_hash` as the
SHA-256 of the exact `SKILL.md` bytes used for the run. Do not copy credentials
or full prompt/specification contents
into the record. Append a `started` event with the same `run_id` to
`index.jsonl`; create the index if needed. Keep the run ID available to every
step and use it in all evidence references.

## 0.0.1: Close Out the Run

Every normal completion, validation stop, blocker, or handled error must pass
through run closeout. Update the per-run JSON atomically (write a temporary
file in the same directory, then rename it) with terminal `status` (`completed`,
`blocked`, `failed`, or `incomplete`), `finished_at`, concise outcome/failure
point, and relative paths to artifacts produced. Then append the corresponding
terminal event to `index.jsonl`. Close out improvement-candidate runs through
the same procedure. If the process is interrupted before closeout, the initial
record and `started` index event remain as evidence; mark stale `running`
records `incomplete` on the next invocation without rewriting their original
timestamps. If the project filesystem is read-only, explicitly report that
the ledger could not be written; do not claim the run was recorded.

After recording the execution outcome, audit the run transcript against every
applicable requirement as specified in `references/run-audit-optimizer.md`.
Write the audit artifact, add its path to the run record, and append its
`transcript_audited` event to the index before returning the final report. An
unavailable transcript produces an explicit `unverifiable` audit.

Example run record:

```json
{
  "schema": "gsd-master-run.v1",
  "run_id": "2026-09-15T11-42-08Z-550e8400-e29b-41d4-a716-446655440000",
  "skill_id": "gsd:master",
  "skill_version": "3.4.0-preview.1",
  "skill_hash": "sha256:<sha256-of-executed-SKILL.md>",
  "skill_commit": "<git-commit-or-null>",
  "argument_mode": "phase",
  "phase": "265",
  "started_at": "2026-09-15T11:42:08Z",
  "finished_at": "2026-09-15T12:10:31Z",
  "status": "completed",
  "outcome": "Phase completed and verified",
  "artifacts": [
    ".gsd-engine/work/phase-265.execution-contract.json",
    ".gsd-engine/work/phase-265.review-evidence.json",
    ".gsd-engine/work/phase-265.lessons-learned.json",
    ".gsd-engine/runs/<run_id>.audit.json"
  ]
}
```

**If argument starts with "improvement-candidate:"**
→ Jump to **Improvement Mode** (Step 13)

**If argument starts with "plan:"**
→ Parse description after `plan:` as draft intent
→ Create or resolve a canonical `phase-specification.v1`
→ Run the same specification, dependency, and phase-gate checks as number mode
→ Do not execute until the phase gate authorizes implementation
→ Steps 1-10 (including review, Codex, Greploop, and execution contract) apply

**If argument is a phase number:**
→ Continue to **Step 0.5** (spec validation)

---

# Step 0.5: Load & Validate Phase Specification

**Applies when:** argument is a phase number or `plan:` draft mode.
**Skips only when:** argument is `improvement-candidate:` mode.

## 0.5.1: Resolve Phase File Path

Try in order:
1. `${GSD_VAULT_PATH:-$HOME/.gsd-vault}/00-GSD-Phases/Phase-{arg}.md`
2. Stop if the canonical phase artifact is missing.

If file not found → `execution_failed` with `failure_point: step0.5_file_not_found`

## 0.5.1a: Resolve Canonical Phase Specification

Resolve the sidecar next to the phase artifact:

```text
Phase-{arg}.specification.json
```

For `plan:` mode, write the draft specification to the declared phase root
only after assigning its phase identity. Validate it with the Core
`phase-specification.v1` validator configured by
`phase_specification_validator`; if the validator is unavailable, stop with
`step0.5_validator_unavailable` rather than falling back to Markdown parsing.

Record and propagate the complete identity tuple:

```text
(phase_id, specification_id, version, specification_hash)
```

The tuple is immutable for the run. A changed specification requires an
explicit new version and a new phase-gate decision.

## 0.5.2: Check Required Fields

The six Markdown checks below remain compatibility checks for the explanatory
phase artifact. They do not replace validation of the canonical sidecar.

Read phase file. Check for each required field:

| # | Field | Check | Fail Token |
|---|-------|-------|------------|
| 1 | Problem Statement | Find `## Problem Statement` heading + non-empty content below | `step0.5_missing_problem` |
| 2 | Acceptance Criteria | Find `## Acceptance Criteria` heading with ≥1 `- [ ]` checkbox | `step0.5_missing_ac` |
| 3 | Dependencies | Find `## Dependencies` heading with ≥1 sub-section (codebase/DB/external/frontend) | `step0.5_missing_deps` |
| 4 | Phase Gate | Find `## Phase Gate` heading with `gate_type`, `min_phase`, `failure_action` | `step0.5_missing_gate` |
| 5 | Trade-offs | Find `## Trade-offs` heading with ≥1 "not doing" item | `step0.5_missing_tradeoffs` |
| 6 | Version & Date | Find `Version:` and `Last Updated:` in frontmatter or overview | `step0.5_missing_version` |

## 0.5.3: Validate Dependencies (Pre-Flight)

For each dependency declared in section 3:
- **Codebase scope file path** → check file exists at path
- **DB migration** → check migration file exists in `supabase/migrations/`
- **External service** → check credentials/config exist
- **Frontend component** → check component file exists at path

## 0.5.4: Check Freshness

If `Last Updated` > 14 days from today:
→ `step0.5_stale_spec` — WARNING (non-blocking, report in validation results)

## 0.5.5: Validation Result

```
results = {
    "phase": "{arg}",
    "file": "{path}",
    "specification": {
        "file": "{phase_specification_path}",
        "schema": "phase-specification.v1",
        "phase_id": "{phase_id}",
        "specification_id": "{specification_id}",
        "version": "{version}",
        "specification_hash": "{hash}",
        "validated": true|false
    },
    "fields": {
        "problem_statement": "pass|fail:step0.5_missing_problem",
        "acceptance_criteria": "pass|fail:step0.5_missing_ac",
        "dependencies": "pass|fail:step0.5_missing_deps",
        "phase_gate": "pass|fail:step0.5_missing_gate",
        "trade_offs": "pass|fail:step0.5_missing_tradeoffs",
        "version_date": "pass|fail:step0.5_missing_version"
    },
    "preflight": {
        "codebase": ["✅ path exists" | "❌ MISSING: {path}"],
        "migrations": ["✅ migration exists" | "❌ MISSING: {path}"],
        "external": ["✅ configured" | "❌ MISSING: {service}"],
        "frontend": ["✅ component exists" | "❌ MISSING: {path}"]
    },
    "stale": "pass|warn:step0.5_stale_spec",
    "passed": true|false
}
```

### If the canonical specification validates, all compatibility fields pass, AND pre-flight passes:
→ Continue to **Step 1** (scope triage) and preserve the specification identity in every artifact.

### If the canonical specification is missing/invalid OR ANY compatibility field fails:
→ Return failure contract:

```
## Specification Validation Failed ❌

**Phase:** {arg}
**Failure Point:** step0.5_validation_failed
**Missing fields:** {list of fail tokens}

### Required Fixes:
{for each fail token, the exact heading + content needed}

### Next Action:
Fill in missing fields in `{phase_file_path}` using template:
`{vault_path}/00-GSD-Phases/PHASE-SPECIFICATION-TEMPLATE.md`

The remediation must also produce or correct the canonical
`Phase-{arg}.specification.json`; Markdown-only repairs are insufficient.
```

### If pre-flight finds MISSING dependencies:
→ Report each missing dependency with exact path. Ask user:
- "Fix and retry?"
- "Proceed anyway (dependencies may be created during execution)?"

## 0.5.6: Phase Gate Authorization and One-Shot Execution

When the canonical specification and compatibility checks pass, the declared
phase gate is the implementation authorization boundary. Record the gate
decision, its evidence, and the complete specification identity in the run
record before execution begins.

After the phase gate passes, execute the authorized scope end-to-end without
intermediate permission prompts. Do not ask whether to continue between tasks,
waves, tests, review, remediation, or closeout. Resolve ordinary repository
mechanics autonomously from the approved specification and repository
evidence.

Stop and request clarification only when uncertainty materially changes intent,
requirements, scope, architecture, security, data integrity, specification
identity, or acceptance. A transient failure follows the declared retry policy;
an implementation or verification failure follows remediation; an unrelated
finding is recorded for later work rather than silently expanding scope.

The phase gate authorizes execution. It does not establish `ACCEPTED`.
Acceptance remains exclusively the Core AcceptanceAuthority result persisted
through `development-workflow.v1`.

Before invoking the production Engine for DAG execution, assemble one
authorization payload containing:

```text
{
  specification: <canonical phase-specification.v1>,
  plan: <derived plan with unchanged governed task fields>,
  dag: <derived scheduling DAG>,
  skill_path: <exact SKILL.md used for this run>
}
```

The Engine must call `authorize_phase_execution()` with that payload before
entering `executing`. A caller must never invoke the runtime directly with a
DAG-only payload.

---

# Step 0.6: Dependency Governance

**Runs before Step 1.** Checks GSD Master's declared dependencies against what's actually installed. Warns — does not block — unless a required dependency is missing.

Three sources of truth:
- **Skill Manifest** (`.gsd-engine/skill-manifest.yaml`) — declares what GSD Master expects
- **Compatibility Matrix** (`.gsd-engine/compatibility-matrix.yaml`) — records validated version pairs
- **Skill Registry** (`.gsd-engine/skill-registry.yaml`) — records what was found (auto-generated)

## 0.6.1: Load Manifest

Read `{project_root}/.gsd-engine/skill-manifest.yaml`. If missing, issue WARNING and skip to Step 1 (dependency governance is optional — older deployments may not have it).

## 0.6.2: Discover Installed State

For each dependency in the manifest, check whether the skill exists at its expected `source` path:

```yaml
discovery:
  - name: codex
    found: true
    version: "latest"          # read from SKILL.md frontmatter if available
    path: ~/.claude/skills/codex
  - name: trailofbits-semgrep
    found: false
    version: ~
    path: ~
```

For required dependencies, absence is a WARNING (non-blocking — user may have relocated or renamed the skill).
For optional dependencies, absence is informational only.
For elective dependencies, absence is silently accepted.

## 0.6.3: Check Compatibility

Compare discovered versions against the Compatibility Matrix:

```
# For each found dependency:
if dependency is required AND not found:
    → WARN: "[name] not found at {source}. GSD Master expects it. Install or update skill-manifest.yaml."

if dependency is found AND version is pinned in compatibility matrix:
    if installed_version not in matrix[gsd_master_version][name]:
        → WARN: "[name] version {installed} not in compatibility matrix for GSD Master {gsd_version}."
        → INFO: "Validated versions: {matrix versions}"

if dependency is found AND no version info:
    → INFO: "[name] installed (version unknown). Add to compatibility-matrix.yaml after validation."
```

Do NOT auto-upgrade. Never modify installed skills.

## 0.6.4: Persist Registry

Write discovered state to `.gsd-engine/skill-registry.yaml` so the orchestrator and human operator can inspect it later.

## 0.6.5: Report

```
## Dependency Governance Report

**Required:**
  ✅ codex (found)
  ⚠️  gsd:precheck-gate (not found — optional, continuing)

**Review Providers:**
  ✅ code-review-excellence (found)
  ⚠️  impeccable (not found — elective, design review will be unavailable)
  ⚡ trailofbits-semgrep (not found — elective, security review will be unavailable)

**Compatibility:**
  ✅ All found dependencies are compatible with GSD Master 3.4.0-preview.1

**Next:** Continue to Step 1.
```

---

## Update Procedure

When a dependency skill releases a new version, do NOT update automatically. Follow this controlled adoption process:

1. **Discover** — Run the compatibility check. Note which skills have newer versions.
2. **Review** — Read the upstream changelog. Check for:
   - Breaking changes to prompts, contracts, or output format
   - Changed assumptions about context, tools, or agent model
   - Deprecated features GSD Master may rely on
3. **Validate** — Run GSD Master's test phases against the new version
4. **Approve** — Update `compatibility-matrix.yaml` with the validated version
5. **Adopt** — Normalize — GSD Master now treats the new version as compatible

### Example: Updating impeccable

```
1. Upstream releases impeccable 4.1.0
2. Read CHANGELOG: new detection rules added, no breaking changes
3. Run `gsd:master test-phase` (design review path) against 4.1.0
4. Update compatibility-matrix.yaml:
      impeccable:
        - 4.0.2
        - 4.0.0
        + 4.1.0
5. Done — GSD Master now supports 4.1.0
```

### Rollback

If a new version causes issues:
```
1. Note the problem in active-decision-log.md
2. Unpin: remove problematic version from compatibility-matrix.yaml
3. Previous versions remain valid
4. No changes to SKILL.md or GSD Master behavior needed
```

---

# Step 1: Scope triage + artifact root

Use only the project-declared `${GSD_VAULT_PATH}/00-GSD-Phases/` root from
Radix startup context. If the canonical phase artifact is absent, stop and
report it. Do not fall back to `.planning` or a repository-local phase tree.

**Read phase file and check status:**

If `status: COMPLETED` or contains `✅ COMPLETED`:
→ Jump to **COMPLETED Phase Fast-Path** (Step 12)

---

**Classify execution mode via the GSD Engine (authoritative).**

Derive the five execution factors from the phase file and execution context.
Each factor is `low | medium | high` with a reason. This is the same signal the
old binary triage used — now graded instead of all-or-nothing:

| Factor | Ask |
|---|---|
| `scope` | How broad is the change (files, modules touched)? |
| `blast_radius` | How costly is it if the change is wrong (rollback / reversibility)? |
| `risk` | Any security-sensitive or physical-device-write code? |
| `dependencies` | New DB tables, services, or external API integrations? |
| `architecture_impact` | Cross-module interfaces, multiple plans/waves? |

Write the factors to `.gsd-engine/work/phase-{arg}.factors.json`:

```json
{
  "factors": {
    "scope":              {"level": "low|medium|high", "reason": "..."},
    "blast_radius":       {"level": "low|medium|high", "reason": "..."},
    "risk":               {"level": "low|medium|high", "reason": "..."},
    "dependencies":       {"level": "low|medium|high", "reason": "..."},
    "architecture_impact":{"level": "low|medium|high", "reason": "..."}
  }
}
```

If a Session ID is present in the startup context (`startup_context_file`) AND
`.gsd-engine/engine.py` exists, classify through the engine (authoritative path):

```bash
python3 .gsd-engine/engine.py \
  --assess-profile .gsd-engine/work/phase-{arg}.factors.json \
  --session-id <Session ID from the startup context>
```

The engine validates the factors, computes the profile, persists it to the
session's profile sidecar, writes the audit events, and prints JSON to stdout.
Use the printed `profile` value and route deterministically:

| profile | execution mode |
|---|---|
| `small` | **LIGHTWEIGHT** |
| `medium` | **STANDARD** |
| `large` | **FULL** |

**The mapping is deterministic and mandatory.** Do not reinterpret the profile
for convenience (e.g., "this medium feels complicated — use FULL"). If the
situation changes during execution, request a new assessment or an operator
override through the engine (`--profile small|medium|large`); never re-route
informally.

**Degraded mode (engine absent, or no Session ID available):** classify inline
with the same rubric — score = Σ(low=0, medium=1, high=2) across the five
factors; 0–2 → small, 3–7 → medium, 8–10 → large. Record
`Profile source: inline (no engine)` in the Step 11 report. No persistence or
audit occurs in this mode.

**Mode behaviour:**

- **LIGHTWEIGHT (small):** plan → implement → verify → summarize.
  Skip: pre-check gate (Step 1.5), Control Matrix scan (Step 3),
  Architecture Challenge (Step 4), Ralph Loop, Wave Reconciliation.
- **STANDARD (medium):** structured engineering work. Run the pre-check gate
  (Step 1.5); run the Control Matrix scan (Step 3) only if `risk` is high or
  security-sensitive code is flagged; run Architecture Challenge (Step 4) only
  if the pre-check gate returns novel issues; single or multi-wave execution
  with the checkpoint flow (not Ralph Loop); Wave Reconciliation only if 2+
  plans.
- **FULL (large):** full pipeline. Pre-check gate (Step 1.5), Control Matrix
  scan (Step 3, physical scan), Architecture Challenge (Step 4, novel issues),
  Ralph Loop (autonomous).

Step 0.6 (dependency governance) runs regardless of mode.
**Review (Review Orchestrator + an independent reviewer) always runs when files
changed, regardless of mode. See `review-orchestrator-spec-v1.md` for
architecture. The implementation agent is never the sole independent reviewer.

## 1.7: Emit Factual Classification (for Review Orchestrator)

Analyze the change scope from Step 1 triage and emit factual flags. Assess describes reality — it never names a review provider. The provider registry maps these flags to providers:

```
FactualClassification:
  touches_backend: bool       # modified Python API/service code
  touches_frontend: bool      # modified TypeScript/React/UI code
  touches_infrastructure: bool # modified Docker, K8s, CI/CD, deploy config
  touches_database: bool      # modified SQL migrations, schema, queries
  touches_documentation: bool # documentation-only change
  touches_auth: bool          # modified authentication/authorization
  touches_encryption: bool    # modified encryption/secrets handling
  touches_pii: bool           # modified PII data paths
  touches_network: bool       # modified network config, firewall, ports
  has_ui_changes: bool        # modified visual components, styles
  frontend_creation: bool     # new or substantially redesigned frontend surface
  has_api_changes: bool       # modified API contracts, routes, serialization
  touches_architecture_boundary: bool  # modified cross-module interfaces
  scope: str                  # single_file | multi_file | cross_module | system_wide
  summary: str                # one-line description of what changed
```

Derive this from the phase file, git diff, and execution context. Pass to Step 7.

# Step 1.5: Pre-check gate (MANDATORY for STANDARD and FULL execution)

**Pre-flight check first:**
```bash
# Verify required external dependency exists (if configured)
if [ -n "{precheck_skill_path}" ] && [ ! -f "{precheck_skill_path}" ]; then
    echo "FATAL: precheck skill missing at {precheck_skill_path}"
    echo "Step 1.5 cannot run without the precheck skill."
    echo "Either restore the file or clear the precheck_skill_path config."
    exit 1
fi
```

If `precheck_skill_path` is empty/unset, Step 1.5 is skipped (the precheck gate becomes optional). If configured but the file is missing, **stop and report** — do not silently skip. The precheck gate exists to filter ~50% false positives from Architecture Challenge; bypassing it reintroduces noise.

Run BEFORE Architecture Challenge to filter already-addressed issues:

```
Task(
  prompt = "Pre-check gate for Phase {arg}.
    Read: {plan_paths}
    Search plans + codebase for each concern.
    Return only NOVEL issues — issues not already addressed.
    Skip ALREADY_ADDRESSED (those go to an appendix).
    This gate exists because Architecture Challenge has ~50% false alarm rate
    when it reports issues the plan already handles.",
  subagent_type = "Explore"
)
```

Result:
- If NOVEL_COUNT == 0: skip Architecture Challenge entirely, proceed to wave execution
- If NOVEL_COUNT > 0: pass NOVEL issues to Architecture Challenge (cuts context by ~50%)

# Step 3: Control Matrix scan (FULL always; STANDARD only when risk/security flagged)

Scan hotspot files for this phase's planned file changes:
- grep hotspot matches against control-matrix.md
- Check Physical column (YES / NO)
- If ANY physical-impact file → set `physical_impact: true`
- Report classification: HIGH SECURITY / STANDARD

# Step 4: Architecture Challenge (STANDARD and FULL, only if novel issues exist)

Pass only NOVEL issues from pre-check gate.

```
Task(
  prompt = "Architecture Challenge for Phase {arg}.
    Concerns (already filtered — these are NOVEL, not already in plans):
    {novel_issues}
    Read: {plan_paths}
    Evaluate: SPOF, error paths, display correctness, config validation, intent classification.
    If Physical=YES: verify safety interlocks preserved.
    Return: BLOCKERS (pre-triage gate applied) | OBSERVATIONS | APPROVED.
    Include Security Classification (v1.1):
    exploitability_band, confidence_score, physical_safety_verified.",
  subagent_type = "Explore"
)
```

If BLOCKERS found → classify whether each item is an implementation defect,
an implementation detail, or a mandatory owner decision. For every mandatory
owner decision, use the guided request in
`<mandatory_owner_decision_gates>` with authoritative evidence and provenance.
Do not ask the owner to choose between opaque policy or schema tokens. After a
valid answer, record it and continue the approved bounded work without
intermediate approval pauses. Implementation defects and details remain
subject to the normal bounded fix and verification flow.
If physical_safety_verified: false → HARD STOP (non-overridable).

# Step 5: OpenCode agent routing + wave execution

Map plans to agent roles:
- **Discovery**: pre-check + research (already completed)
- **Coder**: wave execution (Ralph Loop for autonomous plans, Standard for checkpoint plans)

```
Agent routing per plan:
- autonomous: true → Ralph Loop (Coder agent, 200K context)
- autonomous: false → Standard subagent (Coder agent, checkpoint flow)
```

For each wave:
1. Spawn agents in parallel using Task()
2. Between waves: run Wave Reconciliation (if 2+ plans completed)

# Step 6: Test command and evidence handoff

**ONLY if Phase produced code changes.** Prepare after all waves complete.

## 6.0: Manual execution rule

The agent MUST NOT invoke test runners automatically. For every test or
validation step, provide the exact command, working directory, required
environment, expected result, and any output-file location. The human operator
executes the command and returns the result or an evidence artifact. Do not
claim a test passed without returned evidence.

This rule does not prevent the agent from inspecting test configuration or
interpreting operator-supplied output. Automated test execution requires a
separately qualified project capability and executor.

## 6.1: Detect test framework
- Check for `pytest` config → backend test runner
- Check for `vitest` or `jest` config → frontend test runner
- Both may apply (run both)

## 6.2: Provide commands with baseline filtering

**Never invoke `pytest` (or any test runner) over an entire large test tree in one process.** On a
repo the size of a real production backend (thousands of tests), a single full-suite run can take
20-30+ minutes and has been observed to crash the pytest process itself (pytest INTERNALERROR —
`AST constructor recursion depth mismatch` — reproduced 2026-08-02, Phase 265, ~7000-test backend
suite) rather than just reporting failures. Treat "run the whole suite in one go" as unsafe by
default, not a shortcut.

Also never pipe test output through `| tail -N` when you need the failure list — it silently
discards the `FAILED`/`ERROR` lines once the run is longer than N lines, leaving you with only the
final summary count and no way to tell which tests failed. Always redirect to a file instead.

**Step 1 — targeted run first.** Provide a command for only the test files that plausibly cover the changed files
(same directory, same module name, or found via `grep -rl <changed_symbol> tests/`). This is fast
and gives immediate signal on the phase's own changes.

```bash
# Backend — targeted to files touched by this phase
if [ -f backend/pyproject.toml ] || [ -f backend/setup.cfg ]; then
    pytest ${targeted_test_paths} -q --timeout=60 > /tmp/gsd-targeted-tests.txt 2>&1
    tail -40 /tmp/gsd-targeted-tests.txt
fi
```

**Step 2 — full-suite regression check, batched.** Only if the phase's blast radius genuinely
requires whole-repo confidence. Split by top-level test subdirectory (or another natural boundary)
and run each batch as its own process, redirected to its own file — never one process, never a
`tail`-truncated pipe:

```bash
for dir in backend/tests/*/; do
    name=$(basename "$dir")
    pytest "$dir" -q --timeout=120 > "/tmp/gsd-fullsuite-${name}.txt" 2>&1 &
done
wait
grep -h "passed\|failed\|error" /tmp/gsd-fullsuite-*.txt
```

Run batches in the background and check in on them rather than blocking synchronously — a single
batch can still take several minutes on a large subdirectory.

**Step 3 — separate phase regressions from pre-existing failures.** Cross-reference failures
against `.pytest_cache/v/cache/lastfailed` and file paths touched by the phase. Failures in files
unrelated to the phase's changed files are pre-existing — report them but do not treat them as a
phase blocker unless the user has explicitly scoped this phase to include a wider fix. A phase's
own test harness gate is about the phase's changes, not repo-wide technical debt; surfacing a large
pre-existing failure count is a discovery to report and get scoped by the user, not license to
silently expand the phase into a full-repo fix effort.

```bash
# Frontend
if [ -f frontend/package.json ]; then
    frontend_tests=$(cd frontend && npx vitest run --reporter=verbose 2>&1 | tail -10)
    echo "$frontend_tests"
fi
```

## 6.3: Compare against baseline
If `.gsd-test-baseline.json` exists:
- Load known-failing test paths
- Diff: new failures → BLOCKER (MUST FIX), known failures → SHOULD FIX
- Update baseline on clean run

If no baseline exists:
- Create `.gsd-test-baseline.json` with current failures as known
- Report: "Baseline created — future runs will diff against this"

# Step 6.5: Stall check

After each wave or test run, check elapsed time since step started:
- Track start time at each step boundary
- If 30+ min elapsed AND execution not complete:
  - Append BLOCKER-NNN to `01-Control/blockers.md`
  - Report: `[STALL] No activity for 30+ min — BLOCKER-NNN created`
  - Ask user: continue or abort?

# Step 7: Review Orchestration

Review Orchestrator selects and coordinates review providers based on the factual
classification produced by Step 1.7. The architecture is defined in
`docs/12-development/gsd-master/review-orchestrator-spec-v1.md` and governed by
ADR-012.

**Key rules:**
- Capabilities orchestrate; Providers execute
- Capabilities are stable; Providers are replaceable
- Providers SHALL NOT invoke other providers
- Assess emits facts; the provider registry maps facts to providers

## 7.1: Load Classification

Use the `FactualClassification` from Step 1.7. If not produced (e.g., `plan:` mode),
derive it now from the git diff and execution context.

## 7.2: Load Provider Registry

**Active review route:** the project registry supplies the independent-review
provider, adapter, model and runtime. GSD does not select a provider by name,
embed a provider credential, or assume a particular secret manager. Read the
registry for the actual project. A missing or failed required reviewer is an
incomplete or blocked review, never an implicit PASS.


Read `review-providers.yaml` from `.gsd-engine/review-providers.yaml`. Each provider
declares its `api_version`, `conditions` (factual flags that trigger it), and
`execution` parameters. The registry is the routing policy; providers are not
allowed to select or invoke other providers.

The project registry may declare these elective frontend providers:

```yaml
providers:
  - name: design-taste-frontend
    role: elective
    always: false
    conditions: [frontend_creation]
    purpose: frontend creation or substantial redesign
  - name: impeccable
    role: elective
    always: false
    conditions: [has_ui_changes]
    purpose: frontend critique, accessibility, responsive review, and polish
  - name: project-independent-reviewer
    role: required
    capability: independent_reviewer
    always: true
    execution:
      adapter: provider-neutral-review-adapter
      provider: <project-provider>
      model: <project-model>
      credential_ref: <project-secret-reference>
      runtime_path: <project-registered-runtime>
    purpose: bounded, read-only independent implementation review
```

Use the installed skill path and version discovered by Step 0.6. Do not assume
that a provider is available merely because it appears in this example.

### 7.2.1: Frontend Design Audit Capability Check

When `has_ui_changes` is true and `impeccable` is selected, check the installed
Impeccable package for its audit command before dispatching the design review.
The preferred full audit is:

```bash
node {impeccable_path}/scripts/audit.mjs --json
```

If `audit.mjs` is absent, unavailable, or fails to load, use the installed
detector as the bounded fallback:

```bash
node {impeccable_path}/scripts/detect.mjs --json
```

The fallback is not equivalent to a full audit. Record the exact capability
status in the routing evidence as `audit_unavailable_detector_fallback`, attach
the detector output as evidence, and leave any unresolved design findings for
the independent design reviewer. Never report a full Impeccable audit as
complete without a returned audit result and evidence reference. If both
commands are unavailable, record `impeccable_unavailable` and mark the design
review incomplete rather than silently claiming completion.

## 7.3: Select Providers

Select providers whose conditions match the classification:

- `always: true` providers are always selected (e.g., Code Review)
- `conditions` providers match when any listed factual flag is true

Default providers:
- **Code Review** — the registered independent-review runtime. A single
  registered provider may satisfy both the Code Review role and the independent-
  review contract.
- **Independent Code Reviewer** — always selected when a project registers the
  `independent_reviewer` capability. It receives a fresh, read-only context and
  returns `code-review-result.v1`. The configured model/provider is replaceable;
  the reviewer contract and evidence rules are not.
- **Security review scope** — include relevant authorization, database, encryption,
  PII, and network constraints in the bounded review package. A security
  skill is guidance, not authority to launch an unregistered provider.
- **Frontend creation** — selected for a new or substantially redesigned frontend
  when `design-taste-frontend` is installed. Use it for visual direction and
  implementation guidance.
- **Design Review** — selected when has_ui_changes is true and `impeccable` is
  installed. Use it for critique, accessibility, responsive behavior, and polish.
- **Architecture Review** — selected when touches_backend, touches_infrastructure, or
  touches_architecture_boundary is true. Reviews architectural consistency.

Routing rules:

- No frontend change: select neither frontend provider.
- New or substantial frontend creation: select `design-taste-frontend` if available.
- Existing frontend review or polish: select `impeccable` if available.
- Substantial redesign: select the creation provider first, then Impeccable after
  implementation for review.
- Never select multiple frontend creation providers automatically.
- Missing elective providers are recorded as skipped; they do not block execution.

## 7.4: Dispatch Providers

For each selected provider:
- **Provider-neutral independent reviewer**:
  - resolve the registered adapter and inject the provider credential from the
    approved secret manager;
  - build the bounded review package from the current revision, diff, tests,
    requirements, and architecture references;
  - create a runtime input object containing `request`, `package`,
    `implementation_context_id`, `review_context_id`, `cycle_number`, and
    `prior_cycle_ref`;
  - invoke the registered `execution.runtime_path` in a fresh read-only child
    context. When the credential reference is an environment variable, the
    invocation MUST be wrapped by the approved secret manager, for example:
    ```bash
    <approved-project-secret-manager> <runtime_path> < "${review_input}" > "${review_output}"
    ```
  - validate the returned `code-review-result.v1` and `review-cycle.v1` before
    creating the review-cycle evidence record;
  - treat a non-zero exit, rejected runtime payload, malformed result, or
    missing output as `BLOCKED`/`INCOMPLETE_REVIEW`; never continue as PASS.

The implementation and reviewer may belong to the same overall GSD run, but
their context identifiers must differ. The reviewer child context receives
only the bounded package and has no mutation tools. Persist the runtime output
under `.gsd-engine/reviews/` and reference it from the mandatory
`.gsd-engine/work/phase-{arg}.review-evidence.json` record.
- **Registered provider:** run the registry-selected runtime in a fresh process
  under the project's approved secret-manager binding. Pass the existing runtime
  input unchanged; preserve its `review_result` and `review_cycle` artifacts,
  including blocked/incomplete outcomes. Never substitute a terminal agent or
  infer PASS from an empty findings list.
  When using the repository's legacy orchestration CLI, place this complete
  runtime input under `context.independent_review`; missing task, revision,
  evidence, or independent-context identity must fail closed.
- **Legacy Herdr/Claude review providers:** not active. Do not launch them.
  Specialist review scope belongs in the bounded review package; it does not
  imply enabling another provider or giving a reviewer mutation tools.
- **Local providers** (Architecture Review): invoke directly within the current session

Run providers in parallel where possible.

## 7.5: Aggregate Findings

Merge findings from all providers. Schema per ADR-012:

```
Finding:
  id, severity (blocker|major|minor|advisory),
  confidence (very_high|high|medium|low|very_low),
  title, description, category, evidence_ref, recommendation, source
```

**Deduplication:** Same title + category across providers → higher severity wins.

**Evidence grounding:** Before aggregation, resolve every finding's
`evidence_ref` against the supplied review package and repository revision.
Code findings must use an existing changed file and a positive line number;
references to missing files, invented paths, or unresolvable evidence are
provider failures, not advisories. A review containing such a finding cannot
pass the completion gate.

**Finding quality:** A finding must identify a concrete, actionable defect and
the change needed to resolve it. Praise, confirmation that a safeguard is
correct, or advice to maintain existing behavior is not a finding. Severity
must describe the defect's impact, not the importance of the surrounding
feature.

**False-positive handling:** The coding agent must not dismiss a finding by
editing the review output or changing its severity. A disputed finding requires
a governed `finding-disposition.v1` reviewer-disposition record with an
authorized reviewer reference and rationale evidence. The original finding
remains preserved; only the new disposition may classify it as rejected or
deferred. Recompute the completion gate from effective dispositions and rerun
review after any implementation change.
Equal severity → higher confidence wins.

**Confidence weighting:** A very_high-confidence advisory beats a very_low-confidence
blocker.

## 7.6: Compute Disposition

| Disposition | Meaning |
|-------------|---------|
| `PASS` | All providers approved, no findings |
| `PASS_WITH_ADVISORIES` | Only minor/advisory findings |
| `CHANGES_REQUIRED` | A finding requires action; classify it first. Architecture/requirement blockers return to Design, implementation defects return to Implement, and implementation details are resolved during bounded implementation |
| `INCOMPLETE_REVIEW` | Provider(s) failed/timed out, no blockers found — continue with warning |
| `BLOCKED` | All providers failed — escalate, cannot proceed |

If `CHANGES_REQUIRED`, classify every finding using the design-to-implementation
boundary. Do not send an implementation-detail finding back into recursive
design expansion when the approved boundary is sufficient to resolve it.
If `BLOCKED` → stop and escalate to human.

## 7.7: Bounded Review/Fix Loop

When the disposition is `CHANGES_REQUIRED`, return the findings to the coding
agent, require a new implementation attempt, rerun focused verification, and
rerun the independent reviewer in a fresh context. Repeat for at most three
correction cycles. `CHANGES_REQUIRED`, `BLOCKED`, and an exhausted cycle budget
cannot be reported as `completed`.

For every implementation attempt, create one `review-cycle.v1` coordination
record. The record must reference the task, implementation revision, review
result, finding records, and evidence records; do not copy those records into
the cycle. Preserve the same finding references when a later revision addresses
them. A cycle 1 or 2 `CHANGES_REQUIRED` result may point to the next revision;
a cycle 3 result must set the next action to `escalate` or `stop` and must not
create a fourth automatic revision.

If the configured reviewer is the same provider family as the coding agent,
fresh context and separate session boundaries are mandatory. Same-session
self-review is recorded as `self_review` and cannot satisfy the independent
review gate.

## 7.8: Persist Disposition

Record disposition in execution contract for Step 8:

```
review_orchestrator: {
    disposition: "PASS | PASS_WITH_ADVISORIES | CHANGES_REQUIRED | INCOMPLETE_REVIEW | BLOCKED",
    providers_executed: N,
    providers_failed: N,
    findings_total: N,
    findings_blocker: N,
    findings_advisory: N
}
```

Do not treat this summary as the cycle record itself. Persist a
`review-cycle.v1` record for the attempt and store its identifier in the
evidence artifact. The record's `review_result_ref` must resolve to the
returned reviewer result, and every finding must remain addressable by its
original identifier after a correction.

## 7.9: Persist Routing and Evidence

Write `.gsd-engine/work/phase-{arg}.review-evidence.json` before Step 8. This
record is mandatory whenever files changed, including when an elective provider
was unavailable or intentionally skipped. It must preserve the factual inputs,
the routing decision, provider outcomes, and evidence references:

```json
{
  "schema": "gsd-review-evidence.v1",
  "phase": "{arg}",
  "classification": {},
  "providers": {
    "considered": [],
    "selected": [],
    "skipped": [{"name": "...", "reason": "..."}]
  },
  "reviews": [],
  "findings": [],
  "disposition": "PASS | PASS_WITH_ADVISORIES | CHANGES_REQUIRED | INCOMPLETE_REVIEW | BLOCKED",
  "generated_at": "<ISO-8601 UTC>"
}
```

Each selected provider entry records `name`, `version`, `status`, `duration_ms`,
`finding_count`, and `evidence_ref`. Each skipped provider records a concrete
reason such as `condition_not_matched`, `not_installed`, `not_applicable`, or
`read_only_mode`. Do not claim a provider ran without a returned result or
evidence reference.

Add the cycle references to the same evidence record:

```json
{
  "review_cycles": [
    {
      "cycle_ref": "cycle-001",
      "revision_ref": "revision-001",
      "review_result_ref": "review-result-001",
      "outcome": "CHANGES_REQUIRED",
      "next_action": "implement_fix"
    }
  ]
}
```

The full cycle payload is governed by `review-cycle.v1`; the execution
evidence file stores references and summary fields only.

# Step 8: Codex Independent Validation

**ONLY if Phase produced code changes.**

## 8.0: Completion Gate

Before reporting the phase as `completed`, GSD must verify all of the
following independently:

```text
review cycle outcome == PASS or PASS_WITH_ADVISORIES
independent review evidence == present and validated
focused tests passed == true
live read-only verification == PASSED
evidence persistence and audit integrity == verified (atomic or recoverable)
applicable before/after evidence == present
unresolved blocker count == 0
Forge verification status == PASSED
```

The requirement closure check must compare the implementation's closure
records with the mandatory requirement identifiers from the approved phase
specification. It must fail for an omitted mandatory requirement, an invented
requirement identifier, an unsatisfied requirement, or an evidence reference
that does not resolve. Do not let the implementation agent define the complete
set of requirements being checked.

If any condition is false, the execution contract must remain non-complete
and name the missing evidence. A reviewer `PASS` is only permission to request
Forge verification; it is never completion authority.

Focused tests and live read-only verification are separate requirements: a
build or lint pass cannot substitute for exercising the governed workflow.
When evidence persistence and audit emission are separate operations, the
implementation must demonstrate atomicity or a recoverable reconciliation
path. UI changes must include an evidence-backed before/after comparison;
non-UI changes record that the visual-evidence check was not applicable.

## 8.1: Determine Review Effort

Use the orchestrator disposition from Step 7.7:

```
if disposition == "PASS":
    codex_effort = "MEDIUM"
elif disposition == "PASS_WITH_ADVISORIES":
    codex_effort = "MEDIUM"
elif disposition == "CHANGES_REQUIRED":
    codex_effort = "HIGH"
elif disposition == "INCOMPLETE_REVIEW":
    codex_effort = "MEDIUM"   # partial review still informs Codex
elif disposition == "BLOCKED":
    codex_effort = "SKIP"     # cannot validate if review infrastructure failed
else:
    codex_effort = "SKIP"

# Mode floor (Execution Profile Contract §6): use the execution mode from
# Step 1. A FULL phase must validate at HIGH effort, never below MEDIUM.
# SKIP (BLOCKED review infrastructure) is never forced to run.
if mode == "FULL" and codex_effort == "MEDIUM":
    codex_effort = "HIGH"
```

## 8.2: Invoke Codex CLI

```
if codex_effort != "SKIP":
    modified_files = git diff --name-only HEAD~1 HEAD | grep '\.py$'
    effort_flag = "--reasoning_effort=" + codex_effort  # high | medium | low
    # Use frontmatter default_model, allow env override
    codex_model = os.getenv("GSD_CODEX_MODEL", "gpt-4o")

    Bash(
        command = f"""echo "Review Phase {arg} for bugs, security, architecture.
Modified files: {modified_files}
Scope: bugs + security + architecture" | \\
            codex exec --skip-git-repo-check \\
            --sandbox read-only \\
            --model {codex_model} \\
            {effort_flag} 2>/dev/null | head -50"""
    )
```

## 8.3: Compare vs Orchestrator Findings

```
# Parse Codex stdout for severity count
if codex_effort == "SKIP":
    execution_contract["codex_validation"] = "skipped"
elif "critical" in codex_output or "high" in codex_output:
    severity = "high"
    BLOCKER-NNN: Codex found critical/high issue Review Orchestrator missed
elif codex_issues_found > 0:
    execution_contract["codex_divergence"] = "minor_issues_logged"
else:
    execution_contract["codex_validation"] = "clean"
```

## 8.4: Execution Contract Fields

```
codex_review: {
    effort: "MEDIUM | HIGH | SKIPPED",
    issues_found: N,
    severity: "critical | high | medium | low | none",
    vs_orchestrator: "agrees | diverges_minor | diverges_critical"
}
```

---

# Step 9: Greploop Autonomous PR Review + Fixing

**ONLY if Phase produced code changes AND a PR is targeted.**

## 9.0: Read-Only Guard

Check if GitHub CLI is authenticated:
```bash
if ! gh auth status &>/dev/null; then
    echo "read_only: true" >> .gsd-execution-state
    echo "Greploop requires GitHub CLI authentication. Skipping."
fi
```

If `read_only: true`:
→ Skip Greploop entirely. Report: `greploop: skipped (read-only mode — no GitHub token)`

Greploop is an autonomous code review agent that reviews PRs, posts comments, and fixes issues — looping until 5/5 confidence and zero comments remain.

## 9.1: Commit Phase Changes to Feature Branch

```bash
phase_branch="phase-{arg}"

# Check if branch exists, create if not
if ! git ls-remote --heads origin "refs/heads/{phase_branch}" | grep -q .; then
    git checkout -b "{phase_branch}"
    git push -u origin "{phase_branch}"
else
    git checkout "{phase_branch}"
    git pull origin main
fi

# Commit phase changes with conventional message
git add -A
git commit -m "Phase {arg}: $(git diff --stat HEAD | tail -1 | xargs)"
git push origin "{phase_branch}"
```

## 9.2: Create or Detect PR

```bash
# Build PR body with substituted variables
pr_body="## Phase {arg} — GSD Master v3.3 Pipeline

- Review Orchestrator: {orchestrator_disposition} ({providers_executed} providers)
- Codex Validation: {codex_result}
- **Greploop Step 9**: Autonomous review in progress

**Files changed:** $(git diff --name-only HEAD~1 HEAD | wc -l)
**Tests:** Run via \`gsd:verify-work {arg}\`"

# Check if PR already exists
existing_pr=$(gh pr list --head "{phase_branch}" --json number,title --jq '.[0]')

if [ -n "$existing_pr" ]; then
    pr_number=$(echo $existing_pr | jq -r '.number')
    echo "PR already exists: #{pr_number}"
else
    # Create PR with phase details
    pr_number=$(gh pr create \
        --title "Phase {arg} implementation" \
        --body "$pr_body" \
        --base main \
        --head "{phase_branch}" \
        --json number --jq '.number')
    echo "Created PR: #{pr_number}"
fi
```

## 9.3: Invoke Greploop for Autonomous Review

Greploop iteratively improves the PR until Greptile gives 5/5 confidence + zero unresolved comments. Max 5 iterations.

```
Execute: Skill(args="{pr_number}", skill="greploop")
```

Greploop will:
1. Trigger Greptile review via `@greptile review` comment
2. Poll for check run completion
3. Fetch Greptile review results (confidence score + comments)
4. Fix actionable comments
5. Resolve threads
6. Commit + push, then re-trigger
7. Loop until 5/5 confidence + zero comments (or max 5 iterations)

After Greploop completes, parse output for:
- `status`: "approved" (5/5 + 0 comments) or "partial" (max iterations reached)
- `final_confidence`: X/5
- `open_comments`: N

If no PR was created (Step 9.2 failed), skip Greploop and report `skipped`.

## 9.4: Mark PR Ready-for-Review

```bash
# After Greploop completes (5/5 + zero comments OR max iterations)

if [ iterations < 5 ] && [ open_comments == 0 ]; then
    # Full success — mark ready for human review
    gh pr edit {pr_number} --add-label "greploop-approved"
    gh pr comment {pr_number} --body "## ✅ Greploop Step 9 Complete

**PR #{pr_number}** — reviewed + fixed + approved by Greploop
- **Confidence:** 5/5
- **Open comments:** 0
- **Fixes applied:** {fix_count}
- **Status:** Ready for human merge review

Next: Human reviewer merges via \`gh pr merge {pr_number}\`"

    greploop_status="approved"
    final_confidence="5/5"
else
    # Partial completion — report what was done
    gh pr edit {pr_number} --add-label "greploop-partial"
    gh pr comment {pr_number} --body "## ⚠️ Greploop Step 9 — Partial Completion

**PR #{pr_number}** — Greploop completed {iterations}/5 iterations
- **Final confidence:** {final_confidence}/5
- **Open comments:** {open_comments}
- **Fixes applied:** {fix_count}
- **Status:** Needs human review for remaining issues

Remaining issues reviewed + commented. Human review required."

    greploop_status="partial"
    final_confidence="{final_confidence}/5"
fi
```

## 9.6: Execution Contract Fields

```
greploop_review: {
    pr_number: N | null,
    status: "approved | partial | skipped",
    confidence: "5/5 | N/5 | SKIPPED",
    fixes_applied: N,
    iterations: N,
    open_comments: N,
    labels_added: ["greploop-approved" | "greploop-partial"]
}
```

---

# Step 10: Documentation & Deployment

**ONLY if Phase produced code changes.** Runs after Greploop, before execution contract.

## 10.1: Update vault documentation
```bash
# Update MEMORY.md with phase status
echo "- Phase {arg}: implemented — {summary}" >> {vault_path}/MEMORY.md

# Update active decision log if decisions were made (DEC-NNN entries)
if [ -n "$decisions_made" ]; then
    for dec in $decisions_made; do
        echo "| 1.$(date +%s) | $(date -I) | DEC-$dec added | GSD Phase {arg} |" >> {vault_path}/01-Control/active-decision-log.md
    done
fi
```

## 10.2: Commit and push to git
```bash
# Commit codebase changes
git add -A
git commit -m "feat(phase-{arg}): implementation"
# Only push if not read-only
if [ ! -f .gsd-execution-state ] || ! grep -q "read_only: true" .gsd-execution-state; then
    git push origin $(git branch --show-current)
fi

# Commit vault changes
cd {vault_path}
git add -A
git commit -m "docs(phase-{arg}): update MEMORY.md, active-decision-log.md"
if [ ! -f .gsd-execution-state ] || ! grep -q "read_only: true" .gsd-execution-state; then
    git push origin master
fi
cd -
```

# Step 11: Return Execution Contract (v3.3)

## 11.0: Record Lessons Learned

Every phase run must produce a lessons-learned artifact, including runs that
end blocked or incomplete. Write:

```text
.gsd-engine/work/phase-{arg}.lessons-learned.json
```

Record the observed outcome, review-cycle references, test/Forge evidence,
failed assumptions, and any reusable lesson. Each observation must be
evidence-backed and attributable to the run. Use the `gsd-learning.v1`
observation shape for records:

```json
{
  "schema": "gsd-learning.v1",
  "id": "lesson.phase-{arg}.001",
  "version": "1.0.0",
  "entity_type": "observation",
  "statement": "<factual lesson from this run>",
  "evidence": [{"id": "phase-{arg}-review", "version": "1.0.0"}],
  "confidence": "high",
  "observed_at": "<ISO-8601 UTC>",
  "session_refs": [{"id": "<session-id>", "version": "1.0.0"}]
}
```

Do not change GSD instructions, provider policy, or completion rules directly
from a lesson. If a lesson is repeated or materially significant, record a
`procedural_candidate` or `process_candidate` with status `proposed` and route
it through `improvement-candidate:` and the `gsd-learning.v1` governance and
evaluation boundaries. Learning is mandatory; adoption is never automatic.

```
## Master Orchestration Report (v3.3)

**Phase:** {arg}
**Status:** completed
**Mode:** LIGHTWEIGHT | STANDARD | FULL   (profile: small | medium | large)
**GSD Master:** gsd:master {skill_version} ({skill_hash})
**Profile source:** engine | inline (no engine)
**Artifact root:** project-declared vault
**Dependency Governance:** {required_ok}/{required_total} required OK | {elective_found}/{elective_total} elective found
**Pre-check gate:** {novel_count} novel issues | {addressed_count} pre-filtered
**Architecture Challenge:** {passed | skipped}
**Wave Reconciliation:** {passed | conflicts resolved}
**Review Orchestrator:** {disposition} | {providers_executed} providers | {findings_total} findings
**Routing evidence:** `.gsd-engine/work/phase-{arg}.review-evidence.json`
**Lessons learned:** `.gsd-engine/work/phase-{arg}.lessons-learned.json`
**Improvement candidates:** {N} | adoption: proposed-only
**Codex Validation:** {codex_result}
**Greploop PR Review:** {pr_number} | {status} | {confidence}
**Results:**
- Plans executed: {N}
- Waves: {N}
- Regressions caught: {N}
- Spec drifts: {N}
- Review blocks: {N}
- Stalls detected: {N}
- Codex issues: {N}
- Greploop fixes: {N}

**PR:** https://github.com/{owner}/{repo}/pull/{pr_number}
**Next Action:**
gsd:verify-work {arg}
```

---

# Step 12: COMPLETED Phase Fast-Path

**When:** Phase status is COMPLETED/✅ COMPLETED

**Do NOT re-execute.** Instead:

1. Read phase file
2. Extract: deliverables, test results, definition of done, next phase suggestions
3. Return summary contract:

```
## Phase {arg} — Already Completed ✅

**Summary:** {1-sentence phase purpose}
**Executed:** {date from phase file}
**Duration:** {if recorded}

### Deliverables
{deliverables list}

### Test Coverage
{test results if available}

### Definition of Done
{checkbox status}

### Next Actions
- gsd:verify-work {arg} — verify outcomes
- gsd:new-milestone {next_phase} — start next phase
- Or describe next logical step
```

---

# Step 13: Improvement Mode

**When:** Argument starts with `improvement-candidate:`

Use the Skill Optimizer process in `references/run-audit-optimizer.md`. Analyze
the selected run audit(s), evaluate performance across comparable runs, and
return an evidence-backed proposal; never edit the skill automatically.

1. Parse the issue description after `improvement-candidate:`
2. Read the relevant skill file(s) to analyze
3. Perform root-cause analysis using the issue description
4. Return improvement report:

```
## Skill Improvement Report

**Issue:** {parsed issue description}
**Target skill:** {inferred from issue context}

### Root Cause Analysis
{explanation of what's wrong and why}

### Optimization Opportunities
1. {specific improvement with code example}
2. ...

### Expected Impact
{quantified improvement if possible}

### Suggested Fix
```markdown
// Before
{original code snippet}

// After
{optimized code snippet}
```
```

Improvement mode uses:
- Read: access skill files and code
- Bash: only for profiling/timing if needed
- No write/edit — suggestions only, user applies
</process>

<rationalizations>
Common excuses agents make when running GSD Master — and why they're wrong:

**"This is a tiny change, skip Step 0.5 spec validation."**
→ No. Step 0.5 catches missing fields BEFORE execution starts. Skipping it means discovering the spec is incomplete mid-execution — far more expensive. Lightweight mode skips Steps 3-5 but never Step 0.5.

**"Codex adds 2 minutes, skip for speed."**
→ No. Codex runs as a separate validation pass after the Review Orchestrator, independently of the registry-selected review provider. It catches what the Orchestrator's providers miss specifically because of the model divergence. Skipping it removes the cross-model safety net.

**"No GitHub token, just skip Greploop silently."**
→ Partially correct. The read-only guard (Step 9.0) handles this — but it must EXPLICITLY report `greploop: skipped (read-only mode — no GitHub token)` in the execution contract. Silent skip = lost signal that PR review didn't happen.

**"Architecture Challenge has 50% false positive rate, skip it."**
→ No — that's exactly why Step 1.5 pre-check gate exists. The two-step design filters the false positives BEFORE Architecture Challenge runs. Skipping Architecture Challenge means the pre-check gate is doing nothing.

**"Wave reconciliation is overkill for 2 plans."**
→ No. The reconciliation threshold is 2+ plans, not 3+. With 2 plans, conflicts are most likely because the human hasn't seen the interaction yet. Run it.

**"Test harness is slow, run it later."**
→ No. Step 6 runs BEFORE the review steps specifically so review feedback is informed by test results. Running tests after review means reviewers comment on broken code.

**"This is supervised-phase work, the operator already verified, skip tests."**
→ No. Supervised ≠ tested. The operator verifies operational correctness, not regression coverage. Tests catch what operator attention misses.

**"I improved the skill, no need to update success_criteria."**
→ No. If the change adds/renames a step, success_criteria checkboxes must reflect it. Stale criteria = agent gets credit for work the skill no longer does.
</rationalizations>



<subagent_routing>
| Agent | GSD Step | Context | Shell |
|-------|----------|---------|-------|
| Discovery | Pre-check gate | 150K | No |
| Coder | Wave execution | 200K | Yes |
| Reviewer | Project-registered independent-review runtime | Fresh bounded context | No mutation tools |
| Codex | Step 9 validation | 120K | No |
| Greploop | Step 9 PR review | 200K | Yes |

Per AGENTS.md:
- Discovery: fs readonly, sb readonly, no shell
- Codex: fs readonly, sb readonly, no shell, OpenAI GPT-4o model
- Coder: fs read/write, sb test writes, full shell
- Reviewer: fresh read-only context, no mutation tools, registry-pinned project model
- Greploop: fs read/write, sb read/write, shell, autonomous review loop
</subagent_routing>

<fallback_patterns>
**Spec Validation Failed:**
```
Status: execution_failed | Failure Point: step0.5_validation_failed
Next: Fill in missing fields in phase file using PHASE-SPECIFICATION-TEMPLATE.md
```

**Pre-Flight Dependency Missing:**
```
Status: validation_failed | Failure Point: step0.5_preflight_{missing_path}
Next: Create missing file or remove dependency from spec
```

**Architecture Blocked:**
```
Status: validation_failed | Failure Point: step5_architecture
Next: Review Architecture Challenge report
```

**Test Harness Failure:**
```
Status: validation_failed | Failure Point: step6_test_harness
Next: Fix failing tests or update baseline in .gsd-test-baseline.json
```

**Review Blocked (CHANGES_REQUIRED):**
```
Status: execution_failed | Failure Point: step7_review_changes_required
Next: Fix blocker/major findings from Review Orchestrator, re-run Step 7
```

**Review Blocked (BLOCKED disposition):**
```
Status: execution_failed | Failure Point: step7_review_infrastructure
Next: Review providers failed — check the registered runtime and secret-manager binding. Escalate to human.
```

**Codex Critical Divergence:**
```
Status: execution_failed | Failure Point: step9_codex_critical
Next: Address Codex critical findings before shipping
```

**Greploop Unresolved:**
```
Status: partial | Failure Point: step10_greploop
Next: Human review required for remaining issues
```
</fallback_patterns>

<examples>
Generic invocation traces showing what each argument mode produces. Adapt the placeholder values (`{project}`, `{N}`, etc.) to your domain.

---

### Example 1: Phase 001 — `{number}` mode (full validation pipeline)

**Invocation:** `gsd:master 001`

**Phase file:** `{vault_path}/00-GSD-Phases/Phase-001.md`
**Spec validation:** ✅ All 6 fields present (problem, AC, deps, gate, trade-offs, version)
**Pre-flight:** ✅ target file paths exist, DB migration present, external service configured
**Mode:** FULL (4+ files, new DB tables, security-sensitive)
**Architecture Challenge:** 0 novel issues after pre-check filter
**Waves:** 2 waves (DB migration → backend service → API endpoint)
**Test harness:** 23 new tests, baseline compared, 0 regressions
**Review Orchestrator:** PASS | 3 providers | 0 findings
**Codex:** clean
**Greploop:** N/A (no PR targeted)
**Execution contract:**
```
Phase 001: {phase_name}
Status: completed
Plans: 2 | Waves: 2 | Regressions: 0
Codex: clean | Greploop: skipped
```

---

### Example 2: Phase 002 — `{number}` mode (lightweight variant)

**Invocation:** `gsd:master 002`

**Phase file:** `{vault_path}/00-GSD-Phases/Phase-002.md`
**Spec validation:** ✅ All 6 fields present
**Pre-flight:** ✅ target file exists
**Mode:** LIGHTWEIGHT (≤3 files changed, no new infrastructure, no security-sensitive code)
**Skipped:** Architecture Challenge, Control Matrix, Ralph Loop, Wave Reconciliation
**Test harness:** 49/49 tests passing
**Review Orchestrator:** PASS | 1 provider (Code Review only) | 0 findings
**Codex:** clean
**Execution contract:**
```
Phase 002: {phase_name}
Status: completed
Plans: 1 | Files: 2 | Tests: 49/49
```

---

### Example 3: Phase 003 — `plan:` mode (draft intent)

**Invocation:** `gsd:master plan:{one-line description of pre-reviewed plan}`

**Skipped:** none of the specification or authorization gates; the draft is materialized as a canonical phase specification first
**Runs:** Step 0.6 (dependency governance — always runs)
**Mode:** FULL or LIGHTWEIGHT (determined by plan scope)
**Waves:** 1 wave (single coherent change set)
**Test harness:** runs if test changes present
**Review Orchestrator:** PASS or PASS_WITH_ADVISORIES
**Codex:** clean
**Execution contract:**
```
Phase 003: {phase_name}
Status: completed
Plans: 1 | Mode: plan: | Review: 0 SHOULD FIX
```
**Key insight:** `plan:` mode is an intent shorthand, not a gate bypass. It
must first produce a canonical `phase-specification.v1` and pass the same
phase-gate and dependency checks as `Phase-XXX` mode.

---

### Counter-example: What NOT to invoke GSD Master for

**Bad invocation:** `gsd:master fix-typo-in-readme`
→ Use direct Edit tool. The skill is for orchestrated phase execution, not single-file edits.

**Bad invocation:** `gsd:master why-does-{thing}-fail`
→ Use a debugging workflow. GSD Master executes plans; it doesn't diagnose production issues.

**Bad invocation:** `gsd:master research-{topic}`
→ Use a research workflow. GSD Master is execution-orchestrated, not research-orchestrated.
</examples>

<success_criteria>
- [ ] Phase file loaded and validated (Step 0.5)
- [ ] All 6 required fields present (problem, AC, deps, gate, trade-offs, version)
- [ ] Pre-flight dependency check passed (codebase/DB/external/frontend)
- [ ] Spec freshness checked (warning if >14 days old)
- [ ] Argument type routed correctly (phase / plan: / improvement-candidate)
- [ ] Step 0.6 dependency governance ran (manifest loaded, skills discovered, compatibility checked)
- [ ] Skill registry persisted for operator inspection
- [ ] Required dependencies found (WARNING if not)
- [ ] Compatibility matrix checked for pinned versions
- [ ] `plan:` mode materializes a canonical phase specification and runs Step 0.5 before execution
- [ ] Completed phases use fast-path (no re-execution)
- [ ] Project-declared vault artifact root detected
- [ ] Pre-check gate filtered known-addressed issues
- [ ] Validation passed (or user accepted incomplete)
- [ ] Architecture Challenge passed (or novel_count == 0)
- [ ] All waves executed (Ralph or Standard per plan)
- [ ] Wave reconciliation passed for multi-plan waves
- [ ] Test harness ran and baseline created/compared (Step 6)
- [ ] No stall detected (or stall escalated + resolved)
- [ ] Factual classification emitted in Step 1.7
- [ ] Review Orchestrator selected providers matching classification
- [ ] Registered review runtime dispatched; no legacy Claude/Herdr fallback
- [ ] Frontend design audit capability checked; full audit evidence or explicit detector fallback recorded
- [ ] Findings aggregated with confidence weighting and deduplication
- [ ] Disposition computed (PASS | PASS_WITH_ADVISORIES | CHANGES_REQUIRED | INCOMPLETE_REVIEW | BLOCKED)
- [ ] Disposition persisted for Step 8 consumption
- [ ] Default Code Review provider always runs (preserves existing behavior)
- [ ] Codex validation triggered appropriately (effort matched orchestrator disposition)
- [ ] Codex critical divergence handled (BLOCKER if severity mismatch)
- [ ] Greploop read-only guard checked — skipped cleanly if no GitHub token
- [ ] Greploop: commits to feature branch + creates/detects PR (if authenticated)
- [ ] Greploop: loops until 5/5 confidence + zero comments (or partial)
- [ ] Greploop: marks PR ready-for-review with greploop-approved label
- [ ] Documentation & Deployment step ran (vault docs + git commit + push)
- [ ] Execution contract returned with PR number + confidence (v3.3)
- [ ] Improvement mode produces root-cause analysis + suggestions
</success_criteria>
