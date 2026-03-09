#!/usr/bin/env node
// Vault Context Loader - SessionStart hook
// Detects current project from cwd, loads relevant vault notes into session context
// Spawns detached child process, writes to ~/.claude/cache/vault-session-context.json

const fs = require('fs');
const path = require('path');
const os = require('os');
const { spawn } = require('child_process');

const homeDir = os.homedir();
const cacheDir = path.join(homeDir, '.claude', 'cache');
const cwd = process.cwd();

// Ensure cache directory exists
if (!fs.existsSync(cacheDir)) {
  fs.mkdirSync(cacheDir, { recursive: true });
}

const indexFile = path.join(cacheDir, 'vault-index.json');
const contextFile = path.join(cacheDir, 'vault-session-context.json');

const child = spawn(process.execPath, ['-e', `
  const fs = require('fs');
  const path = require('path');

  const cwd = ${JSON.stringify(cwd)};
  const indexFile = ${JSON.stringify(indexFile)};
  const contextFile = ${JSON.stringify(contextFile)};

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
      if (pkg.name) return pkg.name.toLowerCase().replace(/^@[^/]+\\//, '');
    } catch (e) {}

    // Fallback: directory basename
    return path.basename(dir).toLowerCase();
  }

  try {
    // Wait briefly for vault-index-builder to finish (it runs in parallel)
    let attempts = 0;
    while (!fs.existsSync(indexFile) && attempts < 10) {
      const waitUntil = Date.now() + 200;
      while (Date.now() < waitUntil) {} // busy wait (no setTimeout in inline script)
      attempts++;
    }

    if (!fs.existsSync(indexFile)) {
      // No index yet, write minimal context
      fs.writeFileSync(contextFile, JSON.stringify({
        detected_project: detectProject(cwd),
        cwd,
        relevant_notes: [],
        inbox_pending: [],
        vault_stats: { total: 0, project_notes: 0 },
        generated: new Date().toISOString()
      }, null, 2));
      process.exit(0);
    }

    const index = JSON.parse(fs.readFileSync(indexFile, 'utf8'));
    const project = detectProject(cwd);

    // Find matching project notes
    let relevant = [];
    for (const [projName, notes] of Object.entries(index.projects || {})) {
      if (projName === project || projName.includes(project) || project.includes(projName)) {
        relevant = relevant.concat(notes);
      }
    }

    // Sort by modified date descending
    relevant.sort((a, b) => (b.modified || '').localeCompare(a.modified || ''));

    // Cap at 5
    relevant = relevant.slice(0, 5);

    const context = {
      detected_project: project,
      cwd,
      relevant_notes: relevant.map(n => ({
        title: n.title,
        path: n.path,
        tags: n.tags || [],
        modified: n.modified || ''
      })),
      inbox_pending: (index.inbox || []).map(n => ({
        title: n.title,
        path: n.path
      })),
      vault_stats: {
        total: index.stats ? index.stats.total_notes : 0,
        project_notes: relevant.length
      },
      generated: new Date().toISOString()
    };

    fs.writeFileSync(contextFile, JSON.stringify(context, null, 2));
  } catch (e) {
    // Silent fail
  }
`], {
  stdio: 'ignore',
  windowsHide: true,
  detached: true
});

child.unref();
