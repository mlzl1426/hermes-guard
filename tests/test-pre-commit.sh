#!/bin/bash
# ============================================================
# test-pre-commit.sh — pre-commit-check gate behavior
# Run via: bash tests/run_tests.sh
# ============================================================

run_pre_commit_tests() {
    echo "=== pre-commit-check.sh ==="

    local repo="$WORK/precommit-repo"
    new_repo "$repo"
    copy_scripts "$repo" pre-commit-check.sh verify-project.sh

    # T12: clean state → commit allowed (exit 0)
    echo "change" >> "$repo/README.md"
    git -C "$repo" add README.md
    if (cd "$repo" && bash scripts/pre-commit-check.sh >/dev/null 2>&1); then
        pass "commit allowed without blockers"
    else
        fail "commit blocked in clean state"
    fi

    # T13: unresolved scope file → commit blocked, no-verify hint shown
    mkdir -p "$repo/.hermes"
    echo 'task: "x"' > "$repo/.hermes/scope.yaml"
    OUT=$(cd "$repo" && bash scripts/pre-commit-check.sh 2>&1)
    RC=$?
    if [ "$RC" -ne 0 ] && echo "$OUT" | grep -q "no-verify"; then
        pass "unresolved scope file blocks commit + no-verify hint (exit 1)"
    else
        fail "scope file did not block commit (rc=$RC)"
    fi

    # T14: expired evidence timestamp → warning "not run in 30 minutes"
    rm -rf "$repo/.hermes"
    git -C "$repo" reset -q
    OLD=$(( $(date +%s) - 3600 ))
    echo "$OLD" > /tmp/hermes-guard-verify-last-run
    OUT=$(cd "$repo" && bash scripts/pre-commit-check.sh 2>&1)
    if echo "$OUT" | grep -q "not run in 30 minutes"; then
        pass "expired evidence (1h old) triggers warning"
    else
        fail "expired evidence not detected"
    fi
}
