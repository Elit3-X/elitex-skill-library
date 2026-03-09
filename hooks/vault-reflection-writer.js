#!/usr/bin/env node
// Vault Reflection Writer - Stop hook
// Enhanced replacement for kb-reflection.js
// Writes reflections to Obsidian Inbox with backlinks and also appends to KB Reflections.md

const fs = require('fs');
const path = require('path');
const os = require('os');

const homeDir = os.homedir();
const vaultBase = path.join(homeDir, 'Documents', 'Obsidian Vault');
const inboxDir = path.join(vaultBase, 'Inbox');
const kbDir = path.join(vaultBase, 'Projects', 'Knowledge-Base');
const reflectionsFile = path.join(kbDir, 'Reflections.md');
const indexFile = path.join(homeDir, '.claude', 'cache', 'vault-index.json');

function detectProject(dir) {
  const lower = dir.toLowerCase();
  if (lower.includes('kaufdahoam')) return 'kaufdahoam';
  if (lower.includes('veliano')) return 'veliano';
  if (lower.includes('komotel')) return 'komotel';
  if (lower.includes('kriyaverse')) return 'sovereign-ai-os';
  if (lower.includes('baukasten')) return 'baukasten-it';
  if (lower.includes('elitex') || lower.includes('elite-x')) return 'elitex';

  // Fallback: check package.json name
  const pkgPath = path.join(dir, 'package.json');
  try {
    const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
    if (pkg.name) return pkg.name.toLowerCase().replace(/^@[^/]+\//, '');
  } catch (e) {}

  return path.basename(dir).toLowerCase();
}

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);

    // Get last assistant message
    const messages = data.messages || [];
    const lastAssistant = messages.filter(m => m.role === 'assistant').slice(-1)[0];
    if (!lastAssistant) return;

    const content = typeof lastAssistant.content === 'string'
      ? lastAssistant.content
      : JSON.stringify(lastAssistant.content);

    // Check for completion indicators
    const isCompletion = /(?:completed|done|finished|deployed|shipped|merged|created|built)/i.test(content);
    if (!isCompletion) return;

    // Extract summary (first 200 chars)
    const summary = content.substring(0, 200).replace(/\n/g, ' ').trim();

    const date = new Date().toISOString().split('T')[0];
    const time = new Date().toTimeString().split(' ')[0];
    const cwd = data.cwd || process.cwd();
    const project = detectProject(cwd);

    // Load vault index for backlinks
    let allTitles = [];
    let allNotes = [];
    try {
      if (fs.existsSync(indexFile)) {
        const index = JSON.parse(fs.readFileSync(indexFile, 'utf8'));
        for (const [, notes] of Object.entries(index.projects || {})) {
          for (const note of notes) {
            allTitles.push(note.title);
            allNotes.push(note);
          }
        }
        for (const item of (index.inbox || [])) {
          allTitles.push(item.title);
        }
        for (const fw of (index.frameworks || [])) {
          allTitles.push(fw.title);
        }
      }
    } catch (e) {}

    // Generate backlinks: check if note titles appear in summary
    const backlinks = [];
    const contentLower = content.toLowerCase();
    for (const title of allTitles) {
      if (title.length < 3) continue; // skip very short titles
      if (contentLower.includes(title.toLowerCase())) {
        backlinks.push(`[[${title}]]`);
      }
    }

    // Also check tag matches: collect tags from content, match against note tags
    const contentTags = [];
    const tagMatch = content.match(/#[\w-]+/g);
    if (tagMatch) {
      for (const t of tagMatch) {
        contentTags.push(t.replace('#', '').toLowerCase());
      }
    }
    if (contentTags.length > 0) {
      for (const note of allNotes) {
        if (!note.tags || !Array.isArray(note.tags)) continue;
        for (const noteTag of note.tags) {
          if (contentTags.includes(noteTag.toLowerCase()) && !backlinks.includes(`[[${note.title}]]`)) {
            backlinks.push(`[[${note.title}]]`);
            break;
          }
        }
      }
    }

    // Deduplicate backlinks
    const uniqueBacklinks = [...new Set(backlinks)];
    const relatedTitles = uniqueBacklinks.map(b => b.replace(/^\[\[|\]\]$/g, ''));

    // Write to Project folder (preferred) or Inbox (fallback)
    const projectMap = {
      'kaufdahoam': 'KaufDahoam',
      'veliano': 'Veliano',
      'komotel': 'Komotel',
      'baukasten-it': 'Baukasten-IT',
      'elitex': 'EliteX',
      'sovereign-ai-os': 'Sovereign-AI-OS',
      'infrastructure': 'Infrastructure',
    };
    const projectFolder = projectMap[project] || project;
    const projectDir = path.join(vaultBase, 'Projects', projectFolder);
    const targetDir = fs.existsSync(path.join(vaultBase, 'Projects')) ? projectDir : inboxDir;

    if (!fs.existsSync(targetDir)) {
      fs.mkdirSync(targetDir, { recursive: true });
    }

    const inboxFilename = `${date}-reflection-${project}.md`;
    const inboxPath = path.join(targetDir, inboxFilename);

    if (fs.existsSync(inboxPath)) {
      // Append to existing file
      const appendEntry = `\n---\n\n### ${time}\n\n${summary}\n\n### Related\n${uniqueBacklinks.length > 0 ? uniqueBacklinks.map(b => `- ${b}`).join('\n') : '- No related notes detected'}\n`;
      fs.appendFileSync(inboxPath, appendEntry);
    } else {
      // Create new file with frontmatter
      const frontmatter = `---
project: "${project}"
tags: [reflection, session-log]
status: inbox
confidence: medium
source: claude-code
created: ${date}
related: [${relatedTitles.map(t => `"${t}"`).join(', ')}]
---

## Session Reflection

${summary}

### Related
${uniqueBacklinks.length > 0 ? uniqueBacklinks.map(b => `- ${b}`).join('\n') : '- No related notes detected'}
`;
      fs.writeFileSync(inboxPath, frontmatter);
    }

    // Also append to KB Reflections.md (preserve existing behavior)
    const kbEntry = `\n### ${date} ${time}\n${summary}\n`;

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
      fs.writeFileSync(reflectionsFile, header + kbEntry);
    } else {
      fs.appendFileSync(reflectionsFile, kbEntry);
    }
  } catch (e) {
    // Silent fail - don't break Claude Code
  }
});
