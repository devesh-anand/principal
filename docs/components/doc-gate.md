---
references:
  - hooks/doc-gate.sh
  - hooks/doc-gate-stop.sh
  - hooks/commit-msg
  - hooks/hooks.json
  - .github/workflows/doc-gate.yml
last_verified: 4a13aab
---

# Component: doc-gate

The enforcement subsystem. It blocks a change when the **architectural surface**
moved but `/docs` wasn't touched, with a deliberate escape hatch. One shared
detector sits behind three layers that differ only in scope and entrypoint.

## The shared detector — `hooks/doc-gate.sh`

The single brain. Contract:

- **stdin**: lines of `git diff --name-status` for the change set.
- **`$1`**: the commit/PR message (a string, or `@path` to a file).
- **exit 0**: pass. **exit 1**: block.

### What counts as "architectural" (deliberately conservative)

Fires on high-confidence signals only:

- a module **added or removed** (status `A`/`D`) on a non-noise path,
- a **dependency manifest** changed (`package.json`, `go.mod`, `pyproject.toml`, …),
- a **schema/contract surface** changed (`*.sql`, `*.proto`, `*.graphql`, `migrations/`, `schema/`).

Pure *modifications* to existing source — bugfixes, refactors — do **not** fire.
Added test files, lockfiles, markdown, and dotfiles are treated as noise and
ignored. This conservatism is intentional: a gate that nags gets disabled.

### Doc update & escape hatch

A changed path under `docs/` satisfies the gate. A `docs: n/a` line in the
message bypasses it deliberately (`DOC_GATE_ESCAPE_REGEX`).

### Tuning

A repo-local `.principal/doc-gate.conf` is sourced and may override any
`DOC_GATE_*` variable (doc paths, dependency regex, schema regex, ignore regex,
escape regex).

## The three layers

| Layer | File | Scope it diffs | Notes |
|-------|------|----------------|-------|
| **In-session** | `hooks/doc-gate-stop.sh` (wired by `hooks/hooks.json` as a `Stop` hook) | working tree vs `HEAD` + untracked files | Emits a `{"decision":"block","reason":…}` JSON. Fires once per turn (`stop_hook_active` loop guard = implicit escape). **Resolves the detector relative to its own dir** (the plugin's `hooks/`), not the user's repo. |
| **commit-msg** | `hooks/commit-msg` (git hook) | staged changes (`--cached`) | Reads the message file via `@$1`. Resolves the detector at the project's `hooks/doc-gate.sh`, so that file must be vendored into the target repo. |
| **CI** | `.github/workflows/doc-gate.yml` | PR range (`base...HEAD`) | The hard merge gate. Escape hatch honored from any commit message in the range. |

## Critical invariant

The in-session layer (`doc-gate-stop.sh`) must locate `doc-gate.sh` via its own
script directory, because under a plugin install the user's project has no
`hooks/` of its own. The git-hook and CI layers, by contrast, run *inside* the
target repo and require `hooks/doc-gate.sh` to be vendored there.
