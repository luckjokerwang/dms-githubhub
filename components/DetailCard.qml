import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets

StyledRect {
    id: root

    property var selectedDay: null
    property string defaultWeekday: I18n.tr("Today")
    property string defaultDate: ""
    property int defaultCount: 0
    property color defaultColor: Theme.surfaceContainerHigh

    readonly property int currentCount: selectedDay ? selectedDay.count : defaultCount
    readonly property string currentWeekday: selectedDay ? selectedDay.weekdayName : defaultWeekday
    readonly property string currentDate: {
        if (!selectedDay) return defaultDate || I18n.tr("Today")
        return selectedDay.formattedDate || selectedDay.date || ""
    }
    readonly property color currentColor: selectedDay ? (selectedDay.color || defaultColor) : defaultColor

    width: parent.width
    implicitHeight: cardRow.implicitHeight + Theme.spacingM * 2
    height: implicitHeight
    radius: Theme.cornerRadius
    // Softer, deeper background color
    color: Theme.withAlpha(Theme.surfaceContainerLow, 0.9)
    border.width: 1
    border.color: selectedDay ? Qt.rgba(currentColor.r, currentColor.g, currentColor.b, 0.45) : Theme.withAlpha(Theme.outlineVariant, 0.2)

    Behavior on border.color { ColorAnimation { duration: 150 } }

    RowLayout {
        id: cardRow
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        // Count display column (left)
        Column {
            Layout.preferredWidth: Theme.spacingXL * 3
            Layout.alignment: Qt.AlignVCenter
            spacing: Theme.spacingXXS

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacingS

                Rectangle {
                    width: Theme.spacingM
                    height: Theme.spacingM
                    radius: Theme.cornerRadiusXS
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.currentColor
                    border.color: Qt.darker(color, 1.2)
                    border.width: 1
                    antialiasing: true

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                StyledText {
                    text: root.currentCount.toString()
                    font.pixelSize: Theme.fontSizeXXLarge
                    font.bold: true
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            StyledText {
                text: I18n.tr("contributions")
                font.pixelSize: Theme.fontSizeXSmall
                color: Theme.surfaceVariantText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // Vertical divider
        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: Theme.iconSizeLarge + Theme.spacingS
            Layout.alignment: Qt.AlignVCenter
            color: Theme.withAlpha(Theme.outlineVariant, 0.3)
        }

        // Date and Day info (right)
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Theme.spacingXXS

            RowLayout {
                spacing: Theme.spacingS

                DIcon {
                    name: "commit"
                    size: Theme.iconSizeSmall
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
                    radius: Theme.cornerRadiusXS
                    color: Theme.withAlpha(Theme.primary, 0.15)
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.primary, 0.3)
                    implicitWidth: todayBadgeText.implicitWidth + Theme.spacingS
                    implicitHeight: todayBadgeText.implicitHeight + Theme.spacingXXS

                    StyledText {
                        id: todayBadgeText
                        anchors.centerIn: parent
                        text: I18n.tr("Today")
                        font.pixelSize: Theme.fontSizeXSmall
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
