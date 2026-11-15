import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BrainOS

SectionCard {
    id: root
    signal cycleWallpaper()
    signal launchApp(string appId)
    implicitHeight: 236
    depth: 1.0

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space3

        Text {
            text: "Quick Settings"
            color: Theme.text
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: Theme.space2
            columnSpacing: Theme.space2

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 74
                radius: 16
                color: Theme.surfaceRaised
                border.color: Theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space3
                    spacing: Theme.space3

                    AppIcon {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        source: "image://brainos-icons/wifi"
                        backgroundColor: systemState.wifiEnabled ? Theme.green : "#354052"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: systemState.wifiEnabled ? "Wi-Fi on" : "Wi-Fi off"
                            color: Theme.text
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: systemState.wifiSsid.length ? systemState.wifiSsid : "No network connected"
                            color: Theme.textMuted
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }

                    Switch {
                        checked: systemState.wifiEnabled
                        onToggled: systemState.setWifiEnabled(checked)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 74
                radius: 16
                color: Theme.surfaceRaised
                border.color: Theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space3
                    spacing: Theme.space3

                    AppIcon {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        source: "image://brainos-icons/" + (systemState.audioMuted ? "mute" : "volume")
                        backgroundColor: systemState.audioMuted ? Theme.red : Theme.accent
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: systemState.audioMuted ? "Muted" : "Audio"
                            color: Theme.text
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: systemState.audioVolume + "%"
                            color: Theme.textMuted
                            font.pixelSize: 10
                        }
                    }

                    Switch {
                        checked: !systemState.audioMuted
                        onToggled: systemState.toggleMute()
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space2

            Button { text: "Browser"; onClicked: root.launchApp("browser") }
            Button { text: "Calculator"; onClicked: root.launchApp("calculator") }
            Button { text: "Store"; onClicked: root.launchApp("store") }
            Item { Layout.fillWidth: true }
            Button { text: "Wallpaper"; onClicked: root.cycleWallpaper() }
        }
    }
}
