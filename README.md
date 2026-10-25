# GSD Master v3.4.0-preview.1

Governed software-development lifecycle orchestration for Claude Code. GSD Master
coordinates requirements, design, authorization, delegated implementation,
verification, independent review, remediation and closeout as one evidenced
development phase.

GSD Master is a development skill, not a coding agent, SDK, runtime, framework
or standalone platform. It does not replace Claude Code or your project's own
governance. It structures and records the work performed through them.

> **Adapted from [GSD Core](https://www.npmjs.com/package/@opengsd/gsd-core)** by the OpenGSD team. GSD Master re-implements GSD Core's phase-loop model with strict pre-flight validation, dual review, and autonomous PR review. See [ACKNOWLEDGMENTS.md](ACKNOWLEDGMENTS.md) for full attribution.

## What It Does

Takes a canonical `phase-specification.v1` plus its human-readable phase
context and runs it through an 11-step development lifecycle:

1. **Step 0** — Argument routing (phase number / plan / improvement-candidate)
2. **Step 0.5** — Canonical `phase-specification.v1` validation, compatibility checks, and pre-flight dependency check
3. **Steps 1-6** — Scope triage, pre-check gate, control matrix, architecture challenge, wave execution, test harness
4. **Step 7** — Review Orchestrator with independent provider routing
5. **Step 8** — independent validation and evidence reconciliation
6. **Step 9** — Greploop autonomous PR review + fixing
7. **Step 10** — Documentation & deployment
8. **Step 11** — Execution contract

Returns a structured execution contract with review status, test results, PR number,
and a routing/evidence record showing which providers were selected, skipped, and
what evidence each provider returned, plus `review-cycle.v1` references for
each bounded implementation/review attempt.

Completion is fail-closed: a reviewer `PASS` must be followed by focused tests,
zero unresolved blockers, and the project's required independent verification.

Every phase also emits a lessons-learned artifact backed by `gsd-learning.v1`.
Lessons may produce proposed improvement candidates, but GSD never mutates its
own skill or policy automatically from a single run.

## When to Use

- Phase spans 4+ files across multiple subsystems
- New DB tables, services, or external API integrations
- Security-sensitive or physical-impact code
- Multi-plan execution with waves + reconciliation needed
- PR-targeted work needing autonomous review

**Do NOT use for:** single-file bug fixes, README updates, dependency bumps, debugging, pure research.

## Installation

GSD Master is installed as a Claude Code skill. From a clean checkout:

```bash
mkdir -p ~/.claude/skills
cp -R . ~/.claude/skills/gsd-master
```

Restart or reload Claude Code, then invoke it from a project that has a
configured phase-vault root. The package includes a self-check command for
release maintainers:

```bash
bash scripts/validate-public-package.sh
```

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

### Independent reviewer configuration

Projects may register an `independent_reviewer` provider. The reviewer receives
a fresh, read-only context containing the specification, diff, tests, and
architecture constraints. It returns `code-review-result.v1`; GSD owns the
completion gate and the bounded fix/review loop.

Completion also requires focused-test evidence, live workflow verification,
validated evidence/audit persistence, and applicable before/after evidence;
general build or lint success is insufficient.

False positives are handled through an attributable `finding-disposition.v1`
reviewer disposition with rationale evidence; they are never silently removed
or downgraded by the implementation agent.

Projects may register an independent-review provider through their own
`.gsd-engine/review-providers.yaml`. The project owns the adapter, model,
runtime and secret-manager binding; GSD owns the review contract, evidence
requirements and completion gate.

GSD must never print, persist or include credentials in review context or
evidence. A required reviewer that is unavailable, malformed or incomplete is
reported as blocked or incomplete review. It is never silently treated as a
PASS. The implementation and reviewer must use different context identifiers,
and the reviewer must remain read-only.

## Usage

### Phase number mode

```bash
# From your project root
gsd:master 042
```

Loads `{vault_path}/00-GSD-Phases/Phase-042.md` and its canonical
`Phase-042.specification.json` sidecar, validates the phase specification and
compatibility fields, runs pre-flight checks, then executes the full pipeline.

### Plan mode (draft intent)

```bash
gsd:master plan:add user authentication with OAuth2 + JWT
```

Creates or resolves a canonical phase specification and must pass the same
phase gate before wave execution. It is not an execution bypass.

### Improvement mode

```bash
gsd:master improvement-candidate:precheck gate is slow on large plans
```

Analyzes the skill and returns improvement suggestions. No write/edit — suggestions only.

## Phase Spec Format

The Markdown phase file remains readable project context and must contain the
six compatibility sections below. The executable semantic contract lives in
the adjacent `Phase-{id}.specification.json` sidecar and must validate as
`phase-specification.v1` before implementation is authorized.

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

The sidecar must preserve the complete specification identity
(`phase_id`, `specification_id`, `version`, `specification_hash`) and define
intent, scope, requirements, acceptance criteria, evidence contracts, task
intent, dependencies, verification, independent review, convergence,
remediation, acceptance authority, workflow identity, and provenance. Runtime
artifacts provide evidence against this contract; they do not redefine it.

Each run also records the exact execution contract identity:
`skill_id`, `skill_version`, and `skill_hash` (the SHA-256 of the `SKILL.md`
bytes used for that run). Acceptance can therefore bind both the authorized
phase specification and the GSD Master contract that executed it.

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
│  Step 7: Independent reviewer routing — fresh context       │
│  Step 8: Validation + evidence reconciliation               │
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
| Reviewer | Project-registered independent review | bounded | No | registry-pinned |
| Codex | Step 8 validation | 120K | No | GPT-4o |
| Greploop | Step 9 PR review | 200K | Yes | — |

### Review-provider routing

Provider selection is factual and registry-driven:

| Change classification | Provider |
|---|---|
| Any file change | Code review |
| New or substantial frontend work | `design-taste-frontend` (elective) |
| Existing frontend critique or polish | Impeccable (elective) |
| Auth, database, encryption, PII, or network changes | Trail of Bits Semgrep (elective) |
| Explicit PR-targeted work with GitHub access | Greploop (elective) |

Providers are skipped when their conditions do not match or they are unavailable.
Every selection and skip is recorded in `.gsd-engine/work/phase-{arg}.review-evidence.json`.

An implementation agent may not be the sole reviewer of its own work. A
`CHANGES_REQUIRED` result returns the work to the coding agent and starts a
bounded fix/review cycle, with a maximum of three correction cycles. Each
attempt is recorded as a `review-cycle.v1` reference; reviewer `PASS` still
requires focused tests and Forge verification before completion.

## Public-preview boundaries

The public package is intentionally focused on lifecycle orchestration. It does
not include a consumer project's vault, provider credentials, private runtime,
deployment configuration or production authority decisions. Projects supply
their own domain invariants, approval vocabulary and provider configuration.

See [docs/public-preview.md](docs/public-preview.md) for the lifecycle model,
security boundaries, known limitations and extension guidance.

## Contributing

See `CONTRIBUTING.md` for how to extend the skill, add new steps, or modify the persona table.

## License

MIT — see `LICENSE`.
