#!/bin/bash
# ============================================================
# test-daily-check.sh — daily-check silent contract
# Run via: bash tests/run_tests.sh
# ============================================================

run_daily_check_tests() {
    echo "=== daily-check.sh ==="

    local repo="$WORK/daily-repo"
    new_repo "$repo"
    copy_scripts "$repo" daily-check.sh

    # T19: always exits 0 (alerts are informational)
    if (cd "$repo" && bash scripts/daily-check.sh >/dev/null 2>&1); then
        pass "daily-check exits 0 (silent contract)"
    else
        fail "daily-check exited non-zero"
    fi

    # T20: alert output (if any) contains the summary line
    OUT=$(cd "$repo" && bash scripts/daily-check.sh 2>&1)
    if [ -n "$OUT" ]; then
        if echo "$OUT" | grep -q "alert"; then
            pass "alert output contains summary"
        else
            fail "alert output missing summary"
        fi
    else
        pass "silent when nothing wrong (no output)"
    fi
}
