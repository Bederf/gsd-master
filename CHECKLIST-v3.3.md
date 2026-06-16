# GSD Master v3.3 Implementation Checklist

**Status:** v3.3 shipped to https://github.com/Bederf/gsd-master
**Last Updated:** 2026-06-16

## ✅ Completed (v3.3 ship)

### v3.3 core improvements
- [x] Add `<triggers>` section (when to use / when NOT to) — 20 lines, lines 45-63
- [x] Add `<rationalizations>` section (8 common excuses + rebuttals) — 27 lines
- [x] Add `<examples>` section (3 generic traces + counter-example) — 82 lines
- [x] Add `version: 3.3.0` to frontmatter (machine-parseable)
- [x] Parameterize Codex model: `default_model: "gpt-4o"`, env override `GSD_CODEX_MODEL`
- [x] Step 8.3 explicit SKIP branch (was undefined)
- [x] Step 1.5 load check for precheck skill (fail-fast, not silent skip)
- [x] Frontmatter `config:` block: `vault_path`, `precheck_skill_path`, `default_model`

### Open source prep
- [x] Strip all BMS-specific references (verified: `grep` returns 0 matches)
- [x] Parameterize `{vault_path}` template throughout (sentinel-vault → vault default)
- [x] Generic `<examples>` (no Phase 208/224/225.1, no S002/BACnet/Telegram)
- [x] LICENSE (MIT) added
- [x] README.md added
- [x] CONTRIBUTING.md added
- [x] .gitignore added (`.gsd-execution-state`, `.gsd-test-baseline.json`)
- [x] GitHub repo created: https://github.com/Bederf/gsd-master
- [x] Initial commits pushed (3 commits on main)

## 🔄 Remaining (v3.4 candidates)

### Documentation gaps
- [ ] Add `<troubleshooting>` section (common invocation errors, expected fixes)
- [ ] Add `<anti_patterns>` section (common misuses: e.g., running GSD Master on a single-file edit, treating improvement-candidate mode as a code-review tool)
- [ ] Add worked example: full `Phase-001.md` template file in `examples/` directory
- [ ] Add `examples/plan-mode.md` showing a real `plan:` invocation trace
- [ ] Add `examples/improvement-candidate-mode.md` showing Step 13 output

### Validation/testing
- [ ] Add CI workflow: lint frontmatter, validate success_criteria checkboxes
- [ ] Add CI workflow: grep for forbidden terms (project names, customer names)
- [ ] Test `vault_path` override via `GSD_VAULT_PATH` env var
- [ ] Test `precheck_skill_path=""` empty config (Step 1.5 should skip, not fail)
- [ ] Test Greploop read-only guard (run without `gh auth`, confirm skip is reported)

### Persona improvements
- [ ] Add `SecurityReviewer` persona for security-sensitive phases (currently using generic Reviewer)
- [ ] Add `PerformanceReviewer` persona (Opus with system perf knowledge)
- [ ] Document persona model selection rationale in CONTRIBUTING.md

### Execution contract enhancements
- [ ] Add JSON schema for execution contract (currently prose-only, hard to parse)
- [ ] Add `gsd:validate-contract` skill to check contracts against schema
- [ ] Add `gsd:report-velocity` skill to aggregate execution contract metrics across phases

## 📋 Pre-v3.4 Decision Points

Before v3.4 work starts, decide:

1. **Should the skill be split into `gsd:master` (orchestrator) + `gsd:steps/*` (individual steps)?** Current monolithic 926-line SKILL.md is approaching the Agent Skills "consider splitting" threshold (~1000 lines). Decision affects contribution ergonomics.

2. **Should the v3.3 process numbering be preserved or refactored?** Current scheme (0, 0.5, 1, 1.5, 3, 4, 5, 6, 6.5, 7, 8, 9, 9.6, 10, 11, 12, 13) is non-sequential (Step 2 missing, Step 9.6 after Step 10). Backward compat vs cleaner numbering.

3. **Should `gsd:master` be renamed to `gsd:orchestrate`?** "Master" has problematic connotations in some communities. Current name is established in the user's workflow; renames are disruptive.

## 🔗 Related Workstreams

- **Backend test repairs** (2026-06-14, commit `63d8e820`) — closed 5 pre-existing test failures
- **Sentry bot security audit** (2026-06-13) — all 6 active vectors fixed
- **Phase 208 advisory outcome verification** — example case for v3.3 invocation modes

## File Locations

| File | Purpose |
|------|---------|
| `~/.claude/skills/gsd-master/SKILL.md` | Local copy (sync'd with GitHub) |
| `https://github.com/Bederf/gsd-master` | Public OSS repo |
| `~/.claude/.../memory/MEMORY.md` | Session memory with v3.3 ship log |
