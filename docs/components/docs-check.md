---
references:
  - bin/docs-check.sh
  - .github/workflows/docs-check.yml
last_verified: 393fa20
---

# Component: docs-check

The mechanical verifier for the knowledge base. Where `doc-gate` enforces *that a
change updated the docs*, `docs-check` enforces *that the docs are internally
sound* — turning two forcing functions (verifiable references + the periodic
sweep) from prose into a runnable command.

## The tool — `bin/docs-check.sh`

Scans every *living* doc (any doc carrying a `references:` block) and runs three
checks:

| Check | Meaning | Severity |
|-------|---------|----------|
| **references resolve** | every path in `references:` exists | `ERROR` — exit 1 |
| **decay** | a referenced file changed since the doc's `last_verified` sha | `DECAY` — warning |
| **coverage** | a top-level code dir that no doc references | `COVER` — warning (heuristic) |

`--strict` escalates warnings to a non-zero exit. Tune via a repo-local
`.principal/docs-check.conf` (overrides `DOCS_DIR`, `COVERAGE_IGNORE_REGEX`).

Immutable docs (`decisions/` ADRs) carry no `references:`/`last_verified` and are
skipped — they are never reconciled, so they cannot decay.

## How it's wired

- **Sweep** — `reconcile-docs` (Sweep mode) runs this for its mechanical steps,
  then reconciles the flagged docs.
- **CI** — `.github/workflows/docs-check.yml` runs it on push/PR; broken
  references fail the build, decay/coverage are reported.

## Relationship to doc-gate

Complementary, not redundant: `doc-gate` looks at a *diff* ("did this change
touch docs?"); `docs-check` looks at the *docs themselves* ("do they still point
at real, current code?"). Together they cover both directions of drift. See
[doc-gate.md](doc-gate.md).
