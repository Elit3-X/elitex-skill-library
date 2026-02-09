# Antigravity Skill Library

A consolidated collection of global and project-specific skills for the Antigravity and Claude agents.

## Contents

This repository contains skills gathered from:

- `~/.antigravity/skills/`
- `~/.claude/skills/`
- Project-specific `.agent/skills/` folders

## Installation

To install all these skills on a new machine or IDE:

### Method 1: Automated Script (Recommended)

Run the following command in your terminal:

```bash
curl -sSL https://raw.githubusercontent.com/acid9burn/antigravity-skill-library/main/install.sh | bash
```

### Method 2: Manual Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/acid9burn/antigravity-skill-library.git
   ```
2. Copy the skills to your global antigravity skills directory:
   ```bash
   mkdir -p ~/.antigravity/skills
   cp -R antigravity-skill-library/skills/* ~/.antigravity/skills/
   ```

## Contributing

Add new skills to the `skills/` directory and push your changes.
