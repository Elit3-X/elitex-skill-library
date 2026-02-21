#!/usr/bin/env node
// Spec Gate Hook (PostToolUse)
// Checks if a SPEC.md exists when Claude writes implementation code.
// Source: KB specification-bottleneck + builder-operating-system-2026
//
// Fires on Write tool use. If the file is code (not docs/config) and
// no spec exists in the git root, outputs a warning to stderr.

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const CODE_EXTENSIONS = new Set([
  '.ts', '.tsx', '.js', '.jsx', '.py', '.go', '.dart', '.rs',
  '.java', '.kt', '.swift', '.rb', '.php', '.vue', '.svelte'
]);

const SKIP_PATHS = [
  '/Obsidian Vault/',
  '/node_modules/',
  '/.claude/',
  '/dist/',
  '/build/',
  '/.next/'
];

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);

    // Only fire on Write tool
    if (data.tool_name !== 'Write') return;

    const filePath = data.tool_input?.file_path || data.tool_input?.filePath || '';
    if (!filePath) return;

    // Skip non-code files
    const ext = path.extname(filePath).toLowerCase();
    if (!CODE_EXTENSIONS.has(ext)) return;

    // Skip excluded paths
    if (SKIP_PATHS.some(p => filePath.includes(p))) return;

    // Find git root
    let gitRoot;
    try {
      gitRoot = execSync('git rev-parse --show-toplevel', {
        cwd: path.dirname(filePath),
        encoding: 'utf8',
        timeout: 3000
      }).trim();
    } catch {
      // Not a git repo — skip
      return;
    }

    // Check for spec files
    const specFiles = ['SPEC.md', 'spec.md', 'SPEC.txt', 'specs/'];
    const hasSpec = specFiles.some(f => {
      const target = path.join(gitRoot, f);
      return fs.existsSync(target);
    });

    if (!hasSpec) {
      process.stderr.write(
        '\n⚠ No SPEC.md found in project root. ' +
        'Specification-first development recommends writing a spec before implementation. ' +
        'Run: write-spec.sh "task description" or create SPEC.md manually.\n'
      );
    }
  } catch {
    // Silent fail — never break Claude Code
  }
});
