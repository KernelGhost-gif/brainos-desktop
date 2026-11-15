import QtQuick
import BrainOS

Rectangle {
    id: root

    property string activeTitle: "Desktop"
    property bool notificationsOpen: false

    signal applicationsClicked()
    signal notificationsClicked()
    signal quickSettingsClicked()

    height: Theme.topBarHeight
    color: "#E6070911"
    border.color: "#18FFFFFF"

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Row {
            width: 104
            height: 30
            spacing: 7

            Image {
                anchors.verticalCenter: parent.verticalCenter
                width: 23
                height: 23
                source: "../assets/brainos-mark.svg"
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "BrainOS"
                color: Theme.text
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
        }

        Rectangle {
            width: 1
            height: 20
            color: Theme.border
        }

        Rectangle {
            width: 124
            height: 30
            radius: 9
            color: appHover.hovered ? Theme.surfaceHover : "transparent"

            Row {
                anchors.centerIn: parent
                spacing: 8

                Image {
                    width: 15
                    height: 15
                    source: "image://brainos-icons/apps"
                }

                Text {
                    text: "Applications"
                    color: Theme.text
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
            }

            HoverHandler {
                id: appHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: root.applicationsClicked()
            }
        }

        Rectangle {
            width: Math.min(150, titleText.implicitWidth + 26)
            height: 30
            radius: 9
            color: Theme.surface

            Text {
                id: titleText
                anchors.centerIn: parent
                text: root.activeTitle
                color: Theme.textMuted
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: brain.dateText
            color: Theme.textMuted
            font.pixelSize: 11
        }

        Text {
            text: brain.clockText
            color: Theme.text
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        IconButton {
            iconSource: "image://brainos-icons/bell"
            label: "Notifications"
            checked: root.notificationsOpen
            onClicked: root.notificationsClicked()
        }

        IconButton {
            iconSource: "image://brainos-icons/wifi"
            label: "Network"
            onClicked: root.quickSettingsClicked()
        }

        IconButton {
            iconSource: "image://brainos-icons/volume"
            label: "Sound"
            onClicked: root.quickSettingsClicked()
        }

        IconButton {
            implicitWidth: 54
            iconSource: "image://brainos-icons/battery"
            label: system.batteryLevel >= 0
                   ? "Battery " + system.batteryLevel + "%"
                   : "No battery detected"
            onClicked: root.quickSettingsClicked()

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                text: system.batteryLevel >= 0
                      ? system.batteryLevel + "%"
                      : "AC"
                color: Theme.textMuted
                font.pixelSize: 10
            }
        }

        AppIcon {
            width: 30
            height: 30
            source: "image://brainos-icons/user"
            backgroundColor: "#5A5B3BA8"

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }
    }
}
