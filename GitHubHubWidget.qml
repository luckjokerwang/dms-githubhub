import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "./components"

PluginComponent {
    id: root

    // Popout dimensions
    popoutWidth: 320
    popoutHeight: 418

    // Script paths
    readonly property string contribScriptPath: Qt.resolvedUrl("./scripts/fetch-contributions.sh").toString().replace(/^file:\/\//, "")
    readonly property string ghScriptPath: Qt.resolvedUrl("./scripts/fetch-github-data.sh").toString().replace(/^file:\/\//, "")
    readonly property string dcalScriptPath: Qt.resolvedUrl("./scripts/add-to-dcal.sh").toString().replace(/^file:\/\//, "")
    readonly property string localAvatarUrl: Qt.resolvedUrl("./assets/avatar.png").toString()

    // Settings
    property string configuredUsername: (pluginData && pluginData.username) ? pluginData.username : ""
    property int refreshInterval: (pluginData && pluginData.refreshInterval) ? pluginData.refreshInterval : 300

    // State - User & Auth
    property bool isAuthenticated: false
    property string effectiveUsername: configuredUsername || (ghData && ghData.user && ghData.user.login) ? ghData.user.login : "luckjokerwang"
    property string avatarUrl: (ghData && ghData.user && ghData.user.avatar_url) ? ghData.user.avatar_url : ""
    property string displayName: (ghData && ghData.user && ghData.user.name) ? ghData.user.name : effectiveUsername

    // State - Heatmap
    property var contributions: []
    property var gridData: []
    property string totalContributions: "0"
    property var selectedDay: null
    property var todayItem: null

    // State - GH Data (PRs, Issues, Notifications)
    property var ghData: ({
        authenticated: false,
        user: null,
        prs: [],
        review_requested: [],
        issues: [],
        notifications: [],
        unread_count: 0
    })

    // Actionable urgent alerts (Option B: Review Requested PRs only)
    readonly property bool hasActionableAlert: {
        if (!ghData) return false
        return !!(ghData.review_requested && ghData.review_requested.length > 0)
    }

    // Navigation
    property int activeTab: 0

    // Loading & Error
    property bool isLoading: false
    property bool isError: false
    property string errorMessage: ""
    property var lastRefreshTime: null

    Component.onCompleted: {
        initializePlaceholders()
        refreshAll()
    }

    onConfiguredUsernameChanged: {
        refreshAll()
    }

    onRefreshIntervalChanged: {
        if (refreshTimer.running) {
            refreshTimer.restart()
        }
    }

    function initializePlaceholders() {
        const placeholders = []
        const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        for (let i = 0; i < 7; i++) {
            placeholders.push({
                weekday: i,
                weekdayName: days[i],
                date: "--/--",
                formattedDate: "--/--",
                count: 0,
                color: "#202329"
            })
        }

        contributions = placeholders
        totalContributions = "0"

        const gridPlaceholders = []
        for (let week = 0; week < 8; week++) {
            const weekData = []
            for (let day = 0; day < 7; day++) {
                weekData.push({
                    weekday: day,
                    weekdayName: days[day],
                    date: "--/--",
                    formattedDate: "--/--",
                    count: 0,
                    color: "#202329"
                })
            }
            gridPlaceholders.push(weekData)
        }
        gridData = gridPlaceholders
    }

    function refreshAll() {
        const now = Date.now()
        if (lastRefreshTime && (now - lastRefreshTime) < 10000) {
            console.log("GitHubHub: Refresh skipped (cooldown active)")
            return
        }
        lastRefreshTime = now
        isLoading = true
        isError = false

        // 1. Fetch contributions
        contribProcess.running = true

        // 2. Fetch GH CLI data (user, PRs, Issues)
        ghProcess.running = true
    }

    // Auto-refresh timer
    Timer {
        id: refreshTimer
        interval: Math.max(60, root.refreshInterval) * 1000
        repeat: true
        running: true
        onTriggered: root.refreshAll()
    }

    // Process 1: Fetch Heatmap Contributions
    Process {
        id: contribProcess
        command: [root.contribScriptPath, root.effectiveUsername]
        running: false

        stdout: SplitParser {
            onRead: data => {
                try {
                    const result = JSON.parse(data.trim())
                    if (result.error) {
                        root.isError = true
                        root.errorMessage = result.errorMessage || "Failed to load heatmap"
                        return
                    }

                    if (result.contributions && result.contributions.length > 0) {
                        root.contributions = result.contributions
                        root.todayItem = result.contributions[result.contributions.length - 1]
                    }

                    if (result.gridData && result.gridData.length > 0) {
                        root.gridData = result.gridData
                    }

                    root.totalContributions = (result.total || 0).toString()
                } catch (e) {
                    console.error("GitHubHub: Failed to parse heatmap JSON:", e)
                }
            }
        }

        onExited: (code, status) => {
            if (!ghProcess.running) {
                root.isLoading = false
            }
        }
    }

    // Process 2: Fetch GH CLI Data (Avatar, PRs, Issues)
    Process {
        id: ghProcess
        command: [root.ghScriptPath]
        running: false

        stdout: SplitParser {
            onRead: data => {
                try {
                    const result = JSON.parse(data.trim())
                    root.ghData = result
                    root.isAuthenticated = !!result.authenticated
                    if (result.user && result.user.avatar_url) {
                        root.avatarUrl = result.user.avatar_url
                    }
                } catch (e) {
                    console.error("GitHubHub: Failed to parse GH data JSON:", e)
                }
            }
        }

        onExited: (code, status) => {
            if (!contribProcess.running) {
                root.isLoading = false
            }
        }
    }

    // Process 3: Browser Open Helper
    Process {
        id: openUrlProcess
        property string targetUrl: "https://github.com/" + root.effectiveUsername
        command: ["xdg-open", targetUrl]
        running: false
    }

    function openUrl(url) {
        if (!url) url = "https://github.com/" + root.effectiveUsername
        openUrlProcess.targetUrl = url
        openUrlProcess.running = true
    }

    // Process 4: Add to dcal tasks
    Process {
        id: dcalProcess
        property string taskTitle: ""
        property string taskUrl: ""
        command: [root.dcalScriptPath, taskTitle, taskUrl]
        running: false
    }

    function addToDcal(title, url) {
        dcalProcess.taskTitle = title
        dcalProcess.taskUrl = url
        dcalProcess.running = true
    }

    // --- Horizontal Bar Pill (Classic 7-day Green Vertical Bars + Option B Amber Alert Dot) ---
    horizontalBarPill: Component {
        Item {
            implicitWidth: pillRow.implicitWidth
            implicitHeight: pillRow.implicitHeight

            Row {
                id: pillRow
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: 7

                    Rectangle {
                        width: 8
                        height: 16
                        radius: 2
                        color: (index < root.contributions.length && root.contributions[index].color)
                               ? root.contributions[index].color
                               : "#202329"
                        border.color: Qt.darker(color, 1.25)
                        border.width: 1

                        opacity: root.isLoading ? 0.6 : 1.0

                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }
            }

            // High-priority urgent alert breathing dot (Option B: Amber dot on Review / CI failed)
            Rectangle {
                id: alertDot
                visible: root.hasActionableAlert
                width: 5
                height: 5
                radius: 2.5
                color: "#FFA000" // Warm Amber
                border.color: Theme.surfaceContainerLowest
                border.width: 1
                anchors.top: pillRow.top
                anchors.right: pillRow.right
                anchors.topMargin: -2
                anchors.rightMargin: -2
                z: 10

                SequentialAnimation on opacity {
                    running: alertDot.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 1500; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 1.0; duration: 1500; easing.type: Easing.InOutQuad }
                }
            }
        }
    }

    // --- Vertical Bar Pill (Classic 7-day Green Bars + Option B Amber Alert Dot) ---
    verticalBarPill: Component {
        Item {
            implicitWidth: pillCol.implicitWidth
            implicitHeight: pillCol.implicitHeight

            Column {
                id: pillCol
                spacing: 2
                anchors.horizontalCenter: parent.horizontalCenter

                Repeater {
                    model: 7

                    Rectangle {
                        width: 16
                        height: 8
                        radius: 2
                        color: (index < root.contributions.length && root.contributions[index].color)
                               ? root.contributions[index].color
                               : "#202329"
                        border.color: Qt.darker(color, 1.25)
                        border.width: 1

                        opacity: root.isLoading ? 0.6 : 1.0

                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }
            }

            // High-priority urgent alert breathing dot (Option B: Amber dot on Review / CI failed)
            Rectangle {
                id: vAlertDot
                visible: root.hasActionableAlert
                width: 5
                height: 5
                radius: 2.5
                color: "#FFA000"
                border.color: Theme.surfaceContainerLowest
                border.width: 1
                anchors.top: pillCol.top
                anchors.right: pillCol.right
                anchors.topMargin: -2
                anchors.rightMargin: -2
                z: 10

                SequentialAnimation on opacity {
                    running: vAlertDot.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 1500; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 1.0; duration: 1500; easing.type: Easing.InOutQuad }
                }
            }
        }
    }

    // --- Popout Content ---
    popoutContent: Component {
        PopoutComponent {
            id: popoutContainer
            showCloseButton: false
            headerText: ""

            Column {
                width: parent.width
                spacing: Theme.spacingS
                bottomPadding: 0

                // 1. Header Card (Avatar + User Info + Actions)
                HeaderCard {
                    avatarUrl: root.avatarUrl
                    localAvatarPath: root.localAvatarUrl
                    username: root.effectiveUsername
                    displayName: root.displayName
                    statusText: root.isError
                                ? root.errorMessage
                                : (root.isLoading ? "同步中..." : root.totalContributions + " 次贡献 (近8周)")
                    isLoading: root.isLoading

                    onRefreshClicked: root.refreshAll()
                    onOpenProfileClicked: root.openUrl("https://github.com/" + root.effectiveUsername)
                }

                // 2. Segmented Tab Bar (Hidden if not authenticated)
                TabBar {
                    visible: root.isAuthenticated
                    activeTab: root.activeTab
                    prCount: (root.ghData && root.ghData.prs) ? root.ghData.prs.length : 0
                    issueCount: (root.ghData && root.ghData.issues) ? root.ghData.issues.length : 0
                    isAuthenticated: root.isAuthenticated

                    onTabSelected: idx => root.activeTab = idx
                }

                // 3. Tab Content Area (Tight fitting & dynamically sized)
                Item {
                    id: tabContentContainer
                    width: parent.width
                    height: overviewCol.implicitHeight
                    implicitHeight: overviewCol.implicitHeight

                    // === Tab 0: Overview (Heatmap Grid + Detail Card) ===
                    Column {
                        id: overviewCol
                        visible: root.activeTab === 0
                        width: parent.width
                        spacing: Theme.spacingS
                        anchors.horizontalCenter: parent.horizontalCenter

                        HeatmapGrid {
                            gridData: root.gridData
                            selectedDay: root.selectedDay
                            isLoading: root.isLoading
                            onDayHovered: day => root.selectedDay = day
                        }

                        DetailCard {
                            selectedDay: root.selectedDay
                            defaultWeekday: (root.todayItem && root.todayItem.weekdayName) ? root.todayItem.weekdayName : "今日"
                            defaultDate: (root.todayItem && root.todayItem.formattedDate) ? root.todayItem.formattedDate : "Today"
                            defaultCount: (root.todayItem && root.todayItem.count !== undefined) ? root.todayItem.count : 0
                            defaultColor: (root.todayItem && root.todayItem.color) ? root.todayItem.color : "#202329"
                        }
                    }

                    // === Tab 1: PRs List ===
                    PrListTab {
                        visible: root.activeTab === 1
                        prsList: (root.ghData && root.ghData.prs) ? root.ghData.prs : []
                        isLoading: root.isLoading
                        onOpenUrlClicked: url => root.openUrl(url)
                        onAddToDcalClicked: (title, url) => root.addToDcal(title, url)
                    }

                    // === Tab 2: Issues List ===
                    IssueListTab {
                        visible: root.activeTab === 2
                        issuesList: (root.ghData && root.ghData.issues) ? root.ghData.issues : []
                        isLoading: root.isLoading
                        onOpenUrlClicked: url => root.openUrl(url)
                        onAddToDcalClicked: (title, url) => root.addToDcal(title, url)
                    }
                }
            }
        }
    }
}
