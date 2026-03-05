# Experiment: Builder/Validator Agent Team

Demonstrates the core Agent Teams pattern: two peer agents coordinating via a
shared task list, where one agent's output gates the other's work.

## Status

> Ran live on 2026-03-05 with Opus 4.6 + `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`.
> See `output/` for Builder's code and Validator's review.

## Live Results

**Builder** wrote `parse_hook_json.py` — clean 33-line function with docstring, type hints,
and `json.JSONDecodeError` handling.

**Validator** reviewed and found **2 bugs** (verdict: FAIL):
1. `None` input → uncaught `TypeError` (only `JSONDecodeError` caught)
2. Non-dict JSON (`"123"`, `"null"`) → uncaught `TypeError` on `in` operator

Five other checks passed (empty string, missing keys, extra keys, docstring, type hints).

**Timeline observations:**
- Validator auto-waited while Task #1 was blocked — checked task list and reported "waiting"
- Builder completed independently — no inter-agent communication needed for the handoff
- Validator noticed Task #1 completion and started review before Team Lead's nudge arrived
- Both agents went idle between turns (normal behavior — idle ≠ done)
- Clean shutdown via `shutdown_request` → both approved and terminated

## The Pattern

```
Team Lead
  ├── spawns Builder   → writes parse_hook_json.py
  └── spawns Validator → reviews parse_hook_json.py (blocked until Builder done)

Shared task list:
  Task A: "Builder writes parse_hook_json"     [Builder]    → in_progress → completed
  Task B: "Validator reviews parse_hook_json"  [Validator]  → blocked → in_progress → completed

Team Lead synthesizes findings.
```

## Why Builder/Validator?

This pattern is the clearest demonstration of what makes Agent Teams different
from subagents:

| Subagent (Agent tool) | Agent Team |
|----------------------|------------|
| Reports only to calling agent | Peers — communicate directly |
| Caller orchestrates all coordination | Teammates self-coordinate via shared tasks |
| Sequential or parallel fan-out | Dependency-aware: Validator waits for Builder |
| No shared state | Shared task list + mailbox |

With subagents you'd have to manually pipe Builder's output to Validator.
With Agent Teams, the task dependency handles this automatically.

## Architecture: What Peers Share

- **Task list**: `~/.claude/tasks/{team-name}/` — file-locked, all peers read/write
- **Mailbox**: teammates can `broadcast` (all) or `message` (individual) each other
- **Plan approval gate**: new teammates stay read-only until Team Lead approves their plan

## Key Differences from Subagents

1. **Peer topology, not tree** — teammates don't report "up"; they coordinate laterally
2. **Shared task list** — all agents see the same task state; blocking is automatic
3. **Direct communication** — Builder can message Validator "I'm done, here's the path"
4. **In-process display** — Shift+Down cycles between teammates in the same terminal

## When to Use Agent Teams vs Subagents

Use **Agent Teams** when:
- Tasks have dependencies (B waits for A's output)
- Agents need to negotiate or iterate with each other
- You want adversarial review (competing hypotheses, critic/creator)
- Work spans multiple long-running parallel tracks

Use **Subagents** (Agent tool) when:
- Tasks are fully independent (true fan-out)
- You need results synthesized back to main
- Tasks are short and don't need inter-agent communication
- You want isolation (each agent is ephemeral)

## Hooks That Work With Teams

| Hook | When it fires | Use case |
|------|--------------|----------|
| `TeammateIdle` | Teammate goes idle | Assign new work (exit 2 to keep it active) |
| `TaskCompleted` | Shared task marked done | Trigger downstream tasks |
| `SubagentStart` | Teammate spawned | Log team composition |
| `SubagentStop` | Teammate exits | Detect failure, re-assign |

## Files

- `team-lead-prompt.md` — ready-to-paste prompt for starting the team
- `output/parse_hook_json.py` — Builder's implementation
- `output/validator-report.md` — Validator's review (FAIL, 2 bugs, 7 passes)
