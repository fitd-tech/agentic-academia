# Parallel File Analyzer

**Pattern:** Fan-Out (generic)
**When to use:** Run the same analysis goal across N independent files simultaneously. Replace ANALYSIS_GOAL and FILE_LIST with your specifics.

## Configuration

- `run_in_background`: true (all agents)
- `isolation`: none
- Recommended model: haiku

## Prompt Template

```
<!-- Spawn one Agent call per file — all in a single message for true parallelism -->

<!-- Agent for FILE_PATH_1 -->
Analyze the file at: FILE_PATH_1

Goal: ANALYSIS_GOAL

Return a JSON object:
{
  "file": "FILE_PATH_1",
  "findings": [{"location": "<function or line>", "issue": "...", "severity": "high|medium|low"}],
  "summary": "one sentence",
  "recommendation": "one sentence on the most important action"
}

Return only JSON. No commentary outside the JSON.

<!-- Agent for FILE_PATH_2 -->
Analyze the file at: FILE_PATH_2

Goal: ANALYSIS_GOAL

Return a JSON object:
{
  "file": "FILE_PATH_2",
  "findings": [{"location": "<function or line>", "issue": "...", "severity": "high|medium|low"}],
  "summary": "one sentence",
  "recommendation": "one sentence on the most important action"
}

Return only JSON. No commentary outside the JSON.

<!-- Repeat for each additional file -->
```

## Customization

- `FILE_PATH_N`: absolute paths to each file
- `ANALYSIS_GOAL`: what each agent should look for, e.g.:
  - `"Identify all functions with cyclomatic complexity > 10"`
  - `"Find any hardcoded credentials, API keys, or secrets"`
  - `"Check for missing error handling in async functions"`
  - `"Identify deprecated API usage"`
- To generate the Agent calls programmatically, loop over `glob("src/**/*.ts")` and build one Agent call per result

## Example Output

N JSON objects (one per file) returned via background notifications. The main agent collects all results, merges the `findings` arrays, sorts by severity, and presents a unified report.
