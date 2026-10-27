---
description: Mark this session as blocked - prefix the session and cmux workspace title with "BLOCK:" and colour the workspace red
---

Run `~/.config/opencode/scripts/mark.sh BLOCK Red` with the shell tool. It replaces any existing prefix such as `STORY:` or `BLOCK:` with `BLOCK:`, renames the cmux workspace and this session, and sets the workspace colour to red. Report the resulting title, or the error if it fails. Do nothing else.
