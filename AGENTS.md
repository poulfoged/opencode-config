# AGENTS.md

## Repo purpose

Personal OpenCode setup: skills (reusable instruction files loaded on-demand by the agent skill tool), slash commands, the shell scripts they call, and plugins. No build system, tests, or CI.

## Structure

```
skills/<skill-name>/SKILL.md   ← required; YAML frontmatter + skill content
commands/<command-name>.md     ← slash command; `description` frontmatter, optional `agent` and `model`
scripts/<name>.sh              ← executable shell scripts called by commands
plugins/<name>.js              ← OpenCode plugins
```

Each skill is one directory containing exactly `SKILL.md`. No other files are required.

These four folders are symlinked into `~/.config/opencode/` (`skills`, `commands`, `scripts`, `plugins`). Edit files here, never in the config directory.

## Commands, scripts, and plugins

- Commands call scripts as `~/.config/opencode/scripts/<name>.sh`. Keep that path form.
- Scripts must be executable (`chmod +x`) and independent of their own location (no `$0` / `BASH_SOURCE` path lookups).
- Plugins may only import Node built-ins; imports resolve from the real path in this repo, not from `~/.config/opencode/node_modules`.
- `plugins/cmux-feed.js` and `plugins/cmux-session.js` are upgraded in place by cmux; expect diffs and keep the local patch in `cmux-feed.js`.
- Plugins load at startup; restart OpenCode after changing them.

## Skill name rules

- Lowercase alphanumeric with single hyphens: `^[a-z0-9]+(-[a-z0-9]+)*$`
- 1–64 characters, cannot start or end with `-`, no `--`

## SKILL.md frontmatter (required fields)

```yaml
---
name: skill-name          # must match directory name
description: ...          # used by agent for discovery — keep it precise
license: MIT | Proprietary
compatibility: opencode
---
```

## Installation paths OpenCode searches

Skills must be placed in one of these locations to be auto-discovered (the global location is a symlink to this repo's `skills/` folder):

- `.opencode/skills/<name>/SKILL.md` (project-local)
- `~/.config/opencode/skills/<name>/SKILL.md` (global)
- `.claude/skills/<name>/SKILL.md`
- `~/.claude/skills/<name>/SKILL.md`
- `.agents/skills/<name>/SKILL.md`
- `~/.agents/skills/<name>/SKILL.md`

## Agent behaviour

- Give running progress updates on any task that touches more than one file or takes more than a few steps.
- Don't silently work for a long time before responding — surface what you're doing as you go.

## When modifying skills, commands, scripts, or plugins

- The `description` field drives agent discovery — it must accurately describe when to use the skill.
- Keep rules actionable and concrete; avoid generic advice.
- Update `README.md` at repo root when adding or removing a skill, command, script, or plugin.
- Test the skill with OpenCode before committing (load it via the skill tool and verify it activates correctly).

## Available skills

| Skill | When to load |
|---|---|
| `software-development` | Any code review/design work — SOLID principles, Boy Scout principle, naming clarity, value objects, exception handling, encapsulation, regardless of language |
| `api-design` | Designing, documenting, or reviewing ASP.NET Core APIs — versioning strategy, status codes, TypedResults, or OpenAPI metadata |
| `csharp-development` | Creating, modifying, or reviewing C# / .NET code |
| `testing-standards-and-skills` | Writing or reviewing xUnit tests |
| `feature-sliced-architecture` | Building or refactoring ASP.NET Core apps with feature folders |
| `grill-me` | Stress-testing a plan, decision, or idea, or on any 'grill' trigger phrase |
| `concise-writing` | Any code review, doc writing, PR description, or commit message — brevity in agent output, comments, and markdown |
| `conventional-commits` | Writing or reviewing commit messages |
