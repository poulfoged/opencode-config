#!/usr/bin/env bash
# Usage: mark.sh <PREFIX> <COLOUR>   e.g. mark.sh PR Aqua
# Prefixes the cmux workspace and OpenCode session title with "<PREFIX>: "
# (replacing any existing upper-case prefix such as "STORY: " or "BLOCK: ") and
# colours the cmux workspace. Example: "BLOCK: IAG-653: Hydrator" -> "PR: IAG-653: Hydrator".
set -euo pipefail

prefix="${1:-}"
color="${2:-}"
if ! [[ "$prefix" =~ ^[A-Z][A-Z\ ]*$ ]] || [ -z "$color" ]; then
  echo "usage: mark.sh <UPPERCASE PREFIX> <cmux colour name>" >&2
  exit 2
fi

MARKER_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/opencode-story"
KEY_PREFIX='^[A-Z][A-Z0-9]*-[0-9]+'

strip_prefix() {
  local t="$1"
  while [[ "$t" =~ ^[A-Z][A-Z\ ]*:[[:space:]]+ ]]; do
    t="${t#"${BASH_REMATCH[0]}"}"
  done
  printf '%s' "$t"
}

workspace_title=""
if [ -n "${CMUX_WORKSPACE_ID:-}" ]; then
  workspace_title="$(cmux workspace list --json 2>/dev/null \
    | jq -r --arg id "$CMUX_WORKSPACE_ID" '.workspaces[]? | select(.id == $id) | .title // empty' || true)"
fi

session_title=""
if [ -n "${OPENCODE_SESSION_ID:-}" ]; then
  session_title="$(opencode api GET "/api/session/$OPENCODE_SESSION_ID" 2>/dev/null | jq -r '.data.title // empty' || true)"
fi

base=""
for candidate in "$workspace_title" "$session_title"; do
  [ -n "$candidate" ] || continue
  stripped="$(strip_prefix "$candidate")"
  if [[ "$stripped" =~ $KEY_PREFIX ]]; then
    base="$stripped"
    break
  fi
  [ -n "$base" ] || base="$stripped"
done

if [ -z "$base" ]; then
  echo "mark: no workspace or session title found to rename." >&2
  exit 1
fi

title="$prefix: $base"

if [ -n "${CMUX_WORKSPACE_ID:-}" ]; then
  cmux workspace rename "$CMUX_WORKSPACE_ID" --title "$title" >/dev/null 2>&1 \
    || echo "mark: warning: could not rename cmux workspace" >&2
  cmux workspace-action --action set-color --color "$color" --workspace "$CMUX_WORKSPACE_ID" >/dev/null 2>&1 \
    || echo "mark: warning: could not set cmux workspace colour" >&2
else
  echo "mark: warning: CMUX_WORKSPACE_ID not set; skipped workspace rename and colour" >&2
fi

if [ -n "${OPENCODE_SESSION_ID:-}" ]; then
  mkdir -p "$MARKER_DIR"
  : > "$MARKER_DIR/$OPENCODE_SESSION_ID"
  opencode api patch "/api/session/$OPENCODE_SESSION_ID" \
    --data "$(jq -n --arg t "$title" '{title: $t}')" >/dev/null 2>&1 \
    || echo "mark: warning: could not rename OpenCode session" >&2
else
  echo "mark: warning: OPENCODE_SESSION_ID not set; skipped session rename" >&2
fi

echo "Title: $title"
