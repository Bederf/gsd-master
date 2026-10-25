# Execution Contract Specification — v1.0 (DRAFT)

- **Status:** Draft — for agreement before implementation
- **Date:** 2026-07-08
- **Owner layer:** GSD Master (Execution Engine) → consumed by the Mission Controller
- **Related:** `adr/ADR-000-why-v3.4-not-released.md`

## Purpose

Define the **interface** between the Execution Engine (GSD Master) and everything above it (the
Mission Controller). This is a *language-neutral specification*. Concrete bindings
(JSON Schema, Python dataclass, Pydantic model, TypeScript interface) are derived **from this
document**, not the other way around.

This contract is the one v3.4 item promoted from "feature" to "interface specification" (see
ADR-000). Its basis is the structured fields already present in GSD Master **v3.3** (§8.4
`codex_review`, §9.6 `greploop_review`) — which v3.4 erroneously removed.

## Governing principle

> **Execution Contracts describe the work. Runtime describes the environment.**
> Those two must never be mixed.

Therefore the contract contains **only execution state** — what was attempted, what was produced,
what was verified, and what to do next. It contains **no Runtime state**: no agent identity, no
calibration status, no instruction-file configuration, no environment details. (See
`**Calibration:**` in ADR-000 as the counterexample this rule forbids.)

## Structure (language-neutral)

```yaml
ExecutionContract:
  phase:            string            # phase identifier, e.g. "001"
  status:           enum              # completed | partial | validation_failed | execution_failed
  plans_completed:  PlanSummary       # what was executed
  tests:            TestSummary       # verification state
  reviews:          ReviewSummary     # gate outcomes
  routing:          RoutingSummary    # provider selection and skips
  review_cycles:    ReviewCycleSummary # bounded correction-cycle references
  evidence:         EvidenceSummary   # returned evidence references
  confidence:       Confidence        # aggregated outcome confidence
  artifacts:        ArtifactList      # outputs produced
  next_action:      string            # what the consumer should do next
```

## Field definitions

### `phase` — string — required
Identifier of the executed phase. Opaque to the contract; the Mission Controller maps it to its
own goal state.

### `status` — enum — required
Terminal state of this execution.
- `completed` — all steps ran to the contract's satisfaction.
- `partial` — stopped at max iterations / partial review (e.g. Greploop hit its cap).
- `validation_failed` — Step 0.5 spec validation or pre-flight failed before execution.
- `execution_failed` — a review gate blocked (critical divergence, etc.).

### `plans_completed` — PlanSummary — required
```yaml
PlanSummary:
  total:      integer   # plans in the phase
  executed:   integer   # plans actually run
  waves:      integer   # wave groups executed (Ralph/Standard)
```

### `tests` — TestSummary — required
```yaml
TestSummary:
  ran:          boolean
  passed:       integer
  total:        integer
  regressions:  integer   # count of regressions vs baseline
```
Reported even when `ran: false` (so the consumer sees the gap explicitly).

### `reviews` — ReviewSummary — required
Aggregates the three review gates from v3.3's structured fields.
```yaml
ReviewSummary:
  paranoid:
    status:    enum      # passed | blocked
  codex:
    effort:    enum      # MEDIUM | HIGH | SKIPPED
    issues_found: integer
    severity:  enum      # critical | high | medium | low | none
    vs_paranoid: enum     # agrees | diverges_minor | diverges_critical
  greploop:
    pr_number:  integer | null
    status:     enum      # approved | partial | skipped
    confidence: string    # "5/5" | "N/5" | "SKIPPED"
    fixes_applied: integer
    iterations: integer
    open_comments: integer
    labels_added: [string]
```
`codex` and `greploop` shapes are taken verbatim from v3.3 §8.4 / §9.6.

### `routing` — RoutingSummary — required

```yaml
RoutingSummary:
  considered: [string]              # providers evaluated by registry policy
  selected: [string]                # providers whose conditions matched
  independent_reviewer: string | null
  review_cycles: integer             # 0 for a first pass; maximum 3 corrections
  skipped:
    - name: string
      reason: string                 # condition_not_matched | not_installed | not_applicable | read_only_mode
```

Routing is derived from factual change classification and the project provider
registry. Providers do not select or invoke one another. Elective-provider
absence is represented as a skip and does not, by itself, make the execution
incomplete.

### `review_cycles` — ReviewCycleSummary — required when files changed

```yaml
ReviewCycleSummary:
  cycles:
    - cycle_ref: string
      revision_ref: string
      review_result_ref: string
      finding_refs: [string]
      outcome: PASS | CHANGES_REQUIRED | INCOMPLETE_REVIEW | BLOCKED | ESCALATED
      next_action: implement_fix | re_review | forge_verify | escalate | stop
  current_cycle: integer
  max_cycles: 3
```

Each `cycle_ref` resolves to a `review-cycle.v1` record. GSD owns the loop and
completion decision; this summary does not authorize a revision, declare work
complete, or replace Forge verification. `PASS` routes to Forge verification,
not directly to completion. A third unsuccessful cycle must end in escalation
or stop.

### `evidence` — EvidenceSummary — required

```yaml
EvidenceSummary:
  record: string                    # path to gsd-review-evidence.v1 record
  providers:
    - name: string
      version: string | null
      status: string                 # passed | findings | failed | skipped
      finding_count: integer
      evidence_ref: string | null
```

The evidence record must distinguish a provider that ran from one that was
skipped. A review result without a returned result or evidence reference must
not be reported as passed.

An implementation agent and its independent reviewer must have separate
contexts. Same-session self-review cannot satisfy the independent-review gate.
`CHANGES_REQUIRED` and `BLOCKED` remain non-terminal until a later review cycle
passes or the bounded cycle limit is escalated.

### `confidence` — Confidence — required
```yaml
Confidence:
  score:  string    # e.g. "5/5" (from Greploop) or aggregated
  basis:  string    # what the score is derived from, e.g. "greploop_review"
```

### `artifacts` — ArtifactList — required
Outputs the consumer can act on.
```yaml
ArtifactList:
  pr_url:    string | null   # "https://github.com/{owner}/{repo}/pull/{n}"
  vault_docs: [string]       # paths to updated phase/vault documentation
  notes:     [string]        # free-form artifact pointers
```

### `next_action` — string — required
The single next step the Mission Controller should take, e.g.
`gsd:verify-work 001`. Never a Runtime instruction.

## Explicitly OUT of scope (Runtime, not the contract)

- Agent identity / which model or harness ran the phase.
- Calibration status, instruction-file gap matrices, `karpathy-sync` output.
- Environment, OS, paths, configuration of the executing machine.
- Mission-level state (goal progress, cross-phase decisions) — that lives in the Mission
  Controller, which *consumes* this contract.

## Versioning

- This specification is versioned independently of GSD Master (currently v1.0, DRAFT).
- A contract is backward-compatible if a consumer can ignore unknown fields. Breaking changes
  bump the major version and are agreed before any binding is regenerated.

## Next step (do not do yet)

Once this spec is agreed, generate the bindings in this order:
1. `execution_contract.schema.json` (JSON Schema) — primary interface artifact.
2. Python dataclass (stdlib).
3. Pydantic model (if/when a validator is needed).
4. TypeScript interface (for the Mission Controller MVP).

The schema is derived from this specification, never the reverse.
