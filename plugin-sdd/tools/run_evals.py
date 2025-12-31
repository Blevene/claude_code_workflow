#!/usr/bin/env python
"""Eval runner: discover and run evals, report results."""

import argparse
import importlib.util
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, List, Optional

@dataclass
class EvalResult:
    """Result of an eval run."""
    passed: bool
    spec_id: str
    description: str
    expected: Any
    actual: Any = None
    error: Optional[str] = None

def discover_evals(evals_dir: Path, module: Optional[str] = None) -> List[Path]:
    """Find all eval files in the evals directory."""
    if not evals_dir.exists():
        return []

    pattern = "eval_*.py"
    if module:
        search_dir = evals_dir / module
        if search_dir.exists():
            return list(search_dir.glob(pattern))
        return []

    return list(evals_dir.rglob(pattern))

def load_eval_module(eval_path: Path):
    """Dynamically load an eval module."""
    spec = importlib.util.spec_from_file_location(eval_path.stem, eval_path)
    if spec is None or spec.loader is None:
        return None
    module = importlib.util.module_from_spec(spec)
    sys.modules[eval_path.stem] = module
    try:
        spec.loader.exec_module(module)
        return module
    except Exception as e:
        print(f"[error] Failed to load {eval_path}: {e}")
        return None

def run_eval_file(eval_path: Path) -> List[EvalResult]:
    """Run all evals in a single eval file."""
    module = load_eval_module(eval_path)
    if module is None:
        return [EvalResult(
            passed=False,
            spec_id="<unknown>",
            description=f"Failed to load {eval_path.name}",
            expected="module to load",
            error="Module load failed"
        )]

    results: List[EvalResult] = []

    # Look for SpecEval class with run_all method
    for name in dir(module):
        obj = getattr(module, name)
        if isinstance(obj, type) and hasattr(obj, 'run_all'):
            try:
                instance = obj()
                eval_results = instance.run_all()
                if isinstance(eval_results, list):
                    for r in eval_results:
                        if hasattr(r, 'passed'):
                            results.append(r)
            except Exception as e:
                results.append(EvalResult(
                    passed=False,
                    spec_id=getattr(obj, 'spec_id', '<unknown>'),
                    description=f"Error running {name}",
                    expected="eval to run",
                    error=str(e)
                ))

    # If no class found, look for eval_ functions
    if not results:
        for name in dir(module):
            if name.startswith('eval_') and callable(getattr(module, name)):
                func = getattr(module, name)
                try:
                    result = func()
                    if hasattr(result, 'passed'):
                        results.append(result)
                except Exception as e:
                    results.append(EvalResult(
                        passed=False,
                        spec_id="<unknown>",
                        description=f"Error running {name}",
                        expected="eval to run",
                        error=str(e)
                    ))

    return results

def print_results(results: List[EvalResult], verbose: bool = False) -> int:
    """Print eval results and return exit code."""
    if not results:
        print("[info] No evals found or run.")
        return 0

    passed = sum(1 for r in results if r.passed)
    total = len(results)

    print()
    print("=" * 60)
    print("EVAL RESULTS")
    print("=" * 60)
    print()

    # Group by spec_id
    by_spec: dict = {}
    for r in results:
        if r.spec_id not in by_spec:
            by_spec[r.spec_id] = []
        by_spec[r.spec_id].append(r)

    for spec_id, spec_results in sorted(by_spec.items()):
        spec_passed = sum(1 for r in spec_results if r.passed)
        spec_total = len(spec_results)
        status = "PASS" if spec_passed == spec_total else "FAIL"
        print(f"{spec_id}: {spec_passed}/{spec_total} [{status}]")

        for r in spec_results:
            icon = "+" if r.passed else "x"
            print(f"  [{icon}] {r.description}")
            if not r.passed and (verbose or r.error):
                if r.error:
                    print(f"      Error: {r.error}")
                else:
                    print(f"      Expected: {r.expected}")
                    print(f"      Actual: {r.actual}")
        print()

    print("=" * 60)
    status = "ALL PASSING" if passed == total else "FAILURES"
    print(f"Results: {passed}/{total} passed [{status}]")
    print("=" * 60)
    print()

    return 0 if passed == total else 1

def cmd_run(args: argparse.Namespace) -> int:
    """Run evals command."""
    project_dir = Path(args.project_dir)
    evals_dir = project_dir / "evals"

    if not evals_dir.exists():
        print(f"[error] evals directory not found: {evals_dir}")
        return 1

    eval_files = discover_evals(evals_dir, args.module if hasattr(args, 'module') else None)

    if not eval_files:
        if hasattr(args, 'module') and args.module:
            print(f"[info] No evals found for module: {args.module}")
        else:
            print("[info] No evals found in evals/")
        return 0

    all_results: List[EvalResult] = []
    for eval_file in eval_files:
        if not args.summary:
            print(f"Running: {eval_file.relative_to(project_dir)}")
        results = run_eval_file(eval_file)
        all_results.extend(results)

    return print_results(all_results, verbose=not args.summary)

def main():
    parser = argparse.ArgumentParser(description="Run evals to validate implementation.")
    parser.add_argument("--all", action="store_true", help="Run all evals")
    parser.add_argument("--module", type=str, help="Run evals for specific module")
    parser.add_argument("--spec", type=str, help="Run evals for specific spec ID")
    parser.add_argument("--summary", action="store_true", help="Show summary only")
    parser.add_argument("--project-dir", type=str, default=".", help="Project directory")

    args = parser.parse_args()

    if not args.all and not args.module and not args.spec:
        # Default to running all
        args.all = True

    return cmd_run(args)

if __name__ == "__main__":
    sys.exit(main())
