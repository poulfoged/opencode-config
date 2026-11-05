#!/usr/bin/env bash
# Usage: release.sh <VERSION>   e.g. release.sh 0.15.2
# Creates ~/work/<VERSION>/ (override with RELEASE_WORK_DIR) holding a git
# worktree of the current repo on branch release/<VERSION>, branched from the
# current HEAD, then restarts the release in a new cmux workspace whose shell and
# OpenCode both start in that worktree. Names the cmux workspace and OpenCode
# session "RELEASE: <VERSION>".
set -euo pipefail

WORK_DIR="${RELEASE_WORK_DIR:-${STORY_WORK_DIR:-$HOME/work}}"
VERSION_PATTERN='^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$'
MARKER_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/opencode-story"

version="${1:-}"
version="${version#v}"

if ! [[ "$version" =~ $VERSION_PATTERN ]]; then
  echo "release: '${version}' is not a version (expected e.g. 0.15.2 or 1.0.0-rc.1)." >&2
  exit 2
fi

title="RELEASE: $version"
branch="release/$version"

# Sets repo_dir to a worktree of $toplevel under $work, creating it when missing.
ensure_worktree() {
  local toplevel="$1" repo_name target
  repo_name="$(basename "$toplevel")"
  target="$work/$repo_name"
  # Drop registrations of worktrees whose folder was deleted without `git worktree remove`.
  git -C "$toplevel" worktree prune 2>/dev/null || true
  if [ -d "$target" ]; then
    repo_dir="$target"
    return 0
  fi

  if git -C "$toplevel" show-ref --verify --quiet "refs/heads/$branch"; then
    if git -C "$toplevel" worktree list --porcelain | grep -qx "branch refs/heads/$branch"; then
      echo "release: warning: branch '$branch' is already checked out in another worktree; skipped worktree" >&2
      return 1
    fi
    git -C "$toplevel" worktree add "$target" "$branch" >&2 || return 1
  elif git -C "$toplevel" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    git -C "$toplevel" worktree add --track -b "$branch" "$target" "origin/$branch" >&2 || return 1
  else
    git -C "$toplevel" worktree add --no-track -b "$branch" "$target" HEAD >&2 || return 1
  fi
  repo_dir="$target"
}

work="$WORK_DIR/$version"
if mkdir -p "$work" 2>/dev/null; then
  work="$(cd "$work" && pwd -P)"
else
  echo "release: warning: could not create work folder $work" >&2
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
        ensure_worktree "$toplevel" || echo "release: warning: could not create worktree; continuing without it" >&2
      else
        echo "release: warning: not in a git repository; created the empty work folder only" >&2
      fi
      ;;
  esac
fi

if [ -n "$repo_dir" ] && [ "$inside" = 0 ] && [ -n "${CMUX_WORKSPACE_ID:-}" ]; then
  if cmux new-workspace --name "$title" --cwd "$repo_dir" --focus true \
       --command "opencode --prompt '/release $version'" >/dev/null 2>&1; then
    nohup sh -c "sleep 6; cmux close-workspace --workspace '$CMUX_WORKSPACE_ID' --force" >/dev/null 2>&1 &
    disown 2>/dev/null || true
    echo "RELAUNCHED: $title"
    echo "Work:   $work"
    echo "Repo:   $repo_dir"
    echo "Branch: $branch"
    echo "A new cmux workspace started in the worktree and continues /release there. This workspace closes in a few seconds."
    exit 0
  fi
  echo "release: warning: could not start a workspace in $repo_dir; continuing in the current directory" >&2
fi

if [ -n "${CMUX_WORKSPACE_ID:-}" ]; then
  cmux workspace rename "$CMUX_WORKSPACE_ID" --title "$title" >/dev/null 2>&1 \
    || echo "release: warning: could not rename cmux workspace" >&2
  cmux workspace-action --action set-color --color Purple --workspace "$CMUX_WORKSPACE_ID" >/dev/null 2>&1 \
    || echo "release: warning: could not set cmux workspace colour" >&2
else
  echo "release: warning: CMUX_WORKSPACE_ID not set; skipped workspace rename and colour" >&2
fi

if [ -n "${OPENCODE_SESSION_ID:-}" ]; then
  # Marker first, so the title-lock plugin protects the title from the start.
  mkdir -p "$MARKER_DIR"
  : > "$MARKER_DIR/$OPENCODE_SESSION_ID"
  opencode api patch "/api/session/$OPENCODE_SESSION_ID" \
    --data "$(jq -n --arg t "$title" '{title: $t}')" >/dev/null 2>&1 \
    || echo "release: warning: could not rename OpenCode session" >&2
else
  echo "release: warning: OPENCODE_SESSION_ID not set; skipped session rename" >&2
fi

echo "Title:  $title"
[ -n "$work" ] && echo "Work:   $work"
[ -n "$repo_dir" ] && echo "Repo:   $repo_dir"
echo "Branch: $branch"
