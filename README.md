# agent-plugin

A Claude Code plugin (and marketplace) that bundles **frontend-design**, **context7**, and **ponytail** capabilities.

> ⚠️ Configuration in progress — component content (skills/agents/hooks) will be added step by step. Dependencies are already declared.

## Dependencies

This plugin depends on three plugins from three different marketplaces:

| Dependency | Marketplace | Version (verified) |
|---|---|---|
| `frontend-design` | `claude-code-plugins` (Anthropic official) | 1.1.0 |
| `context7` | `claude-plugins-official` (Anthropic official) | latest |
| `ponytail` | `ponytail` (DietrichGebert/ponytail) | 4.9.0 |

Cross-marketplace dependencies are allowed via `allowCrossMarketplaceDependenciesOn` in `.claude-plugin/marketplace.json`.

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
├── README.md
└── LICENSE
```

## License

MIT
