#!/usr/bin/env bash
# KB Ingest - Automated Knowledge Base ingestion pipeline
# Usage: kb-ingest.sh <transcript.json> [source-name]
#
# Takes a YouTube transcript JSON and:
# 1. Preprocesses it (clean, join segments, categorize)
# 2. Dispatches Claude Code to extract knowledge
# 3. Adds notes to the Obsidian Knowledge Base

set -euo pipefail

INPUT_FILE="${1:?Usage: kb-ingest.sh <transcript.json> [source-name]}"
SOURCE_NAME="${2:-Unknown}"
KB_BASE="$HOME/Documents/Obsidian Vault/Projects/Knowledge-Base"
PREPROCESS_DIR="/tmp/kb_ingest_$(date +%s)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${YELLOW}[kb-ingest]${NC} $1"; }

# Validate input
if [ ! -f "$INPUT_FILE" ]; then
    echo -e "${RED}Error: File not found: $INPUT_FILE${NC}"
    exit 1
fi

# Check it's valid JSON
if ! python3 -c "import json; json.load(open('$INPUT_FILE'))" 2>/dev/null; then
    echo -e "${RED}Error: Invalid JSON: $INPUT_FILE${NC}"
    exit 1
fi

log "Input: $INPUT_FILE"
log "Source: $SOURCE_NAME"

# Step 1: Preprocess
log "Preprocessing transcripts..."

python3 -c "
import json, os, re

INPUT = '$INPUT_FILE'
OUTPUT_DIR = '$PREPROCESS_DIR'
os.makedirs(OUTPUT_DIR, exist_ok=True)

AD_PATTERNS = [
    r'(?i)sponsored by', r'(?i)use my (link|code|coupon)', r'(?i)promo code',
    r'(?i)link in the description', r'(?i)like and subscribe', r'(?i)hit the bell',
    r'(?i)thanks for watching', r'(?i)don.t forget to subscribe',
    r'(?i)join my', r'(?i)patreon', r'(?i)free community',
]

def clean_text(segments):
    parts = []
    for seg in segments:
        text = seg.get('text', '').strip()
        if not text: continue
        if any(re.search(p, text) for p in AD_PATTERNS): continue
        parts.append(text)
    full = ' '.join(parts)
    full = re.sub(r'\s+', ' ', full)
    full = re.sub(r'(?i)\[music\]', '', full)
    return full.strip()

def slugify(title):
    slug = title.lower()
    slug = re.sub(r'[^a-z0-9\s-]', '', slug)
    slug = re.sub(r'[\s]+', '-', slug)
    slug = re.sub(r'-+', '-', slug).strip('-')
    return slug[:80]

with open(INPUT) as f:
    data = json.load(f)

manifest = []
for i, video in enumerate(data.get('videos', [])):
    idx = i + 1
    clean = clean_text(video.get('segments', []))
    entry = {
        'index': idx,
        'title': video.get('title', ''),
        'url': video.get('url', ''),
        'video_id': video.get('id', ''),
        'slug': slugify(video.get('title', '')),
        'char_count': len(clean),
        'is_short': len(clean) <= 3000,
        'text': clean,
    }
    with open(os.path.join(OUTPUT_DIR, f'{idx:02d}.json'), 'w') as f:
        json.dump(entry, f, indent=2)
    manifest.append({k: v for k, v in entry.items() if k != 'text'})

with open(os.path.join(OUTPUT_DIR, 'manifest.json'), 'w') as f:
    json.dump(manifest, f, indent=2)

total = len(manifest)
shorts = sum(1 for m in manifest if m['is_short'])
print(f'Preprocessed {total} videos ({total - shorts} long-form, {shorts} shorts)')
"

log "Preprocessed to: $PREPROCESS_DIR"

# Step 2: Count videos
TOTAL=$(python3 -c "import json; print(len(json.load(open('$PREPROCESS_DIR/manifest.json'))))")
log "Total videos: $TOTAL"

# Step 3: Launch Claude Code extraction
log "Launching Claude Code extraction..."

PROMPT="Process all videos in $PREPROCESS_DIR/ and write structured Obsidian notes to $KB_BASE/.

For each video JSON file:
1. Read the JSON (has fields: title, url, video_id, slug, text, is_short)
2. Skip if is_short is true
3. Determine category folder based on content
4. Write a structured note with frontmatter (source: \"$SOURCE_NAME\"), Core Thesis, Key Insights, Systems & Workflows, Frameworks, Actionable Takeaways, Tool Stack, Raw Signal, Connections sections

Create any needed category subdirectories. Strip ads and filler from text.
When done, report how many notes were created."

echo "$PROMPT" | claude --print 2>&1

log "${GREEN}Ingestion complete${NC}"
log "Check: $KB_BASE/"

# Cleanup
rm -rf "$PREPROCESS_DIR"
