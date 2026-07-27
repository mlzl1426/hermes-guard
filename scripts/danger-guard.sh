#!/bin/bash
# ============================================================
# danger-guard.sh — Intercept destructive commands
#
# Part of Hermes Guard (github.com/mlzl1426/hermes-guard)
# Aligned with: shellfirm (github.com/kaplanelad/shellfirm)
#
# Blocks dangerous operations with math challenge-response.
# Works with ANY project, zero dependencies.
#
# Usage:
#   bash danger-guard.sh <command>
#   Or wrap via alias: alias rm='danger-guard rm'
# ============================================================
set -uo pipefail

red()    { echo -e "\033[31m\033[1m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
green()  { echo -e "\033[32m$1\033[0m"; }

# ---- Challenge-response (shellfirm-style) ----
challenge() {
    local a=$((RANDOM % 10))
    local b=$((RANDOM % 10))
    local op=$((RANDOM % 2))
    local expected

    if [ "$op" -eq 0 ]; then
        expected=$((a + b))
        printf "  \360\237\247\256 %d + %d = ? " "$a" "$b"
    else
        expected=$((a * b))
        printf "  \360\237\247\256 %d \303\227 %d = ? " "$a" "$b"
    fi

    read -r user_input
    if [ "$user_input" != "$expected" ]; then
        red "  \342\235\214 Verification failed — operation cancelled"
        return 1
    fi
    return 0
}

# ---- Main check ----
check_command() {
    local cmd="$*"

    # 1. git push --force to protected branches
    if echo "$cmd" | grep -qE 'git push.*(-f|--force)' && echo "$cmd" | grep -qE 'main|master'; then
        red "\360\237\232\250 DANGER: Force push to main/master"
        echo "   Blast Radius: [REMOTE] — May overwrite teammates' commits"
        echo "   Safer: git push --force-with-lease"
        echo ""
        challenge || exit 1
        return 0
    fi

    # 2. git checkout -- (discards uncommitted changes)
    if echo "$cmd" | grep -qE 'git checkout --'; then
        local target
        target=$(echo "$cmd" | grep -oE 'git checkout -- .*' | sed 's/git checkout -- //')
        if [ -n "$target" ] && git diff --name-only 2>/dev/null | grep -qF "$target"; then
            red "\360\237\232\250 DANGER: git checkout -- discards uncommitted work"
            git diff --stat -- "$target" 2>/dev/null | head -5
            echo ""
            echo "   Tip: git stash push -- $target (saves first)"
            echo ""
            challenge || exit 1
        fi
        return 0
    fi

    # 3. rm -rf in home/project directories
    if echo "$cmd" | grep -qE 'rm -rf'; then
        local target
        target=$(echo "$cmd" | grep -oE 'rm -rf [^;|&]+' | sed 's/rm -rf //' | xargs)
        if echo "$target" | grep -qE "^(/home/|\./|/mnt/|~/)" || [ -d "$target" ]; then
            red "\360\237\232\250 DANGER: rm -rf in home/project directory"
            if [ -e "$target" ]; then
                local count size
                count=$(find "$target" -type f 2>/dev/null | wc -l)
                size=$(du -sh "$target" 2>/dev/null | cut -f1)
                echo "   Blast Radius: [$target] — $count files ($size)"
            fi
            echo ""
            challenge || exit 1
        fi
        return 0
    fi

    # 4. git reset --hard
    if echo "$cmd" | grep -qE 'git reset --hard'; then
        red "\360\237\232\250 DANGER: git reset --hard discards all uncommitted changes"
        git status --short 2>/dev/null | head -10
        echo ""
        echo "   Tip: git stash (saves current work first)"
        echo ""
        challenge || exit 1
        return 0
    fi

    # 5. docker rm -f
    if echo "$cmd" | grep -qE 'docker rm -f'; then
        red "\360\237\232\250 DANGER: docker rm -f force-removes containers"
        echo ""
        challenge || exit 1
        return 0
    fi

    return 0
}

# ---- Entry ----
if [ $# -eq 0 ]; then
    echo "Usage: danger-guard.sh <potentially-dangerous-command>"
    echo "Protects: rm -rf | git push -f | git checkout -- | git reset --hard | docker rm -f"
    exit 0
fi

check_command "$@"
