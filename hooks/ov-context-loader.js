#!/usr/bin/env node
// OpenViking Context Loader - SessionStart hook
// Queries OpenViking for project-relevant context and writes to cache
// Claude reads this cache via CLAUDE.md instructions

const fs = require('fs');
const path = require('path');
const os = require('os');

const homeDir = os.homedir();
const cacheDir = path.join(homeDir, '.claude', 'cache');
const cwd = process.cwd();
const contextFile = path.join(cacheDir, 'ov-session-context.json');

if (!fs.existsSync(cacheDir)) fs.mkdirSync(cacheDir, { recursive: true });

// Detect project name from cwd
function detectProject(dir) {
  const lower = dir.toLowerCase();
  if (lower.includes('zenapply') || lower.includes('applyeu')) return 'zenapply';
  if (lower.includes('kaufdahoam')) return 'kaufdahoam';
  if (lower.includes('veliano')) return 'veliano';
  if (lower.includes('komotel')) return 'komotel';
  if (lower.includes('baukasten')) return 'baukasten-it';
  if (lower.includes('elitex') || lower.includes('elite-x')) return 'elitex';
  return path.basename(dir).toLowerCase();
}

const project = detectProject(cwd);

async function loadContext() {
  const OV_URL = process.env.OPENVIKING_URL || 'http://localhost:1933';

  try {
    // Health check
    const health = await fetch(`${OV_URL}/health`);
    if (!health.ok) throw new Error('OV server not running');

    // Search for project-relevant context
    const searchRes = await fetch(`${OV_URL}/api/v1/search/search`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ query: `${project} architecture overview current state`, limit: 8 })
    });

    const searchData = await searchRes.json();
    const results = [
      ...(searchData.result?.memories || []),
      ...(searchData.result?.resources || [])
    ].map(r => ({
      uri: r.uri,
      type: r.context_type,
      score: r.score,
      abstract: (r.abstract || '').substring(0, 300)
    }));

    const context = {
      project,
      cwd,
      ov_status: 'connected',
      ov_url: OV_URL,
      top_results: results,
      generated: new Date().toISOString()
    };

    fs.writeFileSync(contextFile, JSON.stringify(context, null, 2));
  } catch (e) {
    // OV not running — write minimal context so Claude knows
    fs.writeFileSync(contextFile, JSON.stringify({
      project,
      cwd,
      ov_status: 'offline',
      ov_url: 'http://localhost:1933',
      top_results: [],
      error: e.message,
      generated: new Date().toISOString()
    }, null, 2));
  }
}

loadContext();
