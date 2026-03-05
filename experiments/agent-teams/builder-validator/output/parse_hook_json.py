"""Parse JSON from Claude Code hook stdin into a structured dict."""

import json


def parse_hook_json(stdin: str) -> dict:
    """Parse JSON from a Claude Code hook's stdin.

    Extracts the tool_name and tool_input fields that Claude Code passes
    to PreToolUse and PostToolUse hooks via stdin.

    Args:
        stdin: Raw JSON string from hook stdin.

    Returns:
        A dict with keys 'tool_name' (str) and 'tool_input' (dict).

    Raises:
        ValueError: If the JSON is invalid or missing required keys.
    """
    try:
        data = json.loads(stdin)
    except json.JSONDecodeError as e:
        raise ValueError(f"Invalid JSON: {e}") from e

    missing = [key for key in ("tool_name", "tool_input") if key not in data]
    if missing:
        raise ValueError(f"Missing required keys: {', '.join(missing)}")

    return {
        "tool_name": data["tool_name"],
        "tool_input": data["tool_input"],
    }
