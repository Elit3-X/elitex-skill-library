# Research to Vault

Write agent-generated research to the Obsidian Vault inbox for later triage and mind-mapping.

## Usage

```
/research-to-vault <slug> <title>
```

## Protocol

1. Generate the research markdown with the required frontmatter block below
2. Write the file to: `~/Documents/Obsidian Vault/Inbox/{YYYY-MM-DD}-{slug}.md`
3. Confirm the file was written and remind to triage in Obsidian

## Required Frontmatter

```yaml
---
project: ""              # baukasten-it | elitex | kaufdahoam | komotel | veliano | chenda | pfd | sovereign-ai-os
tags: []                 # Free-form tags
status: inbox            # ALWAYS inbox
confidence: medium       # high | medium | low
source: claude-code
created: {YYYY-MM-DD}
---
```

## File Structure

```markdown
---
(frontmatter as above)
---

# {Title}

## Context

Why this research matters / what triggered it.

## Key Findings

- Finding 1
- Finding 2

## Implications

What this means for EliteX ventures.

## Sources

- Source 1
- Source 2

## Related

- [[relevant-note-1]]
- [[relevant-note-2]]
```

## Rules

- ALWAYS use `status: inbox` -- never write directly to project folders
- ALWAYS include `source: claude-code`
- ALWAYS assign a `project:` value if the research relates to a known project
- If confidence is low, say so. Honesty > completeness.
- Filename pattern: `{YYYY-MM-DD}-{slug}.md`
- Vault path: `/Users/satori/Documents/Obsidian Vault/Inbox/`
