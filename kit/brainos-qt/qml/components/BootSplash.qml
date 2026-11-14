import QtQuick
import BrainOS

Item {
    id: root
    property bool running: true
    property string message: "Preparing BrainOS"
    property int sequenceStep: 0
    visible: opacity > 0
    opacity: running ? 1 : 0
    z: 10000
    Rectangle { anchors.fill: parent; color: "#05060A" }
    Timer { interval: 540; running: root.running && root.sequenceStep < 3; repeat: true; onTriggered: root.sequenceStep += 1 }
    Rectangle {
        anchors.centerIn: parent; width: 190; height: 190; radius: 105; color: "#248B5CF6"; opacity: 0.5
        scale: root.sequenceStep >= 1 ? 1 : 0.82
        SequentialAnimation on opacity { running: root.running; loops: Animation.Infinite; NumberAnimation { to: 0.26; duration: 1200; easing.type: Easing.InOutSine }; NumberAnimation { to: 0.5; duration: 1200; easing.type: Easing.InOutSine } }
    }
    Column {
        anchors.centerIn: parent; spacing: 18
        Image {
            anchors.horizontalCenter: parent.horizontalCenter; width: 96; height: 96
            source: "../assets/brainos-mark.svg"; fillMode: Image.PreserveAspectFit; smooth: true
            opacity: root.sequenceStep >= 1 ? 1 : 0; scale: root.sequenceStep >= 1 ? 1 : 0.76
            Behavior on opacity { NumberAnimation { duration: 300 } }
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
        }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.message; color: Theme.textMuted; font.family: Theme.uiFont; font.pixelSize: 13; font.weight: Font.Medium; opacity: root.sequenceStep >= 2 ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 220 } } }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter; spacing: 7; opacity: root.sequenceStep >= 3 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 220 } }
            Repeater {
                model: 3
                delegate: Rectangle {
                    width: 6; height: 6; radius: 3; color: Theme.accentLight; opacity: 0.25
                    SequentialAnimation on opacity { running: root.running; loops: Animation.Infinite; PauseAnimation { duration: index * 170 }; NumberAnimation { to: 1; duration: 260; easing.type: Easing.OutSine }; NumberAnimation { to: 0.25; duration: 520; easing.type: Easing.InSine }; PauseAnimation { duration: (2-index)*170 } }
                }
            }
        }
    }
    Behavior on opacity { NumberAnimation { duration: 480; easing.type: Easing.InOutCubic } }
}
