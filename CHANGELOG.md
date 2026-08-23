# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned / 计划中

- More danger patterns (Kubernetes / Terraform / AWS)
- Windows shell (Git Bash) support
- Editor/IDE hook integrations
- Plugin system for custom rules

## [0.1.1] - 2026-08-23

### Fixed / 修复

- `verify-project.sh --json` now emits **pure JSON** (header and summary separated out)
- `grep -c` fallback (`|| echo 0`) double-counted "0" when no match — affected
  `verify-project.sh` modified-file count and `pre-commit-check.sh` staged count
- `verify-project.sh --quick` FAIL state reflected in exit code (regression hardening)

### Changed / 变更

- README: "model-proof" → **"model-independent"**; removed absolute claims
  (physically cannot skip / cannot bypass); added **Security Boundary** section
- Reliability percentages (95%/90%/70%) → **Reliability Boundaries** descriptions
- "What Makes This Different" → **Design Trade-offs** (non-confrontational)
- SECURITY.md: removed contradictory public-issue advice; single private reporting path
- CI: markdownlint is now **blocking** (was non-blocking), with a config that
  accounts for bilingual line lengths
- Test suite split into per-script files (`test-*.sh`) with bypass tests —
  15 → **20 tests**, all passing

## [0.1.0] - 2026-08-23

### Added / 新增

- **Core guard scripts** (`scripts/`):
  - `danger-guard.sh` — intercepts destructive commands (`rm -rf`, `git push -f`, `git checkout --`, `git reset --hard`, `docker rm -f`) with math challenge-response
  - `scope-check.sh` — declare → verify scope lifecycle state machine
  - `pre-commit-check.sh` — git pre-commit gate: evidence check, shared-module impact, scope enforcement, SQL anti-patterns
  - `verify-project.sh` — 9 built-in project health checks (Git, root hygiene, API, Docker, DB, critical files, remote sync, disk, pycache), with `--quick` / `--json` modes
  - `daily-check.sh` — silent daily inspection, alerts only on problems
- **Installer** (`install.sh`) — one-command setup: copies scripts, installs pre-commit hook, generates `AGENTS.md` from template, installs Hermes skills
- **Hermes skills** (`skills/`): `guard` (three-step enforcement), `session-startup` (8-step session checklist + cron catch-up)
- **`AGENTS.md` template** — auto-injected session rules (5 core rules + forbidden actions + end-of-day ritual)
- **Documentation**: bilingual (EN/中文) README, architecture doc
- **Engineering**: MIT LICENSE, CHANGELOG, CI (ShellCheck + tests), shell test suite, CONTRIBUTING / SECURITY / SUPPORT

### Fixed / 修复

- `verify-project.sh --quick` now records the evidence-gate timestamp (previously only full runs did, so the gate could never be satisfied by a quick check)

### Changed / 变更

- Documentation aligned with implementation: `verify-project.sh` described as **9 built-in checks** (was incorrectly advertised as 17)

[0.1.1]: https://github.com/mlzl1426/hermes-guard/releases/tag/v0.1.1
[0.1.0]: https://github.com/mlzl1426/hermes-guard/releases/tag/v0.1.0
