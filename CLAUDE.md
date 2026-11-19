# GitHub Hub (`githubHubLocal`) 项目开发指南

> 本项目是专为 Dux Shell (DMS 2.0+) 打造的个人 GitHub 信息中心插件。
> 融合了原版 `githubHeatmap` 的经典 7 天竖条胶囊与网格美学，以及 Plus 版的用户头像与详情展示，同时深度整合系统已登录的 `gh` CLI。

---

## 常用命令与工作流

### 1. 清理缓存与重启 DMS
```bash
rm -rf ~/.cache/DankMaterialShell ~/.cache/quickshell && dms restart
```

### 2. 插件热重载 (开发调试)
```bash
dms ipc call plugins reload githubHubLocal
```

### 3. 检查 GitHub CLI 登录态
```bash
gh auth status
gh api user --jq '.login,.avatar_url'
```

---

## 核心架构原则

1. **顶栏胶囊**：保持原版 7 天竖长条矩形（`width: 8, height: 16`），禁止改为方块或桌面组件。
2. **零额外配置**：自动识别 `gh` CLI 登录态，未登录时无缝平滑降级为纯净热力图模式。
3. **安全容错**：所有数据拉取脚本带有 `timeout` 和空数据容错，避免阻塞 UI 线程。
4. **规范遵循**：严格遵守 `.agents/rules/` 下的 Git 提交规范与任务执行工作流。
