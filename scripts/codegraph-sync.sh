#!/bin/sh
# SessionStart hook: keep the codegraph index in sync with the current project.
# Pure logic, no output. Exit codes are the only signal.
#
# Logic:
#   1. If the current project is NOT a git work tree -> do nothing (exit 0).
#   2. If .codegraph/ already exists (project was `codegraph init`-ed) -> run `codegraph sync`.
#   3. Otherwise -> run `codegraph init` to build the index once.
#
# If the `codegraph` CLI is not installed, do nothing quietly (the MCP server
# handles its own absence); never error out the session.

# Nothing to print: silence everything.
exec >/dev/null 2>&1

# 1. Not a git repo -> nothing to do.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

# codegraph CLI missing -> nothing to do (keep the session quiet).
if ! command -v codegraph >/dev/null 2>&1; then
  exit 0
fi

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -n "$PROJECT_ROOT" ] || exit 0
cd "$PROJECT_ROOT" || exit 0

# 2. Already initialized -> incremental sync.
if [ -d "$PROJECT_ROOT/.codegraph" ]; then
  codegraph sync . >/dev/null 2>&1
  exit 0
fi

# 3. Not initialized yet -> one-time init (builds the graph).
codegraph init . >/dev/null 2>&1
exit 0
