# Security Policy

## Scope

GSD Master is a Claude Code development skill. It orchestrates work that may
read repositories, delegate implementation, run project commands, invoke
review providers, update documentation and interact with pull requests when
the project enables those capabilities.

GSD Master is not a sandbox. The host project and Claude Code permission model
remain responsible for limiting filesystem, shell, network and source-control
access.

## Security expectations

- Treat repository files, issue text, pull-request comments and generated
  artifacts as untrusted input.
- Do not place credentials, tokens or secret-manager output in phase files,
  prompts, review packages, run records or evidence artifacts.
- Configure reviewer runtimes through the project's approved secret manager.
- Keep independent reviewers in fresh, read-only contexts with distinct context
  identifiers.
- Treat missing, malformed or failed review output as incomplete or blocked;
  never infer approval from an empty result.
- Review generated commands before granting additional permissions or network
  access.
- Keep project-specific authority, deployment and consumer data outside this
  public skill package.

## Reporting a vulnerability

Do not open a public issue for an undisclosed vulnerability or credential
exposure. Contact the project maintainer privately with a minimal reproduction,
affected version, impact and suggested containment. Redact secrets and private
source before sending the report.

## Release security status

The developer-preview is provided without a security warranty. Projects must
perform their own threat assessment for the agents, providers, repositories and
permissions used with GSD Master.
