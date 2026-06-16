# Contributing to GSD Master

## What This Skill Is

GSD Master orchestrates multi-step phase execution for Claude Code. It does NOT write code itself — it routes work to specialist subagents (Discovery, Coder, Reviewer, Codex, Greploop) and aggregates their results.

## When to Contribute

- A step is producing false positives/negatives at high rate
- A new review dimension is needed (security, accessibility, performance)
- A new argument mode is needed (e.g., `audit:`, `migrate:`)
- The persona table needs adjustment (context size, model, shell access)

## When NOT to Contribute

- One-off project quirks — keep those in your project config
- Domain-specific examples — strip them before contributing (see "Stripping Project Context" below)
- Step renumbering — breaks back-compat with existing phase files

## Adding a New Step

1. Place the step between existing steps using the next available number (0.5, 1.5, 6.5, 8.5, 9.5 are reserved for "in-between" steps)
2. Document it in `<process>` with: trigger condition, execution body, success criteria checkbox
3. Add a corresponding entry in `<success_criteria>`
4. Add a fallback pattern in `<fallback_patterns>` if the step can fail
5. Update the subagent routing table if the step uses a new agent type

## Modifying a Persona

The persona table in `<subagent_routing>` maps agents to GSD steps. To modify:

1. **Context size**: increase if the agent is running out of context mid-execution; decrease if you're paying for unused tokens
2. **Shell access**: enable if the agent needs to run tests/builds; disable if it's read-only analysis
3. **Model override**: only when the model materially affects output quality (e.g., Reviewer → Opus for nuanced judgment)

## Stripping Project Context

If you forked GSD Master for a specific project and want to contribute back:

1. Replace any `{vault_path}` template references with the generic version
2. Replace project-specific paths in `<examples>` with generic placeholders
3. Remove any project-specific rationale in `<rationalizations>`
4. Verify no project names, customer names, or domain-specific terminology remain
5. Run `grep -r "your-project-name" SKILL.md` — should return nothing

## Testing Changes Locally

1. Create a test phase file in `{vault_path}/00-GSD-Phases/test-phase.md` with all 6 required fields
2. Run `gsd:master test-phase` and verify the full pipeline executes
3. Check the execution contract against `<success_criteria>` — every box should checkable
4. Verify Greploop read-only guard works (run without `gh auth`, confirm skip is reported)

## Commit Message Convention

```
{type}(gsd-master): {description}

{optional body}

{optional footer}
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

Examples:
- `feat(gsd-master): add Step 6.5 stall detection`
- `fix(gsd-master): parameterize Codex model via env var`
- `docs(gsd-master): add examples section with 3 generic traces`

## Versioning

GSD Master follows semver:
- **MAJOR**: breaking change to argument modes, step numbering, or execution contract shape
- **MINOR**: new step, new argument mode, new persona (backward-compatible)
- **PATCH**: bug fix, doc clarification, persona tuning (no API change)

Current version is in the `version:` field of `SKILL.md` frontmatter.
