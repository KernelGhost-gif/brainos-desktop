import QtQuick
import QtQuick.Controls
import BrainOS

Item {
    id: root
    property var desktop
    property string logText: ""
    property bool busy: false

    function installPackage(name) {
        packageField.text = name
        logText = ""
        busy = true
        system.installPackage(name)
    }

    Connections {
        target: system
        function onCommandOutput(requestId, text) { root.logText += text }
        function onCommandFinished(requestId, exitCode) {
            root.busy = false
            root.logText += exitCode === 0 ? "\nPackage operation completed.\n" : "\nPackage operation failed with code " + exitCode + ".\n"
        }
    }

    Rectangle { anchors.fill: parent; color: Theme.surfaceStrong }

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 13

        Row {
            width: parent.width
            Text {
                text: "Package Manager"
                color: Theme.text
                font.pixelSize: 22
                font.weight: Font.DemiBold
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "Backend: " + system.packageBackend
                color: Theme.textDim
                font.pixelSize: 10
            }
        }

        Row {
            width: parent.width
            spacing: 9
            TextField {
                id: packageField
                width: parent.width - 130
                height: 40
                placeholderText: "Package name or Flatpak application ID"
                placeholderTextColor: Theme.textDim
                color: Theme.text
                font.pixelSize: 11
                onAccepted: root.installPackage(text)
                background: Rectangle {
                    radius: 11
                    color: Theme.surfaceRaised
                    border.color: packageField.activeFocus ? Theme.borderStrong : Theme.border
                }
            }
            Button {
                width: 120
                height: 40
                text: root.busy ? "Working…" : "Install"
                enabled: !root.busy && packageField.text.trim().length > 0
                onClicked: root.installPackage(packageField.text.trim())
            }
        }

        Text { text: "Common tools"; color: Theme.textMuted; font.pixelSize: 11; font.weight: Font.DemiBold }

        Flow {
            width: parent.width
            spacing: 9
            Repeater {
                model: [
                    { name: "Firefox", package: "firefox", icon: "🌐" },
                    { name: "VLC", package: "vlc", icon: "▶" },
                    { name: "GIMP", package: "gimp", icon: "◉" },
                    { name: "Git", package: "git", icon: "⑂" },
                    { name: "Python", package: "python3", icon: "⌁" },
                    { name: "LibreOffice", package: "libreoffice", icon: "▤" }
                ]
                delegate: SectionCard {
                    width: (parent.width - 18) / 3
                    height: 82
                    Row {
                        anchors.fill: parent
                        anchors.margins: 11
                        spacing: 10
                        Rectangle {
                            width: 42; height: 42; radius: 12; color: "#4B8B5CF6"
                            Text { anchors.centerIn: parent; text: modelData.icon; color: "white"; font.pixelSize: 19 }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            Text { text: modelData.name; color: Theme.text; font.pixelSize: 11; font.weight: Font.DemiBold }
                            Text { text: "Install"; color: Theme.accentLight; font.pixelSize: 10 }
                        }
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.installPackage(modelData.package) }
                }
            }
        }

        SectionCard {
            width: parent.width
            height: parent.height - 302
            visible: root.busy || root.logText.length > 0
            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 7
                Row {
                    spacing: 8
                    BusyIndicator { width: 18; height: 18; running: root.busy }
                    Text { text: "Package output"; color: Theme.text; font.pixelSize: 11; font.weight: Font.DemiBold }
                }
                TextArea {
                    width: parent.width
                    height: parent.height - 28
                    readOnly: true
                    text: root.logText
                    color: Theme.textMuted
                    font.family: Theme.monoFont
                    font.pixelSize: 10
                    wrapMode: TextEdit.WrapAnywhere
                    background: Rectangle { radius: 8; color: "#66000000" }
                }
            }
        }
    }
}
