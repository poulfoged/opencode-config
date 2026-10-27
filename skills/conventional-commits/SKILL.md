---
name: conventional-commits
description: Enforce Conventional Commits message format — type(scope): description, breaking-change indicator, body/footer conventions. Use when writing or reviewing commit messages.
license: MIT
compatibility: opencode
---

Format: `<type>(<optional scope>): <description>`, optional body, optional footer — each separated by a blank line.

**Types:** `feat`, `fix`, `refactor` (`perf` for performance-focused refactors), `style`, `test`, `docs`, `build`, `ops`, `chore`.

**Breaking changes:** add `!` before `:` in the subject (`feat(api)!: remove status endpoint`). Footer must start with `BREAKING CHANGE:` unless the description already makes it clear.

**Description:** imperative present tense ("add" not "added"), no capital first letter, no trailing period.

**Body:** optional — motivation and contrast with previous behavior, imperative present tense.

**Footer:** optional unless breaking change; may reference issues (`Closes #123`).

**Versioning:** breaking change → major; `feat`/`fix` → minor; else → patch.

Example:
```
feat(cart)!: remove legacy checkout endpoint

BREAKING CHANGE: checkout endpoint no longer accepts v1 payloads
```
