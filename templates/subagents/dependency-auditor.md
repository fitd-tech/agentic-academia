# Dependency Auditor

**Pattern:** Context Protection
**When to use:** Audit project dependencies for security vulnerabilities and staleness — without loading large lock files into the main context.

## Configuration

- `run_in_background`: false (main agent needs results before planning remediation)
- `isolation`: none
- Recommended model: haiku

## Prompt Template

```
<!-- paste this as a single Agent call -->

Audit the dependencies in the project at: REPO_PATH

Steps:
1. Read the manifest file (package.json, pyproject.toml, Gemfile, go.mod, or equivalent)
2. Read the lock file if present (package-lock.json, poetry.lock, Gemfile.lock, go.sum)
3. Run the package manager's audit command if available:
   - npm: `npm audit --json`
   - pip: `pip-audit --format json` (if installed)
   - bundler: `bundle audit --format json` (if installed)
4. Identify packages that are more than STALENESS_THRESHOLD_MONTHS months behind their latest version

Return a JSON object:
{
  "package_manager": "npm|pip|bundler|go|other",
  "total_dependencies": <number>,
  "vulnerabilities": [
    {
      "package": "...",
      "installed_version": "...",
      "severity": "critical|high|medium|low",
      "cve": "<CVE ID if available>",
      "recommendation": "upgrade to X.Y.Z or remove"
    }
  ],
  "stale_packages": [
    {
      "package": "...",
      "installed_version": "...",
      "latest_version": "...",
      "months_behind": <number>
    }
  ],
  "summary": "one sentence",
  "priority_action": "the single most important thing to fix first"
}

Do not return the full lock file contents. Do not add commentary outside the JSON.
```

## Customization

- `REPO_PATH`: absolute path to the project root
- `STALENESS_THRESHOLD_MONTHS`: how old is "stale" — typically `6` or `12`
- Run one agent per service in a monorepo (fan-out) if each service has its own manifest
- Add `"license_issues"` to the return shape to catch GPL/AGPL in commercial projects

## Example Output

A compact JSON audit report. The main agent uses it to prioritize upgrades — the full lock file (which can be hundreds of thousands of lines) never enters the main context.
