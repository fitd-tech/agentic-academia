# .claude — Managed Configuration

This directory is managed by the shared Claude Code config repo.
Config repo: /Users/anthonypelusocook/claude-code-config
Profile: unknown
Last updated: 2026-03-06

Symlinked files in this directory are linked to the config repo and kept in sync
automatically. Do not edit them directly — changes will be overwritten on the next sync.

## Managing this configuration

| Command | What it does |
|---------|--------------|
| `/sync-config` | Detect and repair symlink drift, refresh this README |
| `/init-config` | Re-run setup to add or change linked components |

## Local overrides

- `.claude/settings.local.json` — Personal settings (gitignored, never committed)
- `./CLAUDE.md` (project root) — Project-specific instructions for Claude

## Ejecting

To remove all managed symlinks and take ownership of the config files:

    bash /Users/anthonypelusocook/claude-code-config/unlink.sh
