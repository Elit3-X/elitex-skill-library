# Blog Article Generator

Generate a blog article for elite-x.tech from Knowledge Base content.

## Topic: $ARGUMENTS

## Instructions

1. Use the Task tool with an `explore` subagent to find 3-5 relevant Knowledge Base notes matching the topic:
   - Search `~/Documents/Obsidian Vault/Projects/Knowledge-Base/` recursively
   - Prioritize notes with strong Raw Signal sections
   - Include both strategic (Nate B Jones) and tactical (Ben AI) perspectives

2. Read the matched notes fully, focusing on Raw Signal sections

3. Generate the article:

### Format
```markdown
---
title: "[Compelling title — not clickbait, but specific]"
description: "[1-2 sentence SEO meta description]"
author: "EliteX"
date: YYYY-MM-DD
tags: [tag1, tag2, tag3]
category: [ai-strategy | ai-automation | business | development]
---

## [Opening hook — counterintuitive claim or surprising data point from the KB]

[2-3 paragraphs establishing the problem/opportunity]

## [Section 1: The Framework]
[Present the key framework or mental model]

## [Section 2: How It Works]
[Practical breakdown with examples]

## [Section 3: What This Means For You]
[Actionable takeaways for the reader]

## The Bottom Line
[1 paragraph synthesis with a clear call to action]
```

4. Style rules:
   - Write for business owners and technical decision-makers
   - Use specific numbers and examples from the KB (preserve data points)
   - No fluff, no filler, no "in today's rapidly changing landscape"
   - Direct, confident, opinionated
   - 800-1200 words target
   - Include internal links to EliteX services where relevant

5. Output the article to `~/Documents/Obsidian Vault/Inbox/blog-[slug].md` with status: inbox
