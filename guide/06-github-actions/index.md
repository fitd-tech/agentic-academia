# GitHub Actions & Headless Mode

Running Claude Code without a human in the loop — in CI, on a schedule, or triggered by events.

## Status

> Working examples in `experiments/github-actions/` and `.github/workflows/claude-pr-review.yml`.

## Headless Mode

```bash
claude -p "Run tests and report failures" --output-format json
```

The `-p` flag runs Claude non-interactively. Combine with `--output-format json`
for machine-readable output in CI pipelines.

## GitHub Actions

The `anthropics/claude-code-action@v1` action handles two modes automatically:

**Interactive** (triggered by `@claude` mention in a PR or issue):
```yaml
on: [issue_comment, pull_request_review_comment]
steps:
  - uses: anthropics/claude-code-action@v1
    with:
      anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

**Automated** (scheduled or event-driven, no trigger phrase needed):
```yaml
on:
  push:
    branches: [main]
steps:
  - uses: anthropics/claude-code-action@v1
    with:
      anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
      prompt: "Review this PR for security issues and comment your findings"
```

## Useful Flags

| Flag | Purpose |
|------|---------|
| `--model` | Override model (e.g. `--model opus`) |
| `--output-format json` | Machine-readable output |
| `--worktree` | Isolate to a git worktree |
| `--from-pr <number>` | Pre-load PR diff as context |

## Resources

- [GitHub Actions docs](https://code.claude.com/docs/en/github-actions)
- [Headless mode docs](https://code.claude.com/docs/en/headless)
- [SFEIR CI/CD guide](https://institute.sfeir.com/en/claude-code/claude-code-headless-mode-and-ci-cd/)
