import QtQuick
import QtQuick.Controls
import BrainOS

Item {
    id: root
    property var desktop
    property real zoom: 1

    Rectangle { anchors.fill: parent; color: "#080A0F" }

    Column {
        anchors.fill: parent

        Rectangle {
            width: parent.width
            height: 46
            color: "#171B27"
            border.color: Theme.border
            Row {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 8
                TextField {
                    id: imagePath
                    width: parent.width - 204
                    height: 34
                    placeholderText: system.homePath + "/Pictures/image.png"
                    placeholderTextColor: Theme.textDim
                    color: Theme.text
                    font.pixelSize: 10
                    selectByMouse: true
                    background: Rectangle { radius: 9; color: Theme.surfaceRaised; border.color: Theme.border }
                    onAccepted: image.source = system.fileUrl(text)
                }
                Button { width: 72; height: 34; text: "Open"; onClicked: image.source = system.fileUrl(imagePath.text) }
                Button { width: 50; height: 34; text: "−"; onClicked: root.zoom = Math.max(0.25, root.zoom - 0.25) }
                Button { width: 50; height: 34; text: "+"; onClicked: root.zoom = Math.min(4, root.zoom + 0.25) }
            }
        }

        Flickable {
            width: parent.width
            height: parent.height - 46
            contentWidth: Math.max(width, image.implicitWidth * root.zoom)
            contentHeight: Math.max(height, image.implicitHeight * root.zoom)
            clip: true

            Image {
                id: image
                anchors.centerIn: parent
                width: implicitWidth * root.zoom
                height: implicitHeight * root.zoom
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }

            Text {
                anchors.centerIn: parent
                visible: image.status !== Image.Ready
                text: image.status === Image.Error ? "Could not load image" : "Enter an image path"
                color: Theme.textDim
                font.pixelSize: 12
            }
        }
    }
}
