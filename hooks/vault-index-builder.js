#!/usr/bin/env node
// Vault Index Builder - SessionStart hook
// Walks Obsidian Vault directories and builds a JSON index for other hooks
// Spawns detached child process, writes to ~/.claude/cache/vault-index.json

const fs = require('fs');
const path = require('path');
const os = require('os');
const { spawn } = require('child_process');

const homeDir = os.homedir();
const cacheDir = path.join(homeDir, '.claude', 'cache');

// Ensure cache directory exists
if (!fs.existsSync(cacheDir)) {
  fs.mkdirSync(cacheDir, { recursive: true });
}

const cacheFile = path.join(cacheDir, 'vault-index.json');

const child = spawn(process.execPath, ['-e', `
  const fs = require('fs');
  const path = require('path');

  const vaultBase = ${JSON.stringify(path.join(homeDir, 'Documents', 'Obsidian Vault'))};
  const projectsDir = path.join(vaultBase, 'Projects');
  const inboxDir = path.join(vaultBase, 'Inbox');
  const cacheFile = ${JSON.stringify(cacheFile)};

  function parseFrontmatter(content) {
    const match = content.match(/^---\\n([\\s\\S]*?)\\n---/);
    if (!match) return {};
    const fm = {};
    const lines = match[1].split('\\n');
    for (const line of lines) {
      const m = line.match(/^(\\w+):\\s*(.+)/);
      if (!m) continue;
      const key = m[1];
      let val = m[2].trim();
      // Parse arrays like [a, b, c]
      if (val.startsWith('[') && val.endsWith(']')) {
        val = val.slice(1, -1).split(',').map(s => s.trim().replace(/^["']|["']$/g, ''));
      }
      // Strip quotes
      if (typeof val === 'string') {
        val = val.replace(/^["']|["']$/g, '');
      }
      fm[key] = val;
    }
    return fm;
  }

  function walkDir(dir, results, opts) {
    if (!fs.existsSync(dir)) return;
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        // Skip Knowledge-Base subdirs except Frameworks
        if (opts && opts.skipKB) {
          const rel = path.relative(projectsDir, fullPath);
          if (rel.startsWith('Knowledge-Base')) {
            if (rel === 'Knowledge-Base' || rel.startsWith('Knowledge-Base/Frameworks')) {
              // Allow walking into Knowledge-Base root (for _index.md) and Frameworks
              walkDir(fullPath, results, opts);
            }
            // Skip all other Knowledge-Base subdirs
            continue;
          }
        }
        walkDir(fullPath, results, opts);
      } else if (entry.name.endsWith('.md')) {
        // For Knowledge-Base, only include _index.md and Frameworks/*.md
        if (opts && opts.skipKB) {
          const rel = path.relative(projectsDir, fullPath);
          if (rel.startsWith('Knowledge-Base/') && rel !== 'Knowledge-Base/_index.md' && !rel.startsWith('Knowledge-Base/Frameworks/')) {
            continue;
          }
        }
        results.push(fullPath);
      }
    }
  }

  try {
    const projectFiles = [];
    walkDir(projectsDir, projectFiles, { skipKB: true });

    const inboxFiles = [];
    walkDir(inboxDir, inboxFiles, {});

    const projects = {};
    const frameworks = [];
    let totalNotes = 0;

    for (const filePath of projectFiles) {
      try {
        const content = fs.readFileSync(filePath, 'utf8');
        const stat = fs.statSync(filePath);
        const fm = parseFrontmatter(content);
        const title = path.basename(filePath, '.md');
        const modified = stat.mtime.toISOString().split('T')[0];
        const rel = path.relative(projectsDir, filePath);

        // Frameworks go to separate array
        if (rel.startsWith('Knowledge-Base/Frameworks/')) {
          frameworks.push({ title, path: filePath });
          totalNotes++;
          continue;
        }
        if (rel === 'Knowledge-Base/_index.md') {
          frameworks.push({ title, path: filePath });
          totalNotes++;
          continue;
        }

        // Determine project name from frontmatter or directory
        const projectName = fm.project || rel.split('/')[0].toLowerCase();
        if (!projects[projectName]) projects[projectName] = [];
        projects[projectName].push({
          title,
          path: filePath,
          tags: Array.isArray(fm.tags) ? fm.tags : (fm.tags ? [fm.tags] : []),
          status: fm.status || '',
          modified
        });
        totalNotes++;
      } catch (e) {}
    }

    const inbox = [];
    for (const filePath of inboxFiles) {
      try {
        const stat = fs.statSync(filePath);
        const title = path.basename(filePath, '.md');
        const created = stat.birthtime.toISOString().split('T')[0];
        inbox.push({ title, path: filePath, created });
        totalNotes++;
      } catch (e) {}
    }

    const index = {
      built: new Date().toISOString(),
      projects,
      inbox,
      frameworks,
      stats: {
        total_notes: totalNotes,
        projects: Object.keys(projects).length,
        inbox_pending: inbox.length,
        frameworks: frameworks.length
      }
    };

    fs.writeFileSync(cacheFile, JSON.stringify(index, null, 2));
  } catch (e) {
    // Silent fail
  }
`], {
  stdio: 'ignore',
  windowsHide: true,
  detached: true
});

child.unref();
