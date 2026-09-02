#!/bin/sh
# SessionStart hook: keep the codegraph index in sync with the current project.
# Pure logic, no output on stdout/stderr. Exit codes are the only signal.
# Targets: macOS and Linux (POSIX sh — no bashisms, no GNU-only tools).
#
# Logic:
#   1. Not inside a git work tree          -> do nothing (exit 0).
#   2. `codegraph` CLI not found           -> do nothing (exit 0).
#   3. `.codegraph/` exists (already init) -> `codegraph sync .`
#   4. Otherwise                           -> `codegraph init .` (one-time)
#
# macOS note: if codegraph was installed via Homebrew it lives under
# /opt/homebrew/bin (Apple Silicon) or /usr/local/bin (Intel). If the host
# shell/PATH doesn't include it, `command -v` misses it and this hook stays
# silent — which is the intended "not found => do nothing" behaviour. The user
# should ensure `codegraph` is on PATH (e.g. export in their shell profile).

# Silence everything from this point on: no stdout, no stderr, ever.
exec >/dev/null 2>&1

# 1. Not a git work tree -> nothing to do.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

# 2. codegraph CLI missing -> nothing to do (keep the session quiet).
if ! command -v codegraph >/dev/null 2>&1; then
  exit 0
fi

# Resolve the repo root (POSIX-safe: command substitution strips trailing
# newlines; paths with spaces are handled by quoting).
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -n "$PROJECT_ROOT" ] || exit 0
cd "$PROJECT_ROOT" || exit 0

# 3. Already initialized -> incremental sync.
if [ -d "$PROJECT_ROOT/.codegraph" ]; then
  codegraph sync . >/dev/null 2>&1
  exit 0
fi

# 4. Not initialized yet -> one-time init (builds the graph).
codegraph init . >/dev/null 2>&1
exit 0
