# Build Log Analyzer

**Pattern:** Context Protection
**When to use:** A CI build or test run produced a large, noisy log. Extract only the failures and root causes — without loading the full log into the main context.

## Configuration

- `run_in_background`: false (main agent needs the analysis before proceeding)
- `isolation`: none
- Recommended model: haiku

## Prompt Template

```
<!-- paste this as a single Agent call -->

Read the build/test log at: LOG_FILE_PATH

Your job is to extract actionable failure information only. Ignore passing tests, progress bars, timestamps, and informational lines.

Return a JSON object with this exact shape:
{
  "total_failures": <number>,
  "failures": [
    {
      "type": "test_failure|compile_error|lint_error|runtime_error",
      "file": "<file path if available>",
      "line": "<line number if available>",
      "message": "<error message, max 2 lines>",
      "root_cause": "<your best inference of the cause, one sentence>"
    }
  ],
  "flaky_suspects": ["<test names that look timing-dependent or environment-dependent>"],
  "summary": "one sentence describing the overall failure pattern"
}

If the build passed with no failures, return: {"total_failures": 0, "failures": [], "summary": "all checks passed"}
Do not add commentary outside the JSON.
```

## Customization

- `LOG_FILE_PATH`: absolute path to the log file (e.g. `/tmp/ci-run-123.log`)
- Pipe CI output to a temp file first: `npm test 2>&1 > /tmp/test-log.txt`
- Add `"suggested_fix"` to the failure shape if you want the agent to propose solutions
- For multi-stage pipelines, run one agent per stage log in parallel (fan-out pattern)

## Example Output

A JSON object with 5-15 failure entries extracted from a 2000-line log. The main agent uses the structured output to plan fixes — the raw log never enters its context.
