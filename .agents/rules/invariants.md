# GitHub Hub Local Invariants & Architecture Rules

> **生效范围**：`/home/wzy/.config/DankMaterialShell/plugins/githubHubLocal`

## 1. 认证安全与零配置铁律 (Zero-Secret Model)
- **DO**: 直接复用系统环境已认证的 `/usr/bin/gh`，由 OS Secret Service / Keyring 管理 OAuth 凭据。
- **DON'T**: 严禁在插件设置界面中明文输入或在本地 JSON/配置文件中持久化 GitHub PAT 或用户密码。

## 2. 异步非阻塞与内核超时守护 (Non-Blocking I/O & Timeout Guard)
- **DO**: 所有系统命令派生（`QProcess` / POSIX pipe）必须以异步方式执行，且必须外挂 `timeout 5s` 内核守护，防止半开连接或网络挂起阻塞桌面渲染主事件循环（VSync 60/120 FPS）。
- **DON'T**: 严禁在 QML 渲染主线程中执行任何同步阻塞式 I/O、网络请求或未经超时的 Shell 脚本。

## 3. 四阶弹性平滑降级铁律 (Graceful Degradation Invariant)
- **DO**: 严格按照【特权私有态 (Level 4) -> 公开免密态 (Level 3) -> 本地磁盘缓存态 (Level 2) -> 极简本地矢量骨架态 (Level 1)】进行容灾分层。
- **DO**: 核心热力图与顶栏 7 天竖条胶囊必须与 `gh` 认证逻辑物理隔离，未登录时依然 100% 正常渲染；头像按 `gh api user` -> `github.com/<user>.png` -> 本地 SVG 三级平滑降级；权限 Tab 未登录时显示优雅的终端登录引导卡片。
- **DON'T**: 严禁在未登录、离线或遭遇 Rate Limit（403）时抛出未捕获的 QML 异常或造成面板空白白屏。
