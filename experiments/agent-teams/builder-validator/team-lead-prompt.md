# Team Lead Prompt: Builder/Validator

Use this prompt to start a Builder/Validator agent team from a Claude Code session
with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` set.

---

## Prompt (paste into Team Lead session)

```
We're running a Builder/Validator agent team experiment.

Your role: Team Lead — coordinate two teammates.

## Team Setup

Spawn two teammates:
1. **Builder** — writes a Python function
2. **Validator** — reviews Builder's output, reports issues

## Task

Builder's goal: write a Python function `parse_hook_json(stdin: str) -> dict` that:
- Parses JSON from a Claude Code hook's stdin
- Returns a dict with keys: tool_name, tool_input
- Raises ValueError with a clear message if JSON is invalid or missing required keys
- Has a docstring and type hints

Validator's goal: after Builder completes, review the function for:
- Correctness (does it handle edge cases?)
- Missing error cases (empty string, extra keys, None input)
- Code quality (docstring complete? type hints accurate?)

Report findings as: PASS / FAIL with specific line references.

## Coordination

1. Create shared tasks:
   - Task A: "Builder writes parse_hook_json" (assign to Builder)
   - Task B: "Validator reviews parse_hook_json" (assign to Validator, blocked by A)

2. Tell Builder to write the function to:
   `experiments/agent-teams/builder-validator/output/parse_hook_json.py`

3. Tell Validator to read that file and write their review to:
   `experiments/agent-teams/builder-validator/output/validator-report.md`

4. When both complete, summarize: what did Builder produce, what did Validator find?

Begin.
```

---

## How to Run

```bash
# 1. Set env var (or add to .claude/settings.json)
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

# 2. Start Claude Code in this repo
cd /path/to/agentic-academia
claude

# 3. Paste the prompt above into the Team Lead session

# 4. Use Shift+Down to cycle between teammates and watch them coordinate
```

## What to Watch For

- Teammates share a task list — Validator's task is blocked until Builder's completes
- Teammates communicate via broadcast/message — watch for Builder signaling completion
- Plan approval gate — Validator stays read-only until Team Lead approves its plan
- Each teammate has its own context window — they don't see each other's full output
