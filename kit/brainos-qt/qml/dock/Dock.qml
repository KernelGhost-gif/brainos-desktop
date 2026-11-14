import QtQuick
import BrainOS

Item {
    id: root
    property var activeApps: []
    signal launchApp(string appId)

    property var apps: [
        { id: "files", title: "Files", icon: "../assets/icons/folder.svg", color: "#7552D9" },
        { id: "terminal", title: "Terminal", icon: "../assets/icons/terminal.svg", color: "#303849" },
        { id: "settings", title: "Settings", icon: "../assets/icons/settings.svg", color: "#687284" },
        { id: "packages", title: "Packages", icon: "../assets/icons/package.svg", color: "#8B5CF6" },
        { id: "media", title: "Media Player", icon: "../assets/icons/music.svg", color: "#8255D8" },
        { id: "editor", title: "Text Editor", icon: "../assets/icons/editor.svg", color: "#D48B38" },
        { id: "images", title: "Image Viewer", icon: "../assets/icons/image.svg", color: "#3099C5" },
        { id: "about", title: "About", icon: "../assets/icons/info.svg", color: "#348BCB" }
    ]

    width: Math.min(parent ? parent.width - 32 : 720, appRow.implicitWidth + 38)
    height: Theme.dockHeight

    Rectangle {
        anchors.fill: parent
        anchors.margins: -16
        radius: 36
        color: "#52000000"
        opacity: 0.5
        z: -2
    }

    Rectangle {
        anchors.fill: parent
        radius: 26
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#F0262B3B" }
            GradientStop { position: 0.55; color: "#E5141926" }
            GradientStop { position: 1.0; color: "#F00C1019" }
        }
        border.color: Theme.border
        border.width: 1
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 2
        height: 1
        color: "#45FFFFFF"
    }

    Row {
        id: appRow
        anchors.centerIn: parent
        spacing: 7

        Repeater {
            model: root.apps
            delegate: Item {
                id: dockItem
                readonly property bool isOpen: root.activeApps.indexOf(modelData.id) >= 0
                width: dockHover.hovered ? 58 : 48
                height: 58

                AppIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: dockHover.hovered ? 6 : 4
                    width: dockHover.hovered ? 56 : 46
                    height: width
                    source: modelData.icon
                    backgroundColor: modelData.color
                    scale: dockPress.pressed ? 0.88 : 1
                    Behavior on width { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 120 } }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: dockItem.isOpen ? 6 : 0
                    height: 3
                    radius: 2
                    color: Theme.accentLight
                    Behavior on width { NumberAnimation { duration: 140 } }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.top
                    anchors.bottomMargin: 8
                    width: dockLabel.implicitWidth + 18
                    height: 26
                    radius: 8
                    color: "#F21A1F2D"
                    border.color: Theme.border
                    visible: dockHover.hovered
                    Text {
                        id: dockLabel
                        anchors.centerIn: parent
                        text: modelData.title
                        color: Theme.text
                        font.pixelSize: 10
                    }
                }

                HoverHandler {
                    id: dockHover
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    id: dockPress
                    onTapped: root.launchApp(modelData.id)
                }
                Behavior on width { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }
            }
        }

        Rectangle {
            width: 1
            height: 38
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.border
        }

        Item {
            width: 48
            height: 58
            AppIcon {
                anchors.centerIn: parent
                width: 46
                height: 46
                source: "image://brainos-icons/trash"
                backgroundColor: "#58606D"
            }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: system.openPath(system.homePath + "/.local/share/Trash/files") }
        }
    }
}
