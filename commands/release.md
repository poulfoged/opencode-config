---
description: Create a release worktree named after the given version, open it in a new cmux workspace, and name the session RELEASE: <version>
---

Start release $ARGUMENTS.

1. Run `~/.config/opencode/scripts/release.sh $ARGUMENTS` with the shell tool. It creates the work folder `~/work/<version>/` with a git worktree of the current repo on branch `release/<version>`, branched from the current HEAD, and starts this command again in a new cmux workspace inside that worktree. When it runs in the worktree it names the cmux workspace and this session `RELEASE: <version>` and colours the workspace purple. If it fails, report the error and stop.
2. If the output starts with `RELAUNCHED:`, stop. Tell the user the release continues in the new workspace and this one closes shortly. Do nothing else.
   If the output contains `could not create worktree` or `skipped worktree`, stop. Quote the `release:` warning lines and tell the user no worktree was created, so this session is still in the original checkout. Do nothing else.
3. Report the resulting title and the `Work:`, `Repo:` and `Branch:` lines. Quote any `release: warning:` lines. Do nothing else.
