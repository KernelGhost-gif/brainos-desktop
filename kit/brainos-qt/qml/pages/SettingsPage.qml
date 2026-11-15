import QtQuick
import QtQuick.Controls
import BrainOS

Item {
    id: root
    property var desktop

    Rectangle {
        anchors.fill: parent
        color: Theme.surfaceStrong
    }

    Flickable {
        anchors.fill: parent
        contentHeight: settingsColumn.height + 36
        clip: true

        Column {
            id: settingsColumn
            x: 20
            y: 18
            width: parent.width - 40
            spacing: 14

            Text {
                text: "Appearance"
                color: Theme.text
                font.pixelSize: 22
                font.weight: Font.DemiBold
            }

            Text {
                text: "Choose a wallpaper and tune the desktop presentation."
                color: Theme.textMuted
                font.pixelSize: 12
            }

            SectionCard {
                width: parent.width
                height: 190

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    Text {
                        text: "Wallpaper"
                        color: Theme.text
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    Row {
                        width: parent.width
                        spacing: 12

                        Repeater {
                            model: [
                                { name: "Aurora", source: "../assets/wallpapers/aurora.svg" },
                                { name: "Horizon", source: "../assets/wallpapers/horizon.svg" },
                                { name: "Glass", source: "../assets/wallpapers/glass.svg" }
                            ]

                            delegate: Item {
                                width: (parent.width - 24) / 3
                                height: 128

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 12
                                    color: Theme.surfaceRaised
                                    border.width: brain.wallpaperIndex === index ? 2 : 1
                                    border.color: brain.wallpaperIndex === index
                                                  ? Theme.accentLight
                                                  : Theme.border

                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        source: modelData.source
                                        fillMode: Image.PreserveAspectCrop
                                    }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.bottom: parent.bottom
                                        anchors.margins: 9
                                        text: modelData.name
                                        color: "white"
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                    }
                                }

                                HoverHandler {
                                    cursorShape: Qt.PointingHandCursor
                                }

                                TapHandler {
                                    onTapped: brain.wallpaperIndex = index
                                }
                            }
                        }
                    }
                }
            }

            SectionCard {
                width: parent.width
                height: 210

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 4

                    Text {
                        text: "Desktop"
                        color: Theme.text
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        bottomPadding: 6
                    }

                    Repeater {
                        model: [
                            {
                                title: "Animations",
                                subtitle: "Window, dock, menu, and workspace motion",
                                key: "animations"
                            },
                            {
                                title: "Desktop widgets",
                                subtitle: "Clock, weather, performance, music, and notes",
                                key: "widgets"
                            },
                            {
                                title: "Translucent surfaces",
                                subtitle: "Glass treatment for shell panels and windows",
                                key: "translucency"
                            }
                        ]

                        delegate: Rectangle {
                            width: parent.width
                            height: 52
                            color: "transparent"

                            Column {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: modelData.title
                                    color: Theme.text
                                    font.pixelSize: 11
                                }

                                Text {
                                    text: modelData.subtitle
                                    color: Theme.textDim
                                    font.pixelSize: 9
                                }
                            }

                            Switch {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter

                                checked: modelData.key === "animations"
                                         ? brain.animationsEnabled
                                         : modelData.key === "widgets"
                                           ? brain.widgetsEnabled
                                           : brain.translucencyEnabled

                                onToggled: {
                                    if (modelData.key === "animations")
                                        brain.animationsEnabled = checked
                                    else if (modelData.key === "widgets")
                                        brain.widgetsEnabled = checked
                                    else
                                        brain.translucencyEnabled = checked
                                }
                            }
                        }
                    }
                }
            }

            SectionCard {
                width: parent.width
                height: 110

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 7

                    Text {
                        text: "Display"
                        color: Theme.text
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: "The shell scales from 1366×768 through 4K and ultrawide outputs."
                        color: Theme.textMuted
                        font.pixelSize: 11
                    }

                    Text {
                        text: "Qt Wayland compositor output • responsive desktop layout"
                        color: Theme.textDim
                        font.pixelSize: 10
                    }
                }
            }
        }
    }
}
