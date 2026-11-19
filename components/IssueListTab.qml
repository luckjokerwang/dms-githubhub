import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Common
import qs.Widgets

Item {
    id: root

    property var issuesList: []
    property bool isLoading: false

    signal openUrlClicked(string url)
    signal addToDcalClicked(string title, string url)

    implicitWidth: parent.width
    implicitHeight: parent.height

    // Empty state
    StyledRect {
        visible: !root.isLoading && (!root.issuesList || root.issuesList.length === 0)
        anchors.fill: parent
        color: Theme.withAlpha(Theme.surfaceContainerLow, 0.9)
        radius: Theme.cornerRadius

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Theme.spacingM

            DankIcon {
                Layout.alignment: Qt.AlignHCenter
                name: "check_circle"
                size: 36
                color: Theme.primary
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "太棒了！暂无未结的议题"
                font.bold: true
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
            }
        }
    }

    // Issues List
    ListView {
        id: listView
        visible: root.issuesList && root.issuesList.length > 0
        anchors.fill: parent
        clip: true
        spacing: 6
        model: root.issuesList

        delegate: Rectangle {
            id: issueItem
            width: listView.width
            // Adaptive height based on text lines, with defensive clipping
            height: Math.max(68, itemRowLayout.implicitHeight + 16)
            radius: Theme.cornerRadius - 2
            color: itemHover.containsMouse ? Theme.surfaceContainer : Theme.withAlpha(Theme.surfaceContainerLow, 0.9)
            border.width: 0
            clip: true

            required property var modelData
            required property int index

            Behavior on color { ColorAnimation { duration: 150 } }

            RowLayout {
                id: itemRowLayout
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                // Issue icon
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 16
                    color: Theme.surfaceContainerLowest
                    Layout.alignment: Qt.AlignVCenter

                    DankIcon {
                        anchors.centerIn: parent
                        name: "bug_report"
                        size: 16
                        color: "#f59e0b"
                    }
                }

                // Details column
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        text: (issueItem.modelData.repo || "") + (issueItem.modelData.number ? (" #" + issueItem.modelData.number) : "")
                        font.pixelSize: Theme.fontSizeSmall - 2
                        color: Theme.secondary
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: issueItem.modelData.title || ""
                        font.bold: true
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceText
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }

                // Action buttons (hover)
                Row {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4

                    // Add to dcal task button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: Theme.cornerRadius - 4
                        color: pinHover.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                        DankIcon {
                            anchors.centerIn: parent
                            name: "push_pin"
                            size: 14
                            color: pinHover.containsMouse ? Theme.primary : Theme.surfaceVariantText
                        }

                        MouseArea {
                            id: pinHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const title = "[Issue] " + (issueItem.modelData.repo || "") + "#" + (issueItem.modelData.number || "") + ": " + (issueItem.modelData.title || "")
                                root.addToDcalClicked(title, issueItem.modelData.url || "")
                            }
                        }
                    }

                    // Open in browser button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: Theme.cornerRadius - 4
                        color: openHover.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                        DankIcon {
                            anchors.centerIn: parent
                            name: "open_in_new"
                            size: 14
                            color: openHover.containsMouse ? Theme.primary : Theme.surfaceVariantText
                        }

                        MouseArea {
                            id: openHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openUrlClicked(issueItem.modelData.url || "")
                        }
                    }
                }
            }

            MouseArea {
                id: itemHover
                anchors.fill: parent
                hoverEnabled: true
                z: -1
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openUrlClicked(issueItem.modelData.url || "")
            }
        }
    }
}
