#!/usr/bin/env bash
# Opens the current repo's GitHub pull requests as a cmux browser tab,
# reusing an existing "PRs" tab in the same pane.
set -uo pipefail

title="PRs"

base="$(gh repo view --json url -q .url 2>/dev/null || true)"
if [ -z "$base" ]; then
  echo "prs: error: could not resolve a GitHub repository from $(pwd)" >&2
  exit 1
fi
url="$base/pulls"

if [ -z "${CMUX_WORKSPACE_ID:-}" ]; then
  echo "prs: error: CMUX_WORKSPACE_ID not set; not running inside cmux" >&2
  exit 1
fi

pane="$(cmux identify --json 2>/dev/null | jq -r '.caller.pane_ref // empty' || true)"
if [ -z "$pane" ]; then
  cmux browser open "$url" --workspace "$CMUX_WORKSPACE_ID" --focus false >/dev/null 2>&1 \
    || { echo "prs: error: could not open $url in cmux" >&2; exit 1; }
  echo "Opened $url"
  exit 0
fi

existing="$(cmux --json list-pane-surfaces --pane "$pane" --workspace "$CMUX_WORKSPACE_ID" 2>/dev/null \
  | jq -r --arg t "$title" '.surfaces[]? | select(.type == "browser" and .title == $t) | .ref' | head -1 || true)"
if [ -n "$existing" ]; then
  cmux browser --surface "$existing" navigate "$url" >/dev/null 2>&1 \
    || { echo "prs: error: could not navigate existing tab to $url" >&2; exit 1; }
  echo "Reused tab $existing: $url"
  exit 0
fi

new="$(cmux --json new-surface --type browser --pane "$pane" --workspace "$CMUX_WORKSPACE_ID" \
  --url "$url" --focus false 2>/dev/null | jq -r '.surface_ref // empty' || true)"
if [ -z "$new" ]; then
  echo "prs: error: could not open $url as a tab in cmux" >&2
  exit 1
fi
cmux rename-tab --surface "$new" "$title" >/dev/null 2>&1 || true
echo "Opened tab $new: $url"
