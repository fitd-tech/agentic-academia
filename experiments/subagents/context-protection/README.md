# Experiment: Context Protection

Demonstrates using a subagent as a "summarizer firewall" — the subagent reads a
large or noisy file and returns only the signal. The main agent never sees the noise.

## What Was Built

Generated a 90-line mock CI build log (`data/build-log.txt`) containing verbose
output interspersed with errors. Spawned a subagent to read it and return only:
- Lint/type errors (file, line, message)
- Failed tests (name, error)
- Coverage threshold failures
- Final status

**Input:** 90 lines / ~4,500 chars of build log
**Output:** ~30 lines of structured JSON — only actionable failures

## Why This Matters

Without a subagent:
```
Main agent reads build-log.txt
→ 90 lines of [npm install output] [cache hits] [passing tests] pollute context
→ main agent must reason over all of it to find the 5 important lines
→ on a real 10,000-line log, this is genuinely expensive
```

With a subagent:
```
Agent("read log, return only errors/failures")
→ returns 30-line JSON summary
→ main agent works with clean structured data
→ raw log never enters main context window
```

## The Pattern

```
Agent(
  prompt="Read [large file]. Extract only: [specific fields]. Return compact JSON.",
  subagent_type="Explore"  # read-only, fast
)
→ returns compact summary
Main agent uses summary
```

**The key constraint in the prompt:**
- Be explicit about what to extract and what to ignore
- Specify the output format (JSON, table, bullet list)
- "No preamble, no explanation — just the extracted data" prevents wrapping prose

## When to Use This Pattern

| Situation | Use context protection? |
|-----------|------------------------|
| Log file > ~200 lines | Yes |
| Large JSON/YAML config you need 3 fields from | Yes |
| Multiple large files (combine with fan-out) | Yes |
| File < ~50 lines | No — just use Read |
| You need the full content anyway | No |

## Key Lessons

1. **Specify output format explicitly** — without this, the subagent wraps the
   data in prose explanation, partially defeating the purpose.

2. **"Ignore all other output" is load-bearing** — tells the subagent to filter,
   not summarize. Filtering is more reliable than summarizing for structured data.

3. **Explore subagent is ideal** — read-only access, fast, no side effects.
   Use `general-purpose` only if the task involves writing or multi-step reasoning.

4. **The protection is permanent** — even if the main conversation is later
   summarized/compressed, the raw file never entered the context to be summarized.
   This matters for privacy, cost, and coherence.

5. **Fan-out + context protection compose** — you can spawn N subagents each
   reading a different large file. Each returns a compact summary. Main agent
   synthesizes N summaries instead of N large files.
