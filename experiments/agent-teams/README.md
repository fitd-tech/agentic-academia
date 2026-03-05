# Agent Teams Experiments

Hands-on experiments with multi-agent peer coordination (requires Opus 4.6+).

## Prerequisites

```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

## Experiments

1. **[builder-validator/](builder-validator/)** — Builder writes a function, Validator reviews it; demonstrates shared task list + dependency blocking

## Suggested Starting Points

1. **Builder/Validator** — one agent writes a function, a second agent reviews and critiques it
2. **Parallel PR review** — one agent checks security, another checks performance
3. **Root cause investigation** — two agents with competing hypotheses debug the same issue
