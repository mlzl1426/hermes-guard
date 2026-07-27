#!/bin/bash
# ============================================================
# daily-check.sh — Silent daily inspection
#
# Part of Hermes Guard (github.com/mlzl1426/hermes-guard)
#
# Designed for Hermes cron (no_agent=true).
# Only outputs when problems found — silent otherwise.
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/.."

OUTPUT=""; ALERTS=0
add_alert() { OUTPUT="${OUTPUT}${1}\n"; ALERTS=$((ALERTS + 1)); }

# ---- Git status ----
UNTRACKED=$(git status --short 2>/dev/null | grep '^??' | wc -l)
[ "$UNTRACKED" -gt 10 ] && add_alert "🟡 $UNTRACKED untracked files"

ROOT_COUNT=$(ls *.md *.sql *.sh 2>/dev/null | wc -l)
[ "$ROOT_COUNT" -gt 15 ] && add_alert "🔴 Root dir: $ROOT_COUNT files (>15)"

# ---- API ----
API_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 http://localhost:8000/health 2>/dev/null || echo "000")
[ "$API_CODE" != "200" ] && [ "$API_CODE" != "000" ] && add_alert "🔴 API: HTTP $API_CODE"

# ---- Docker ----
if command -v docker &>/dev/null; then
    docker ps --format "{{.Status}}" --filter "name=db" 2>/dev/null | grep -q "Up" || \
        add_alert "🟡 DB container not running"
fi

# ---- Disk ----
DISK_PCT=$(df -h . 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//')
[ -n "$DISK_PCT" ] && [ "$DISK_PCT" -gt 90 ] && add_alert "🔴 Disk: ${DISK_PCT}%"

# ---- Output ----
if [ "$ALERTS" -gt 0 ]; then
    echo "📋 Project Health — $(date '+%Y-%m-%d %H:%M')"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "$OUTPUT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$ALERTS alert(s)"
else
    exit 0  # Silent — nothing wrong
fi
