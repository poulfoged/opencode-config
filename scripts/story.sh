#!/usr/bin/env bash
# Usage: story.sh [JIRA-KEY]
# Fetches a Jira story, opens it as a cmux browser tab, and names the cmux
# workspace and OpenCode session "<KEY>: <summary>". Read-only against Jira.
# Also creates ~/work/<KEY>/ (override with STORY_WORK_DIR) holding a git
# worktree of the current repo, then restarts the story in a new cmux workspace
# whose shell and OpenCode both start in that worktree.
set -euo pipefail

JIRA_SITE="https://legogroup.atlassian.net"
WORK_DIR="${STORY_WORK_DIR:-$HOME/work}"
KEY_PATTERN='^[A-Z][A-Z0-9]*-[0-9]+$'
MARKER_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/opencode-story"

key="${1:-}"
if [ -z "$key" ]; then
  key="$(git branch --show-current 2>/dev/null | grep -oE '[A-Z][A-Z0-9]*-[0-9]+' | head -1 || true)"
fi

if ! [[ "$key" =~ $KEY_PATTERN ]]; then
  echo "story: '${key}' is not a Jira key (expected e.g. IAG-657) and the branch has none." >&2
  exit 2
fi

raw="$(jira issue view "$key" --raw 2>&1)" || {
  echo "story: failed to fetch $key from Jira:" >&2
  echo "$raw" >&2
  exit 1
}

summary="$(printf '%s' "$raw" | jq -r '.fields.summary // empty')"
title="$key: ${summary:-$key}"
url="$JIRA_SITE/browse/$key"

slugify() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' \
    | cut -c1-50 | sed -E 's/-+$//'
}

# Sets repo_dir to a worktree of $toplevel under $work, creating it when missing.
ensure_worktree() {
  local toplevel="$1" repo_name target match branch base slug key_re
  repo_name="$(basename "$toplevel")"
  target="$work/$repo_name"
  # Drop registrations of worktrees whose folder was deleted without `git worktree remove`.
  git -C "$toplevel" worktree prune 2>/dev/null || true
  if [ -d "$target" ]; then
    repo_dir="$target"
    return 0
  fi

  key_re="(^|[^A-Za-z0-9])${key}([^0-9]|\$)"
  match="$(git -C "$toplevel" for-each-ref --format='%(refname:short)' refs/heads | grep -E "$key_re" | head -1 || true)"
  if [ -n "$match" ]; then
    if git -C "$toplevel" worktree list --porcelain | grep -qx "branch refs/heads/$match"; then
      echo "story: warning: branch '$match' is already checked out in another worktree; skipped worktree" >&2
      return 1
    fi
    git -C "$toplevel" worktree add "$target" "$match" >&2 || return 1
  else
    match="$(git -C "$toplevel" for-each-ref --format='%(refname:short)' refs/remotes/origin | grep -v '/HEAD$' | grep -E "$key_re" | head -1 || true)"
    if [ -n "$match" ]; then
      branch="${match#origin/}"
      git -C "$toplevel" worktree add --track -b "$branch" "$target" "$match" >&2 || return 1
    else
      slug="$(slugify "$summary")"
      branch="$key${slug:+-$slug}"
      base="$(git -C "$toplevel" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo HEAD)"
      git -C "$toplevel" worktree add --no-track -b "$branch" "$target" "$base" >&2 || return 1
    fi
  fi
  repo_dir="$target"
}

work="$WORK_DIR/$key"
if mkdir -p "$work" 2>/dev/null; then
  work="$(cd "$work" && pwd -P)"
else
  echo "story: warning: could not create work folder $work" >&2
  work=""
fi

repo_dir=""
inside=0
if [ -n "$work" ]; then
  toplevel="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  case "$(pwd -P)/" in
    "$work"/*)
      inside=1
      repo_dir="${toplevel:-$(pwd -P)}"
      ;;
    *)
      if [ -n "$toplevel" ]; then
        ensure_worktree "$toplevel" || echo "story: warning: could not create worktree; continuing without it" >&2
      else
        echo "story: warning: not in a git repository; created the empty work folder only" >&2
      fi
      ;;
  esac
fi

if [ -n "$repo_dir" ] && [ "$inside" = 0 ] && [ -n "${CMUX_WORKSPACE_ID:-}" ]; then
  if cmux new-workspace --name "$title" --cwd "$repo_dir" --focus true \
       --command "opencode --prompt '/story $key'" >/dev/null 2>&1; then
    nohup sh -c "sleep 6; cmux close-workspace --workspace '$CMUX_WORKSPACE_ID' --force" >/dev/null 2>&1 &
    disown 2>/dev/null || true
    echo "RELAUNCHED: $title"
    echo "Work:  $work"
    echo "Repo:  $repo_dir"
    echo "A new cmux workspace started in the worktree and continues /story there. This workspace closes in a few seconds."
    exit 0
  fi
  echo "story: warning: could not start a workspace in $repo_dir; continuing in the current directory" >&2
fi

if [ -n "${CMUX_WORKSPACE_ID:-}" ]; then
  cmux workspace rename "$CMUX_WORKSPACE_ID" --title "$title" >/dev/null 2>&1 \
    || echo "story: warning: could not rename cmux workspace" >&2
  cmux workspace-action --action set-color --color Olive --workspace "$CMUX_WORKSPACE_ID" >/dev/null 2>&1 \
    || echo "story: warning: could not set cmux workspace colour" >&2
  pane="$(cmux identify --json 2>/dev/null | jq -r '.caller.pane_ref // empty' || true)"
  if [ -n "$pane" ]; then
    existing="$(cmux --json list-pane-surfaces --pane "$pane" --workspace "$CMUX_WORKSPACE_ID" 2>/dev/null \
      | jq -r --arg k "$key" '.surfaces[]? | select(.type == "browser" and .title == $k) | .ref' | head -1 || true)"
    if [ -z "$existing" ]; then
      new="$(cmux --json new-surface --type browser --pane "$pane" --workspace "$CMUX_WORKSPACE_ID" \
        --url "$url" --focus false 2>/dev/null | jq -r '.surface_ref // empty' || true)"
      if [ -n "$new" ]; then
        cmux rename-tab --surface "$new" "$key" >/dev/null 2>&1 || true
      else
        echo "story: warning: could not open $url as a tab in cmux" >&2
      fi
    fi
  else
    cmux browser open "$url" --workspace "$CMUX_WORKSPACE_ID" --focus false >/dev/null 2>&1 \
      || echo "story: warning: could not open $url in cmux" >&2
  fi
else
  echo "story: warning: CMUX_WORKSPACE_ID not set; skipped workspace rename and browser tab" >&2
fi

if [ -n "${OPENCODE_SESSION_ID:-}" ]; then
  # Marker first, so the title-lock plugin protects the title from the start.
  mkdir -p "$MARKER_DIR"
  : > "$MARKER_DIR/$OPENCODE_SESSION_ID"
  opencode api patch "/api/session/$OPENCODE_SESSION_ID" \
    --data "$(jq -n --arg t "$title" '{title: $t}')" >/dev/null 2>&1 \
    || echo "story: warning: could not rename OpenCode session" >&2
else
  echo "story: warning: OPENCODE_SESSION_ID not set; skipped session rename" >&2
fi

echo "Title: $title"
echo "URL:   $url"
[ -n "$work" ] && echo "Work:  $work"
[ -n "$repo_dir" ] && echo "Repo:  $repo_dir"
echo
jira issue view "$key" --plain --comments 10
