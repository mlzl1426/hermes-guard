#!/bin/bash
# ============================================================
# test-verify-project.sh — verify-project health check behavior
# Run via: bash tests/run_tests.sh
# ============================================================

run_verify_project_tests() {
    echo "=== verify-project.sh ==="

    local repo="$WORK/verify-repo"
    new_repo "$repo"
    copy_scripts "$repo" verify-project.sh

    # T15: quick mode exits 0 in a minimal repo (critical files disabled)
    rm -f /tmp/hermes-guard-verify-last-run
    if (cd "$repo" && CRITICAL_FILES="" bash scripts/verify-project.sh --quick >/dev/null 2>&1); then
        pass "verify --quick exits 0"
    else
        fail "verify --quick failed in minimal repo"
    fi

    # T16: quick mode records evidence timestamp
    if [ -f /tmp/hermes-guard-verify-last-run ]; then
        NOW=$(date +%s)
        LAST=$(cat /tmp/hermes-guard-verify-last-run 2>/dev/null || echo 0)
        DIFF=$((NOW - LAST))
        if [ "$DIFF" -ge 0 ] && [ "$DIFF" -lt 60 ]; then
            pass "--quick recorded evidence timestamp ($DIFF s ago)"
        else
            fail "timestamp suspiciously old ($DIFF s)"
        fi
    else
        fail "no timestamp file created by --quick"
    fi

    # T17: missing critical file → FAIL (exit 1)
    if (cd "$repo" && CRITICAL_FILES="MUST_EXIST.md" bash scripts/verify-project.sh --quick >/dev/null 2>&1); then
        fail "missing critical file did not fail"
    else
        pass "missing critical file fails check (exit 1)"
    fi

    # T18: --json emits valid JSON
    OUT=$(cd "$repo" && CRITICAL_FILES="" bash scripts/verify-project.sh --json 2>/dev/null)
    if echo "$OUT" | python3 -c "import json,sys; json.loads(sys.stdin.read())" 2>/dev/null; then
        pass "--json output is valid JSON"
    else
        fail "--json output is not valid JSON: $OUT"
    fi
}
