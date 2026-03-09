#!/bin/bash
# Obsidian Vault Sync: Mac → NAS (via tar+SSH+docker)
# Triggered by fswatch on file changes, debounced to avoid rapid-fire syncs

VAULT_DIR="$HOME/Documents/Obsidian Vault"
NAS_HOST="Satori@192.168.10.50"
NAS_PATH="/home/Satori/Documents/Obsidian"
SSH_KEY="$HOME/.ssh/mikrotik"
LOCK_FILE="/tmp/obsidian-sync.lock"
LOG_FILE="$HOME/.claude/logs/obsidian-sync.log"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

# Prevent concurrent syncs
if [ -f "$LOCK_FILE" ]; then
    pid=$(cat "$LOCK_FILE" 2>/dev/null)
    if kill -0 "$pid" 2>/dev/null; then
        exit 0
    fi
    rm -f "$LOCK_FILE"
fi
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

log "Sync started"

# Full sync via tar into "Fold 7" subfolder (matches Android vault name)
REMOTE_SUBDIR="Fold 7"
cd "$VAULT_DIR" && tar czf - --exclude='.DS_Store' --exclude='._*' . \
    | ssh -i "$SSH_KEY" -o ConnectTimeout=10 "$NAS_HOST" \
    "docker run --rm -i -v ${NAS_PATH}:/data alpine sh -c 'rm -rf \"/data/${REMOTE_SUBDIR}\"/* \"/data/${REMOTE_SUBDIR}\"/.obsidian && mkdir -p \"/data/${REMOTE_SUBDIR}\" && cd \"/data/${REMOTE_SUBDIR}\" && tar xzf -'" \
    2>> "$LOG_FILE"

if [ $? -eq 0 ]; then
    # Fix ownership for WebDAV container (UID 82)
    ssh -i "$SSH_KEY" -o ConnectTimeout=10 "$NAS_HOST" \
        "docker run --rm -v ${NAS_PATH}:/data alpine chown -R 82:82 /data/" \
        2>> "$LOG_FILE"
    log "Sync completed successfully"
else
    log "Sync FAILED"
fi
