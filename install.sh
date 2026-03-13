#!/bin/bash
# EliteX Skill Library Installer
# Syncs skills, hooks, scripts, commands, and global config to ~/.claude/

set -e

CLAUDE_DIR="$HOME/.claude"
REPO_URL="https://github.com/Elit3-X/elitex-skill-library.git"

echo "EliteX Skill Library — Installing..."

# Create directories
mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/scripts" "$CLAUDE_DIR/commands" "$CLAUDE_DIR/agents" "$CLAUDE_DIR/teams" "$CLAUDE_DIR/logs"

# Clone if not running from within the repo
REPO_DIR="."
if [ ! -d "skills" ]; then
    REPO_DIR=$(mktemp -d)
    git clone --depth 1 "$REPO_URL" "$REPO_DIR"
    cd "$REPO_DIR"
fi

# Skills
if [ -d "skills" ]; then
    echo "  Skills..."
    cp -R skills/* "$CLAUDE_DIR/skills/"
    echo "    $(ls -1d skills/*/ 2>/dev/null | wc -l | xargs) skills"
fi

# Hooks
if [ -d "hooks" ]; then
    echo "  Hooks..."
    cp hooks/* "$CLAUDE_DIR/hooks/"
    echo "    $(ls -1 hooks/ | wc -l | xargs) hooks"
fi

# Scripts
if [ -d "scripts" ]; then
    echo "  Scripts..."
    cp scripts/* "$CLAUDE_DIR/scripts/"
    chmod +x "$CLAUDE_DIR/scripts/"*.sh 2>/dev/null || true
    echo "    $(ls -1 scripts/ | wc -l | xargs) scripts"
fi

# Commands
if [ -d "commands" ]; then
    echo "  Commands..."
    cp commands/*.md "$CLAUDE_DIR/commands/" 2>/dev/null || true
    [ -d "commands/gsd" ] && cp -R commands/gsd "$CLAUDE_DIR/commands/gsd"
    echo "    $(find commands -name '*.md' | wc -l | xargs) commands"
fi

# Agents
if [ -d "agents" ]; then
    echo "  Agents..."
    cp -R agents/* "$CLAUDE_DIR/agents/"
    echo "    $(find agents -name '*.md' | wc -l | xargs) agent definitions"
fi

# GSD Framework
if [ -d "get-shit-done" ]; then
    echo "  GSD Framework..."
    cp -R get-shit-done "$CLAUDE_DIR/get-shit-done"
    echo "    $(ls -1 get-shit-done/workflows/ 2>/dev/null | wc -l | xargs) workflows"
fi

# Teams (don't overwrite existing)
if [ -d "teams" ]; then
    echo "  Teams..."
    for team_dir in teams/*/; do
        team_name=$(basename "$team_dir")
        if [ ! -d "$CLAUDE_DIR/teams/$team_name" ]; then
            cp -R "$team_dir" "$CLAUDE_DIR/teams/$team_name"
            echo "    + $team_name"
        else
            echo "    ~ $team_name (exists, skipped)"
        fi
    done
fi

# Global config
if [ -f "CLAUDE.md" ]; then
    if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
        echo "  CLAUDE.md exists — backing up to CLAUDE.md.bak"
        cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.bak"
    fi
    cp CLAUDE.md "$CLAUDE_DIR/CLAUDE.md"
fi

# Settings template (don't overwrite — user must merge manually)
if [ -f "settings.json.example" ] && [ ! -f "$CLAUDE_DIR/settings.json" ]; then
    cp settings.json.example "$CLAUDE_DIR/settings.json"
    echo "  settings.json installed (from template)"
elif [ -f "settings.json.example" ]; then
    echo "  settings.json exists — review settings.json.example for hook registration"
fi

# Cleanup temp dir
if [ "$REPO_DIR" != "." ]; then
    rm -rf "$REPO_DIR"
fi

echo ""
echo "Done. Restart Claude Code to pick up changes."
