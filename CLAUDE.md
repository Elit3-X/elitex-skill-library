# Global Claude Code Rules

## Tech Stack

This project stack: TypeScript + HTML (primary), Next.js/Vercel hosting, Supabase backend. Always use TypeScript for new code. Primary languages by usage: HTML templates, TypeScript logic, JSON config.

## Important Constraints

When working with screenshots or images from the user, NEVER attempt to process images that may exceed API size limits. Instead, ask the user to resize the image to under 5MB or describe the issue in text. If image processing fails once, do NOT retry — immediately switch to asking for a text description.

## GSD (Get Shit Done) Mode - ALWAYS ACTIVE

Every conversation operates in GSD mode by default. This means:

### Core Principles
- **Execute immediately** - No filler, no "Let me...", no sycophancy
- **Imperative voice** - Direct instructions, technical precision
- **Atomic commits** - One commit per task, meaningful messages
- **Context engineering** - Manage context window deliberately, use subagents
- **Plans as prompts** - Executable specifications, not documents

### Auto-Skill Invocation
**CRITICAL: Invoke relevant skills automatically without announcing them.**

When working on tasks, silently apply the appropriate skill's methodology:
- **Flutter/Dart work** → Apply arctv, flutter patterns
- **Database work** → Apply postgres-patterns, database design
- **API work** → Apply backend-patterns, security-review
- **React/Next.js** → Apply react-best-practices, frontend-patterns
- **Testing** → Apply tdd-workflow, test-driven-development
- **Code review** → Apply code-review, security-review
- **Planning** → Apply planning-with-files, executing-plans
- **Go work** → Apply golang-patterns, golang-testing, go-review
- **Python work** → Apply python-patterns, python-testing, python-review

**Never say "I'm using the X skill"** - just apply the methodology.

### Workflow Standards
1. **Todo tracking** - Use TodoWrite for multi-step tasks
2. **Parallel execution** - Run independent tasks simultaneously
3. **Verify completion** - Always verify work before marking done
4. **Update memory** - Keep MEMORY.md current with learnings

### Banned Patterns
- Sycophancy ("Great!", "Awesome!", "I'd love to help")
- Filler ("Let me", "Just", "Simply", "Basically")
- Enterprise patterns (story points, sprint ceremonies)
- Temporal language ("We changed", "Previously")
- Time estimates ("This will take...")
- Asking permission for obvious fixes

### Communication Style
- Brief, technical, direct
- Code references with line numbers: `file.ts:42`
- Tables for structured data
- No emojis unless explicitly requested

## Skill Auto-Application Matrix

| Context Detected | Skills Applied Silently |
|-----------------|------------------------|
| `.dart`, `.flutter` | arctv, flutter best practices |
| `.go` | golang-patterns, go-review |
| `.py` | python-patterns, python-review |
| `.ts`, `.tsx` | frontend-patterns, react-best-practices |
| `supabase`, `postgres` | postgres-patterns, database-reviewer |
| `test`, `spec` | tdd-workflow, test-coverage |
| Security-sensitive code | security-review |
| Planning requests | planning-with-files, executing-plans |
| Code modifications | code-review (post-edit) |

## Knowledge Vault (Obsidian)

- Location: `~/Documents/Obsidian Vault/`
- Agent writes ALWAYS go to `Inbox/` with `status: inbox`
- Use `/obsidian` to activate vault documentation mode (all research auto-written to vault)
- Use `/noobsidian` to deactivate vault documentation mode
- Use `/research-to-vault <slug> <title>` to stage individual research findings
- Use `context7` MCP tools when looking up framework/service documentation

### Vault Structure

```
Inbox/              # Agent writes land here
Projects/           # Organized by project (Baukasten-IT, EliteX, PFD, Sovereign-AI-OS)
Canvas/             # Mind maps and visual boards
_templates/         # Templater templates
```

### Frontmatter Schema

```yaml
project: ""         # baukasten-it | elitex | pfd | sovereign-ai-os | etc.
tags: []            # Free-form
status: inbox       # inbox | active | archived
confidence: medium  # high | medium | low
source: Claude
created: YYYY-MM-DD
```

## Secrets Management (Bitwarden)

- Use `bitwarden` MCP tools to fetch credentials, API keys, and passwords from the vault.
- NEVER hardcode secrets in files. Always fetch from Bitwarden at runtime.
- NEVER echo full vault items unless explicitly requested — return only the specific field needed.
- Use `/get-secret <name>` command for quick credential lookups.
- Use `/gen-password` command to generate secure passwords via Bitwarden.
- If `BW_SESSION` is not set or expired, instruct the user to run: `eval "$(bw-session)"`

## Database & Supabase

For Supabase projects: Always check for REMOTE Supabase instances first (check .env files for SUPABASE_URL). Never assume local Supabase is the only source of truth. When database operations fail via API/CLI, immediately suggest the user run SQL directly in Supabase SQL Editor rather than iterating through multiple connection approaches.

## Deployment

For Vercel deployments: Before deploying, always verify: 1) All code is committed and pushed to GitHub, 2) All required environment variables are set in Vercel project settings (check with `vercel env ls`), 3) Git author/team permissions are configured. If deployment fails due to permissions, immediately ask the user to resolve via Vercel dashboard rather than retrying programmatically.

## UI & Frontend

When fixing UI/CSS bugs, always verify the fix works on BOTH desktop and mobile viewports. Do not use responsive hiding classes (like lg:hidden) without confirming the element should actually be hidden at that breakpoint. If user reports a visual issue persists after a fix, re-examine the actual root cause rather than applying incremental patches.

## Session Initialization

On every new conversation:
1. Check for existing MEMORY.md and load context
2. Identify project type and applicable skills
3. Enter GSD mode (direct execution, no preamble)
4. Track progress with TodoWrite for complex tasks

## Knowledge Base Integration

The Knowledge Base at `~/Documents/Obsidian Vault/Projects/Knowledge-Base/` contains 148 structured notes from 169 YouTube transcripts (Nate B Jones + Ben AI). Use it as the foundation for:

- **Brainstorming:** `/brainstorm <topic>` — structured ideation using KB frameworks
- **Blog generation:** `/blog-from-kb <topic>` — articles grounded in KB research
- **Project scoping:** `/scope-project <description>` — priced proposals using agency frameworks
- **Knowledge queries:** `/kb <query>` — search and synthesize KB content

### Key Frameworks (Auto-Apply)

| Context | Framework to Apply |
|---------|-------------------|
| Starting any feature | [[spec-driven-development]] skill — write spec before code |
| Client project scoping | [[three-stage-ai-pricing]] + [[productized-ai-system]] |
| Building automations | [[n8n-workflow-generator]] skill — standard patterns |
| Multi-agent design | [[agent-responsibility-minimization]] — keep agents small |
| Evaluating AI output | [[scenarios-vs-tests]] — external holdout sets |
| Pricing client work | [[ai-agency-operations]] skill — three-stage pricing |

### Autonomous Coding (Ralph Pattern)

For long-running autonomous tasks, use the Ralph Loop:
```bash
~/.claude/scripts/ralph-loop.sh SPEC.md 10
```
Loop runs Claude Code against a spec file, commits progress, checks tests, and iterates until success criteria are met.

### Knowledge Base Categories

**Strategic (Nate B Jones):** AI-Engineering, Agentic-Systems, Business-Strategy, Career-Intelligence, Hiring-Workforce, Market-Intelligence, Tool-Analysis

**Practical (Ben AI):** AI-Agency-Business, AI-Agent-Building, AI-Automation-Platforms, AI-Marketing-Ads, AI-SaaS-Building, AI-Sales-Outreach, Claude-Code-MCP

### Venture Mapping
Always cross-reference work against the active ventures:
- Baukasten IT → AI training for German SMBs, productized systems
- EliteX Agency → Level 4-5 development, agency scaling
- KaufDahoam → Marketplace, SEO automation
- Komotel → Hotel tech, customer support AI
- Veliano → Jewelry e-commerce, product AI
- Chenda → Early stage SaaS
