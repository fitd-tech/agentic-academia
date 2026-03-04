#!/usr/bin/env bash
# Hook: PostToolUse
# Experiment: Edit Logger
#
# Appends a record to .claude/edit-log.jsonl after every file-modifying tool call.
# PostToolUse cannot block — it's for observation only.
#
# Claude Code sends JSON to stdin:
#   {
#     "tool_name": "Edit",
#     "tool_input":  { "file_path": "...", "old_string": "...", "new_string": "..." },
#     "tool_response": { ... }
#   }

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')

# Only log file-modifying tools
case "$TOOL" in
  Edit|Write|NotebookEdit) ;;
  *) exit 0 ;;
esac

LOG_FILE="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")/.claude/edit-log.jsonl"

jq -c \
  --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --arg tool "$TOOL" \
  '{
    timestamp: $ts,
    tool: $tool,
    file: (.tool_input.file_path // .tool_input.notebook_path // "unknown")
  }' <<< "$INPUT" >> "$LOG_FILE"
