#!/usr/bin/env bash
# Hook: PreToolUse
# Experiment: Secret Scanner
#
# Intercepts Bash tool calls and blocks commands that appear to expose secrets.
#
# Claude Code sends JSON to stdin:
#   { "tool_name": "Bash", "tool_input": { "command": "echo $API_KEY" } }
#
# We return JSON to stdout:
#   {}                                          → allow
#   { "decision": "block", "reason": "..." }   → block with message shown to Claude

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')

# Only inspect Bash commands
if [ "$TOOL" != "Bash" ]; then
  echo '{}'
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

PATTERNS=(
  # Echoing or printing env vars with secret-like names
  '(echo|print|printf).*\$(.*)(key|token|secret|password|passwd|credential|auth)'
  # Reading .env or credential files
  '(cat|head|tail|less|more)\s+.*\.(env|pem|key|p12|pfx)'
  # curl/wget with Authorization or Bearer headers
  '-H\s+.*(Authorization|Bearer|token)'
  # Printing all env vars (env, printenv, export with no args)
  '^(env|printenv|export)(\s+-\w+)?\s*$'
)

for PATTERN in "${PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -Eiq -- "$PATTERN"; then
    MSG="Blocked: command appears to expose secrets (matched pattern: $PATTERN). Review and run manually if intentional."
    echo "{\"decision\": \"block\", \"reason\": $(echo "$MSG" | jq -Rs .)}"
    exit 0
  fi
done

echo '{}'
