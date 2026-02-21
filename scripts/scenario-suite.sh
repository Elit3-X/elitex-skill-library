#!/usr/bin/env bash
# Scenario Suite — Generate external behavioral scenarios
# Source: KB scenarios-vs-tests framework
#
# Usage: scenario-suite.sh
#
# Creates SCENARIOS.md — behavioral specs the agent never sees during development.
# These are your holdout set: they validate correctness from the outside.
# Tests live inside the codebase (gameable). Scenarios live outside (not gameable).

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check for git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo -e "${RED}Error: Not in a git repository${NC}"
  exit 1
fi

GIT_ROOT=$(git rev-parse --show-toplevel)

# Check if SCENARIOS.md already exists
if [ -f "$GIT_ROOT/SCENARIOS.md" ]; then
  echo -e "${YELLOW}SCENARIOS.md already exists. Overwrite? (y/N)${NC}"
  read -r confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Aborted."
    exit 0
  fi
fi

# Check for SPEC.md
HAS_SPEC="false"
SPEC_CONTEXT=""
if [ -f "$GIT_ROOT/SPEC.md" ]; then
  HAS_SPEC="true"
  SPEC_CONTEXT="## Existing Spec
$(cat "$GIT_ROOT/SPEC.md")"
  echo -e "${GREEN}Found SPEC.md — will use success criteria as scenario seeds.${NC}"
else
  echo -e "${YELLOW}No SPEC.md found — will generate scenarios from codebase analysis.${NC}"
fi

echo -e "${GREEN}Generating external behavioral scenarios...${NC}"
echo ""

PROMPT=$(cat <<PROMPT_END
You are generating an external behavioral scenario suite for this project.

## Critical Concept: Scenarios vs Tests
- TESTS live inside the codebase. AI agents can see them and optimize to pass them (teaching to the test).
- SCENARIOS live outside as behavioral specs. The agent never sees them during development. They are a holdout set that prevents overfitting.

Your job: generate SCENARIOS that describe what the system does from a USER/BUSINESS perspective, not how the code works internally.

$SPEC_CONTEXT

## Instructions

1. Analyze the codebase structure and understand what this system does
2. Generate behavioral scenarios covering:
   - Core happy paths (what works when everything goes right)
   - Error handling (what happens when things fail)
   - Edge cases (boundary conditions, empty states, concurrent access)
   - Integration points (where this system talks to external systems)
   - User journeys (end-to-end flows from user perspective)

3. Output SCENARIOS.md with this structure:

\`\`\`markdown
# Behavioral Scenarios (External Holdout Set)

> These scenarios validate system behavior from the outside.
> They must NOT reference internal code, function names, or implementation details.
> They describe what a user or API consumer would observe.

## Core Flows

### Scenario: [Name]
**Given** [precondition]
**When** [action]
**Then** [expected observable outcome]
**Priority:** Must | Should | Could

## Error Handling

### Scenario: [Name]
**Given** [precondition]
**When** [failure condition]
**Then** [expected error behavior]
**Priority:** Must | Should | Could

## Edge Cases

### Scenario: [Name]
**Given** [boundary condition]
**When** [action at boundary]
**Then** [expected behavior]
**Priority:** Must | Should | Could

## Integration Points

### Scenario: [Name]
**Given** [external system state]
**When** [interaction with external system]
**Then** [expected end-to-end outcome]
**Priority:** Must | Should | Could
\`\`\`

Output ONLY the markdown content. No preamble, no explanation.
PROMPT_END
)

# Run Claude and capture output
if command -v claude &>/dev/null; then
  echo "$PROMPT" | claude --print > "$GIT_ROOT/SCENARIOS.md" 2>/dev/null
else
  echo -e "${RED}Error: claude CLI not found${NC}"
  exit 1
fi

echo ""
echo -e "${GREEN}SCENARIOS.md created at $GIT_ROOT/SCENARIOS.md${NC}"
echo -e "Use as external quality gate for ralph-loop and autonomous builds."
echo -e "${YELLOW}Tip: Do NOT commit this to the repo if you want it invisible to the agent during development.${NC}"
echo ""
echo "--- Preview ---"
head -40 "$GIT_ROOT/SCENARIOS.md"
