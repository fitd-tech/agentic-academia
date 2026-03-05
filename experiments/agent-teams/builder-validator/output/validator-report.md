# Validator Report: parse_hook_json.py

## Verdict: FAIL

Two unhandled edge cases that raise uncaught exceptions instead of the documented `ValueError`.

---

## Findings

### FAIL - Line 22: `None` input raises uncaught `TypeError`

`json.loads(None)` raises `TypeError`, not `json.JSONDecodeError`. The `except` block on line 23 only catches `JSONDecodeError`, so passing `None` produces an unhandled `TypeError` instead of the documented `ValueError`.

**Reproduce:**
```python
parse_hook_json(None)  # TypeError: the JSON object must be str, bytes or bytearray, not NoneType
```

**Fix:** Catch `TypeError` alongside `JSONDecodeError` on line 23, or add an early guard:
```python
if not isinstance(stdin, str):
    raise ValueError(f"Expected str, got {type(stdin).__name__}")
```

### FAIL - Line 26: Non-dict JSON input raises uncaught `TypeError`

If stdin is valid JSON but not an object (e.g., `"[]"`, `"123"`, `"null"`), `json.loads` succeeds but the `in` operator on line 26 raises `TypeError` for non-iterable types or gives wrong results for lists.

**Reproduce:**
```python
parse_hook_json("123")   # TypeError: argument of type 'int' is not iterable
parse_hook_json("null")  # TypeError: argument of type 'NoneType' is not iterable
parse_hook_json("[]")    # Returns misleading "Missing required keys" (correct message, but by accident)
```

**Fix:** Add a type check after parsing:
```python
if not isinstance(data, dict):
    raise ValueError(f"Expected JSON object, got {type(data).__name__}")
```

### PASS - Missing required keys (line 26-28)

Correctly detects and reports missing `tool_name` and/or `tool_input` with a clear message listing which keys are absent.

### PASS - Extra keys in input

Extra keys are silently dropped by the return dict on lines 30-33. This is correct -- the function returns only the documented keys.

### PASS - Empty string input

`json.loads("")` raises `JSONDecodeError`, which is caught on line 23 and re-raised as `ValueError`. Works as documented.

### PASS - Docstring and type hints (lines 7-19)

Docstring is complete with Args, Returns, and Raises sections. Type hints are present. Minor note: return type `dict` could be more specific (e.g., `dict[str, str | dict]`) but this is not a failure.

---

## Summary

| Check              | Result |
|--------------------|--------|
| Valid JSON parsing  | PASS   |
| Invalid JSON        | PASS   |
| Empty string        | PASS   |
| None input          | FAIL   |
| Non-dict JSON       | FAIL   |
| Missing keys        | PASS   |
| Extra keys          | PASS   |
| Docstring           | PASS   |
| Type hints          | PASS   |
