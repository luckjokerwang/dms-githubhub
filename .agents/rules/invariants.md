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

## 4. GraphQL 单往返投影与颜色分级矩阵铁律 (GraphQL Precise Projection & Matrix Invariant)
- **DO**: 贡献热力图数据拉取必须优先采用 `gh api graphql` 查询 `contributionsCollection`，单次 RTT 提取包含 `totalContributions`、`contributionLevel`（`NONE` 到 `FOURTH_QUARTILE`）以及精细计数的强类型日历矩阵。
- **DO**: 脚本层（`fetch-contributions.sh`）必须为每个数据点计算并规范化 `level`（0-4），使 QML 热力图方块能直接跟随 Material You 主题色阶渲染。
- **DON'T**: 严禁回退到容易被 CDN 边缘缓存且极易因 DOM 改版破损的 HTML/SVG 网页抓取方案。

## 5. 桌面 IPC 快捷键总线与主动探活铁律 (Desktop IPC & Shortcut Bus Invariant)
- **DO**: 必须在插件根对象中注册全局快捷键（`Mod+Alt+G`）以及弹窗内键盘事件（`F5` / `Ctrl+R`），并暴露标准 IPC 接口 `dms ipc call githubHubLocal refresh/toggle/open/close`。
- **DO**: 收到主动刷新信令时，必须触发网络连通性探测（包含 6 秒硬超时），在 UI 状态栏显式呈现绿/琥珀/红状态灯，支撑网络故障排查。
- **DON'T**: 严禁仅依赖固定时长的被动定时器轮询，避免在网络代理跃迁时无法主动即时同步。

## 6. 多 Agent 物理并发 Git 锁排他与单点原子落地铁律 (Multi-Agent Git Worktree Mutex Invariant)
- **DO**: 在多 Agent 协同开发同一插件时，严禁并发执行 `git add` 或 `git commit`。必须由主导发布流程的协调 Agent 统一在特性稳定后收敛原子提交（Atomic Commit），防止 `.git/index.lock` 争用崩溃。
- **DON'T**: 严禁在未验证本地全部异步脚本退出码（Exit Code）与 QML 组件兼容性的前提下直接推送远端分支。
