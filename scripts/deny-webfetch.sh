#!/bin/sh
# PreToolUse guard: deny the system WebFetch tool and redirect to the Tavily
# MCP extract tool. Prints hookSpecificOutput JSON to stdout (no other output).
#
# Claude Code reads the deny decision from this JSON; the model is told in
# permissionDecisionReason to use the `tavily-extract` tool. The tool name is
# intentionally unprefixed so the model resolves the closest matching tool in
# whatever harness this plugin runs in.

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"WebFetch is disabled by agent-plugin. Use the Tavily extract tool instead: tavily-extract. Call it with the target URL(s) in the urls parameter."}}
JSON
exit 0
