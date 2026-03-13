#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# Entity Linker — Installer
#
# Installs the Entity Linker Discord listener on any OpenClaw agent.
# Rewrites local file paths (~/clawd/...) to Entity HTTP URLs in Discord.
#
# Usage:
#   ./install.sh
#   ENTITY_OUTPUT_BASE_URL=https://my-entity.example/output ./install.sh
#
# Requirements:
#   - Node.js 18+
#   - Discord bot token (reads from OpenClaw config or prompts)
#   - systemd (user services)
# ──────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${ENTITY_LINKER_DIR:-$HOME/clawd/entity-linker}"
SERVICE_NAME="entity-linker"
SERVICE_FILE="$HOME/.config/systemd/user/${SERVICE_NAME}.service"

echo "╔══════════════════════════════════════════╗"
echo "║   Entity Linker — Discord Path Rewriter  ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── 1. Detect Node.js ────────────────────────────────────────────────────────
if ! command -v node &>/dev/null; then
  echo "❌ Node.js not found. Install Node.js 18+ first."
  exit 1
fi

NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
  echo "❌ Node.js 18+ required (found v$(node -v))"
  exit 1
fi
echo "✅ Node.js $(node -v)"

# ── 2. Copy files to install dir ─────────────────────────────────────────────
if [ "$SCRIPT_DIR" != "$INSTALL_DIR" ]; then
  echo "📁 Installing to $INSTALL_DIR..."
  mkdir -p "$INSTALL_DIR/src"
  cp "$SCRIPT_DIR/discord-listener.js" "$INSTALL_DIR/"
  cp "$SCRIPT_DIR/package.json" "$INSTALL_DIR/"
  cp "$SCRIPT_DIR/src/rewrite-paths.js" "$INSTALL_DIR/src/"
  cp "$SCRIPT_DIR/src/rewrite-paths.test.js" "$INSTALL_DIR/src/"
  cp "$SCRIPT_DIR/install.sh" "$INSTALL_DIR/"
else
  echo "📁 Running from install dir: $INSTALL_DIR"
fi

# ── 3. Install dependencies ──────────────────────────────────────────────────
echo "📦 Installing npm dependencies..."
cd "$INSTALL_DIR"
npm install --production --silent 2>&1 | tail -2

# ── 4. Run tests ──────────────────────────────────────────────────────────────
echo "🧪 Running tests..."
if node --test src/rewrite-paths.test.js 2>&1 | grep -q "fail 0"; then
  echo "✅ All tests passed"
else
  echo "⚠️  Some tests failed — continuing anyway"
fi

# ── 5. Resolve Discord bot token ─────────────────────────────────────────────
ENV_FILE="$INSTALL_DIR/.env"
DISCORD_TOKEN=""

# Try OpenClaw config first
OPENCLAW_CONFIG="$HOME/.openclaw/openclaw.json"
if [ -f "$OPENCLAW_CONFIG" ]; then
  DISCORD_TOKEN=$(node -e '
    const fs = require("fs");
    try {
      const cfg = JSON.parse(fs.readFileSync("'"$OPENCLAW_CONFIG"'", "utf8"));
      const token = cfg.channels?.discord?.token || "";
      if (token) process.stdout.write(token);
    } catch {}
  ' 2>/dev/null || true)
fi

# Try existing .env
if [ -z "$DISCORD_TOKEN" ] && [ -f "$ENV_FILE" ]; then
  DISCORD_TOKEN=$(grep "^DISCORD_BOT_TOKEN=" "$ENV_FILE" 2>/dev/null | cut -d= -f2- || true)
fi

# Try environment variable
if [ -z "$DISCORD_TOKEN" ] && [ -n "${DISCORD_BOT_TOKEN:-}" ]; then
  DISCORD_TOKEN="$DISCORD_BOT_TOKEN"
fi

# Prompt if still missing
if [ -z "$DISCORD_TOKEN" ]; then
  echo ""
  echo "🔑 Discord bot token not found in OpenClaw config."
  read -rsp "   Enter your Discord bot token: " DISCORD_TOKEN
  echo ""
fi

if [ -z "$DISCORD_TOKEN" ]; then
  echo "❌ No Discord bot token provided. Exiting."
  exit 1
fi
echo "✅ Discord bot token configured"

# ── 6. Resolve Entity base URL ───────────────────────────────────────────────
ENTITY_URL="${ENTITY_OUTPUT_BASE_URL:-}"
if [ -z "$ENTITY_URL" ]; then
  # Try to detect from Entity server
  ENTITY_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "")
  if [ -n "$ENTITY_IP" ]; then
    ENTITY_URL="http://${ENTITY_IP}:3000/output/"
  else
    ENTITY_URL="http://localhost:3000/output/"
  fi
fi
echo "🌐 Entity URL: $ENTITY_URL"

# ── 7. Resolve guild IDs ─────────────────────────────────────────────────────
GUILD_IDS="${MONITOR_GUILD_IDS:-}"
if [ -z "$GUILD_IDS" ] && [ -f "$OPENCLAW_CONFIG" ]; then
  GUILD_IDS=$(node -e '
    const fs = require("fs");
    try {
      const cfg = JSON.parse(fs.readFileSync("'"$OPENCLAW_CONFIG"'", "utf8"));
      const guilds = cfg.channels?.discord?.guilds || {};
      const ids = Object.keys(guilds).filter(k => k.match(/^\d+$/));
      if (ids.length) process.stdout.write(ids.join(","));
    } catch {}
  ' 2>/dev/null || true)
fi
if [ -n "$GUILD_IDS" ]; then
  echo "🏠 Monitoring guilds: $GUILD_IDS"
else
  echo "🏠 Monitoring: all guilds"
fi

# ── 8. Write .env file ───────────────────────────────────────────────────────
cat > "$ENV_FILE" <<EOF
DISCORD_BOT_TOKEN=${DISCORD_TOKEN}
ENTITY_OUTPUT_BASE_URL=${ENTITY_URL}
MONITOR_GUILD_IDS=${GUILD_IDS}
EOF
chmod 600 "$ENV_FILE"
echo "✅ Environment file written"

# ── 9. Create systemd service ────────────────────────────────────────────────
NODE_PATH=$(which node)
mkdir -p "$(dirname "$SERVICE_FILE")"

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Entity Linker — Discord path rewriter
After=network.target

[Service]
Type=simple
WorkingDirectory=${INSTALL_DIR}
EnvironmentFile=${ENV_FILE}
ExecStart=${NODE_PATH} discord-listener.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

echo "✅ Systemd service created"

# ── 10. Enable and start ─────────────────────────────────────────────────────
systemctl --user daemon-reload
systemctl --user enable "$SERVICE_NAME" --now 2>/dev/null

sleep 2
if systemctl --user is-active "$SERVICE_NAME" &>/dev/null; then
  echo ""
  echo "╔══════════════════════════════════════════╗"
  echo "║   ✅ Entity Linker is running!           ║"
  echo "╚══════════════════════════════════════════╝"
  echo ""
  echo "  Status:  systemctl --user status $SERVICE_NAME"
  echo "  Logs:    journalctl --user -u $SERVICE_NAME -f"
  echo "  Stop:    systemctl --user stop $SERVICE_NAME"
  echo "  Restart: systemctl --user restart $SERVICE_NAME"
  echo ""
else
  echo ""
  echo "⚠️  Service started but may not be running. Check:"
  echo "  systemctl --user status $SERVICE_NAME"
  echo "  journalctl --user -u $SERVICE_NAME -n 20"
fi
