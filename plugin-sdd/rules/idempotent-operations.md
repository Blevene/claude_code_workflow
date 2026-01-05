---
globs: ["**/*.sh", "**/*.py", "hooks/**/*"]
---

# Idempotent Operations

When adding redundant paths (fallbacks, retries, repairs), make them idempotent.

## Pattern

**Redundancy without idempotency causes loops, churn, or data corruption.**

An operation is idempotent if running it multiple times produces the same result as running it once.

## DO

1. **Check before writing:**
   ```python
   # Good - idempotent
   if not os.path.exists(output_file):
       write_file(output_file, content)
   
   # Bad - overwrites every time
   write_file(output_file, content)
   ```

2. **Use atomic write/rename:**
   ```python
   # Good - atomic
   temp_path = output_path + '.tmp'
   write_file(temp_path, content)
   os.rename(temp_path, output_path)
   
   # Bad - can leave partial file
   write_file(output_path, content)
   ```

3. **Make reconciliation safe to repeat:**
   ```python
   # Good - upsert pattern
   def update_ledger(entry):
       ledger = load_ledger()
       ledger[entry.id] = entry  # Overwrites same ID
       save_ledger(ledger)
   
   # Bad - append pattern
   def update_ledger(entry):
       with open(ledger_file, 'a') as f:
           f.write(entry)  # Duplicates on retry
   ```

4. **Use unique identifiers:**
   ```python
   # Good - deterministic ID
   entry_id = f"{date}-{task_id}-{phase}"
   
   # Bad - timestamp-based (different each call)
   entry_id = datetime.now().isoformat()
   ```

## DON'T

- ❌ Write unconditionally in fallback paths
- ❌ Allow multiple writers to overwrite each other
- ❌ Fire "repair" actions that can trigger more repairs
- ❌ Append to files in hooks (use upsert patterns)
- ❌ Generate new IDs on each retry

## Hook-Specific Guidelines

**PostToolUse hooks:**
```bash
# Good - tracks by file path (idempotent per file)
echo "$TIMESTAMP|$TOOL_NAME|$FILE_PATH" >> "$LOOP_FILE"

# Bad - would duplicate on hook retry
echo "$TIMESTAMP|$TOOL_NAME|$FILE_PATH|$RANDOM_ID" >> "$TRACKING_FILE"
```

**Ledger updates:**
```bash
# Good - update-ledger.sh replaces sections
update_ledger "## State" "$NEW_STATE"

# Bad - appending would duplicate
echo "$NEW_STATE" >> "$LEDGER_FILE"
```

## SDD-Specific Patterns

**Eval results:**
```python
# Good - store by spec_id (overwrites previous run)
results[spec_id] = EvalResult(passed=True, timestamp=now)

# Bad - append results (duplicates on re-run)
results.append(EvalResult(spec_id=spec_id, passed=True))
```

**Traceability matrix:**
```python
# Good - upsert by requirement ID
matrix.update_requirement(req_id, {
    "spec": spec_id,
    "status": "implemented"
})

# Bad - could create duplicate entries
matrix.add_requirement(req_id, spec_id)
```

## Testing Idempotency

Before deploying any hook or script:

1. Run it once, note the output
2. Run it again immediately
3. Verify: Same output? No duplicates? No errors?

```bash
# Test hook idempotency
echo '{"tool_name": "Edit", "tool_input": {"file_path": "test.py"}}' | \
  bash hooks/post-tool-use.sh

# Run again - should produce same result
echo '{"tool_name": "Edit", "tool_input": {"file_path": "test.py"}}' | \
  bash hooks/post-tool-use.sh
```

