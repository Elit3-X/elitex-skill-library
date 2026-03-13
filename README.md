<p align="center">
  <img src="assets/logo.svg" alt="EliteX" width="200"/>
</p>

<h1 align="center">EliteX Skill Library</h1>

<p align="center">
  <em>Strategy meets execution. Knowledge meets code.</em><br/>
  <sub>The complete Claude Code toolkit for EliteX workstations.</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/skills-247-blue?style=flat-square" alt="247 skills"/>
  <img src="https://img.shields.io/badge/hooks-12-orange?style=flat-square" alt="12 hooks"/>
  <img src="https://img.shields.io/badge/scripts-9-green?style=flat-square" alt="9 scripts"/>
  <img src="https://img.shields.io/badge/commands-95-purple?style=flat-square" alt="95 commands"/>
  <img src="https://img.shields.io/badge/agents-170-red?style=flat-square" alt="170 agents"/>
  <img src="https://img.shields.io/badge/GSD_workflows-38-yellow?style=flat-square" alt="38 GSD workflows"/>
  <img src="https://img.shields.io/badge/teams-9-teal?style=flat-square" alt="9 teams"/>
</p>

---

## The Idea

We processed hundreds of hours of research on AI-native building, distilled it into 32 named frameworks, and turned all of it into something Claude Code can actually use — skills that fire automatically, hooks that watch your back, scripts that bridge the gap between "I have an idea" and "it's shipped."

This repo is the single source of truth. Clone it on a new machine, run the installer, and your entire workflow drops in. Every skill, every hook, every command — synced.

The yin-yang isn't just a logo. It's how this works: **strategy and tactics, thinking and doing, spec and code** — always in balance.

---

## How It Fits Together

```mermaid
graph TB
    subgraph "Your Brain"
        A[Idea] --> B["write-spec.sh"]
    end

    subgraph "Spec Layer"
        B --> C[SPEC.md]
        C --> D["scenario-suite.sh"]
        D --> E[SCENARIOS.md]
    end

    subgraph "Execution Layer"
        C --> F["ralph-loop.sh"]
        F -->|"git as memory"| G{Tests pass?}
        G -->|No| F
        G -->|Yes| H[Shipped]
    end

    subgraph "GSD Framework"
        I2["gsd-new-project"] --> I3["plan-phase"]
        I3 --> I4["execute-phase"]
        I4 --> I5["verify-work"]
        I5 -->|"iterate"| I3
    end

    subgraph "Auto-Resume Loop"
        M["gsd-context-monitor.js"] -->|"CRITICAL 25%"| N["handoff.json"]
        N --> O["auto-resume-loop.js"]
        O -->|"spawns"| P["infinite-agent.sh --resume"]
        P -->|"new session"| M
    end

    subgraph "Background — Always Running"
        I["spec-gate.js"] -.->|"PostToolUse"| F
        J["productization-tracker.js"] -.->|"Stop"| H
        K["vault-reflection-writer.js"] -.->|"Stop"| H
        L["gsd-context-monitor.js"] -.->|"PostToolUse"| F
    end

    style A fill:#1a1a2e,stroke:#555,color:#fff
    style C fill:#16213e,stroke:#0f3460,color:#fff
    style E fill:#16213e,stroke:#0f3460,color:#fff
    style H fill:#1a1a2e,stroke:#e0e0e0,color:#fff
    style I fill:#2d2d2d,stroke:#555,color:#aaa
    style J fill:#2d2d2d,stroke:#555,color:#aaa
    style K fill:#2d2d2d,stroke:#555,color:#aaa
    style L fill:#2d2d2d,stroke:#555,color:#aaa
```

---

## What's In The Box

### Skills — 247

Skills are markdown files that Claude loads automatically when it detects you're working in a relevant context. You don't invoke them. They just show up when you need them.

```mermaid
graph LR
    subgraph "KB-Derived — Built from our Knowledge Base"
        S1["spec-driven-development"]
        S2["agent-architecture"]
        S3["prompt-templates"]
    end

    subgraph "Platform & SDK"
        S4["110+ Azure SDKs"]
        S5["Frontend — React, Next.js, Tailwind"]
        S6["Backend — Django, Spring, FastAPI"]
    end

    subgraph "Workflow & Quality"
        S7["TDD, Testing & Verification"]
        S8["Planning & Execution"]
        S9["Security & Review"]
    end

    subgraph "Content & Style"
        S10["adapt, polish, critique"]
        S11["normalize, clarify, distill"]
        S12["animate, colorize, delight"]
    end

    style S1 fill:#1a1a2e,stroke:#0f3460,color:#fff
    style S2 fill:#1a1a2e,stroke:#0f3460,color:#fff
    style S3 fill:#1a1a2e,stroke:#0f3460,color:#fff
```

The three we built from the Knowledge Base are the ones that matter most:

| Skill | What It Actually Does |
|:------|:---------------------|
| **spec-driven-development** | Stops you from coding before you think. Forces a SPEC.md with success criteria, behavioral scenarios, and explicit scope boundaries. Based on the insight that *the bottleneck moved from code to specification* — building the wrong thing fast is worse than building nothing. |
| **agent-architecture** | When you're building any AI agent or automation, this skill enforces one rule: agents make decisions, tools do work. Default to one agent. Only add more if tasks are truly independent. Research proves more agents usually makes things worse. |
| **prompt-templates** | Three battle-tested prompt structures — Short (extraction), Long (generation), Agent (decision-making) — with a selection matrix telling you which to use when. Includes the Notes section trick that exploits how LLMs weight the end of prompts more heavily. |

#### New in this release — Content & Style Skills

22 new skills for content transformation, communication tuning, and output control:

| Skill | Purpose |
|:------|:--------|
| `adapt` | Adjust tone and format for different audiences |
| `animate` | Add motion and transitions to UI elements |
| `audit` | Systematic codebase audit framework |
| `bolder` | Make messaging more assertive and direct |
| `changelog-generator` | Auto-generate changelogs from git history |
| `clarify` | Simplify complex explanations |
| `colorize` | Apply color schemes and theming |
| `content-research-writer` | Research-grounded content creation |
| `critique` | Structured feedback on code or content |
| `delight` | Add polish and micro-interactions |
| `distill` | Extract key points from verbose content |
| `extract` | Pull structured data from unstructured text |
| `harden` | Security hardening patterns |
| `lead-research-assistant` | Deep research with source synthesis |
| `meeting-insights-analyzer` | Extract action items from meeting notes |
| `normalize` | Standardize formatting and conventions |
| `onboard` | Generate onboarding guides from codebases |
| `optimize` | Performance optimization patterns |
| `polish` | Final-pass quality improvements |
| `quieter` | Reduce output verbosity |
| `tailored-resume-generator` | Context-aware resume creation |
| `teach-impeccable` | Pedagogical explanation patterns |

### Agents — 170 personas across 13 categories

Agent definitions for spawning specialized teammates. Each has a focused role and clear boundaries.

#### GSD Framework Agents (12)

| Agent | Role |
|:------|:-----|
| `gsd-planner` | Creates executable phase plans with task breakdown and dependency analysis |
| `gsd-executor` | Executes plans with atomic commits, deviation handling, and checkpoints |
| `gsd-debugger` | Investigates bugs using scientific method, manages debug sessions |
| `gsd-verifier` | Verifies phase goal achievement through goal-backward analysis |
| `gsd-codebase-mapper` | Explores codebase and writes structured analysis documents |
| `gsd-roadmapper` | Creates project roadmaps with phase breakdown and requirement mapping |
| `gsd-phase-researcher` | Researches how to implement a phase before planning |
| `gsd-project-researcher` | Researches domain ecosystem before roadmap creation |
| `gsd-research-synthesizer` | Synthesizes research outputs from parallel researcher agents |
| `gsd-plan-checker` | Verifies plans will achieve phase goal before execution |
| `gsd-integration-checker` | Verifies cross-phase integration and E2E flows |
| `gsd-nyquist-auditor` | Fills validation gaps by generating tests and verifying coverage |

#### Domain Agent Categories (158 personas)

| Category | Count | Examples |
|:---------|:-----:|:--------|
| **Engineering** | 22 | Senior dev, frontend, backend architect, DB optimizer, DevOps, SRE, AI engineer, mobile, Solidity, embedded firmware |
| **Marketing** | 26 | Growth hacker, content strategist, SEO specialist, social media, email marketing, brand manager |
| **Specialized** | 22 | MCP builder, developer advocate, document generator, model QA, cultural intelligence strategist |
| **Game Development** | 19 | Game designer, level designer, narrative designer, QA tester, shader programmer |
| **Strategy** | 16 | Business analyst, competitive intelligence, market researcher, innovation scout |
| **Design** | 8 | UI/UX designer, motion designer, design system architect, accessibility specialist |
| **Testing** | 8 | QA engineer, performance tester, security tester, test automation architect |
| **Sales** | 8 | Account executive, SDR, solution architect, deal desk analyst |
| **Paid Media** | 7 | PPC specialist, programmatic buyer, creative strategist, analytics lead |
| **Spatial Computing** | 6 | AR developer, VR designer, 3D artist, spatial UX researcher |
| **Support** | 6 | Technical support, customer success, knowledge base manager |
| **Project Management** | 6 | Scrum master, program manager, release manager, risk analyst |
| **Product** | 4 | Product manager, product analyst, UX researcher, growth PM |

### GSD Framework — Get Shit Done

A full project management framework built into Claude Code. 38 workflows, 36 templates, 13 reference docs.

```
get-shit-done/
├── bin/           # CLI tooling (gsd-tools.cjs + lib/)
├── references/    # Model profiles, git integration, TDD, verification patterns
├── templates/     # Project, milestone, phase, debug, research templates
└── workflows/     # 38 executable workflow definitions
```

Key workflows: `new-project` → `plan-phase` → `execute-phase` → `verify-work` → `complete-milestone`

### Hooks — 12 watchers

Hooks run in the background. You never touch them. They fire on lifecycle events.

| Hook | When | What It Does |
|:-----|:-----|:-------------|
| `spec-gate.js` | PostToolUse (Write) | Checks if SPEC.md exists before writing code |
| `productization-tracker.js` | Stop | Logs what you built — patterns emerge after weeks |
| `kb-reflection.js` | Stop | Captures session summaries into the Knowledge Base |
| `vault-reflection-writer.js` | Stop | Auto-writes Obsidian vault notes after significant work |
| `vault-index-builder.js` | SessionStart | Rebuilds vault index for mid-session queries |
| `vault-context-loader.js` | SessionStart | Loads project-relevant vault notes into context |
| `ov-context-loader.js` | SessionStart | Loads Obsidian Vault session context (project-specific) |
| `handoff-resume-loader.js` | SessionStart | Loads handoff state for seamless session continuity |
| `auto-resume-loop.js` | Stop | Spawns `infinite-agent.sh --resume` when context exhausts — sessions never die |
| `gsd-context-monitor.js` | PostToolUse | Monitors context exhaustion at 35% (warn) and 25% (critical), triggers auto-handoff |
| `gsd-check-update.js` | SessionStart | Initializes GSD mode |
| `gsd-statusline.js` | StatusLine | Dynamic status bar with context usage, current task, progress |

### Scripts — 9 tools you run yourself

| Script | When You'd Use It |
|:-------|:------------------|
| `write-spec.sh "build a chatbot"` | Produces a structured SPEC.md with success criteria, scenarios, architecture |
| `scenario-suite.sh` | Generates behavioral scenarios from the outside — the agent can't game these |
| `ralph-loop.sh SPEC.md 10` | Autonomous build loop: run Claude, check tests, commit, retry with fresh context |
| `infinite-agent.sh` | Long-running autonomous agent with handoff, resume, and dollar-budget caps |
| `debug-loop.sh` | Iterative debugging with scientific method and checkpoints |
| `kb-ingest.sh` | Feed new research content into the Knowledge Base |
| `bw-auto-unlock.sh` | Bitwarden auto-unlock via macOS Keychain |
| `obsidian-sync.sh` | Sync vault index and session context |
| `obsidian-watch.sh` | Watch for vault changes and trigger syncs |

### Commands — 95 slash commands

Type these directly in Claude Code.

#### Core Workflow

| Command | What Happens |
|:--------|:-------------|
| `/commit` | Smart git commit — linting, conventional messages, auto-split for multi-concern changes |
| `/create-pull-request` | GitHub PR with summary, test plan, and generated status |
| `/create-pr` | Alias for `/create-pull-request` |
| `/pr-review` | 6-perspective PR review (PM, Dev, QA, Security, DevOps, Designer) |
| `/fix-github-issue` | Auto-checkout issue branch, fix, create PR, link issue |
| `/create-worktrees` | Creates git worktrees for all open PRs + cleanup for stale branches |
| `/update-branch-name` | Rename git branch + update PR |
| `/release` | Release management workflow |
| `/act` | Test GitHub Actions locally with Act |

#### Knowledge & Research

| Command | What Happens |
|:--------|:-------------|
| `/kb pricing strategies` | Searches the Knowledge Base and synthesizes relevant frameworks |
| `/brainstorm hotel tech` | Deep brainstorm using 8-10+ KB notes, cross-referenced against ventures |
| `/scope-project "AI chatbot"` | Full project scope with pricing, ROI, timeline, and tool stack |
| `/blog-from-kb ai automation` | 800-1200 word blog article grounded in KB data |
| `/research-to-vault <slug>` | Stage research findings to vault with backlinks |
| `/load-llms-txt` | Load llms.txt prompt context for any framework |

#### Vault & Memory

| Command | What Happens |
|:--------|:-------------|
| `/obsidian` | Activates vault mode — all research auto-writes to Obsidian |
| `/noobsidian` | Deactivates vault mode |
| `/vault-query <topic>` | Search vault notes by keyword, returns top matches with backlinks |
| `/vault-sync` | Update MEMORY.md pointers from current vault state |

#### Planning & Docs

| Command | What Happens |
|:--------|:-------------|
| `/create-plan` | Create execution plan with milestones |
| `/create-prd` | Create Product Requirements Doc |
| `/create-prp` | Create Product Release Plan |
| `/create-jtbd` | Create JTBD (Jobs To Be Done) template |
| `/context-prime` | Prime context for complex tasks |
| `/update-docs` | Auto-regenerate documentation |
| `/add-to-changelog` | Add entries to CHANGELOG.md |

#### Utilities

| Command | What Happens |
|:--------|:-------------|
| `/get-secret <name>` | Quick credential lookup from Bitwarden |
| `/gen-password` | Generate secure password via Bitwarden CLI |
| `/optimize` | Code/performance optimization |
| `/clean` | Cleanup caches and temp files |
| `/todo` | Project todo manager with due dates |
| `/husky` | Manage git hooks via Husky |
| `/create-hook` | Scaffold new hook in `~/.claude/hooks/` |
| `/initref` | Initialize reference config |

#### GSD Subcommands (34)

All prefixed with `/gsd-` or `/gsd:`:

**Project**: `new-project`, `new-milestone`, `add-phase`, `remove-phase`, `insert-phase`
**Planning**: `plan-phase`, `research-phase`, `discuss-phase`, `plan-milestone-gaps`, `list-phase-assumptions`
**Execution**: `execute-phase`, `complete-milestone`, `audit-milestone`, `quick`
**Work**: `add-todo`, `check-todos`, `verify-work`, `pause-work`, `resume-work`, `reapply-patches`
**Misc**: `progress`, `help`, `debug`, `map-codebase`, `settings`, `set-profile`, `join-discord`, `update`, `add-tests`, `validate-phase`, `health`, `cleanup`

### Teams — 9 saved team configs

Reusable multi-agent team configurations for different project types.

| Team | Purpose |
|:-----|:--------|
| `kaufdahoam-finalize` | 8-agent audit & finalization swarm |
| `kriyaverse-migration` | Parallel research + planning + execution |
| `kriyaverse-ui-overhaul` | 4-agent UI component swarm |
| `testflight-fix-sprint` | 5-agent bug fix sprint |
| `obsidian-to-affine` | 6-worker migration pipeline |
| `logo-fix` | 3-agent asset pipeline |
| `theme-fix` | 3-agent theming swarm |
| `arc-polish` | UI polish swarm |
| `iptv-production` | IPTV app production pipeline |

### Config Files

| File | Purpose |
|:-----|:--------|
| `CLAUDE.md` | Global instructions — GSD mode, auto-skills, vault integration, deployment rules |
| `settings.json.example` | Hooks, permissions, statusline, teams config |
| `mcp.json.example` | MCP server configuration (Apple Mail) |
| `.mcp.json.example` | Extended MCP config (Firebase, PostHog, Apple Mail) |
| `gsd-file-manifest.json` | GSD framework file registry |

---

## The Auto-Resume System

Sessions never die. When context hits 25%, the system automatically saves state, commits work, and spawns a fresh session that picks up exactly where the last one left off.

```
gsd-context-monitor.js  →  handoff.json  →  auto-resume-loop.js  →  infinite-agent.sh --resume
        (CRITICAL)           (state dump)        (Stop hook)              (fresh session)
```

**Three-part cycle:**
1. **Monitor** — `gsd-context-monitor.js` warns at 35%, triggers handoff at 25%
2. **Save** — Claude writes `handoff.json` (task, progress, files, blockers, git state) + vault note + commits code
3. **Resume** — `auto-resume-loop.js` spawns `infinite-agent.sh --resume` with full context restored

Stop the loop: `touch /tmp/infinite-agent-stop`

---

## The Knowledge Behind It

Everything in this repo traces back to the EliteX Knowledge Base — 148 structured research notes distilled into 32 named frameworks.

```mermaid
graph TD
    subgraph "EliteX KB — Strategic Frameworks"
        N1["Specification Bottleneck"]
        N2["5 Levels of AI Coding"]
        N3["Ralph Pattern"]
        N4["Scenarios vs Tests"]
        N5["Multi-Agent Failure Patterns"]
        N6["Phronesis — Practical Wisdom"]
        N7["Builder Operating System 2026"]
    end

    subgraph "EliteX KB — Tactical Frameworks"
        B1["Three-Stage Pricing"]
        B2["Agent Responsibility Minimization"]
        B3["Prompt Engineering Frameworks"]
        B4["Productized AI System Model"]
        B5["Agency Scaling Roadmap"]
    end

    N1 --> SK["spec-driven-development skill"]
    N2 --> SK
    N4 --> SC["scenario-suite.sh script"]
    N3 --> RL["ralph-loop.sh script"]
    N5 --> AG["agent-architecture skill"]
    N6 --> AG
    B2 --> AG
    B3 --> PT["prompt-templates skill"]
    B4 --> TR["productization-tracker.js hook"]
    N1 --> SG["spec-gate.js hook"]

    style SK fill:#1a1a2e,stroke:#0f3460,color:#fff
    style AG fill:#1a1a2e,stroke:#0f3460,color:#fff
    style PT fill:#1a1a2e,stroke:#0f3460,color:#fff
    style SC fill:#16213e,stroke:#555,color:#ccc
    style RL fill:#16213e,stroke:#555,color:#ccc
    style SG fill:#2d2d2d,stroke:#555,color:#aaa
    style TR fill:#2d2d2d,stroke:#555,color:#aaa
```

---

## Install

One line. Any machine.

```bash
curl -sSL https://raw.githubusercontent.com/Elit3-X/elitex-skill-library/main/install.sh | bash
```

Or do it by hand:

```bash
git clone https://github.com/Elit3-X/elitex-skill-library.git
cd elitex-skill-library

# Core
cp -R skills/* ~/.claude/skills/
cp -R commands/* ~/.claude/commands/
cp hooks/* ~/.claude/hooks/
cp scripts/* ~/.claude/scripts/ && chmod +x ~/.claude/scripts/*.sh

# Agents & GSD
cp -R agents/* ~/.claude/agents/
cp -R get-shit-done ~/.claude/get-shit-done/

# Teams (optional — review before overwriting)
cp -R teams ~/.claude/teams/

# Config (review before overwriting your own)
cp CLAUDE.md ~/.claude/CLAUDE.md
cp settings.json.example ~/.claude/settings.json
cp mcp.json.example ~/.claude/mcp.json
```

Restart Claude Code. Done.

---

## Sync Back

Made changes locally? Push them back so every workstation stays in sync.

```bash
cd /path/to/elitex-skill-library

cp -R ~/.claude/skills/* skills/
cp -R ~/.claude/commands/* commands/
cp ~/.claude/hooks/*.js hooks/
cp ~/.claude/scripts/*.sh scripts/
cp -R ~/.claude/agents/* agents/
cp -R ~/.claude/get-shit-done/* get-shit-done/
cp ~/.claude/CLAUDE.md CLAUDE.md
cp ~/.claude/settings.json settings.json.example

git add -A && git commit -m "sync from $(hostname)" && git push
```

---

## The Balance

The yin-yang isn't decoration. It's the operating philosophy:

| | Strategy (Yin) | Execution (Yang) |
|:--|:---------------|:-----------------|
| **Source** | EliteX KB — frameworks, theory, market intelligence | EliteX KB — builds, templates, step-by-step systems |
| **Artifact** | SPEC.md, SCENARIOS.md | Code, commits, shipped product |
| **Mode** | Colleague-shaped AI (explore, clarify, question) | Tool-shaped AI (execute, iterate, ship) |
| **Skill** | spec-driven-development | ralph-loop, prompt-templates |
| **Metric** | Spec quality, scenario coverage | Tests passing, iteration speed |

Neither side works without the other. Spec without execution is a document. Execution without spec is waste at speed.

---

<p align="center">
  <sub>EliteX GbR — Aichach, Germany</sub><br/>
  <sub>Built by Vaisakhan Sanu & Chris Zanfir</sub>
</p>
