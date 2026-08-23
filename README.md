# 🛡️ Hermes Guard

> **AI agents are fast. Guardrails make them safe.**
> **AI 代理很快，护栏让它们安全。**

**AI coding agents should not be responsible for verifying their own work.**

**AI 编码代理不应该负责验证自己的工作。**

Hermes Guard is a **zero-token, model-proof verification layer** for AI coding agents. It runs entirely outside the agent's context — shell scripts, git hooks, and cron jobs — so the agent can't forget, skip, or hallucinate its way past the checks.

Hermes Guard 是一个**零 token、模型无法绕过的验证层**。它完全在 AI 代理的上下文之外运行——纯 shell 脚本、git hooks、cron 定时任务——代理无法忘记、无法跳过、无法编造检查结果。

```
Developer
    │
    ▼
AI Coding Agent
    │
    ▼
HERMES GUARD
 ├── Scope Check     (declare → verify state machine)
 ├── Danger Guard    (intercepts destructive commands)
 ├── Git Hook        (blocks bad commits at OS level)
 ├── Health Check    (9 built-in project inspections)
 └── Daily Inspection (silent cron, alerts only on problems)
    │
    ▼
PASS / BLOCK
```

Built for [Hermes Agent](https://github.com/NousResearch/hermes-agent), but the scripts work with **any AI coding tool** (Claude Code, Codex, Cursor, etc.).

为 [Hermes Agent](https://github.com/NousResearch/hermes-agent) 构建，但脚本可用于**任何 AI 编码工具**（Claude Code、Codex、Cursor 等）。

---

## 🤔 The Problem / 问题

You tell your AI agent to follow rules. It says "✅ Checked everything, all good!" — but it didn't. Sound familiar?

你告诉 AI 代理要遵守规则。它说「✅ 全部检查完毕，一切正常！」——但根本没查。耳熟吗？

```
Agent: "CHANGELOG updated ✓"
Reality: CHANGELOG.md hasn't been touched in 3 days

Agent: "No impact on other modules ✓"  
Reality: grep shows 12 other files reference what you just changed

Agent: "All docs synced ✓"
Reality: Windows host files are from last week
```

```
代理: 「CHANGELOG 已更新 ✓」
实际: CHANGELOG.md 3 天没动过

代理: 「不影响其他模块 ✓」
实际: grep 发现 12 个文件引用了你刚改的东西

代理: 「文档已全部同步 ✓」
实际: 宿主机文件还是上周的
```

**The root cause: AI agents self-verify. They're both the player and the referee.** The same model that wrote the code is asked to judge the code — it has no incentive, and often no ability, to catch its own mistakes.

**根因：AI 代理自我验证——既当运动员又当裁判。** 写代码的模型和验证代码的是同一个模型，你不能信它——它没有动机、也常常没有能力发现自己的错误。

That is why verification must be **model-independent**: checks that run outside the model's reasoning, triggered by mechanisms the model cannot override.

所以验证必须是**模型无关的（model-independent）**：检查在模型的推理之外运行，由模型无法覆盖的机制触发。

---

## ✅ The Solution / 解决方案

Hermes Guard adds an **external verification layer** — checks that run outside the agent's reasoning, so the agent physically cannot skip them.

Hermes Guard 增加了一个**外部验证层**——检查在代理推理之外运行，代理物理上无法跳过。

```
🟢 Layer 5: Cron auto-inspection     ← runs whether agent remembers or not
🟢 Layer 4: Pre-commit git hook      ← blocks bad commits at the OS level
🟢 Layer 3: Scope + danger gates     ← prevents scope creep and destructive ops
🟡 Layer 2: AGENTS.md auto-injection ← system-level rule injection every session
🟡 Layer 1: Skills knowledge base    ← detailed procedures, loaded on trigger
```

```
🟢 第五层: Cron 自动巡检       ← 代理记不记得都会跑
🟢 第四层: Pre-commit Git Hook ← OS 级拦截，代理绕不过去
🟢 第三层: 范围+危险门         ← 防止越界修改和破坏性操作
🟡 第二层: AGENTS.md 自动注入  ← 每次会话系统级规则注入
🟡 第一层: 技能知识库          ← 详细流程，触发词加载
```

**The reliability principle: the more reliable a layer is, the less it depends on the AI model.** Cron and git hooks (95%) never touch the model; skills and memory (70%) are model-dependent by nature.

**可靠性原则：越可靠的层越不依赖 AI 模型。** Cron 和 git hook（95%）完全不经过模型；技能和记忆（70%）天生依赖模型。

---

## 🚀 Quick Start / 快速开始

```bash
# 1. Install / 安装
git clone https://github.com/mlzl1426/hermes-guard.git
cd hermes-guard && bash install.sh /path/to/your-project

# 2. What happens: / 安装后自动完成：
#    ✅ Pre-commit hook 已安装 (.git/hooks/pre-commit)
#    ✅ AGENTS.md 已创建（每次 Hermes 会话自动注入）
#    ✅ Guard 技能已安装 (~/.hermes/skills/)
#    ✅ Shell 脚本已复制到 your-project/scripts/
#    ⏰ Cron 示例输出（需手动注册到你的 Hermes cron）

# 3. Start working — protection is active immediately
#    开始工作——保护立即生效
```

Requirements / 环境要求：`bash 4+`, `git`, and standard POSIX tools (`grep`, `sed`, `awk`, `curl`). Docker/MySQL checks auto-skip when not present.

依赖：`bash 4+`、`git` 及标准 POSIX 工具（`grep`、`sed`、`awk`、`curl`）。未安装 Docker/MySQL 时相关检查自动跳过。

---

## 📦 What's Included / 包含内容

### Scripts (zero-token, pure shell) / 脚本（零 token，纯 shell）

| Script / 脚本 | What it does / 作用 | Aligned with / 对齐 |
|--------|-------------|:--:|
| `danger-guard.sh` | 拦截危险命令（`rm -rf`/`git push -f`/`git reset --hard`），数学验证码阻断 | [shellfirm](https://github.com/kaplanelad/shellfirm) |
| `scope-check.sh` | 改前声明任务范围 → 改后检查是否越界 | [agent-guardrails](https://github.com/logi-cmd/agent-guardrails) |
| `pre-commit-check.sh` | 每次提交：证据门 + 公共模块影响 + SQL 反模式检查 | [agentlint](https://github.com/mauhpr/agentlint) |
| `verify-project.sh` | 9 项内置健康检查：Git、API、Docker、DB、关键文件、磁盘、PyCache… | [repo-seatbelt](https://github.com/berkcangumusisik/repo-seatbelt) |
| `daily-check.sh` | 静默每日巡检——只有发现问题才报告 | — |

### Skills (Hermes-native) / 技能（Hermes 原生）

| Skill / 技能 | What it does / 作用 |
|-------|-------------|
| `guard` | 每次改代码强制执行 IMPACT_SCAN → RULE_CHECK → VERIFY |
| `session-startup` | 每次新会话 8 步项目健康检查 + cron 追补 |

### Templates / 模板

| File / 文件 | Purpose / 用途 |
|------|---------|
| `AGENTS.md.template` | 每次会话自动注入——5 条核心规则 + 禁止行为 + 下班收尾仪式 |

---

## 📊 Case Study / 实战案例

Deployed on a 50K-line commercial BI platform (private repository, identity withheld).

已在 5 万行商业 BI 平台（私有仓库，项目名匿名）上实际部署验证。

**Project Size / 项目规模** — ~50K LOC (Python/Vue/SQL), 284 commits, in production use since July 2026

**Problems Found / 发现的问题**
- Missing verification — agent claimed "verified" without running checks / 声称验证过但实际没跑
- Workflow violations — rules forgotten after 2 days / 规则两天后被遗忘
- Scope violations — changes touching undeclared files / 改动越出声明范围
- Documentation mismatch — docs claimed updated, files stale / 文档声称更新实际滞后

**Outcome / 效果**

| Problem / 问题 | Before / 之前 | After / 之后 |
|---------|:--:|:--:|
| Agent forgets workflow after 2 days / 代理两天后忘记流程 | Frequent / 频繁 | Eliminated / 消除 |
| Change A breaks B / 改 A 坏 B | Weekly / 每周 | Blocked / 拦截 |
| "Verified" but didn't / 说验证了但没验证 | Daily / 每天 | Caught / 捕获 |
| Files claimed updated, not actually / 说更新了但没更新 | Occasional / 偶尔 | Caught / 捕获 |
| Documentation drift / 文档漂移 | Constant / 持续 | <3 day lag / <3 天滞后 |

---

## 🏗️ Architecture / 架构

```
┌─────────────────────────────────────────────────────────┐
│                  HERMES GUARD                            │
│                                                          │
│  🟢 CRON (no_agent=true)  ─── daily-check.sh            │
│       │  每天定时巡检，只报告异常                          │
│       │  代理忘记一切也会执行                              │
│                                                          │
│  🟢 GIT HOOK  ─── pre-commit-check.sh                   │
│       │  拦截违规提交                                      │
│       │  代理无法跳过——OS 级别强制执行                     │
│                                                          │
│  🟢 GATES  ─── scope-check.sh + danger-guard.sh         │
│       │  范围: 改前声明，改后验证                          │
│       │  危险: 数学验证码阻断破坏性命令                     │
│                                                          │
│  🟡 CONTEXT  ─── AGENTS.md (auto-injected)              │
│       │  核心规则每次会话都注入                             │
│                                                          │
│  🟡 SKILLS  ─── guard + session-startup                 │
│       │  详细流程，触发词加载                               │
│                                                          │
│  🔴 AGENT REASONING  ─── 最不可靠，最后手段               │
└─────────────────────────────────────────────────────────┘
```

Full design notes: [docs/architecture.md](docs/architecture.md)
完整设计文档：[docs/architecture.md](docs/architecture.md)

---

## ⭐ What Makes This Different / 我们的独特之处

| Feature / 特性 | Hermes Guard | Other tools / 其他工具 |
|---------|:--:|:--:|
| **Zero token cost / 零 token 成本** | ✅ Shell 脚本在代理上下文外运行 | ❌ 代理花 token 自我验证 |
| **Model-proof / 模型绕不过去** | ✅ 代理无法绕过 git hook 或 cron | ❌ 代理可以"忘记"运行检查 |
| **Cron catch-up / Cron 追补** | ✅ Cron 错过？会话启动自动补 | ❌ 错过就永远错过了 |
| **Evidence gate / 证据门** | ✅ 检查你是否真的验证了，而不是声称验证了 | ❌ "我检查过了，相信我" |
| **Scope lifecycle / 范围生命周期** | ✅ declare → verify → cleanup 状态机 | ❌ 有声明无强制执行 |
| **Hermes native / Hermes 原生** | ✅ 深度集成 skills + memory + cron | ❌ 外部工具，松耦合 |
| **Works offline / 离线可用** | ✅ 所有检查本地运行，无需 API | ⚠️ 部分需要云服务 |

---

## 🗺️ Roadmap / 路线图

What we are actually working on — no promises beyond these. / 只列真实计划，不做空头承诺。

| Version / 版本 | Scope / 范围 |
|--------|--------|
| **v0.1.0** (current / 当前) | Core guard scripts + installer + bilingual docs + CI (ShellCheck) + shell tests |
| **v0.2.0** | More danger patterns (Kubernetes / Terraform / AWS), Windows shell (Git Bash) support, wider test coverage |
| **v0.3.0** | Editor/IDE hook integration, plugin system for custom rules, per-project rule profiles |

---

## 🌱 Vision / 愿景

Hermes Guard is intended to become a **reusable verification layer for AI coding agents** — not a tool tied to a single assistant. Any developer who works with AI-assisted coding should be able to add an independent safety net in one command.

Hermes Guard 的目标是成为**可复用的 AI 编码代理验证层**——不绑定任何单一助手。任何使用 AI 辅助编码的开发者，都能用一条命令给自己的项目加上独立的安全网。

The project exists to help developers build **trustworthy AI-assisted development workflows**.

这个项目的意义，是帮助开发者建立**可信的 AI 辅助开发流程**。

---

## 🔬 Tech Stack / 技术栈

| 层 | 技术 | 可靠性 |
|-----|------|:--:|
| 外部脚本 | Pure Bash + POSIX tools（git/curl/grep/sed/awk，零外部依赖） | 95% |
| Git Hook | Bash + Git | 90% |
| Cron | Hermes `no_agent=true` | 95% |
| 规则注入 | AGENTS.md（每次会话自动） | 90% |
| 知识库 | Hermes Skills（触发词加载） | 70% |

**核心设计原则：越可靠的层越不依赖 AI 模型。**

---

## 🆕 Innovations / 创新点

1. **Cron Catch-up / Cron 追补机制** — 电脑关机错过 cron？下次会话启动自动补执行。社区其他工具都假设服务常驻。

2. **Evidence Gate / 证据门** — 不只检查代码对不对，而是检查「你有没有真的验证过」。pre-commit hook 会检查 verify-project.sh 是否在 30 分钟内运行过。

3. **Scope Lifecycle State Machine / 范围生命周期状态机** — `.hermes/scope.yaml` 的存在本身就是一个信号：「正在改代码，提交被锁」。文件不存在 = 安全。

4. **no_agent=true Cron / 纯脚本 Cron** — 利用 Hermes 的 `no_agent=true` 模式，cron 任务完全不经过模型，零幻觉。

5. **Three-Layer Knowledge Injection / 三层知识注入** — AGENTS.md（自动）+ Skills（触发）+ Memory（持久），按可靠性分层。

---

## 🤝 Contributing / 贡献

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines. Areas we'd love help with / 贡献指南见 [CONTRIBUTING.md](CONTRIBUTING.md)。欢迎 PR！希望贡献的方向：

- [ ] More danger patterns (kubernetes, terraform, AWS) / 更多危险模式
- [ ] Windows shell (Git Bash) support / Windows 支持
- [ ] Editor/IDE hook integrations / 编辑器/IDE 集成
- [ ] Web dashboard for inspection history / Web 巡检历史面板
- [ ] 中文文档完善

## 🛡️ Security / 安全

Found a vulnerability or a dangerous pattern we missed? See [SECURITY.md](SECURITY.md).
发现漏洞或漏掉的危险模式？请看 [SECURITY.md](SECURITY.md)。

## 💬 Support / 支持

Questions, feedback, or issues? See [SUPPORT.md](SUPPORT.md).
问题、反馈或故障？请看 [SUPPORT.md](SUPPORT.md)。

---

## 📄 License / 许可证

[MIT](LICENSE) © 2026 [木木](https://github.com/mlzl1426)

---

*"Don't trust the agent. Verify."*
*「不要相信代理。验证它。」*
