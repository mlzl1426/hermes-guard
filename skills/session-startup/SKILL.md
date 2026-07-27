---
name: session-startup
description: Project health check on every new session — 8 steps + cron catch-up
tags: [startup, session, health, governance]
triggers:
  - "启动"
  - "开始"
  - "新会话"
  - "start"
  - "begin"
---

# Session Startup Checklist

> Part of Hermes Guard (github.com/mlzl1426/hermes-guard)

---

## When to Run

Every new Hermes Agent session for this project.

---

## 8 Steps (≈2 minutes, cannot skip)

### Step 1: Read project rules (30s)
- Read `AGENTS.md` or `CLAUDE.md` or `DEVELOPMENT_CONSTITUTION.md`
- Confirm core rules are loaded

### Step 2: Sync code (20s)
```bash
git pull
# If conflict → STOP, notify user
```

### Step 3: Recent changes (20s)
```bash
git log -3 --oneline
git status --short
```

### Step 4: Root directory hygiene (10s)
```bash
ls *.md *.sql *.sh 2>/dev/null | wc -l
# >15 → needs cleanup
```

### Step 5: Confirm working directory (10s)
Verify you're in the correct project root.

### Step 6: 🔴 Cron catch-up (30s)
Check if automated inspections missed their window:
- Daily health check cron → last_run > 24h? → run now
- Weekly governance cron → last_run > 7 days? → run now
- Report any missed tasks to user

### Step 7: Start services (40s, optional)
Only if user asks. Check Docker → MySQL → API → Frontend.

### Step 8: Load guard + verify (30s)
```bash
# Load enforcement skill
# Run quick health check
bash scripts/verify-project.sh --quick
```

---

## Completion Report Template

```
✅ Session startup complete
- Rules loaded: [file name]
- Code synced: [git log -1 --oneline]
- Recent: git log shows [N] new commits
- Verify: [✅N ⚠️N ❌N]
- Cron catch-up: [OK / ⚠️ ran N missed tasks]
- Status: [stable / ⚠️ N items need attention]
```

**Never say "all good" until verify-project.sh passes with 0 ❌.**
