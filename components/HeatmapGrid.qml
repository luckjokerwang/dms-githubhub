import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets

Item {
    id: root

    property var gridData: []
    property var selectedDay: null
    property bool isLoading: false

    signal dayHovered(var dayData)

    width: parent.width
    implicitHeight: gridRow.implicitHeight

    // Sized to 28x28 square as requested, centered horizontally
    readonly property int cellSize: 28
    readonly property int labelWidth: 14
    readonly property int labelSpacing: 6
    readonly property int colSpacing: 3
    readonly property int rowSpacing: 3

    Row {
        id: gridRow
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.labelSpacing

        // Day labels column
        Column {
            spacing: root.rowSpacing
            width: root.labelWidth
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
                model: ["S", "M", "T", "W", "T", "F", "S"]

                StyledText {
                    text: modelData
                    font.pixelSize: 10
                    color: Theme.surfaceVariantText
                    width: root.labelWidth
                    height: root.cellSize
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        // 8-week Grid (28x28 square cells)
        Row {
            spacing: root.colSpacing

            Repeater {
                model: root.gridData

                Column {
                    id: weekCol
                    spacing: root.rowSpacing
                    required property var modelData
                    required property int index
                    z: 1

                    Repeater {
                        model: modelData

                        Rectangle {
                            id: cellRect
                            width: root.cellSize
                            height: root.cellSize
                            // Smooth rounded square
                            radius: root.selectedDay === modelData ? 6 : 4
                            color: modelData.color || "#202329"
                            border.color: root.selectedDay === modelData ? Theme.primary : Qt.darker(color, 1.15)
                            border.width: root.selectedDay === modelData ? 2 : 1
                            opacity: root.isLoading ? 0.6 : 1.0

                            required property var modelData

                            Behavior on radius { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            MouseArea {
                                id: cellMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: {
                                    weekCol.z = 100
                                    if (modelData && modelData.date) {
                                        root.selectedDay = modelData
                                        root.dayHovered(modelData)
                                    }
                                }
                                onExited: {
                                    weekCol.z = 1
                                }
                            }

                            // Tooltip popup on hover (Original project style: "11/18: 1")
                            Rectangle {
                                id: tooltipBadge
                                visible: cellMouseArea.containsMouse && modelData && modelData.date && modelData.date !== "--/--"
                                z: 999
                                anchors.bottom: parent.top
                                anchors.bottomMargin: 4
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: tooltipText.implicitWidth + 12
                                height: tooltipText.implicitHeight + 6
                                color: Theme.surfaceContainerHighest
                                border.color: Theme.withAlpha(Theme.outlineVariant, 0.4)
                                border.width: 1
                                radius: 4

                                StyledText {
                                    id: tooltipText
                                    anchors.centerIn: parent
                                    text: (modelData.formattedDate || modelData.date) + ": " + (modelData.count !== undefined ? modelData.count : 0)
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
