#!/usr/bin/env bash
# Debug Loop - Autonomous bug-fix cycle for Claude Code
# Usage: debug-loop.sh [bug-file|description] [max-iterations] [project-dir]
#
# Reads bug context (file, inline description, or git diff),
# then loops: diagnose → fix → verify build → commit.
# Stops when build passes and no regressions found.

set -euo pipefail

BUG_INPUT="${1:-}"
MAX_ITERATIONS="${2:-5}"
PROJECT_DIR="${3:-.}"
LOG_FILE=".debug-loop.log"
ITERATION=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo -e "${YELLOW}[debug:${ITERATION}]${NC} $1" | tee -a "$LOG_FILE"
}

check_prereqs() {
    if ! command -v claude &>/dev/null; then
        echo -e "${RED}Error: claude CLI not found${NC}"
        exit 1
    fi
    if [ -z "$BUG_INPUT" ]; then
        echo -e "${RED}Error: No bug context provided${NC}"
        echo ""
        echo "Usage: debug-loop.sh [bug-file|\"description\"] [max-iterations] [project-dir]"
        echo ""
        echo "Examples:"
        echo "  debug-loop.sh bugs.md 5"
        echo "  debug-loop.sh \"Map crashes on load in HofDetailScreen\" 3"
        echo "  debug-loop.sh BUGS.md 10 ~/projects/kriyaverse"
        exit 1
    fi
    cd "$PROJECT_DIR"
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo -e "${RED}Error: Not in a git repository${NC}"
        exit 1
    fi
}

detect_build_cmd() {
    if [ -f "package.json" ]; then
        if grep -q '"typecheck"' package.json 2>/dev/null; then
            echo "npm run typecheck"
        elif grep -q '"build"' package.json 2>/dev/null; then
            echo "npx tsc --noEmit"
        else
            echo "npx tsc --noEmit"
        fi
    elif [ -f "go.mod" ]; then
        echo "go build ./..."
    elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
        echo "python -m py_compile"
    else
        echo ""
    fi
}

detect_test_cmd() {
    if [ -f "package.json" ] && grep -q '"test"' package.json 2>/dev/null; then
        echo "npm test -- --watchAll=false 2>&1 | tail -30"
    elif [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] || [ -d "tests" ]; then
        echo "python -m pytest --tb=short -q 2>&1 | tail -30"
    elif [ -f "go.mod" ]; then
        echo "go test ./... 2>&1 | tail -30"
    else
        echo ""
    fi
}

get_bug_context() {
    if [ -f "$BUG_INPUT" ]; then
        cat "$BUG_INPUT"
    else
        echo "$BUG_INPUT"
    fi
}

build_prompt() {
    local iteration=$1
    local build_cmd
    local test_cmd
    local bug_context
    local prev_context=""

    build_cmd=$(detect_build_cmd)
    test_cmd=$(detect_test_cmd)
    bug_context=$(get_bug_context)

    if [ "$iteration" -gt 1 ]; then
        prev_context="
## Previous Attempts (Git Log)
\`\`\`
$(git log --oneline -$((iteration - 1)) 2>/dev/null || echo "No prior commits")
\`\`\`

## Current Diff
\`\`\`
$(git diff --stat 2>/dev/null || echo "Clean")
\`\`\`

## Last Build Output
\`\`\`
$(eval "$build_cmd" 2>&1 | tail -40 || echo "Build command not found")
\`\`\`
"
    fi

    cat <<EOF
You are in a Debug Loop — an autonomous bug-fix cycle.

## Bug Context
${bug_context}

## Project
Directory: $(pwd)
Build command: ${build_cmd:-"none detected"}
Test command: ${test_cmd:-"none detected"}
${prev_context}

## Process
1. READ the bug context and understand the issue
2. DIAGNOSE — find the root cause by reading relevant files, grepping for patterns, checking git blame
3. FIX — make the minimal targeted fix. Do not refactor surrounding code
4. VERIFY — run the build command: \`${build_cmd}\`
5. If tests exist, run: \`${test_cmd}\`
6. COMMIT with message: "debug[${iteration}]: <what you fixed>"

## Rules
- Fix ONE bug per iteration. Start with the highest priority
- Minimal changes only — do not refactor, add comments, or improve unrelated code
- If the build passes with zero errors, create a file called .debug-done with the text "FIXED"
- If you fix a bug but others remain, commit your fix and continue to the next bug
- If you're stuck after 3 attempts at the same bug, commit a .debug-blocked file describing the blocker
- Do not ask for input — diagnose and fix autonomously
- Always verify the build passes before committing
EOF
}

main() {
    check_prereqs

    echo -e "${CYAN}=== Debug Loop ===${NC}"
    echo -e "Bug input: ${BUG_INPUT}"
    echo -e "Project: $(cd "$PROJECT_DIR" && pwd)"
    echo -e "Max iterations: ${MAX_ITERATIONS}"
    echo -e "Build cmd: $(detect_build_cmd)"
    echo -e "Started: $(date)"
    echo ""

    > "$LOG_FILE"

    while [ "$ITERATION" -lt "$MAX_ITERATIONS" ]; do
        ITERATION=$((ITERATION + 1))
        log "Iteration ${ITERATION}/${MAX_ITERATIONS}"

        PROMPT=$(build_prompt "$ITERATION")

        log "Running Claude Code..."
        echo "$PROMPT" | claude --print --dangerously-skip-permissions 2>&1 | tee -a "$LOG_FILE"

        # Check completion signals
        if [ -f ".debug-done" ]; then
            log "${GREEN}All bugs fixed after ${ITERATION} iterations${NC}"
            rm -f .debug-done
            break
        fi

        if [ -f ".debug-blocked" ]; then
            log "${RED}Blocked — see .debug-blocked for details${NC}"
            cat .debug-blocked
            break
        fi

        sleep 2
    done

    if [ "$ITERATION" -ge "$MAX_ITERATIONS" ] && [ ! -f ".debug-done" ]; then
        log "${RED}Max iterations reached. Review git log for partial progress.${NC}"
    fi

    echo ""
    echo -e "${CYAN}=== Debug Loop Summary ===${NC}"
    echo "Iterations: ${ITERATION}"
    echo "Git log:"
    git log --oneline -"$ITERATION" 2>/dev/null || echo "No commits"
    echo ""
    echo "Full log: ${LOG_FILE}"
}

main "$@"
