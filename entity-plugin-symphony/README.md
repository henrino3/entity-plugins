# Entity Plugin: Symphony

Replaces Symphony's Linear tracker adapter with Entity's Swarm API, allowing Symphony to use Entity as the work tracker while running agents as executor.

## What it does

- Reads work items from Entity's `/api/swarm/jobs` endpoint
- Maps Entity Swarm statuses ↔ Symphony workflow states
- Posts feedback and status updates back to Entity jobs

## Prerequisites

- [openai/symphony](https://github.com/h-mascot/openai-symphony) installed at `$HOME/Code/symphony`
- `ENTITY_API_URL` env var pointing to Entity's swarm API (e.g. `http://100.104.229.62:3000/api/swarm`)
- Optional: `ENTITY_API_KEY` for authenticated endpoints

## Install

```bash
cd entity-plugin-symphony
./install.sh
```

This copies `entity.ex` into the Symphony Elixir tracker path:
```
$SYMMPHONY_HOME/elixir/lib/symphony_elixir/tracker/entity.ex
```

Then configure Symphony to use the Entity tracker in your `WORKFLOW.md`:

```yaml
---
tracker:
  kind: entity
  endpoint: http://100.104.229.62:3000/api/swarm
---
```

## Status mapping

| Entity (Swarm) | Symphony        |
|----------------|-----------------|
| draft          | Backlog         |
| queued         | Todo            |
| running        | In Progress     |
| proof/review   | Human Review    |
| done           | Done            |
| failed         | Canceled        |
