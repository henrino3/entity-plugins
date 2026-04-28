# entity-plugin-acp

Swarm execution provider that dispatches build jobs to **Geordi ACP** (Agent Coding Protocol) running on Mac.

## What it does

Wraps the Geordi ACP adapter as a Swarm provider. Entity dispatches jobs to this provider, which forwards them over HTTP to the ACP agent.

- Health checks via `GET /ping`
- Dispatch via `POST /runs`
- Status via `GET /runs/:id`
- Cancel via `POST /runs/:id/cancel`
- Proof collection via `GET /runs/:id`

## Installation

```bash
git clone https://github.com/h-mascot/entity-plugins.git
cd entity-plugins/entity-plugin-acp
./install.sh
# Restart Entity
```

Or via the **Extensions** page in the Entity UI.

## Configuration

| Env var | Default | Description |
|---------|---------|-------------|
| `ACP_BASE_URL` | `http://100.86.150.96:8100` | ACP agent HTTP endpoint |

## Requirements

- Entity server with geordi-swarm plugin
- ACP agent running on Mac at the configured URL
- Codex CLI installed and authenticated (`codex login`)

## License

Apache 2.0
