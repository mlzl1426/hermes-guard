#!/bin/bash
# ============================================================
# test-scope-check.sh — scope-check declare/verify lifecycle
# Run via: bash tests/run_tests.sh
# ============================================================

run_scope_check_tests() {
    echo "=== scope-check.sh ==="

    local repo="$WORK/scope-repo"
    new_repo "$repo"
    copy_scripts "$repo" scope-check.sh

    # T8: declare creates scope file
    if (cd "$repo" && bash scripts/scope-check.sh declare "Test task" >/dev/null 2>&1) && [ -f "$repo/.hermes/scope.yaml" ]; then
        pass "declare creates .hermes/scope.yaml"
    else
        fail "declare did not create scope file"
    fi

    # T9: verify without out-of-scope changes passes and cleans up
    if (cd "$repo" && bash scripts/scope-check.sh verify >/dev/null 2>&1); then
        if [ ! -f "$repo/.hermes/scope.yaml" ]; then
            pass "verify passes and cleans up scope file"
        else
            fail "verify passed but scope file not cleaned"
        fi
    else
        fail "verify failed on clean scope"
    fi

    # T10: out-of-scope code file change → verify blocks (exit 1)
    (cd "$repo" && bash scripts/scope-check.sh declare "Only docs" >/dev/null 2>&1)
    echo "print('x')" > "$repo/app.py"
    if (cd "$repo" && bash scripts/scope-check.sh verify >/dev/null 2>&1); then
        fail "out-of-scope change was NOT blocked"
    else
        pass "out-of-scope code file blocks verify (exit 1)"
    fi
    rm -f "$repo/app.py"

    # T11: verify without scope file is non-blocking (exit 0)
    rm -rf "$repo/.hermes"
    if (cd "$repo" && bash scripts/scope-check.sh verify >/dev/null 2>&1); then
        pass "verify without scope file exits 0"
    else
        fail "verify without scope file failed"
    fi
}
