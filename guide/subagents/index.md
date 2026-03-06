# Subagent Patterns

Subagents (spawned via the `Agent` tool) let the main agent delegate work to
isolated child processes. Each subagent gets its own context window, toolset,
and execution environment.

## When to Use Subagents

| Situation | Use subagent? |
|-----------|---------------|
| Analyzing N independent files | Yes — fan-out/fan-in |
| Large/noisy file you only need a summary of | Yes — context protection |
| Concurrent edits to the same repo | Yes — worktree isolation |
| Reading one small file | No — use Read directly |
| Simple grep/search | No — use Grep directly |

## Core Patterns

### 1. Fan-Out / Fan-In

Spawn N subagents in parallel, collect results, synthesize in main.

```
# Key: all Agent calls in the same response message
Agent(file_1, run_in_background=true)
Agent(file_2, run_in_background=true)
Agent(file_3, run_in_background=true)
  ↓ wait for notifications
Synthesize results
```

**Rules:**
- All agents must be launched in a single message to run in parallel
- Use `run_in_background: true`
- Pass all needed context in the prompt — subagents don't share state

See: `experiments/subagents/parallel-analysis/`

### 2. Context Protection

Delegate reading a large/complex file to a subagent that returns only a summary.
The raw content never enters the main context window.

```
Agent("Summarize this 5000-line file, return only: X, Y, Z")
  → returns compact summary
Main agent works with summary, not raw file
```

See: `experiments/subagents/context-protection/`

### 3. Worktree Isolation

Use `isolation: "worktree"` to give a subagent its own copy of the repo.
Multiple subagents can edit the same files concurrently without conflicts.

```
Agent(task_A, isolation="worktree")  # works on branch-A
Agent(task_B, isolation="worktree")  # works on branch-B
  ↓ both complete
Merge or review changes independently
```

See: `experiments/subagents/worktree-isolation/`

## Subagent Types

| Type | Best for |
|------|----------|
| `general-purpose` | Multi-step tasks, code execution, writing |
| `Explore` | Read-only codebase analysis, searches |
| `Plan` | Designing implementation strategies |

## Key Constraints

- Subagents don't share context with the main agent or each other
- Each subagent starts a fresh session — no memory of prior calls
- Tool access depends on subagent type
- `run_in_background: true` required for true parallelism

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
