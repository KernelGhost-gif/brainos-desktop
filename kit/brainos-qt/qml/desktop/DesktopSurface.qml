import QtQuick
import QtQuick.Layouts
import BrainOS

Item {
    id: root
    property var openWindows: []
    property var activeApps: []
    property var externalWindowModel
    property int nextWindowZ: 20
    property string activeTitle: "Desktop"
    property bool applicationsOpen: false
    property bool notificationsOpen: false

    function appSpec(appId) {
        const specs = {
            "files": { title: "Files", icon: "../assets/icons/folder.svg", component: filesPage, w: 820, h: 570 },
            "terminal": { title: "Terminal", icon: "../assets/icons/terminal.svg", component: terminalPage, w: 760, h: 520 },
            "settings": { title: "Settings", icon: "../assets/icons/settings.svg", component: settingsPage, w: 790, h: 560 },
            "installer": { title: "Installer", icon: "../assets/icons/download.svg", component: installerPage, w: 820, h: 570 },
            "packages": { title: "Package Manager", icon: "../assets/icons/package.svg", component: packagePage, w: 820, h: 570 },
            "media": { title: "Media Player", icon: "../assets/icons/music.svg", component: mediaPage, w: 760, h: 520 },
            "editor": { title: "Text Editor", icon: "../assets/icons/editor.svg", component: editorPage, w: 780, h: 550 },
            "images": { title: "Image Viewer", icon: "../assets/icons/image.svg", component: imagePage, w: 800, h: 560 },
            "about": { title: "About BrainOS", icon: "../assets/icons/info.svg", component: aboutPage, w: 680, h: 480 },
            "calculator": { title: "Calculator", icon: "../assets/icons/calculator.svg", component: calculatorPage, w: 520, h: 520 },
            "browser": { title: "Web Browser", icon: "../assets/icons/browser.svg", component: browserPage, w: 1060, h: 700 }
        }
        return specs[appId]
    }

    function launchApp(appId) {
        applicationsOpen = false
        for (let i = 0; i < openWindows.length; ++i) {
            if (openWindows[i].appId === appId) {
                activateAppWindow(openWindows[i])
                return
            }
        }

        const spec = appSpec(appId)
        if (!spec)
            return

        const availableWidth = windowLayer.width
        const availableHeight = windowLayer.height
        // Keep windows usable on small QEMU/VNC modes and narrow laptop screens.
        const maxWidth = Math.max(1, availableWidth - 16)
        const maxHeight = Math.max(1, availableHeight - 16)
        const width = Math.min(spec.w, maxWidth)
        const height = Math.min(spec.h, maxHeight)
        const offset = openWindows.length % 6
        const x = Math.max(12, Math.min(availableWidth - width - 12,
                                       (availableWidth - width) / 2 - 80 + offset * 26))
        const y = Math.max(12, Math.min(availableHeight - height - 12, 36 + offset * 24))

        const window = appWindowComponent.createObject(windowLayer, {
            "appId": appId,
            "title": spec.title,
            "iconSource": spec.icon,
            "contentComponent": spec.component,
            "desktopController": root,
            "x": x,
            "y": y,
            "width": width,
            "height": height,
            "z": ++nextWindowZ
        })
        if (!window)
            return

        window.activated.connect(function() { root.activateAppWindow(window) })
        window.closed.connect(function() { root.removeAppWindow(window) })
        openWindows = openWindows.concat([window])
        refreshActiveApps()
        activateAppWindow(window)
    }

    function activateAppWindow(window) {
        if (!window)
            return
        window.minimized = false
        window.z = ++nextWindowZ
        window.opacity = 1
        window.scale = 1
        activeTitle = window.title
    }

    function removeAppWindow(window) {
        const remaining = []
        for (let i = 0; i < openWindows.length; ++i) {
            if (openWindows[i] !== window)
                remaining.push(openWindows[i])
        }
        openWindows = remaining
        window.destroy()
        refreshActiveApps()
        activeTitle = openWindows.length > 0 ? openWindows[openWindows.length - 1].title : "Desktop"
    }

    function refreshActiveApps() {
        const apps = []
        for (let i = 0; i < openWindows.length; ++i)
            apps.push(openWindows[i].appId)
        activeApps = apps
    }

    Wallpaper {
        anchors.fill: parent
        wallpaperIndex: brain.wallpaperIndex
    }

    Item {
        anchors.fill: parent
        anchors.topMargin: Theme.topBarHeight
        anchors.bottomMargin: Theme.dockHeight + 18

        Item {
            id: desktopIcons
            anchors.left: parent.left
            anchors.leftMargin: root.width < 1500 ? 14 : 24
            anchors.top: parent.top
            anchors.topMargin: 18
            width: 84
            height: parent.height
            visible: root.width >= 820

            Repeater {
                model: [
                    { title: "Files", id: "files", icon: "../assets/icons/folder.svg", color: "#7552D9" },
                    { title: "Downloads", id: "downloads", icon: "../assets/icons/download.svg", color: "#2AAFD5" },
                    { title: "Trash", id: "trash", icon: "../assets/icons/trash.svg", color: "#687284" },
                    { title: "Projects", id: "projects", icon: "../assets/icons/projects.svg", color: "#7552D9" },
                    { title: "Terminal", id: "terminal", icon: "../assets/icons/terminal.svg", color: "#303849" }
                ]
                delegate: DesktopIcon {
                    y: [0, 92, 190, 286, 384][index]
                    title: modelData.title
                    appId: modelData.id
                    iconSource: modelData.icon
                    iconColor: modelData.color
                    onLaunched: function(id) {
                        if (id === "downloads")
                            system.openPath(system.homePath + "/Downloads")
                        else if (id === "trash")
                            system.openPath(system.homePath + "/.local/share/Trash/files")
                        else if (id === "projects")
                            system.openPath(system.homePath + "/Projects")
                        else
                            root.launchApp(id)
                    }
                }
            }
        }

        Flickable {
            id: widgetRail
            property real railMargin: root.width < 1500 ? Theme.space3 : Theme.space5
            anchors.right: parent.right
            anchors.rightMargin: railMargin
            anchors.top: parent.top
            anchors.topMargin: Theme.topBarHeight + Theme.space4
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.dockHeight + Theme.space6
            width: Math.min(root.width < 1500 ? 272 : 316, parent.width * 0.26)
            visible: brain.widgetsEnabled && root.width >= 920
            contentHeight: widgetsColumn.implicitHeight + Theme.space4
            clip: true
            opacity: visible ? 1 : 0
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            ColumnLayout {
                id: widgetsColumn
                width: parent.width
                spacing: Theme.space3

                ClockCalendarWidget {
                    Layout.fillWidth: true
                    clockText: brain.clockText
                    dateText: brain.dateText
                }

                WeatherWidget {
                    Layout.fillWidth: true
                }

                SystemMonitorWidget {
                    Layout.fillWidth: true
                }

                MusicWidget {
                    Layout.fillWidth: true
                    onOpenPlayer: root.launchApp("media")
                }

                QuickNotesWidget {
                    Layout.fillWidth: true
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: brain.animationsEnabled ? Theme.motionNormal : 0
                    easing.type: Easing.OutCubic
                }
            }
        }
        Item {
            id: windowLayer
            anchors.fill: parent
            anchors.leftMargin: root.width < 820 ? 12 : 102
            anchors.rightMargin: widgetRail.visible ? widgetRail.width + widgetRail.railMargin + 10 : 18
        }
    }

    Item {
        id: externalWaylandLayer
        anchors.fill: parent
        anchors.topMargin: Theme.topBarHeight
        anchors.bottomMargin: Theme.dockHeight + 18
        z: 1200

        Repeater {
            model: root.externalWindowModel
            delegate: WindowChrome {
                windowIndex: index
                shellSurface: model.shellSurface
                title: model.title
                appId: model.appId
                posX: model.windowX
                posY: model.windowY
                windowWidth: model.windowWidth
                windowHeight: model.windowHeight
                active: model.active
                minimized: model.minimized
                maximized: model.maximized
            }
        }
    }

    TopBar {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        activeTitle: root.activeTitle
        notificationsOpen: root.notificationsOpen
        onApplicationsClicked: {
            root.applicationsOpen = !root.applicationsOpen
            root.notificationsOpen = false
        }
        onNotificationsClicked: {
            root.notificationsOpen = !root.notificationsOpen
            root.applicationsOpen = false
        }
        onQuickSettingsClicked: {
            root.notificationsOpen = !root.notificationsOpen
            root.applicationsOpen = false
        }
    }

    ApplicationMenu {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.top: parent.top
        anchors.topMargin: Theme.topBarHeight + 8
        z: 2000
        opened: root.applicationsOpen
        onLaunchApp: function(appId) { root.launchApp(appId) }
    }

    NotificationCenter {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.top: parent.top
        anchors.topMargin: Theme.topBarHeight + 8
        z: 2000
        opened: root.notificationsOpen
        onCycleWallpaper: brain.cycleWallpaper()
        onLaunchApp: function(appId) {
            root.notificationsOpen = false
            root.launchApp(appId)
        }
    }

    Dock {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        z: 1900
        activeApps: root.activeApps
        onLaunchApp: function(appId) { root.launchApp(appId) }
    }

    Shortcut {
        sequence: "Ctrl+Space"
        onActivated: root.applicationsOpen = !root.applicationsOpen
    }

    Timer {
        interval: 2750
        running: qaOpenWindows
        repeat: false
        onTriggered: {
            root.launchApp("files")
            root.launchApp("terminal")
        }
    }
    Shortcut {
        sequence: "Ctrl+Alt+T"
        onActivated: root.launchApp("terminal")
    }
    Shortcut {
        sequence: "Ctrl+B"
        onActivated: root.launchApp("browser")
    }
    Shortcut {
        sequence: "Ctrl+Shift+C"
        onActivated: root.launchApp("calculator")
    }
    Shortcut {
        sequence: "Meta+E"
        onActivated: root.launchApp("files")
    }
    Shortcut {
        sequence: "Escape"
        onActivated: {
            root.applicationsOpen = false
            root.notificationsOpen = false
        }
    }

    Component { id: appWindowComponent; AppWindow {} }
    Component { id: filesPage; FilesPage {} }
    Component { id: terminalPage; TerminalPage {} }
    Component { id: settingsPage; SettingsPage {} }
    Component { id: installerPage; InstallerPage {} }
    Component { id: packagePage; PackageManagerPage {} }
    Component { id: mediaPage; MediaPlayerPage {} }
    Component { id: editorPage; TextEditorPage {} }
    Component { id: imagePage; ImageViewerPage {} }
    Component { id: aboutPage; AboutPage {} }
    Component { id: calculatorPage; CalculatorPage {} }
    Component { id: browserPage; BrowserPage {} }
}
