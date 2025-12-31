#!/usr/bin/env python
"""Spec linter: validate behavioral specification format and completeness."""

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional


@dataclass
class LintIssue:
    """A linting issue found in a spec file."""
    severity: str  # "error", "warning", "info"
    rule: str
    message: str
    line: Optional[int] = None


@dataclass
class SpecLintResult:
    """Result of linting a single spec file."""
    path: Path
    spec_id: str
    issues: List[LintIssue] = field(default_factory=list)

    @property
    def passed(self) -> bool:
        return not any(i.severity == "error" for i in self.issues)

    @property
    def error_count(self) -> int:
        return sum(1 for i in self.issues if i.severity == "error")

    @property
    def warning_count(self) -> int:
        return sum(1 for i in self.issues if i.severity == "warning")


class SpecLinter:
    """Linter for SDD behavioral specifications."""

    def __init__(self, strict: bool = False):
        self.strict = strict

    def lint_file(self, spec_path: Path) -> SpecLintResult:
        """Lint a single spec file."""
        # Extract SPEC-ID from filename
        match = re.search(r'(SPEC-\d+)', spec_path.name)
        spec_id = match.group(1) if match else "<unknown>"

        result = SpecLintResult(path=spec_path, spec_id=spec_id)

        try:
            content = spec_path.read_text()
            lines = content.split('\n')
        except Exception as e:
            result.issues.append(LintIssue(
                severity="error",
                rule="file-readable",
                message=f"Could not read file: {e}"
            ))
            return result

        # Run all lint checks
        self._check_req_ids(content, lines, result)
        self._check_status(content, lines, result)
        self._check_behavioral_patterns(content, lines, result)
        self._check_eval_criteria(content, lines, result)
        self._check_sections(content, lines, result)
        self._check_spec_id_match(content, spec_id, result)

        return result

    def _check_req_ids(self, content: str, lines: List[str], result: SpecLintResult):
        """Check for REQ-* ID references."""
        req_pattern = r'REQ-\d+'
        if not re.search(req_pattern, content):
            result.issues.append(LintIssue(
                severity="error",
                rule="req-id-required",
                message="Spec must reference at least one REQ-* ID"
            ))
        else:
            # Check it's in the header area (first 20 lines)
            header = '\n'.join(lines[:20])
            if not re.search(r'\*\*REQ IDs?\*\*:', header, re.IGNORECASE):
                result.issues.append(LintIssue(
                    severity="warning",
                    rule="req-id-header",
                    message="REQ ID should be in header with '**REQ IDs:**' format"
                ))

    def _check_status(self, content: str, lines: List[str], result: SpecLintResult):
        """Check for Status field."""
        status_pattern = r'\*\*Status\*\*:\s*(Draft|Approved|Deprecated)'
        if not re.search(status_pattern, content, re.IGNORECASE):
            result.issues.append(LintIssue(
                severity="warning",
                rule="status-required",
                message="Spec should have '**Status:** Draft|Approved|Deprecated'"
            ))

    def _check_behavioral_patterns(self, content: str, lines: List[str], result: SpecLintResult):
        """Check for WHEN/THEN or GIVEN/WHEN/THEN patterns."""
        behavioral_patterns = [
            r'WHEN\s+.+\s+THEN\s+',
            r'GIVEN\s+.+\s+WHEN\s+',
            r'Given\s+.+\s+When\s+',
            r'When\s+.+\s+Then\s+',
        ]

        found_behavioral = False
        for pattern in behavioral_patterns:
            if re.search(pattern, content, re.IGNORECASE | re.DOTALL):
                found_behavioral = True
                break

        if not found_behavioral:
            result.issues.append(LintIssue(
                severity="error",
                rule="behavioral-pattern",
                message="Spec must contain WHEN/THEN or GIVEN/WHEN/THEN behavioral patterns"
            ))

    def _check_eval_criteria(self, content: str, lines: List[str], result: SpecLintResult):
        """Check for Eval Criteria section."""
        eval_section_patterns = [
            r'##\s*Eval\s+Criteria',
            r'##\s*Evaluation\s+Criteria',
            r'##\s*Test\s+Criteria',
            r'##\s*Acceptance\s+Criteria',
        ]

        found_eval = False
        for pattern in eval_section_patterns:
            if re.search(pattern, content, re.IGNORECASE):
                found_eval = True
                break

        if not found_eval:
            result.issues.append(LintIssue(
                severity="warning",
                rule="eval-criteria",
                message="Spec should have '## Eval Criteria' section"
            ))

        # Check for checkbox items in eval criteria
        if found_eval and '- [ ]' not in content and '- [x]' not in content.lower():
            result.issues.append(LintIssue(
                severity="info",
                rule="eval-checkboxes",
                message="Consider using checkbox items (- [ ]) for eval criteria"
            ))

    def _check_sections(self, content: str, lines: List[str], result: SpecLintResult):
        """Check for required sections."""
        required_sections = [
            (r'##\s*(Overview|Summary|Description)', "overview", "warning"),
            (r'##\s*(Behavioral\s+Specification|Behavior|Expected\s+Behavior)', "behavioral-section", "error"),
        ]

        recommended_sections = [
            (r'##\s*Input', "input-section", "info"),
            (r'##\s*Output', "output-section", "info"),
            (r'##\s*Edge\s+Cases', "edge-cases", "info"),
        ]

        for pattern, rule, severity in required_sections:
            if not re.search(pattern, content, re.IGNORECASE):
                result.issues.append(LintIssue(
                    severity=severity,
                    rule=rule,
                    message=f"Spec should have section matching '{pattern}'"
                ))

        if self.strict:
            for pattern, rule, severity in recommended_sections:
                if not re.search(pattern, content, re.IGNORECASE):
                    result.issues.append(LintIssue(
                        severity=severity,
                        rule=rule,
                        message=f"Consider adding section matching '{pattern}'"
                    ))

    def _check_spec_id_match(self, content: str, spec_id: str, result: SpecLintResult):
        """Check that filename SPEC-ID matches content."""
        if spec_id == "<unknown>":
            result.issues.append(LintIssue(
                severity="error",
                rule="spec-id-filename",
                message="Filename should match SPEC-XXX.md pattern"
            ))
            return

        # Check if spec_id appears in the title (first heading)
        title_pattern = rf'#\s+{spec_id}'
        if not re.search(title_pattern, content):
            result.issues.append(LintIssue(
                severity="warning",
                rule="spec-id-title",
                message=f"Title should include spec ID: '# {spec_id}: ...'"
            ))


def lint_directory(specs_dir: Path, strict: bool = False) -> List[SpecLintResult]:
    """Lint all spec files in a directory."""
    linter = SpecLinter(strict=strict)
    results = []

    if not specs_dir.exists():
        return results

    for spec_file in specs_dir.rglob("SPEC-*.md"):
        results.append(linter.lint_file(spec_file))

    return results


def print_report(results: List[SpecLintResult], output_format: str = "text", verbose: bool = False):
    """Print linting report."""
    total_errors = sum(r.error_count for r in results)
    total_warnings = sum(r.warning_count for r in results)
    passed = sum(1 for r in results if r.passed)
    failed = len(results) - passed

    if output_format == "json":
        report = {
            "summary": {
                "total_specs": len(results),
                "passed": passed,
                "failed": failed,
                "total_errors": total_errors,
                "total_warnings": total_warnings
            },
            "results": [
                {
                    "path": str(r.path),
                    "spec_id": r.spec_id,
                    "passed": r.passed,
                    "issues": [
                        {"severity": i.severity, "rule": i.rule, "message": i.message, "line": i.line}
                        for i in r.issues
                    ]
                }
                for r in results
                if r.issues or verbose
            ]
        }
        print(json.dumps(report, indent=2))
        return

    # Text output
    print("=" * 60)
    print("SPEC LINTER REPORT")
    print("=" * 60)
    print()

    status = "PASS" if failed == 0 else "FAIL"
    print(f"Status: {status}")
    print(f"Specs: {passed}/{len(results)} passed")
    print(f"Issues: {total_errors} errors, {total_warnings} warnings")
    print()

    # Show issues per file
    for result in results:
        if not result.issues and not verbose:
            continue

        status_icon = "PASS" if result.passed else "FAIL"
        print(f"{status_icon}: {result.spec_id} ({result.path})")

        for issue in result.issues:
            icon = {"error": "E", "warning": "W", "info": "I"}[issue.severity]
            line_info = f":{issue.line}" if issue.line else ""
            print(f"  [{icon}] {issue.rule}{line_info}: {issue.message}")

        if result.issues:
            print()

    print("=" * 60)


def main():
    parser = argparse.ArgumentParser(
        description="Lint behavioral specification files for format and completeness",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  uv run python tools/spec_linter.py
  uv run python tools/spec_linter.py --strict
  uv run python tools/spec_linter.py --format json
  uv run python tools/spec_linter.py specs/auth/SPEC-001.md
        """
    )
    parser.add_argument(
        "files",
        nargs="*",
        type=Path,
        help="Specific spec files to lint (default: all in specs/)"
    )
    parser.add_argument(
        "--specs-dir",
        type=Path,
        default=Path("specs"),
        help="Directory containing specs (default: specs)"
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Enable strict mode with additional checks"
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Show all files including those that passed"
    )
    parser.add_argument(
        "--format",
        choices=["text", "json"],
        default="text",
        help="Output format (default: text)"
    )

    args = parser.parse_args()

    linter = SpecLinter(strict=args.strict)

    if args.files:
        results = [linter.lint_file(f) for f in args.files]
    else:
        results = lint_directory(args.specs_dir, args.strict)

    if not results:
        print("[info] No spec files found")
        sys.exit(0)

    print_report(results, args.format, args.verbose)

    # Exit with error if any specs failed
    if any(not r.passed for r in results):
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
