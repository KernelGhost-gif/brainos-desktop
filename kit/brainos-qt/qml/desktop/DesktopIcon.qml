import QtQuick
import BrainOS

Item {
    id: root
    property string title
    property string appId
    property url iconSource
    property color iconColor: Theme.accent
    signal launched(string appId)

    width: 84
    height: 88
    scale: hover.hovered ? 1.04 : 1

    Rectangle {
        anchors.fill: parent
        radius: 13
        color: hover.hovered ? "#28FFFFFF" : "transparent"
        border.color: hover.hovered ? Theme.border : "transparent"
    }

    Column {
        anchors.centerIn: parent
        spacing: 7

        AppIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 48
            height: 48
            source: root.iconSource
            backgroundColor: Qt.tint(Theme.surfaceRaised, Qt.rgba(root.iconColor.r, root.iconColor.g, root.iconColor.b, 0.34))
        }

        Text {
            width: 80
            text: root.title
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: 12
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            style: Text.Outline
            styleColor: "#90000000"
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        onTapped: root.launched(root.appId)
    }

    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
}
