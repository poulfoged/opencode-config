---
name: concise-writing
description: Enforce brevity in agent output, code comments, and markdown docs — 4-line guideline for summaries and paragraphs, no chatty narration, and target-state-as-fact for anything created or changed within a single PR. Use for any code review, doc writing, PR description, or commit message.
license: MIT
compatibility: opencode
---

Say what's needed, nothing more. Agents default to chatty commentary — resist that.

**Code comments/summaries:** aim for 4 lines max. Longer explanations belong in docs, not inline.

**Markdown paragraphs:** aim for 4 lines max. Split long prose into lists, headers, or tables instead.

**PR-scoped writing:** anything created or changed within a single PR is documented as the resulting state, not as a narrated diff. No "added X" / "changed Y from A to B." Applies to code comments, docs, commit messages, and PR descriptions alike. Diff history belongs to git log, not prose.

These are strong defaults, not hard limits — exceed them when content genuinely needs it, not out of habit.
