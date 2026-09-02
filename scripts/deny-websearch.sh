#!/bin/sh
# PreToolUse guard: deny the system WebSearch tool and redirect to the Tavily
# MCP search tool. Prints hookSpecificOutput JSON to stdout (no other output).
#
# Claude Code reads the deny decision from this JSON; the model is told in
# permissionDecisionReason to use the `tavily-search` tool. The tool name is
# intentionally unprefixed so the model resolves the closest matching tool in
# whatever harness (Claude Code, or another compatible harness) this plugin
# runs in.

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"WebSearch is disabled by agent-plugin. Use the Tavily search tool instead: tavily-search. Call it with the same query parameters (query, search_depth, max_results, include_domains, exclude_domains)."}}
JSON
exit 0
