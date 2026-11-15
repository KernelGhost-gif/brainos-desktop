import QtQuick
import QtQuick.Controls

Item {
    id: root
    property string activePage: "home"
    signal launchPage(string pageId)
    signal openHome()

    width: Math.min(parent ? parent.width - 40 : 1200, 860)
    height: 74

    Rectangle {
        anchors.fill: parent
        radius: 23
        color: "#0f1621"
        border.color: "#2c3b52"
        opacity: 0.95
    }

    Row {
        anchors.centerIn: parent
        spacing: 10

        Repeater {
            model: [
                { id: "home", title: "Home" },
                { id: "files", title: "Files" },
                { id: "terminal", title: "Terminal" },
                { id: "settings", title: "Settings" },
                { id: "installer", title: "Installer" },
                { id: "about", title: "About" }
            ]

            delegate: Rectangle {
                width: 116
                height: 46
                radius: 18
                color: root.activePage === modelData.id ? "#e8f1ff" : "#182232"
                border.color: root.activePage === modelData.id ? "#ffffff" : "#2e3e55"

                Text {
                    anchors.centerIn: parent
                    text: modelData.title
                    color: root.activePage === modelData.id ? "#081120" : "#eaf1f8"
                    font.pixelSize: 14
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (modelData.id === "home")
                            root.openHome()
                        else
                            root.launchPage(modelData.id)
                    }
                }
            }
        }
    }
}
