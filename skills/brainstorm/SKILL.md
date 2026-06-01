---
name: brainstorm
description: >
  Refine a rough idea into a validated design before any code is written.
  Asks sharp questions, explores alternatives, and presents the design in
  digestible sections for sign-off. Its output is decision-shaped: a draft ADR
  capturing the choice, the rejected alternatives, and the docs the work will
  touch — the front of Principal's dissolve loop.
---

# brainstorm

The front of the Principal workflow. Where a vague idea becomes a design the
user has actually validated — and, crucially, where the *decision and its
rationale* are captured so they survive as durable knowledge.

Unlike a plan (transient scaffolding), brainstorm's output is **decision-shaped**.
It feeds the dissolve loop: the decision becomes an ADR.

## Procedure

1. **Orient first.** Run `load-context` — read the docs that bound this idea.
   You cannot brainstorm well against a system you haven't loaded; existing ADRs
   and invariants are exactly the constraints that kill bad ideas early.
2. **Refine the idea.** Ask the questions that change the answer — scope,
   constraints, the real problem behind the stated one. Surface assumptions.
   Don't proceed on a fuzzy target.
3. **Explore alternatives.** Present 2–4 genuinely different approaches with
   honest trade-offs. Recommend one, but make the others real. Pressure-test the
   favorite — name how it could fail.
4. **Present in sections, validate each.** Don't dump a finished design. Walk
   through it in digestible pieces and get a read on each before moving on.
5. **Capture the decision as a draft ADR.** When the design is validated, write
   `docs/decisions/ADR-NNNN-<slug>.md` with status `proposed`: the decision, the
   rationale, the alternatives rejected and *why*, and consequences. This is the
   knowledge that plan-centric workflows lose.
6. **Forward-point.** In the draft ADR, list the living docs the implementation
   will touch — a map for `reconcile-docs` to follow later.
7. **Hand off to `plan`.**

## Integrity

- Record only attestable rationale — what was actually reasoned, not a tidy
  post-hoc story.
- The ADR is `proposed`, not `accepted`, until the work ships and
  `reconcile-docs` finalizes it. Reality may still diverge.

## What this is NOT

- Not planning. No task breakdown here — that's `plan`.
- Not a rubber stamp. If the idea doesn't survive the questions, say so.
