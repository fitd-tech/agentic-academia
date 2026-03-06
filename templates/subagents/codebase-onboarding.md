# Codebase Onboarding

**Pattern:** Context Protection
**When to use:** Explore a large or unfamiliar codebase and get a structured summary — without flooding the main context window with raw file contents.

## Configuration

- `run_in_background`: false (sequential — main agent waits for summary before continuing)
- `isolation`: none
- Recommended model: haiku (reading and summarizing, no complex reasoning needed)

## Prompt Template

```
<!-- paste this as a single Agent call -->

You are exploring a codebase located at: REPO_PATH

Your job is to read the codebase and return a structured summary. Do NOT include raw file contents in your response.

Steps:
1. Read the top-level directory listing
2. Read CLAUDE.md, README.md, and package.json (or equivalent manifest) if they exist
3. Identify the entry point(s) — main file, server start, CLI entrypoint
4. Identify the top 5 most-edited or most-imported modules
5. Note the test setup (framework, where tests live, how to run them)

Return a JSON object with this exact shape:
{
  "stack": {"language": "...", "framework": "...", "package_manager": "..."},
  "entry_points": ["<file>:<function or route>"],
  "key_modules": [{"path": "...", "responsibility": "one sentence"}],
  "test_setup": {"framework": "...", "test_dir": "...", "run_command": "..."},
  "conventions": ["list of conventions found in CLAUDE.md or README"],
  "open_questions": ["anything unclear that the main agent should investigate"]
}

Do not add commentary outside the JSON.
```

## Customization

- `REPO_PATH`: absolute path to the repo root (e.g. `/Users/you/projects/myapp`)
- Add fields to the JSON shape for domain-specific information (e.g., `"api_routes"`, `"database_schema"`)
- To narrow scope, restrict the agent to a subdirectory (`src/`, `services/auth/`)

## Example Output

A compact JSON summary (~30 lines) that the main agent uses to orient itself. The raw file tree, README contents, and source files never enter the main context.
