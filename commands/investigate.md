---
description: Mark this session as an investigation (INVESTIGATE: prefix, amber workspace) and optionally start investigating a topic given as the prompt
agent: plan
---

1. Deduce a good short title, then run `~/.config/opencode/scripts/mark.sh INVESTIGATE Amber "<title>"` with the shell tool. It replaces any existing prefix such as `STORY:` or `BLOCK:` with `INVESTIGATE:`, renames the cmux workspace and this session, and sets the workspace colour to amber.
   - Deduce the title from the topic below. If the topic is empty, deduce it from the conversation so far. If there is nothing to go on, omit the title argument so the current title is kept.
   - The title is 3–7 words in sentence case and says what is being investigated. Leave out the `INVESTIGATE:` prefix, any ticket key (the script keeps an existing one), quotes and trailing punctuation.
   - On success, report the resulting title.
   - On failure (non-zero exit), start your reply with `⚠️ mark.sh failed:` followed by the full error output. Do this before anything else.
   - `mark.sh` also prints `mark: warning: ...` lines to stderr and still exits 0 when only part of the marking failed, such as the workspace rename or the colour. Quote any warnings in your reply as well.
2. If the topic below is not empty, start investigating it now. Research and discuss only, and make no code changes.

Topic: $ARGUMENTS
