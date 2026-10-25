# M1 Acceptance Criteria — Stable Execution Engine

**Purpose:** answer one question — *How do we know the architecture is ready for M2?*

This is an **architectural acceptance gate**, not a code-test suite. It validates that the
boundaries, interfaces, and records produced during M1 actually hold — independent of whether the
engine passes unit tests.

**Verdict:** M1 is accepted. All five criteria pass, with one explicit nuance: the Execution
Contract spec is DRAFT, so its *empirical* validation against a real consumer is deferred to M2's
mock-first approach. M1 requires a specified and leakage-free contract — which exists.

Related: `ADR-000-why-v3.4-not-released.md`, `ARCHITECTURAL-INVARIANTS.md`,
`../docs/execution-contract-specification-v1.0.md`, `MILESTONES.md`.

---

## AC-1 — GSD Master can execute a complete phase independently
**✅ Pass.** GSD Master v3.3.0 (Stable Reference Implementation) runs a phase end-to-end on its
own: argument routing → spec validation → DAG/waves → test harness → Paranoid/Codex/Greploop
review → documentation → Execution Contract (SKILL.md Steps 0–11). No external controller is
required for it to function.

## AC-2 — The Execution Contract is sufficient for an external controller to decide what to do next
**✅ Pass by design / ⚠️ empirical validation deferred.** The v1.0 spec
(`../docs/execution-contract-specification-v1.0.md`) carries the fields a controller needs to
decide continue/stop: `status` (terminal state), `confidence` (outcome strength),
`next_action` (the single next step), plus `reviews` and `artifacts` for context. On paper this
is sufficient. The *live* validation — proving a controller can act on it — is the explicit job
of M2, where the Mission Controller is built against a mock first. **This criterion is satisfied
at the specification level; M2 is the empirical proof.**

## AC-3 — The contract avoids runtime leakage
**✅ Pass.** Invariant 07 (`ARCHITECTURAL-INVARIANTS.md`) forbids runtime details in execution
artifacts, and the spec's "Explicitly OUT of scope" section enumerates them (calibration, prompt
sync, instruction files, cache, MCP, sandbox). The v3.4 `**Calibration:**` leak was identified
in ADR-000 and explicitly excluded. The v3.3 live contract already omits runtime fields.

## AC-4 — All architectural invariants are satisfied
**✅ Pass (in scope).** The single invariant defined for this architecture (Invariant 07) holds
by construction across the ADR and the spec. Invariants 01–06 for the broader consumer system are
reserved and outside M1's scope; they will be checked when defined.

## AC-5 — Another developer can understand the architecture from the ADRs and specs alone
**✅ Pass.** The trail is self-contained and cross-linked: ADR-000 (context + decision),
ARCHITECTURAL-INVARIANTS.md (Invariant 07), the v1.0 spec (interface), and MILESTONES.md
(M1/M2). A reader can reconstruct *why* v3.4 was abandoned and *where* the work moved without
access to any chat history.

---

## The one nuance
AC-2 is proven on paper but not yet empirically. That is intentional: M2's mock-first rule (below)
is the validation step. M1 does **not** require a working consumer — it requires a *specified and
leakage-free* contract, which exists. The Execution Contract spec remains DRAFT until M2 agrees
it against a real (mock) consumer; promoting it to AGREED is an M2 action, not a blocker for M1.

## M2 Entry Rule — Mock-First
M2 may begin only under this rule:

> **The Mission Controller may not contain a single line of GSD-specific logic. It may only
> depend on the Execution Engine Interface.**

The controller is built and tested against a **Mock Execution Engine** first. Only once it drives
a phase, receives an Execution Contract *through the interface*, and decides continue/stop using
only that contract, is GSD Master connected as the first concrete implementation.

```
Mission Controller
        │
Execution Engine Interface   ← the only thing the controller knows
        │
        ├── GSD Master            (concrete — connected last)
        ├── MockExecutionEngine   (used first — proves decoupling)
        └── FutureExecutionEngine (proves the interface is real, not GSD-shaped)
```

If GSD Master can be swapped for a mock without changing the controller, the interface is
genuinely decoupled rather than conceptually convenient. This prevents GSD-specific assumptions
from leaking *up* into the controller — the mirror-image of the Runtime-leakage problem Invariant
07 guards against *down* at the contract boundary.
