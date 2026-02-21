---
name: n8n-workflow-generator
description: |
  Generate n8n workflow JSON from natural language descriptions.
  Use when building automations, integrating services, or creating AI agent workflows.
  Triggers: "n8n", "workflow", "automation", "integrate", "connect services", "webhook".
---

# N8N Workflow Generator

## When to Use
When the user needs to build an automation workflow connecting multiple services. Generate the n8n workflow JSON that can be directly imported.

## Core Architecture Patterns

### Pattern 1: Webhook → Process → Output
```
Webhook Trigger → Set/Code Node (parse input) → AI Agent/HTTP Request → Response
```
Use for: API endpoints, form handlers, Slack/Discord bots

### Pattern 2: Schedule → Scrape → Enrich → Notify
```
Cron Trigger → HTTP Request (scrape) → AI Agent (analyze) → Slack/Email/Airtable
```
Use for: Monitoring, competitive analysis, content curation

### Pattern 3: CRM Trigger → AI Agent → Multi-Channel Output
```
Airtable/HubSpot Trigger → AI Agent (personalize) → Switch → Email/WhatsApp/LinkedIn
```
Use for: Sales automation, outreach, follow-ups

### Pattern 4: Document → Extract → Transform → Load
```
Webhook (file upload) → Extract Text → AI Agent (structure) → Database/Airtable
```
Use for: Invoice processing, document analysis, data entry

## Tool Stack Reference
| Tool | n8n Node | Use Case |
|------|----------|----------|
| OpenAI/Claude | AI Agent node | Text generation, analysis |
| Airtable | Airtable node | Database, CRM |
| Google Sheets | Google Sheets node | Spreadsheet I/O |
| Slack | Slack node | Notifications |
| Gmail | Gmail node | Email send/receive |
| HTTP Request | HTTP Request node | Any API call |
| Webhook | Webhook node | Trigger from external |
| Code | Code node | Custom JS/Python logic |
| Switch | Switch node | Conditional routing |
| Merge | Merge node | Combine data streams |

## Workflow Generation Rules
1. Always start with a trigger node (webhook, cron, or service trigger)
2. Use Set nodes to clean/transform data between steps
3. Use Error Trigger + Slack/Email for error notifications
4. Add retry logic on HTTP Request nodes (3 retries, 1s backoff)
5. Use sub-workflows for reusable logic
6. Keep AI Agent prompts in Set nodes (easier to edit)
7. Always include a test webhook URL in the output

## Pricing Reference (for client scoping)
| Complexity | Nodes | Build Time | Price Range |
|-----------|-------|------------|-------------|
| Simple | 3-5 | 2-4 hours | $500-$1,500 |
| Medium | 6-15 | 1-2 days | $1,500-$3,500 |
| Complex | 15-30 | 3-5 days | $3,500-$7,500 |
| Enterprise | 30+ | 1-2 weeks | $7,500-$15,000+ |

## Output Format
When generating a workflow, output:
1. Architecture diagram (Mermaid)
2. n8n workflow JSON (importable)
3. Setup instructions (API keys needed, env vars)
4. Test plan (how to verify it works)
