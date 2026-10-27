---
description: Fetch a Jira story, set up a work folder with a repo worktree, open it in a browser tab, name the session after it, and start planning
agent: plan
---

Start work on Jira story $ARGUMENTS (if empty, the script uses the key from the current git branch).

1. Run `~/.config/opencode/scripts/story.sh $ARGUMENTS` with the shell tool. It fetches the story, creates the work folder `~/work/<KEY>/` with a git worktree of the current repo, and starts this command again in a new cmux workspace inside that worktree. When it runs in the worktree it opens the story as a browser tab (reusing an existing tab for the same key) and names the cmux workspace and this session. If it fails, report the error and stop.
2. If the output starts with `RELAUNCHED:`, stop. Tell the user the story continues in the new workspace and this one closes shortly. Do nothing else.
   If the output contains `could not create worktree` or `skipped worktree`, stop. Quote the `story:` warning lines and tell the user no worktree was created, so this session is still in the original checkout. Do nothing else.
3. Read the story, including description, acceptance criteria and comments.
4. Check it against the repository: `AGENTS.md`, `CONTEXT.md`, `docs/adr/` and the code it touches.
5. Present a plan: summary of the story, proposed approach, open questions, and risks. Make no code changes. The output lists the `Work:` folder; if you are asked to write notes or a plan to a file, put it there.
