#!/usr/bin/env bash
# Infinite Agent Loop — autonomous Claude Code with context handoff
#
# Usage:
#   infinite-agent.sh [task-file]         # Run from task queue
#   infinite-agent.sh --spec SPEC.md      # Run single spec (enhanced ralph)
#   infinite-agent.sh --resume            # Resume from last handoff
#
# Runs in tmux. Claude auto-saves state on context exhaustion.
# Loop reads handoff, generates next prompt, restarts Claude.
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
MAX_CONSECUTIVE_FAILURES=3
COOLDOWN_SECONDS=5

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

# ── Prompt Generation ──────────────────────────────────────────
build_prompt() {
  local mode="$1"
  local context=""

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

  # Git context
  local git_log
  git_log=$(git log --oneline -5 2>/dev/null || echo "No git history")

  case "$mode" in
    spec)
      local spec_file="${2:-SPEC.md}"
      cat <<EOF
You are in an Infinite Agent Loop — autonomous execution with auto-handoff.

${context}
## Spec
$(cat "$spec_file" 2>/dev/null || echo "ERROR: Spec file not found: $spec_file")

## Recent Git History
\`\`\`
${git_log}
\`\`\`

## Instructions
1. Read the spec and any handoff context above
2. Continue from where the previous session left off (or start fresh if no handoff)
3. Implement incrementally — commit after each meaningful unit
4. Use commit format: "agent[auto]: <description>"
5. If ALL success criteria are met, create \`.agent-done\` with "COMPLETE"
6. Context will auto-save if you run low — just keep working
7. Do NOT ask for input — make decisions and proceed
8. After completing each task, write a vault note to ~/Documents/Obsidian Vault/Projects/{project-name}/ with frontmatter (project, tags, status, source: infinite-agent, created), commits, what was done, what's next, and [[backlinks]]
EOF
      ;;
    task)
      local task_desc="${2:-}"
      cat <<EOF
You are in an Infinite Agent Loop — autonomous execution with auto-handoff.

${context}
## Current Task
${task_desc}

## Recent Git History
\`\`\`
${git_log}
\`\`\`

## Instructions
1. Execute the task described above
2. If there's handoff context, continue from where the previous session stopped
3. Commit progress incrementally: "agent[auto]: <description>"
4. When the task is FULLY complete, create \`.agent-done\` with "COMPLETE"
5. Context will auto-save if you run low — just keep working
6. Do NOT ask for input — make decisions and proceed
7. After completing each task, write a vault note to ~/Documents/Obsidian Vault/Projects/{project-name}/ with frontmatter (project, tags, status, source: infinite-agent, created), commits, what was done, what's next, and [[backlinks]]
EOF
      ;;
    resume)
      cat <<EOF
You are resuming from a previous session handoff.

${context}
## Recent Git History
\`\`\`
${git_log}
\`\`\`

## Instructions
1. Read the handoff context above carefully
2. Continue exactly where the previous session left off
3. Commit progress: "agent[auto]: <description>"
4. When done, create \`.agent-done\` with "COMPLETE"
5. Do NOT ask for input — make decisions and proceed
6. After completing work, write a vault note to ~/Documents/Obsidian Vault/Projects/{project-name}/ with frontmatter, commits, summary, and [[backlinks]]
EOF
      ;;
  esac
}

# ── Run Claude ─────────────────────────────────────────────────
run_claude() {
  local prompt="$1"
  local exit_code=0

  log "Starting Claude session..."
  export INFINITE_AGENT=1
  # Write prompt to temp file to avoid arg length issues
  local prompt_file
  prompt_file=$(mktemp /tmp/agent-prompt-XXXXXX.txt)
  echo "$prompt" > "$prompt_file"
  claude -p --dangerously-skip-permissions < "$prompt_file" 2>&1 | tee -a "$LOG_FILE" || exit_code=$?
  rm -f "$prompt_file"

  return $exit_code
}

# ── Vault Save ─────────────────────────────────────────────────
save_to_vault() {
  local project
  project=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
  project=$(echo "$project" | tr '[:upper:]' '[:lower:]')

  local vault_dir="$HOME/Documents/Obsidian Vault/Projects"
  local date
  date=$(date +%Y-%m-%d)

  # Map project names
  case "$project" in
    kaufdahoam) vault_dir="$vault_dir/KaufDahoam" ;;
    veliano)    vault_dir="$vault_dir/Veliano" ;;
    komotel)    vault_dir="$vault_dir/Komotel" ;;
    *)          vault_dir="$vault_dir/$project" ;;
  esac

  mkdir -p "$vault_dir"

  local note_path="$vault_dir/Agent-Session-${date}.md"
  local handoff_summary=""

  if [ -f "$HANDOFF_FILE" ] && [ -s "$HANDOFF_FILE" ]; then
    handoff_summary=$(jq -r 'to_entries | map("- **\(.key)**: \(.value)") | join("\n")' "$HANDOFF_FILE" 2>/dev/null || echo "")
  fi

  local commits
  commits=$(git log --oneline --since="1 hour ago" 2>/dev/null | head -10 || echo "No recent commits")

  local completed_tasks
  completed_tasks=$(jq -r '.completed | if length > 0 then map("- " + .) | join("\n") else "None" end' "$TASK_QUEUE" 2>/dev/null || echo "None")

  if [ -f "$note_path" ]; then
    # Append to existing note
    cat >> "$note_path" <<EOF

---

## Session $(date +%H:%M)

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

## Session $(date +%H:%M)

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
  case "${1:-}" in
    --spec)
      mode="spec"
      spec_or_task="${2:-SPEC.md}"
      ;;
    --resume)
      mode="resume"
      ;;
    --help|-h)
      echo "Usage: infinite-agent.sh [task-file | --spec SPEC.md | --resume]"
      echo ""
      echo "  task-file     JSON file with tasks array"
      echo "  --spec FILE   Run against a spec file"
      echo "  --resume      Resume from last handoff"
      echo ""
      echo "Stop cleanly:   touch /tmp/infinite-agent-stop"
      echo "Monitor:        tail -f /tmp/infinite-agent.log"
      exit 0
      ;;
    "")
      # Default: check for existing handoff or task queue
      if [ -f "$HANDOFF_FILE" ] && [ "$(cat "$HANDOFF_FILE")" != "{}" ]; then
        mode="resume"
      elif [ -f "$TASK_QUEUE" ] && [ "$(jq '.tasks | length' "$TASK_QUEUE" 2>/dev/null)" -gt 0 ]; then
        mode="task"
      else
        err "No handoff, no tasks. Provide a spec or task file."
        exit 1
      fi
      ;;
    *)
      # Task file provided
      if [ -f "$1" ]; then
        cp "$1" "$TASK_QUEUE"
        mode="task"
      else
        err "File not found: $1"
        exit 1
      fi
      ;;
  esac

  # Init
  mkdir -p "$CACHE_DIR"
  init_task_queue
  init_handoff
  rm -f "$STOP_FILE" ".agent-done"
  echo $$ > "$PID_FILE"

  log "=== Infinite Agent Started ==="
  log "Mode: $mode"
  log "PID: $$"
  log "Stop: touch $STOP_FILE"
  log "Monitor: tail -f $LOG_FILE"
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
        log "${YELLOW}Context exhausted — HANDOFF. Restarting with saved state...${NC}"
        save_to_vault
        failures=0
        # Don't pop task — same task continues in next iteration
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
        # After first resume, switch to task mode if queue has items
        mode="task"
        ;;
    esac

    log "Iteration $iteration starting..."

    # Run Claude
    if run_claude "$prompt"; then
      failures=0
    else
      failures=$((failures + 1))
      err "Claude exited with error (failure $failures/$MAX_CONSECUTIVE_FAILURES)"

      if [ "$failures" -ge "$MAX_CONSECUTIVE_FAILURES" ]; then
        err "Too many consecutive failures. Stopping."
        save_to_vault
        break
      fi
    fi

    # Save to vault between iterations
    save_to_vault

    # Cooldown
    log "Cooldown ${COOLDOWN_SECONDS}s..."
    sleep "$COOLDOWN_SECONDS"
  done

  log "=== Infinite Agent Finished ==="
  log "Iterations: $iteration"
  log "Log: $LOG_FILE"
}

main "$@"
