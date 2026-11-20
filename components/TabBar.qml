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
            { text: "热力图", icon: "grid_view" },
            { text: "PR" + (root.prCount > 0 ? " (" + root.prCount + ")" : ""), icon: "call_merge" },
            { text: "议题" + (root.issueCount > 0 ? " (" + root.issueCount + ")" : ""), icon: "bug_report" }
        ]
        onTabClicked: index => {
            root.activeTab = index
            root.tabSelected(index)
        }
    }
}
