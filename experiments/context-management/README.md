# Context Management

Experiments covering the three main tools for managing context in Claude Code sessions.

## Experiments

### 1. `/compact` in practice

`/compact` compresses the conversation history into a structured summary, freeing context
window space without starting a fresh session. Claude retains the summary but loses raw
message history.

**How to trigger:**
- Type `/compact` at any point in a session
- Claude Code will automatically suggest it when context usage is high

**What gets preserved:**
- Task state (what you were working on)
- Key decisions made during the session
- File paths and code references from the summary
- The summary prompt (see Experiment 2) shapes what's emphasized

**What gets lost:**
- Raw message history — you can no longer scroll up to see earlier turns
- Exact wording of previous responses
- Tool call outputs that weren't referenced in the summary

**When to use it:**
- Long debugging sessions where early turns are no longer relevant
- After finishing a major subtask before starting the next
- When the status bar context percentage turns red

---

### 2. Customizing compact summaries

There are two real mechanisms to shape what `/compact` retains:

**Option A: CLAUDE.md instructions**
Put summary guidance directly in CLAUDE.md. Claude reads this before compacting, so
instructions like "when summarizing, always capture the active experiment and next step"
influence the output. This is the simplest approach.

**Option B: `PreCompact` hook**
The `PreCompact` hook event fires before compaction. A shell script or command can print
additional context to stdout that gets injected into the compact prompt.

```json
{
  "hooks": {
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Focus the summary on: (1) active experiment, (2) key lessons, (3) next step. Include all modified file paths.'"
          }
        ]
      }
    ]
  }
}
```

**Note:** `compactCustomInstructions` is NOT a valid settings key — the schema rejects it.
The `PreCompact` hook is the correct settings-based mechanism.

**What the hook output does:** The printed text is prepended to the compaction prompt,
shaping what Claude emphasizes in the summary. More sophisticated scripts could read
git status, recent edits, or MEMORY.md to produce dynamic context.

---

### 3. Session Continuity

Three mechanisms for resuming work across sessions:

| Mechanism | How | Best for |
|-----------|-----|----------|
| `--continue` | `claude --continue` | Resume the most recent session immediately |
| `--resume <id>` | `claude --resume abc123` | Resume a specific past session by ID |
| MEMORY.md | Auto-loaded via system prompt | Persist decisions and progress across ALL sessions |

**Key insight:** `--continue` / `--resume` restore the raw conversation history (including
tool results), so they use more context than a compacted session. For long-running projects,
the right pattern is: compact aggressively during a session, then use MEMORY.md to carry
forward the distilled knowledge permanently.

**Session IDs:** Visible in `~/.claude/projects/` as directory names. Each session creates
a JSONL transcript file.

**Headless continuity:** In CI, `claude --continue -p "pick up where we left off"` resumes
the last session non-interactively. Combine with `--output-format json` for pipeline use.

## Key Lessons

- `/compact` is lossless for intent, lossy for raw history — use it freely
- `compactCustomInstructions` is NOT a real settings field — the schema rejects it
- The `PreCompact` hook is the real settings-based mechanism for shaping summaries
- CLAUDE.md instructions influence compact output without any hook wiring
- MEMORY.md + `/compact` is the right combination: compact during session, persist to memory at milestones
- `--resume` is useful for forensics (reviewing what Claude did), not just continuation
