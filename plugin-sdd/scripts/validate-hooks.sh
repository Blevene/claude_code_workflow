#!/bin/bash
# Quick diagnostic script for hook validation
# Usage: bash scripts/validate-hooks.sh

echo "=== Hook Validation ==="

echo -e "\n1. Checking hook files..."
for hook in plugin-sdd/hooks/*.sh; do
    if [[ -x "$hook" ]]; then
        echo "  ✓ $hook (executable)"
    else
        echo "  ✗ $hook (NOT executable)"
    fi
done

echo -e "\n2. Checking dependencies..."
for cmd in jq bash grep date; do
    if command -v $cmd &>/dev/null; then
        echo "  ✓ $cmd"
    else
        echo "  ✗ $cmd (MISSING)"
    fi
done

echo -e "\n3. Testing SessionStart hook..."
result=$(echo '{"source":"startup"}' | plugin-sdd/hooks/session-start.sh 2>&1)
if [[ $? -eq 0 ]]; then
    echo "  ✓ SessionStart returned: ${result:0:100}..."
else
    echo "  ✗ SessionStart failed: $result"
fi

echo -e "\n4. Checking settings.json..."
if [[ -f "plugin-sdd/.claude-plugin/settings.json" ]]; then
    hooks=$(grep -c '"hooks"' plugin-sdd/.claude-plugin/settings.json)
    echo "  ✓ settings.json exists (hooks config: $hooks)"
else
    echo "  ✗ settings.json not found"
fi

echo -e "\n=== Done ==="

