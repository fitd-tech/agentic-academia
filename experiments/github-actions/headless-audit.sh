#!/usr/bin/env bash
# headless-audit.sh
#
# Demonstrates claude -p (headless/non-interactive mode).
# Asks Claude to audit the hook scripts and return structured JSON.
#
# Usage:
#   bash experiments/github-actions/headless-audit.sh
#   bash experiments/github-actions/headless-audit.sh | jq .
#
# Requires: ANTHROPIC_API_KEY set in environment

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
HOOKS_DIR="$REPO_ROOT/experiments/hooks"

# Build a file listing to include in the prompt
HOOK_LIST=$(ls "$HOOKS_DIR"/*.sh 2>/dev/null | xargs -I{} basename {})

claude \
  --output-format json \
  --model claude-haiku-4-5-20251001 \
  -p "You are auditing Claude Code hook scripts in a learning repository.

The hooks directory contains: $HOOK_LIST

For each hook script in $HOOKS_DIR, read the file and return a JSON object with this structure:
{
  \"audit_timestamp\": \"<ISO8601>\",
  \"hooks\": [
    {
      \"name\": \"<filename>\",
      \"hook_type\": \"PreToolUse|PostToolUse\",
      \"matcher\": \"<tool names matched>\",
      \"can_block\": true|false,
      \"risk_level\": \"low|medium|high\",
      \"risk_reason\": \"<one sentence>\"
    }
  ],
  \"summary\": \"<one sentence overall assessment>\"
}

Return ONLY valid JSON. No preamble, no explanation."
