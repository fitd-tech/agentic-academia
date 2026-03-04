# Hooks Experiments

## Completed

### Secret Scanner (`secret-scanner.sh`)

A `PreToolUse` hook that intercepts Bash tool calls and blocks commands that
appear to expose secrets.

**What it blocks:**
- `echo $API_KEY` — echoing env vars with secret-like names
- `cat .env` — reading `.env` / credential files
- `curl -H "Authorization: Bearer ..."` — authenticated HTTP requests
- `env` / `printenv` — printing all environment variables

**What it allows:**
- All non-Bash tools (Read, Write, Edit, etc.)
- Bash commands with no secret-like patterns

**Wired in:** `.claude/settings.json` under `PreToolUse` → `Bash` matcher

#### What Was Learned

1. **The hook contract is stdin/stdout JSON.** Claude writes `{ "tool": "...", "input": {...} }`
   to stdin. Return `{}` to allow, or `{ "decision": "block", "reason": "..." }` to block.

2. **`PreToolUse` fires before anything happens** — it's the right place for governance.
   `PostToolUse` is for observation, not prevention.

3. **Use `grep -Eiq --`** — the `--` is required when patterns start with `-` (like `-H`)
   to prevent grep from treating the pattern as a flag. macOS BSD grep respects this.

4. **Matchers scope hooks to specific tools.** The `"matcher": "Bash"` in `settings.json`
   means this script only runs for Bash calls — no overhead on Read/Write/etc.

5. **Shell state doesn't persist between Claude Code tool calls.** Each Bash invocation
   is a fresh shell. Avoid relying on variables set in previous calls.

#### When This Hook Is (and Isn't) Appropriate

**Blocks are for irreversible or dangerous actions in your context.** For a local solo
project, `echo $API_KEY` in a terminal you control carries little real risk. Blocking
it here is overcautious — the hook is most valuable as a learning artifact.

The same pattern applied to a **team project or CI environment** is genuinely important:
a secret echoed in GitHub Actions logs is exposed to anyone with repo access, and
`echo $TOKEN` in a committed workflow is a real credential leak vector.

**Practical rule of thumb:**

| Context | Right tool |
|---------|-----------|
| Local solo project | `PostToolUse` log (observe, don't block) |
| Shared team repo | `PreToolUse` block (enforce for everyone) |
| CI/CD pipeline | `PreToolUse` block (logs are often retained and visible) |

For this project specifically, an **edit logger** (`PostToolUse`) would be a more
proportionate use of hooks than a secret blocker.

---

### Edit Logger (`edit-logger.sh`)

A `PostToolUse` hook that appends a timestamped record to `.claude/edit-log.jsonl`
after every `Edit`, `Write`, or `NotebookEdit` tool call.

**What it logs:**
```json
{"timestamp":"2026-03-04T15:07:30Z","tool":"Edit","file":"src/auth.py"}
```

**What it ignores:** all non-file-modifying tools (Bash, Read, Glob, etc.)

**Output location:** `.claude/edit-log.jsonl` (gitignored — local only)

**Wired in:** `.claude/settings.json` under `PostToolUse` → `Edit|Write|NotebookEdit` matcher

#### What Was Learned

1. **`PostToolUse` cannot block.** The action is already done. Return value is ignored —
   this event is purely for observation, logging, and side effects.

2. **The matcher supports regex alternation.** `"matcher": "Edit|Write|NotebookEdit"`
   matches any of the three tools in a single hook entry.

3. **JSONL is the right format for append logs.** One JSON object per line means the file
   is always valid to read line-by-line, even if written to concurrently by multiple agents.

4. **`git rev-parse --show-toplevel`** finds the repo root regardless of where Claude
   is running from — makes log paths portable across subdirectories.

5. **`PostToolUse` is the right hook for a solo project.** No friction, full visibility.
   Contrast with the secret scanner: same domain (file/command activity), different
   risk context, different hook choice.

## Suggested Next Experiments


- **Commit normalizer** — `PreToolUse` hook that enforces conventional commit format
- **Dry-run injector** — `PreToolUse` hook that adds `--dry-run` to destructive commands
