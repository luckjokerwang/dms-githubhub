import QtQuick
import QtQuick.Layouts
import Quickshell
import QtQuick.Controls
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import qs.DCommon.Widgets
import "./components"

PluginComponent {
    id: root

    // Popout state tracking
    property bool isPopoutOpen: false

    // Popout dimensions
    popoutWidth: 320
    popoutHeight: 418

    // Script paths
    readonly property string contribScriptPath: Qt.resolvedUrl("./scripts/fetch-contributions.sh").toString().replace(/^file:\/\//, "")
    readonly property string ghScriptPath: Qt.resolvedUrl("./scripts/fetch-github-data.sh").toString().replace(/^file:\/\//, "")
    readonly property string notifyScriptPath: Qt.resolvedUrl("./scripts/notify.sh").toString().replace(/^file:\/\//, "")

    // Settings
    property string configuredUsername: (pluginData && pluginData.username) ? pluginData.username : ""
    property int refreshInterval: (pluginData && pluginData.refreshInterval) ? pluginData.refreshInterval : 300
    property bool showDesktopNotifications: (pluginData && pluginData.showNotifications !== undefined)
                                           ? (pluginData.showNotifications !== false && pluginData.showNotifications !== "false")
                                           : true

    // Theme-derived level-to-color mapping
    function levelToColor(level) {
        const lvl = Math.max(0, Math.min(4, Math.round(level || 0)))
        if (lvl === 0) {
            return Theme.surfaceContainerHigh
        }
        const steps = [0.30, 0.55, 0.80, 1.0]
        return Theme.withAlpha(Theme.primary, steps[lvl - 1])
    }

    // State - User & Auth (Zero hardcoded names, clean fallbacks)
    property bool isAuthenticated: false
    property string effectiveUsername: configuredUsername || (ghData && ghData.user && ghData.user.login) || ""
    property string avatarUrl: (ghData && ghData.user && ghData.user.avatar_url) ? ghData.user.avatar_url : ""
    property string cachedAvatarPath: (ghData && ghData.user && ghData.user.avatar_cache) ? ghData.user.avatar_cache : ""
    property string displayName: (ghData && ghData.user && ghData.user.name) ? ghData.user.name : effectiveUsername

    // State - Heatmap (Raw & Mapped)
    property var rawContributions: []
    property var rawGridData: []
    property var contributions: []
    property var gridData: []
    property string totalContributions: "0"
    property var selectedDay: null
    property var todayItem: null

    function updateColors() {
        if (rawContributions && rawContributions.length > 0) {
            const mappedContribs = []
            for (let i = 0; i < rawContributions.length; i++) {
                const item = rawContributions[i]
                const lvl = (item.level !== undefined) ? item.level : 0
                const c = item.date === "--/--" ? root.levelToColor(0) : root.levelToColor(lvl)
                mappedContribs.push(Object.assign({}, item, {
                    color: c,
                    level: lvl
                }))
            }
            root.contributions = mappedContribs
            if (mappedContribs.length > 0) {
                root.todayItem = mappedContribs[mappedContribs.length - 1]
            }
        }

        if (rawGridData && rawGridData.length > 0) {
            const mappedGrid = []
            for (let w = 0; w < rawGridData.length; w++) {
                const weekArr = rawGridData[w]
                const mappedWeek = []
                for (let d = 0; d < weekArr.length; d++) {
                    const item = weekArr[d]
                    const lvl = (item.level !== undefined) ? item.level : 0
                    const c = item.date === "--/--" ? root.levelToColor(0) : root.levelToColor(lvl)
                    mappedWeek.push(Object.assign({}, item, {
                        color: c,
                        level: lvl
                    }))
                }
                mappedGrid.push(mappedWeek)
            }
            root.gridData = mappedGrid
        }

        if (root.selectedDay) {
            const selLvl = (root.selectedDay.level !== undefined) ? root.selectedDay.level : 0
            const selColor = root.levelToColor(selLvl)
            root.selectedDay = Object.assign({}, root.selectedDay, { color: selColor, level: selLvl })
        }
    }

    Connections {
        target: Theme
        function onPrimaryChanged() {
            root.updateColors()
        }
        function onSurfaceContainerHighChanged() {
            root.updateColors()
        }
    }

    // State - GH Data (PRs, Issues)
    property var ghData: ({
        authenticated: false,
        user: null,
        prs: [],
        review_requested: [],
        issues: []
    })

    // Actionable urgent alerts (Review Requested PRs)
    readonly property bool hasActionableAlert: {
        if (!ghData) return false
        return !!(ghData.review_requested && ghData.review_requested.length > 0)
    }

    // Navigation
    property int activeTab: 0

    // Loading & Error & Sync
    property bool isLoading: false
    property bool isError: false
    property string errorMessage: ""
    property var lastRefreshTime: null
    property bool isManualRefresh: false
    property string lastSyncTimeStr: ""
    property string lastFetchedUser: ""

    Component.onCompleted: {
        initializePlaceholders()
        refreshAll(true)
    }

    onEffectiveUsernameChanged: {
        if (effectiveUsername && effectiveUsername !== lastFetchedUser) {
            fetchContributions(true)
        }
    }

    onConfiguredUsernameChanged: {
        refreshAll(true)
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
                level: 0,
                color: Theme.surfaceContainerHigh
            })
        }

        rawContributions = placeholders
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
                    level: 0,
                    color: Theme.surfaceContainerHigh
                })
            }
            gridPlaceholders.push(weekData)
        }
        rawGridData = gridPlaceholders
        updateColors()
    }

    function triggerManualRefresh() {
        root.isManualRefresh = true
        root.sendDesktopNotification(I18n.tr("Checking GitHub connection..."), I18n.tr("Sending request to test connectivity..."), "low")
        root.refreshAll(true)
    }

    function fetchContributions(force) {
        if (!effectiveUsername) return
        lastFetchedUser = effectiveUsername
        contribProcess.command = [root.contribScriptPath, root.effectiveUsername]
        contribProcess.running = true
    }

    function refreshAll(force) {
        const now = Date.now()
        if (!force && lastRefreshTime && (now - lastRefreshTime) < 10000) {
            console.log("GitHubHub: Refresh skipped (cooldown active)")
            return
        }
        lastRefreshTime = now
        isLoading = true
        isError = false

        // 1. Fetch GH CLI data (user identity, PRs, Issues)
        ghProcess.running = true

        // 2. Fetch contributions if effective username is already known
        if (root.effectiveUsername) {
            root.fetchContributions(force)
        }
    }

    function checkProcessesDone() {
        if (!contribProcess.running && !ghProcess.running) {
            root.isLoading = false
            if (root.isManualRefresh) {
                root.isManualRefresh = false
                if (root.isError) {
                    root.sendDesktopNotification(I18n.tr("GitHub Hub · Sync Failed"), I18n.tr("Connection failed: %1").arg(root.errorMessage || I18n.tr("Network timeout")), "critical")
                } else {
                    const time = Qt.formatTime(new Date(), "hh:mm:ss")
                    root.lastSyncTimeStr = time
                    root.sendDesktopNotification(I18n.tr("GitHub Hub · Synced"), I18n.tr("Connected. %1 contributions in the last 8 weeks").arg(root.totalContributions), "normal")
                }
            } else if (!root.isError) {
                root.lastSyncTimeStr = Qt.formatTime(new Date(), "hh:mm")
            }
        }
    }

    // Auto-refresh timer
    Timer {
        id: refreshTimer
        interval: Math.max(60, root.refreshInterval) * 1000
        repeat: true
        running: true
        onTriggered: root.refreshAll(false)
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
                        root.rawContributions = result.contributions
                    }

                    if (result.gridData && result.gridData.length > 0) {
                        root.rawGridData = result.gridData
                    }

                    root.totalContributions = (result.total || 0).toString()
                    root.updateColors()
                } catch (e) {
                    console.error("GitHubHub: Failed to parse heatmap JSON:", e)
                }
            }
        }

        onExited: (code, status) => {
            if (code !== 0 && !root.isError) {
                root.isError = true
                root.errorMessage = I18n.tr("Network timeout or command failed")
            }
            root.checkProcessesDone()
        }
    }

    // Process 2: Fetch GH CLI Data (Identity, Avatar Cache, PRs, Issues)
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
                    if (result.user && result.user.avatar_cache) {
                        root.cachedAvatarPath = result.user.avatar_cache
                    }

                    // If user is detected and heatmap not yet fetched for this user, fetch now
                    if (result.user && result.user.login && !root.configuredUsername && result.user.login !== root.lastFetchedUser) {
                        root.fetchContributions(true)
                    }
                } catch (e) {
                    console.error("GitHubHub: Failed to parse GH data JSON:", e)
                }
            }
        }

        onExited: (code, status) => {
            root.checkProcessesDone()
        }
    }

    // IPC Endpoint: allows CLI & Global Keybinds via `dms ipc call githubHub <method>`
    IpcHandler {
        target: "githubHub"

        function refresh() {
            root.triggerManualRefresh()
        }

        function toggle() {
            if (typeof root.triggerPopout === "function") {
                root.triggerPopout()
            }
        }

        function open() {
            if (!root.isPopoutOpen && typeof root.triggerPopout === "function") {
                root.triggerPopout()
            }
        }

        function close() {
            root.isPopoutOpen = false
            if (typeof root.closePopout === "function") {
                root.closePopout()
            }
        }
    }

    // Process 3: Browser Open Helper
    Process {
        id: openUrlProcess
        property string targetUrl: "https://github.com/" + (root.effectiveUsername || "")
        command: ["xdg-open", targetUrl]
        running: false
    }

    function openUrl(url) {
        if (!url) url = "https://github.com/" + (root.effectiveUsername || "")
        openUrlProcess.targetUrl = url
        openUrlProcess.running = true
    }

    // Process 4: Desktop Notification (DMS Native notification)
    Process {
        id: notifyProcess
        property string notifyTitle: ""
        property string notifyMessage: ""
        property string notifyUrgency: "normal"
        command: [root.notifyScriptPath, notifyTitle, notifyMessage, notifyUrgency]
        running: false
    }

    function sendDesktopNotification(title, message, urgency) {
        if (!root.showDesktopNotifications) return
        notifyProcess.notifyTitle = title
        notifyProcess.notifyMessage = message
        notifyProcess.notifyUrgency = urgency || "normal"
        notifyProcess.running = true
    }

    // --- Horizontal Bar Pill (7-day Contribution Bars + Alert Dot) ---
    horizontalBarPill: Component {
        Item {
            implicitWidth: pillRow.implicitWidth
            implicitHeight: pillRow.implicitHeight

            Row {
                id: pillRow
                spacing: Theme.spacingXXS
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: 7

                    Rectangle {
                        width: Theme.spacingS
                        height: Theme.iconSizeSmall
                        radius: Theme.cornerRadiusXS
                        color: (index < root.contributions.length && root.contributions[index].color)
                               ? root.contributions[index].color
                               : Theme.surfaceContainerHigh
                        border.color: Qt.darker(color, 1.25)
                        border.width: 1

                        opacity: root.isLoading ? 0.6 : 1.0

                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }
            }

            // High-priority urgent alert static dot (Theme.warning on Review Requested)
            Rectangle {
                id: alertDot
                visible: root.hasActionableAlert
                width: Theme.spacingXS + 1
                height: width
                radius: width / 2
                color: Theme.warning
                border.color: Theme.surfaceContainerLowest
                border.width: 1
                anchors.top: pillRow.top
                anchors.right: pillRow.right
                anchors.topMargin: -Theme.spacingXXS
                anchors.rightMargin: -Theme.spacingXXS
                z: 10
            }
        }
    }

    // --- Vertical Bar Pill (7-day Contribution Bars + Alert Dot) ---
    verticalBarPill: Component {
        Item {
            implicitWidth: pillCol.implicitWidth
            implicitHeight: pillCol.implicitHeight

            Column {
                id: pillCol
                spacing: Theme.spacingXXS
                anchors.horizontalCenter: parent.horizontalCenter

                Repeater {
                    model: 7

                    Rectangle {
                        width: Theme.iconSizeSmall
                        height: Theme.spacingS
                        radius: Theme.cornerRadiusXS
                        color: (index < root.contributions.length && root.contributions[index].color)
                               ? root.contributions[index].color
                               : Theme.surfaceContainerHigh
                        border.color: Qt.darker(color, 1.25)
                        border.width: 1

                        opacity: root.isLoading ? 0.6 : 1.0

                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }
            }

            // High-priority urgent alert static dot (Theme.warning on Review Requested)
            Rectangle {
                id: vAlertDot
                visible: root.hasActionableAlert
                width: Theme.spacingXS + 1
                height: width
                radius: width / 2
                color: Theme.warning
                border.color: Theme.surfaceContainerLowest
                border.width: 1
                anchors.top: pillCol.top
                anchors.right: pillCol.right
                anchors.topMargin: -Theme.spacingXXS
                anchors.rightMargin: -Theme.spacingXXS
                z: 10
            }
        }
    }

    // --- Popout Content ---
    popoutContent: Component {
        PopoutComponent {
            id: popoutContainer
            showCloseButton: false
            headerText: ""

            Component.onCompleted: root.isPopoutOpen = true
            Component.onDestruction: root.isPopoutOpen = false

            Shortcut {
                sequence: "F5"
                onActivated: root.triggerManualRefresh()
            }

            Shortcut {
                sequence: "Ctrl+R"
                onActivated: root.triggerManualRefresh()
            }

            Column {
                width: parent.width
                spacing: Theme.spacingS
                bottomPadding: 0

                // 1. Header Card (Avatar + User Info + Actions)
                HeaderCard {
                    avatarUrl: root.avatarUrl
                    cachedAvatarPath: root.cachedAvatarPath
                    username: root.effectiveUsername
                    displayName: root.displayName
                    statusText: root.isError
                                ? root.errorMessage
                                : (root.isLoading ? I18n.tr("Syncing...") : (root.totalContributions + " " + I18n.tr("contributions") + (root.lastSyncTimeStr ? " · " + root.lastSyncTimeStr : "")))
                    isLoading: root.isLoading
                    isError: root.isError
                    lastSyncTime: root.lastSyncTimeStr

                    onRefreshClicked: root.triggerManualRefresh()
                    onOpenProfileClicked: {
                        if (root.effectiveUsername) {
                            root.openUrl("https://github.com/" + root.effectiveUsername)
                        }
                    }
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
                            defaultWeekday: (root.todayItem && root.todayItem.weekdayName) ? root.todayItem.weekdayName : I18n.tr("Today")
                            defaultDate: (root.todayItem && root.todayItem.formattedDate) ? root.todayItem.formattedDate : I18n.tr("Today")
                            defaultCount: (root.todayItem && root.todayItem.count !== undefined) ? root.todayItem.count : 0
                            defaultColor: (root.todayItem && root.todayItem.color) ? root.todayItem.color : Theme.surfaceContainerHigh
                        }
                    }

                    // === Tab 1: PRs List ===
                    PrListTab {
                        visible: root.activeTab === 1
                        prsList: (root.ghData && root.ghData.prs) ? root.ghData.prs : []
                        isLoading: root.isLoading
                        onOpenUrlClicked: url => root.openUrl(url)
                    }

                    // === Tab 2: Issues List ===
                    IssueListTab {
                        visible: root.activeTab === 2
                        issuesList: (root.ghData && root.ghData.issues) ? root.ghData.issues : []
                        isLoading: root.isLoading
                        onOpenUrlClicked: url => root.openUrl(url)
                    }
                }
            }
        }
    }
}
