import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets

StyledRect {
    id: root

    property var selectedDay: null
    property string defaultWeekday: "Today"
    property string defaultDate: ""
    property int defaultCount: 0
    property color defaultColor: "#202329"

    readonly property int currentCount: selectedDay ? selectedDay.count : defaultCount
    readonly property string currentWeekday: selectedDay ? selectedDay.weekdayName : defaultWeekday
    readonly property string currentDate: {
        if (!selectedDay) return defaultDate || "Today"
        return selectedDay.formattedDate || selectedDay.date || ""
    }
    readonly property color currentColor: selectedDay ? (selectedDay.color || defaultColor) : defaultColor

    width: parent.width
    height: 72
    radius: Theme.cornerRadius
    // Softer, deeper background color
    color: Theme.withAlpha(Theme.surfaceContainerLow, 0.9)
    border.width: 1
    border.color: selectedDay ? Qt.rgba(currentColor.r, currentColor.g, currentColor.b, 0.45) : Theme.withAlpha(Theme.outlineVariant, 0.2)

    Behavior on border.color { ColorAnimation { duration: 150 } }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        // Count display column (left)
        Column {
            Layout.preferredWidth: 88
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Rectangle {
                    width: 10
                    height: 10
                    radius: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.currentColor
                    border.color: Qt.darker(color, 1.2)
                    border.width: 1
                    antialiasing: true

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                StyledText {
                    text: root.currentCount.toString()
                    font.pixelSize: Theme.fontSizeXLarge * 1.4
                    font.bold: true
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            StyledText {
                text: "contributions"
                font.pixelSize: Theme.fontSizeSmall - 2
                color: Theme.surfaceVariantText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // Vertical divider
        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 38
            Layout.alignment: Qt.AlignVCenter
            color: Theme.withAlpha(Theme.outlineVariant, 0.3)
        }

        // Date and Day info (right)
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            RowLayout {
                spacing: Theme.spacingS

                DankIcon {
                    name: "commit"
                    size: 16
                    color: Theme.primary
                }

                StyledText {
                    text: root.currentWeekday
                    font.bold: true
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                }

                Rectangle {
                    visible: !root.selectedDay
                    radius: 3
                    color: Theme.withAlpha(Theme.primary, 0.15)
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.primary, 0.3)
                    implicitWidth: todayBadgeText.implicitWidth + 8
                    implicitHeight: todayBadgeText.implicitHeight + 2

                    StyledText {
                        id: todayBadgeText
                        anchors.centerIn: parent
                        text: "今日"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Theme.primary
                    }
                }
            }

            StyledText {
                text: root.currentDate
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
        }
    }
}
