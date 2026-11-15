import QtQuick
import BrainOS

Rectangle {
    id: root
    property url source
    property color tint: Theme.text
    property color backgroundColor: Theme.surfaceRaised
    property real iconScale: 0.5

    radius: width * 0.27
    color: backgroundColor
    border.color: Theme.border
    border.width: 1

    Image {
        anchors.centerIn: parent
        width: parent.width * root.iconScale
        height: width
        source: root.source
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }
}
