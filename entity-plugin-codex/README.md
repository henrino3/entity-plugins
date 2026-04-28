# Entity Plugin: Codex

Replaces the ACP provider with OpenAI Codex as the build agent. Dispatches jobs to the Codex app server via WebSocket RPC.

## What it does

- WebSocket RPC client for the Codex app server (`ws://127.0.0.1:8300`)
- Creates a new thread per dispatched job and sends the task spec as a turn
- Maps Swarm status ↔ Codex thread status
- Handles streaming agent message deltas for proof collection

## Prerequisites

- Codex app server running: `codex app-server --listen ws://127.0.0.1:8300`
- `CODEX_APP_SERVER_URL` env var (defaults to `ws://127.0.0.1:8300`)
- `CODEX_CODEX_HOME` env var (defaults to `$HOME/.codex`)

## Install

```bash
cd entity-plugin-codex
./install.sh
```

This copies `codex.ts` into the Entity Swarm providers directory:
```
$HOME/Code/Entity/packages/server/src/swarm/providers/codex.ts
```

Then restart Entity to load the new provider.

## Provider configuration

The `CodexProvider` is registered in `dispatcher.ts`. After installing, verify it appears:

```bash
curl http://localhost:3000/api/swarm/providers
```

## Sandbox mode

By default, Codex app server runs read-only. To allow file writes:

```bash
codex app-server --sandbox none --listen ws://127.0.0.1:8300
```
