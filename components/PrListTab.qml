import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets

Item {
    id: root

    property var prsList: []
    property bool isLoading: false

    signal openUrlClicked(string url)

    implicitWidth: parent.width
    implicitHeight: parent.height

    // Empty state
    StyledRect {
        visible: !root.isLoading && (!root.prsList || root.prsList.length === 0)
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
                text: I18n.tr("No open pull requests")
                font.bold: true
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
            }
        }
    }

    // PR List using DListView
    DListView {
        id: listView
        visible: root.prsList && root.prsList.length > 0
        anchors.fill: parent
        clip: true
        spacing: 6
        model: root.prsList

        delegate: Rectangle {
            id: prItem
            width: listView.width
            // Adaptive height based on text lines, with defensive clipping
            height: Math.max(68, itemRowLayout.implicitHeight + 16)
            radius: Theme.cornerRadius - 2
            color: itemHover.containsMouse ? Theme.surfaceContainer : Theme.withAlpha(Theme.surfaceContainerLow, 0.9)
            border.width: (prItem.modelData && prItem.modelData.isReviewRequested) ? 1 : 0
            border.color: (prItem.modelData && prItem.modelData.isReviewRequested) ? Theme.primary : "transparent"
            clip: true

            required property var modelData
            required property int index

            Behavior on color { ColorAnimation { duration: 150 } }

            RowLayout {
                id: itemRowLayout
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                // PR icon
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 16
                    color: Theme.surfaceContainerLowest
                    Layout.alignment: Qt.AlignVCenter

                    DIcon {
                        anchors.centerIn: parent
                        name: "call_merge"
                        size: 16
                        color: Theme.primary
                    }
                }

                // Details column
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        StyledText {
                            Layout.fillWidth: true
                            text: (prItem.modelData.repo || "") + (prItem.modelData.number ? (" #" + prItem.modelData.number) : "")
                            font.pixelSize: Theme.fontSizeSmall - 2
                            color: Theme.primary
                            elide: Text.ElideRight
                        }

                        // Review Requested pill
                        Rectangle {
                            visible: !!(prItem.modelData && prItem.modelData.isReviewRequested)
                            Layout.preferredHeight: Theme.iconSizeSmall
                            Layout.preferredWidth: unreadRow.implicitWidth + Theme.spacingS
                            radius: Theme.cornerRadiusXS
                            color: Theme.withAlpha(Theme.primary, 0.15)
                            border.color: Theme.withAlpha(Theme.primary, 0.5)
                            border.width: 1

                            Row {
                                id: unreadRow
                                anchors.centerIn: parent
                                spacing: Theme.spacingXXS

                                StyledText {
                                    text: I18n.tr("Review Requested")
                                    font.pixelSize: Theme.fontSizeSmall - 2
                                    font.bold: true
                                    color: Theme.primary
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: prItem.modelData.title || ""
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
                        onClicked: root.openUrlClicked(prItem.modelData.url || "")
                    }
                }
            }

            MouseArea {
                id: itemHover
                anchors.fill: parent
                hoverEnabled: true
                z: -1
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openUrlClicked(prItem.modelData.url || "")
            }
        }
    }
}
