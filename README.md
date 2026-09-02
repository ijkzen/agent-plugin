# agent-plugin

A Claude Code plugin (and marketplace) that bundles **frontend-design**, **context7**, and **ponytail** capabilities, plus MCP servers for vision, web search, and code graph.

> ⚠️ Configuration in progress — component content (skills/agents/hooks) will be added step by step. Dependencies are already declared.

## Dependencies

This plugin depends on three plugins from three different marketplaces:

| Dependency | Marketplace | Version (verified) |
|---|---|---|
| `frontend-design` | `claude-code-plugins` (Anthropic official) | 1.1.0 |
| `context7` | `claude-plugins-official` (Anthropic official) | latest |
| `ponytail` | `ponytail` (DietrichGebert/ponytail) | 4.9.0 |

Cross-marketplace dependencies are allowed via `allowCrossMarketplaceDependenciesOn` in `.claude-plugin/marketplace.json`.

## MCP servers

This plugin ships three MCP servers in `.mcp.json`. **Secrets are never stored in this repo** — they are injected at runtime via environment variables. Set them before enabling the plugin, or the server will fail to connect (see [Environment variables](#environment-variables)).

| Server | Transport | Purpose | Needs config? |
|---|---|---|---|
| `luma-vision` | stdio (`npx -y luma-mcp`) | Vision model access via custom gateway | ⚠️ requires `LUMA_API_KEY` |
| `tavily_proxy` | http | Web search API proxy | ⚠️ requires `TAVILY_API_KEY` |
| `codegraph-mcp` | stdio (`codegraph serve --mcp`) | Code knowledge graph for agents | ❌ none (needs `codegraph` CLI installed) |

### Environment variables

| Variable | Used by | Required | Default |
|---|---|---|---|
| `LUMA_API_KEY` | luma-vision | ✅ required | — |
| `LUMA_BASE_URL` | luma-vision | optional | `https://gateway.ijkzen.cn/v1` |
| `LUMA_MODEL_NAME` | luma-vision | optional | `deepseek-v4-flash-vision-exp` |
| `TAVILY_API_KEY` | tavily_proxy | ✅ required | — |

`luma-vision` also passes fixed values (non-secret): `MODEL_PROVIDER=custom`, `CUSTOM_PATH=/chat/completions`.

The `tavily_proxy` URL embeds the key as a query parameter: `https://tavily.ijkzen.cn/mcp?key=${TAVILY_API_KEY}` — the key is read from the environment, never hard-coded here.

### How to set the variables

```bash
# Shell (before launching Claude Code)
export LUMA_API_KEY="your-luma-key"
export TAVILY_API_KEY="your-tavily-key"

# Or add to your Claude Code settings env (~/.claude/settings.json)
{
  "env": {
    "LUMA_API_KEY": "your-luma-key",
    "TAVILY_API_KEY": "your-tavily-key"
  }
}
```

### Verify the servers connect

```bash
claude mcp list          # all three should appear; missing-variable warnings show if a required env is unset
claude mcp get luma-vision
claude mcp get tavily_proxy
```

If a required variable is unset, `claude mcp list` shows a missing-variable warning and the server uses the literal `${VAR}` text — set the variable and restart Claude Code.

## Hooks

| Hook | Script | Behavior |
|---|---|---|
| `SessionStart` | `scripts/codegraph-sync.sh` | On session start: if the current project is a git work tree, keep its codegraph index fresh — run `codegraph sync` if `.codegraph/` exists (already initialized), else `codegraph init` once. Silent (no output); no-op outside git repos or when the `codegraph` CLI is missing. |

## Installation

```bash
# Add this repo as a marketplace
claude plugin marketplace add github:ijkzen/agent-plugin

# Install the plugin (auto-installs dependencies)
claude plugin install agent-plugin

# Or directly
claude plugin add github:ijkzen/agent-plugin
```

## Structure

```
agent-plugin/
├── .claude-plugin/
│   ├── plugin.json        # manifest (with dependencies)
│   └── marketplace.json   # marketplace manifest (allowCrossMarketplaceDependenciesOn)
├── .mcp.json              # MCP server definitions (secrets via env vars)
├── hooks/
│   └── hooks.json         # SessionStart → codegraph-sync.sh
├── scripts/
│   └── codegraph-sync.sh  # silent codegraph init/sync on session start
├── README.md
└── LICENSE
```

## License

MIT
