# Git 提交与版本规范 (Git & Versioning Rules)

## 1. 严格禁止主动/自动执行 Git 提交
- **严禁擅自提交**：在任何情况下，绝不要在没有用户明确要求的情况下自动执行 `git commit`、`git push` 或创建 tag；
- **纯本地工作区开发**：所有代码修改、功能迭代与 Bug 修复仅在本地工作区进行，并通过清理缓存与重启 DMS（`rm -rf ~/.cache/DankMaterialShell ~/.cache/quickshell && dms restart`）让用户测试验证。

## 2. 最小原子化提交与中文提交规范 (Atomic Commits & Chinese Commit Messages)
- 每次 Git 提交必须且只能包含一个独立、完整的逻辑变更（一个 TODO 或一个 Bug 修复），确保提交粒度最小且原子化；
- 严禁将多个不相关的问题修复或功能混杂在同一个 Git 提交中；
- **强制使用中文提交信息**：Commit Message 必须采用 **`type(scope): 简洁准确的中文描述 (vx.y.z)`** 规范格式（例如 `feat(ui): 融合 HeaderCard 头像卡片与详情卡片 (v0.1.0)`），严禁使用纯英文；
- **Git Tag 注释必须同步使用中文描述**。

## 3. 语义化版本号标准 (SemVer x.y.z)
- 每次用户确认并指示执行 Git 提交时，严格按照 **`x.y.z`** 语义化版本规范递增：
  - **`patch` (z + 1)**：Bug 修复、UI 微调、细节优化；
  - **`minor` (y + 1, z = 0)**：新增功能模块、支持新特性；
  - **`major` (x + 1, y = 0, z = 0)**：重大重构或破坏性变更。

## 4. 全配置文件版本号强一致同步
- 提交前必须同步更新项目中所有包含版本号的配置文件（`plugin.json`、`README.md` 等）。
