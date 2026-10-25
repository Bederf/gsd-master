# Public Developer Preview

## Product boundary

GSD Master is a development lifecycle skill for Claude Code. It structures and
governs software-development phases; it is not a coding agent, runtime, SDK,
framework or standalone platform.

The project remains responsible for its domain invariants, authority model,
approval vocabulary, repository policy and deployment controls. GSD records and
enforces those project-declared boundaries; it does not invent them.

## Lifecycle

```text
intent
  → phase specification
  → dependency and phase-gate validation
  → scope and risk triage
  → design and architecture review
  → authorised delegated implementation
  → test evidence
  → independent review
  → bounded remediation
  → documentation and closeout
  → execution contract
```

The lifecycle is fail-closed around missing specifications, failed gates,
missing evidence, malformed review results and unresolved blockers.

## External project inputs

A usable project integration supplies:

1. a vault root containing the phase artifact and its
   `Phase-{id}.specification.json` sidecar;
2. project-specific authority and decision sources;
3. any required `.gsd-engine/skill-manifest.yaml` and
   `.gsd-engine/review-providers.yaml` files;
4. a project-approved independent-review provider when the phase requires one;
5. the project's own test commands and evidence locations.

The public package does not include a consumer vault, provider credentials,
private runtime or production authority configuration.

## First-run example

Copy the example phase and sidecar into the project's configured vault root,
then invoke:

```text
gsd:master 001
```

The example is intentionally a documentation fixture. The project's configured
`phase-specification.v1` validator remains authoritative for execution.

## Known limitations

- Claude Code is the supported host for this preview.
- Provider integrations are project-configured rather than bundled.
- GSD prepares test commands and requires returned evidence; it does not claim
  test success without operator or qualified-executor output.
- Greploop is optional and only applies to PR-targeted work where the project
  has configured it and GitHub access is intentionally available.
- Public release does not imply approval to deploy, merge or consume results in
  any particular production system.

## Extension guidance

Contributions should improve lifecycle behavior, contract clarity, evidence
quality, review routing, failure handling or public usability. Project-specific
providers and authority policies belong in the consuming project or in a
separately governed adapter.
