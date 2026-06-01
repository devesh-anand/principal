#!/usr/bin/env bash
#
# Principal doc-gate — in-session wrapper (layer 1: catches agent edits).
#
# Wired via hooks/hooks.json as a Stop hook. When the agent finishes a turn that
# left an architectural change with no doc update, this blocks the stop with a
# reason, nudging the agent to reconcile (or to decide no doc change is needed).
# It fires at most once per turn — `stop_hook_active` prevents an infinite loop,
# which is the in-session equivalent of the escape hatch.

input="$(cat)"

# Already nudged this cycle → stand down (loop guard / implicit escape).
if printf '%s' "$input" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

# Working-tree change set vs HEAD, plus brand-new untracked files as additions.
changes="$(
  {
    git -C "$root" diff HEAD --name-status
    git -C "$root" ls-files --others --exclude-standard | sed 's/^/A\t/'
  } 2>/dev/null
)"
[ -z "$changes" ] && exit 0

reason="$(printf '%s\n' "$changes" | "$root/hooks/doc-gate.sh" "" 2>&1 1>/dev/null)"
rc=$?
[ "$rc" -eq 0 ] && exit 0

# Emit a Stop-hook block decision with the detector's message as the reason.
escaped="$(printf '%s' "$reason" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null)"
if [ -z "$escaped" ]; then
  # Fallback if python3 is unavailable: crude escaping.
  escaped="\"$(printf '%s' "$reason" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk 'BEGIN{ORS="\\n"}{print}')\""
fi
printf '{"decision":"block","reason":%s}\n' "$escaped"
exit 0
