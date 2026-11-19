# GitHub CLI 接入与平滑降级铁律 (GH Integration Invariants)

## 1. 认证安全与零配置铁律
- 插件直接复用系统终端环境的 `/usr/bin/gh` 认证凭据，严禁要求用户在界面明文输入 GitHub Token 或密码；
- 脚本执行时必须设置合理超时（`timeout 5s`），防止网络波动导致后台僵死进程积聚。

## 2. 渐进式平滑降级铁律 (Graceful Degradation)
- **热力图独立性**：热力图拉取不依赖 `gh` 认证，即使未登录 `gh` 或 `gh` 命令不存在，热力图网格和顶栏 7 天竖条胶囊依然必须 100% 正常显示；
- **头像降级链路**：优先使用 `gh api user` 获取的高清头像 URL；若未登录则降级为公开地址 `https://github.com/<username>.png`；若断网或加载失败则回退至本地 GitHub SVG 图标；
- **权限面板容灾**：当未登录 `gh` 时，PR/Issue/通知等需鉴权的数据 Tab 必须展示精致友好的引导卡片（提示在终端执行 `gh auth login` 即可解锁），严禁抛出 QML 红色异常或导致面板空白。
