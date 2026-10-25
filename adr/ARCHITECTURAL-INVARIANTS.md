# Architectural Invariants — GSD Master / Mission Controller Architecture

These are rules that must hold regardless of implementation. They are derived from the
architecture developed in 2026-07 and recorded in `ADR-000-why-v3.4-not-released.md`.

Invariant 07 is the foundational boundary rule for this architecture: it governs what the
architecture currently contains. Invariant 08 governs how the architecture is allowed to grow.
Both are numbered to extend the ecosystem invariant sequence; invariants 01–06 are reserved for
a broader consumer system and are not enumerated here.

---

## Invariant 07

> **Execution artifacts must never expose runtime implementation details.**

An *execution artifact* is anything an Execution Engine (GSD Master) produces for consumption by
a layer above it (e.g. the Mission Controller) — principally the **Execution Contract**. A
*runtime detail* is anything about the environment in which the work was performed: which agent,
which rules were loaded, what was cached, how the sandbox was configured.

The two must never be mixed. The contract describes **the work**; the runtime describes
**the environment**.

### ✅ Belongs in an Execution Contract (the work)

- tests passed
- review completed
- confidence
- artifacts produced

### ❌ Must never appear (runtime / environment)

- calibration status
- prompt synchronization
- loaded instruction files
- cache state
- MCP configuration
- sandbox configuration

### Why

Mixing the two couples "what was built" to "what agent/rules were active when it was built."
That coupling (concretely, the `**Calibration:**` field v3.4 tried to inject into the contract —
see ADR-000) forces every consumer to understand the runtime, prevents the execution engine
from being swapped or run under different runtimes, and leaks environment state across a boundary
that should carry only results.

Enforcing Invariant 07 keeps the Execution Engine interchangeable and the Mission Controller
runtime-agnostic.

---

## Invariant 08

> **Prefer evolution over proliferation.** Before introducing a new architectural primitive,
> determine whether an existing primitive can be extended without violating its
> responsibilities or architectural boundaries. New primitives should only be introduced when
> extension would compromise separation of concerns, ownership, or architectural clarity.

### Why

This is not a one-off preference; it emerged from repeatedly applying the same test and getting
the same answer, across three separate decisions:

- **Mission Policy** (`RFC-0001-mission-policy.md`) was deliberately *not* proposed as a new
  artifact sitting beside `budget` — the RFC explicitly leaves open whether it's `budget`
  generalized rather than a parallel object, and puts the burden of proof on the new primitive.
- **Execution Journal** was considered and set aside before being written up, pending the same
  question against `LoopState` (ADR-003) — is this a new artifact, or `LoopState` extended?
- **Calibration** (ADR-000) was rejected from the Execution Engine specifically because it tried
  to make the Execution Contract carry a second kind of information (runtime state) rather than
  extending an existing, correctly-scoped concept (Runtime configuration, owned elsewhere).

In each case, minting a new primitive first would have produced an architecture with more moving
parts than the problem required, and — per Invariant 07's core lesson — parallel primitives are
exactly how boundary-crossing leaks happen. Proposers of a new RFC or ADR are expected to show
this test was applied, not merely assert that a new concept was needed.
