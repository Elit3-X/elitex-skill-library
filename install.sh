#!/bin/bash

# Antigravity Skill Library Installer
# This script installs skills into the default Antigravity/Claude skill directories.

set -e

SKILLS_DIR="$HOME/.antigravity/skills"
CLAUDE_DIR="$HOME/.claude/skills"

echo "🚀 Starting Antigravity Skill Library installation..."

# Create directories if they don't exist
mkdir -p "$SKILLS_DIR"
mkdir -p "$CLAUDE_DIR"

# Clone the temporary library if not running from within the repo
if [ ! -d "skills" ]; then
    echo "📥 Cloning skill library..."
    TEMP_DIR=$(mktemp -d)
    git clone --depth 1 https://github.com/acid9burn/antigravity-skill-library.git "$TEMP_DIR"
    cd "$TEMP_DIR"
fi

echo "📦 Copying skills to $SKILLS_DIR..."
cp -R skills/* "$SKILLS_DIR/"

echo "📦 Syncing skills to $CLAUDE_DIR..."
cp -R skills/* "$CLAUDE_DIR/"

echo "✅ Installation complete! Total skills installed: $(ls -1 skills | wc -l | xargs)"
echo "💡 You can now use these skills in your Antigravity or Claude sessions."
