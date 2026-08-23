#!/bin/bash
# ============================================================
# test-danger-guard.sh — danger-guard core behavior tests
# Run via: bash tests/run_tests.sh
# ============================================================

run_danger_guard_tests() {
    echo "=== danger-guard.sh ==="

    # T1: safe command passes through
    if bash "$REPO_DIR/scripts/danger-guard.sh" "echo hello" >/dev/null 2>&1; then
        pass "safe command not intercepted (exit 0)"
    else
        fail "safe command was blocked"
    fi

    # T2: usage printed with no args
    if bash "$REPO_DIR/scripts/danger-guard.sh" 2>&1 | grep -q "Usage: danger-guard.sh"; then
        pass "usage shown without arguments"
    else
        fail "usage not shown"
    fi

    # T3: force-push to main triggers challenge, wrong answer blocked
    OUT=$(echo "999" | bash "$REPO_DIR/scripts/danger-guard.sh" "git push -f origin main" 2>&1)
    RC=$?
    if [ "$RC" -ne 0 ] && echo "$OUT" | grep -q "Verification failed"; then
        pass "force-push to main blocked on wrong challenge answer"
    else
        fail "force-push not blocked (rc=$RC, out=$OUT)"
    fi

    # T4: rm -rf in home directory triggers challenge
    OUT=$(echo "999" | bash "$REPO_DIR/scripts/danger-guard.sh" "rm -rf /home/someuser/tmp" 2>&1)
    RC=$?
    if [ "$RC" -ne 0 ] && echo "$OUT" | grep -q "DANGER"; then
        pass "rm -rf in /home blocked"
    else
        fail "rm -rf not blocked (rc=$RC)"
    fi

    # T5: docker rm -f triggers challenge
    OUT=$(echo "999" | bash "$REPO_DIR/scripts/danger-guard.sh" "docker rm -f mycontainer" 2>&1)
    RC=$?
    if [ "$RC" -ne 0 ] && echo "$OUT" | grep -q "DANGER"; then
        pass "docker rm -f blocked"
    else
        fail "docker rm -f not blocked (rc=$RC)"
    fi

    # T6: git checkout -- with uncommitted changes triggers challenge
    local repo="$WORK/danger-git"
    new_repo "$repo"
    echo "change" >> "$repo/README.md"
    OUT=$(echo "999" | (cd "$repo" && bash "$REPO_DIR/scripts/danger-guard.sh" "git checkout -- README.md") 2>&1)
    RC=$?
    if [ "$RC" -ne 0 ] && echo "$OUT" | grep -q "DANGER"; then
        pass "git checkout -- discarding work blocked"
    else
        fail "git checkout -- not blocked (rc=$RC)"
    fi

    # T7: git reset --hard triggers challenge
    OUT=$(echo "999" | (cd "$repo" && bash "$REPO_DIR/scripts/danger-guard.sh" "git reset --hard") 2>&1)
    RC=$?
    if [ "$RC" -ne 0 ] && echo "$OUT" | grep -q "DANGER"; then
        pass "git reset --hard blocked"
    else
        fail "git reset --hard not blocked (rc=$RC)"
    fi
}
