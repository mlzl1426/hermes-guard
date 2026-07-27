#!/bin/bash
# ============================================================
# pre-commit-check.sh — Git pre-commit compliance gate
#
# Part of Hermes Guard (github.com/mlzl1426/hermes-guard)
# Aligned with: agentlint (github.com/mauhpr/agentlint)
#
# Install: ln -s ../../scripts/pre-commit-check.sh .git/hooks/pre-commit
#
# Checks:
#   1. Common module impact (if shared code changed)
#   2. Evidence gate (verify script run recently?)
#   3. Scope enforcement (unresolved scope file?)
#   4. Destructive patterns (SQL injection, force push)
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/.."

ERRORS=0
WARNINGS=0

red()    { echo -e "\033[31m\033[1m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
green()  { echo -e "\033[32m$1\033[0m"; }

echo "=== Pre-commit Guard ==="
echo ""

# ---- 1. Staged files ----
STAGED=$(git diff --cached --name-only 2>/dev/null)
STAGED_COUNT=$(echo "$STAGED" | grep -c . || echo 0)
echo "📋 Files: ${STAGED_COUNT}"
echo ""

# ---- 2. Common/shared module impact ----
if echo "$STAGED" | grep -qE "common/|shared/|lib/|utils/"; then
    yellow "⚠️  Shared module changed!"
    echo "   Potential callers:"
    for f in $(echo "$STAGED" | grep -E "common/|shared/|lib/|utils/"); do
        module_name=$(basename "$f" .py 2>/dev/null || basename "$f")
        echo "   → $module_name:"
        grep -rn "from.*$module_name\|import.*$module_name" \
            --include="*.py" --include="*.ts" --include="*.js" . 2>/dev/null \
            | grep -v "common/\|shared/\|lib/\|utils/" | head -5 | sed 's/^/     /'
    done
    echo "   🔴 Confirm all callers are updated"
    echo ""
    WARNINGS=$((WARNINGS + 1))
fi

# ---- 3. Evidence gate ----
VERIFY_SCRIPT=""
for candidate in "scripts/verify-project.sh" "scripts/verify-docs.sh" "scripts/verify.sh"; do
    [ -f "$candidate" ] && { VERIFY_SCRIPT="$candidate"; break; }
done

if [ -n "$VERIFY_SCRIPT" ]; then
    VERIFY_LOG="/tmp/hermes-guard-verify-last-run"
    if [ -f "$VERIFY_LOG" ]; then
        LAST_RUN=$(cat "$VERIFY_LOG")
        NOW=$(date +%s)
        if [ $((NOW - LAST_RUN)) -gt 1800 ]; then
            yellow "⚠️  Verify script not run in 30 minutes"
            echo "   Run: bash $VERIFY_SCRIPT --quick"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        yellow "⚠️  No verify script run record this session"
        echo "   Run: bash $VERIFY_SCRIPT --quick"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# ---- 4. Scope enforcement ----
if [ -f ".hermes/scope.yaml" ]; then
    red "❌ Unresolved scope file .hermes/scope.yaml"
    echo "   Run: bash scripts/scope-check.sh verify"
    ERRORS=$((ERRORS + 1))
fi

# ---- 5. SQL injection anti-patterns ----
if echo "$STAGED" | grep -qE "\.sql$|\.py$"; then
    BAD_SQL=$(grep -rn 'SQL\s*+\s*where\|sql\s*+\s*where\|sql\s*+\s*" WHERE' \
        --include="*.py" . 2>/dev/null | grep -v ".git/" | grep -v "DYNAMIC_WHERE" || true)
    if [ -n "$BAD_SQL" ]; then
        red "❌ Direct SQL concatenation detected (use parameterized queries):"
        echo "$BAD_SQL" | head -5 | sed 's/^/     /'
        ERRORS=$((ERRORS + 1))
    fi
fi

# ---- Summary ----
echo "========================================"
if [ "$ERRORS" -gt 0 ]; then
    red "🔴 $ERRORS blocking issue(s) — commit rejected"
    red "   Fix issues or use: git commit --no-verify"
    exit 1
elif [ "$WARNINGS" -gt 0 ]; then
    yellow "🟡 $WARNINGS warning(s) — review recommended"
    green "✅ Commit allowed (warnings don't block)"
    exit 0
else
    green "✅ All checks passed"
    exit 0
fi
