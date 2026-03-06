# Subagents

You already know the basics. This section focuses on production patterns —
worktree isolation, scoping, and when subagents are the right tool vs. Agent Teams.

## Status

> Work in progress. See `experiments/subagents/` for working examples.

## When to Use Subagents

- Focused, isolated tasks where only the result matters
- Parallel independent work (multiple subagents on different files)
- Protecting the main context window from large tool outputs
- Tasks with a clear, bounded scope

## Worktree Isolation

New in late 2025: subagents can get their own isolated git worktree.
Multiple agents can work on the same repo in parallel without conflicts.

```json
// In agent definition
{
  "isolation": "worktree"
}
```

Or via CLI flag: `--worktree`

The `WorktreeCreate` and `WorktreeRemove` hooks let you customize the lifecycle.

## Subagents vs. Agent Teams

| | Subagents | Agent Teams |
|---|---|---|
| Communication | Report to caller only | Peer-to-peer messaging |
| Coordination | Caller manages | Shared task list, self-organize |
| Cost | Lower | Higher (scales with team size) |
| Best for | Focused isolated tasks | Complex cross-cutting work |

## Starter Templates

Paste-and-customize Agent prompts for the most common subagent use cases.
All templates live in [`templates/subagents/`](../../templates/subagents/).

| Template | Pattern | Use case |
|----------|---------|----------|
| `parallel-pr-review.md` | Fan-out | 3 agents review a PR: security, performance, test coverage |
| `codebase-onboarding.md` | Context protection | Read a large codebase, return a structured summary |
| `build-log-analyzer.md` | Context protection | Extract failures and root causes from noisy build output |
| `parallel-file-analyzer.md` | Fan-out (generic) | Analyze N files simultaneously; fill in your own goal |
| `worktree-feature-builder.md` | Worktree isolation | Build a complete feature on an isolated branch |
| `dependency-auditor.md` | Context protection | Audit dependencies for vulnerabilities and staleness |

## Resources

- [Claude Code subagents docs](https://code.claude.com/docs/en/)
- [Enabling autonomy blog post](https://www.anthropic.com/news/enabling-claude-code-to-work-more-autonomously)
