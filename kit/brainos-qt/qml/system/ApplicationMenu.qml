import QtQuick
import QtQuick.Controls
import BrainOS

Item {
    id: root
    property bool opened: false
    signal launchApp(string appId)

    width: Math.min(520, parent ? parent.width - 24 : 520)
    height: Math.min(460, parent ? parent.height - 90 : 460)
    visible: opacity > 0
    opacity: opened ? 1 : 0
    scale: opened ? 1 : 0.97
    transformOrigin: Item.TopLeft

    property var apps: [
        { id: "files", title: "Files", subtitle: "Browse your computer", icon: "../assets/icons/folder.svg", color: "#7552D9" },
        { id: "terminal", title: "Terminal", subtitle: "Command line", icon: "../assets/icons/terminal.svg", color: "#303849" },
        { id: "settings", title: "Settings", subtitle: "Personalize BrainOS", icon: "../assets/icons/settings.svg", color: "#677184" },
        { id: "installer", title: "Installer", subtitle: "Install local apps", icon: "../assets/icons/download.svg", color: "#2AAFD5" },
        { id: "packages", title: "Package Manager", subtitle: "Linux software", icon: "../assets/icons/package.svg", color: "#8B5CF6" },
        { id: "media", title: "Media Player", subtitle: "Play audio and video", icon: "../assets/icons/music.svg", color: "#8255D8" },
        { id: "editor", title: "Text Editor", subtitle: "Edit plain text", icon: "../assets/icons/editor.svg", color: "#D48B38" },
        { id: "images", title: "Image Viewer", subtitle: "View local images", icon: "../assets/icons/image.svg", color: "#3099C5" },
        { id: "about", title: "About", subtitle: "System information", icon: "../assets/icons/info.svg", color: "#348BCB" },
        { id: "calculator", title: "Calculator", subtitle: "Quick arithmetic", icon: "../assets/icons/calculator.svg", color: "#7C5CE0" },
        { id: "browser", title: "Web Browser", subtitle: "Browse the web", icon: "../assets/icons/browser.svg", color: "#2996C8" }
    ]

    function submitSearch() {
        const value = searchField.text.trim()
        if (value.length === 0)
            return
        var partialMatch = -1
        for (let i = 0; i < apps.length; ++i) {
            var title = apps[i].title.toLowerCase()
            if (title === value.toLowerCase()) {
                opened = false
                launchApp(apps[i].id)
                return
            }
            if (title.indexOf(value.toLowerCase()) >= 0) {
                if (partialMatch >= 0) {
                    partialMatch = -2
                    break
                }
                partialMatch = i
            }
        }
        if (partialMatch >= 0) {
            opened = false
            launchApp(apps[partialMatch].id)
            return
        }
        if (system.pathExists(value)) {
            system.openPath(value)
            opened = false
        }
    }

    Rectangle { anchors.fill: parent; radius: 20; color: "#F40D111B"; border.color: Theme.border }

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        Text { text: "Applications"; color: Theme.text; font.pixelSize: 19; font.weight: Font.DemiBold }

        TextField {
            id: searchField
            width: parent.width
            height: 38
            placeholderText: "Search applications"
            placeholderTextColor: Theme.textDim
            color: Theme.text
            leftPadding: 38
            font.pixelSize: 12
            onAccepted: root.submitSearch()
            background: Rectangle {
                radius: 11
                color: Theme.surfaceRaised
                border.color: searchField.activeFocus ? Theme.borderStrong : Theme.border
            }
            Image {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 16
                source: "image://brainos-icons/search"
            }
        }

        Flickable {
            width: parent.width
            height: parent.height - 104
            contentHeight: appFlow.height
            clip: true
            Flow {
                id: appFlow
                width: parent.width
                spacing: 10
                Repeater {
                    model: root.apps
                    delegate: Rectangle {
                        visible: searchField.text.length === 0
                                 || modelData.title.toLowerCase().includes(searchField.text.toLowerCase())
                        width: (appFlow.width - 10) / 2
                        height: visible ? 70 : 0
                        radius: 13
                        color: menuHover.hovered ? Theme.surfaceHover : "transparent"
                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 11
                            AppIcon { width: 46; height: 46; source: modelData.icon; backgroundColor: modelData.color }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 60
                                spacing: 3
                                Text { width: parent.width; text: modelData.title; color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold; elide: Text.ElideRight }
                                Text { width: parent.width; text: modelData.subtitle; color: Theme.textMuted; font.pixelSize: 10; elide: Text.ElideRight }
                            }
                        }
                        HoverHandler { id: menuHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: { root.opened = false; root.launchApp(modelData.id) } }
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                width: parent.width - 28
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                visible: searchField.text.trim().length > 0
                         && !root.apps.some(function(app) { return app.title.toLowerCase().indexOf(searchField.text.trim().toLowerCase()) >= 0 })
                text: "No applications match “" + searchField.text.trim() + "”."
                color: Theme.textMuted
                font.pixelSize: 12
            }
        }
    }
    onOpenedChanged: { if (opened) { searchField.text = ""; searchField.forceActiveFocus() } }
    Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
}
