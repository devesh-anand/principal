---
references:
  - skills/reconcile-docs/SKILL.md
last_verified: caf16cd
---

# Glossary

**Living docs** — `architecture/`, `components/`, `guides/`, `glossary.md`.
Overwritten freely to match the current code.

**Immutable docs** — `decisions/` (ADRs). Append-only; a wrong one is superseded
by a new ADR that references it, never edited or deleted.

**ADR** (Architecture Decision Record) — a timestamped record of a decision and
its rationale. The durable "why".

**Dissolve** — what happens to a finished plan: rationale → an ADR, current-state
→ living docs, task checklist → deleted. Plans never survive as artifacts.

**Manifest** — `docs/README.md`. One navigable line per doc; the entry point
`load-context` reads. Navigate, don't bulk-load.

**Architectural surface** — the set of changes the gate treats as
doc-worthy: added/removed modules, dependency-manifest changes, schema/contract
changes. Excludes pure modifications (bugfixes/refactors).

**Escape hatch** — a `docs: n/a` line in a commit/PR message that bypasses
doc-gate deliberately.

**Forcing functions** — the four independent mechanisms that keep docs honest:
dogfooding, the PR-gate, verifiable references, and the periodic sweep.

**Dogfooding** — the agent reading docs first (`load-context`); stale docs cause
visibly wrong behavior, which surfaces the staleness.

**Reconcile modes** — `reconcile-docs` runs as **Bootstrap** (no docs yet),
**Incremental** (a change set), or **Sweep** (periodic audit).

**`references` / `last_verified`** — living-doc frontmatter. `references` lists
the files/symbols a doc describes (mechanically checked); `last_verified` is the
commit sha at which the doc was last reconciled (drives decay detection).

**Decay** — a living doc whose referenced files changed since its `last_verified`
sha; queued for reconciliation by the sweep.
