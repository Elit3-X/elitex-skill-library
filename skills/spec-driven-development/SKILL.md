# Spec-Driven Development

> Source: Knowledge Base frameworks — specification-bottleneck, colleague-vs-tool-shaped-ai, five-levels-of-ai-coding, four-principles-ai-era-building

## When to Use

Trigger this skill when:
- Starting any new feature, module, or system
- User says "build", "implement", "create", "add feature", "new project"
- Beginning work that involves more than a single-file edit
- Before running a ralph-loop or any autonomous coding session

## Core Principle

The bottleneck has moved from code to specification. Building the wrong thing at unprecedented speed compounds faster than saving on production. A good spec is now the highest-ROI artifact in any project.

## Two Modes of Work

### Mode 1: Colleague-Shaped (Clarify Intent)
Use when intent is unclear, exploratory, or ambiguous.
- Ask questions to surface hidden assumptions
- Challenge scope ("what's NOT in scope?")
- Identify success criteria that are testable
- Output: a SPEC.md

### Mode 2: Tool-Shaped (Execute Against Spec)
Use when spec exists and correctness is defined upfront.
- Read spec, execute, verify against success criteria
- Human-in-the-middle is overhead to minimize
- Scale by parallelizing agents if needed

**The transition:** Always start Colleague-Shaped to produce spec. Then switch to Tool-Shaped for execution. Never skip Mode 1.

## Workflow

### Step 1: Check for Spec
Look for `SPEC.md`, `spec.md`, or equivalent in project root.

### Step 2: If No Spec Exists — Write One
Produce a SPEC.md with this structure:

```markdown
# Spec: [Feature/Project Name]

## Problem Statement
What pain point or need does this solve? One paragraph.

## Success Criteria
Measurable, testable conditions that prove the work is done.
- [ ] Criterion 1 (specific and verifiable)
- [ ] Criterion 2
- [ ] Criterion 3

## Behavioral Scenarios (External Holdout)
These scenarios live OUTSIDE the codebase. The agent never sees them during development.
| Scenario | Input | Expected Output | Priority |
|----------|-------|-----------------|----------|
| Happy path | ... | ... | Must |
| Edge case | ... | ... | Must |
| Error state | ... | ... | Should |

## Architecture
How the system works at a structural level. Components, data flow, integrations.

## Constraints
Technical limitations, budget, timeline, compatibility requirements.

## Out of Scope
Explicitly list what this does NOT include. Prevents scope creep.

## Open Questions
Unknowns that need resolution before or during implementation.
```

### Step 3: If Spec Exists — Execute
1. Read the spec fully
2. Verify success criteria are testable
3. Implement against criteria, one at a time
4. After each criterion is met, check it off
5. Optimize for iteration speed, not first-pass quality (Principle 4)

### Step 4: Evaluate, Don't Review
Instead of reading every line of AI-generated code:
- Run the behavioral scenarios
- Check success criteria
- Verify integration points
- Only read code if scenarios fail

## Level Check

Reference the 5 Levels of AI Coding:
- **Level 2 (Junior Dev):** You read all code Claude writes. Fine for learning, slow for shipping.
- **Level 3 (Manager):** You review at PR level, not line-by-line. Requires good spec + tests.
- **Level 4 (PM):** You write spec, leave, come back, check tests. Code is a black box.
- **Level 5 (Dark Factory):** Spec in, software out. No human review.

Target: Level 4 minimum for all EliteX work. This skill pushes toward Level 3-4 behavior.

## Integration
- For ralph-loop: write SPEC.md first, ralph executes against it
- For git repos: create `specs/` directory, reference spec in PR descriptions
- For client work: spec IS the deliverable from Discovery phase

## Anti-Patterns
- Writing code without a spec ("I'll figure it out as I go")
- Vague success criteria ("it should work well")
- Skipping Out of Scope (guarantees scope creep)
- Optimizing first-pass quality over iteration speed
- Reviewing every line instead of testing outcomes
