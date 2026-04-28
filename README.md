# Entity Plugins

Plugins and tools for [Entity](https://github.com/h-mascot/entity) — the Mission Control platform for AI agent swarms.

## Swarm Provider Plugins

Each plugin adds an execution provider to Entity's Swarm system.

| Plugin | Provider | Mode | Description |
|--------|----------|------|-------------|
| [entity-plugin-acp](./entity-plugin-acp/) | `acp` | Push | Dispatches to Geordi ACP (Codex on Mac) |
| [entity-plugin-symphony](./entity-plugin-symphony/) | `symphony` | Pull | Pulls from Entity via openai/symphony |
| [entity-plugin-eforge](./entity-plugin-eforge/) | `eforge` | Queue | Writes jobs to eforge file queue |
| [entity-plugin-codex](./entity-plugin-codex/) | `codex` | WebSocket | Direct Codex app-server via WebSocket RPC |

### Installation (per plugin)

```bash
git clone https://github.com/h-mascot/entity-plugins.git
cd entity-plugins/<plugin-name>
./install.sh
# Restart Entity
```

Or install via the **Extensions** page in the Entity UI.

## Behavior Plugins

### [Discord Entity Linker](./discord-entity-linker/)

Rewrites local file paths to clickable Entity HTTP URLs in Discord messages. Standalone Node service.

```bash
cd discord-entity-linker
./install.sh
```

## License

MIT
