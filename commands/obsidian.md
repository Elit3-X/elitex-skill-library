**OBSIDIAN DOCUMENTATION MODE: ACTIVE**

For the remainder of this session, ALL research, analysis, and knowledge outputs MUST be written to the Obsidian Vault. This is non-negotiable.

## Vault Location

`~/Documents/Obsidian Vault/`

## Documentation Protocol

1. **Every research output** gets written as a markdown file to `~/Documents/Obsidian Vault/Inbox/`
2. **Filename pattern**: `{YYYY-MM-DD}-{slug}.md`
3. **Frontmatter is mandatory** on every file (schema below)
4. **Wikilinks**: Link to related notes using `[[Note Name]]` syntax
5. **After writing**: Confirm the file path and remind the user to triage in Obsidian

## Required Frontmatter Schema

```yaml
---
project: ""              # baukasten-it | elitex | kaufdahoam | komotel | veliano | chenda | pfd | sovereign-ai-os
tags: []                 # Free-form tags (e.g., research, pricing, gpu, market-analysis)
status: inbox            # ALWAYS inbox — never write directly to project folders
confidence: medium       # high | medium | low
source: claude-code
created: {YYYY-MM-DD}
---
```

## Active Projects in Vault

| Project | Folder | Description |
|---------|--------|-------------|
| Baukasten IT | `Projects/Baukasten-IT/` | Zoho MSP + AI for German SMBs |
| EliteX | `Projects/EliteX/` | Full-service dev studio |
| PFD | `Projects/PFD/` | Present-First Development research |
| Sovereign AI OS | `Projects/Sovereign-AI-OS/` | On-prem enterprise AI platform |

## Behavior

When this mode is active:
- At the END of every substantial research or analysis response, write the output to the vault
- If the user asks a question that produces reusable knowledge, document it
- If the output is trivial (one-liner answers, config fixes, debugging), do NOT document it
- Use your judgment: if it's worth remembering in 30 days, write it to the vault

$ARGUMENTS
