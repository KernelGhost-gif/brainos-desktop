import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    property string clockText: ""
    property string dateText: ""
    property bool desktopReady: true
    signal launchPage(string pageId)

    height: 52
    color: "#111827"
    opacity: 0.90
    border.color: "#223044"
    border.width: 0

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Rectangle {
            width: 132
            height: 30
            radius: 15
            color: "#172231"
            border.color: "#2b3a50"

            Text {
                anchors.centerIn: parent
                text: "Activities"
                color: "#eaf1f8"
                font.pixelSize: 14
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.launchPage("home")
            }
        }

        Rectangle {
            width: 146
            height: 30
            radius: 15
            color: "#172231"
            border.color: "#2b3a50"

            Text {
                anchors.centerIn: parent
                text: desktopReady ? "BrainOS Desktop" : "Booting…"
                color: "#cfdbe8"
                font.pixelSize: 13
            }
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.clockText
            color: "#f3f7fb"
            font.pixelSize: 18
            font.bold: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.dateText
            color: "#a7b6c6"
            font.pixelSize: 11
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Rectangle {
            width: 104
            height: 30
            radius: 15
            color: "#172231"
            border.color: "#2b3a50"
            Text {
                anchors.centerIn: parent
                text: "Wi-Fi"
                color: "#cfdbe8"
                font.pixelSize: 13
            }
        }

        Rectangle {
            width: 104
            height: 30
            radius: 15
            color: "#172231"
            border.color: "#2b3a50"
            Text {
                anchors.centerIn: parent
                text: "Sound"
                color: "#cfdbe8"
                font.pixelSize: 13
            }
        }

        Rectangle {
            width: 104
            height: 30
            radius: 15
            color: "#172231"
            border.color: "#2b3a50"
            Text {
                anchors.centerIn: parent
                text: "Power"
                color: "#cfdbe8"
                font.pixelSize: 13
            }
        }
    }
}
