"""
Property-Based Eval Template for SPEC-XXX - REQ-XXX

Uses hypothesis for properties that must hold for ANY valid input.
Copy this template to: evals/{module}/eval_spec_xxx_properties.py
"""
from dataclasses import dataclass
from hypothesis import given, strategies as st, settings

@dataclass
class EvalResult:
    passed: bool
    spec_id: str
    description: str
    expected: str
    actual: str = None
    error: str = None

class PropertyEval:
    """Property-based evals using hypothesis."""

    spec_id = "SPEC-XXX"

    @given(st.text(min_size=1, max_size=100))
    def eval_round_trip(self, value: str):
        """Property: encode then decode returns original."""
        # encoded = module.encode(value)
        # decoded = module.decode(encoded)
        # assert decoded == value
        pass  # Awaiting implementation

    @given(st.integers(min_value=0))
    def eval_idempotent(self, value: int):
        """Property: normalizing twice equals normalizing once."""
        # once = module.normalize(value)
        # twice = module.normalize(once)
        # assert once == twice
        pass  # Awaiting implementation

    @given(st.lists(st.integers()))
    def eval_invariant_preserved(self, items: list):
        """Property: sum is preserved after shuffle."""
        # original_sum = sum(items)
        # shuffled = module.shuffle(items)
        # assert sum(shuffled) == original_sum
        pass  # Awaiting implementation

# When to use hypothesis:
# | Requirement Pattern     | Property Type         | Example                        |
# |-------------------------|-----------------------|--------------------------------|
# | "for any valid X"       | Universal quantifier  | @given(valid_inputs())         |
# | "always returns"        | Invariant             | Assert for all generated inputs|
# | "encode/decode"         | Round-trip            | decode(encode(x)) == x         |
# | "calling twice"         | Idempotence           | f(f(x)) == f(x)                |
# | "order doesn't matter"  | Commutativity         | f(a, b) == f(b, a)             |
