import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Common
import qs.Widgets
import qs.Services

StyledRect {
    id: root

    property string avatarUrl: ""
    property string localAvatarPath: ""
    property string username: ""
    property string displayName: ""
    property string statusText: ""
    property bool isLoading: false
    property bool showNickname: true

    signal refreshClicked()
    signal openProfileClicked()

    Component.onCompleted: {
        const savedShowNickname = PluginService.loadPluginData("githubHub", "showNickname", true)
        root.showNickname = (savedShowNickname !== false && savedShowNickname !== "false")
    }

    width: parent.width
    height: 72
    radius: Theme.cornerRadius
    // Softer, deeper background color
    color: Theme.withAlpha(Theme.surfaceContainerLow, 0.9)
    border.width: 0

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        // Avatar container
        Rectangle {
            id: avatarWrapper
            Layout.preferredWidth: 44
            Layout.preferredHeight: 44
            radius: 22
            color: Theme.surfaceContainerLowest
            border.color: profileHover.containsMouse ? Theme.primary : Theme.withAlpha(Theme.outlineVariant, 0.25)
            border.width: 1
            clip: true

            Behavior on border.color { ColorAnimation { duration: 150 } }

            ClippingRectangle {
                anchors.fill: parent
                radius: 22
                color: "transparent"

                Image {
                    id: avatarImg
                    anchors.fill: parent
                    source: root.localAvatarPath ? root.localAvatarPath : root.avatarUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: status === Image.Ready && (root.localAvatarPath !== "" || root.avatarUrl !== "")
                }
            }

            // Fallback: Official GitHub Octocat icon
            Image {
                anchors.centerIn: parent
                width: 24
                height: 24
                source: Qt.resolvedUrl("../assets/github.svg")
                fillMode: Image.PreserveAspectFit
                visible: !avatarImg.visible
            }

            MouseArea {
                id: profileHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openProfileClicked()
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
                    spacing: 6
                    anchors.verticalCenter: parent.verticalCenter

                    StyledText {
                        id: nameLabel
                        text: root.showNickname ? (root.displayName || root.username || "GitHub User") : (root.username || "GitHub User")
                        font.bold: true
                        font.pixelSize: Theme.fontSizeMedium + 1
                        color: nameMouseArea.containsMouse ? Theme.primary : Theme.surfaceText
                        elide: Text.ElideRight

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    DankIcon {
                        name: "swap_horiz"
                        size: 14
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
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.showNickname = !root.showNickname
                        PluginService.savePluginData("githubHub", "showNickname", root.showNickname)
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.statusText
                font.pixelSize: Theme.fontSizeSmall - 1
                color: root.isLoading ? Theme.primary : Theme.surfaceVariantText
                elide: Text.ElideRight
            }
        }

        // Action buttons row (Plus version refined rounded square design)
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: Theme.spacingS

            // Refresh button (Rounded square, clean crisp SVG icon style)
            Item {
                width: 38
                height: 38
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

                DankIcon {
                    id: refreshIcon
                    name: "refresh"
                    size: 20
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
            }

            // Open in browser button (matching rounded square design)
            Item {
                width: 38
                height: 38
                scale: openArea.pressed ? 0.92 : (openArea.containsMouse ? 1.06 : 1.0)
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.cornerRadius
                    color: openArea.pressed
                           ? Theme.withAlpha(Theme.primary, 0.20)
                           : (openArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.12) : Theme.withAlpha(Theme.surfaceContainerHighest, 0.4))
                    border.width: 1
                    border.color: openArea.pressed
                                 ? Theme.withAlpha(Theme.primary, 0.6)
                                 : (openArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.35) : Theme.withAlpha(Theme.outlineVariant, 0.2))
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                }

                DankIcon {
                    anchors.centerIn: parent
                    name: "open_in_browser"
                    size: 20
                    color: Theme.primary
                }

                MouseArea {
                    id: openArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openProfileClicked()
                }
            }
        }
    }
}
