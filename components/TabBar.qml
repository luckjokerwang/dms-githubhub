import QtQuick
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets

Item {
    id: root

    property int activeTab: 0
    property int prCount: 0
    property int issueCount: 0
    property bool isAuthenticated: true

    signal tabSelected(int index)

    width: parent.width
    implicitHeight: dTabBar.implicitHeight
    height: implicitHeight

    DTabBar {
        id: dTabBar
        anchors.fill: parent
        equalWidthTabs: true
        currentIndex: root.activeTab
        model: [
            { text: I18n.tr("Heatmap"), icon: "grid_view" },
            { text: I18n.tr("PR") + (root.prCount > 0 ? " (" + root.prCount + ")" : ""), icon: "call_merge" },
            { text: I18n.tr("Issues") + (root.issueCount > 0 ? " (" + root.issueCount + ")" : ""), icon: "bug_report" }
        ]
        onTabClicked: index => {
            root.activeTab = index
            root.tabSelected(index)
        }
    }
}
