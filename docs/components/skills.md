---
references:
  - skills/reconcile-docs/SKILL.md
  - skills/load-context/SKILL.md
  - skills/brainstorm/SKILL.md
  - skills/plan/SKILL.md
last_verified: 393fa20
---

# Component: skills

The agent-facing half of Principal — two Claude Code skills that drive the
methodology. Each is a `SKILL.md` with `name`/`description` frontmatter; the
folder name is the skill name, namespaced on install as `/principal:<name>`.

## `reconcile-docs` — keep `/docs` true

`skills/reconcile-docs/SKILL.md`. The core skill. One skill, three modes,
auto-selected from repo state:

- **Bootstrap** (`docs/` absent/empty) — explore the whole codebase, build the
  initial knowledge base. Documents *what is*, never fabricates *why*: writes
  one `ADR-0000` baseline rather than inventing rationale.
- **Incremental** (a change set is in play) — reconcile affected living docs to
  what actually shipped, and dissolve any finished plan.
- **Sweep** (periodic, no change set) — re-run mechanical reference checks and
  flag decayed docs.

It owns the doc taxonomy (`architecture/`, `components/`, `decisions/`,
`guides/`, `glossary.md`, the `README.md` manifest) and the living-doc
frontmatter contract (`references`, `last_verified`).

## `load-context` — read docs first

`skills/load-context/SKILL.md`. The consumer. At the start of a task it reads
the `docs/README.md` manifest, navigates to the relevant docs (never bulk-loads
the tree), and treats them as the starting model of the system. When code
contradicts a doc, that drift is the dogfooding signal — it's flagged for
`reconcile-docs`.

## `brainstorm` — refine an idea into a decision

`skills/brainstorm/SKILL.md`. The front of the workflow. Orients via
`load-context`, asks the questions that change the answer, explores real
alternatives, and validates the design in sections. Its output is
**decision-shaped**: a *draft* ADR (status `proposed`) capturing the choice, the
rejected alternatives and why, and a forward-pointer to the living docs the work
will touch. Hands off to `plan`.

## `plan` — transient execution scaffolding

`skills/plan/SKILL.md`. Decomposes the validated design into bite-sized tasks
with file paths and verification steps, written to `.principal/plans/<slug>.md`
— **gitignored, never committed, never knowledge**. On completion,
`reconcile-docs` dissolves it: the ADR is finalized, living docs updated, and the
plan file deleted. See [ADR-0001](../decisions/ADR-0001-workflow-front.md).

## Relationship — the full loop

`brainstorm` (decision) → `plan` (transient tasks) → execute → `reconcile-docs`
(dissolve: finalize ADR, update living docs, delete plan). `load-context`
surfaces staleness → `reconcile-docs` fixes it. See
[architecture/overview.md](../architecture/overview.md).
