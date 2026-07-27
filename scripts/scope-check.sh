#!/bin/bash
# ============================================================
# scope-check.sh — Task scope enforcement
#
# Part of Hermes Guard (github.com/mlzl1426/hermes-guard)
# Aligned with: agent-guardrails (github.com/logi-cmd/agent-guardrails)
#
# Prevents "change A breaks B" by enforcing declared task scope.
# declare → work → verify state machine.
#
# Usage:
#   bash scope-check.sh declare "Fix login button alignment"
#   ... make changes ...
#   bash scope-check.sh verify
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/.."

SCOPE_FILE=".hermes/scope.yaml"
ACTION="${1:-verify}"

red()    { echo -e "\033[31m\033[1m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
green()  { echo -e "\033[32m$1\033[0m"; }
bold()   { echo -e "\033[1m$1\033[0m"; }

do_declare() {
    local task="$*"
    if [ -z "$task" ]; then
        red "Usage: scope-check.sh declare \"task description\""
        exit 1
    fi

    local baseline
    baseline=$(git diff --name-only 2>/dev/null | sort)
    local staged
    staged=$(git diff --cached --name-only 2>/dev/null | sort)
    local all_files
    all_files=$( (echo "$baseline"; echo "$staged") | sort -u | grep -v '^$')

    mkdir -p .hermes
    cat > "$SCOPE_FILE" << EOF
# Scope declaration — auto-generated
# This file existing = pre-commit is BLOCKED until you run 'verify'

task: "$task"
declared_at: "$(date '+%Y-%m-%d %H:%M:%S')"
baseline_files:
$(echo "$all_files" | sed 's/^/  - "/' | sed 's/$/"/')
EOF

    echo ""
    bold "\360\237\223\213 Scope declared"
    echo "   Task: $task"
    echo "   Baseline files ($(echo "$all_files" | grep -c .)):"
    echo "$all_files" | sed 's/^/     \360\237\223\204 /'
    echo ""
    echo "   When done: bash scripts/scope-check.sh verify"
}

do_verify() {
    if [ ! -f "$SCOPE_FILE" ]; then
        yellow "\342\232\240\357\270\217  No scope file found."
        echo "   Before changes: bash scripts/scope-check.sh declare \"task\""
        exit 0
    fi

    local task declared_at
    task=$(grep 'task:' "$SCOPE_FILE" | head -1 | sed 's/task: *"//' | sed 's/"$//')
    declared_at=$(grep 'declared_at:' "$SCOPE_FILE" | head -1 | sed 's/declared_at: *"//' | sed 's/"$//')

    local baseline_files
    baseline_files=$(sed -n '/baseline_files:/,/^[a-z]/p' "$SCOPE_FILE" \
        | grep '  - "' | sed 's/  - "//' | sed 's/"$//')

    local current_files staged_files all_current
    current_files=$(git diff --name-only 2>/dev/null | sort)
    staged_files=$(git diff --cached --name-only 2>/dev/null | sort)
    all_current=$( (echo "$current_files"; echo "$staged_files") | sort -u | grep -v '^$')

    local new_files="" scope_violations=0
    for f in $all_current; do
        if ! echo "$baseline_files" | grep -qF "$f"; then
            new_files="$new_files$f\n"
            scope_violations=$((scope_violations + 1))
        fi
    done

    echo ""
    bold "\360\237\224\215 Scope verification"
    echo "   Task: $task"
    echo ""

    if [ "$scope_violations" -gt 0 ]; then
        yellow "\342\232\240\357\270\217  $scope_violations file(s) outside declared scope:"
        echo -e "$new_files" | grep -v '^$' | sed 's/^/     \360\237\223\204 /'

        local safe_patterns='^scripts/\|^docs/\|^.hermes/\|^.git/'
        local truly_risky=0
        for f in $(echo -e "$new_files" | grep -v '^$'); do
            if ! echo "$f" | grep -qE "$safe_patterns"; then
                truly_risky=$((truly_risky + 1))
            fi
        done

        if [ "$truly_risky" -gt 0 ]; then
            red "\360\237\224\264 $truly_risky are code files — may impact other modules!"
            echo ""
            echo "   Review the changes, then:"
            echo "   bash scripts/scope-check.sh declare \"$task\"  # re-declare"
            exit 1
        else
            green "\342\234\205 New files are scripts/docs/config — low risk"
        fi
    else
        green "\342\234\205 No out-of-scope files detected"
    fi

    rm -f "$SCOPE_FILE"
    echo ""
    green "\342\234\205 Scope check passed — scope file cleaned up"
}

case "$ACTION" in
    declare|plan) shift; do_declare "$@" ;;
    verify|enforce|check) do_verify ;;
    *) echo "Usage: scope-check.sh {declare|verify}" ;;
esac
