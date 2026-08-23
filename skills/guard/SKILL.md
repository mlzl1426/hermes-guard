---
name: guard
description: Universal enforcement — IMPACT_SCAN → RULE_CHECK → VERIFY on every code change
tags: [guard, enforcement, verification]
triggers:
  - "改代码"
  - "修改"
  - "提交"
  - "commit"
  - "guard"
  - "执法"
  - "验证"
---

# Guard — Universal Code Change Enforcement

> Part of Hermes Guard (github.com/mlzl1426/hermes-guard)
> Drop-in skill for any Hermes Agent project.

---

## Three-Step Enforcement (cannot skip)

```
BEFORE:  IMPACT_SCAN  →  DURING:  RULE_CHECK  →  AFTER:  VERIFY
```

---

## Step 1: Before — IMPACT_SCAN

**Before writing any code, answer three questions:**

### Q1: Which files will change?
List exact file paths.

### Q2: Who references these files?
For each file/function/class being changed:
```bash
grep -rn "<name>" --include="*.py" --include="*.vue" --include="*.ts" --include="*.sql" .
```

### Q3: Do affected modules need synchronized changes?
Confirm each one. If unsure → ask first.

**Shared modules (common/, lib/, utils/) → MUST grep ALL references.**

---

## Step 2: During — RULE_CHECK

| Change type | Must verify |
|-------------|------------|
| Database/SQL | Parameterized queries? COUNT query synced? |
| API/Backend | All callers updated? Endpoint contract preserved? |
| Frontend/UI | Shared components affected? CSS isolation? |
| Config/Env | Docker Compose references? .env template? |
| Delete file | `grep -rn "filename" docker-compose.yml Makefile` |

---

## Step 3: After — VERIFY

```bash
# Quick health check
bash scripts/verify-project.sh --quick

# Full verification  
bash scripts/verify-project.sh

# Pre-commit gate (runs automatically via git hook)
bash scripts/pre-commit-check.sh
```

---

## Iron Rules

1. **IMPACT_SCAN cannot be skipped** — no scanning = no coding
2. **VERIFY cannot be fabricated** — must actually run the script
3. **verify-project.sh output must be shown** — no "trust me, I checked"
4. **WARN ≥ 1 → never say "all good"** — be honest about warnings

---

## Verification Layers

```
Agent self-check (guard) → fast, every change
    ↓
External verify (verify-project.sh) → independent, shell-based
    ↓  
Git hook (pre-commit) → enforced on the git commit path
    ↓
Cron inspection (daily-check.sh) → automatic, catches drift
```
