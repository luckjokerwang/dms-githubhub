import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets

Item {
    id: root

    property var gridData: []
    property var selectedDay: null
    property bool isLoading: false

    signal dayHovered(var dayData)

    width: parent.width
    implicitHeight: gridRow.implicitHeight

    // Centered 8-week grid layout with Theme-derived cell metrics
    readonly property int cellSize: Theme.iconSizeLarge - Theme.spacingXS
    readonly property int labelWidth: Theme.iconSizeSmall - Theme.spacingXXS
    readonly property int labelSpacing: Theme.spacingS
    readonly property int colSpacing: Theme.spacingXS
    readonly property int rowSpacing: Theme.spacingXS

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
                    font.pixelSize: Theme.fontSizeXSmall
                    color: Theme.surfaceVariantText
                    width: root.labelWidth
                    height: root.cellSize
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        // 8-week Grid
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
                            radius: root.selectedDay === modelData ? 5 : 3
                            color: modelData.color || Theme.surfaceContainerHigh
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

                            DTooltipHost {
                                text: (modelData.formattedDate || modelData.date) + ": " + (modelData.count !== undefined ? modelData.count : 0)
                                target: cellRect
                                hoverArea: cellMouseArea
                            }
                        }
                    }
                }
            }
        }
    }
}
