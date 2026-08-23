#!/bin/bash
# ============================================================
# verify-project.sh — Project health verification (model-independent)
#
# Part of Hermes Guard (github.com/mlzl1426/hermes-guard)
# Aligned with: repo-seatbelt (github.com/berkcangumusisik/repo-seatbelt)
#
# Pure shell, zero tokens, 9 built-in checks (extensible to 17+).
# The agent CANNOT fake these results — they come from real system calls.
#
# Usage:
#   bash verify-project.sh          # All 9 checks
#   bash verify-project.sh --quick  # 9 checks, no extended section
#   bash verify-project.sh --json   # Machine-readable output
#
# Configuration: edit the CONFIG section below for your project.
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/.."

# ---- CONFIG: Customize for your project ----
PROJECT_NAME="${PROJECT_NAME:-$(basename "$(pwd)")}"
API_HEALTH_URL="${API_HEALTH_URL:-http://localhost:8000/health}"
DB_CONTAINER="${DB_CONTAINER:-db}"
DB_NAME="${DB_NAME:-app}"
DB_USER="${DB_USER:-root}"
DB_PASS="${DB_PASS:-secret}"
CRITICAL_FILES="${CRITICAL_FILES-README.md,CHANGELOG.md,.gitignore}"  # Empty string disables the check
WIN_SYNC_DIR="${WIN_SYNC_DIR:-}"  # Optional Windows host path for doc sync

# ---- Parsing ----
QUICK=false
JSON=false
for arg in "$@"; do
    case $arg in --quick) QUICK=true ;; --json) JSON=true ;; esac
done

PASS=0; FAIL=0; WARN=0; RESULTS=()

check() {
    local name="$1" status="$2" detail="$3"
    if [ "$JSON" = true ]; then
        RESULTS+=("{\"check\":\"$name\",\"status\":\"$status\",\"detail\":\"$detail\"}")
    else
        case $status in
            PASS) echo "✅ $name: $detail"; PASS=$((PASS+1)) ;;
            FAIL) echo "❌ $name: $detail"; FAIL=$((FAIL+1)) ;;
            WARN) echo "⚠️  $name: $detail"; WARN=$((WARN+1)) ;;
        esac
    fi
}

if [ "$JSON" != true ]; then
    echo "=== $PROJECT_NAME Health Check $(date '+%Y-%m-%d %H:%M') ==="
    echo ""
fi

# ---- 1. Git working tree ----
UNTRACKED=$(git status --short 2>/dev/null | grep '^??' | wc -l)
MODIFIED=$(git status --short 2>/dev/null | grep -c '^ M\|^M ' || true)
if [ "$UNTRACKED" -eq 0 ] && [ "$MODIFIED" -eq 0 ]; then
    check "Git状态" PASS "Clean"
else
    check "Git状态" WARN "$UNTRACKED untracked + $MODIFIED modified"
fi

# ---- 2. Root directory hygiene ----
ROOT_COUNT=$(ls *.md *.sql *.sh *.py *.js *.ts 2>/dev/null | wc -l)
if [ "$ROOT_COUNT" -le 15 ]; then
    check "根目录" PASS "$ROOT_COUNT files (≤15)"
else
    check "根目录" WARN "$ROOT_COUNT files (>15, consider archiving)"
fi

# ---- 3. API health ----
if [ -n "$API_HEALTH_URL" ] && [ "$API_HEALTH_URL" != "http://localhost:8000/health" ] || curl -s --connect-timeout 2 "$API_HEALTH_URL" >/dev/null 2>&1; then
    API_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "$API_HEALTH_URL" 2>/dev/null || echo "000")
    if [ "$API_CODE" = "200" ]; then
        check "API服务" PASS "health → 200"
    elif [ "$API_CODE" = "000" ]; then
        check "API服务" WARN "Not running"
    else
        check "API服务" FAIL "HTTP $API_CODE"
    fi
else
    check "API服务" PASS "Not configured (skip)"
fi

# ---- 4. Docker containers ----
if command -v docker &>/dev/null; then
    DB_STATUS=$(docker ps --format "{{.Status}}" --filter "name=$DB_CONTAINER" 2>/dev/null | head -1)
    if [ -n "$DB_STATUS" ]; then
        if echo "$DB_STATUS" | grep -q "Up"; then
            check "Docker" PASS "$DB_CONTAINER: $DB_STATUS"
        else
            check "Docker" FAIL "$DB_CONTAINER: $DB_STATUS"
        fi
    else
        check "Docker" WARN "$DB_CONTAINER not running"
    fi
else
    check "Docker" PASS "Not installed (skip)"
fi

# ---- 5. Database connectivity ----
if command -v docker &>/dev/null && docker ps --format "{{.Names}}" 2>/dev/null | grep -q "$DB_CONTAINER"; then
    DB_OK=$(docker exec "$DB_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASS" -e "SELECT 1" "$DB_NAME" 2>/dev/null | grep -c 1 || echo 0)
    if [ "$DB_OK" -gt 0 ]; then
        check "数据库" PASS "$DB_NAME reachable"
    else
        check "数据库" WARN "Cannot connect to $DB_NAME"
    fi
else
    check "数据库" PASS "Not configured (skip)"
fi

# ---- 6. Critical files ----
IFS=',' read -ra CRITICAL <<< "$CRITICAL_FILES"
MISSING=""
for f in "${CRITICAL[@]}"; do
    f=$(echo "$f" | xargs)
    [ -n "$f" ] || continue
    if [ ! -f "$f" ]; then MISSING="$MISSING $f"; fi
done
if [ -z "$MISSING" ]; then
    check "关键文件" PASS "All ${#CRITICAL[@]} present"
else
    check "关键文件" FAIL "Missing:$MISSING"
fi

# ---- 7. Git remote sync ----
AHEAD=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo 0)
BEHIND=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)
if [ "$AHEAD" -gt 0 ] && [ "$BEHIND" -gt 0 ]; then
    check "Git远程" WARN "+$AHEAD/-$BEHIND (diverged!)"
elif [ "$AHEAD" -gt 0 ]; then
    check "Git远程" WARN "$AHEAD commits ahead (not pushed)"
elif [ "$BEHIND" -gt 0 ]; then
    check "Git远程" WARN "$BEHIND commits behind (need pull)"
else
    check "Git远程" PASS "Synced"
fi

# ---- 8. Disk space ----
DISK_PCT=$(df -h . 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//')
if [ -n "$DISK_PCT" ]; then
    if [ "$DISK_PCT" -lt 80 ]; then check "磁盘空间" PASS "${DISK_PCT}%"
    elif [ "$DISK_PCT" -lt 95 ]; then check "磁盘空间" WARN "${DISK_PCT}%"
    else check "磁盘空间" FAIL "${DISK_PCT}% CRITICAL"
    fi
fi

# ---- 9. Pycache staleness ----
PYC_COUNT=$(find . -name "__pycache__" -type d -not -path "*/.venv/*" 2>/dev/null | wc -l)
if [ "$PYC_COUNT" -gt 10 ]; then
    check "PyCache" WARN "$PYC_COUNT dirs (maybe stale)"
elif [ "$PYC_COUNT" -gt 0 ]; then
    check "PyCache" PASS "$PYC_COUNT dirs"
else
    check "PyCache" PASS "Clean"
fi

# ---- Quick mode exit ----
if [ "$QUICK" = true ]; then
    # Record timestamp for evidence gate (pre-commit-check.sh)
    date +%s > /tmp/hermes-guard-verify-last-run 2>/dev/null || true
    echo ""
    echo "--- Quick check done ---"
    [ "$FAIL" -eq 0 ] || exit 1
    exit 0
fi

# ---- 10+: Extended checks ----
# (Add your project-specific checks below — linting, tests, custom validations)

if [ "$JSON" != true ]; then
    echo ""
    echo "========================================"
fi
if [ "$JSON" = true ]; then
    echo "[${RESULTS[*]}]" | sed 's/} {/}, {/g'
else
    echo "Result: ✅$PASS ⚠️$WARN ❌$FAIL"
fi

# Record timestamp for evidence gate
date +%s > /tmp/hermes-guard-verify-last-run 2>/dev/null || true

[ "$FAIL" -eq 0 ] || exit 1
