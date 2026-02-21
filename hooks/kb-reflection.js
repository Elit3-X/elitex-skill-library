#!/usr/bin/env node
// KB Reflection Hook
// After significant task completion, log a reflection to the Knowledge Base
// Triggered by: task completion patterns in Claude Code

const fs = require('fs');
const path = require('path');
const os = require('os');

const kbDir = path.join(os.homedir(), 'Documents', 'Obsidian Vault', 'Projects', 'Knowledge-Base');
const reflectionsFile = path.join(kbDir, 'Reflections.md');

// Read stdin for hook data
let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
    try {
        const data = JSON.parse(input);
        
        // Only log on significant completions
        const messages = data.messages || [];
        const lastAssistant = messages.filter(m => m.role === 'assistant').slice(-1)[0];
        if (!lastAssistant) return;
        
        const content = typeof lastAssistant.content === 'string' 
            ? lastAssistant.content 
            : JSON.stringify(lastAssistant.content);
        
        // Check for completion indicators
        const isCompletion = /(?:completed|done|finished|deployed|shipped|merged|created|built)/i.test(content);
        if (!isCompletion) return;
        
        // Extract a brief summary (first 200 chars of the completion message)
        const summary = content.substring(0, 200).replace(/\n/g, ' ').trim();
        
        const date = new Date().toISOString().split('T')[0];
        const time = new Date().toTimeString().split(' ')[0];
        
        // Append to reflections file
        const entry = `\n### ${date} ${time}\n${summary}\n`;
        
        // Create file with frontmatter if it doesn't exist
        if (!fs.existsSync(reflectionsFile)) {
            const header = `---
title: "Session Reflections"
tags: [reflections, learnings, meta]
category: meta
status: active
project: knowledge-base
created: ${date}
---

## Session Reflections

Automated log of significant completions and learnings.

`;
            fs.writeFileSync(reflectionsFile, header + entry);
        } else {
            fs.appendFileSync(reflectionsFile, entry);
        }
    } catch (e) {
        // Silent fail — don't break Claude Code
    }
});
