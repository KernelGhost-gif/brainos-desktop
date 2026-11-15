import QtQuick
import BrainOS

Rectangle {
    id: root
    property real depth: 1

    default property alias contentData: body.data

    color: "transparent"
    radius: Theme.panelRadius
    border.color: Theme.border
    border.width: 1
    clip: true

    Rectangle {
        anchors.fill: parent
        anchors.margins: -Math.round(8 * root.depth)
        radius: root.radius + Math.round(10 * root.depth)
        color: "#3A000000"
        opacity: 0.45
        z: -2
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: brain.translucencyEnabled ? "#F01B2030" : "#FF1B2030" }
            GradientStop { position: 0.6; color: brain.translucencyEnabled ? "#E3131825" : "#FF131825" }
            GradientStop { position: 1.0; color: brain.translucencyEnabled ? "#F00E121C" : "#FF0E121C" }
        }
        z: -1
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 1
        height: 1
        radius: 1
        color: "#28FFFFFF"
    }

    Item {
        id: body
        anchors.fill: parent
        anchors.margins: Theme.space4
        clip: true
        z: 1
    }
}
