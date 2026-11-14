import QtQuick
import QtQuick.Controls
import BrainOS

Item {
    id: root
    property var desktop
    property string currentPath: system.homePath
    property string selectedPath: ""
    property var entries: []

    function refresh() {
        entries = system.listDirectory(currentPath)
        pathField.text = currentPath
    }

    function navigate(path) {
        const resolved = system.resolvePath(path, currentPath)
        if (system.directoryExists(resolved)) {
            currentPath = resolved
            selectedPath = ""
            refresh()
        }
    }

    Component.onCompleted: refresh()

    Rectangle { anchors.fill: parent; color: Theme.surfaceStrong }

    Row {
        anchors.fill: parent

        Rectangle {
            width: Math.min(190, parent.width * 0.27)
            height: parent.height
            color: "#B90F131E"
            border.color: Theme.border

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 4

                Text {
                    text: "Favorites"
                    color: Theme.textDim
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    leftPadding: 8
                    bottomPadding: 6
                }

                Repeater {
                    model: [
                        { name: "Home", path: system.homePath, icon: "../assets/icons/folder.svg" },
                        { name: "Desktop", path: system.homePath + "/Desktop", icon: "../assets/icons/projects.svg" },
                        { name: "Documents", path: system.homePath + "/Documents", icon: "../assets/icons/editor.svg" },
                        { name: "Downloads", path: system.homePath + "/Downloads", icon: "../assets/icons/download.svg" },
                        { name: "Pictures", path: system.homePath + "/Pictures", icon: "../assets/icons/image.svg" },
                        { name: "Music", path: system.homePath + "/Music", icon: "../assets/icons/music.svg" },
                        { name: "Trash", path: system.homePath + "/.local/share/Trash/files", icon: "../assets/icons/trash.svg" }
                    ]
                    delegate: Rectangle {
                        width: parent.width
                        height: 36
                        radius: 9
                        color: sideHover.hovered ? Theme.surfaceHover : "transparent"
                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            spacing: 10
                            Image { anchors.verticalCenter: parent.verticalCenter; width: 15; height: 15; source: modelData.icon }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.name; color: Theme.textMuted; font.pixelSize: 11 }
                        }
                        HoverHandler { id: sideHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: root.navigate(modelData.path) }
                    }
                }
            }
        }

        Column {
            width: parent.width - Math.min(190, parent.width * 0.27)
            height: parent.height

            Rectangle {
                width: parent.width
                height: 48
                color: "#D3171B27"
                border.color: Theme.border

                Row {
                    anchors.fill: parent
                    anchors.margins: 7
                    spacing: 7

                    IconButton {
                        width: 34; height: 34
                        iconSource: "image://brainos-icons/folder"
                        label: "Home"
                        onClicked: root.navigate(system.homePath)
                    }
                    Rectangle {
                        width: 34; height: 34; radius: 9
                        color: upHover.hovered ? Theme.surfaceHover : "transparent"
                        Text { anchors.centerIn: parent; text: "↑"; color: Theme.text; font.pixelSize: 17 }
                        HoverHandler { id: upHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: root.navigate(root.currentPath + "/..") }
                    }
                    TextField {
                        id: pathField
                        width: parent.width - 150
                        height: 34
                        color: Theme.text
                        font.pixelSize: 11
                        selectByMouse: true
                        onAccepted: root.navigate(text)
                        background: Rectangle {
                            radius: 9
                            color: Theme.surfaceRaised
                            border.color: pathField.activeFocus ? Theme.borderStrong : Theme.border
                        }
                    }
                    IconButton {
                        width: 34; height: 34
                        iconSource: "image://brainos-icons/search"
                        label: "Refresh"
                        onClicked: root.refresh()
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: parent.height - 48
                color: "#E00B0F18"

                ListView {
                    id: fileList
                    anchors.fill: parent
                    anchors.margins: 10
                    clip: true
                    spacing: 2
                    model: root.entries

                    header: Row {
                        width: fileList.width
                        height: 28
                        Text { width: parent.width * 0.56; text: "Name"; color: Theme.textDim; font.pixelSize: 10 }
                        Text { width: parent.width * 0.18; text: "Size"; color: Theme.textDim; font.pixelSize: 10 }
                        Text { width: parent.width * 0.26; text: "Modified"; color: Theme.textDim; font.pixelSize: 10 }
                    }

                    delegate: Rectangle {
                        width: fileList.width
                        height: 42
                        radius: 9
                        color: root.selectedPath === modelData.path ? "#3D8B5CF6"
                              : fileHover.hovered ? Theme.surfaceHover : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8
                            AppIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 28
                                height: 28
                                source: modelData.isDir ? "../assets/icons/folder.svg"
                                      : (["png", "jpg", "jpeg", "webp", "svg"].indexOf(modelData.suffix) >= 0
                                         ? "../assets/icons/image.svg" : "../assets/icons/editor.svg")
                                backgroundColor: modelData.isDir ? "#7150D0" : "#344255"
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * 0.56 - 36
                                text: modelData.name
                                color: Theme.text
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * 0.18
                                text: modelData.isDir ? "Folder" : Math.max(1, Math.round(modelData.size / 1024)) + " KB"
                                color: Theme.textMuted
                                font.pixelSize: 10
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * 0.24
                                text: modelData.modified
                                color: Theme.textDim
                                font.pixelSize: 10
                            }
                        }
                        HoverHandler { id: fileHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                root.selectedPath = modelData.path
                                if (modelData.isDir)
                                    root.navigate(modelData.path)
                            }
                            onDoubleTapped: {
                                if (modelData.isDir)
                                    root.navigate(modelData.path)
                                else
                                    system.openPath(modelData.path)
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.entries.length === 0
                        text: "This folder is empty"
                        color: Theme.textDim
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
