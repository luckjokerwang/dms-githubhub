import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import qs.Services
import qs.DCommon.Widgets

PluginSettings {
    id: root
    pluginId: "githubHub"

    PluginGlobalVar {
        id: usernameSetting
        varName: "username"
        defaultValue: ""
    }

    PluginGlobalVar {
        id: refreshIntervalSetting
        varName: "refreshInterval"
        defaultValue: 300
    }

    PluginGlobalVar {
        id: followThemeColorSetting
        varName: "followThemeColor"
        defaultValue: false
    }

    PluginGlobalVar {
        id: showNotificationsSetting
        varName: "showNotifications"
        defaultValue: true
    }

    Component.onCompleted: {
        const savedUsername = PluginService.loadPluginData(root.pluginId, "username", "")
        const savedInterval = PluginService.loadPluginData(root.pluginId, "refreshInterval", 300)
        const savedNickname = PluginService.loadPluginData(root.pluginId, "showNickname", true)
        const savedFollowTheme = PluginService.loadPluginData(root.pluginId, "followThemeColor", true)
        const savedNotify = PluginService.loadPluginData(root.pluginId, "showNotifications", true)

        if (savedUsername) {
            usernameField.text = savedUsername
            PluginService.setGlobalVar(root.pluginId, "username", savedUsername)
        }

        intervalField.text = savedInterval.toString()
        PluginService.setGlobalVar(root.pluginId, "refreshInterval", savedInterval)

        nicknameToggle.checked = (savedNickname !== false && savedNickname !== "false")
        followThemeToggle.checked = (savedFollowTheme !== false && savedFollowTheme !== "false")
        notifyToggle.checked = (savedNotify !== false && savedNotify !== "false")
    }

    Column {
        width: parent.width
        spacing: Theme.spacingL

        // Header
        Column {
            width: parent.width
            spacing: Theme.spacingXS

            StyledText {
                text: "GitHub Hub 设置"
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Bold
                color: Theme.surfaceText
            }

            StyledText {
                text: "个人 GitHub 综合中心：热力图贡献统计与 PR/Issue 追踪"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
            }
        }

        // Display Name vs Username Toggle
        StyledRect {
            width: parent.width
            height: nameRow.implicitHeight + Theme.spacingL * 2
            color: Theme.surfaceContainerHigh
            radius: Theme.cornerRadius

            RowLayout {
                id: nameRow
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingXXS

                    StyledText {
                        text: "优先显示 GitHub 昵称"
                        font.bold: true
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                    }

                    StyledText {
                        text: "开启显示 GitHub 个人资料昵称；关闭则显示 GitHub 用户名。弹窗内点击名字亦可随时切换。"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }

                DToggle {
                    id: nicknameToggle
                    checked: true
                    onClicked: checked = !checked
                }
            }
        }

        // GitHub Username Override
        StyledRect {
            width: parent.width
            height: usernameCol.implicitHeight + Theme.spacingL * 2
            color: Theme.surfaceContainerHigh
            radius: Theme.cornerRadius

            Column {
                id: usernameCol
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                RowLayout {
                    spacing: Theme.spacingS

                    DIcon {
                        name: "person"
                        size: Theme.iconSize
                        color: Theme.primary
                    }

                    StyledText {
                        text: "GitHub 用户名"
                        font.bold: true
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                    }
                }

                StyledText {
                    width: parent.width
                    text: "默认会自动检测系统中已登录的 GitHub CLI (gh) 账号。若未登录或需要查询任意指定用户的公开热力图，可在此处手动输入用户名。"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                }

                DTextField {
                    id: usernameField
                    width: parent.width
                    placeholderText: "留空则自动使用已登录的 gh 账号"
                }
            }
        }

        // Refresh Interval
        StyledRect {
            width: parent.width
            height: intervalCol.implicitHeight + Theme.spacingL * 2
            color: Theme.surfaceContainerHigh
            radius: Theme.cornerRadius

            Column {
                id: intervalCol
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                RowLayout {
                    spacing: Theme.spacingS

                    DIcon {
                        name: "timer"
                        size: Theme.iconSize
                        color: Theme.primary
                    }

                    StyledText {
                        text: "数据刷新间隔 (秒)"
                        font.bold: true
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                    }
                }

                StyledText {
                    width: parent.width
                    text: "建议保持在 300 秒（5 分钟）以上，避免高频请求触发 GitHub API 速率限制（最低不小于 60 秒）。"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                }

                DTextField {
                    id: intervalField
                    width: parent.width
                    placeholderText: "300"
                }
            }
        }

        // Theme Color Following Toggle & Live Preview
        StyledRect {
            width: parent.width
            height: themeColorCol.implicitHeight + Theme.spacingL * 2
            color: Theme.surfaceContainerHigh
            radius: Theme.cornerRadius

            Column {
                id: themeColorCol
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                RowLayout {
                    width: parent.width
                    spacing: Theme.spacingM

                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: followThemeToggle.checked ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Theme.withAlpha(Theme.surfaceContainerHighest, 0.5)
                        Layout.alignment: Qt.AlignVCenter
                        Behavior on color { ColorAnimation { duration: 150 } }

                        DIcon {
                            name: "palette"
                            size: 20
                            color: followThemeToggle.checked ? Theme.primary : Theme.surfaceVariantText
                            anchors.centerIn: parent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingXXS

                        StyledText {
                            text: "跟随 DMS 系统主题色"
                            font.bold: true
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                        }

                        StyledText {
                            text: "开启后热力图色阶跟随系统强调色（Material You 当前主色）实时变动；关闭则保持经典 GitHub 纯正绿阶。"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }
                    }

                    DToggle {
                        id: followThemeToggle
                        checked: true
                        onClicked: checked = !checked
                    }
                }

                // Palette preview strip
                Column {
                    width: parent.width
                    spacing: 6

                    StyledText {
                        text: "当前色彩风格预览："
                        font.pixelSize: Theme.fontSizeSmall - 1
                        color: Theme.surfaceVariantText
                    }

                    Row {
                        spacing: 6
                        anchors.horizontalCenter: parent.horizontalCenter

                        Repeater {
                            model: 5
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 4
                                color: {
                                    if (modelData === 0) return Theme.surfaceContainerHighest
                                    if (followThemeToggle.checked) {
                                        const steps = [0.30, 0.55, 0.80, 1.0]
                                        return Theme.withAlpha(Theme.primary, steps[modelData - 1])
                                    } else {
                                        const classic = ["", "#0e4429", "#006d32", "#26a641", "#39d353"]
                                        return classic[modelData]
                                    }
                                }
                                border.color: Qt.darker(color, 1.2)
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                    }
                }
            }
        }

        // Shortcut & Network Diagnostic Guidance
        StyledRect {
            width: parent.width
            height: shortcutCol.implicitHeight + Theme.spacingL * 2
            color: Theme.surfaceContainerHigh
            radius: Theme.cornerRadius

            Column {
                id: shortcutCol
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                RowLayout {
                    spacing: Theme.spacingS

                    DIcon {
                        name: "keyboard"
                        size: Theme.iconSize
                        color: Theme.primary
                    }

                    StyledText {
                        text: "快捷键与网络连通性验证"
                        font.bold: true
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                    }
                }

                StyledText {
                    width: parent.width
                    text: "• 弹窗快捷键：F5 或 Ctrl + R（打开热力图弹窗时直接刷新）\n• IPC 命令行刷新：dms ipc call githubHub refresh（可自行绑定到窗口管理器快捷键）\n• 网络可用性反馈：刷新后在屏幕右上角弹出系统桌面通知（支持通知中心归档与随时回看）"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                }

                DButton {
                    width: parent.width
                    text: "立即测试刷新网络验证 (IPC)"
                    iconName: "network_check"
                    onClicked: {
                        Quickshell.execDetached(["dms", "ipc", "call", "githubHub", "refresh"])
                    }
                }
            }
        }

        // Desktop Notification Toggle
        StyledRect {
            width: parent.width
            height: notifyRow.implicitHeight + Theme.spacingL * 2
            color: Theme.surfaceContainerHigh
            radius: Theme.cornerRadius

            RowLayout {
                id: notifyRow
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: notifyToggle.checked ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Theme.withAlpha(Theme.surfaceContainerHighest, 0.5)
                    Layout.alignment: Qt.AlignVCenter
                    Behavior on color { ColorAnimation { duration: 150 } }

                    DIcon {
                        name: "notifications"
                        size: 20
                        color: notifyToggle.checked ? Theme.primary : Theme.surfaceVariantText
                        anchors.centerIn: parent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingXXS

                    StyledText {
                        text: "发送系统桌面通知"
                        font.bold: true
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                    }

                    StyledText {
                        text: "数据刷新与快捷键验证时，在屏幕右上角弹出系统通知卡片（头像图标 + 自动归档至通知中心）。"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }

                DToggle {
                    id: notifyToggle
                    checked: true
                    onClicked: checked = !checked
                }
            }
        }

        // Save Button
        DButton {
            width: parent.width
            text: "保存配置"
            iconName: "check"

            onClicked: {
                var interval = parseInt(intervalField.text) || 300
                if (interval < 60) interval = 60

                PluginService.savePluginData(root.pluginId, "username", usernameField.text.trim())
                PluginService.savePluginData(root.pluginId, "refreshInterval", interval)
                PluginService.savePluginData(root.pluginId, "showNickname", nicknameToggle.checked)
                PluginService.savePluginData(root.pluginId, "followThemeColor", followThemeToggle.checked)
                PluginService.savePluginData(root.pluginId, "showNotifications", notifyToggle.checked)

                PluginService.setGlobalVar(root.pluginId, "username", usernameField.text.trim())
                PluginService.setGlobalVar(root.pluginId, "refreshInterval", interval)
                PluginService.setGlobalVar(root.pluginId, "followThemeColor", followThemeToggle.checked)
                PluginService.setGlobalVar(root.pluginId, "showNotifications", notifyToggle.checked)

                ToastService.showInfo("GitHub Hub 设置已保存")
            }
        }
    }
}
