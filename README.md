# EliteX Skill Library

Single source of truth for Claude Code configuration across all EliteX workstations. Contains skills, hooks, scripts, commands, and global config.

## Structure

```
skills/              223 skills (auto-invoked by Claude based on context)
hooks/               5 hooks (lifecycle events — automatic)
scripts/             4 scripts (manual terminal tools)
commands/            36 slash commands + gsd/ subcommands
CLAUDE.md            Global agent instructions
settings.json.example   Reference settings with hook registration
```

## What's Inside

### Skills (223)

Full library covering:

| Category | Examples | Count |
|----------|---------|-------|
| Azure SDKs | blob, cosmos, keyvault, search, identity, eventhub, servicebus | ~110 |
| Frontend | react-best-practices, frontend-design, tailwind, nextjs, react-native | ~15 |
| Backend | backend-patterns, django, springboot, fastapi, postgres, clickhouse | ~15 |
| Testing/TDD | tdd-workflow, python-testing, golang-testing, django-tdd, springboot-tdd | ~10 |
| Agent/AI | multi-agent-patterns, evaluation, context-optimization, memory-systems | ~15 |
| Workflow | planning-with-files, executing-plans, verification-before-completion | ~10 |
| Content | docx, pdf, pptx, xlsx, obsidian-markdown, obsidian-bases, json-canvas | ~10 |
| KB-Derived | spec-driven-development, agent-architecture, prompt-templates | 3 |
| Other | security-review, mcp-builder, brand-guidelines, algorithmic-art, etc. | ~35 |

**KB-Derived Skills (from EliteX Knowledge Base):**

| Skill | Source Frameworks | Purpose |
|-------|-------------------|---------|
| `spec-driven-development` | specification-bottleneck, colleague-vs-tool-shaped-ai, five-levels-of-ai-coding | Spec before code. Colleague mode to clarify, Tool mode to execute. |
| `agent-architecture` | agent-responsibility-minimization, multi-agent-failure-patterns, phronesis | Agent = decisions only. Single agent default. Principles over rules. |
| `prompt-templates` | prompt-engineering-frameworks | Short/Long/Agent prompt formats with selection matrix. |

### Hooks (5)

| Hook | Event | Purpose |
|------|-------|---------|
| `spec-gate.js` | PostToolUse (Write) | Warns when writing code without SPEC.md |
| `productization-tracker.js` | Stop | Logs builds to `~/.claude/logs/solutions-built.log` |
| `kb-reflection.js` | Stop | Logs session completions to Knowledge Base |
| `gsd-check-update.js` | SessionStart | GSD mode initialization |
| `gsd-statusline.js` | StatusLine | GSD status bar display |

### Scripts (4)

| Script | Usage | Purpose |
|--------|-------|---------|
| `write-spec.sh` | `write-spec.sh "task"` | Claude generates SPEC.md from task description |
| `scenario-suite.sh` | `scenario-suite.sh` | Generates external behavioral scenarios (holdout set) |
| `ralph-loop.sh` | `ralph-loop.sh SPEC.md 10` | Autonomous build loop — git as memory, tests as exit criteria |
| `kb-ingest.sh` | `kb-ingest.sh` | Ingest new content into Knowledge Base |

### Commands (36 + 31 gsd subcommands)

**Knowledge Base:**
`/kb`, `/brainstorm`, `/blog-from-kb`, `/scope-project`

**Vault:**
`/obsidian`, `/noobsidian`, `/research-to-vault`

**Secrets:**
`/get-secret`, `/gen-password`

**GSD (Get Shit Done):**
`/gsd-new-project`, `/gsd-new-milestone`, `/gsd-execute-phase`, `/gsd-progress`, `/gsd-debug`, and 27 more.

## Installation

### Automated

```bash
curl -sSL https://raw.githubusercontent.com/Elit3-X/elitex-skill-library/main/install.sh | bash
```

### Manual

```bash
git clone https://github.com/Elit3-X/elitex-skill-library.git
cd elitex-skill-library

# Skills
cp -R skills/* ~/.claude/skills/

# Hooks
cp hooks/* ~/.claude/hooks/

# Scripts
cp scripts/* ~/.claude/scripts/
chmod +x ~/.claude/scripts/*.sh

# Commands
cp commands/*.md ~/.claude/commands/
cp -R commands/gsd ~/.claude/commands/gsd

# Global config (review before overwriting)
cp CLAUDE.md ~/.claude/CLAUDE.md
cp settings.json.example ~/.claude/settings.json
```

### Push Local Changes Back

After modifying skills/hooks/scripts locally, sync back to the repo:

```bash
cd /path/to/elitex-skill-library
cp -R ~/.claude/skills/* skills/
cp ~/.claude/hooks/*.js hooks/
cp ~/.claude/scripts/*.sh scripts/
cp ~/.claude/commands/*.md commands/
cp -R ~/.claude/commands/gsd commands/gsd
cp ~/.claude/CLAUDE.md CLAUDE.md
git add -A && git commit -m "sync from workstation" && git push
```

## Workflow

```
Idea -> write-spec.sh -> SPEC.md
SPEC.md -> scenario-suite.sh -> SCENARIOS.md
SPEC.md -> ralph-loop.sh -> Autonomous build (git as memory, tests as gate)
                             spec-gate hook stays silent (spec exists)
                             productization-tracker logs the build
                             kb-reflection logs completions
```
