#!/usr/bin/env bash
# Ralph Loop - Autonomous Claude Code execution loop
# Based on Jeffrey Huntley's pattern (from Knowledge Base)
# Usage: ralph-loop.sh [spec-file] [max-iterations]
#
# Runs Claude Code against a spec file in a loop:
# 1. Claude reads spec + git log for context
# 2. Claude implements/iterates
# 3. Claude commits progress
# 4. Loop checks if tests pass
# 5. If pass → done. If fail → fresh context, loop again.

set -euo pipefail

SPEC_FILE="${1:-SPEC.md}"
MAX_ITERATIONS="${2:-10}"
LOG_FILE=".ralph-loop.log"
ITERATION=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${YELLOW}[ralph:${ITERATION}]${NC} $1" | tee -a "$LOG_FILE"
}

check_prereqs() {
    if ! command -v claude &>/dev/null; then
        echo -e "${RED}Error: claude CLI not found${NC}"
        exit 1
    fi
    if [ ! -f "$SPEC_FILE" ]; then
        echo -e "${RED}Error: Spec file '$SPEC_FILE' not found${NC}"
        echo "Usage: ralph-loop.sh [spec-file] [max-iterations]"
        exit 1
    fi
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo -e "${RED}Error: Not in a git repository${NC}"
        exit 1
    fi
}

run_tests() {
    # Try common test runners in order
    if [ -f "package.json" ] && grep -q '"test"' package.json; then
        npm test 2>&1
    elif [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] || [ -d "tests" ]; then
        python -m pytest 2>&1
    elif [ -f "Makefile" ] && grep -q "^test:" Makefile; then
        make test 2>&1
    elif [ -f "go.mod" ]; then
        go test ./... 2>&1
    else
        # No test runner found — check if spec has success criteria
        log "No test runner detected. Checking spec success criteria manually."
        return 0
    fi
}

build_prompt() {
    local iteration=$1
    local git_context=""
    
    # Get recent git history for context
    if [ "$iteration" -gt 0 ]; then
        git_context=$(git log --oneline -10 2>/dev/null || echo "No git history")
        git_context="

## Previous Progress (Git Log)
\`\`\`
${git_context}
\`\`\`

## Current Diff (unstaged)
\`\`\`
$(git diff --stat 2>/dev/null || echo "No changes")
\`\`\`
"
    fi

    cat <<EOF
You are in a Ralph Loop — an autonomous development cycle.

## Spec
$(cat "$SPEC_FILE")
${git_context}

## Instructions
1. Read the spec and any previous progress from git log
2. Implement the next piece of work toward completing the spec
3. Run tests to verify your changes
4. Commit your progress with a descriptive message: "ralph[${iteration}]: <what you did>"
5. If all success criteria from the spec are met, create a file called .ralph-done with "COMPLETE" as content
6. If not complete, make as much progress as possible in this iteration

## Rules
- Focus on ONE success criterion at a time
- Commit after each meaningful unit of progress
- If tests fail, fix them before moving on
- Do not ask for input — make decisions and proceed
- If stuck, document what's blocking in a git commit message
EOF
}

main() {
    check_prereqs
    
    echo -e "${GREEN}=== Ralph Loop ===${NC}"
    echo -e "Spec: ${SPEC_FILE}"
    echo -e "Max iterations: ${MAX_ITERATIONS}"
    echo -e "Starting at: $(date)"
    echo ""
    
    > "$LOG_FILE"  # Clear log
    
    while [ "$ITERATION" -lt "$MAX_ITERATIONS" ]; do
        ITERATION=$((ITERATION + 1))
        log "Starting iteration ${ITERATION}/${MAX_ITERATIONS}"
        
        # Build prompt and run Claude
        PROMPT=$(build_prompt "$ITERATION")
        
        log "Running Claude Code..."
        echo "$PROMPT" | claude --print --dangerously-skip-permissions 2>&1 | tee -a "$LOG_FILE"
        
        # Check if Ralph marked itself as done
        if [ -f ".ralph-done" ]; then
            log "${GREEN}Ralph Loop COMPLETE after ${ITERATION} iterations${NC}"
            rm -f .ralph-done
            break
        fi
        
        # Check if tests pass
        log "Running tests..."
        if run_tests >> "$LOG_FILE" 2>&1; then
            log "${GREEN}Tests passing${NC}"
        else
            log "${RED}Tests failing — will retry in next iteration${NC}"
        fi
        
        # Brief pause between iterations
        sleep 2
    done
    
    if [ "$ITERATION" -ge "$MAX_ITERATIONS" ]; then
        log "${RED}Max iterations reached. Review progress in git log.${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}=== Ralph Loop Summary ===${NC}"
    echo "Iterations: ${ITERATION}"
    echo "Git log:"
    git log --oneline -"$ITERATION" 2>/dev/null || echo "No commits"
    echo ""
    echo "Full log: ${LOG_FILE}"
}

main "$@"
