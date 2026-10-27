# OpenCode Config

Personal OpenCode setup: skills, commands, scripts, and plugins. The folders mirror `~/.config/opencode/` and are symlinked into it.

## Overview

| Folder | Contents |
|---|---|
| [`skills/`](./skills/) | Agent skills that enforce coding standards, architectural patterns, and best practices |
| [`commands/`](./commands/) | Slash commands (`/story`, `/pr`, `/done`, ...) |
| [`scripts/`](./scripts/) | Shell scripts called by the commands |
| [`plugins/`](./plugins/) | OpenCode plugins (cmux integration, session title handling) |

## Available Skills

### [software-development](./skills/software-development/)
Enforce language-agnostic software engineering principles — SOLID design, the Boy Scout principle, early returns, naming clarity, real types over primitives, value objects, exception handling, and encapsulation.

**Coverage:**
- SOLID principles (Single Responsibility, Open/Closed — priority, Liskov Substitution, Interface Segregation, Dependency Inversion)
- Boy Scout principle (leave code better than you found it)
- Early returns and guard clauses
- Naming clarity (no abbreviations, storage-agnostic naming for stores)
- Real types over primitives (avoiding primitive obsession)
- Value objects with built-in validation
- Exception handling as control flow (result types over throwing)
- Encapsulation via most-restrictive accessibility
- No regions or visual comment separators

**Use when:** Creating, modifying, or reviewing code in any language — especially when evaluating extensibility, coupling, class responsibilities, naming, or how errors/nulls are represented.

---

### [api-design](./skills/api-design/)

Enforce API design standards for ASP.NET Core APIs including versioning strategy, status code declarations, TypedResults usage, ProblemDetails contracts, and response metadata.

**Coverage:**
- True REST resource modelling (properties vs sub-resources, PATCH over sub-resources)
- Versioning strategy (URL-prefix, not header or content-negotiation)
- TypedResults as the primary response documentation mechanism
- Standard status code catalogue (200, 201, 204, 400, 401, 403, 404, 408, 409, 422, 500)
- 408 for client abort/disconnect
- ProblemDetails for all 4xx and 5xx responses
- `[ProducesResponseType]` for supplemental descriptions
- Do-not-use guidance for `[SwaggerResponse]`
- URL casing (lowercase kebab-case) and enum formatting
- OpenAPI metadata conventions (`[ExcludeFromDescription]`, `[Tags]`, `[EndpointDescription]`, `[EndpointSummary]`)
- Strongly typed `IOptions<T>` over raw `IConfiguration`

**Use when:** Designing, documenting, or reviewing ASP.NET Core APIs — versioning strategy, status codes, TypedResults, or OpenAPI metadata.

---

### [csharp-development](./skills/csharp-development/)
Enforce C#/.NET-specific coding conventions — casing, project setup, using directives, CancellationToken propagation, IOptions<T> configuration, and syntax-level idioms. For language-agnostic design principles, see `software-development`.

**Coverage:**
- .NET 10 project conventions (`global.json`, central package management, `Directory.Build.props`)
- Naming conventions (PascalCase/camelCase)
- Documentation minimalism (self-documenting names over comments, single-line summaries for public interfaces)
- Global usings and using directive ordering
- Namespace and folder structure alignment
- Source-generated regex (`[GeneratedRegex]`) with required timeout
- Pattern matching over null checks
- CancellationToken propagation
- Strongly typed `IOptions<T>` configuration
- Model mapping conventions
- Test assertion cleanliness

**Use when:** Creating, modifying, or reviewing C# code in .NET projects.

---

### [testing-standards-and-skills](./skills/testing-standards-and-skills/)
Enforce repository unit test standards for xUnit, Shouldly, naming, structure, and embedded test resources.

**Coverage:**
- xUnit test framework conventions
- Shouldly assertion library usage
- Test naming patterns (`MethodUnderTest_ExpectedBehavior_Condition`)
- Arrange/Act/Assert structure
- Test categorization (Unit/Integration traits)
- Version traits for multiple interface versions
- Project and folder structure
- Embedded resource management

**Use when:** Writing or reviewing unit and integration tests.

---

### [feature-sliced-architecture](./skills/feature-sliced-architecture/)
Structure ASP.NET Core applications around vertical feature folders with isolated dependency injection, feature boundaries, and shared infrastructure modules.

**Coverage:**
- Vertical slice architecture principles
- Feature folder organization
- Dependency injection conventions
- Infrastructure module patterns
- Feature boundaries and coupling
- Configuration management
- Naming conventions for features and infrastructure

**Use when:** Building or refactoring ASP.NET Core applications with feature-based organization.

---

### [grill-me](./skills/grill-me/)
Grill the user relentlessly about a plan, decision, or idea to stress-test their thinking.

**Coverage:**
- Design-tree modelling of decisions and their dependents
- Round-based questioning limited to the current "frontier" of unblocked decisions
- Numbered questions with a recommended answer for each
- Fact-finding delegated to sub-agents instead of asking the user
- Non-blocking exploration — unrelated frontier questions proceed while facts are gathered
- Session ends only when the full design tree has been visited

**Use when:** The user wants to stress-test a plan, decision, or idea, or uses any 'grill' trigger phrases.

---

### [concise-writing](./skills/concise-writing/)
Enforce brevity in agent output, code comments, and markdown docs.

**Coverage:**
- 4-line guideline for code comments/summaries
- 4-line guideline for markdown paragraphs
- No chatty narration in agent responses
- Target-state-as-fact for anything created or changed within a single PR (no "added X" / "changed Y from A to B")

**Use when:** Any code review, doc writing, PR description, or commit message.

---

### [conventional-commits](./skills/conventional-commits/)
Enforce Conventional Commits message format.

**Coverage:**
- `type(scope): description` subject format
- Type catalogue (`feat`, `fix`, `refactor`, `perf`, `style`, `test`, `docs`, `build`, `ops`, `chore`)
- Breaking-change indicator (`!`) and `BREAKING CHANGE:` footer
- Description/body/footer style rules
- Semver impact (major/minor/patch) per commit type

**Use when:** Writing or reviewing commit messages.

---

## Available Commands

Slash commands in [`commands/`](./commands/). Those that mark a session call a shared script in [`scripts/`](./scripts/).

| Command | Purpose | Script |
|---|---|---|
| `/story <KEY>` | Fetch a Jira story, create a worktree in `~/work/<KEY>/`, open a new cmux workspace, and start planning. Requires `JIRA_SITE` (e.g. `https://your-org.atlassian.net`) in the environment | `story.sh` |
| `/pr` | Prefix session and cmux workspace title with `PR:` and colour it aqua | `mark.sh` |
| `/done` | Prefix with `DONE:` and colour it green | `mark.sh` |
| `/block` | Prefix with `BLOCK:` and colour it red | `mark.sh` |
| `/investigate` | Prefix with `INVESTIGATE:` and colour it amber | `mark.sh` |
| `/prs` | Open the current repo's GitHub pull requests as a cmux browser tab | `prs.sh` |
| `/check-skills` | Verify all skills against the current codebase | - |

## Plugins

Plugins in [`plugins/`](./plugins/), loaded through `"plugins": ["./plugins"]` in `opencode.jsonc`.

| Plugin | Purpose |
|---|---|
| `cmux-feed.js` | Bridges the OpenCode event bus to the cmux feed. Managed by cmux and carries a local patch |
| `cmux-session.js` | Bridges session lifecycle events into cmux's session store. Managed by cmux |
| `story-title-lock.js` | Keeps the session title set by `story.sh` |
| `strip-thinking-block-binding.js` | Strips `thinking.block_binding` from outgoing requests to gateways whose URL contains `genai` |

`cmux-feed.js` and `cmux-session.js` are upgraded in place by cmux. Because `~/.config/opencode/plugins` is a symlink, upgrades appear as diffs in this repo; re-apply the local patch if needed.

## Installation

Clone the repo and symlink each folder into the OpenCode config directory:

```bash
REPO=~/Projects/opencode-config
mkdir -p ~/.config/opencode

ln -s "$REPO/skills"   ~/.config/opencode/skills
ln -s "$REPO/commands" ~/.config/opencode/commands
ln -s "$REPO/scripts"  ~/.config/opencode/scripts
ln -s "$REPO/plugins"  ~/.config/opencode/plugins
```

Commands reference scripts as `~/.config/opencode/scripts/<name>.sh`, so the `scripts` link is required for the commands to work. Restart OpenCode after linking `plugins`.

Plugins may only import Node built-ins. Node resolves imports from the real path inside this repo, so packages in `~/.config/opencode/node_modules` are not found.

### Project-Level Skills

To use a skill in a single project instead, copy it into the project:

```bash
mkdir -p .opencode/skills
cp -r "$REPO/skills/software-development" .opencode/skills/
```

### Alternative Skill Paths

OpenCode also searches these locations:
- `.claude/skills/<name>/SKILL.md`
- `~/.claude/skills/<name>/SKILL.md`
- `.agents/skills/<name>/SKILL.md`
- `~/.agents/skills/<name>/SKILL.md`

## Usage

Once installed, OpenCode will automatically discover available skills. The agent can load skills when needed using the native skill tool.

Skills are loaded on-demand—the agent sees available skills and loads the full content when the task matches the skill's description.

## Skill Structure

Each skill follows this structure:

```
skills/skill-name/
├── SKILL.md       # Main skill definition with YAML frontmatter
└── README.md      # Optional: Skill-specific documentation
```

### SKILL.md Format

```yaml
---
name: skill-name
description: Brief description for agent discovery
license: MIT | Proprietary
compatibility: opencode
metadata:
  key: value
---

## What I do
[Description of what the skill enforces]

## When to use me
[Guidance on when to apply this skill]

## [Sections with rules, examples, and guidance]
```

## Creating New Skills

To create a new skill:

1. Create a directory under `skills/` with a valid skill name (lowercase, alphanumeric, hyphens only)
2. Add a `SKILL.md` file with proper YAML frontmatter
3. Include clear sections: "What I do", "When to use me", and detailed rules
4. Provide concrete examples (good and bad)
5. Add enforcement guidelines

### Skill Name Requirements

- 1-64 characters
- Lowercase alphanumeric with single hyphen separators
- Cannot start or end with `-`
- No consecutive `--`
- Regex: `^[a-z0-9]+(-[a-z0-9]+)*$`

## Creating New Commands

1. Add `commands/<name>.md` with `description` frontmatter (and optionally `agent` and `model`).
2. If the command needs a shell script, add it to `scripts/`, make it executable, and call it as `~/.config/opencode/scripts/<name>.sh`.
3. Keep scripts independent of their own location (no `$0` or `BASH_SOURCE` path lookups).
4. Add the command to the table above.

## Contributing

When adding or modifying skills, commands, scripts, or plugins:

1. Follow the established structure and formatting
2. Provide clear, actionable rules
3. Include concrete examples
4. Test the skill with OpenCode before committing
5. Update this README with new skills, commands, scripts, or plugins

## Philosophy

These skills embody several key principles:

- **Zero warnings**: Code must be clean and warning-free
- **Boy Scout principle**: Leave code better than you found it
- **Consistency**: Apply standards uniformly across the codebase
- **Clarity over cleverness**: Readable, maintainable code wins
- **Pragmatism**: Rules have clear rationale and exceptions when justified

## License

Individual skills may have different licenses. Check each skill's SKILL.md frontmatter for licensing information.

## Related Resources

- [OpenCode Documentation](https://opencode.ai/docs)
- [OpenCode Skills Guide](https://opencode.ai/docs/skills)
