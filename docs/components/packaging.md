---
references:
  - .claude-plugin/plugin.json
  - .claude-plugin/marketplace.json
  - hooks/hooks.json
last_verified: 4a13aab
---

# Component: packaging

How Principal is distributed and installed as a Claude Code plugin.

## Manifests

- **`.claude-plugin/plugin.json`** — the plugin manifest. `name: "principal"`
  (kebab-case, required), `description`, `version`, `author`.
- **`.claude-plugin/marketplace.json`** — lets a user add this repo as a
  marketplace. Lists one plugin whose `source` points at the repo root.

### `source` gotcha

For a plugin living at the repository root, the marketplace `source` must be
`"./"` — **not** `"."`. `claude plugin validate` rejects `"."` with
`plugins.0.source: Invalid input`. Relative sources must start with `./` and
resolve from the marketplace (repo) root.

## Install paths

```text
/plugin marketplace add devesh-anand/principal
/plugin install principal@principal
```

Skills become `/principal:<skill-name>`. Installing as a plugin also activates
doc-gate's in-session layer via the bundled `hooks/hooks.json` (`${CLAUDE_PLUGIN_ROOT}`
resolves the hook scripts). Manual (skills-only) install does **not** enable the
gate — see the root `README.md` for vendoring instructions.

## What ships vs. what's vendored

- **Ships with the plugin, zero setup:** the skills + the in-session gate.
- **Vendored into the target repo by the user:** `hooks/doc-gate.sh` +
  `hooks/commit-msg` (commit-msg layer) and `.github/workflows/doc-gate.yml`
  (CI layer).
