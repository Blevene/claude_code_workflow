#!/usr/bin/env python
"""Traceability matrix tools: init, validate, gap check, summary."""

import argparse, json
from pathlib import Path
from typing import Any, Dict, List

# Schema is in the same directory as this tool (plugin/tools/../schemas/)
TOOL_DIR = Path(__file__).parent
SCHEMA_PATH = TOOL_DIR.parent / "schemas" / "traceability_matrix_schema.json"

DEFAULT_MATRIX = {
    "meta": {
        "version": 1,
        "description": "Traceability matrix linking EARS requirements to specs, evals, tasks, design, and code."
    },
    "requirements": []
}

def load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        raise SystemExit(f"[error] invalid JSON: {path}: {e}")

def validate_structural(matrix: Any) -> List[str]:
    issues: List[str] = []
    if not isinstance(matrix, dict):
        issues.append(f"Root is {type(matrix).__name__}, expected object.")
        return issues
    reqs = matrix.get("requirements")
    if reqs is None:
        issues.append("Missing 'requirements' array.")
        return issues
    if not isinstance(reqs, list):
        issues.append("'requirements' is not an array.")
        return issues
    for idx, r in enumerate(reqs):
        if not isinstance(r, dict):
            issues.append(f"requirements[{idx}] is {type(r).__name__}, expected object.")
            continue
        if "id" not in r:
            issues.append(f"requirements[{idx}] missing 'id'.")
        if "ears" not in r:
            issues.append(f"requirements[{idx}] missing 'ears'.")
    return issues

def validate_with_schema(matrix: Any) -> List[str]:
    try:
        import jsonschema  # type: ignore
    except ImportError:
        return ["jsonschema library not installed; skipping schema validation."]
    from jsonschema import Draft202012Validator  # type: ignore
    try:
        schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        return [f"Invalid schema JSON: {SCHEMA_PATH}: {e}"]
    v = Draft202012Validator(schema)
    errs: List[str] = []
    for err in sorted(v.iter_errors(matrix), key=lambda e: e.path):
        path = "/".join(str(p) for p in err.path) or "<root>"
        errs.append(f"{path}: {err.message}")
    return errs

def analyze_gaps(matrix: Dict[str, Any]) -> Dict[str, List[Dict[str, Any]]]:
    reqs: List[Dict[str, Any]] = matrix.get("requirements", [])
    missing_code: List[Dict[str, Any]] = []
    missing_specs: List[Dict[str, Any]] = []
    missing_evals: List[Dict[str, Any]] = []
    missing_tasks: List[Dict[str, Any]] = []
    for r in reqs:
        rid = r.get("id", "<unknown>")
        ears = r.get("ears", "")
        code = r.get("code") or []
        specs = r.get("specs") or []
        evals = r.get("evals") or []
        tasks = r.get("tasks") or []
        if not code:
            missing_code.append({"id": rid, "ears": ears})
        if not specs:
            missing_specs.append({"id": rid, "ears": ears})
        if not evals:
            missing_evals.append({"id": rid, "ears": ears})
        if not tasks:
            missing_tasks.append({"id": rid, "ears": ears})
    return {
        "missing_code": missing_code,
        "missing_specs": missing_specs,
        "missing_evals": missing_evals,
        "missing_tasks": missing_tasks,
    }

def cmd_init(args: argparse.Namespace) -> int:
    path = Path(args.matrix_file)
    if path.exists() and not args.force:
        print(f"[warn] {path} already exists. Use --force to overwrite.")
        return 1
    path.write_text(json.dumps(DEFAULT_MATRIX, indent=2), encoding="utf-8")
    print(f"[ok] initialized empty traceability matrix at {path}")
    return 0

def cmd_validate(args: argparse.Namespace) -> int:
    path = Path(args.matrix_file)
    if not path.exists():
        print(f"[error] file does not exist: {path}")
        return 1
    matrix = load_json(path)
    issues = validate_structural(matrix)
    schema_issues = validate_with_schema(matrix)
    issues.extend(schema_issues)
    non_schema = [m for m in issues if "jsonschema library not installed" not in m]
    if non_schema:
        print(f"[warn] {len(non_schema)} issue(s) in matrix:")
        for m in non_schema:
            print(f"  - {m}")
        return 1
    if issues:
        for m in issues:
            print(f"[info] {m}")
    print(f"[ok] {path} passes structural (and schema, if available) validation.")
    return 0

def cmd_check_gaps(args: argparse.Namespace) -> int:
    path = Path(args.matrix_file)
    if not path.exists():
        print(f"[error] file does not exist: {path}")
        return 1
    matrix = load_json(path)
    gaps = analyze_gaps(matrix)

    def show(label: str, items: List[Dict[str, Any]]):
        print(f"{label}: {len(items)}")
        for r in items[: args.max_show]:
            ears = r["ears"]
            short = ears[:80] + ("..." if len(ears) > 80 else "")
            print(f"  - {r['id']}: {short}")
        if len(items) > args.max_show:
            print(f"    ... ({len(items) - args.max_show} more)")

    show("Requirements missing specs", gaps["missing_specs"])
    print()
    show("Requirements missing evals", gaps["missing_evals"])
    print()
    show("Requirements missing code", gaps["missing_code"])
    print()
    show("Requirements missing tasks", gaps["missing_tasks"])

    total = sum(len(v) for v in gaps.values())
    return 1 if total > 0 else 0

def cmd_summary(args: argparse.Namespace) -> int:
    path = Path(args.matrix_file)
    if not path.exists():
        print(f"[error] file does not exist: {path}")
        return 1
    matrix = load_json(path)
    reqs: List[Dict[str, Any]] = matrix.get("requirements", [])
    total = len(reqs)
    by_status = {}
    by_priority = {}
    with_specs = 0
    with_evals = 0
    with_code = 0
    for r in reqs:
        st = r.get("status", "unknown")
        pr = r.get("priority", "unspecified")
        by_status[st] = by_status.get(st, 0) + 1
        by_priority[pr] = by_priority.get(pr, 0) + 1
        if r.get("specs"):
            with_specs += 1
        if r.get("evals"):
            with_evals += 1
        if r.get("code"):
            with_code += 1
    if args.markdown:
        print(f"# Traceability Summary for {path.name}\n")
        print(f"- Total requirements: **{total}**")
        print(f"- With specs: **{with_specs}**")
        print(f"- With evals: **{with_evals}**")
        print(f"- With code: **{with_code}**")
        print(f"- By status:")
        for st, count in sorted(by_status.items()):
            print(f"  - `{st}`: {count}")
        print(f"- By priority:")
        for pr, count in sorted(by_priority.items()):
            print(f"  - `{pr}`: {count}")
    else:
        print(f"Traceability Summary for {path.name}")
        print(f"  Total requirements: {total}")
        print(f"  With specs: {with_specs}")
        print(f"  With evals: {with_evals}")
        print(f"  With code: {with_code}")
        print("  By status:")
        for st, count in sorted(by_status.items()):
            print(f"    - {st}: {count}")
        print("  By priority:")
        for pr, count in sorted(by_priority.items()):
            print(f"    - {pr}: {count}")
    return 0

def main():
    parser = argparse.ArgumentParser(description="Traceability matrix tools.")
    sub = parser.add_subparsers(dest="command", required=True)
    p_init = sub.add_parser("init", help="Initialize an empty matrix file.")
    p_init.add_argument("matrix_file")
    p_init.add_argument("--force", action="store_true")
    p_init.set_defaults(func=cmd_init)
    p_val = sub.add_parser("validate", help="Validate matrix structure and schema.")
    p_val.add_argument("matrix_file")
    p_val.set_defaults(func=cmd_validate)
    p_gap = sub.add_parser("check-gaps", help="Show requirements missing specs/evals/code/tasks.")
    p_gap.add_argument("matrix_file")
    p_gap.add_argument("--max-show", type=int, default=10)
    p_gap.set_defaults(func=cmd_check_gaps)
    p_sum = sub.add_parser("summary", help="Summarize matrix.")
    p_sum.add_argument("matrix_file")
    p_sum.add_argument("--markdown", action="store_true")
    p_sum.set_defaults(func=cmd_summary)
    args = parser.parse_args()
    raise SystemExit(args.func(args))

if __name__ == "__main__":
    main()
