# Entity Plugins

Plugins and tools for [Entity](https://github.com/nicholasgasior/entity) — the file server for OpenClaw agents.

## Plugins

### [Discord Entity Linker](./discord-entity-linker/)

Automatically rewrites local file paths (`~/clawd/...`) to clickable Entity HTTP URLs in Discord messages. Runs as a standalone systemd service.

```bash
cd discord-entity-linker
./install.sh
```

### [entity-plugin-symphony](./entity-plugin-symphony/)

Replaces Symphony's Linear tracker adapter with Entity's Swarm API. Lets Symphony use Entity as the work tracker.

```bash
cd entity-plugin-symphony
./install.sh
```

### [entity-plugin-eforge](./entity-plugin-eforge/)

Verifies and documents the eforge CLI daemon setup for Entity. Eforge is a standalone CLI that Entity dispatches build jobs to.

```bash
cd entity-plugin-eforge
./install.sh
```

### [entity-plugin-codex](./entity-plugin-codex/)

Replaces the ACP provider with OpenAI Codex as the build agent. Dispatches jobs to the Codex app server via WebSocket RPC.

```bash
cd entity-plugin-codex
./install.sh
```

## License

MIT
