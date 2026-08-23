#!/bin/bash
# ============================================================
# run_tests.sh — Hermes Guard core behavior test suite
#
# Pure shell, zero dependencies (bash + git + standard tools).
# Run: bash tests/run_tests.sh
#
# Covers the core behavior of every guard script:
#   danger-guard     → interception + challenge rejection
#   scope-check      → declare/verify lifecycle, violation detection
#   pre-commit-check → scope file blocking
#   verify-project   → quick mode + evidence timestamp
#   daily-check      → silent exit contract
# ============================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORK="$(mktemp -d /tmp/hermes-guard-test.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "  ✅ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ❌ $1"; }

# ------------------------------------------------------------
# Helper: fresh temp git repo
# ------------------------------------------------------------
new_repo() {
    local dir="$1"
    mkdir -p "$dir"
    git -C "$dir" init -q
    git -C "$dir" config user.email test@example.com
    git -C "$dir" config user.name test
    echo "# Test" > "$dir/README.md"
    git -C "$dir" add -A
    git -C "$dir" commit -qm "init"
}

# ============================================================
echo "=== danger-guard.sh ==="

# T1: safe command passes through
if bash "$REPO_DIR/scripts/danger-guard.sh" "echo hello" >/dev/null 2>&1; then
    pass "T1: safe command not intercepted (exit 0)"
else
    fail "T1: safe command was blocked"
fi

# T2: usage printed with no args
if bash "$REPO_DIR/scripts/danger-guard.sh" 2>&1 | grep -q "Usage: danger-guard.sh"; then
    pass "T2: usage shown without arguments"
else
    fail "T2: usage not shown"
fi

# T3: force-push to main triggers challenge, wrong answer blocked (exit 1)
OUT=$(echo "999" | bash "$REPO_DIR/scripts/danger-guard.sh" "git push -f origin main" 2>&1)
RC=$?
if [ "$RC" -ne 0 ] && echo "$OUT" | grep -q "Verification failed"; then
    pass "T3: force-push to main blocked on wrong challenge answer"
else
    fail "T3: force-push not blocked (rc=$RC, out=$OUT)"
fi

# T4: rm -rf in home directory triggers challenge
OUT=$(echo "999" | bash "$REPO_DIR/scripts/danger-guard.sh" "rm -rf /home/someuser/tmp" 2>&1)
RC=$?
if [ "$RC" -ne 0 ] && echo "$OUT" | grep -q "DANGER"; then
    pass "T4: rm -rf in /home blocked"
else
    fail "T4: rm -rf not blocked (rc=$RC)"
fi

# T5: docker rm -f triggers challenge
OUT=$(echo "999" | bash "$REPO_DIR/scripts/danger-guard.sh" "docker rm -f mycontainer" 2>&1)
RC=$?
if [ "$RC" -ne 0 ] && echo "$OUT" | grep -q "DANGER"; then
    pass "T5: docker rm -f blocked"
else
    fail "T5: docker rm -f not blocked (rc=$RC)"
fi

# ============================================================
echo ""
echo "=== scope-check.sh ==="

REPO="$WORK/scope-repo"
new_repo "$REPO"
mkdir -p "$REPO/scripts"
cp "$REPO_DIR/scripts/scope-check.sh" "$REPO/scripts/"

# T6: declare creates scope file
if (cd "$REPO" && bash scripts/scope-check.sh declare "Test task" >/dev/null 2>&1) && [ -f "$REPO/.hermes/scope.yaml" ]; then
    pass "T6: declare creates .hermes/scope.yaml"
else
    fail "T6: declare did not create scope file"
fi

# T7: verify without out-of-scope changes passes and cleans up
if (cd "$REPO" && bash scripts/scope-check.sh verify >/dev/null 2>&1); then
    if [ ! -f "$REPO/.hermes/scope.yaml" ]; then
        pass "T7: verify passes and cleans up scope file"
    else
        fail "T7: verify passed but scope file not cleaned"
    fi
else
    fail "T7: verify failed on clean scope"
fi

# T8: out-of-scope code file change → verify blocks (exit 1)
(cd "$REPO" && bash scripts/scope-check.sh declare "Only docs" >/dev/null 2>&1)
echo "print('x')" > "$REPO/app.py"
if (cd "$REPO" && bash scripts/scope-check.sh verify >/dev/null 2>&1); then
    fail "T8: out-of-scope change was NOT blocked"
else
    pass "T8: out-of-scope code file blocks verify (exit 1)"
fi
rm -f "$REPO/app.py"

# T9: verify without scope file is non-blocking (exit 0)
rm -rf "$REPO/.hermes"
if (cd "$REPO" && bash scripts/scope-check.sh verify >/dev/null 2>&1); then
    pass "T9: verify without scope file exits 0"
else
    fail "T9: verify without scope file failed"
fi

# ============================================================
echo ""
echo "=== pre-commit-check.sh ==="

REPO2="$WORK/precommit-repo"
new_repo "$REPO2"
mkdir -p "$REPO2/scripts"
cp "$REPO_DIR/scripts/pre-commit-check.sh" "$REPO2/scripts/"

# T10: clean state → commit allowed (exit 0)
echo "change" >> "$REPO2/README.md"
git -C "$REPO2" add README.md
if (cd "$REPO2" && bash scripts/pre-commit-check.sh >/dev/null 2>&1); then
    pass "T10: commit allowed without blockers"
else
    fail "T10: commit blocked in clean state"
fi

# T11: unresolved scope file → commit blocked (exit 1)
mkdir -p "$REPO2/.hermes"
echo 'task: "x"' > "$REPO2/.hermes/scope.yaml"
if (cd "$REPO2" && bash scripts/pre-commit-check.sh >/dev/null 2>&1); then
    fail "T11: unresolved scope file did NOT block commit"
else
    pass "T11: unresolved scope file blocks commit (exit 1)"
fi

# ============================================================
echo ""
echo "=== verify-project.sh ==="

REPO3="$WORK/verify-repo"
new_repo "$REPO3"
mkdir -p "$REPO3/scripts"
cp "$REPO_DIR/scripts/verify-project.sh" "$REPO3/scripts/"

# T12: quick mode exits 0 in a minimal repo (critical files disabled)
rm -f /tmp/hermes-guard-verify-last-run
if (cd "$REPO3" && CRITICAL_FILES="" bash scripts/verify-project.sh --quick >/dev/null 2>&1); then
    pass "T12: verify --quick exits 0"
else
    fail "T12: verify --quick failed in minimal repo"
fi

# T13: quick mode records evidence timestamp
if [ -f /tmp/hermes-guard-verify-last-run ]; then
    NOW=$(date +%s)
    LAST=$(cat /tmp/hermes-guard-verify-last-run 2>/dev/null || echo 0)
    DIFF=$((NOW - LAST))
    if [ "$DIFF" -ge 0 ] && [ "$DIFF" -lt 60 ]; then
        pass "T13: --quick recorded evidence timestamp ($DIFF s ago)"
    else
        fail "T13: timestamp suspiciously old ($DIFF s)"
    fi
else
    fail "T13: no timestamp file created by --quick"
fi

# T14: missing critical file → FAIL (exit 1)
if (cd "$REPO3" && CRITICAL_FILES="MUST_EXIST.md" bash scripts/verify-project.sh --quick >/dev/null 2>&1); then
    fail "T14: missing critical file did not fail"
else
    pass "T14: missing critical file fails check (exit 1)"
fi

# ============================================================
echo ""
echo "=== daily-check.sh ==="

# T15: always exits 0 (alerts are informational)
REPO4="$WORK/daily-repo"
new_repo "$REPO4"
mkdir -p "$REPO4/scripts"
cp "$REPO_DIR/scripts/daily-check.sh" "$REPO4/scripts/"
if (cd "$REPO4" && bash scripts/daily-check.sh >/dev/null 2>&1); then
    pass "T15: daily-check exits 0 (silent contract)"
else
    fail "T15: daily-check exited non-zero"
fi

# ============================================================
echo ""
echo "============================================"
echo "Results: ✅$PASS  ❌$FAIL"
[ "$FAIL" -eq 0 ] && echo "ALL TESTS PASSED" || echo "SOME TESTS FAILED"
exit $([ "$FAIL" -eq 0 ] && echo 0 || echo 1)
