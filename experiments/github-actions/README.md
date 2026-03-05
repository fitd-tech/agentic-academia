# Experiment: GitHub Actions & Headless Mode

Two patterns for running Claude without a human in the loop.

## Artifacts

| File | What it demonstrates |
|------|---------------------|
| `headless-audit.sh` | `claude -p` non-interactive mode with `--output-format json` |
| `sample-audit-output.json` | Expected output from headless-audit.sh |
| `.github/workflows/claude-pr-review.yml` | Both interactive (@claude) and automated PR review |

---

## Pattern 1: Headless Mode (`claude -p`)

```bash
claude \
  --output-format json \
  --model claude-haiku-4-5-20251001 \
  -p "Your prompt here"
```

**Key flags:**

| Flag | Purpose |
|------|---------|
| `-p "..."` | Non-interactive — runs prompt and exits |
| `--output-format json` | Machine-readable; useful for piping to `jq` |
| `--model` | Override model; use Haiku for cheap CI tasks |

**Running headless-audit.sh:**

```bash
# From a terminal (NOT inside a Claude Code session — see gotcha below)
export ANTHROPIC_API_KEY=sk-...
bash experiments/github-actions/headless-audit.sh | jq .hooks
```

**Gotcha: nested sessions are blocked.** Claude Code detects the `CLAUDECODE`
environment variable and refuses to launch inside an existing session. Run
headless scripts from a plain terminal or CI runner, not from within Claude.

To bypass in a script (when you're sure it's safe):
```bash
CLAUDECODE="" claude -p "..."
```

---

## Pattern 2: GitHub Actions

Two modes in one workflow (`.github/workflows/claude-pr-review.yml`):

### Interactive (triggered by `@claude` comment)

```yaml
on:
  issue_comment:
    types: [created]
```

Someone writes `@claude explain this change` on a PR →  Claude reads the
comment and context, responds naturally in the PR thread. No prompt needed.

### Automated (triggered by PR push)

```yaml
on:
  pull_request:
    branches: [main]
```

Every PR push → Claude runs a headless audit with a fixed prompt, posts
findings as a review comment. No human trigger needed.

**Required secret:** `ANTHROPIC_API_KEY` in repo Settings → Secrets.

**Required permissions:**
```yaml
permissions:
  contents: read
  pull-requests: write
  issues: write
```

---

## Key Lessons

1. **`claude -p` exits after one response** — it's stateless. For multi-step
   tasks in CI, chain multiple `claude -p` calls or use a single detailed prompt.

2. **`CLAUDECODE` env var blocks nesting** — the guard exists to prevent
   resource exhaustion. Unset it only when you're certain the context is safe.

3. **Haiku for CI, Sonnet/Opus for complex review** — use `--model` to control
   cost. Haiku is 20x cheaper than Opus and sufficient for structured audits.

4. **`--output-format json` enables pipeline composition** — pipe to `jq`, `fx`,
   or save to a file for downstream steps. The JSON includes the full response
   plus metadata (model, usage, stop reason).

5. **Interactive and automated modes compose** — a single workflow can handle
   both `@claude` triggers and automated runs. Use `if:` conditions to route.

6. **`fetch-depth: 0` matters** — `actions/checkout` defaults to shallow clone.
   Claude needs full history for `git diff`, `git log`, and context-aware review.
