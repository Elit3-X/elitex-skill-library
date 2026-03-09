#!/bin/zsh
# Auto-unlock Bitwarden using macOS Keychain
# First-time setup: security add-generic-password -a "$USER" -s "bitwarden-master" -w
# That ^ prompts for your BW master password and stores it in Keychain

SESSION_FILE="$HOME/.claude/cache/bw-session"

# Check if already unlocked
if [ -f "$SESSION_FILE" ]; then
  export BW_SESSION=$(cat "$SESSION_FILE")
  if bw unlock --check &>/dev/null; then
    echo "$BW_SESSION"
    exit 0
  fi
fi

# Fetch master password from macOS Keychain
MASTER_PW=$(security find-generic-password -a "$USER" -s "bitwarden-master" -w 2>/dev/null)
if [ -z "$MASTER_PW" ]; then
  echo "ERROR: No Bitwarden master password in Keychain." >&2
  echo "Run: security add-generic-password -a \"\$USER\" -s \"bitwarden-master\" -w" >&2
  exit 1
fi

# Unlock Bitwarden
SESSION=$(echo "$MASTER_PW" | bw unlock --raw 2>/dev/null)
if [ -n "$SESSION" ]; then
  mkdir -p "$(dirname "$SESSION_FILE")"
  echo "$SESSION" > "$SESSION_FILE"
  chmod 600 "$SESSION_FILE"
  echo "$SESSION"
else
  echo "ERROR: Failed to unlock Bitwarden." >&2
  exit 1
fi
