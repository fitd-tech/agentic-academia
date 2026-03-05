#!/usr/bin/env bash
# PreCompact hook — injects project-specific guidance into the compact summary prompt.
# Output from this script is prepended to the compaction prompt.

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

# Emit compact instructions tailored for this project
cat <<'EOF'
When writing this compact summary, prioritize:
1. Which experiment or topic was active and exactly what was built or changed
2. Any gotchas, key lessons, or non-obvious decisions made during this session
3. File paths of anything created or modified
4. The next planned step, if known

Structure: brief paragraph of context, then bullet points for lessons/gotchas, then next step.
EOF

# Append recent git changes for grounding (last 5 modified tracked files)
if [ -n "$REPO_ROOT" ]; then
    RECENT=$(git -C "$REPO_ROOT" diff --name-only HEAD 2>/dev/null | head -5)
    if [ -n "$RECENT" ]; then
        echo ""
        echo "Files modified in this session (for reference):"
        echo "$RECENT" | sed 's/^/  - /'
    fi
fi
