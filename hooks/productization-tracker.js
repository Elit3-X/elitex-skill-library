#!/usr/bin/env node
// Productization Tracker Hook (Stop)
// Logs what was built each session to track patterns.
// Source: KB productized-ai-system ("any solution built 3+ times is a productization candidate")
//
// Appends to ~/.claude/logs/solutions-built.log
// Format: YYYY-MM-DD | project-name | brief description

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execSync } = require('child_process');

const LOG_DIR = path.join(os.homedir(), '.claude', 'logs');
const LOG_FILE = path.join(LOG_DIR, 'solutions-built.log');

// Build indicators — only log sessions that actually built something
const BUILD_PATTERNS = /(?:created|built|implemented|deployed|shipped|added|set up|configured|automated|integrated|generated|wrote|scaffolded)/i;

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const messages = data.messages || [];

    // Find last assistant message
    const lastAssistant = messages
      .filter(m => m.role === 'assistant')
      .slice(-1)[0];

    if (!lastAssistant) return;

    const content = typeof lastAssistant.content === 'string'
      ? lastAssistant.content
      : Array.isArray(lastAssistant.content)
        ? lastAssistant.content.filter(b => b.type === 'text').map(b => b.text).join(' ')
        : JSON.stringify(lastAssistant.content);

    // Only log if something was built
    if (!BUILD_PATTERNS.test(content)) return;

    // Try to get project name from git or cwd
    let projectName = 'unknown';
    try {
      const remote = execSync('git remote get-url origin', {
        encoding: 'utf8',
        timeout: 3000
      }).trim();
      // Extract repo name from URL
      projectName = remote.split('/').pop().replace('.git', '');
    } catch {
      try {
        const cwd = execSync('pwd', { encoding: 'utf8', timeout: 2000 }).trim();
        projectName = path.basename(cwd);
      } catch {
        // Keep 'unknown'
      }
    }

    // Extract brief summary (first meaningful sentence, max 120 chars)
    const summary = content
      .replace(/[#*`\[\]]/g, '')
      .split(/[.\n]/)
      .map(s => s.trim())
      .filter(s => s.length > 20 && BUILD_PATTERNS.test(s))
      .slice(0, 1)[0] || content.substring(0, 120).replace(/\n/g, ' ').trim();

    const date = new Date().toISOString().split('T')[0];
    const entry = `${date} | ${projectName} | ${summary.substring(0, 120)}\n`;

    // Ensure log directory exists
    if (!fs.existsSync(LOG_DIR)) {
      fs.mkdirSync(LOG_DIR, { recursive: true });
    }

    fs.appendFileSync(LOG_FILE, entry);
  } catch {
    // Silent fail
  }
});
