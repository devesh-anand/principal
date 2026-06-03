#!/usr/bin/env bash
#
# Principal docs-check — mechanical verification of the /docs knowledge base.
#
# Powers two forcing functions that were otherwise only prose:
#   • verifiable references  — every `references:` path must resolve
#   • the periodic sweep      — the mechanical half reconcile-docs runs on a timer
#
# Checks:
#   1. references resolve   — a broken path is an ERROR (exit 1)
#   2. decay                — a referenced file changed since the doc's
#                             `last_verified` sha is a WARNING (reconcile needed)
#   3. coverage             — a top-level code dir no doc references is a WARNING
#                             (heuristic hint, not a guarantee)
#
# Usage: bin/docs-check.sh [--strict]
#   --strict escalates warnings (decay/coverage) to a non-zero exit too.
#
# Tune via a repo-local .principal/docs-check.conf (sourced; may override the
# DOCS_DIR / COVERAGE_IGNORE_REGEX defaults below).

set -uo pipefail   # NOT -e: we collect every finding before deciding the exit.

strict=0
[ "${1:-}" = "--strict" ] && strict=1

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root"

DOCS_DIR="${DOCS_DIR:-docs}"
COVERAGE_IGNORE_REGEX="${COVERAGE_IGNORE_REGEX:-^(docs|\.git|\.github|\.principal|node_modules)$}"
[ -f ".principal/docs-check.conf" ] && . ".principal/docs-check.conf"

# --- frontmatter helpers -----------------------------------------------------

# List the paths in a doc's `references:` block (robust to body markdown lists).
refs_of() {
  awk '
    /^---[[:space:]]*$/            { r=0; next }
    /^references:/                 { r=1; next }
    /^[a-zA-Z_][a-zA-Z0-9_]*:/     { r=0; next }
    r && /^[[:space:]]*-[[:space:]]/ { gsub(/^[[:space:]]*-[[:space:]]*/,""); print }
  ' "$1"
}
sha_of() { grep -m1 '^last_verified:' "$1" | sed 's/last_verified:[[:space:]]*//'; }

# --- gather living docs (those carrying a references: block) -----------------

if [ ! -d "$DOCS_DIR" ]; then
  echo "docs-check: no $DOCS_DIR/ directory — run reconcile-docs to bootstrap." >&2
  exit 1
fi

living=()
while IFS= read -r f; do
  grep -q '^references:' "$f" && living+=("$f")
done < <(find "$DOCS_DIR" -name '*.md' | sort)

echo "docs-check: scanning ${#living[@]} living doc(s) under $DOCS_DIR/"
echo

errors=0
warns=0
refs_seen="$(mktemp)"
trap 'rm -f "$refs_seen"' EXIT

# --- checks 1 & 2: references resolve, and decay -----------------------------

for f in "${living[@]}"; do
  sha="$(sha_of "$f")"
  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    echo "${ref%%/*}" >> "$refs_seen"          # top-level dir, for coverage
    if [ ! -e "$ref" ]; then
      echo "  ERROR  $f"
      echo "         missing reference: $ref"
      errors=$((errors + 1))
      continue
    fi
    if [ -z "$sha" ]; then
      echo "  WARN   $f → no last_verified stamp"
      warns=$((warns + 1))
    elif git rev-parse --verify -q "$sha^{commit}" >/dev/null 2>&1; then
      if ! git diff --quiet "$sha" HEAD -- "$ref" 2>/dev/null; then
        echo "  DECAY  $f"
        echo "         $ref changed since last_verified ($sha) — reconcile needed"
        warns=$((warns + 1))
      fi
    else
      echo "  WARN   $f → last_verified '$sha' is not a known commit"
      warns=$((warns + 1))
    fi
  done < <(refs_of "$f")
done

# --- check 3: coverage (heuristic) -------------------------------------------

while IFS= read -r d; do
  base="${d#./}"
  printf '%s\n' "$base" | grep -Eq "$COVERAGE_IGNORE_REGEX" && continue
  if ! grep -qx "$base" "$refs_seen"; then
    echo "  COVER  no doc references anything under: $base/"
    warns=$((warns + 1))
  fi
done < <(find . -maxdepth 1 -type d ! -path . | sort)

# --- verdict -----------------------------------------------------------------

echo
echo "docs-check: $errors error(s), $warns warning(s)"
[ "$errors" -gt 0 ] && exit 1
[ "$strict" -eq 1 ] && [ "$warns" -gt 0 ] && exit 1
exit 0
