# Antigravity Skill Library

Skills, hooks, scripts, and commands for Claude Code and Antigravity agents. Includes KB-derived workflow tools built from 169 processed videos (Nate B Jones + Ben AI).

## Repository Structure

```
skills/           # Claude Code skills (auto-invoked based on context)
hooks/            # Lifecycle hooks (run automatically on events)
scripts/          # Shell scripts (run manually from terminal)
commands/         # Slash commands (invoked via /command-name in Claude Code)
```

## KB-Derived Components

Built from the EliteX Knowledge Base — 136 structured notes, 32 named frameworks.

### Skills

| Skill | Source Frameworks | What It Does |
|-------|-------------------|-------------|
| `spec-driven-development` | specification-bottleneck, colleague-vs-tool-shaped-ai, five-levels-of-ai-coding | Enforces spec-before-code. Colleague mode to clarify intent, Tool mode to execute. Targets Level 4+ AI coding. |
| `agent-architecture` | agent-responsibility-minimization, multi-agent-failure-patterns, phronesis-practical-wisdom | Agent = decisions + communication only. Default to single agent. Sub-agent communication templates. Principles over rules. |
| `prompt-templates` | prompt-engineering-frameworks | Three ready-to-use prompt formats: Short Structured, Long Structured, Agent. Use-case selection matrix included. |

### Hooks

| Hook | Event | What It Does |
|------|-------|-------------|
| `spec-gate.js` | PostToolUse (Write) | Warns when writing code without a SPEC.md in the project root. Automatic, silent when spec exists. |
| `productization-tracker.js` | Stop | Logs date/project/description to `~/.claude/logs/solutions-built.log` after each build session. Surfaces productization candidates over time. |

### Scripts

| Script | Usage | What It Does |
|--------|-------|-------------|
| `write-spec.sh` | `write-spec.sh "task description"` | Runs Claude in colleague-shaped mode to produce a SPEC.md. Use before ralph-loop. |
| `scenario-suite.sh` | `scenario-suite.sh` (from project root) | Generates SCENARIOS.md — external behavioral specs the agent never sees during development. Holdout set for quality gating. |

### Commands

| Command | Usage | What It Does |
|---------|-------|-------------|
| `kb` | `/kb <query>` | Search the Knowledge Base for frameworks, insights, and actionable ideas |
| `scope-project` | `/scope-project <description>` | Generate a project scope with pricing using KB agency frameworks |
| `blog-from-kb` | `/blog-from-kb <topic>` | Generate an elite-x.tech blog article grounded in KB content |
| `brainstorm` | `/brainstorm <topic>` | Structured brainstorming session using KB + venture context |

## Installation

### Automated (Recommended)

```bash
curl -sSL https://raw.githubusercontent.com/Elit3-X/antigravity-skill-library/main/install.sh | bash
```

### Manual

```bash
git clone https://github.com/Elit3-X/antigravity-skill-library.git
cd antigravity-skill-library

# Skills
cp -R skills/* ~/.claude/skills/

# Hooks
mkdir -p ~/.claude/hooks
cp hooks/* ~/.claude/hooks/

# Scripts
mkdir -p ~/.claude/scripts
cp scripts/* ~/.claude/scripts/
chmod +x ~/.claude/scripts/*.sh

# Commands
mkdir -p ~/.claude/commands
cp commands/* ~/.claude/commands/
```

Then add hooks to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "node \"~/.claude/hooks/spec-gate.js\""
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "node \"~/.claude/hooks/productization-tracker.js\""
          }
        ]
      }
    ]
  }
}
```

## Workflow

1. Have an idea -> `write-spec.sh "the idea"` -> produces SPEC.md
2. Run `scenario-suite.sh` -> produces SCENARIOS.md (external holdout set)
3. Run `ralph-loop.sh SPEC.md` -> autonomous build loop
4. `spec-gate` hook stays silent because SPEC.md exists
5. Session ends, `productization-tracker` logs what was built
6. Skills activate silently when Claude detects relevant context

## Source Frameworks

| Framework | Origin | Key Insight |
|-----------|--------|-------------|
| Specification Bottleneck | Nate B Jones | Code is cheap, specs are expensive. Invest in spec quality. |
| Colleague vs Tool-Shaped AI | Nate B Jones | Start exploratory (colleague), switch to execution (tool). |
| 5 Levels of AI Coding | Nate B Jones | Most devs plateau at Level 2. Target Level 4+. |
| Agent Responsibility Minimization | Ben AI | Agent = decisions only. Tools do generation. Sub-agents do specialized reasoning. |
| Multi-Agent Failure Patterns | Nate B Jones | More agents = worse. Default to single agent. |
| Phronesis (Practical Wisdom) | Nate B Jones | Write principles, not rules. Agents need judgment. |
| Scenarios vs Tests | Nate B Jones | Tests are gameable. Scenarios (external holdout) are not. |
| Prompt Engineering Frameworks | Ben AI | Short/Long/Agent templates. Notes section exploits end-of-prompt attention. |
| Ralph Pattern | Nate B Jones | Loop until tests pass. Git as memory. Simpler than orchestration. |
| Productized AI System | Ben AI | Track what you build. 3+ repeats = productize. 85% margins vs 40%. |
