#!/bin/bash

# Antigravity Skill Library Installer
# Installs skills, hooks, scripts, and commands into Claude Code / Antigravity directories.

set -e

SKILLS_DIR="$HOME/.antigravity/skills"
CLAUDE_SKILLS="$HOME/.claude/skills"
CLAUDE_HOOKS="$HOME/.claude/hooks"
CLAUDE_SCRIPTS="$HOME/.claude/scripts"
CLAUDE_COMMANDS="$HOME/.claude/commands"
CLAUDE_LOGS="$HOME/.claude/logs"

echo "Starting Antigravity Skill Library installation..."

# Create directories
mkdir -p "$SKILLS_DIR" "$CLAUDE_SKILLS" "$CLAUDE_HOOKS" "$CLAUDE_SCRIPTS" "$CLAUDE_COMMANDS" "$CLAUDE_LOGS"

# Clone if not running from within the repo
if [ ! -d "skills" ]; then
    echo "Cloning skill library..."
    TEMP_DIR=$(mktemp -d)
    git clone --depth 1 https://github.com/Elit3-X/antigravity-skill-library.git "$TEMP_DIR"
    cd "$TEMP_DIR"
fi

# Install skills
if [ -d "skills" ]; then
    echo "Installing skills..."
    cp -R skills/* "$SKILLS_DIR/" 2>/dev/null || true
    cp -R skills/* "$CLAUDE_SKILLS/" 2>/dev/null || true
    SKILL_COUNT=$(ls -1d skills/*/ 2>/dev/null | wc -l | xargs)
    echo "  $SKILL_COUNT skills installed"
fi

# Install hooks
if [ -d "hooks" ]; then
    echo "Installing hooks..."
    cp hooks/* "$CLAUDE_HOOKS/" 2>/dev/null || true
    HOOK_COUNT=$(ls -1 hooks/ 2>/dev/null | wc -l | xargs)
    echo "  $HOOK_COUNT hooks installed"
fi

# Install scripts
if [ -d "scripts" ]; then
    echo "Installing scripts..."
    cp scripts/* "$CLAUDE_SCRIPTS/" 2>/dev/null || true
    chmod +x "$CLAUDE_SCRIPTS"/*.sh 2>/dev/null || true
    SCRIPT_COUNT=$(ls -1 scripts/ 2>/dev/null | wc -l | xargs)
    echo "  $SCRIPT_COUNT scripts installed"
fi

# Install commands
if [ -d "commands" ]; then
    echo "Installing commands..."
    cp commands/* "$CLAUDE_COMMANDS/" 2>/dev/null || true
    CMD_COUNT=$(ls -1 commands/ 2>/dev/null | wc -l | xargs)
    echo "  $CMD_COUNT commands installed"
fi

echo ""
echo "Installation complete."
echo ""
echo "To activate hooks, add to ~/.claude/settings.json:"
echo '  "hooks": {'
echo '    "PostToolUse": [{"matcher": "Write", "hooks": [{"type": "command", "command": "node ~/.claude/hooks/spec-gate.js"}]}],'
echo '    "Stop": [{"hooks": [{"type": "command", "command": "node ~/.claude/hooks/productization-tracker.js"}]}]'
echo '  }'
echo ""
echo "Scripts available:"
echo "  ~/.claude/scripts/write-spec.sh \"task description\""
echo "  ~/.claude/scripts/scenario-suite.sh"
