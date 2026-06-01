# ADR-0000 — Knowledge base baseline

- **Status:** accepted
- **Date:** 2026-06-01
- **Commit:** 4a13aab

## Context

This `/docs` knowledge base was established by `reconcile-docs` in **Bootstrap
mode** against the Principal repository at commit `4a13aab`. Per the bootstrap
procedure, a bootstrap documents *what is* and does not fabricate decision
records for rationale it cannot verify.

## Decision

Seed the knowledge base with the living docs (architecture, components,
glossary) describing the code as it exists at this commit, and record this single
baseline ADR rather than inventing a decision history.

Principal's founding design principles — plans dissolve, two doc lifecycles,
four forcing functions, a conservative gate — are real decisions made while the
code was built. They are recorded as **principles** in
[architecture/overview.md](../architecture/overview.md) rather than as
back-dated ADRs.

## Consequences

- The living docs are a *baseline*, expected to be corrected by the first few
  incremental reconciliations.
- Future decisions get their own ADRs (`ADR-0001`, …) via incremental
  `reconcile-docs`, superseding earlier ADRs by reference rather than edit.

## Note (a dogfooding finding)

Bootstrapping a repo whose rationale *is* known to the author (here, the same
session that wrote the code) strains the "exactly one ADR" rule — capturable
rationale risks being under-recorded. Candidate refinement to the
`reconcile-docs` skill: allow Bootstrap to seed ADRs from rationale the operator
can attest to, while still refusing to *invent* rationale for foreign code.
