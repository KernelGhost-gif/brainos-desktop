import QtQuick
import QtQuick.Controls
import BrainOS

Rectangle {
    id: root
    property url iconSource
    property string label: ""
    property bool checked: false
    property color iconColor: Theme.text
    signal clicked()

    implicitWidth: 34
    implicitHeight: 34
    radius: 10
    color: checked ? Qt.rgba(0.55, 0.36, 0.96, 0.28)
                   : hover.hovered ? Theme.surfaceHover : "transparent"
    border.color: checked ? Theme.borderStrong : "transparent"

    Image {
        anchors.centerIn: parent
        width: 18
        height: 18
        source: root.iconSource
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.clicked()
    }

    ToolTip.visible: hover.hovered && label.length > 0
    ToolTip.text: label
    ToolTip.delay: 500

    Behavior on color { ColorAnimation { duration: 120 } }
}
