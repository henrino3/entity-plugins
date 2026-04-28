#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing entity-plugin-eforge..."

# Verify eforge is installed
if ! command -v /opt/homebrew/bin/eforge &> /dev/null; then
  echo "  ✗ eforge not found at /opt/homebrew/bin/eforge"
  echo "    Install: npm install -g @openai/eforge"
  exit 1
fi

# Verify eforge daemon is running on port 4567
if ! curl -s --max-time 2 http://localhost:4567/health &>/dev/null; then
  echo "  ! eforge daemon not reachable at localhost:4567"
  echo "    Run: /opt/homebrew/bin/eforge daemon start"
fi

echo "  → eforge: /opt/homebrew/bin/eforge"
echo "  → health: http://localhost:4567/health"
echo "Done."
