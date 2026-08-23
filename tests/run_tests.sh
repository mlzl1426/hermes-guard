#!/bin/bash
# ============================================================
# run_tests.sh — Hermes Guard test suite entry point
#
# Pure shell, zero dependencies (bash + git + python3 + standard tools).
# Run: bash tests/run_tests.sh
#
# Suite layout (each file tests one guard script):
#   lib.sh                   shared helpers
#   test-danger-guard.sh     interception + challenge rejection
#   test-scope-check.sh      declare/verify lifecycle, violation detection
#   test-pre-commit.sh       scope blocking, evidence gate expiry, no-verify hint
#   test-verify-project.sh   quick mode, evidence timestamp, JSON output
#   test-daily-check.sh      silent exit contract
# ============================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
export REPO_DIR
WORK="$(mktemp -d /tmp/hermes-guard-test.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
export WORK

source "$SCRIPT_DIR/lib.sh"
source "$SCRIPT_DIR/test-danger-guard.sh"
source "$SCRIPT_DIR/test-scope-check.sh"
source "$SCRIPT_DIR/test-pre-commit.sh"
source "$SCRIPT_DIR/test-verify-project.sh"
source "$SCRIPT_DIR/test-daily-check.sh"

run_danger_guard_tests
run_scope_check_tests
run_pre_commit_tests
run_verify_project_tests
run_daily_check_tests

echo ""
echo "============================================"
echo "Results: ✅$PASS  ❌$FAIL"
[ "$FAIL" -eq 0 ] && echo "ALL TESTS PASSED" || echo "SOME TESTS FAILED"
exit $([ "$FAIL" -eq 0 ] && echo 0 || echo 1)
