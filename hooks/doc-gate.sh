#!/usr/bin/env bash
#
# doc-gate.sh — Principal's shared "did the docs keep up?" detector.
#
# This is the single brain behind all three gate layers (in-session hook,
# git commit-msg hook, CI). Each layer computes a `git diff --name-status`
# for its own scope and pipes it here; this script decides pass/block.
#
# Contract:
#   stdin : lines of `git diff --name-status` output for the change set
#   $1    : the commit/PR message (a string, or @path to a file). Optional.
#   exit 0: pass (no gate, or satisfied, or escaped)
#   exit 1: BLOCK — architectural change shipped with no doc change
#
# Philosophy: err toward NOT firing. A gate that nags on every bugfix gets
# switched off, and a switched-off gate protects nothing. So modifications to
# existing source do NOT trip it — only high-confidence architectural signals
# do. The escape hatch is the pressure valve for the rest.
#
# Tune by dropping a `.principal/doc-gate.conf` in the repo root; it is sourced
# and may override any DOC_GATE_* variable below.

set -euo pipefail

# ---- defaults (override in .principal/doc-gate.conf) ------------------------

# A changed path matching this = "the docs were updated".
DOC_GATE_DOC_REGEX="${DOC_GATE_DOC_REGEX:-^docs/}"

# Dependency manifests: a change to any of these is architectural (deps moved).
DOC_GATE_DEP_REGEX="${DOC_GATE_DEP_REGEX:-(^|/)(package\.json|requirements\.txt|pyproject\.toml|go\.mod|Cargo\.toml|Gemfile|pom\.xml|build\.gradle|composer\.json)$}"

# Schema / contract surfaces: a change here is architectural (data shape moved).
DOC_GATE_SCHEMA_REGEX="${DOC_GATE_SCHEMA_REGEX:-(/migrations?/|/schema/|\.sql$|\.proto$|\.graphql$)}"

# Added/removed files matching this are NOT architectural (noise, not modules).
DOC_GATE_IGNORE_REGEX="${DOC_GATE_IGNORE_REGEX:-(^docs/|(^|/)(test|tests|spec|specs|__tests__|fixtures|__snapshots__)/|\.(test|spec)\.[^/]+$|\.(md|txt|lock|snap)$|(^|/)\.[^/]+$|(^|/)(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|poetry\.lock|Cargo\.lock|go\.sum)$)}"

# Escape hatch: if the message matches this, the gate stands down deliberately.
DOC_GATE_ESCAPE_REGEX="${DOC_GATE_ESCAPE_REGEX:-[Dd]ocs:[[:space:]]*n/?a}"

# Load repo-local overrides if present.
if [ -f ".principal/doc-gate.conf" ]; then
  # shellcheck disable=SC1091
  . ".principal/doc-gate.conf"
fi

# ---- read the message (string or @file) ------------------------------------

message="${1:-}"
case "$message" in
  @*) msg_file="${message#@}"; message="$( [ -f "$msg_file" ] && cat "$msg_file" || true )" ;;
esac

if printf '%s' "$message" | grep -Eq "$DOC_GATE_ESCAPE_REGEX"; then
  exit 0   # explicit, deliberate bypass — trust the human/agent
fi

# ---- classify the change set ------------------------------------------------

doc_changed=0
arch_changed=0
arch_reason=""

while IFS=$'\t' read -r status p1 p2 || [ -n "${status:-}" ]; do
  [ -z "${status:-}" ] && continue
  code="${status:0:1}"
  # For renames/copies the new path is the 2nd field; otherwise the 1st.
  path="$p1"
  case "$code" in R|C) [ -n "${p2:-}" ] && path="$p2" ;; esac
  [ -z "${path:-}" ] && continue

  # Did the docs move?
  if printf '%s' "$path" | grep -Eq "$DOC_GATE_DOC_REGEX"; then
    doc_changed=1
    continue
  fi

  # High-confidence architectural signals:
  # 1) dependency manifest touched (any status)
  if printf '%s' "$path" | grep -Eq "$DOC_GATE_DEP_REGEX"; then
    arch_changed=1; arch_reason="dependency manifest changed ($path)"; continue
  fi
  # 2) schema/contract surface touched (any status)
  if printf '%s' "$path" | grep -Eq "$DOC_GATE_SCHEMA_REGEX"; then
    arch_changed=1; arch_reason="schema/contract surface changed ($path)"; continue
  fi
  # 3) a module was ADDED or DELETED (not mere modification, not noise)
  case "$code" in
    A|D)
      if ! printf '%s' "$path" | grep -Eq "$DOC_GATE_IGNORE_REGEX"; then
        verb=$([ "$code" = A ] && echo added || echo removed)
        arch_changed=1; arch_reason="module $verb ($path)"; continue
      fi
      ;;
  esac
done

# ---- verdict ----------------------------------------------------------------

if [ "$arch_changed" -eq 1 ] && [ "$doc_changed" -eq 0 ]; then
  {
    echo "doc-gate: BLOCKED — architectural change with no docs update"
    echo "  reason: $arch_reason"
    echo "  fix: update the relevant docs (run reconcile-docs),"
    echo "       or add a 'docs: n/a' line to the commit/PR message to bypass."
  } >&2
  exit 1
fi

exit 0
