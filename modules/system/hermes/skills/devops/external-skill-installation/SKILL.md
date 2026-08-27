---
name: external-skill-installation
description: "Install external agent skills (GitHub repos, CLAUDE.md, SKILL.md) into Hermes permanent skills directory in dotfiles."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [skill-management, dotfiles, installation, external-skills]
    related_skills: [hermes-agent]
---

# External Skill Installation

Workflow for taking skills from external sources (GitHub repos, community skill sets) and installing them as permanent Hermes skills in the dotfiles repository.

## Directory Structure

```
/dotfiles/modules/system/hermes/skills/
├── creative/           # Creative/design skills
├── devops/             # DevOps, CI/CD, infrastructure
├── software-development/ # Code, architecture, testing
└── svelte/             # Svelte/SvelteKit specific
```

## Installation Process

### 1. Identify Source

Find the external skill. Common sources:
- GitHub repos (e.g., `mattpocock/skills`, community forks)
- CLAUDE.md files from other projects
- Blog posts with agent prompts
- OpenSpec SDD specifications

### 2. Download Files

```bash
# From GitHub raw content
curl -sL https://raw.githubusercontent.com/<user>/<repo>/main/<path>/SKILL.md -o /tmp/skill.md

# If skill has referenced files (tests.md, mocking.md, etc.)
curl -sL https://raw.githubusercontent.com/<user>/<repo>/main/<path>/tests.md -o /tmp/tests.md
```

### 3. Choose Category

Place in the appropriate category directory:
- **software-development/** - Code review, TDD, architecture, patterns
- **devops/** - CI/CD, Docker, NixOS, deployment
- **creative/** - Design, visuals, writing
- **svelte/** - Svelte/SvelteKit specific patterns

### 4. Name the Directory

Use `<source>-<skill-name>` format:
- `matt-pocock-code-review` (from Matt Pocock's repo)
- `community-tdd-patterns` (from community contribution)
- `opencode-best-practices` (from OpenCode docs)

### 5. Add Hermes Frontmatter

Every SKILL.md must have YAML frontmatter:

```yaml
---
name: <directory-name>           # Must match directory name
description: "<one-line description>"
version: 1.0.0
author: <original-author> (adapted for Hermes)
license: MIT
metadata:
  hermes:
    tags: [tag1, tag2, tag3]     # For search/discovery
    related_skills: [other-skill-name]
---
```

### 6. Adapt for Hermes

Replace Claude Code / OpenCode specific references:

| Original | Hermes Adaptation |
|----------|-------------------|
| `Call the Skill tool with "X"` | `Load skill_view(name="X")` |
| `CLAUDE.md` | `CONTEXT.md` or project docs |
| `.claude/` directory | Hermes skill directory |
| `claude plugins install` | Copy to dotfiles + rebuild |

### 7. Copy Referenced Files

If the skill references other files (tests.md, mocking.md, HTML-REPORT.md):
- Copy them into the same skill directory
- Update any internal references to use relative paths

### 8. Test the Skill

```bash
# From Hermes session
skill_view(name="<skill-name>")
```

Verify:
- Frontmatter parses correctly
- Content is complete
- No broken references to other skills
- Tool references are Hermes-compatible

### 9. Commit to Dotfiles

```bash
cd /dotfiles
git add modules/system/hermes/skills/
git commit -m "skills: add <skill-name> from <source>"
git push
```

## Naming Convention

| Pattern | Example | When |
|---------|---------|------|
| `<source>-<name>` | `matt-pocock-tdd` | External skill from known author |
| `<name>` | `code-review-skill` | Original Hermes skill |
| `<category>-<name>` | `svelte-shadcn-integration` | Category-specific skill |

## Updating External Skills

When the source repo updates:

```bash
# Re-download the skill
curl -sL https://raw.githubusercontent.com/<user>/<repo>/main/<path>/SKILL.md -o /tmp/skill.md

# Diff against current
diff /dotfiles/modules/system/hermes/skills/<category>/<skill-name>/SKILL.md /tmp/skill.md

# Apply updates if beneficial
cp /tmp/skill.md /dotfiles/modules/system/hermes/skills/<category>/<skill-name>/SKILL.md
```

## Skill File Format

### Minimum Viable SKILL.md

```markdown
---
name: my-skill
description: "What this skill does in one line."
---

# Skill Title

## When to Use
- Condition 1
- Condition 2

## Process
1. Step one
2. Step two
```

### Full SKILL.md

```markdown
---
name: my-skill
description: "Detailed description of what this skill does."
version: 1.0.0
author: Author Name
license: MIT
metadata:
  hermes:
    tags: [tag1, tag2]
    related_skills: [other-skill]
---

# Skill Title

## Overview
What this skill accomplishes.

## When to Use
- Trigger conditions

## Process
Step-by-step instructions.

## Examples
Code samples or command examples.

## Pitfalls
What to watch out for.

## References
Links to external docs or related skills.
```

## Currently Installed External Skills

| Skill | Source | Category | Installed |
|-------|--------|----------|-----------|
| matt-pocock-code-review | mattpocock/skills | software-development | 2026-08-27 |
| matt-pocock-codebase-design | mattpocock/skills | software-development | 2026-08-27 |
| matt-pocock-improve-codebase-architecture | mattpocock/skills | software-development | 2026-08-27 |
| matt-pocock-to-spec | mattpocock/skills | software-development | 2026-08-27 |
| matt-pocock-grill-with-docs | mattpocock/skills | software-development | 2026-08-27 |
| matt-pocock-tdd | mattpocock/skills | software-development | 2026-08-27 |
