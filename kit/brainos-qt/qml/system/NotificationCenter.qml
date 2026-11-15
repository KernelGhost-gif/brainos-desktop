import QtQuick
import QtQuick.Layouts
import BrainOS

SectionCard {
    id: root
    property bool opened: false
    signal cycleWallpaper()
    signal launchApp(string appId)

    width: Math.min(356, parent ? parent.width - 24 : 356)
    height: Math.min(520, parent ? parent.height - Theme.topBarHeight - 24 : 520)
    visible: opacity > 0
    opacity: opened ? 1 : 0
    scale: opened ? 1 : 0.97
    transformOrigin: Item.TopRight
    depth: 1.0

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space3

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space2

            Text {
                Layout.fillWidth: true
                text: "Notifications"
                color: Theme.text
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

            IconButton {
                width: 28
                height: 28
                iconSource: "image://brainos-icons/close"
                label: "Close"
                onClicked: root.opened = false
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 76
            radius: 16
            color: Theme.surfaceRaised
            border.color: Theme.border

            Column {
                anchors.centerIn: parent
                spacing: 6

                AppIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 34
                    height: 34
                    source: "image://brainos-icons/bell"
                    backgroundColor: "#354052"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No new notifications"
                    color: Theme.textMuted
                    font.pixelSize: 11
                }
            }
        }

        QuickSettings {
            Layout.fillWidth: true
            onCycleWallpaper: root.cycleWallpaper()
            onLaunchApp: function(appId) { root.launchApp(appId) }
        }

        ClockCalendarWidget {
            Layout.fillWidth: true
            clockText: brain.clockText
            dateText: brain.dateText
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: brain.animationsEnabled ? Theme.motionFast : 0
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: brain.animationsEnabled ? Theme.motionFast : 0
            easing.type: Easing.OutCubic
        }
    }
}
