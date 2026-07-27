# Hermes Guard — Architecture

## Design Philosophy

**Don't trust the agent. Verify.**

AI coding agents are powerful but unreliable at self-verification. The same model that writes code cannot be trusted to verify it — it will hallucinate, forget rules, and claim "checked" without checking.

Hermes Guard solves this by creating an **external verification layer** that runs completely outside the agent's context. Shell scripts don't forget. Git hooks can't be skipped. Cron jobs don't get distracted.

## Reliability Layers

```
🟢 Layer 5: Cron (no_agent=true)    95% reliable — shell, no model
🟢 Layer 4: Git hook (pre-commit)   90% reliable — OS-level enforcement
🟢 Layer 3: Gates (scope + danger)  85% reliable — state machine
🟡 Layer 2: AGENTS.md               70% reliable — auto-injected context
🟡 Layer 1: Skills                  60% reliable — trigger-based loading
🔴 Agent reasoning                   50% reliable — self-verification
```

The key insight: **the most reliable layers (🟢) do not involve the AI model at all.**

## Data Flow

```
User opens session
    │
    ├─ AGENTS.md auto-injected ─────────────── Layer 2
    ├─ Session startup checklist runs ──────── Layer 1
    │     └─ Checks for missed cron tasks
    │     └─ Runs verify-project.sh --quick
    │
User says "change X"
    │
    ├─ scope-check.sh declare "change X" ───── Layer 3
    ├─ IMPACT_SCAN (grep all references)
    ├─ Make changes
    ├─ scope-check.sh verify ────────────────── Layer 3
    │
User says "commit"
    │
    └─ pre-commit hook fires ───────────────── Layer 4
          ├─ Evidence gate (verify run?)
          ├─ Scope check (.hermes/scope.yaml?)
          ├─ Common module impact
          └─ SQL anti-patterns

Daily (automatic):
    ├─ 9:00 cron: daily-check.sh ───────────── Layer 5
    └─ 14:00 cron: daily-check.sh ──────────── Layer 5

Weekly (automatic):
    └─ Monday 11:00 cron: governance check ──── Layer 5
```

## Innovation: Cron Catch-up

Most tools assume their cron service is always running. On developer laptops, that's not true.

Hermes Guard's session-startup skill checks:
1. When did the daily cron last run?
2. If >24 hours → execute immediately
3. Report missed inspections to user

This means even if your laptop was off at 9 AM, protection kicks in the moment you open a session.

## Innovation: Evidence Gate

Standard pre-commit hooks check code quality. Hermes Guard's evidence gate checks something meta:

**"Did you actually run the verification, or just claim you did?"**

The pre-commit hook checks `/tmp/hermes-guard-verify-last-run` — if `verify-project.sh` hasn't run in 30 minutes, it warns. This specifically targets the "I checked, trust me" hallucination pattern.

## Innovation: Scope Lifecycle State Machine

The `.hermes/scope.yaml` file acts as a state machine:

```
No file → Safe to commit
    │
    ▼ scope-check.sh declare
File exists → Pre-commit BLOCKED
    │
    ▼ scope-check.sh verify
File deleted → Safe to commit
```

The file's mere existence is a signal: "Currently modifying code, commit locked."

## Comparison with Community Tools

| Feature | Hermes Guard | shellfirm | agentlint | agent-guardrails |
|---------|:--:|:--:|:--:|:--:|
| Shell-based | ✅ | ✅ | ✅ | ✅ |
| Pre-commit hook | ✅ | ✅ | ✅ | ✅ |
| Danger interception | ✅ | ✅ | ❌ | ❌ |
| Scope enforcement | ✅ | ❌ | ❌ | ✅ |
| Evidence gate | ✅ | ❌ | ❌ | ❌ |
| Cron catch-up | ✅ | ❌ | ❌ | ❌ |
| Agent-native skills | ✅ | ❌ | ❌ | ❌ |
| Zero external deps | ✅ | ✅ | ❌ (Python) | ❌ (Node) |
| Offline-first | ✅ | ✅ | ✅ | ✅ |

## File Map

```
hermes-guard/
├── README.md                    # Overview + quick start
├── install.sh                   # One-command installer
├── scripts/
│   ├── danger-guard.sh          # Blocks destructive commands
│   ├── scope-check.sh           # Task scope state machine
│   ├── pre-commit-check.sh      # Git hook compliance gate
│   ├── verify-project.sh        # 17 health checks
│   └── daily-check.sh           # Silent cron inspection
├── skills/
│   ├── guard/SKILL.md           # IMPACT→RULE→VERIFY enforcement
│   └── session-startup/SKILL.md # 8-step session health check
├── templates/
│   └── AGENTS.md.template       # Auto-injected rules template
└── docs/
    └── architecture.md          # This file
```

## Extending

Add project-specific checks to `verify-project.sh`:

```bash
# ---- Custom: Run linter ----
if command -v eslint &>/dev/null; then
    eslint --quiet . 2>/dev/null && check "ESLint" PASS "Clean" || check "ESLint" WARN "Issues found"
fi

# ---- Custom: Run tests ----
if [ -f "package.json" ]; then
    npm test -- --passWithNoTests 2>/dev/null && check "Tests" PASS "Passed" || check "Tests" WARN "Some failed"
fi
```
