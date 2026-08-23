# Security Policy / 安全策略

## Reporting a Vulnerability / 报告漏洞

Hermes Guard blocks destructive commands — a bypass is a real security issue.

Hermes Guard 的作用是拦截破坏性命令——如果存在绕过方式，那是一个真实的安全问题。

**Please do NOT open a public issue for security vulnerabilities.**
**请不要为安全漏洞开公开 issue。**

Instead, report privately / 请私下报告：

- **GitHub Security Advisory**: https://github.com/mlzl1426/hermes-guard/security/advisories (preferred / 推荐)
- **Email**: open an issue first with the label `security` if you prefer public discussion, or contact the maintainer via GitHub

Please include / 请包含：

1. The dangerous command pattern that bypasses the guard / 可绕过防护的危险命令模式
2. Environment (bash version, OS, git version) / 运行环境
3. Reproduction steps / 复现步骤
4. Suggested fix (if any) / 建议修复方案（如有）

## What We Cover / 覆盖范围

- Bypasses of `danger-guard.sh` interception patterns / `danger-guard.sh` 拦截模式的绕过
- Bypasses of the pre-commit hook (e.g. symlink/hook removal vectors) / pre-commit hook 的绕过
- Command injection in scope/verify scripts / scope/verify 脚本中的命令注入

## Response / 响应

We aim to acknowledge reports within **7 days** and ship a fix as soon as possible.
我们承诺在 **7 天内**确认报告，并尽快发布修复。

## Responsible Disclosure / 负责任披露

Please give us **90 days** before public disclosure of any confirmed vulnerability.
确认漏洞后请给 **90 天**窗口再公开披露。

## Missing a dangerous pattern? / 发现漏掉的危险模式？

Not every dangerous command can be anticipated. If you find a destructive pattern we miss, please:

- Open a **public issue** (this is a feature request, not a vulnerability) with the pattern, or
- Contribute a check via [CONTRIBUTING.md](CONTRIBUTING.md)

危险模式永远无法穷举。如果你发现我们漏掉的破坏性命令：

- 开**公开 issue**（这属于功能请求而非漏洞），或
- 通过 [CONTRIBUTING.md](CONTRIBUTING.md) 贡献检查规则
