#!/usr/bin/env bash
# Hook: PreToolUse
# Experiment: Dry-Run Injector
#
# Rewrites destructive commands to add --dry-run before they execute.
# This demonstrates PreToolUse *input modification* — not just block or allow,
# but returning a changed version of the tool input.
#
# Claude Code sends JSON to stdin:
#   { "tool_name": "Bash", "tool_input": { "command": "git clean -fd" } }
#
# To modify the input, return the full tool_input with changes:
#   { "tool_input": { "command": "git clean -fd --dry-run" } }
#
# Claude executes the modified command and sees the dry-run output.
# It can then decide whether to run the real command intentionally.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')

if [ "$TOOL" != "Bash" ]; then
  echo '{}'
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

# --- git clean ---
# Destructive: removes untracked files from the working tree.
# Supports --dry-run natively (shows what would be removed).
if echo "$COMMAND" | grep -Eq -- 'git clean' && ! echo "$COMMAND" | grep -Eq -- '(--dry-run|-n)'; then
  NEW_CMD="${COMMAND} --dry-run"
  echo "{\"tool_input\": {\"command\": $(printf '%s' "$NEW_CMD" | jq -Rs .)}}"
  exit 0
fi

# --- rsync with --delete ---
# Destructive: --delete removes files at the destination that don't exist at source.
# Supports --dry-run natively.
if echo "$COMMAND" | grep -Eq -- 'rsync.*--delete' && ! echo "$COMMAND" | grep -Eq -- '--dry-run'; then
  NEW_CMD="${COMMAND} --dry-run"
  echo "{\"tool_input\": {\"command\": $(printf '%s' "$NEW_CMD" | jq -Rs .)}}"
  exit 0
fi

echo '{}'
