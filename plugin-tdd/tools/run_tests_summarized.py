#!/usr/bin/env python
"""Run tests and emit a compact JSON summary.

Usage:
    uv run python tools/run_tests_summarized.py --cmd "uv run pytest tests/" --tail 40

IMPORTANT: Always use 'uv run' for all Python execution to ensure code runs
in the correct virtual environment with synced dependencies.
"""

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path
from typing import List, Tuple


def check_uv_usage(cmd: str) -> str:
    """Check if command uses uv and warn/fix if not.
    
    Args:
        cmd: The command string to check.
        
    Returns:
        The (potentially modified) command string.
    """
    # If already using uv run, we're good
    if cmd.strip().startswith("uv run"):
        return cmd
    
    # Check if uv is available
    uv_available = shutil.which("uv") is not None
    
    # If running pytest directly, suggest using uv run
    if "pytest" in cmd and not cmd.strip().startswith("uv"):
        if uv_available:
            # Auto-prefix with uv run
            print(
                "⚠️  Auto-prefixing with 'uv run' to use virtual environment",
                file=sys.stderr
            )
            return f"uv run {cmd}"
        else:
            print(
                "⚠️  Warning: Running pytest without 'uv run'. "
                "Install uv for proper venv management: "
                "curl -LsSf https://astral.sh/uv/install.sh | sh",
                file=sys.stderr
            )
    
    return cmd


def run_command(cmd: str) -> Tuple[int, List[str]]:
    try:
        proc = subprocess.Popen(
            cmd, shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
    except OSError as e:
        return 127, [f"Failed to start command: {e}"]
    lines: List[str] = []
    assert proc.stdout is not None
    for line in proc.stdout:
        lines.append(line.rstrip("\n"))
    proc.wait()
    return proc.returncode, lines

def summarize(returncode: int, lines: List[str], tail: int) -> dict:
    markers = ("FAIL", "ERROR", "E   ", "AssertionError", "FAILED")
    fail_lines = [ln for ln in lines if any(m in ln for m in markers)]
    tail_lines = lines[-tail:] if tail > 0 else []
    if returncode == 0 and not fail_lines:
        status = "pass"
        summary = "All tests passed (exit code 0, no failure markers)."
    else:
        status = "fail"
        summary = f"Tests exited with code {returncode} and {len(fail_lines)} line(s) with failure markers."
    return {
        "status": status,
        "exit_code": returncode,
        "failure_marker_lines": len(fail_lines),
        "tail_lines": tail_lines,
        "summary": summary,
    }

def main():
    parser = argparse.ArgumentParser(
        description="Run tests and produce a compact JSON summary.",
        epilog="Tip: Use 'uv run pytest' for proper venv management."
    )
    parser.add_argument(
        "--cmd",
        default="uv run pytest",
        help="Test command to run (default: 'uv run pytest')."
    )
    parser.add_argument(
        "--tail",
        type=int,
        default=30,
        help="Number of tail lines to include."
    )
    parser.add_argument(
        "--output", "-o",
        help="Optional output file path for summary JSON."
    )
    parser.add_argument(
        "--no-uv-check",
        action="store_true",
        help="Skip the automatic uv run prefixing."
    )
    args = parser.parse_args()
    
    # Ensure command uses uv for proper venv management
    cmd = args.cmd if args.no_uv_check else check_uv_usage(args.cmd)
    
    code, lines = run_command(cmd)
    data = summarize(code, lines, args.tail)
    text = json.dumps(data, indent=2)
    if args.output:
        Path(args.output).write_text(text, encoding="utf-8")
    else:
        print(text)
    raise SystemExit(code)

if __name__ == "__main__":
    main()
