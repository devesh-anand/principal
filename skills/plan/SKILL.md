---
name: plan
description: >
  Decompose a validated design into a transient, bite-sized task list with file
  paths and verification steps. The plan is explicitly disposable scaffolding —
  it lives in a scratch location and is deleted when reconcile-docs dissolves the
  work. It is never treated as knowledge.
---

# plan

Turns a validated design (from `brainstorm`, with its draft ADR) into an
executable task list. The defining rule of Principal: **a plan is scaffolding,
not an artifact.** It exists to guide execution and then it dies.

## Where plans live

`.principal/plans/<slug>.md` — a scratch location, **gitignored**. Plans are not
committed and not part of the knowledge base. Keeping them out of the repo is
deliberate: a plan in version control is the stale corpse Principal exists to
avoid.

The file opens with a banner so no one mistakes it for truth:

```
> TRANSIENT — execution scaffolding, not knowledge.
> reconcile-docs deletes this on completion. Durable truth lives in /docs.
```

## Procedure

1. **Take the validated design** and its draft ADR (`docs/decisions/ADR-NNNN`).
2. **Decompose into bite-sized tasks** — each small enough to verify in one sitting,
   with the exact files to touch and a concrete verification step (a test, a
   command, an observable outcome). Order by dependency.
3. **Write the plan** to `.principal/plans/<slug>.md` with the transient banner
   and a pointer back to the ADR it implements.
4. **Execute** the tasks (here or via your normal execution flow), checking each
   off as its verification passes.
5. **Finish by dissolving.** When the work ships, run `reconcile-docs`:
   - the draft ADR is finalized (`proposed` → `accepted`), reconciled against
     what *actually* shipped;
   - the affected living docs are updated to match reality;
   - **this plan file is deleted.**

## Integrity

- Plan against the design, but expect to diverge — when execution forces a
  change, the *docs and ADR* capture the truth at dissolve time, not the plan.
- Never promote a plan into `/docs`. If something in the plan turns out to be
  durable knowledge, it belongs in a living doc or an ADR — written there, not
  copied from the checklist.

## What this is NOT

- Not a design exercise — decisions belong in the ADR from `brainstorm`.
- Not a permanent record — that's what the dissolve step prevents.
