"""
Eval Template for SPEC-XXX - REQ-XXX

SDD Status: PENDING (awaiting implementation)

Copy this template to: evals/{module}/eval_spec_xxx.py
"""
from dataclasses import dataclass
from typing import Any

@dataclass
class EvalResult:
    """Result of an eval run."""
    passed: bool
    spec_id: str
    description: str
    expected: Any
    actual: Any = None
    error: str = None

class SpecEval:
    """Evals for SPEC-XXX."""

    spec_id = "SPEC-XXX"
    req_ids = ["REQ-XXX"]

    # === Happy Path Evals ===

    def eval_valid_input_succeeds(self) -> EvalResult:
        """Eval: Valid input produces expected output."""
        input_data = {"field": "value"}
        expected = {"result": "success"}

        try:
            # result = module.process(input_data)  # Uncomment when implemented
            result = None  # Awaiting implementation

            passed = result == expected
            return EvalResult(
                passed=passed,
                spec_id=self.spec_id,
                description="Valid input succeeds",
                expected=expected,
                actual=result
            )
        except Exception as e:
            return EvalResult(
                passed=False,
                spec_id=self.spec_id,
                description="Valid input succeeds",
                expected=expected,
                error=str(e)
            )

    # === Error Case Evals ===

    def eval_invalid_input_returns_error(self) -> EvalResult:
        """Eval: Invalid input returns appropriate error."""
        input_data = None
        expected_error = "ValidationError"

        try:
            # result = module.process(input_data)  # Uncomment when implemented
            return EvalResult(
                passed=False,
                spec_id=self.spec_id,
                description="Invalid input returns error",
                expected=expected_error,
                error="Expected error but got success"
            )
        except Exception as e:
            passed = expected_error in str(type(e).__name__)
            return EvalResult(
                passed=passed,
                spec_id=self.spec_id,
                description="Invalid input returns error",
                expected=expected_error,
                actual=type(e).__name__
            )

    def run_all(self) -> list[EvalResult]:
        """Run all evals and return results."""
        return [
            self.eval_valid_input_succeeds(),
            self.eval_invalid_input_returns_error(),
        ]

def main():
    """Run evals and print results."""
    eval_suite = SpecEval()
    results = eval_suite.run_all()

    print(f"\n{'='*60}")
    print(f"{eval_suite.spec_id} Eval Results")
    print(f"{'='*60}\n")

    passed = sum(1 for r in results if r.passed)
    total = len(results)

    for result in results:
        status = "PASS" if result.passed else "FAIL"
        print(f"{status}: {result.description}")
        if not result.passed:
            print(f"    Expected: {result.expected}")
            print(f"    Actual: {result.actual or result.error}")

    print(f"\n{'='*60}")
    print(f"Results: {passed}/{total} passed")
    print(f"{'='*60}\n")

    return 0 if passed == total else 1

if __name__ == "__main__":
    exit(main())
