#!/bin/bash
# ============================================================
# install.sh — Hermes Guard one-command installer
#
# Usage:
#   bash install.sh /path/to/your-project
#
# What it does:
#   1. Copies scripts to your-project/scripts/
#   2. Installs pre-commit hook (.git/hooks/pre-commit)
#   3. Generates AGENTS.md from template
#   4. Copies skills to ~/.hermes/skills/
#   5. Registers cron jobs (daily + weekly inspection)
#   6. Runs first health check
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-}"

if [ -z "$TARGET" ]; then
    echo "Usage: bash install.sh /path/to/your-project"
    exit 1
fi

if [ ! -d "$TARGET" ]; then
    echo "❌ Directory not found: $TARGET"
    exit 1
fi

PROJECT_NAME=$(basename "$(cd "$TARGET" && pwd)")
echo ""
echo "🛡️  Hermes Guard — Installing for $PROJECT_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ---- 1. Copy scripts ----
echo "📋 Copying scripts..."
mkdir -p "$TARGET/scripts"
cp "$SCRIPT_DIR/scripts/"*.sh "$TARGET/scripts/"
chmod +x "$TARGET/scripts/"*.sh
echo "   ✅ danger-guard.sh"
echo "   ✅ scope-check.sh"
echo "   ✅ pre-commit-check.sh"
echo "   ✅ verify-project.sh"
echo "   ✅ daily-check.sh"
echo ""

# ---- 2. Install pre-commit hook ----
echo "🔗 Installing pre-commit hook..."
if [ -d "$TARGET/.git" ]; then
    ln -sf ../../scripts/pre-commit-check.sh "$TARGET/.git/hooks/pre-commit"
    echo "   ✅ .git/hooks/pre-commit → scripts/pre-commit-check.sh"
else
    echo "   ⚠️  Not a git repository — skip hook"
fi
echo ""

# ---- 3. Generate AGENTS.md ----
echo "📝 Generating AGENTS.md..."
if [ ! -f "$TARGET/AGENTS.md" ]; then
    sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
        "$SCRIPT_DIR/templates/AGENTS.md.template" > "$TARGET/AGENTS.md"
    echo "   ✅ AGENTS.md created"
else
    echo "   ⚠️  AGENTS.md already exists — skipped (remove it to regenerate)"
fi
echo ""

# ---- 4. Copy skills to Hermes ----
echo "🧠 Installing skills..."
SKILLS_DIR="$HOME/.hermes/skills"
mkdir -p "$SKILLS_DIR/guard" "$SKILLS_DIR/session-startup"
cp "$SCRIPT_DIR/skills/guard/SKILL.md" "$SKILLS_DIR/guard/SKILL.md"
cp "$SCRIPT_DIR/skills/session-startup/SKILL.md" "$SKILLS_DIR/session-startup/SKILL.md"
echo "   ✅ guard → ~/.hermes/skills/guard/"
echo "   ✅ session-startup → ~/.hermes/skills/session-startup/"
echo ""

# ---- 5. Cron setup hint ----
echo "⏰ Cron setup:"
echo "   Add these to your Hermes cron (or run manually):"
echo ""
echo "   # Daily health check (silent — only alerts on problems)"
echo "   hermes cron create '0 9 * * *' --script daily-check.sh --no-agent --name 'Daily Health Check'"
echo ""
echo "   # Weekly governance"
echo "   hermes cron create '0 11 * * 1' --skill guard --name 'Weekly Governance'"
echo ""

# ---- 6. Run first check ----
echo "🔍 Running first health check..."
cd "$TARGET"
if bash scripts/verify-project.sh --quick 2>&1; then
    echo ""
else
    echo ""
    echo "⚠️  Some checks have warnings — review above"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Hermes Guard installed for $PROJECT_NAME"
echo ""
echo "   Next steps:"
echo "   1. Edit $TARGET/AGENTS.md — customize rules for your project"
echo "   2. Edit $TARGET/scripts/verify-project.sh CONFIG section"
echo "   3. Start a new Hermes session — protection is active"
echo ""
echo "   The agent will now self-verify on every change."
echo "   You can't forget. You can't skip. You can't fake."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
