import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Common
import qs.Widgets
import qs.Services
import qs.DCommon.Widgets

StyledRect {
    id: root

    property string avatarUrl: ""
    property string cachedAvatarPath: ""
    property string username: ""
    property string displayName: ""
    property string statusText: ""
    property bool isLoading: false
    property bool isError: false
    property string lastSyncTime: ""
    property bool showNickname: true

    signal refreshClicked()
    signal openProfileClicked()

    Component.onCompleted: {
        const savedShowNickname = PluginService.loadPluginData("githubHub", "showNickname", true)
        root.showNickname = (savedShowNickname !== false && savedShowNickname !== "false")
    }

    width: parent.width
    implicitHeight: cardRow.implicitHeight + Theme.spacingM * 2
    height: implicitHeight
    radius: Theme.cornerRadius
    // Softer, deeper background color
    color: Theme.withAlpha(Theme.surfaceContainerLow, 0.9)
    border.width: 0

    RowLayout {
        id: cardRow
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        // Avatar container
        Rectangle {
            id: avatarWrapper
            Layout.preferredWidth: Theme.iconSizeLarge + Theme.spacingS
            Layout.preferredHeight: Layout.preferredWidth
            radius: Layout.preferredWidth / 2
            color: Theme.surfaceContainerLowest
            border.color: profileHover.containsMouse ? Theme.primary : Theme.withAlpha(Theme.outlineVariant, 0.25)
            border.width: 1
            clip: true

            Behavior on border.color { ColorAnimation { duration: 150 } }

            ClippingRectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"

                CachingImage {
                    id: avatarImg
                    anchors.fill: parent
                    imagePath: root.avatarUrl ? root.avatarUrl : (root.cachedAvatarPath ? ("file://" + root.cachedAvatarPath) : "")
                    visible: (root.avatarUrl !== "" || root.cachedAvatarPath !== "")
                }
            }

            // Fallback: Code icon that automatically adapts to dark/light theme
            DIcon {
                anchors.centerIn: parent
                size: Theme.iconSize
                name: "code"
                color: Theme.surfaceVariantText
                visible: !avatarImg.visible
            }

            MouseArea {
                id: profileHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.username ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (root.username) {
                        root.openProfileClicked()
                    }
                }
            }
        }

        // User info column (clickable to toggle GitHub username / nickname)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            // Clickable name container covering the exact label + icon area
            Item {
                Layout.fillWidth: true
                implicitHeight: nameRow.implicitHeight

                Row {
                    id: nameRow
                    spacing: Theme.spacingS
                    anchors.verticalCenter: parent.verticalCenter

                    StyledText {
                        id: nameLabel
                        text: {
                            if (!root.username && !root.displayName) {
                                return I18n.tr("No account configured")
                            }
                            return root.showNickname ? (root.displayName || root.username) : root.username
                        }
                        font.weight: Font.DemiBold
                        font.pixelSize: Theme.fontSizeLarge
                        color: (nameMouseArea.containsMouse && root.username) ? Theme.primary : Theme.surfaceText
                        elide: Text.ElideRight

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    DIcon {
                        visible: root.username !== ""
                        name: "swap_horiz"
                        size: Theme.iconSizeSmall
                        color: nameMouseArea.containsMouse ? Theme.primary : Theme.surfaceVariantText
                        opacity: nameMouseArea.containsMouse ? 1.0 : 0.5
                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }

                MouseArea {
                    id: nameMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: root.username ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (!root.username) {
                            return
                        }
                        root.showNickname = !root.showNickname
                        PluginService.savePluginData("githubHub", "showNickname", root.showNickname)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingS

                // Network status indicator dot
                Rectangle {
                    width: 7
                    height: 7
                    radius: 3.5
                    color: {
                        if (root.isError) return Theme.error
                        if (root.isLoading) return Theme.warning
                        if (!root.username) return Theme.surfaceVariantText
                        return Theme.primary
                    }
                    border.width: 1
                    border.color: Qt.darker(color, 1.2)
                    Layout.alignment: Qt.AlignVCenter

                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        if (!root.username && !root.isLoading && !root.isError) {
                            return I18n.tr("Set username or log in via gh CLI")
                        }
                        return root.statusText
                    }
                    font.pixelSize: Theme.fontSizeSmall
                    color: root.isError ? Theme.error : (root.isLoading ? Theme.primary : Theme.surfaceVariantText)
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                    maximumLineCount: 1
                }
            }
        }

        // Action button (Refresh button with tooltip)
        Item {
            id: refreshBtn
            Layout.alignment: Qt.AlignVCenter
            width: Theme.iconSizeLarge + Theme.spacingXS
            height: width
            scale: refreshArea.pressed ? 0.92 : (refreshArea.containsMouse ? 1.06 : 1.0)
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

            Rectangle {
                anchors.fill: parent
                radius: Theme.cornerRadius
                color: refreshArea.pressed
                       ? Theme.withAlpha(Theme.primary, 0.20)
                       : (refreshArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.12) : Theme.withAlpha(Theme.surfaceContainerHighest, 0.4))
                border.width: 1
                border.color: refreshArea.pressed
                             ? Theme.withAlpha(Theme.primary, 0.6)
                             : (refreshArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.35) : Theme.withAlpha(Theme.outlineVariant, 0.2))
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
            }

            DIcon {
                id: refreshIcon
                name: "refresh"
                size: Theme.iconSizeMedium
                color: Theme.primary
                anchors.centerIn: parent

                NumberAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                    running: root.isLoading
                }
            }

            MouseArea {
                id: refreshArea
                anchors.fill: parent
                hoverEnabled: !root.isLoading
                enabled: !root.isLoading
                cursorShape: root.isLoading ? Qt.ArrowCursor : Qt.PointingHandCursor
                onClicked: root.refreshClicked()
            }

            DTooltipHost {
                text: I18n.tr("Refresh data (F5 / Ctrl+R)")
                target: refreshBtn
                hoverArea: refreshArea
            }
        }
    }
}
