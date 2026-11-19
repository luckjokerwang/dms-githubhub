# QML 开发与依赖规范 (QML Development & Component Integrity Rules)

## 1. 强制依赖导入 (Mandatory Imports Check)
- **布局依赖**：凡是使用了 `RowLayout`、`ColumnLayout`、`GridLayout` 或 `Layout.*` 附加属性的 `.qml` 文件，文件顶部**必须显式包含 `import QtQuick.Layouts`**，严禁遗漏；
- **Quickshell 依赖**：凡是使用了 `Process`、`SplitParser`、`StdioCollector` 等进程处理的文件，必须导入 `import Quickshell.Io`；
- **插件全局变量**：凡是使用了 `PluginGlobalVar` 的文件，**必须导入 `import qs.Widgets`**；
- **插件根组件**：凡是作为插件入口的文件，根节点使用 `PluginComponent`，必须导入 `import qs.Modules.Plugins`。

## 2. DMS 2.0 组件规范
- 在 Dux Shell / DMS 2.0+ 环境下，优先使用现代 `D*` 系列组件（如 `DButton`、`DIcon`、`DTextField` 等），若使用历史组件垫片（`Dank*`），需保证兼容性，无运行时类型错误。

## 3. 防 DMS 自动熔断降级监控 (DMS Plugin Auto-Disable Prevention)
- DMS 的 `PluginService` 在检测到插件 QML 加载抛出未捕获语法或类型异常时，会自动将该插件 Toggle 切换为关闭状态（防止 Shell 崩溃）；
- 每次组件编写完毕后，必须核对语法及 import，确认无致命错误。

---

## 4. QML 文本溢出与尺寸撑开避坑指南 (QML vs HTML Layout Pitfalls)

### ⚠️ QML 与 HTML Flexbox 的本质差异
- **HTML/CSS 行为**：`<div>` 默认 `height: auto`，文本换行（多行）时容器会自动向下撑开，兄弟元素自动后移，绝不发生层叠重叠。
- **QML 行为**：
  1. `Item` / `Rectangle` 默认**不会**因为子元素内容增加而自动扩大 `height`；
  2. 若给卡片写死 `height: 64`，当内部文字从 1 行折行成 2 行或 3 行时，文字会直接超出卡片下边界，而 QML 默认 `clip: false`，导致文字直接盖在下方卡片上；
  3. 在 `ListView` 中，若委托项（Delegate）的 `height` 写死，`ListView` 分配的槽位就只有写死的高度，溢出文字不仅越界还会污染相邻列表项。

### 🛡️ 规避与正确实现规范
1. **容器高度自适应（自撑开）**：
   卡片高度禁止写死绝对像素，必须绑定内部布局的 `implicitHeight`：
   ```qml
   // ✅ 正确做法：由内部 ColumnLayout 真实高度 + 内边距动态决定
   height: Math.max(64, cardLayout.implicitHeight + Theme.spacingS * 2)
   ```
2. **文本行数限制与末尾省略号 (Bounded Lines with Elide)**：
   长标题文字必须同时指定 `wrapMode`、`maximumLineCount` 和 `elide`：
   ```qml
   StyledText {
       Layout.fillWidth: true
       text: modelData.title
       wrapMode: Text.WordWrap
       maximumLineCount: 2               // 限制最多 2 行，防止无限撑大
       elide: Text.ElideRight            // 超出两行后末尾显示 '...'
   }
   ```
3. **卡片防御性裁剪 (`clip: true`)**：
   所有列表卡片、卡片容器均应显式设置 `clip: true`，确保即使发生极端计算异常，内容也绝不溢出到卡片之外污染兄弟组件。
