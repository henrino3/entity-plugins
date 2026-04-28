# Entity Plugin: Eforge

Configures Entity to dispatch build jobs to the Eforge CLI daemon for execution.

## What it does

- Eforge is a standalone CLI tool installed globally (`/opt/homebrew/bin/eforge`)
- Entity communicates with the eforge daemon via HTTP API (`localhost:4567`)
- No Entity source files are modified — this plugin just verifies the eforge setup

## Prerequisites

- Eforge installed: `npm install -g @openai/eforge`
- Eforge daemon running: `/opt/homebrew/bin/eforge daemon start`
- Port 4567 reachable

## Install

```bash
cd entity-plugin-eforge
./install.sh
```

## Entity configuration

Set these env vars before starting Entity:

```bash
export EFORGE_API_URL=http://localhost:4567
export EFORGE_QUEUE_DIR=$HOME/Code/eforge-queue   # optional, default ~/.eforge/queue
```

The `SwarmProvider` for eforge is hardcoded in `dispatcher.ts` — no plugin install needed in Entity core.

## Daemon commands

```bash
/opt/homebrew/bin/eforge daemon start   # start
/opt/homebrew/bin/eforge daemon stop    # stop
/opt/homebrew/bin/eforge daemon status  # check status
```
