import QtQuick
import QtQuick.Controls
import BrainOS

Item {
    id: root
    property var desktop
    property bool playing: false

    Rectangle { anchors.fill: parent; color: "#090C13" }

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        Rectangle {
            width: parent.width
            height: parent.height - 120
            radius: 16
            gradient: Gradient {
                GradientStop { position: 0; color: "#241B43" }
                GradientStop { position: 1; color: "#0B1727" }
            }
            Text {
                anchors.centerIn: parent
                text: "♫"
                color: "#D5C5FF"
                font.pixelSize: 86
                opacity: 0.8
            }
        }

        Row {
            width: parent.width
            spacing: 9
            TextField {
                id: mediaPath
                width: parent.width - 132
                height: 38
                placeholderText: system.homePath + "/Music/track.mp3"
                placeholderTextColor: Theme.textDim
                color: Theme.text
                font.pixelSize: 11
                selectByMouse: true
                background: Rectangle { radius: 10; color: Theme.surfaceRaised; border.color: Theme.border }
            }
            Button {
                width: 122
                height: 38
                text: "Open media"
                onClicked: system.openPath(mediaPath.text)
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 22
            Text { text: "‹"; color: Theme.text; font.pixelSize: 24 }
            Text {
                text: root.playing ? "Ⅱ" : "▶"
                color: Theme.text
                font.pixelSize: 22
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -10
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.playing = !root.playing
                }
            }
            Text { text: "›"; color: Theme.text; font.pixelSize: 24 }
        }
    }
}
