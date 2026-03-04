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

6. **The actual stdin schema differs from the docs.** Hook scripts receive `tool_name`
   and `tool_input`, not `tool` and `input` as simplified examples suggest. Confirmed
   by capturing raw stdin with `cat >> /tmp/debug.log` as a wildcard hook.

---

### Commit Normalizer (`commit-normalizer.sh`)

A `PreToolUse` hook that blocks `git commit` commands whose messages don't follow
[conventional commit](https://www.conventionalcommits.org/) format.

**Valid format:** `type(scope): description` or `type: description`

**Valid types:** `feat`, `fix`, `chore`, `docs`, `style`, `refactor`, `test`, `perf`, `ci`, `build`, `revert`

**What it blocks:**
- `git commit -m "updated stuff"` — no type prefix
- `git commit -m "update: add thing"` — invalid type

**What it allows:**
- `git commit -m "feat: add login page"` — valid
- `git commit -m "fix(auth): handle expired tokens"` — valid with scope
- `git status`, `git push`, other non-commit commands — not targeted
- Interactive commits (no `-m` flag) — passed through

**Wired in:** `.claude/settings.json` alongside the secret scanner under the same `Bash` matcher

#### What Was Learned

1. **Multiple hooks can share a matcher.** Both `secret-scanner.sh` and `commit-normalizer.sh`
   run under `"matcher": "Bash"` — Claude Code runs them in order for every Bash call.

2. **Scoping within a hook matters too.** The hook only acts when the command contains
   `git commit`, leaving all other Bash commands untouched.

3. **Blocks are appropriate here even locally.** Unlike the secret scanner, normalizing
   commit messages is a quality convention that applies regardless of team size. Malformed
   commits are tedious to fix after pushing.

4. **Interactive commits pass through.** Without a `-m` flag, we can't parse the message
   without blocking the command entirely — so we let it through and trust the user.

---

### Dry-Run Injector (`dry-run-injector.sh`)

A `PreToolUse` hook that *rewrites* destructive commands to add `--dry-run` before
they execute. This demonstrates the input modification capability of `PreToolUse` —
returning a changed tool input rather than just allowing or blocking.

**What it rewrites:**
- `git clean -fd` → `git clean -fd --dry-run`
- `rsync -av --delete src/ dst/` → `rsync -av --delete src/ dst/ --dry-run`

**Idempotent:** if `--dry-run` or `-n` is already present, passes through unchanged.

**Wired in:** `.claude/settings.json` alongside the other Bash hooks

#### The Input Modification Pattern

This is what makes this hook different from the others. Instead of returning `{}`
(allow) or `{ "decision": "block" }`, it returns a modified `tool_input`:

```json
{ "tool_input": { "command": "git clean -fd --dry-run" } }
```

Claude executes the modified command and sees the dry-run output. It can then
decide whether to run the real command intentionally — with full knowledge of
what will be affected.

#### What Was Learned

1. **Input modification is the most powerful `PreToolUse` capability.** Block/allow
   is binary; modification lets you add guardrails without removing agency.

2. **Use `printf '%s'` not `echo` when building JSON strings.** `echo` adds a trailing
   newline that ends up in the JSON string value as `\n`.

3. **Always use `grep -- pattern`** when patterns might start with `-`. Without `--`,
   `grep` interprets leading dashes as flags. This is a recurring shell gotcha.

4. **Make modifications idempotent.** Check for `--dry-run` before adding it —
   a hook that doubles flags on repeated calls would be maddening to debug.

## Hooks Section Complete

All four experiments are done. The patterns covered:

| Hook | Type | Technique |
|------|------|-----------|
| Secret scanner | PreToolUse | Block |
| Edit logger | PostToolUse | Observe / log |
| Commit normalizer | PreToolUse | Block with guidance |
| Dry-run injector | PreToolUse | Input modification |

**Next:** SKILL.md files — `.claude/skills/`
