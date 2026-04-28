#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENTITY_REPO="${ENTITY_REPO:-$HOME/Code/Entity}"
PROVIDER_DIR="$ENTITY_REPO/packages/server/src/swarm/providers"
echo "==> Installing entity-plugin-acp"
echo "    Entity repo: $ENTITY_REPO"
if [ ! -d "$PROVIDER_DIR" ]; then echo "ERROR: $PROVIDER_DIR not found"; exit 1; fi
cp "$SCRIPT_DIR/provider.ts" "$PROVIDER_DIR/acp.ts"
echo "    Copied acp.ts"
echo ""
echo "==> ACP provider installed. Restart Entity to load."
echo "    Set ACP_BASE_URL env var to configure the endpoint."
