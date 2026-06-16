# GSD Master v3.3

Phase orchestration skill for Claude Code. Orchestrates multi-plan phase execution with spec validation, mandatory review (Paranoid + Codex), test harness, and Greploop PR review.

> **Adapted from [GSD Core](https://www.npmjs.com/package/@opengsd/gsd-core)** by the OpenGSD team. GSD Master re-implements GSD Core's phase-loop model with strict pre-flight validation, dual review, and autonomous PR review. See [ACKNOWLEDGMENTS.md](ACKNOWLEDGMENTS.md) for full attribution.

## What It Does

Takes a phase spec (or pre-reviewed plan) and runs it through an 11-step pipeline:

1. **Step 0** — Argument routing (phase number / plan / improvement-candidate)
2. **Step 0.5** — Spec validation (6 required fields) + pre-flight dependency check
3. **Steps 1-6** — Scope triage, pre-check gate, control matrix, architecture challenge, wave execution, test harness
4. **Step 7** — Paranoid Review (mandatory, runs on any file change)
5. **Step 8** — Codex validation (cross-model second opinion)
6. **Step 9** — Greploop autonomous PR review + fixing
7. **Step 10** — Documentation & deployment
8. **Step 11** — Execution contract

Returns a structured execution contract with review status, test results, and PR number.

## When to Use

- Phase spans 4+ files across multiple subsystems
- New DB tables, services, or external API integrations
- Security-sensitive or physical-impact code
- Multi-plan execution with waves + reconciliation needed
- PR-targeted work needing autonomous review

**Do NOT use for:** single-file bug fixes, README updates, dependency bumps, debugging, pure research.

## Installation

Drop the `gsd-master/` directory into `~/.claude/skills/`. The skill is discovered automatically by Claude Code.

## Configuration

Edit the `config:` block in `SKILL.md` frontmatter:

```yaml
config:
  vault_path: "vault"                   # Phase file root
  precheck_skill_path: "skills/gsd/precheck-gate.md"  # Optional external precheck skill
  default_model: "gpt-4o"               # Codex default
```

Override via environment variables:

```bash
export GSD_VAULT_PATH="my-vault"
export GSD_CODEX_MODEL="gpt-4-turbo"
```

## Usage

### Phase number mode

```bash
# From your project root
gsd:master 042
```

Loads `{vault_path}/00-GSD-Phases/Phase-042.md`, validates the 6 required fields (problem, acceptance criteria, dependencies, phase gate, trade-offs, version), runs pre-flight checks, then executes the full pipeline.

### Plan mode (pre-reviewed spec)

```bash
gsd:master plan:add user authentication with OAuth2 + JWT
```

Skips Step 0.5 spec validation (plan is already reviewed). Goes directly to wave execution.

### Improvement mode

```bash
gsd:master improvement-candidate:precheck gate is slow on large plans
```

Analyzes the skill and returns improvement suggestions. No write/edit — suggestions only.

## Phase Spec Format

Phase files must contain these 6 sections (validated by Step 0.5):

```markdown
## Problem Statement
{what's wrong or missing}

## Acceptance Criteria
- [ ] {criterion 1}
- [ ] {criterion 2}

## Dependencies
### Codebase
- {file path that must exist}
### DB
- {migration file path}
### External
- {service/credential required}

## Phase Gate
gate_type: {manual|automated|advisory}
min_phase: {N|N/A}
failure_action: {block|warn|log}

## Trade-offs
- Not doing: {thing we explicitly chose not to do}

Version: 1.0
Last Updated: 2026-06-16
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Step 0: Argument routing                                    │
│  Step 0.5: Spec validation + pre-flight                      │
└────────────────────────┬────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 1: Scope triage (LIGHTWEIGHT or FULL)                  │
│  Step 1.5: Pre-check gate (filter known issues)              │
│  Step 3: Control matrix scan (FULL only)                     │
│  Step 4: Architecture Challenge (FULL only, novel issues)    │
│  Step 5: Wave execution (Ralph Loop or Standard)             │
│  Step 6: Test harness + baseline diff                        │
│  Step 6.5: Stall detection                                   │
└────────────────────────┬────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 7: Paranoid Review (Opus) — mandatory when files change│
│  Step 8: Codex validation (GPT-4o) — cross-model check      │
│  Step 9: Greploop PR review + fix (requires gh auth)        │
└────────────────────────┬────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 10: Doc update + git commit/push                       │
│  Step 11: Execution contract                                 │
└─────────────────────────────────────────────────────────────┘
```

## Subagent Routing

| Agent | GSD Step | Context | Shell | Model |
|-------|----------|---------|-------|-------|
| Discovery | Pre-check gate | 150K | No | — |
| Coder | Wave execution | 200K | Yes | — |
| Reviewer | Paranoid Review | 120K | No | Opus |
| Codex | Step 8 validation | 120K | No | GPT-4o |
| Greploop | Step 9 PR review | 200K | Yes | — |

## Contributing

See `CONTRIBUTING.md` for how to extend the skill, add new steps, or modify the persona table.

## License

MIT — see `LICENSE`.
