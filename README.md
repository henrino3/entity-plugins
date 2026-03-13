# Entity Linker Discord Plugin

A standalone Discord listener that automatically rewrites local file paths in bot messages into clickable [Entity](https://github.com/nicholasgasior/entity) HTTP URLs.

## What it does

When an OpenClaw agent sends a Discord message containing a local path like:

```
Check ~/clawd/output/report.md for details
```

The Entity Linker edits it within ~250ms to:

```
Check http://100.106.69.9:3000/output/report.md for details
```

The link is clickable and opens the file in Entity's web UI.

## Supported path formats

| Input | Output |
|---|---|
| `~/clawd/output/file.md` | `http://<entity>/output/file.md` |
| `~/clawd/memory/rules.md` | `http://<entity>/output/memory/rules.md` |
| `/home/user/clawd/output/file.md` | `http://<entity>/output/file.md` |
| `/Users/user/clawd/docs/llms.txt` | `http://<entity>/output/docs/llms.txt` |
| `/home/alice/clawd/output/file.md` | `http://<entity>/output/file.md` |

Works with any username on Linux (`/home/...`) and macOS (`/Users/...`).

Trailing punctuation is handled automatically:
- `~/clawd/output/file.md.` → `<http://.../file.md>.`
- `~/clawd/output/a.txt, ~/clawd/output/b.txt!` → `<http://.../a.txt>, <http://.../b.txt>!`

## Quick install

```bash
git clone https://github.com/henrino3/entity-plugins.git
cd entity-plugins/entity-linker
./install.sh
```

The installer will:
1. Check for Node.js 18+
2. Install npm dependencies
3. Run the test suite
4. Auto-detect your Discord bot token from OpenClaw config
5. Auto-detect your Entity server URL
6. Auto-detect your Discord guild IDs from OpenClaw config
7. Create and start a systemd user service

## Manual install

```bash
# Clone
git clone https://github.com/henrino3/entity-plugins.git
cd entity-plugins/entity-linker

# Install deps
npm install

# Create .env
cat > .env << EOF
DISCORD_BOT_TOKEN=your-bot-token-here
ENTITY_OUTPUT_BASE_URL=http://your-entity-ip:3000/output/
MONITOR_GUILD_IDS=your-guild-id-here
EOF
chmod 600 .env

# Run
node discord-listener.js
```

## Environment variables

| Variable | Required | Description |
|---|---|---|
| `DISCORD_BOT_TOKEN` | Yes | Discord bot token (same as your OpenClaw agent) |
| `ENTITY_OUTPUT_BASE_URL` | No | Entity file server URL (default: `http://100.106.69.9:3000/output/`) |
| `MONITOR_GUILD_IDS` | No | Comma-separated guild IDs to monitor (default: all guilds) |

## Service management

```bash
# Status
systemctl --user status entity-linker

# Logs (live)
journalctl --user -u entity-linker -f

# Restart
systemctl --user restart entity-linker

# Stop
systemctl --user stop entity-linker

# Disable (won't start on boot)
systemctl --user disable entity-linker
```

## How it works

```
┌──────────────┐     ┌──────────┐     ┌─────────┐
│ OpenClaw     │────▶│ Discord  │────▶│ Entity  │
│ Agent        │     │ API      │     │ Linker  │
│ sends msg    │     │          │     │ edits   │
│ with ~/path  │     │          │     │ msg     │
└──────────────┘     └──────────┘     └─────────┘
                                           │
                                           ▼
                                     Message now has
                                     clickable HTTP link
```

1. OpenClaw agent sends a message to Discord (via any code path)
2. Discord delivers the message
3. Entity Linker (running as a separate process) receives the message via Discord.js gateway
4. If the message contains local paths, it edits the message via the Discord API
5. The edited message now has clickable Entity URLs

This approach is:
- **Independent of OpenClaw** — survives gateway restarts and updates
- **Deterministic** — pure regex, no LLM tokens burned
- **Fast** — edits happen in ~250ms
- **Reliable** — systemd auto-restarts on failure

## Tests

```bash
npm test
```

## Architecture decision

We tried the OpenClaw plugin approach first (18 attempts over 24+ hours). It failed because:
- OpenClaw's `message_sending` hook only fires for natural conversational replies
- The `message` tool calls `sendMessageDiscord` directly, bypassing all hooks
- Custom channel adapters lose to the bundled Discord plugin in `dedupeChannels`

The standalone Discord listener approach worked on the first try because it operates at the Discord level, catching all messages regardless of how OpenClaw sent them.

## License

MIT
