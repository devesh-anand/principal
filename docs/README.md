# Principal — knowledge base

The living source of truth for this repository. Read this manifest first, then
navigate to the doc you need — don't bulk-load the tree. Maintained by
`reconcile-docs`; baseline established at commit `4a13aab` (see
[ADR-0000](decisions/ADR-0000-baseline.md)).

## Architecture
- [architecture/overview.md](architecture/overview.md) — what Principal is, its three components, the Principal loop, and the founding principles.

## Components
- [components/skills.md](components/skills.md) — the agent-facing skills (`reconcile-docs`, `load-context`, `brainstorm`, `plan`) and the full loop.
- [components/doc-gate.md](components/doc-gate.md) — the shared detector + three enforcement layers (in-session / commit-msg / CI).
- [components/packaging.md](components/packaging.md) — plugin manifests, install paths, the `"./"` source gotcha.

## Decisions (immutable)
- [decisions/ADR-0000-baseline.md](decisions/ADR-0000-baseline.md) — knowledge base baseline.
- [decisions/ADR-0001-workflow-front.md](decisions/ADR-0001-workflow-front.md) — decision-shaped brainstorm, transient plan.

## Reference
- [glossary.md](glossary.md) — the methodology's vocabulary.
