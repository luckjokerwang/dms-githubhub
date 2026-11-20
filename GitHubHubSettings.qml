import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Widgets
import qs.Services
import qs.Modules.Plugins
import qs.DCommon.Widgets

PluginSettings {
    id: root
    pluginId: "githubHub"

    Component.onCompleted: {
        const savedUsername = PluginService.loadPluginData(root.pluginId, "username", "")
        const savedInterval = PluginService.loadPluginData(root.pluginId, "refreshInterval", 300)
        const savedNickname = PluginService.loadPluginData(root.pluginId, "showNickname", true)
        const savedNotify = PluginService.loadPluginData(root.pluginId, "showNotifications", true)

        if (savedUsername) {
            usernameField.text = savedUsername
        }

        intervalField.text = savedInterval.toString()

        nicknameToggle.checked = (savedNickname !== false && savedNickname !== "false")
        notifyToggle.checked = (savedNotify !== false && savedNotify !== "false")

        const savedThemeColor = PluginService.loadPluginData(root.pluginId, "useThemeColor", false)
        themeColorToggle.checked = (savedThemeColor === true || savedThemeColor === "true")
    }

    Column {
        width: parent.width
        spacing: Theme.spacingL

        // Header
        Column {
            width: parent.width
            spacing: Theme.spacingXS

            StyledText {
                text: I18n.tr("GitHub Hub Settings")
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Bold
                color: Theme.surfaceText
            }

            StyledText {
                text: I18n.tr("Personal GitHub center: contribution heatmap and PR/Issue tracker")
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
                        text: I18n.tr("Prefer GitHub Nickname")
                        font.bold: true
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                    }

                    StyledText {
                        text: I18n.tr("Display profile nickname instead of login handle when available.")
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
                        text: I18n.tr("GitHub Username")
                        font.bold: true
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                    }
                }

                StyledText {
                    width: parent.width
                    text: I18n.tr("Automatically detects logged-in gh CLI account. Enter a username here to override or view public contributions.")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                }

                DTextField {
                    id: usernameField
                    width: parent.width
                    placeholderText: I18n.tr("Leave empty to use logged-in gh account")
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
                        name: "schedule"
                        size: Theme.iconSize
                        color: Theme.primary
                    }

                    StyledText {
                        text: I18n.tr("Refresh Interval (seconds)")
                        font.bold: true
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                    }
                }

                StyledText {
                    width: parent.width
                    text: I18n.tr("Automatic background sync interval (minimum 60 seconds).")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                }

                DTextField {
                    id: intervalField
                    width: parent.width
                    text: "300"
                }
            }
        }

        // Notifications Toggle
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

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingXXS

                    StyledText {
                        text: I18n.tr("Desktop Notifications")
                        font.bold: true
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                    }

                    StyledText {
                        text: I18n.tr("Show desktop notification on manual refresh to confirm connectivity.")
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

        // Theme Color Toggle
        StyledRect {
            width: parent.width
            height: themeColorRow.implicitHeight + Theme.spacingL * 2
            color: Theme.surfaceContainerHigh
            radius: Theme.cornerRadius

            RowLayout {
                id: themeColorRow
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingXXS

                    StyledText {
                        text: I18n.tr("Match Desktop Theme Color")
                        font.bold: true
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                    }

                    StyledText {
                        text: I18n.tr("Adapt heatmap colors to the system theme instead of classic GitHub green.")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }

                DToggle {
                    id: themeColorToggle
                    checked: false
                    onClicked: checked = !checked
                }
            }
        }

        // Shortcut & Diagnostic Guidance
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
                        text: I18n.tr("Shortcuts & Integration")
                        font.bold: true
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                    }
                }

                StyledText {
                    width: parent.width
                    text: I18n.tr("• Popout shortcuts: F5 or Ctrl + R to refresh\n• IPC CLI command: dms ipc call githubHub refresh\n• Popout open/close: dms ipc call githubHub toggle")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                }

                DButton {
                    width: parent.width
                    text: I18n.tr("Test Refresh via IPC")
                    iconName: "network_check"
                    onClicked: {
                        Quickshell.execDetached(["dms", "ipc", "call", "githubHub", "refresh"])
                    }
                }
            }
        }

        // Save Button
        DButton {
            width: parent.width
            text: I18n.tr("Save Settings")
            iconName: "check"

            onClicked: {
                var interval = parseInt(intervalField.text) || 300
                if (interval < 60) interval = 60

                PluginService.savePluginData(root.pluginId, "username", usernameField.text.trim())
                PluginService.savePluginData(root.pluginId, "refreshInterval", interval)
                PluginService.savePluginData(root.pluginId, "showNickname", nicknameToggle.checked)
                PluginService.savePluginData(root.pluginId, "showNotifications", notifyToggle.checked)
                PluginService.savePluginData(root.pluginId, "useThemeColor", themeColorToggle.checked)

                ToastService.showInfo(I18n.tr("GitHub Hub settings saved"))
            }
        }
    }
}
