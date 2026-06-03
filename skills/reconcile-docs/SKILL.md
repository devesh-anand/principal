---
name: reconcile-docs
description: >
  Keep /docs as the true, current knowledge base of the codebase. Run after a
  brainstorm/plan dissolves, on every PR/commit that changes the architectural
  surface, or periodically as a janitor sweep. On a repo with no docs yet, it
  bootstraps the whole knowledge base from the code.
---

# reconcile-docs

The core skill of **Principal**. Its job is to make `/docs` match
reality — always describing the code **as it is now**, never as someone once
planned it to be.

Plans are transient scaffolding. Docs are the durable artifact. This skill is
the bridge: it dissolves completed plans into docs and continuously drags the
docs back toward truth.

## Operating principle

> Document what *is*, with evidence. Never assert what you cannot verify, and
> never preserve what is merely intended.

Two failure modes are equally fatal and this skill exists to prevent both:
1. **Stale docs** — docs that describe a past state and now lie.
2. **Fabricated docs** — confident claims (especially "why") that were never true.

## Modes (auto-selected by repo state)

Pick the mode from state; do not ask the user which mode unless ambiguous.

| Mode | Selected when | Scope |
|------|---------------|-------|
| **Bootstrap** | `docs/` is absent, empty, or has no `docs/README.md` | the entire codebase |
| **Incremental** | docs exist AND a change set is in play (PR, recent commits, or a just-dissolved plan) | the diff since each doc's `last_verified` |
| **Sweep** | docs exist, invoked with no change set (periodic / manual full audit) | docs flagged decayed + all mechanical ref checks |

---

## Doc taxonomy this skill maintains

Two lifecycles, **never mixed in the same file**:

```
docs/
  README.md          # MANIFEST. Entry point. One line per doc, navigate-don't-load.
  architecture/      # LIVING.  System shape, data flow, invariants. Overwritten to match reality.
  components/        # LIVING.  One file per subsystem: purpose, key files, public surface, deps.
  decisions/         # IMMUTABLE. ADRs. Timestamped, append-only. The "why". Never edited after writing.
  guides/            # LIVING.  Runbooks, how-tos.
  glossary.md        # LIVING.  Domain terms.
```

**Living** docs are overwritten freely to track reality.
**Immutable** docs (`decisions/`) are append-only — a wrong ADR is superseded by
a new ADR that references it, never edited or deleted. The history is the point.

### Frontmatter on every living doc

```yaml
---
references: [src/auth/session.ts, src/auth/middleware.ts]  # files/symbols this doc describes
last_verified: <commit-sha>                                # HEAD when this doc was last reconciled
---
```

`references` powers the mechanical check (the paths must exist).
`last_verified` powers decay detection (a doc is *decayed* when files it
references have changed since the sha it records).

---

## Mode: Bootstrap

First contact with a repo that has no docs. Build the knowledge base from the
code itself.

1. **Map the repo.** Languages, build system, dependency manifests, entry
   points, top-level directory structure. Record nothing yet — just orient.
2. **Identify subsystems.** Cut the codebase along module/directory boundaries
   into a handful of components. Prefer the boundaries the code already implies
   (packages, top-level dirs, service boundaries) over invented ones.
3. **Document each component** (`components/<name>.md`): purpose, key files,
   public interface, who it depends on and who depends on it. Read enough source
   to be correct; cite files in `references`.
4. **Synthesize architecture** (`architecture/`): how the components connect,
   the main data/control flows, and invariants — but **mark every invariant you
   infer but cannot prove as `inferred, unverified`.**
5. **Never *invent* ADRs — but capture *attestable* ones.** Always write
   `decisions/ADR-0000-baseline.md`, stating the knowledge base was bootstrapped
   on this date from this commit and that prior decisions are otherwise
   undocumented. For foreign code whose rationale you cannot verify, stop there —
   reconstructed "why" is fabrication. **But** if the operator can genuinely
   attest to specific decisions and their reasoning (e.g. they just designed the
   code in this session), you MAY seed those as additional ADRs (`ADR-0001`, …).
   The test is attestation, not convenience: record rationale that is *known*,
   never rationale that is *guessed*.
6. **Write the manifest** (`docs/README.md`): one navigable line per doc.
7. **Stamp** `references` + `last_verified: <HEAD sha>` on every living doc.

> Bootstrap on a large codebase is a natural fan-out (one explorer per
> subsystem). Only parallelize this way if the user has explicitly opted into
> multi-agent orchestration.

Bootstrap's output is a *baseline*, not gospel. It is expected to be corrected
by the first few incremental runs.

---

## Mode: Incremental

The common case. A change set exists (a PR, recent commits, or a plan that just
finished executing).

1. **Get the change set.** The diff of files touched since the relevant base.
2. **Threshold — does this change the architectural surface?** Only these
   warrant a living-doc update:
   - public interfaces / exported signatures
   - new or removed modules/components
   - data-model or schema changes
   - new or dropped dependencies
   - changed invariants or control flow
   A pure internal refactor or bugfix that changes no documented contract needs
   **no doc change** — say so and stop. (Nagging on trivia gets this skill
   switched off. Protect that threshold.)
3. **Reconcile reality into living docs.** For each affected doc, overwrite it
   to match what *shipped* — not what the plan said would ship. The divergence
   between plan and reality is exactly the knowledge worth capturing.
4. **Dissolve the plan, if one drove this work:**
   - decisions/rationale → a new immutable ADR in `decisions/`
   - current-state effects → folded into the living docs above
   - the task checklist → **deleted.** No archived plan survives.
5. **Re-stamp** `references` + `last_verified: <HEAD sha>` on every doc touched.
6. **Update the manifest** if any doc was added/removed/renamed.

---

## Mode: Sweep (periodic janitor)

No change set; auditing the whole knowledge base. The backstop net for drift
that the gate and dogfooding missed.

Steps 1–3 are mechanical and shipped as `bin/docs-check.sh` — run it to get the
report rather than re-deriving it by hand:

1. **Mechanical ref check.** For every living doc, confirm each path/symbol in
   `references` still exists. Broken ref → flag (this catches renames/moves, the
   #1 source of silent drift). *(docs-check: `ERROR`, exit 1.)*
2. **Decay scan.** For every living doc, compare `last_verified` against the
   current state of its referenced files. Files changed since that sha →
   the doc is *decayed* → queue it for an incremental reconcile. *(docs-check:
   `DECAY`.)*
3. **Coverage gap.** Look for subsystems with code but no `components/` doc.
   *(docs-check: `COVER`, heuristic.)*
4. **Report, then reconcile.** Run `bin/docs-check.sh` for steps 1–3, then run
   incremental reconcile over the flagged docs.

The sweep never invents ADRs and never edits immutable docs.

---

## What NOT to document (bloat control)

The knowledge base competes for the agent's context budget. Keep it lean:
- No restating of code that is self-evident from a glance at the file.
- No tutorials for standard tools/frameworks.
- No speculative future plans — those are transient, and they do not belong here.
- No duplication: one fact lives in one doc; link with relative paths instead.

If a doc is never loaded by `load-context` and never referenced, it is dead
weight — delete it.

## Done means

- Every living doc touched matches current reality and carries a fresh
  `last_verified`.
- Every `references` entry resolves.
- Any completed plan is dissolved (ADR written, checklist deleted).
- The manifest reflects what exists.
- Nothing asserted that wasn't verified; inferences marked as such.
