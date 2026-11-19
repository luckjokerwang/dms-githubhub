import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import qs.Services

PluginSettings {
    id: root
    pluginId: "githubHubLocal"

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

    Component.onCompleted: {
        const savedUsername = PluginService.loadPluginData(root.pluginId, "username", "")
        const savedInterval = PluginService.loadPluginData(root.pluginId, "refreshInterval", 300)
        const savedNickname = PluginService.loadPluginData(root.pluginId, "showNickname", true)
        const savedFollowTheme = PluginService.loadPluginData(root.pluginId, "followThemeColor", false)

        if (savedUsername) {
            usernameField.text = savedUsername
            PluginService.setGlobalVar(root.pluginId, "username", savedUsername)
        }

        intervalField.text = savedInterval.toString()
        PluginService.setGlobalVar(root.pluginId, "refreshInterval", savedInterval)

        nicknameToggle.checked = (savedNickname !== false && savedNickname !== "false")
        followThemeToggle.checked = (savedFollowTheme === true || savedFollowTheme === "true")
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
                        text: "开启显示个人昵称 (如 Wang)；关闭则显示 GitHub 用户名 (如 luckjokerwang)。弹窗内点击名字亦可随时切换。"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }

                DankToggle {
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

                    DankIcon {
                        name: "person"
                        size: Theme.iconSize
                        color: Theme.primary
                    }

                    StyledText {
                        text: "自定义 GitHub 用户名"
                        font.bold: true
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                    }
                }

                DankTextField {
                    id: usernameField
                    width: parent.width
                    placeholderText: "留空则自动使用已登录的 gh 账号 (luckjokerwang)"
                    text: ""
                }

                StyledText {
                    text: "未登录 gh 时，插件将使用此用户名拉取公开热力图"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
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

                    DankIcon {
                        name: "schedule"
                        size: Theme.iconSize
                        color: Theme.primary
                    }

                    StyledText {
                        text: "数据刷新间隔"
                        font.bold: true
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                    }
                }

                DankTextField {
                    id: intervalField
                    width: parent.width
                    placeholderText: "300"
                    text: "300"
                    validator: IntValidator { bottom: 60 }
                }

                StyledText {
                    text: "后台自动拉取更新的间隔时间（秒，最低 60 秒）"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
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

                        DankIcon {
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

                    DankToggle {
                        id: followThemeToggle
                        checked: false
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
                                width: 36
                                height: 20
                                radius: 4
                                color: {
                                    if (followThemeToggle.checked) {
                                        if (index === 0) return Theme.withAlpha(Theme.surfaceText, 0.08)
                                        const steps = [0.28, 0.52, 0.76, 1.0]
                                        return Theme.withAlpha(Theme.primary, steps[index - 1])
                                    } else {
                                        const classic = ["#202329", "#0e4429", "#006d32", "#26a641", "#39d353"]
                                        return classic[index]
                                    }
                                }
                                border.color: Qt.darker(color, 1.2)
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 250 } }
                            }
                        }
                    }
                }
            }
        }

        // Hotkey & Network Verification Guide
        StyledRect {
            width: parent.width
            height: hotkeyCol.implicitHeight + Theme.spacingL * 2
            color: Theme.surfaceContainerHigh
            radius: Theme.cornerRadius

            Column {
                id: hotkeyCol
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                RowLayout {
                    spacing: Theme.spacingS

                    DankIcon {
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
                    text: "• 全局快捷键：Mod + Alt + G（系统任意界面一键刷新并验证 GitHub 连通性）\n• 弹窗快捷键：F5 或 Ctrl + R（打开热力图弹窗时直接刷新）\n• 网络可用性反馈：刷新后右下角弹出 Toast 反馈（连接成功 vs 超时断连）"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                }

                DankButton {
                    width: parent.width
                    text: "立即测试刷新网络验证 (IPC)"
                    iconName: "network_check"
                    onClicked: {
                        Quickshell.execDetached(["dms", "ipc", "call", "githubHub", "refresh"])
                    }
                }
            }
        }

        // Save Button
        DankButton {
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

                PluginService.setGlobalVar(root.pluginId, "username", usernameField.text.trim())
                PluginService.setGlobalVar(root.pluginId, "refreshInterval", interval)
                PluginService.setGlobalVar(root.pluginId, "followThemeColor", followThemeToggle.checked)

                ToastService.showInfo("GitHub Hub 设置已保存")
            }
        }
    }
}
