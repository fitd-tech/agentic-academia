# Agent Teams

Released February 2026 with Opus 4.6. The frontier of Claude Code capability —
even most senior engineers haven't used this in production yet.

## Status

> Builder/Validator experiment scaffolded. See `experiments/agent-teams/builder-validator/`.
> Requires Opus 4.6 + `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` to run live.

## What Makes This Different

Agent Teams are **peers** — they communicate directly with each other, share a task list,
and self-coordinate. This is architecturally different from subagents, which only report
back to the calling agent.

## How It Works

- One session acts as **Team Lead**; it spawns Teammates
- Teammates share a file-locked task list at `~/.claude/tasks/{team-name}/`
- Teammates communicate via a mailbox system (`broadcast` or `message` individuals)
- Plan approval gates: Teammate stays read-only until the Lead approves
- Display: in-process (Shift+Down cycles teammates) or split-pane via tmux/iTerm2

## Setup

```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
# or add to .claude/settings.json
```

## Ideal Use Cases

- **Parallel PR review**: security agent + performance agent + test coverage agent simultaneously
- **Adversarial investigation**: two agents with competing hypotheses on a bug
- **Cross-layer feature work**: frontend/backend/tests owned by separate agents
- **Builder/Validator pattern**: one agent builds, one validates

## Hooks for Teams

- `TeammateIdle` — fires when a teammate goes idle (exit code 2 to keep it working)
- `TaskCompleted` — fires when a shared task is marked complete
- `SubagentStart` / `SubagentStop` — track teammate lifecycle

## Resources

- [Agent teams docs](https://code.claude.com/docs/en/agent-teams)
- [Addy Osmani: Claude Code Swarms](https://addyosmani.com/blog/claude-code-agent-teams/)
- [paddo.dev: Hidden multi-agent system](https://paddo.dev/blog/claude-code-hidden-swarm/)
