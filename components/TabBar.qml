import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property int activeTab: 0
    property int prCount: 0
    property int issueCount: 0
    property int unreadPrCount: 0
    property int unreadIssueCount: 0
    property bool isAuthenticated: true

    signal tabSelected(int index)

    width: parent.width
    height: 36
    radius: Theme.cornerRadius
    // Deeper, softer surface container
    color: Theme.withAlpha(Theme.surfaceContainerLowest, 0.7)
    border.width: 0

    RowLayout {
        anchors.fill: parent
        anchors.margins: 3
        spacing: 4

        // Tab 0: Overview / Heatmap
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.cornerRadius - 2
            color: root.activeTab === 0 ? Theme.withAlpha(Theme.surfaceContainerHigh, 0.8) : "transparent"
            border.width: 0

            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
                anchors.centerIn: parent
                spacing: 4

                DankIcon {
                    name: "grid_view"
                    size: 14
                    color: root.activeTab === 0 ? Theme.primary : Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: "热力图"
                    font.bold: root.activeTab === 0
                    font.pixelSize: Theme.fontSizeSmall
                    color: root.activeTab === 0 ? Theme.surfaceText : Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.activeTab = 0
                    root.tabSelected(0)
                }
            }
        }

        // Tab 1: PRs (visible when authenticated)
        Rectangle {
            visible: root.isAuthenticated
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.cornerRadius - 2
            color: root.activeTab === 1 ? Theme.withAlpha(Theme.surfaceContainerHigh, 0.8) : "transparent"
            border.width: 0

            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
                anchors.centerIn: parent
                spacing: 4

                DankIcon {
                    name: "call_merge"
                    size: 14
                    color: root.activeTab === 1 ? Theme.primary : Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: "PR" + (root.prCount > 0 ? " (" + root.prCount + ")" : "")
                    font.bold: root.activeTab === 1
                    font.pixelSize: Theme.fontSizeSmall
                    color: root.activeTab === 1 ? Theme.surfaceText : Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.activeTab = 1
                    root.tabSelected(1)
                }
            }
        }

        // Tab 2: Issues (visible when authenticated)
        Rectangle {
            visible: root.isAuthenticated
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.cornerRadius - 2
            color: root.activeTab === 2 ? Theme.withAlpha(Theme.surfaceContainerHigh, 0.8) : "transparent"
            border.width: 0

            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
                anchors.centerIn: parent
                spacing: 4

                DankIcon {
                    name: "bug_report"
                    size: 14
                    color: root.activeTab === 2 ? Theme.primary : Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: "议题" + (root.issueCount > 0 ? " (" + root.issueCount + ")" : "")
                    font.bold: root.activeTab === 2
                    font.pixelSize: Theme.fontSizeSmall
                    color: root.activeTab === 2 ? Theme.surfaceText : Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.activeTab = 2
                    root.tabSelected(2)
                }
            }
        }
    }
}
