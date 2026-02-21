# Prompt Engineering Templates

> Source: Knowledge Base framework — prompt-engineering-frameworks (Ben AI)

## When to Use

Trigger this skill when:
- Writing system prompts for AI agents or automations
- Building prompts for n8n, Make.com, Relevance AI, or any LLM-powered node
- User says "write a prompt", "system prompt", "agent instructions"
- Designing prompt structure for any AI workflow

## Key Principle

Agent prompting is fundamentally different from conversational prompting. You must get it right in a single prompt without back-and-forth, and it must work consistently at scale across edge cases.

## Framework Selection Matrix

| Use Case | Framework | Model Tier | Notes |
|----------|-----------|------------|-------|
| Data extraction / summarization | Short | Cheap (GPT-4o-mini) | LLMs naturally good at this |
| Classification / categorization | Short or Long | Cheap | Long if subjective classification |
| Content generation | Long | Best (GPT-4o/Claude) | Hardest, most hallucination-prone |
| Evaluation / scoring | Long | Best | Subjective, needs context |
| Data transformation | Short or Long | Best | Always include I/O examples |
| Decision-making (agents) | Agent | Best | Always use best models for reasoning |

---

## Template 1: Short Structured (Simple Tasks)

Use for: extraction, classification, simple transformations.

```
## Objective
[One sentence: what to do]

## Instructions
- [Rule 1]
- [Rule 2]
- Only output [X]. No summary, no explanation, nothing but [X].
- If you don't find [X], only output "not found". Nothing else.

## Examples
Input: [example input]
Output: [example output]

## Input
{{variable}}
```

**Rules:**
- Always define a fallback ("If not found, output 'not found'")
- "Only output X" prevents unwanted commentary
- Start here. Escalate to Long only if model struggles.

---

## Template 2: Long Structured (Complex Tasks)

Use for: content generation, evaluation, complex reasoning.

```
## Role
You are a world-class [role] with particular expertise in [specific task].

## Objective
[Direct task description]
Think step by step about [specific reasoning chain].

## Context
[Why this task matters. Bigger picture. What happens if it goes wrong.]

## Instructions
1. [Step 1]
2. [Step 2]
3. [Step 3]

### Output Format
[Exact format specification]

### Rules
- IMPORTANT: [Critical rule in caps]
- [Rule 2]
- [Rule 3]

## Examples
### Example 1
Input: [example input]
Output: [example output]

### Example 2 (Edge Case)
Input: [tricky input]
Output: [correct handling]

## Input
{{variable_1}}
{{variable_2}}

## Notes
[Double-down on the most critical rules here. LLMs weight the end of the prompt heavily — this is the fastest fix location when output quality drops.]
```

**Key sections:**
- **Role:** Assign expertise + qualities. "World-class" triggers better output.
- **Context:** Why it matters. Can include emotional weight ("It is vital to my career...")
- **Notes:** End-of-prompt correction. LLMs attend to beginning + end most heavily. Put your most critical constraints here.

---

## Template 3: Agent Prompt (Decision-Making Agents)

Use for: agents that route, decide, delegate. Extends Long Structured with two additional sections.

```
## Role
You are [role] responsible for [scope]. You manage a team of specialized tools and sub-agents.

## Objective
[What this agent decides and coordinates]
Think step by step about which action to take.

## Context
[System overview. What other agents/tools exist. Where this agent fits.]

## Instructions
[General behavioral rules]

## SOP (Standard Operating Procedure)
1. Analyze the incoming request
2. Determine which action path applies:
   2.1 If [condition A] → use [Tool/Agent X]
   2.2 If [condition B] → use [Tool/Agent Y]
   2.3 If [condition C] → escalate to human
3. Execute the selected path
4. Verify the output meets quality criteria
5. Return result in specified format

## Tools & Sub-Agents

### [Tool Name 1]
**What it does:** [One sentence]
**When to use it:** [Trigger condition]
**How to communicate:**
Example input: "[sample request with {{variables}}]"
Example output: "[expected response format]"

### [Sub-Agent Name 1]
**What it does:** [One sentence]
**When to use it:** [Trigger condition]
**How to communicate:**
Example input: "[sample delegation with {{variables}}]"
Example output: "[expected response format]"

## Examples

### Example 1: Standard Flow
Request: "[sample request]"
SOP Execution: Step 1 → analyzed as [type] → Step 2.1 → Tool X invoked → Step 4 → verified → output returned

### Example 2: Edge Case
Request: "[tricky request]"
SOP Execution: Step 1 → ambiguous → Step 2.3 → escalated to human with context: "[explanation]"

## Input
{{incoming_request}}

## Notes
- Edge-case examples provide the LARGEST reliability gains in agent prompts
- If uncertain between two paths, [preferred default behavior]
- NEVER [critical prohibition]
```

---

## Techniques Reference

| Technique | What It Does | When to Apply |
|-----------|-------------|---------------|
| "Only output X" | Prevents unwanted commentary | Every extraction prompt |
| Fallback definition | "If not found, output 'not found'" | Prevents hallucination |
| Notes section | End-of-prompt rule reinforcement | Every Long/Agent prompt |
| Edge-case examples | Largest reliability gain | Every Agent prompt |
| Chain prompting | Break complex task into single-task steps | When one prompt can't handle it |
| CAPS for emphasis | Highlights critical rules | Sparingly, for true deal-breakers |
