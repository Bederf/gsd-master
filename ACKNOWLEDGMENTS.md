# Acknowledgments

## GSD Core

GSD Master is adapted from **[GSD Core](https://www.npmjs.com/package/@opengsd/gsd-core)** (`@opengsd/gsd-core`) by the OpenGSD team, licensed under MIT.

GSD Core is a context-engineering and spec-driven development framework that drives AI coding agents through a disciplined phase loop:

> **Discuss → Plan → Execute → Verify → Ship**

It solves context rot by running heavy research, planning, and execution work in fresh-context subagents while keeping the main session lean. STATE.md and CONTEXT.md survive session boundaries, and the verify step walks through what was built and generates fix plans before a phase is declared done.

**GSD Master** takes GSD Core's phase-loop framework and adapts it for multi-plan, multi-phase orchestration with strict pre-flight validation and autonomous review. It is not a fork of the GSD Core source code — it is a re-implementation of the same conceptual model with a different process shape, optimized for projects where phases span 4+ files, security-sensitive code, and PR-targeted work.

### What GSD Master Adds

GSD Master extends GSD Core's five-step loop with:

- **Step 0.5: Specification validation gate** — requires 6 fields (problem, acceptance criteria, dependencies, phase gate, trade-offs, version) plus pre-flight dependency checks before any execution starts
- **Mandatory dual review** — Paranoid Review (Opus) + Codex validation (GPT-4o) on every code change, regardless of phase size
- **Greploop PR review (Step 9)** — autonomous PR review + fixing loop with read-only guard for unauthenticated environments
- **Test harness with baseline diff (Step 6)** — runs pytest/vitest, diffs against `.gsd-test-baseline.json`, blocks on new failures
- **Stall detection (Step 6.5)** — appends BLOCKER-NNN and escalates if execution stalls for 30+ minutes
- **Three argument modes** — `{phase-number}` (full validation), `plan:` (pre-reviewed spec), `improvement-candidate:` (skill self-analysis)
- **Agent Skills defensive patterns** — `<triggers>`, `<rationalizations>`, and `<examples>` sections to prevent misapplication

### Configuration Compatibility

GSD Master is configurable via frontmatter `config:` block, with defaults that align with GSD Core's conventions:

```yaml
config:
  vault_path: "vault"                   # Phase file root (GSD Core uses .planning/ by default)
  precheck_skill_path: "skills/gsd/precheck-gate.md"  # Optional external precheck skill
  default_model: "gpt-4o"               # Codex default
```

Users migrating from GSD Core can set `vault_path: ".planning"` to use GSD Core's native phase file structure.

### Why a Separate Project?

GSD Core is excellent for general AI-assisted development. GSD Master optimizes specifically for:

- Multi-plan, multi-wave phases that need DAG-style reconciliation
- Phases that produce security-sensitive or physical-impact code (auth, payments, device control)
- PR-targeted work that needs autonomous review + fix loops
- Environments where pre-flight validation is more important than context flexibility

If your workflow is a single-developer project with simple linear phases, **GSD Core is likely a better fit**. If your workflow involves strict gates, dual review, and PR autonomy, GSD Master is the targeted adaptation.

### License

Both GSD Core and GSD Master are licensed under MIT. See `LICENSE` for the full text.

---

## See Also

- GSD Core documentation: https://www.npmjs.com/package/@opengsd/gsd-core
- GSD Master repository: https://github.com/Bederf/gsd-master
- Agent Skills specification: https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview
