#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$(dirname "$SCRIPT_DIR")"

echo "Installing entity-plugin-symphony..."

if [ -d "$HOME/Code/symphony" ]; then
  DEST="$HOME/Code/symphony/elixir/lib/symphony_elixir/tracker/entity.ex"
  cp "$SOURCE_DIR/entity-plugin-symphony/entity.ex" "$DEST"
  echo "  → Copied entity.ex to $DEST"
else
  echo "  → Skipped: $HOME/Code/symphony not found"
  echo "    (Symphony not installed — install it first at https://github.com/h-mascot/openai-symphony)"
fi

echo "Done."
