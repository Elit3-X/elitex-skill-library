# Vault Sync

Synchronize vault state into MEMORY.md and update active context pointers.

## Instructions

1. Read `~/.claude/cache/vault-index.json` for current vault inventory
2. Read `~/.claude/cache/vault-session-context.json` for current session context
3. Read current MEMORY.md at `~/.claude/projects/-Users-satori/memory/MEMORY.md`

4. Update MEMORY.md sections:
   - **Active Context**: Update project note pointers with current vault paths
   - **Vault Stats**: Update note counts, inbox pending count, last sync timestamp
   - Keep **Hot Facts** section unchanged (only update if user explicitly requests)

5. Check for inbox items that should be triaged:
   - List any `status: inbox` notes older than 3 days
   - Suggest moving them to appropriate project folders

6. Report what changed:
   - Notes added/removed since last sync
   - MEMORY.md sections updated
   - Inbox triage suggestions

7. Optionally: If vault analysis reveals new patterns or conventions, suggest CLAUDE.md updates
