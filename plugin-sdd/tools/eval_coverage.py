#!/usr/bin/env python
"""Eval coverage checker: verify every spec has at least one eval."""

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple


def find_specs(specs_dir: Path) -> Dict[str, Path]:
    """Find all SPEC-*.md files and return {spec_id: path}."""
    specs = {}
    if not specs_dir.exists():
        return specs

    for spec_file in specs_dir.rglob("SPEC-*.md"):
        # Extract SPEC-XXX from filename
        match = re.search(r'(SPEC-\d+)', spec_file.name)
        if match:
            spec_id = match.group(1)
            specs[spec_id] = spec_file

    return specs


def find_evals(evals_dir: Path) -> Dict[str, List[Path]]:
    """Find all eval_*.py files and extract which specs they cover."""
    eval_coverage = {}
    if not evals_dir.exists():
        return eval_coverage

    for eval_file in evals_dir.rglob("eval_*.py"):
        # Read file to find spec_id references
        try:
            content = eval_file.read_text()

            # Look for spec_id = "SPEC-XXX" pattern
            spec_matches = re.findall(r'spec_id\s*=\s*["\']?(SPEC-\d+)["\']?', content)

            # Also look for SPEC-XXX in comments/docstrings
            comment_matches = re.findall(r'SPEC-\d+', content)

            all_specs = set(spec_matches + comment_matches)

            for spec_id in all_specs:
                if spec_id not in eval_coverage:
                    eval_coverage[spec_id] = []
                eval_coverage[spec_id].append(eval_file)

        except Exception as e:
            print(f"[warn] Could not read {eval_file}: {e}", file=sys.stderr)

    return eval_coverage


def check_coverage(specs_dir: Path, evals_dir: Path) -> Tuple[Dict, Dict, Dict]:
    """Check eval coverage for specs.

    Returns:
        (covered, uncovered, orphan_evals)
    """
    specs = find_specs(specs_dir)
    eval_coverage = find_evals(evals_dir)

    covered = {}
    uncovered = {}

    for spec_id, spec_path in specs.items():
        if spec_id in eval_coverage:
            covered[spec_id] = {
                'spec': spec_path,
                'evals': eval_coverage[spec_id]
            }
        else:
            uncovered[spec_id] = spec_path

    # Find evals that reference non-existent specs
    orphan_evals = {}
    for spec_id, eval_paths in eval_coverage.items():
        if spec_id not in specs:
            orphan_evals[spec_id] = eval_paths

    return covered, uncovered, orphan_evals


def print_report(covered: Dict, uncovered: Dict, orphan_evals: Dict,
                 verbose: bool = False, output_format: str = "text"):
    """Print coverage report."""

    total_specs = len(covered) + len(uncovered)
    coverage_pct = (len(covered) / total_specs * 100) if total_specs > 0 else 0

    if output_format == "json":
        report = {
            "summary": {
                "total_specs": total_specs,
                "covered": len(covered),
                "uncovered": len(uncovered),
                "coverage_percent": round(coverage_pct, 1),
                "orphan_evals": len(orphan_evals)
            },
            "uncovered_specs": [str(p) for p in uncovered.values()],
            "orphan_evals": {k: [str(p) for p in v] for k, v in orphan_evals.items()}
        }
        if verbose:
            report["covered_specs"] = {
                k: {"spec": str(v["spec"]), "evals": [str(e) for e in v["evals"]]}
                for k, v in covered.items()
            }
        print(json.dumps(report, indent=2))
        return

    # Text output
    print("=" * 60)
    print("EVAL COVERAGE REPORT")
    print("=" * 60)
    print()

    # Summary
    status = "PASS" if len(uncovered) == 0 else "FAIL"
    print(f"Status: {status}")
    print(f"Coverage: {len(covered)}/{total_specs} specs ({coverage_pct:.1f}%)")
    print()

    # Uncovered specs (always show)
    if uncovered:
        print("UNCOVERED SPECS (need evals):")
        print("-" * 40)
        for spec_id, path in sorted(uncovered.items()):
            print(f"  {spec_id}: {path}")
        print()

    # Orphan evals (always show)
    if orphan_evals:
        print("ORPHAN EVALS (reference missing specs):")
        print("-" * 40)
        for spec_id, paths in sorted(orphan_evals.items()):
            for path in paths:
                print(f"  {spec_id}: {path}")
        print()

    # Covered specs (verbose only)
    if verbose and covered:
        print("COVERED SPECS:")
        print("-" * 40)
        for spec_id, info in sorted(covered.items()):
            eval_count = len(info['evals'])
            print(f"  {spec_id}: {eval_count} eval(s)")
            for eval_path in info['evals']:
                print(f"    - {eval_path}")
        print()

    print("=" * 60)


def main():
    parser = argparse.ArgumentParser(
        description="Check eval coverage for behavioral specs",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  uv run python tools/eval_coverage.py
  uv run python tools/eval_coverage.py --verbose
  uv run python tools/eval_coverage.py --format json
  uv run python tools/eval_coverage.py --specs-dir specs --evals-dir evals
        """
    )
    parser.add_argument(
        "--specs-dir",
        type=Path,
        default=Path("specs"),
        help="Directory containing SPEC-*.md files (default: specs)"
    )
    parser.add_argument(
        "--evals-dir",
        type=Path,
        default=Path("evals"),
        help="Directory containing eval_*.py files (default: evals)"
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Show detailed coverage information"
    )
    parser.add_argument(
        "--format",
        choices=["text", "json"],
        default="text",
        help="Output format (default: text)"
    )
    parser.add_argument(
        "--fail-under",
        type=float,
        default=0,
        help="Exit with error if coverage is below this percentage"
    )

    args = parser.parse_args()

    covered, uncovered, orphan_evals = check_coverage(args.specs_dir, args.evals_dir)
    print_report(covered, uncovered, orphan_evals, args.verbose, args.format)

    # Calculate coverage for exit code
    total = len(covered) + len(uncovered)
    coverage_pct = (len(covered) / total * 100) if total > 0 else 100

    if coverage_pct < args.fail_under:
        sys.exit(1)
    elif uncovered:
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()
