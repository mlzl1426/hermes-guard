#!/bin/bash
# ============================================================
# lib.sh — shared helpers for the Hermes Guard test suite
#
# Provides: pass/fail counters, temp git repo factory,
#           script copier. Sourced by run_tests.sh and
#           individual test files (when run standalone).
# ============================================================

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "  ✅ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ❌ $1"; }

# Fresh temp git repo with one committed file
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

# Copy guard scripts into a repo's scripts/ dir
copy_scripts() {
    local repo="$1"
    shift
    mkdir -p "$repo/scripts"
    for s in "$@"; do
        cp "$REPO_DIR/scripts/$s" "$repo/scripts/"
    done
}
