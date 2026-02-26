#!/usr/bin/env bash
set -euo pipefail

# Sync skills from skills_project to aria-go
# Copies .claude/commands/*.md and .claude/agents/*.md

SRC="$(cd "$(dirname "$0")/../.." && pwd)"
DEST="/Users/nsmc/projects/nexus/aria-go"

if [ ! -d "$DEST/.claude" ]; then
  echo "Error: aria-go .claude directory not found at $DEST/.claude"
  exit 1
fi

echo "Syncing from $SRC -> $DEST"

# Sync commands
mkdir -p "$DEST/.claude/commands"
for f in "$SRC/.claude/commands/"*.md; do
  [ -f "$f" ] || continue
  name="$(basename "$f")"
  cp "$f" "$DEST/.claude/commands/$name"
  echo "  commands/$name"
done

# Sync agents
mkdir -p "$DEST/.claude/agents"
for f in "$SRC/.claude/agents/"*.md; do
  [ -f "$f" ] || continue
  name="$(basename "$f")"
  cp "$f" "$DEST/.claude/agents/$name"
  echo "  agents/$name"
done

echo "Done."
