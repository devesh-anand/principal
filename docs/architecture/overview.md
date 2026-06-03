---
references:
  - skills/reconcile-docs/SKILL.md
  - skills/load-context/SKILL.md
  - hooks/doc-gate.sh
  - .claude-plugin/plugin.json
last_verified: caf16cd
---

# Architecture overview

Principal is a **Claude Code plugin** that encodes a development *methodology*:
keep a codebase's `/docs` directory as its single living source of truth, treat
plans as disposable scaffolding, and continuously reconcile the docs against the
code so a fresh agent inherits the context of a principal engineer.

There is no application runtime. The "codebase" is the plugin itself —
Markdown skill specs the agent reads, Bash hooks that enforce the methodology,
and JSON manifests that make it installable.

## Components

| Component | What it is | Doc |
|-----------|-----------|-----|
| **skills** | The agent-facing methodology: `brainstorm`, `plan`, `reconcile-docs`, `load-context`. | [components/skills.md](../components/skills.md) |
| **doc-gate** | The diff-side enforcer: one detector behind three layers (in-session hook, git commit-msg, CI). | [components/doc-gate.md](../components/doc-gate.md) |
| **docs-check** | The docs-side verifier: `bin/docs-check.sh` checks references resolve, detects decay, flags coverage. | [components/docs-check.md](../components/docs-check.md) |
| **packaging** | The `.claude-plugin/` manifests that distribute and install Principal. | [components/packaging.md](../components/packaging.md) |

## How they connect — the Principal loop

```
load-context ─▶ work (brainstorm → plan → execute) ─▶ reconcile-docs
     ▲                                                      │
     └──────────────── docs/ (the knowledge base) ◀─────────┘
                              ▲
                      doc-gate enforces the loop ran
```

1. **`load-context`** reads `docs/README.md` and the relevant docs before any
   work. Using stale docs produces visibly wrong behavior — that's the primary,
   self-correcting forcing function (dogfooding).
2. Work happens. Plans are transient scaffolding.
3. **`reconcile-docs`** folds reality into the living docs, dissolves the plan
   (decisions → an ADR, current-state → living docs, checklist → deleted).
4. **`doc-gate`** blocks an architectural change that ships without a doc update,
   so the loop can't be silently skipped.

## Founding principles (these are design decisions, not inferences)

- **Plans dissolve, never archive.** A finished plan leaves an immutable ADR and
  updated living docs; the task checklist is deleted. No prospective artifact
  survives to go stale.
- **Two documentation lifecycles, never mixed.** *Living* docs (architecture,
  components, guides, glossary) are overwritten to match reality. *Immutable*
  docs (`decisions/` ADRs) are append-only — a wrong ADR is superseded by a new
  one, never edited.
- **Four forcing functions keep docs honest:** dogfooding (`load-context`), the
  PR-gate (`doc-gate`), verifiable references (`bin/docs-check.sh` over the
  `references` + `last_verified` frontmatter), and the periodic sweep (also
  `docs-check`). They are independent nets.
- **The gate is deliberately conservative.** It fires only on high-confidence
  architectural signals so it never nags on bugfixes — a gate that annoys gets
  switched off, and a switched-off gate protects nothing.

## Inferred / unverified

- *(none yet — this baseline was authored by the same session that built the
  code, so the principles above are known, not inferred. Future bootstraps of
  foreign codebases should mark anything they cannot verify here.)*
