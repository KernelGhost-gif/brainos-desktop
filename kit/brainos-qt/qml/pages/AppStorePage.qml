import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BrainOS

SectionCard {
    id: root
    signal installApp(string appId)
    implicitHeight: 540
    depth: 1.1

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space4

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space3

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "Brain Store"
                    color: Theme.text
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "Curated apps for BrainOS"
                    color: Theme.textMuted
                    font.pixelSize: 11
                }
            }

            TextField {
                Layout.preferredWidth: 190
                placeholderText: "Search apps"
                background: Rectangle {
                    radius: 14
                    color: "#0A0D13"
                    border.color: Theme.border
                }
                leftPadding: Theme.space3
                rightPadding: Theme.space3
                topPadding: Theme.space2
                bottomPadding: Theme.space2
            }
        }

        GridView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: 210
            cellHeight: 132
            model: [
                { id: "browser", title: "Browser", desc: "Open web pages", icon: "browser" },
                { id: "files", title: "Files", desc: "Browse your system", icon: "files" },
                { id: "terminal", title: "Terminal", desc: "Run commands", icon: "terminal" },
                { id: "settings", title: "Settings", desc: "Configure BrainOS", icon: "settings" },
                { id: "calculator", title: "Calculator", desc: "Do quick math", icon: "calculator" },
                { id: "store", title: "App Store", desc: "Install BrainOS apps", icon: "store" }
            ]

            delegate: Rectangle {
                width: 198
                height: 120
                radius: 18
                color: Theme.surfaceRaised
                border.color: Theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space4
                    spacing: Theme.space3

                    AppIcon {
                        Layout.preferredWidth: 52
                        Layout.preferredHeight: 52
                        source: "image://brainos-icons/" + modelData.icon
                        backgroundColor: Theme.wallpaperAccent(brain.wallpaperIndex)
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: modelData.title
                            color: Theme.text
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: modelData.desc
                            color: Theme.textMuted
                            font.pixelSize: 10
                            wrapMode: Text.Wrap
                        }

                        Item { Layout.fillHeight: true }

                        Button {
                            text: "Install"
                            onClicked: root.installApp(modelData.id)
                        }
                    }
                }
            }
        }
    }
}
