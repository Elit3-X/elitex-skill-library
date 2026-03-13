#!/usr/bin/env bash
# Infinite Agent Loop — autonomous Claude Code with context handoff
#
# Usage:
#   infinite-agent.sh [task-file]         # Run from task queue
#   infinite-agent.sh --spec SPEC.md      # Run single spec (enhanced ralph)
#   infinite-agent.sh --resume            # Resume from last handoff
#   infinite-agent.sh --budget 0.75       # Override $ budget per iteration
#   infinite-agent.sh --timeout 900       # Override iteration timeout (seconds)
#
# Each iteration has a dollar budget cap ($0.50 default). Claude is instructed
# to self-manage: do real work, then save state (handoff.json + vault note)
# before the budget/context runs out. The loop restarts with fresh context,
# injecting the handoff + latest vault note as context.
#
# No statusline or PostToolUse hooks needed — works fully in headless mode.
#
# Requires: claude CLI, jq
# Kill cleanly: touch /tmp/infinite-agent-stop

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
CACHE_DIR="$HOME/.claude/cache"
HANDOFF_FILE="$CACHE_DIR/handoff.json"
TASK_QUEUE="$CACHE_DIR/task-queue.json"
LOG_FILE="/tmp/infinite-agent.log"
STOP_FILE="/tmp/infinite-agent-stop"
PID_FILE="/tmp/infinite-agent.pid"
VAULT_DIR="$HOME/Documents/Obsidian Vault/Projects"
MAX_CONSECUTIVE_FAILURES=3
COOLDOWN_SECONDS=5
MAX_BUDGET="0.50"       # Dollar budget per iteration — hard stop safety net
ITERATION_TIMEOUT=600   # 10 min timeout per iteration (seconds)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${CYAN}[agent:$(date +%H:%M:%S)]${NC} $1" | tee -a "$LOG_FILE"; }
err() { echo -e "${RED}[agent:$(date +%H:%M:%S)]${NC} $1" | tee -a "$LOG_FILE"; }

cleanup() {
  rm -f "$PID_FILE" "$STOP_FILE"
  log "Agent loop stopped."
}
trap cleanup EXIT

# ── Initialization ──────────────────────────────────────────────
init_task_queue() {
  if [ ! -f "$TASK_QUEUE" ]; then
    echo '{"tasks":[],"completed":[],"current":null}' > "$TASK_QUEUE"
  fi
}

init_handoff() {
  if [ ! -f "$HANDOFF_FILE" ]; then
    echo '{}' > "$HANDOFF_FILE"
  fi
}

# ── Vault Operations ─────────────────────────────────────────────
resolve_vault_dir() {
  local project
  project=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
  project=$(echo "$project" | tr '[:upper:]' '[:lower:]')

  case "$project" in
    kaufdahoam) echo "$VAULT_DIR/KaufDahoam" ;;
    veliano)    echo "$VAULT_DIR/Veliano" ;;
    komotel)    echo "$VAULT_DIR/Komotel" ;;
    baukasten*) echo "$VAULT_DIR/Baukasten-IT" ;;
    elitex*)    echo "$VAULT_DIR/EliteX" ;;
    *)          echo "$VAULT_DIR/$project" ;;
  esac
}

# Find the most recent vault note for the current project
get_latest_vault_note() {
  local vdir
  vdir=$(resolve_vault_dir)
  if [ -d "$vdir" ]; then
    local latest
    latest=$(ls -t "$vdir"/*.md 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
      echo "$latest"
    fi
  fi
}

# Read vault note content, truncated to keep prompt reasonable
read_vault_context() {
  local note_path
  note_path=$(get_latest_vault_note)
  if [ -n "$note_path" ] && [ -f "$note_path" ]; then
    local bname
    bname=$(basename "$note_path")
    echo "## Latest Vault Note: $bname"
    echo ""
    # Cap at 80 lines to avoid bloating the prompt
    head -80 "$note_path"
    local total_lines
    total_lines=$(wc -l < "$note_path" | tr -d ' ')
    if [ "$total_lines" -gt 80 ]; then
      echo ""
      echo "[... truncated, ${total_lines} total lines — read full note at: $note_path]"
    fi
  fi
}

# List recent vault notes (last 5) for awareness
list_recent_vault_notes() {
  local vdir
  vdir=$(resolve_vault_dir)
  if [ -d "$vdir" ]; then
    local notes
    notes=$(ls -t "$vdir"/*.md 2>/dev/null | head -5)
    if [ -n "$notes" ]; then
      echo "## Recent Vault Notes"
      echo "Read these for deeper context if needed:"
      echo ""
      while IFS= read -r note; do
        echo "- \`$note\`"
      done <<< "$notes"
    fi
  fi
}

# ── Task Queue Operations ──────────────────────────────────────
get_current_task() {
  jq -r '.current // empty' "$TASK_QUEUE"
}

get_next_task() {
  jq -r '.tasks[0] // empty' "$TASK_QUEUE"
}

pop_task() {
  local task
  task=$(jq -r '.tasks[0]' "$TASK_QUEUE")
  jq '.current = .tasks[0] | .tasks = .tasks[1:]' "$TASK_QUEUE" > "$TASK_QUEUE.tmp"
  mv "$TASK_QUEUE.tmp" "$TASK_QUEUE"
  echo "$task"
}

complete_current_task() {
  jq '.completed += [.current + " (" + (now | strftime("%Y-%m-%d %H:%M")) + ")"] | .current = null' "$TASK_QUEUE" > "$TASK_QUEUE.tmp"
  mv "$TASK_QUEUE.tmp" "$TASK_QUEUE"
}

# ── End-of-Iteration Protocol (injected into every prompt) ─────
end_of_iteration_protocol() {
  local vdir
  vdir=$(resolve_vault_dir)
  local project
  project=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")

  cat <<PROTO

## MANDATORY End-of-Iteration Protocol

You are running in headless mode with a budget cap (\$${MAX_BUDGET}). There are NO context
warnings in headless mode — the session simply ends when budget/context runs out.
You MUST self-manage and execute this protocol before that happens.

### When task is FULLY COMPLETE:
1. Write \`~/.claude/cache/handoff.json\`:
   \`\`\`json
   {"task":"<task>","progress":"COMPLETE — all success criteria met","remaining":"none","files_touched":"<files>","blockers":"none","git_state":"<branch> <commit>"}
   \`\`\`
2. Write a vault note to \`${vdir}/\` with:
   - Frontmatter: project, tags, status, confidence, source: infinite-agent, created
   - What was done (grouped by category)
   - Commits this session (with hashes)
   - What's remaining / next steps
   - \`[[backlinks]]\` to related vault notes
3. Commit all uncommitted work: \`git add <files> && git commit -m "agent[auto]: <summary>"\`
4. Create \`.agent-done\` with content \`COMPLETE\`

### When task is NOT YET COMPLETE (most iterations):
1. Write \`~/.claude/cache/handoff.json\` with accurate progress/remaining
2. Write/append a vault note to \`${vdir}/\` documenting:
   - What you accomplished this iteration
   - Decisions made and rationale
   - Exact next steps for the next iteration (be specific — file paths, line numbers)
   - Any blockers or unknowns
3. Commit all uncommitted work
4. Create \`.agent-done\` with content \`HANDOFF\`

### Timing — CRITICAL
- You have a \$${MAX_BUDGET} budget cap per iteration. This buys roughly 30-60 tool calls.
- Do real work for the first ~75% of your turns.
- Then STOP doing new work and execute the protocol above (takes 3-5 turns).
- The next iteration will pick up exactly where you left off using your handoff + vault note.
- If you're unsure whether you have budget left for new work, SAVE STATE FIRST.
- It is MUCH better to save state early than to get cut off mid-work with no handoff.

**Vault directory for this project:** \`${vdir}/\`
**Project name:** \`${project}\`
PROTO
}

# ── Prompt Generation ──────────────────────────────────────────
build_prompt() {
  local mode="$1"
  local context=""
  local vault_context=""

  # Read handoff if exists
  if [ -f "$HANDOFF_FILE" ] && [ -s "$HANDOFF_FILE" ]; then
    local handoff_content
    handoff_content=$(cat "$HANDOFF_FILE")
    if [ "$handoff_content" != "{}" ]; then
      context="## Previous Session Handoff
$(echo "$handoff_content" | jq -r '
  "- **Task**: \(.task // "unknown")\n" +
  "- **Progress**: \(.progress // "unknown")\n" +
  "- **Remaining**: \(.remaining // "unknown")\n" +
  "- **Files touched**: \(.files_touched // "unknown")\n" +
  "- **Blockers**: \(.blockers // "none")\n" +
  "- **Git state**: \(.git_state // "unknown")"
' 2>/dev/null || echo "$handoff_content")

"
    fi
  fi

  # Read vault context (latest note + list of recent notes)
  vault_context=$(read_vault_context 2>/dev/null || echo "")
  local vault_list
  vault_list=$(list_recent_vault_notes 2>/dev/null || echo "")

  # Git context
  local git_log
  git_log=$(git log --oneline -10 2>/dev/null || echo "No git history")

  # End-of-iteration protocol
  local protocol
  protocol=$(end_of_iteration_protocol)

  case "$mode" in
    spec)
      local spec_file="${2:-SPEC.md}"
      cat <<EOF
You are in an Infinite Agent Loop (budget: \$${MAX_BUDGET} per iteration).

${context}
${vault_context}

${vault_list}

## Spec
$(cat "$spec_file" 2>/dev/null || echo "ERROR: Spec file not found: $spec_file")

## Recent Git History
\`\`\`
${git_log}
\`\`\`

## Instructions
1. Read the spec, handoff context, and vault note above for full situation awareness
2. If resuming: read any vault notes listed above for deeper context on decisions/rationale
3. Continue from where the previous session left off (or start fresh if no handoff)
4. Implement incrementally — commit after each meaningful unit
5. Use commit format: "agent[auto]: <description>"
6. If ALL success criteria are met, follow the COMPLETE protocol below
7. Do NOT ask for input — make decisions and proceed
8. Do NOT wait for context warnings — they don't exist in headless mode

${protocol}
EOF
      ;;
    task)
      local task_desc="${2:-}"
      cat <<EOF
You are in an Infinite Agent Loop (budget: \$${MAX_BUDGET} per iteration).

${context}
${vault_context}

${vault_list}

## Current Task
${task_desc}

## Recent Git History
\`\`\`
${git_log}
\`\`\`

## Instructions
1. Read the task, handoff context, and vault note above for full situation awareness
2. If resuming: read any vault notes listed above for deeper context on decisions/rationale
3. Continue from where the previous session stopped (or start fresh if no handoff)
4. Commit progress incrementally: "agent[auto]: <description>"
5. If task is FULLY complete, follow the COMPLETE protocol below
6. Do NOT ask for input — make decisions and proceed
7. Do NOT wait for context warnings — they don't exist in headless mode

${protocol}
EOF
      ;;
    resume)
      cat <<EOF
You are resuming from a previous session in an Infinite Agent Loop (budget: \$${MAX_BUDGET} per iteration).

${context}
${vault_context}

${vault_list}

## Recent Git History
\`\`\`
${git_log}
\`\`\`

## Instructions
1. Read the handoff context and vault note above — they contain your full state
2. Read additional vault notes listed above if you need deeper context on prior decisions
3. Continue exactly where the previous session left off
4. Commit progress: "agent[auto]: <description>"
5. Do NOT ask for input — make decisions and proceed
6. Do NOT wait for context warnings — they don't exist in headless mode

${protocol}
EOF
      ;;
  esac
}

# ── Run Claude ─────────────────────────────────────────────────
run_claude() {
  local prompt="$1"
  local exit_code=0

  log "Starting Claude session (budget: \$${MAX_BUDGET}, timeout: ${ITERATION_TIMEOUT}s)..."
  export INFINITE_AGENT=1

  # Write prompt to temp file to avoid arg length issues
  local prompt_file
  prompt_file=$(mktemp /tmp/agent-prompt-XXXXXX.txt)
  echo "$prompt" > "$prompt_file"

  # Record handoff mtime before running Claude so we can detect if it changed
  local handoff_mtime_before=""
  if [ -f "$HANDOFF_FILE" ]; then
    handoff_mtime_before=$(stat -f %m "$HANDOFF_FILE" 2>/dev/null || echo "0")
  fi

  # Run with budget cap and timeout
  timeout "$ITERATION_TIMEOUT" claude -p \
    --max-budget-usd "$MAX_BUDGET" \
    --dangerously-skip-permissions \
    < "$prompt_file" 2>&1 | tee -a "$LOG_FILE" || exit_code=$?

  rm -f "$prompt_file"

  # If Claude exited without creating .agent-done, check if handoff was updated
  if [ ! -f ".agent-done" ] && [ -f "$HANDOFF_FILE" ]; then
    local handoff_mtime_after
    handoff_mtime_after=$(stat -f %m "$HANDOFF_FILE" 2>/dev/null || echo "0")

    if [ "$handoff_mtime_after" != "$handoff_mtime_before" ] && [ "$handoff_mtime_after" != "0" ]; then
      # Handoff was updated — treat as HANDOFF
      log "${YELLOW}Claude exited with updated handoff.json — treating as HANDOFF${NC}"
      echo "HANDOFF" > ".agent-done"
    elif [ "$exit_code" -eq 0 ] || [ "$exit_code" -eq 124 ]; then
      # Clean exit or timeout but no handoff update — force HANDOFF to keep loop going
      log "${YELLOW}Claude exited without .agent-done (exit=$exit_code) — forcing HANDOFF${NC}"
      echo "HANDOFF" > ".agent-done"
    fi
  fi

  return $exit_code
}

# ── Vault Save (shell-level fallback — supplements Claude's own vault writes) ──
save_to_vault() {
  local vdir
  vdir=$(resolve_vault_dir)
  local project
  project=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
  project=$(echo "$project" | tr '[:upper:]' '[:lower:]')
  local date
  date=$(date +%Y-%m-%d)

  mkdir -p "$vdir"

  local note_path="$vdir/Agent-Session-${date}.md"
  local handoff_summary=""

  if [ -f "$HANDOFF_FILE" ] && [ -s "$HANDOFF_FILE" ]; then
    handoff_summary=$(jq -r 'to_entries | map("- **\(.key)**: \(.value)") | join("\n")' "$HANDOFF_FILE" 2>/dev/null || echo "")
  fi

  local commits
  commits=$(git log --oneline --since="1 hour ago" 2>/dev/null | head -10 || echo "No recent commits")

  local completed_tasks
  completed_tasks=$(jq -r '.completed | if length > 0 then map("- " + .) | join("\n") else "None" end' "$TASK_QUEUE" 2>/dev/null || echo "None")

  if [ -f "$note_path" ]; then
    cat >> "$note_path" <<EOF

---

## Iteration at $(date +%H:%M)

### Commits
\`\`\`
${commits}
\`\`\`

### Handoff State
${handoff_summary:-No handoff state}

### Completed Tasks
${completed_tasks}
EOF
  else
    cat > "$note_path" <<EOF
---
project: "${project}"
tags: [agent-session, autonomous]
status: active
confidence: high
source: infinite-agent
created: ${date}
---

# Agent Session ${date}

## Iteration at $(date +%H:%M)

### Commits
\`\`\`
${commits}
\`\`\`

### Handoff State
${handoff_summary:-Fresh start}

### Completed Tasks
${completed_tasks}
EOF
  fi

  log "Saved to vault: $note_path"
}

# ── Main Loop ──────────────────────────────────────────────────
main() {
  local mode="resume"
  local spec_or_task=""
  local failures=0

  # Parse args
  while [ $# -gt 0 ]; do
    case "$1" in
      --spec)
        mode="spec"
        spec_or_task="${2:-SPEC.md}"
        shift 2
        ;;
      --resume)
        mode="resume"
        shift
        ;;
      --budget)
        MAX_BUDGET="${2:-0.50}"
        shift 2
        ;;
      --timeout)
        ITERATION_TIMEOUT="${2:-600}"
        shift 2
        ;;
      --help|-h)
        echo "Usage: infinite-agent.sh [OPTIONS] [task-file]"
        echo ""
        echo "Options:"
        echo "  --spec FILE    Run against a spec file"
        echo "  --resume       Resume from last handoff"
        echo "  --budget N     Dollar budget per iteration (default: 0.50)"
        echo "  --timeout N    Timeout per iteration in seconds (default: 600)"
        echo "  task-file      JSON file with tasks array"
        echo ""
        echo "Stop cleanly:   touch /tmp/infinite-agent-stop"
        echo "Monitor:        tail -f /tmp/infinite-agent.log"
        exit 0
        ;;
      *)
        if [ -f "$1" ]; then
          cp "$1" "$TASK_QUEUE"
          mode="task"
        else
          err "File not found: $1"
          exit 1
        fi
        shift
        ;;
    esac
  done

  # Default mode detection if no explicit mode set
  if [ "$mode" = "resume" ] && [ -z "$spec_or_task" ]; then
    if [ -f "$HANDOFF_FILE" ] && [ "$(cat "$HANDOFF_FILE")" != "{}" ]; then
      mode="resume"
    elif [ -f "$TASK_QUEUE" ] && [ "$(jq '.tasks | length' "$TASK_QUEUE" 2>/dev/null)" -gt 0 ]; then
      mode="task"
    fi
  fi

  # Init
  mkdir -p "$CACHE_DIR"
  init_task_queue
  init_handoff
  rm -f "$STOP_FILE" ".agent-done"
  echo $$ > "$PID_FILE"

  log "=== Infinite Agent Started ==="
  log "Mode: $mode | Budget: \$${MAX_BUDGET}/iter | Timeout: ${ITERATION_TIMEOUT}s"
  log "PID: $$"
  log "Stop: touch $STOP_FILE"
  log "Monitor: tail -f $LOG_FILE"
  log "Vault: $(resolve_vault_dir)"
  echo ""

  local iteration=0

  while true; do
    iteration=$((iteration + 1))

    # Check stop signal
    if [ -f "$STOP_FILE" ]; then
      log "Stop signal received. Saving state..."
      save_to_vault
      break
    fi

    # Check if done or handoff
    if [ -f ".agent-done" ]; then
      local done_status
      done_status=$(cat ".agent-done" | tr -d '[:space:]')
      rm -f ".agent-done"

      if [ "$done_status" = "COMPLETE" ]; then
        log "${GREEN}Task COMPLETE${NC}"

        if [ "$mode" = "task" ]; then
          complete_current_task
          save_to_vault

          local next
          next=$(get_next_task)
          if [ -z "$next" ]; then
            log "${GREEN}=== All tasks complete ===${NC}"
            break
          fi

          log "Moving to next task..."
          echo '{}' > "$HANDOFF_FILE"
          failures=0
          continue
        else
          save_to_vault
          break
        fi

      elif [ "$done_status" = "HANDOFF" ]; then
        log "${YELLOW}Iteration $iteration ended — HANDOFF. Restarting with saved state...${NC}"
        save_to_vault
        failures=0
        sleep "$COOLDOWN_SECONDS"
        continue
      fi
    fi

    # Build prompt based on mode
    local prompt=""
    case "$mode" in
      spec)
        prompt=$(build_prompt spec "$spec_or_task")
        ;;
      task)
        local current
        current=$(get_current_task)
        if [ -z "$current" ]; then
          current=$(pop_task)
        fi
        if [ -z "$current" ] || [ "$current" = "null" ]; then
          log "${GREEN}=== No more tasks ===${NC}"
          break
        fi
        log "Task: $current"
        prompt=$(build_prompt task "$current")
        ;;
      resume)
        prompt=$(build_prompt resume)
        # After first resume, switch to spec/task if available
        if [ -n "$spec_or_task" ]; then
          mode="spec"
        elif [ "$(jq '.tasks | length' "$TASK_QUEUE" 2>/dev/null)" -gt 0 ]; then
          mode="task"
        fi
        ;;
    esac

    log "Iteration $iteration starting..."

    # Run Claude
    if run_claude "$prompt"; then
      failures=0
    else
      local ec=$?
      if [ "$ec" -eq 124 ]; then
        log "${YELLOW}Iteration timed out — treating as HANDOFF${NC}"
        failures=0
      else
        failures=$((failures + 1))
        err "Claude exited with error code $ec (failure $failures/$MAX_CONSECUTIVE_FAILURES)"
      fi

      if [ "$failures" -ge "$MAX_CONSECUTIVE_FAILURES" ]; then
        err "Too many consecutive failures. Stopping."
        save_to_vault
        break
      fi
    fi

    # Fallback vault save (supplements Claude's own vault write)
    save_to_vault

    # Cooldown
    log "Cooldown ${COOLDOWN_SECONDS}s..."
    sleep "$COOLDOWN_SECONDS"
  done

  log "=== Infinite Agent Finished ==="
  log "Iterations: $iteration"
  log "Log: $LOG_FILE"
  log "Vault: $(resolve_vault_dir)"
}

main "$@"
