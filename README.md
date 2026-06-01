# Principal

**Give every agent the context of your principal engineer.**

Principal is a methodology — shipped as a Claude Code plugin — for keeping a
codebase's `/docs` directory as its single, living source of truth. Plans are
treated as disposable scaffolding; the durable artifact is the documentation,
and it is continuously reconciled against the code so it never drifts out of date.

> Status: **v0.2.** `reconcile-docs`, `load-context`, and the three-layer
> `doc-gate` are implemented. `brainstorm` and `plan` are on the
> [roadmap](#roadmap). This README describes the full design; what ships today is
> marked honestly below — because a tool whose premise is *evidence over claims*
> shouldn't make any.

---

## Why Principal

Most agentic dev workflows are **plan-centric**: you brainstorm, write a detailed
plan, and execute it. The plan becomes an artifact in the repo. The problem is
that a plan is **prospective** — it describes what you *intended* to do. The
moment the work ships (and reality always diverges from the plan during
implementation), the plan becomes a lie that looks authoritative. Repos
accumulate these corpses, and new contributors — human or agent — read stale
intentions as current truth.

Principal's thesis:

> **Plans are transient. Docs are durable. Completing a plan means *dissolving*
> it into the docs — then discarding it.**

A plan dissolves into two places and leaves nothing behind:

- its **decisions and rationale** → an immutable, timestamped ADR in `docs/decisions/`
- its **effect on the system** → folded into the living architecture/component docs,
  reconciled against *what actually shipped*
- its **task checklist** → **deleted**

The result is a `/docs` directory that always describes the code *as it is now*.
A fresh agent that reads it inherits the context of the engineer who's been on
the codebase for years — what it does, why it's shaped this way, and what not to
touch. That's the name.

## How it works

### Two documentation lifecycles — never mixed

```
docs/
  README.md          # Manifest. Entry point. One line per doc — navigate, don't bulk-load.
  architecture/      # LIVING.  System shape, data flow, invariants. Overwritten to match reality.
  components/        # LIVING.  One file per subsystem: purpose, key files, public surface, deps.
  decisions/         # IMMUTABLE. ADRs. Timestamped, append-only. The "why".
  guides/            # LIVING.  Runbooks, how-tos.
  glossary.md        # LIVING.  Domain terms.
```

**Living** docs are freely overwritten to track the code. **Immutable** docs
(`decisions/`) are append-only — a wrong ADR is *superseded by a new ADR that
references it*, never edited or deleted. The history is the point, so the
decisions never go stale.

### What keeps docs honest

Staleness doesn't vanish — it has to be actively fought. Principal layers four
independent forcing functions:

1. **Dogfooding** — the agent reads docs *first* (`load-context`). Stale docs
   produce visibly wrong behavior, so reality enforces them.
2. **PR-gate** — a `doc-gate` hook blocks a merge when an architectural change
   ships with no corresponding doc update.
3. **Verifiable docs** — every living doc declares the files/symbols it
   describes; a mechanical check fails when those references break (catching
   renames and moves, the #1 source of silent drift).
4. **Periodic sweep** — a janitor pass re-verifies references and flags decay on
   a timer, backstopping whatever the other three missed.

### The heart: `reconcile-docs`

One skill, three modes, auto-selected from repo state:

| Mode | Triggered when | Scope |
|------|----------------|-------|
| **Bootstrap** | `docs/` is empty/absent | the entire codebase — explores it and builds the knowledge base from scratch |
| **Incremental** | a change set is in play (PR, commits, a just-finished plan) | the diff; updates affected docs, dissolves the plan |
| **Sweep** | run periodically with no change set | decayed docs + all mechanical reference checks |

Bootstrap documents *what is*, never fabricates *why* — it writes a single
`ADR-0000` baseline rather than inventing rationale it can't verify.

---

## Installation

### As a plugin (recommended)

```text
/plugin marketplace add devesh-anand/principal
/plugin install principal@principal
```

Skills are then available namespaced, e.g. `/principal:reconcile-docs`.

### Manual

Clone the repo and copy the skills into your Claude Code skills directory.

**Global (all projects):**
```bash
git clone https://github.com/devesh-anand/principal.git
cp -r principal/skills/* ~/.claude/skills/
```

**Single project:**
```bash
cp -r principal/skills/* /path/to/your-project/.claude/skills/
```

Each skill lives at `<skills-dir>/<skill-name>/SKILL.md`; the folder name is the
skill name.

---

## Setup guide (first run)

1. **Install** Principal via either method above.

2. **Bootstrap your knowledge base.** In a project that has no `/docs` yet, run:
   ```text
   /principal:reconcile-docs
   ```
   It detects the empty `docs/`, explores the codebase, and writes the initial
   `architecture/`, `components/`, `glossary.md`, the `docs/README.md` manifest,
   and an `ADR-0000` baseline. Treat this output as a *first draft* — review it;
   the first few incremental runs will correct it.

3. **Adopt the loop.** From then on, your normal cycle is:
   - *brainstorm* a change → *plan* it (transient) → *execute* it
   - run `/principal:reconcile-docs` as part of finishing the work — it folds
     reality into the living docs, writes an ADR for the decisions, and deletes
     the spent plan

4. **Enable the gate** (see [doc-gate](#doc-gate) below) so architectural
   changes can't ship without a doc update — this is what makes the freshness
   guarantees trustworthy rather than aspirational.

5. **(Optional) Schedule the sweep.** Run `reconcile-docs` periodically (cron,
   `/schedule`, or CI) as a janitor pass to catch drift nothing else caught.

---

## doc-gate

The enforcement layer. It blocks a change when the **architectural surface**
moved (a module was added/removed, a dependency manifest changed, or a
schema/contract surface changed) but `/docs` wasn't touched. Pure modifications
to existing source — bugfixes, refactors — never trip it; the gate is
deliberately conservative so it doesn't get switched off.

**Escape hatch:** add a `docs: n/a` line to the commit/PR message to bypass
deliberately when a doc change genuinely isn't warranted.

Three layers, shared brain (`hooks/doc-gate.sh`):

| Layer | Catches | Enable |
|-------|---------|--------|
| **In-session** (`Stop` hook) | the agent forgetting to reconcile mid-session | automatic when the plugin is installed |
| **commit-msg** (git hook) | any local commit, human or agent | `git config core.hooksPath hooks` (or copy `hooks/commit-msg` into `.git/hooks/`) |
| **CI** (GitHub Actions) | the actual merge — the hard gate | copy `.github/workflows/doc-gate.yml` into your repo |

**Tuning:** drop a `.principal/doc-gate.conf` in your repo root to override any
`DOC_GATE_*` pattern (doc paths, dependency manifests, schema globs, the ignore
list, the escape regex). The shipped defaults target common JS/TS/Python/Go/Rust
layouts.

---

## What's in the pack

| Skill / component | Purpose | Status |
|-------------------|---------|--------|
| `reconcile-docs` | Bootstrap, reconcile, and sweep `/docs` against the code; dissolve finished plans | ✅ shipped |
| `load-context` | Read the docs manifest and load relevant docs before acting (dogfooding) | ✅ shipped |
| `doc-gate` (hooks + CI) | Block changes where the architectural surface moved but docs didn't | ✅ shipped |
| `brainstorm` | Refine an idea via questions and alternatives; emit a draft ADR | 🛠 roadmap |
| `plan` | Decompose work into a transient, clearly-disposable task list | 🛠 roadmap |

## Roadmap

- [x] `load-context` — make dogfooding real
- [x] `doc-gate` — three-layer gate (in-session hook + git commit-msg + CI), block-with-escape-hatch
- [ ] `brainstorm` + `plan` — the front of the workflow, feeding the dissolve step
- [ ] Bootstrap Principal's own `docs/` (self-dogfooding) as the first end-to-end test
- [ ] Tune the `doc-gate` heuristic against real repos (it ships deliberately conservative)

## License

[MIT](LICENSE) © 2026 Devesh Anand
