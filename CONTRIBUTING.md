# Contributing / 贡献指南

Thanks for considering contributing to Hermes Guard! / 感谢你考虑为 Hermes Guard 贡献代码！

## Development Setup / 开发环境

```bash
git clone https://github.com/mlzl1426/hermes-guard.git
cd hermes-guard
```

Requirements: `bash 4+`, `git`, standard POSIX tools. No build step, no dependencies to install.
环境要求：`bash 4+`、`git`、标准 POSIX 工具。无构建步骤、无依赖安装。

## How to Contribute / 如何贡献

1. **Open an issue first** for non-trivial changes — we can align on the approach before you write code.
   非平凡改动请先开 issue——先对齐方案再写代码。
2. Fork the repo, create a feature branch (`feat/...` or `fix/...`).
   Fork 仓库并创建功能分支（`feat/...` 或 `fix/...`）。
3. Make your change. Keep scripts **pure POSIX bash** — no external dependencies.
   做改动。脚本保持**纯 POSIX bash**——不引入外部依赖。
4. Run the checks below.
   运行下面的检查。
5. Open a pull request against `main`.
   向 `main` 发起 pull request。

## Checks / 检查

```bash
# 1. Syntax check / 语法检查
bash -n scripts/*.sh install.sh tests/*.sh

# 2. ShellCheck (if installed) / 静态检查（如已安装）
shellcheck scripts/*.sh install.sh tests/*.sh

# 3. Test suite / 测试套件
bash tests/run_tests.sh
```

All tests must pass before opening a PR. CI runs the same checks on GitHub.
开 PR 前所有测试必须通过。CI 会在 GitHub 上运行同样的检查。

## Coding Conventions / 编码规范

- `set -uo pipefail` (or `set -euo pipefail`) at the top of every script / 每个脚本开头设置
- Every script starts with a header comment block: purpose, usage, "Part of Hermes Guard" line
  每个脚本开头有头注释块：用途、用法、"Part of Hermes Guard" 行
- No external dependencies beyond POSIX tools + git / 除 POSIX 工具 + git 外无外部依赖
- New checks should be **opt-in via environment variables** (see `verify-project.sh` CONFIG section)
  新检查应通过**环境变量可选启用**（见 `verify-project.sh` 的 CONFIG 段）
- Document new behavior in README (bilingual) and CHANGELOG / 新行为同步更新 README（双语）和 CHANGELOG

## License / 许可

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
贡献即表示同意你的贡献遵循 [MIT License](LICENSE)。
