#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$(dirname "$SCRIPT_DIR")"

echo "Installing entity-plugin-codex..."

if [ -d "$HOME/Code/Entity/packages/server/src/swarm/providers" ]; then
  DEST="$HOME/Code/Entity/packages/server/src/swarm/providers/codex.ts"
  cp "$SOURCE_DIR/entity-plugin-codex/codex.ts" "$DEST"
  echo "  → Copied codex.ts to $DEST"
else
  echo "  → Skipped: Entity not found at $HOME/Code/Entity"
fi

echo "Done."
