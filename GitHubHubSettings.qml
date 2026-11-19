import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import qs.Services

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

    Component.onCompleted: {
        const savedUsername = PluginService.loadPluginData(root.pluginId, "username", "")
        const savedInterval = PluginService.loadPluginData(root.pluginId, "refreshInterval", 300)
        const savedNickname = PluginService.loadPluginData(root.pluginId, "showNickname", true)

        if (savedUsername) {
            usernameField.text = savedUsername
            PluginService.setGlobalVar(root.pluginId, "username", savedUsername)
        }

        intervalField.text = savedInterval.toString()
        PluginService.setGlobalVar(root.pluginId, "refreshInterval", savedInterval)

        nicknameToggle.checked = (savedNickname !== false && savedNickname !== "false")
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

                PluginService.setGlobalVar(root.pluginId, "username", usernameField.text.trim())
                PluginService.setGlobalVar(root.pluginId, "refreshInterval", interval)

                ToastService.showSuccess("GitHub Hub 设置已保存")
            }
        }
    }
}
