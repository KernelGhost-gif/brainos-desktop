import QtQuick
import BrainOS

Item {
    id: root

    property int wallpaperIndex: 0
    readonly property var sources: [
        "../assets/wallpapers/aurora.svg",
        "../assets/wallpapers/horizon.svg",
        "../assets/wallpapers/glass.svg"
    ]

    Rectangle {
        anchors.fill: parent
        color: Theme.background
    }

    Repeater {
        model: 3

        delegate: Image {
            anchors.fill: parent
            source: root.sources[index]
            fillMode: Image.PreserveAspectCrop
            smooth: true
            mipmap: true
            asynchronous: true
            opacity: root.wallpaperIndex === index ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 520
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#22000000"
            }

            GradientStop {
                position: 0.55
                color: "#08000000"
            }

            GradientStop {
                position: 1
                color: "#36000000"
            }
        }
    }
}
