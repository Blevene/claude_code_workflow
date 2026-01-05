#!/bin/bash
# SDD Plugin Installation Script
# Installs to both ~/.claude/plugins/sdd and individual global directories

set -e

SRC="/Volumes/tank/claude_code_workflow/plugin-sdd"
DEST_PLUGIN="$HOME/.claude/plugins/sdd"
DEST_ROOT="$HOME/.claude"

echo "=== Installing SDD Plugin ==="
echo ""

# 1. Install full plugin to ~/.claude/plugins/sdd
echo "1. Installing plugin to $DEST_PLUGIN..."
rm -rf "$DEST_PLUGIN"
mkdir -p "$DEST_PLUGIN"
cp -R "$SRC"/* "$DEST_PLUGIN/"
echo "   ✓ Plugin directory created"

# 2. Copy hooks to global location (scripts only, NOT hooks.json - use settings.json)
echo ""
echo "2. Installing hooks to $DEST_ROOT/hooks/..."
mkdir -p "$DEST_ROOT/hooks"
cp "$SRC"/hooks/*.sh "$DEST_ROOT/hooks/"
chmod +x "$DEST_ROOT/hooks/"*.sh
# Remove any old hooks.json that could cause double-firing
rm -f "$DEST_ROOT/hooks/hooks.json" 2>/dev/null || true
echo "   ✓ Hooks installed (using settings.json for hook config)"

# 3. Copy scripts to global location
echo ""
echo "3. Installing scripts to $DEST_ROOT/scripts/..."
mkdir -p "$DEST_ROOT/scripts"
cp "$SRC"/scripts/*.sh "$DEST_ROOT/scripts/"
chmod +x "$DEST_ROOT/scripts/"*.sh
echo "   ✓ Scripts installed"

# 4. Copy rules to global location
echo ""
echo "4. Installing rules to $DEST_ROOT/rules/..."
mkdir -p "$DEST_ROOT/rules"
cp "$SRC"/rules/*.md "$DEST_ROOT/rules/"
echo "   ✓ Rules installed"

# 5. Copy skills to global location
echo ""
echo "5. Installing skills to $DEST_ROOT/skills/..."
mkdir -p "$DEST_ROOT/skills"
cp -R "$SRC"/skills/* "$DEST_ROOT/skills/"
echo "   ✓ Skills installed"

# 6. Copy agents to global location
echo ""
echo "6. Installing agents to $DEST_ROOT/agents/..."
mkdir -p "$DEST_ROOT/agents"
cp "$SRC"/agents/*.md "$DEST_ROOT/agents/"
echo "   ✓ Agents installed"

# 7. Copy commands to global location
echo ""
echo "7. Installing commands to $DEST_ROOT/commands/..."
mkdir -p "$DEST_ROOT/commands"
cp "$SRC"/commands/*.md "$DEST_ROOT/commands/"
echo "   ✓ Commands installed"

# 8. Copy schemas to global location
echo ""
echo "8. Installing schemas to $DEST_ROOT/schemas/..."
mkdir -p "$DEST_ROOT/schemas"
cp "$SRC"/schemas/*.json "$DEST_ROOT/schemas/"
echo "   ✓ Schemas installed"

# 9. Copy templates to global location
echo ""
echo "9. Installing templates to $DEST_ROOT/templates/..."
mkdir -p "$DEST_ROOT/templates"
cp "$SRC"/templates/*.py "$DEST_ROOT/templates/"
echo "   ✓ Templates installed"

# 10. Copy guides to global location
echo ""
echo "10. Installing guides to $DEST_ROOT/guides/..."
mkdir -p "$DEST_ROOT/guides"
cp "$SRC"/guides/*.md "$DEST_ROOT/guides/"
echo "   ✓ Guides installed"

# 11. Copy tools to global location
echo ""
echo "11. Installing tools to $DEST_ROOT/tools/..."
mkdir -p "$DEST_ROOT/tools"
cp "$SRC"/tools/*.py "$DEST_ROOT/tools/" 2>/dev/null || true
cp "$SRC"/tools/*.sql "$DEST_ROOT/tools/" 2>/dev/null || true
echo "   ✓ Tools installed"

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Installed locations:"
echo "  Plugin:    $DEST_PLUGIN"
echo "  Hooks:     $DEST_ROOT/hooks/"
echo "  Scripts:   $DEST_ROOT/scripts/"
echo "  Rules:     $DEST_ROOT/rules/"
echo "  Skills:    $DEST_ROOT/skills/"
echo "  Agents:    $DEST_ROOT/agents/"
echo "  Commands:  $DEST_ROOT/commands/"
echo "  Schemas:   $DEST_ROOT/schemas/"
echo "  Templates: $DEST_ROOT/templates/"
echo "  Guides:    $DEST_ROOT/guides/"
echo "  Tools:     $DEST_ROOT/tools/"
echo ""
echo "Usage options:"
echo "  Option A: claude --plugin-dir ~/.claude/plugins/sdd"
echo "  Option B: Global hooks via ~/.claude/settings.json (already configured)"
echo ""
echo "Verify installation:"
echo "  ls ~/.claude/hooks/"
echo "  ls ~/.claude/plugins/sdd/"

