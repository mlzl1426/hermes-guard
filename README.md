# 🛡️ Hermes Guard

> **AI agents are fast. Guardrails make them safe.**

Hermes Guard is a **zero-token, model-proof verification layer** for AI coding agents. It runs entirely outside the agent's context — shell scripts, git hooks, and cron jobs — so the agent can't forget, skip, or hallucinate its way past the checks.

Built for [Hermes Agent](https://github.com/NousResearch/hermes-agent), but the scripts work with **any AI coding tool** (Claude Code, Codex, Cursor, etc.).

---

## The Problem

You tell your AI agent to follow rules. It says "✅ Checked everything, all good!" — but it didn't. Sound familiar?

```
Agent: "CHANGELOG updated ✓"
Reality: CHANGELOG.md hasn't been touched in 3 days

Agent: "No impact on other modules ✓"  
Reality: grep shows 12 other files reference what you just changed

Agent: "All docs synced ✓"
Reality: Windows host files are from last week
```

**The root cause: AI agents self-verify. They're both the player and the referee.** You can't trust the same model that wrote the code to verify the code.

---

## The Solution

Hermes Guard adds an **external verification layer** — checks that run outside the agent's reasoning, so the agent physically cannot skip them.

```
🟢 Layer 5: Cron auto-inspection     ← runs whether agent remembers or not
🟢 Layer 4: Pre-commit git hook      ← blocks bad commits at the OS level
🟢 Layer 3: Scope + danger gates     ← prevents scope creep and destructive ops
🟡 Layer 2: AGENTS.md auto-injection ← system-level rule injection every session
🟡 Layer 1: Skills knowledge base    ← detailed procedures, loaded on trigger
```

---

## What's Included

### Scripts (zero-token, pure shell)

| Script | What it does | Aligned with |
|--------|-------------|:--:|
| `danger-guard.sh` | Blocks destructive commands (`rm -rf`, `git push -f`, `git reset --hard`) with math challenge | [shellfirm](https://github.com/kaplanelad/shellfirm) |
| `scope-check.sh` | Declare task scope before changes → verify no out-of-scope files after | [agent-guardrails](https://github.com/logi-cmd/agent-guardrails) |
| `pre-commit-check.sh` | Runs evidence gate + common module impact + DYNAMIC_WHERE check on every commit | [agentlint](https://github.com/mauhpr/agentlint) |
| `verify-project.sh` | 17 automated health checks: API, Docker, DB, files, git sync, disk, pycache... | [repo-seatbelt](https://github.com/berkcangumusisik/repo-seatbelt) |
| `daily-check.sh` | Silent daily cron inspection — only reports when something's wrong | — |

### Skills (Hermes-native)

| Skill | What it does |
|-------|-------------|
| `guard` | Enforces IMPACT_SCAN → RULE_CHECK → VERIFY on every code change |
| `session-startup` | 8-step project health check on every new session + cron catch-up |

### Templates

| File | Purpose |
|------|---------|
| `AGENTS.md.template` | Auto-injected every session — 5 core rules + forbidden actions + end-of-day ritual |

---

## Quick Start

```bash
# 1. Install
git clone https://github.com/mlzl1426/hermes-guard.git
cd hermes-guard && bash install.sh /path/to/your-project

# 2. What happens:
#    ✅ Pre-commit hook installed (.git/hooks/pre-commit)
#    ✅ AGENTS.md created (auto-injected every Hermes session)
#    ✅ Cron jobs registered (daily + weekly inspection)
#    ✅ Guard skills installed (~/.hermes/skills/)
#    ✅ Shell scripts copied to your-project/scripts/

# 3. Start working — protection is active immediately
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  HERMES GUARD                            │
│                                                          │
│  🟢 CRON (no_agent=true)  ─── daily-check.sh            │
│       │  9:00 + 14:00 daily, only alerts on problems    │
│       │  Runs even if agent forgets everything          │
│                                                          │
│  🟢 GIT HOOK  ─── pre-commit-check.sh                   │
│       │  Blocks commits that violate rules              │
│       │  Agent CANNOT skip — OS-level enforcement        │
│                                                          │
│  🟢 GATES  ─── scope-check.sh + danger-guard.sh         │
│       │  Scope: declare before change, verify after     │
│       │  Danger: math challenge for destructive commands│
│                                                          │
│  🟡 CONTEXT  ─── AGENTS.md (auto-injected)              │
│       │  Core rules present in every session             │
│                                                          │
│  🟡 SKILLS  ─── guard + session-startup                 │
│       │  Detailed procedures, loaded on trigger words    │
│                                                          │
│  🔴 AGENT REASONING  ─── least reliable, last resort    │
└─────────────────────────────────────────────────────────┘
```

---

## What Makes This Different

| Feature | Hermes Guard | Other tools |
|---------|:--:|:--:|
| **Zero token cost** | ✅ Shell scripts run outside agent context | ❌ Agents pay tokens to self-verify |
| **Model-proof** | ✅ Agent CANNOT bypass git hooks or cron | ❌ Agent can "forget" to run checks |
| **Cron catch-up** | ✅ Missed cron? Session startup catches it | ❌ Missed = gone forever |
| **Evidence gate** | ✅ Checks if you actually verified, not just claimed to | ❌ "I checked, trust me" |
| **Scope lifecycle** | ✅ declare → verify → cleanup state machine | ❌ Plan without enforcement |
| **Hermes native** | ✅ Deep integration with skills + memory + cron | ❌ External tools, loose coupling |
| **Works offline** | ✅ All checks run locally, no API calls | ⚠️ Some require cloud services |

---

## Real-World Results

Deployed on [M-ABI](https://github.com/mlzl1426/cb-bi) — a 50,000-line commercial BI platform:

| Problem | Before | After |
|---------|:--:|:--:|
| Agent forgets workflow after 2 days | Frequent | Eliminated (AGENTS.md + cron) |
| Change A breaks B | Weekly | Blocked (scope-check + pre-commit) |
| "Verified" but didn't | Daily | Caught (evidence gate) |
| Files claimed updated, not actually | Occasional | Caught (verify-project.sh) |
| Documentation drift | Constant | <3 day lag enforced |

---

## Contributing

Pull requests welcome! Areas we'd love help with:
- [ ] VS Code / Cursor extension
- [ ] More danger patterns (kubernetes, terraform, AWS)
- [ ] Web dashboard for inspection history
- [ ] Claude Code / Codex native integrations

---

## License

MIT © 2026 [木木](https://github.com/mlzl1426)

---

*"Don't trust the agent. Verify."*
