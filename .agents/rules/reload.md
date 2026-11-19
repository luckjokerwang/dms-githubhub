# DMS 缓存清理与重启规范

这个 DMS 项目不是热重载，每次修改完成后必须清除缓存并重启才能生效：

```bash
rm -rf ~/.cache/DankMaterialShell ~/.cache/quickshell && dms restart
```

在测试单个插件更新时，亦可通过 IPC 触发重载：
```bash
dms ipc call plugins reload githubHubLocal
```
但若修改了底层 Store、类型定义或插件元数据，必须执行全量冷重启。
