# Status Line Experiment

## What was built

A two-line status bar at the bottom of Claude Code (`~/.claude/statusline.sh`):

- **Line 1:** `[Model]  branch  (worktree: name)` — worktree field only appears in worktree sessions
- **Line 2:** Color-coded context bar (green/yellow/red) + context percentage + session cost

## How it works

Claude Code pipes JSON session data to the script via stdin after each assistant message,
on permission mode changes, and when vim mode toggles (debounced at 300ms).

The script reads that JSON with `jq`, builds the output, and prints to stdout.
Claude Code displays whatever is printed.

## Key learnings

### Data schema
The full JSON schema has far more fields than expected — notably:
- `worktree.*` — worktree name, path, branch, and original branch (only present in worktree sessions)
- `agent.name` — agent name when running with `--agent`
- `context_window.current_usage` — per-call token breakdown (input, output, cache creation, cache read)
- `cost.*` — total USD, wall-clock duration, API duration, lines added/removed
- `exceeds_200k_tokens` — boolean flag regardless of actual context window size
- `vim.mode` — `NORMAL` or `INSERT` (only present when vim mode is active)

Use `// 0` or `// empty` fallbacks in jq for fields that may be absent or null
(especially `current_usage`, `used_percentage`, and worktree fields).

### printf gotchas
- Never pass a variable as the printf format string if it contains `%` or `$`
- Use `printf "%s\n" "$VAR"` for plain strings
- Use `printf "%b\n" "$VAR"` when the variable contains `\033` ANSI escape sequences
  (`%b` interprets backslash escapes in the argument, not the format string)

### Color codes in bash
Store ANSI codes as `"\033[32m"` (double-quoted) — bash stores them as the literal
4-character sequence `\033`. `printf "%b"` then converts `\033` to the ESC character
at print time, which terminals interpret as color.

### Git branch without running git
Reading `$CWD/.git/HEAD` is faster than spawning a git subprocess on every update.
The file contains `ref: refs/heads/main` — strip the prefix with `sed`.

### /statusline command
Claude Code has a built-in `/statusline` slash command that generates a script and
wires the settings automatically from a plain-English description. Useful for quick
setup; manual approach is better for learning the data model.

### Update timing
The status line updates after each assistant message — not continuously.
Edits to the script file take effect on the next interaction (no restart needed).

## Configuration

In `~/.claude/settings.json` (user-level — applies to all projects):

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

The `padding` field (optional integer) adds horizontal spacing beyond the built-in margin.

## Testing

Pipe sample JSON directly to the script to test without running a full session:

```bash
echo '{"model":{"display_name":"Sonnet"},"workspace":{"current_dir":"/your/project"},"cost":{"total_cost_usd":0.03},"context_window":{"used_percentage":23}}' \
  | ~/.claude/statusline.sh
```

## Files

- `~/.claude/statusline.sh` — the status line script (user-level, not in this repo)
- `~/.claude/settings.json` — wires the script into Claude Code
