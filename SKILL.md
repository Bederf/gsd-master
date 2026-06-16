---
name: gsd:master-v3
alias: gsd:master
version: 3.3.0
description: Phase orchestration v3.3 — vault-aware, Step 0.5 spec validation, plan-as-spec mode, mandatory review, test harness, precheck gate, Codex review, Greploop PR review
argument-hint: "<phase-number|plan:<description>|improvement-candidate:<description>>"
config:
  vault_path: "vault"                   # Phase file root (override via env: GSD_VAULT_PATH)
  precheck_skill_path: "skills/gsd/precheck-gate.md"  # External precheck skill (optional)
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
Phase orchestration v3.3 — adds Step 0.5 specification validation gate before scope triage + Greploop autonomous PR review + fixing (Step 9) after Codex validation.

**What v3.3 adds over v3.2:**
1. Step 0.5 specification validation: requires 6 fields (problem, AC, deps, gate, trade-offs, version) + pre-flight dependency check
2. `plan:` argument mode — skips phase file discovery for pre-reviewed specs
3. Old Step 3 (validate-phase skill) removed — merged into Step 0.5
4. Heartbeat system removed (had no consumer)
5. Read-only guard for Greploop (auto-skips if no GitHub token)
6. Mandatory scope-adaptive review (always runs when files changed)
7. Test harness scaffolding (auto-detect + run + baseline diff)
8. Documentation + git push step (auto-commit vault docs)

**Full Pipeline:**
Step 0: Argument routing → Step 0.5: Spec validation → Steps 1-6: Orchestration (DAG, waves, test harness)
         ↓
Step 7: Paranoid Review → Step 8: Codex validation → Step 9: Greploop
         ↓
Step 10: Documentation & Deployment → Step 11: Execution contract
</objective>

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
- Have a pre-reviewed plan? → `plan:{description}` (skip Step 0.5)
- Skill is misbehaving? → `improvement-candidate:{description}` (Step 13)
</triggers>

<execution_context>
@{precheck_skill_path}
</execution_context>

<context>
Argument: $ARGUMENTS

**Argument modes:**
- `{number}` → Phase execution (e.g., `211`, `208`)
- `plan:{description}` → Pre-reviewed spec mode (skips Step 0.5, uses plan directly as spec)
- `improvement-candidate:{description}` → Skill self-improvement (e.g., `improvement-candidate: precheck gate is slow`)

**Artifact root detection** (check in order):
1. `{vault_path}/00-GSD-Phases/Phase-{arg}.md` — Obsidian vault (primary)
2. `.planning/phases/{arg}/` — legacy fallback
3. Project root — ask user

**Blocker path:** `{vault_path}/01-Control/blockers.md` or `.planning/blockers.md`
</context>

<process>
# Step 0: Route by argument type

**If argument starts with "improvement-candidate:"**
→ Jump to **Improvement Mode** (Step 13)

**If argument starts with "plan:"**
→ Parse description after `plan:` as the plan brief
→ Skip Step 0.5 (no phase file needed — plan is pre-reviewed)
→ Skip Step 1 (scope triage — plan scope is already defined)
→ Skip Step 1.5 (pre-check gate — plan is pre-reviewed)
→ Go directly to **Step 2** (wave execution)
→ Steps 7-10 (review, Codex, Greploop, execution contract) still apply

**If argument is a phase number:**
→ Continue to **Step 0.5** (spec validation)

---

# Step 0.5: Load & Validate Phase Specification

**Applies when:** argument is a phase number (`{number}` mode).
**Skips when:** argument is `improvement-candidate:` or `plan:` mode.

## 0.5.1: Resolve Phase File Path

Try in order:
1. `{vault_path}/00-GSD-Phases/Phase-{arg}.md`
2. `{vault_path}/00-GSD-Phases/Commercial/Phase-{arg}-*` (fuzzy match)
3. `.planning/phases/{arg}/PLAN.md`
4. Ask user for path

If file not found → `execution_failed` with `failure_point: step0.5_file_not_found`

## 0.5.2: Check Required Fields

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

### If ALL fields pass AND pre-flight passes:
→ Continue to **Step 1** (scope triage).

### If ANY field fails:
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
```

### If pre-flight finds MISSING dependencies:
→ Report each missing dependency with exact path. Ask user:
- "Fix and retry?"
- "Proceed anyway (dependencies may be created during execution)?"

---

# Step 1: Scope triage + artifact root

Check artifact root in order:
- Does `{vault_path}/00-GSD-Phases/Phase-{arg}.md` exist? → vault mode
- Does `.planning/phases/{arg}/` exist? → legacy mode
- Neither? → ask user

**Read phase file and check status:**

If `status: COMPLETED` or contains `✅ COMPLETED`:
→ Jump to **COMPLETED Phase Fast-Path** (Step 12)

---

**LIGHTWEIGHT** if ALL of:
- ≤ 3 files changed
- No new infrastructure (DB tables, services, external APIs)
- No security-sensitive or physical-device-write code
- Success criteria clear and rollback trivial

**FULL** if ANY of:
- 4+ files across backend + frontend
- New DB tables, services, or external API integrations
- Security-sensitive or physical-impact code
- Multiple plans/waves required

If LIGHTWEIGHT: plan → implement → verify → summarize.
Skip: Architecture Challenge, Control Matrix scan, Ralph Loop, Wave Reconciliation.
**Review (Paranoid Review + Codex) always runs when files changed, regardless of mode.**

# Step 1.5: Pre-check gate (MANDATORY for FULL execution)

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

# Step 3: Control Matrix scan (FULL only)

Scan hotspot files for this phase's planned file changes:
- grep hotspot matches against control-matrix.md
- Check Physical column (YES / NO)
- If ANY physical-impact file → set `physical_impact: true`
- Report classification: HIGH SECURITY / STANDARD

# Step 4: Architecture Challenge (FULL only, only if novel issues exist)

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

If BLOCKERS found → present to user. User decides: fix or proceed.
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

# Step 6: Test harness

**ONLY if Phase produced code changes.** Runs after all waves complete.

## 6.1: Detect test framework
- Check for `pytest` config → backend test runner
- Check for `vitest` or `jest` config → frontend test runner
- Both may apply (run both)

## 6.2: Run with baseline filtering
```bash
# Backend
if [ -f backend/pyproject.toml ] || [ -f backend/setup.cfg ]; then
    backend_tests=$(pytest backend/tests/ -q --tb=short --timeout=120 2>&1 | tail -5)
    echo "$backend_tests"
fi

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

# Step 7: Paranoid Review (always runs when files changed, Reviewer agent)
**Effort:** LIGHT (1-3 files), MEDIUM (4-10 files), FULL (10+ files) — determined by diff complexity.

```
Task(
  prompt = "Paranoid Review for Phase {arg}.
    Read summaries: {summary_paths}
    Read git diff: git log --oneline {first_commit}..HEAD
    Check: error handling, state consistency, display correctness,
    config sensitivity, rate limits, concurrency, scope drift.
    Return: MUST FIX (ship-blocking) | SHOULD FIX | LOOKS GOOD.",
  subagent_type = "general-purpose"
)
```

If MUST FIX → fix, commit, re-run review.
Paranoid Review runs on Opus model (Reviewer agent).

# Step 8: Codex Independent Validation

**ONLY if Phase produced code changes.**

## 8.1: Determine Review Effort

```
if paranoid_review_status == "LOOKS_GOOD":
    codex_effort = "MEDIUM"
elif paranoid_review_status == "SHOULD_FIX":
    codex_effort = "MEDIUM"
elif paranoid_review_status == "MUST_FIX":
    codex_effort = "HIGH"
else:
    codex_effort = "SKIP"
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

## 8.3: Compare vs Paranoid Review

```
# Parse Codex stdout for severity count
if codex_effort == "SKIP":
    execution_contract["codex_validation"] = "skipped"
elif "critical" in codex_output or "high" in codex_output:
    severity = "high"
    BLOCKER-NNN: Codex found critical/high issue Paranoid Review missed
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
    vs_paranoid: "agrees | diverges_minor | diverges_critical"
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

- Paranoid Review: {paranoid_status}
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

```
## Master Orchestration Report (v3.3)

**Phase:** {arg}
**Status:** completed
**Artifact root:** {vault | .planning | project}
**Pre-check gate:** {novel_count} novel issues | {addressed_count} pre-filtered
**Architecture Challenge:** {passed | skipped}
**Wave Reconciliation:** {passed | conflicts resolved}
**Paranoid Review:** {passed | blocked}
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
→ No. Codex runs in parallel with Paranoid Review via different model (gpt-4o vs Opus). It catches what Paranoid Review misses specifically because of the model divergence. Skipping it removes the cross-model safety net.

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
| Reviewer | Paranoid Review | 120K | No |
| Codex | Step 9 validation | 120K | No |
| Greploop | Step 9 PR review | 200K | Yes |

Per AGENTS.md:
- Discovery: fs readonly, sb readonly, no shell
- Codex: fs readonly, sb readonly, no shell, OpenAI GPT-4o model
- Coder: fs read/write, sb test writes, full shell
- Reviewer: fs readonly, sb readonly, no shell, Opus model
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

**Review Blocked:**
```
Status: execution_failed | Failure Point: step8_review
Next: Fix MUST FIX issues
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
**Paranoid Review:** LOOKS GOOD
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
**Paranoid Review:** LOOKS GOOD (mandatory despite lightweight)
**Codex:** clean
**Execution contract:**
```
Phase 002: {phase_name}
Status: completed
Plans: 1 | Files: 2 | Tests: 49/49
```

---

### Example 3: Phase 003 — `plan:` mode (pre-reviewed spec)

**Invocation:** `gsd:master plan:{one-line description of pre-reviewed plan}`

**Skipped:** Step 0.5 (plan is pre-reviewed), Step 1 (scope defined in plan), Step 1.5 (pre-reviewed)
**Mode:** FULL or LIGHTWEIGHT (determined by plan scope)
**Waves:** 1 wave (single coherent change set)
**Test harness:** runs if test changes present
**Paranoid Review:** LOOKS GOOD or SHOULD FIX (resolved before completion)
**Codex:** clean
**Execution contract:**
```
Phase 003: {phase_name}
Status: completed
Plans: 1 | Mode: plan: | Review: 0 SHOULD FIX
```
**Key insight:** `plan:` mode is faster (skips 3 steps) but only safe when the plan has been pre-reviewed against the same 6-field standard as `Phase-XXX.md` files.

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
- [ ] `plan:` mode skips Step 0.5 + Step 1 (goes directly to wave execution)
- [ ] Completed phases use fast-path (no re-execution)
- [ ] Artifact root detected (vault / .planning / project)
- [ ] Pre-check gate filtered known-addressed issues
- [ ] Validation passed (or user accepted incomplete)
- [ ] Architecture Challenge passed (or novel_count == 0)
- [ ] All waves executed (Ralph or Standard per plan)
- [ ] Wave reconciliation passed for multi-plan waves
- [ ] Test harness ran and baseline created/compared (Step 6)
- [ ] No stall detected (or stall escalated + resolved)
- [ ] Paranoid Review ran (always runs when files changed, not FULL-only)
- [ ] Review effort scaled to diff complexity (LIGHT/MEDIUM/FULL)
- [ ] Codex validation triggered appropriately (effort matched Paranoid Review result)
- [ ] Codex critical divergence handled (BLOCKER if severity mismatch)
- [ ] Greploop read-only guard checked — skipped cleanly if no GitHub token
- [ ] Greploop: commits to feature branch + creates/detects PR (if authenticated)
- [ ] Greploop: loops until 5/5 confidence + zero comments (or partial)
- [ ] Greploop: marks PR ready-for-review with greploop-approved label
- [ ] Documentation & Deployment step ran (vault docs + git commit + push)
- [ ] Execution contract returned with PR number + confidence (v3.3)
- [ ] Improvement mode produces root-cause analysis + suggestions
</success_criteria>