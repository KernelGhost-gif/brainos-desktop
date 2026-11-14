import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property var apps: [
        { title: "Files", icon: "../assets/icons/folder.svg", page: "files" },
        { title: "Terminal", icon: "../assets/icons/terminal.svg", page: "terminal" },
        { title: "Settings", icon: "../assets/icons/settings.svg", page: "settings" },
        { title: "Installer", icon: "../assets/icons/download.svg", page: "installer" },
        { title: "About", icon: "../assets/icons/info.svg", page: "about" }
    ]

    Rectangle {
        anchors.fill: parent
        radius: 18
        color: "#0f1723"
        opacity: 0.96
        border.color: "#2a3a50"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        Text {
            text: "Applications"
            color: "#f2f6fb"
            font.pixelSize: 28
            font.bold: true
        }

        Text {
            text: "Open an app from here or from the dock below."
            color: "#9db0c7"
            font.pixelSize: 15
        }

        GridView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: 130
            cellHeight: 130
            model: root.apps

            delegate: Item {
                width: 120
                height: 120

                Rectangle {
                    anchors.fill: parent
                    radius: 22
                    color: "#162131"
                    border.color: "#2e3f56"
                    opacity: 0.98
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Image {
                        source: modelData.icon
                        width: 44
                        height: 44
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    Text {
                        text: modelData.title
                        color: "#f1f5fb"
                        font.pixelSize: 14
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        width: 100
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: rootWindow.activePage = modelData.page
                }
            }
        }
    }
}
