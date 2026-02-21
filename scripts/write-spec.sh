#!/usr/bin/env bash
# Write Spec — Colleague-shaped Claude session that produces SPEC.md
# Source: KB specification-bottleneck + colleague-vs-tool-shaped-ai
#
# Usage: write-spec.sh "build a customer support chatbot for Komotel"
# Or:    echo "task description" | write-spec.sh
#
# Runs Claude in print mode to produce a SPEC.md in the current directory.
# Use before ralph-loop.sh to bridge the gap between idea and execution.

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get task description from argument or stdin
if [ -n "${1:-}" ]; then
  TASK="$1"
elif [ ! -t 0 ]; then
  TASK=$(cat)
else
  echo -e "${RED}Error: No task description provided${NC}"
  echo "Usage: write-spec.sh \"task description\""
  echo "Or:    echo \"task description\" | write-spec.sh"
  exit 1
fi

# Check for git repo (optional but recommended)
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo -e "${YELLOW}Warning: Not in a git repository. SPEC.md will be created in current directory.${NC}"
fi

# Check if SPEC.md already exists
if [ -f "SPEC.md" ]; then
  echo -e "${YELLOW}SPEC.md already exists. Overwrite? (y/N)${NC}"
  read -r confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Aborted."
    exit 0
  fi
fi

echo -e "${GREEN}Generating spec for:${NC} $TASK"
echo ""

PROMPT=$(cat <<'PROMPT_END'
You are in Colleague-shaped mode. Your job is to produce a rigorous specification.

## Task
TASK_PLACEHOLDER

## Instructions

Think through this task deeply. Consider:
- What problem does this actually solve?
- What are the hidden assumptions?
- What could go wrong?
- What is explicitly NOT in scope?
- What are the testable success criteria?

Then output a complete SPEC.md with this exact structure:

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
| Scenario | Given | When | Then | Priority |
|----------|-------|------|------|----------|
| Happy path | ... | ... | ... | Must |
| Edge case | ... | ... | ... | Must |
| Error state | ... | ... | ... | Should |

## Architecture
Components, data flow, integrations. How the system works structurally.

## Tool Stack
| Tool | Role | Notes |
|------|------|-------|
| ... | ... | ... |

## Constraints
Technical limitations, budget, timeline, compatibility.

## Out of Scope
Explicitly what this does NOT include.

## Open Questions
Unknowns that need resolution before or during implementation.
```

Output ONLY the markdown content. No preamble, no explanation, no wrapping.
PROMPT_END
)

# Replace placeholder with actual task
PROMPT="${PROMPT/TASK_PLACEHOLDER/$TASK}"

# Run Claude and capture output
if command -v claude &>/dev/null; then
  echo "$PROMPT" | claude --print > SPEC.md 2>/dev/null
else
  echo -e "${RED}Error: claude CLI not found${NC}"
  exit 1
fi

echo ""
echo -e "${GREEN}SPEC.md created.${NC}"
echo -e "Review and edit the spec, then run: ${YELLOW}ralph-loop.sh SPEC.md${NC}"
echo ""
echo "--- Preview ---"
head -30 SPEC.md
