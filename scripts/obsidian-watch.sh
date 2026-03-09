#!/bin/bash
# Watches Obsidian Vault for changes and triggers sync to NAS
# Debounces to 30 seconds to avoid rapid-fire syncs

VAULT_DIR="$HOME/Documents/Obsidian Vault"
SYNC_SCRIPT="$HOME/.claude/scripts/obsidian-sync.sh"

/opt/homebrew/bin/fswatch -o -l 30 \
    --exclude '\.DS_Store$' \
    --exclude '\._' \
    "$VAULT_DIR" \
    | while read -r count; do
        "$SYNC_SCRIPT"
    done
