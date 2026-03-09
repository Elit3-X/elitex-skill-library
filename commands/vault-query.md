# Vault Query

Search the Obsidian vault for notes relevant to: $ARGUMENTS

## Instructions

1. Read `~/.claude/cache/vault-index.json` to see the full note inventory
2. Use Grep to search `~/Documents/Obsidian Vault/Projects/` for the query terms in file contents
3. Use Grep to search `~/Documents/Obsidian Vault/Inbox/` for the query terms
4. Also search `~/Documents/Obsidian Vault/Projects/Knowledge-Base/Frameworks/` for framework matches
5. Read the top 3 most relevant files (highest match density)
6. Synthesize findings:
   - **Relevant Notes:** List matching notes with `[[Note Title]]` backlinks
   - **Key Insights:** Bullet points from the matched content
   - **Frameworks:** Any applicable frameworks from the Knowledge Base
   - **Source Paths:** Full file paths for reference
7. If findings are significant and not already tracked, suggest running `/vault-sync` to update MEMORY.md pointers
