#!/usr/bin/env node
// Auto-Resume Loop — Stop hook
// When a Claude session ends with a fresh handoff.json, automatically spawn
// infinite-agent.sh --resume to continue the work in a new session.
//
// This ensures context exhaustion never kills progress — every session that
// saves a handoff automatically gets a successor.
//
// Safety:
//   - Won't spawn if infinite-agent is already running
//   - Won't spawn if handoff.json is stale (> 5 min old)
//   - Won't spawn if handoff.json is empty
//   - Won't spawn if stop file exists (/tmp/infinite-agent-stop)
//   - Cooldown: won't respawn within 30s of last spawn

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawn } = require('child_process');

const homeDir = os.homedir();
const HANDOFF_FILE = path.join(homeDir, '.claude', 'cache', 'handoff.json');
const SCRIPT_PATH = path.join(homeDir, '.claude', 'scripts', 'infinite-agent.sh');
const PID_FILE = '/tmp/infinite-agent.pid';
const STOP_FILE = '/tmp/infinite-agent-stop';
const SPAWN_LOG = '/tmp/auto-resume-loop.log';
const LAST_SPAWN_FILE = '/tmp/auto-resume-last-spawn';

const FRESH_SECONDS = 300;     // handoff must be < 5 min old
const COOLDOWN_SECONDS = 30;   // min time between spawns

function log(msg) {
  const ts = new Date().toISOString();
  try {
    fs.appendFileSync(SPAWN_LOG, `[${ts}] ${msg}\n`);
  } catch (e) {}
}

function main() {
  try {
    // Don't spawn if stop file exists
    if (fs.existsSync(STOP_FILE)) {
      log('Stop file exists, skipping');
      return;
    }

    // Don't spawn if already running
    if (fs.existsSync(PID_FILE)) {
      try {
        const pid = parseInt(fs.readFileSync(PID_FILE, 'utf8').trim());
        if (pid > 0) {
          try {
            process.kill(pid, 0); // check if alive
            log(`Already running (PID ${pid}), skipping`);
            return;
          } catch (e) {
            // PID is dead, clean up stale file
            log(`Stale PID file (PID ${pid} dead), cleaning up`);
            fs.unlinkSync(PID_FILE);
          }
        }
      } catch (e) {
        // Corrupt PID file, remove it
        try { fs.unlinkSync(PID_FILE); } catch (e2) {}
      }
    }

    // Cooldown check
    if (fs.existsSync(LAST_SPAWN_FILE)) {
      try {
        const lastSpawn = parseInt(fs.readFileSync(LAST_SPAWN_FILE, 'utf8').trim());
        const elapsed = Math.floor(Date.now() / 1000) - lastSpawn;
        if (elapsed < COOLDOWN_SECONDS) {
          log(`Cooldown active (${elapsed}s < ${COOLDOWN_SECONDS}s), skipping`);
          return;
        }
      } catch (e) {}
    }

    // Check handoff.json exists and is fresh
    if (!fs.existsSync(HANDOFF_FILE)) {
      log('No handoff.json, skipping');
      return;
    }

    const stat = fs.statSync(HANDOFF_FILE);
    const ageSec = (Date.now() - stat.mtimeMs) / 1000;
    if (ageSec > FRESH_SECONDS) {
      log(`Handoff is stale (${Math.round(ageSec)}s old), skipping`);
      return;
    }

    // Check handoff has content
    const content = JSON.parse(fs.readFileSync(HANDOFF_FILE, 'utf8'));
    if (!content || Object.keys(content).length === 0 || !content.task) {
      log('Handoff is empty, skipping');
      return;
    }

    // Check script exists
    if (!fs.existsSync(SCRIPT_PATH)) {
      log(`Script not found: ${SCRIPT_PATH}`);
      return;
    }

    // Record spawn time
    fs.writeFileSync(LAST_SPAWN_FILE, String(Math.floor(Date.now() / 1000)));

    // Spawn infinite-agent.sh --resume in background
    log(`Spawning infinite-agent.sh --resume for task: ${content.task}`);
    const child = spawn('bash', [SCRIPT_PATH, '--resume'], {
      detached: true,
      stdio: 'ignore',
      env: { ...process.env, INFINITE_AGENT: '1' }
    });
    child.unref();
    log(`Spawned with PID ${child.pid}`);
  } catch (e) {
    log(`Error: ${e.message}`);
  }
}

// Read stdin (required by hook protocol) but we don't need the data
let input = '';
const timeout = setTimeout(() => { main(); process.exit(0); }, 3000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  clearTimeout(timeout);
  main();
  process.exit(0);
});
