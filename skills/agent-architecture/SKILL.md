# Agent Architecture

> Source: Knowledge Base frameworks — agent-responsibility-minimization, multi-agent-failure-patterns, phronesis-practical-wisdom

## When to Use

Trigger this skill when:
- Designing any AI agent, automation, or agentic workflow
- Building with n8n, Make.com, Relevance AI, or any agent platform
- User mentions "agent", "automation", "workflow", "multi-agent"
- Architecting client AI systems for EliteX or Baukasten IT

## Core Rule

**Agent = Decision-making + Communication ONLY**

| Work Type | Handled By | Example |
|-----------|-----------|---------|
| Generative work | Tools | Email generation, content creation, data formatting |
| Specialized reasoning | Sub-agents | Calendar management, prospect research, outreach |
| Decision-making | Agent | When to act, which tool/sub-agent to invoke, routing |
| Communication | Agent | Delegating to sub-agents, reporting results |

An agent that does generation is an overloaded agent. Offload it.

## Default: Single Agent

Google Research proved that adding agents makes systems worse, not better:
- Coordination overhead grows super-linearly
- Communication noise degrades signal across handoffs
- Optimal team size is smaller than intuition suggests
- A single well-configured agent frequently outperforms multi-agent swarms

**Only add agents when tasks are truly independent with no shared state.** The moment agents need to coordinate, the system degrades.

Always measure multi-agent performance against a single-agent baseline.

## Sub-Agent Communication Template

For each tool or sub-agent in a system, define exactly three things:

```
### [Tool/Sub-Agent Name]
**What it does:** [One sentence]
**When to use it:** [Trigger condition]
**How to communicate:** [Example message with variables]

Example:
  Input: "Research prospect {{company_name}} and return company size, industry, and recent news"
  Output: JSON with company_size, industry, recent_news fields
```

## Phronesis: Principles Over Rules

Write principles-based guidance for agents, not rigid rule sets:
- A phronesis-oriented agent understands WHY rules exist
- It weighs context against principles and makes judgment calls
- Rigid rules break on edge cases; principles adapt

**Bad:** "Never send emails after 5pm"
**Good:** "Respect the recipient's working hours. Consider timezone and urgency."

## Architecture Patterns

### Pattern 1: Micro-Agent Per Integration
Build one agent per software integration (email agent, calendar agent, CRM agent). Reusable across projects.

### Pattern 2: Deterministic Shell, Agentic Core
Keep deterministic steps as deterministic logic (templates, fixed rules, conditional branches). Use agents ONLY for parts requiring dynamic reasoning.

### Pattern 3: Human-in-the-Loop Checkpoints
AI generates → human reviews/edits → AI continues. Captures user decisions as feedback for self-improvement.

## Discovery Method: Dream Day Interview

When scoping agent work for clients, ask:
> "Describe when you do your job perfectly vs. an average day."

The gap reveals 2-3 automatable workflows — the best starting point for any agentic build.

## Anti-Patterns
- **Monolithic agent:** One agent doing everything (generation + decisions + communication)
- **Agent sprawl:** Adding agents without proving independent tasks exist
- **Rigid SOPs:** Step-by-step procedures that break on edge cases
- **No baseline:** Building multi-agent without testing single-agent first
- **Coordination theater:** Agents passing messages back and forth with no value added
