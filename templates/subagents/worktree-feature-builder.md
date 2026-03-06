# Worktree Feature Builder

**Pattern:** Worktree Isolation
**When to use:** Delegate building a complete feature to a subagent on its own isolated branch, so the main agent's working tree stays clean.

## Configuration

- `run_in_background`: true (feature build can be long-running)
- `isolation`: worktree
- Recommended model: sonnet (feature implementation requires full reasoning capability)

## Prompt Template

```
<!-- paste this as a single Agent call with isolation: "worktree" -->

You are building a new feature on an isolated branch. The main codebase is at: REPO_PATH

Feature specification:
FEATURE_DESCRIPTION

Acceptance criteria:
- CRITERION_1
- CRITERION_2
- CRITERION_3

Instructions:
1. Read the existing codebase structure before writing any code
2. Implement the feature following the conventions in CLAUDE.md
3. Write tests that cover the acceptance criteria
4. Run the test suite and confirm all tests pass
5. Do NOT commit — leave changes staged or unstaged for review

When complete, return a JSON object:
{
  "files_created": ["<path>"],
  "files_modified": ["<path>"],
  "tests_written": ["<test file>:<test name>"],
  "test_result": "pass|fail",
  "notes": "anything the reviewer should know"
}
```

## Customization

- `REPO_PATH`: absolute path to the repo root
- `FEATURE_DESCRIPTION`: detailed spec — the more specific, the better the output
- `CRITERION_N`: measurable acceptance criteria (not vague goals)
- Remove the "do NOT commit" instruction and add a commit step if you want the agent to commit its work
- Run two worktree agents in parallel for two independent features — they won't conflict

## Example Output

The agent builds the feature in an isolated worktree. The main agent receives the JSON summary and can then review, merge, or discard the worktree. If the agent makes no changes, the worktree is cleaned up automatically.

> **Note:** Worktree isolation provides repo isolation, not permission elevation. The subagent inherits the same tool permissions as the main agent.
