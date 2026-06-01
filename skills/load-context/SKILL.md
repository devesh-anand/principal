---
name: load-context
description: >
  Before working on a codebase, load its /docs knowledge base as context: read
  the manifest, navigate to the docs relevant to the task, and treat them as the
  current truth. This is Principal's dogfooding loop — using the docs is what
  surfaces their staleness and triggers a reconcile.
---

# load-context

The consumer half of Principal. `reconcile-docs` keeps `/docs` true;
`load-context` makes the agent actually *use* it — which is the cheapest and
strongest forcing function, because stale docs now produce visibly wrong
behavior that you feel immediately.

## When to run

At the start of any non-trivial task on a repo that has a `docs/README.md`,
before reading source or making changes. If there's no `docs/README.md`, the
knowledge base hasn't been built — suggest running `reconcile-docs` (it will
bootstrap) and proceed without it.

## Procedure

1. **Read the manifest** — `docs/README.md`. It's one line per doc by design;
   reading it is cheap. Do **not** bulk-load the whole `docs/` tree.
2. **Map the task to docs.** From the manifest, select only what's relevant:
   - the architecture overview (almost always)
   - the `components/` doc(s) for the subsystem(s) the task touches
   - any `decisions/` ADRs that constrain this area (the "why you can't just…")
   - `glossary.md` if the task uses unfamiliar domain terms
   Navigate; don't hoard. Context budget is real.
3. **Load the selected docs** and use them as your starting model of the system —
   what exists, why it's shaped this way, what's load-bearing, what not to touch.
4. **Verify as you act.** Docs are the *starting* truth, not gospel. When you
   touch the actual code, watch for contradictions between doc and reality.

## The dogfooding signal (do not skip this)

If the code contradicts a doc — a function the doc describes is gone, a stated
invariant no longer holds, a referenced file moved — **that is the system
working as designed.** The staleness just surfaced through use. Do two things:

- Don't trust the stale doc for the rest of the task; trust the code.
- **Flag it for reconciliation.** Note the drift and, when the work is done,
  let `reconcile-docs` fold the correction in. Staleness that's noticed and
  fixed is the whole point; staleness that's silently worked around defeats it.

## What this skill is NOT

- Not a substitute for reading code — it's the *orientation* before you do.
- Not bulk context-stuffing — loading all docs every task blows the budget and
  trains you to ignore them. Navigate via the manifest.
