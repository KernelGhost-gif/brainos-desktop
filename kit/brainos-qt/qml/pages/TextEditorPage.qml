import QtQuick
import QtQuick.Controls
import BrainOS

Item {
    id: root
    property var desktop
    property string filePath: system.homePath + "/Documents/untitled.txt"
    property string status: "Ready"

    function loadFile() {
        editor.text = system.readTextFile(pathField.text)
        filePath = system.resolvePath(pathField.text)
        status = editor.text.length > 0 ? "Loaded" : "New or empty file"
    }
    function saveFile() {
        filePath = system.resolvePath(pathField.text)
        status = system.writeTextFile(filePath, editor.text) ? "Saved" : "Could not save"
    }

    Rectangle { anchors.fill: parent; color: Theme.surfaceStrong }

    Column {
        anchors.fill: parent

        Rectangle {
            width: parent.width
            height: 46
            color: "#D3181C28"
            border.color: Theme.border
            Row {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 8
                TextField {
                    id: pathField
                    width: parent.width - 190
                    height: 34
                    text: root.filePath
                    color: Theme.text
                    font.pixelSize: 10
                    selectByMouse: true
                    background: Rectangle { radius: 9; color: Theme.surfaceRaised; border.color: Theme.border }
                }
                Button { width: 80; height: 34; text: "Open"; onClicked: root.loadFile() }
                Button { width: 80; height: 34; text: "Save"; onClicked: root.saveFile() }
            }
        }

        TextArea {
            id: editor
            width: parent.width
            height: parent.height - 70
            color: Theme.text
            selectionColor: Theme.accent
            selectedTextColor: "white"
            font.family: Theme.monoFont
            font.pixelSize: 12
            wrapMode: TextEdit.Wrap
            selectByMouse: true
            leftPadding: 18
            rightPadding: 18
            topPadding: 16
            bottomPadding: 16
            background: Rectangle { color: "#0B0F17" }
        }

        Rectangle {
            width: parent.width
            height: 24
            color: "#171B27"
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: root.status + "  •  " + editor.length + " characters"
                color: Theme.textDim
                font.pixelSize: 9
            }
        }
    }
}
