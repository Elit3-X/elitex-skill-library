#!/usr/bin/env node
// Handoff Resume Loader - SessionStart hook
// If a fresh handoff.json exists from a previous session, inject it as
// additionalContext so Claude can resume seamlessly.

const fs = require('fs');
const path = require('path');
const os = require('os');

const homeDir = os.homedir();
const HANDOFF_FILE = path.join(homeDir, '.claude', 'cache', 'handoff.json');
const HANDOFF_MAX_AGE_HOURS = 24; // ignore handoffs older than 24h

let input = '';
const stdinTimeout = setTimeout(() => process.exit(0), 3000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    if (!fs.existsSync(HANDOFF_FILE)) {
      process.exit(0);
    }

    const stat = fs.statSync(HANDOFF_FILE);
    const ageHours = (Date.now() - stat.mtimeMs) / (1000 * 60 * 60);

    if (ageHours > HANDOFF_MAX_AGE_HOURS) {
      process.exit(0);
    }

    const content = JSON.parse(fs.readFileSync(HANDOFF_FILE, 'utf8'));

    // Skip empty handoffs
    if (!content || Object.keys(content).length === 0 || JSON.stringify(content) === '{}') {
      process.exit(0);
    }

    const h = content;
    const ageMin = Math.round(ageHours * 60);
    const resumeMsg =
      `HANDOFF FROM PREVIOUS SESSION (${ageMin} min ago):\n\n` +
      `- **Task**: ${h.task || 'unknown'}\n` +
      `- **Progress**: ${h.progress || 'unknown'}\n` +
      `- **Remaining work**: ${h.remaining || 'unknown'}\n` +
      `- **Files touched**: ${h.files_touched || 'unknown'}\n` +
      `- **Blockers**: ${h.blockers || 'none'}\n` +
      `- **Git state**: ${h.git_state || 'unknown'}\n\n` +
      'A previous session saved this handoff. Offer to resume this work if the user\'s request is related, ' +
      'or proceed with their new request if unrelated.';

    const output = {
      hookSpecificOutput: {
        hookEventName: 'SessionStart',
        additionalContext: resumeMsg
      }
    };

    process.stdout.write(JSON.stringify(output));
  } catch (e) {
    process.exit(0);
  }
});
