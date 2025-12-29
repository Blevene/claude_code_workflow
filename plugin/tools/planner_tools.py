#!/usr/bin/env python
"""Planner tools: validate planner output against the schema and basic structure."""

import argparse, json
from pathlib import Path
from typing import Any, Dict, List

SCHEMA_PATH = Path(".claude") / "schemas" / "planner_task_schema.json"

def load_json_with_heuristics(path: Path) -> Any:
    text = path.read_text(encoding="utf-8").strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass
    if "```" in text:
        parts = text.split("```")
        for i in range(1, len(parts), 2):
            block = parts[i]
            lines = block.splitlines()
            if not lines:
                continue
            if lines[0].strip().lower() in {"json", "jsonc"}:
                candidate = "\n".join(lines[1:]).strip()
            else:
                candidate = block.strip()
            try:
                return json.loads(candidate)
            except json.JSONDecodeError:
                continue
    raise SystemExit(f"[error] Could not parse JSON (even with heuristics): {path}")

def load_schema() -> Dict[str, Any]:
    if not SCHEMA_PATH.exists():
        raise SystemExit(f"[error] schema not found at {SCHEMA_PATH}")
    try:
        return json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        raise SystemExit(f"[error] invalid schema JSON: {SCHEMA_PATH}: {e}")

def validate_structural(plan: Any) -> List[str]:
    issues: List[str] = []
    if not isinstance(plan, dict):
        issues.append(f"Root is {type(plan).__name__}, expected object.")
        return issues
    tasks = plan.get("tasks")
    meta = plan.get("meta")
    if tasks is None:
        issues.append("Missing top-level 'tasks'.")
    if meta is None:
        issues.append("Missing top-level 'meta'.")
    if isinstance(tasks, list):
        for idx, t in enumerate(tasks):
            if not isinstance(t, dict):
                issues.append(f"tasks[{idx}] is {type(t).__name__}, expected object.")
                continue
            for field in ("id", "title", "owner_agent", "status"):
                if field not in t:
                    issues.append(f"tasks[{idx}] missing '{field}'.")
    return issues

def validate_with_schema(plan: Any) -> List[str]:
    try:
        import jsonschema  # type: ignore
    except ImportError:
        return ["jsonschema library not installed; skipping JSON Schema validation."]
    from jsonschema import Draft202012Validator  # type: ignore
    schema = load_schema()
    v = Draft202012Validator(schema)
    errors: List[str] = []
    for err in sorted(v.iter_errors(plan), key=lambda e: e.path):
        path = "/".join(str(p) for p in err.path) or "<root>"
        errors.append(f"{path}: {err.message}")
    return errors

def cmd_validate(args: argparse.Namespace) -> int:
    path = Path(args.plan_file)
    if not path.exists():
        print(f"[error] file does not exist: {path}")
        return 1
    plan = load_json_with_heuristics(path)
    issues = validate_structural(plan)
    schema_issues = validate_with_schema(plan)
    issues.extend(schema_issues)
    non_schema = [m for m in issues if "jsonschema library not installed" not in m]
    if non_schema:
        print(f"[warn] {len(non_schema)} issue(s) in plan:")
        for m in non_schema:
            print(f"  - {m}")
        return 1
    if issues:
        for m in issues:
            print(f"[info] {m}")
    print(f"[ok] {path} passes structural (and schema, if available) validation.")
    return 0

def main():
    parser = argparse.ArgumentParser(description="Planner tools.")
    sub = parser.add_subparsers(dest="command", required=True)
    p_val = sub.add_parser("validate", help="Validate planner JSON output.")
    p_val.add_argument("plan_file")
    p_val.set_defaults(func=cmd_validate)
    args = parser.parse_args()
    raise SystemExit(args.func(args))

if __name__ == "__main__":
    main()
