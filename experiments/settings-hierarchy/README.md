# Settings Hierarchy

Claude Code loads settings from five layers in order from lowest to highest precedence.
Settings merge across layers — a key set in a higher-precedence layer overrides the same
key from lower layers. More restrictive permission rules always win regardless of layer.

## The Five Layers

```
1. Managed   (~/.claude/managed-settings.json)  — enterprise MDM/admin policy, read-only
2. User      (~/.claude/settings.json)           — your personal defaults, all projects
3. Project   (.claude/settings.json)             — checked into repo, shared with team
4. Local     (.claude/settings.local.json)       — gitignored, your local overrides only
5. CLI flags (--model, --allowedTools, etc.)     — one session only, highest precedence
```

### Merge behavior

- **Scalar values** (model, defaultMode, outputStyle): higher layer wins
- **Arrays** (allow, deny, ask, additionalDirectories): merge — all layers contribute entries
- **Permissions**: deny always beats allow, regardless of which layer either came from
- **Hooks**: all layers' hooks run; no layer can suppress another layer's hooks
  (unless `allowManagedHooksOnly: true` is set in managed settings)

---

## Layer-by-Layer Guide

### 1. Managed (`~/.claude/managed-settings.json`)

Set by enterprise administrators via MDM (Mobile Device Management) or policy tooling.
Users cannot edit or override it — it's the floor, not the ceiling.

Used for: model allowlists, MCP server allowlists, hook governance, permission floors.

```json
{
  "availableModels": ["haiku", "sonnet"],
  "allowManagedHooksOnly": true,
  "permissions": {
    "deny": ["Bash(rm -rf *)"]
  }
}
```

### 2. User (`~/.claude/settings.json`)

Your personal defaults applied to every Claude Code session on this machine, across all
projects. Good for: statusLine, personal model preference, tools you always trust.

```json
// ~/.claude/settings.json  (this machine's actual config)
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

**What to put here:** UI preferences, statusLine, personal allow rules for tools you
always trust (e.g. `Read`, `Glob`, `Grep`).

**What NOT to put here:** project-specific hooks, model overrides for a single repo,
deny rules that only apply to one codebase.

### 3. Project (`.claude/settings.json`)

Checked into the repo — shared with everyone who clones it. This is the main config for
team-level governance: hooks, model selection, project-specific permissions.

```json
// .claude/settings.json  (this repo's actual config)
{
  "model": "claude-sonnet-4-6",
  "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" },
  "hooks": { ... }
}
```

**What to put here:** hooks, model override for this project, env vars, project-wide
permissions that every contributor should have.

**What NOT to put here:** personal preferences, machine-specific paths, secrets.

### 4. Local (`.claude/settings.local.json`)

Gitignored — your personal overrides for this project only. Useful for temporarily
changing the model, enabling experimental flags, or adding personal allow rules
without affecting teammates.

```json
// .claude/settings.local.json  (this repo, gitignored)
{
  "outputStyle": "default"
}
```

**What to put here:** temporary model switches (`"model": "claude-opus-4-6"`), personal
debug flags, overrides you don't want to commit.

**Gitignore:** `.claude/settings.local.json` should be in `.gitignore` (Claude Code adds
it automatically when the file is created).

### 5. CLI Flags

Highest precedence, one session only. Override anything from settings files.

```bash
claude --model claude-haiku-4-5-20251001   # override project model
claude --allowedTools "Read,Glob"          # restrict tools this session
claude --permission-mode plan              # read-only planning session
```

---

## Practical Patterns

### Personal tool trust in user settings

```json
// ~/.claude/settings.json
{
  "permissions": {
    "allow": ["Read", "Glob", "Grep", "Bash(git log *)", "Bash(git diff *)"]
  }
}
```
These auto-approve across all your projects — no prompts for common read-only operations.

### Project-level model + hooks, local-level model override

```json
// .claude/settings.json (committed)
{ "model": "claude-sonnet-4-6", "hooks": { ... } }

// .claude/settings.local.json (gitignored, your machine only)
{ "model": "claude-opus-4-6" }   // temporarily using Opus for a hard problem
```
The local override wins for your session; teammates still use Sonnet.

### Deny in project, allow in local (works, but rarely the right pattern)

Deny rules merge across layers — a deny in project settings applies even if you add an
allow in local. If you need to lift a project deny locally, you cannot — you'd need to
remove the deny from the project settings. This is intentional security behavior.

---

## Inspecting Effective Settings

There's no single "show merged settings" command, but you can reason through it:

1. Read each layer's file in order
2. For scalars: the highest layer with that key wins
3. For arrays: concatenate all layers
4. For permissions: deny beats allow at any layer

To see what settings files exist for a project:
```bash
ls ~/.claude/managed-settings.json 2>/dev/null   # managed
cat ~/.claude/settings.json                       # user
cat .claude/settings.json                         # project
cat .claude/settings.local.json                   # local
```

---

## Key Lessons

- **Five layers**: managed → user → project → local → CLI (each overrides the previous for scalars)
- **Deny is sticky**: a deny from any layer cannot be overridden by an allow in a higher layer
- **Hooks accumulate**: hooks from all layers run; no override/suppression between layers
- **Local settings are gitignored** — the right place for personal/temporary overrides
- **User settings are cross-project** — put only genuinely universal preferences there
- **Managed settings are immutable** — the enterprise floor; everything else builds on top
- **CLI flags are ephemeral** — nothing persists after the session ends
