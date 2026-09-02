# agent-plugin

Claude Code plugin: agent tools & workflow — task planning, code review, and automated quality hooks.

## Features

| Component | Location | Purpose |
|---|---|---|
| **Task Runner** | `skills/task-runner/` | Plan & track multi-step tasks |
| **Code Reviewer** | `skills/code-reviewer/` | Structured code review (correctness/security/perf) |
| **Reviewer Agent** | `agents/reviewer.md` | Subagent for deep code review |
| **Hooks** | `hooks/hooks.json` | Auto-format Python on write, session start intro |

## Installation

```bash
# From GitHub marketplace
claude plugin add github:ijkzen/agent-plugin

# Or from local directory (development)
claude --plugin-dir /path/to/agent-plugin
```

## Usage

- **Task planning**: ask "plan this task" → auto-invokes `task-runner` skill
- **Code review**: ask "review this code" → auto-invokes `code-reviewer` skill
- **Deep review**: use `@reviewer review src/main.py` for subagent review

## Structure

```
agent-plugin/
├── .claude-plugin/plugin.json   # manifest (only file in this dir)
├── skills/
│   ├── task-runner/SKILL.md
│   └── code-reviewer/SKILL.md
├── agents/reviewer.md
└── hooks/hooks.json
```

## License

MIT
