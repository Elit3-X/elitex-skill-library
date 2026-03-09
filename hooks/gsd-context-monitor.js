#!/usr/bin/env node
// Context Monitor - PostToolUse hook
// Reads context metrics from the statusline bridge file and injects
// warnings when context usage is high.
//
// NEW: Also handles auto-resume after compact by detecting fresh handoff.json
// when context usage is low (meaning a compact just happened).
//
// Flow:
//   1. Context hits CRITICAL → tells Claude to save handoff + vault note + /compact
//   2. After compact, context usage drops → hook detects fresh handoff.json
//   3. Injects handoff as additionalContext so Claude seamlessly resumes
//
// Thresholds:
//   WARNING  (remaining <= 35%): Agent should wrap up current task
//   CRITICAL (remaining <= 25%): Agent MUST save state and compact
//
// Debounce: 5 tool uses between warnings to avoid spam
// Severity escalation bypasses debounce (WARNING -> CRITICAL fires immediately)

const fs = require('fs');
const os = require('os');
const path = require('path');

const WARNING_THRESHOLD = 35;  // remaining_percentage <= 35%
const CRITICAL_THRESHOLD = 25; // remaining_percentage <= 25%
const STALE_SECONDS = 60;      // ignore metrics older than 60s
const DEBOUNCE_CALLS = 5;      // min tool uses between warnings
const HANDOFF_FRESH_SECONDS = 300; // handoff is "fresh" if < 5 min old
const RESUME_USED_THRESHOLD = 40;  // context used < 40% = likely post-compact

const homeDir = os.homedir();
const HANDOFF_FILE = path.join(homeDir, '.claude', 'cache', 'handoff.json');

let input = '';
const stdinTimeout = setTimeout(() => process.exit(0), 3000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    const data = JSON.parse(input);
    const sessionId = data.session_id;

    if (!sessionId) {
      process.exit(0);
    }

    const tmpDir = os.tmpdir();
    const metricsPath = path.join(tmpDir, `claude-ctx-${sessionId}.json`);

    // If no metrics file, this is a subagent or fresh session -- exit silently
    if (!fs.existsSync(metricsPath)) {
      process.exit(0);
    }

    const metrics = JSON.parse(fs.readFileSync(metricsPath, 'utf8'));
    const now = Math.floor(Date.now() / 1000);

    // Ignore stale metrics
    if (metrics.timestamp && (now - metrics.timestamp) > STALE_SECONDS) {
      process.exit(0);
    }

    const remaining = metrics.remaining_percentage;
    const usedPct = metrics.used_pct;

    // ── Post-Compact Resume Detection ──────────────────────────
    // If context usage is low AND a fresh handoff.json exists AND we previously
    // hit CRITICAL, inject resume context and clear the handoff.
    const resumeFlagPath = path.join(tmpDir, `claude-ctx-${sessionId}-resumed.json`);
    const warnPath = path.join(tmpDir, `claude-ctx-${sessionId}-warned.json`);

    if (usedPct < RESUME_USED_THRESHOLD && fs.existsSync(HANDOFF_FILE)) {
      try {
        const handoffStat = fs.statSync(HANDOFF_FILE);
        const handoffAgeSec = (Date.now() - handoffStat.mtimeMs) / 1000;
        const handoffContent = JSON.parse(fs.readFileSync(HANDOFF_FILE, 'utf8'));

        // Only inject if handoff is fresh, non-empty, and we haven't already resumed
        const alreadyResumed = fs.existsSync(resumeFlagPath);
        const handoffHasContent = handoffContent && Object.keys(handoffContent).length > 0
          && JSON.stringify(handoffContent) !== '{}';

        if (handoffAgeSec < HANDOFF_FRESH_SECONDS && handoffHasContent && !alreadyResumed) {
          // Mark as resumed so we don't inject again
          fs.writeFileSync(resumeFlagPath, JSON.stringify({ timestamp: now, session: sessionId }));

          // Clear warned state since we're post-compact
          if (fs.existsSync(warnPath)) fs.unlinkSync(warnPath);

          // Build resume context
          const h = handoffContent;
          const resumeMsg =
            'CONTEXT RESUMED: A compact just occurred. Here is your saved state from before the compact:\n\n' +
            `- **Task**: ${h.task || 'unknown'}\n` +
            `- **Progress**: ${h.progress || 'unknown'}\n` +
            `- **Remaining work**: ${h.remaining || 'unknown'}\n` +
            `- **Files touched**: ${h.files_touched || 'unknown'}\n` +
            `- **Blockers**: ${h.blockers || 'none'}\n` +
            `- **Git state**: ${h.git_state || 'unknown'}\n\n` +
            'Continue from where you left off. Do NOT re-read files you already read unless necessary. ' +
            'Pick up the remaining work items and proceed.';

          const output = {
            hookSpecificOutput: {
              hookEventName: 'PostToolUse',
              additionalContext: resumeMsg
            }
          };

          process.stdout.write(JSON.stringify(output));
          process.exit(0);
        }
      } catch (e) {
        // Handoff file corrupted or unreadable, continue with normal monitoring
      }
    }

    // ── Normal Context Monitoring ──────────────────────────────
    // No warning needed
    if (remaining > WARNING_THRESHOLD) {
      process.exit(0);
    }

    // Debounce: check if we warned recently
    let warnData = { callsSinceWarn: 0, lastLevel: null };
    let firstWarn = true;

    if (fs.existsSync(warnPath)) {
      try {
        warnData = JSON.parse(fs.readFileSync(warnPath, 'utf8'));
        firstWarn = false;
      } catch (e) {
        // Corrupted file, reset
      }
    }

    warnData.callsSinceWarn = (warnData.callsSinceWarn || 0) + 1;

    const isCritical = remaining <= CRITICAL_THRESHOLD;
    const currentLevel = isCritical ? 'critical' : 'warning';

    // Emit immediately on first warning, then debounce subsequent ones
    // Severity escalation (WARNING -> CRITICAL) bypasses debounce
    const severityEscalated = currentLevel === 'critical' && warnData.lastLevel === 'warning';
    if (!firstWarn && warnData.callsSinceWarn < DEBOUNCE_CALLS && !severityEscalated) {
      fs.writeFileSync(warnPath, JSON.stringify(warnData));
      process.exit(0);
    }

    // Reset debounce counter
    warnData.callsSinceWarn = 0;
    warnData.lastLevel = currentLevel;
    fs.writeFileSync(warnPath, JSON.stringify(warnData));

    // Clear any previous resume flag since we're heading toward a new compact cycle
    if (fs.existsSync(resumeFlagPath)) {
      try { fs.unlinkSync(resumeFlagPath); } catch (e) {}
    }

    // Detect context
    const cwd = data.cwd || process.cwd();
    const isGsdActive = fs.existsSync(path.join(cwd, '.planning', 'STATE.md'));
    const isAgentLoop = !!process.env.INFINITE_AGENT || fs.existsSync('/tmp/infinite-agent.pid');

    let message;
    if (isCritical) {
      // Universal CRITICAL message — works for ALL sessions (agent loop, GSD, or plain)
      const handoffInstructions =
        'Context is nearly exhausted. You MUST do the following NOW:\n\n' +
        '1. **Save handoff state** — write `~/.claude/cache/handoff.json` with:\n' +
        '   ```json\n' +
        '   {"task":"<current task>","progress":"<what you completed>","remaining":"<what is left>","files_touched":"<key files>","blockers":"<any blockers>","git_state":"<branch and last commit>"}\n' +
        '   ```\n' +
        '2. **Write a vault note** — save session summary to `~/Documents/Obsidian Vault/Projects/{project}/`\n' +
        '3. **Commit uncommitted work** if any: `git add <files> && git commit -m "wip: <summary>"`\n' +
        '4. **Run `/compact`** to compress context and continue working\n\n' +
        'Do this NOW. Do not start any new work until you have saved state and compacted.';

      if (isAgentLoop) {
        message = `CONTEXT CRITICAL: Usage at ${usedPct}%. Remaining: ${remaining}%. ` +
          'You are in an Infinite Agent Loop. ' + handoffInstructions +
          '\n\nAfter saving, create `.agent-done` with "HANDOFF" instead of running /compact.';
      } else {
        message = `CONTEXT CRITICAL: Usage at ${usedPct}%. Remaining: ${remaining}%. ` +
          handoffInstructions;
      }
    } else {
      // WARNING level
      message = isGsdActive
        ? `CONTEXT WARNING: Usage at ${usedPct}%. Remaining: ${remaining}%. ` +
          'Context is getting limited. Wrap up current work step. Prepare to save state soon.'
        : `CONTEXT WARNING: Usage at ${usedPct}%. Remaining: ${remaining}%. ` +
          'Context is getting limited. Wrap up current work. Avoid starting new complex tasks. ' +
          'Prepare to save state to handoff.json soon.';
    }

    const output = {
      hookSpecificOutput: {
        hookEventName: process.env.GEMINI_API_KEY ? 'AfterTool' : 'PostToolUse',
        additionalContext: message
      }
    };

    process.stdout.write(JSON.stringify(output));
  } catch (e) {
    // Silent fail -- never block tool execution
    process.exit(0);
  }
});
