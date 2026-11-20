import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets

Item {
    id: root

    property var issuesList: []
    property bool isLoading: false

    signal openUrlClicked(string url)

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

            DIcon {
                Layout.alignment: Qt.AlignHCenter
                name: "check_circle"
                size: Theme.iconSizeLarge
                color: Theme.primary
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: I18n.tr("No open issues")
                font.bold: true
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
            }
        }
    }

    // Issues List using DListView
    DListView {
        id: listView
        visible: root.issuesList && root.issuesList.length > 0
        anchors.fill: parent
        clip: true
        spacing: Theme.spacingS
        model: root.issuesList

        delegate: Rectangle {
            id: issueItem
            width: listView.width
            // Adaptive height based on text lines, with defensive clipping
            height: Math.max(Theme.iconSizeLarge * 2, itemRowLayout.implicitHeight + Theme.spacingL)
            radius: Theme.cornerRadius - Theme.spacingXXS
            color: itemHover.containsMouse ? Theme.surfaceContainer : Theme.withAlpha(Theme.surfaceContainerLow, 0.9)
            border.width: 0
            clip: true

            required property var modelData
            required property int index

            Behavior on color { ColorAnimation { duration: 150 } }

            RowLayout {
                id: itemRowLayout
                anchors.fill: parent
                anchors.margins: Theme.spacingS
                spacing: Theme.spacingS

                // Issue icon
                Rectangle {
                    Layout.preferredWidth: Theme.iconSizeLarge
                    Layout.preferredHeight: Layout.preferredWidth
                    radius: Layout.preferredWidth / 2
                    color: Theme.surfaceContainerLowest
                    Layout.alignment: Qt.AlignVCenter

                    DIcon {
                        anchors.centerIn: parent
                        name: "bug_report"
                        size: Theme.iconSizeSmall
                        color: Theme.warning
                    }
                }

                // Details column
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Theme.spacingXXS

                    StyledText {
                        Layout.fillWidth: true
                        text: (issueItem.modelData.repo || "") + (issueItem.modelData.number ? (" #" + issueItem.modelData.number) : "")
                        font.pixelSize: Theme.fontSizeXSmall
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

                // Open in browser button
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    width: Theme.iconSizeLarge - Theme.spacingXS
                    height: width
                    radius: Theme.cornerRadiusXS
                    color: openHover.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                    DIcon {
                        anchors.centerIn: parent
                        name: "open_in_new"
                        size: Theme.iconSizeSmall
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
