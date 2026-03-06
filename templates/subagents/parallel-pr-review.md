# Parallel PR Review

**Pattern:** Fan-Out
**When to use:** Run three independent code review perspectives on a PR simultaneously — cuts review time to the duration of the slowest agent.

## Configuration

- `run_in_background`: true (all three agents)
- `isolation`: none
- Recommended model: haiku (each agent has a focused, bounded task)

## Prompt Template

```
<!-- paste each of these three Agent calls in a single message -->

<!-- Agent 1: Security Review -->
You are a security reviewer. Review the following git diff for security issues only.

Diff:
DIFF_CONTENT

Return a JSON object:
{
  "findings": [{"severity": "high|medium|low", "line": "<file>:<line>", "issue": "...", "recommendation": "..."}],
  "verdict": "pass|needs_changes",
  "summary": "one sentence"
}

If no issues found, return findings: []. Do not add commentary outside the JSON.

<!-- Agent 2: Performance Review -->
You are a performance reviewer. Review the following git diff for performance issues only.
Look for: N+1 queries, missing indexes, unnecessary allocations, blocking I/O, algorithmic complexity regressions.

Diff:
DIFF_CONTENT

Return a JSON object:
{
  "findings": [{"severity": "high|medium|low", "line": "<file>:<line>", "issue": "...", "recommendation": "..."}],
  "verdict": "pass|needs_changes",
  "summary": "one sentence"
}

If no issues found, return findings: []. Do not add commentary outside the JSON.

<!-- Agent 3: Test Coverage Review -->
You are a test coverage reviewer. Review the following git diff.
Identify: new code paths with no test, deleted tests, edge cases not covered, assertions that are too shallow.

Diff:
DIFF_CONTENT

Return a JSON object:
{
  "findings": [{"severity": "high|medium|low", "location": "<file or function>", "issue": "...", "recommendation": "..."}],
  "verdict": "pass|needs_changes",
  "summary": "one sentence"
}

If no issues found, return findings: []. Do not add commentary outside the JSON.
```

## Customization

- `DIFF_CONTENT`: output of `git diff main...HEAD` or the PR diff text
- Add a fourth agent for style/conventions if your project needs it
- Change `haiku` to `sonnet` if the diff is large or the issues are subtle

## Example Output

Three JSON objects (one per agent) returned via background notifications. Synthesize in the main agent by merging findings, deduplicating, and producing a final verdict.
