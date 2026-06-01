# ADR-0001 — Workflow front: decision-shaped brainstorm, transient plan

- **Status:** accepted
- **Date:** 2026-06-01
- **Supersedes:** none

## Context

Principal's whole premise is that plans go stale because they are kept as
artifacts. The front of the workflow (`brainstorm`, `plan`) had to be designed so
it *feeds* the dissolve loop rather than re-introducing durable plan corpses.

## Decision

1. **`brainstorm` output is decision-shaped, not plan-shaped.** It produces a
   *draft* ADR (status `proposed`) — the decision, rejected alternatives and
   why, and a forward-pointer to the living docs the work will touch. The
   decision and its rationale are the part worth keeping, so they are captured as
   immutable knowledge from the start.
2. **`plan` output is transient and uncommitted.** Plans live in
   `.principal/plans/<slug>.md`, which is gitignored. A plan is execution
   scaffolding; keeping it out of version control is what prevents the stale
   corpse problem.
3. **Dissolution finalizes, not archives.** On completion `reconcile-docs`
   flips the ADR `proposed → accepted` (reconciled against what actually
   shipped), updates living docs, and deletes the plan file.

## Alternatives rejected

- *Plan committed under `docs/` or an `archive/`* — rejected: this is exactly the
  staleness Principal exists to eliminate.
- *Brainstorm emits a free-form design doc* — rejected: a design doc is neither
  durable decision (ADR) nor disposable scaffolding (plan); it would drift into a
  third, unmaintained lifecycle.

## Consequences

- Decisions are captured early (as `proposed` ADRs) and survive even if a plan is
  abandoned.
- Plans leave no trace in the repo; the audit trail is the ADR, not the checklist.
- This ADR was authored from attested rationale (designed in-session), per the
  bootstrap rule refined in `reconcile-docs`.
