import QtQuick
import QtWayland.Compositor
import BrainOS

Item {
    id: root
    property int windowIndex: -1
    property var shellSurface
    property string title: ""
    property string appId: ""
    property real posX: 0
    property real posY: 0
    property real windowWidth: 900
    property real windowHeight: 620
    property bool active: false
    property bool minimized: false
    property bool maximized: false
    property real dragStartX: 0
    property real dragStartY: 0
    property real resizeStartWidth: 0
    property real resizeStartHeight: 0

    x: posX
    y: posY
    width: windowWidth
    height: windowHeight
    visible: !minimized
    z: active ? 100 : 10

    Rectangle {
        anchors.fill: parent
        anchors.margins: -13
        radius: Theme.windowRadius + 12
        color: Theme.shadow
        opacity: 0.5
        z: -1
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.windowRadius
        color: Theme.surfaceStrong
        border.color: active ? Theme.borderStrong : Theme.border
        clip: true

        Rectangle {
            id: titleBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 42
            color: "#F2191D29"
            border.color: Theme.border

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Rectangle {
                    width: 8; height: 8; radius: 4
                    color: root.active ? Theme.green : Theme.textDim
                }
                Text {
                    text: root.title.length > 0 ? root.title : root.appId
                    color: Theme.text
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    width: Math.min(300, titleBar.width - 180)
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Repeater {
                    model: [
                        { symbol: "−", action: "minimize" },
                        { symbol: "□", action: "maximize" },
                        { symbol: "×", action: "close" }
                    ]
                    delegate: Rectangle {
                        width: 32; height: 28; radius: 8
                        color: chromeHover.hovered
                               ? (modelData.action === "close" ? Theme.red : Theme.surfaceHover)
                               : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: modelData.symbol
                            color: Theme.text
                            font.pixelSize: modelData.action === "maximize" ? 13 : 17
                        }
                        HoverHandler { id: chromeHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                if (modelData.action === "minimize")
                                    windows.minimizeWindow(root.windowIndex)
                                else if (modelData.action === "maximize")
                                    windows.toggleMaximize(root.windowIndex, root.parent.width, root.parent.height)
                                else
                                    windows.closeWindow(root.windowIndex)
                            }
                        }
                    }
                }
            }

            DragHandler {
                target: null
                enabled: !root.maximized
                onActiveChanged: {
                    if (active) {
                        root.dragStartX = root.posX
                        root.dragStartY = root.posY
                        windows.activateWindow(root.windowIndex)
                    }
                }
                onTranslationChanged: {
                    if (active)
                        windows.moveWindow(root.windowIndex,
                                           Math.max(0, root.dragStartX + translation.x),
                                           Math.max(0, root.dragStartY + translation.y))
                }
            }
            TapHandler {
                onTapped: windows.activateWindow(root.windowIndex)
                onDoubleTapped: windows.toggleMaximize(root.windowIndex, root.parent.width, root.parent.height)
            }
        }

        ShellSurfaceItem {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: titleBar.bottom
            anchors.bottom: parent.bottom
            shellSurface: root.shellSurface
            moveItem: titleBar
            autoCreatePopupItems: true
            focusOnClick: true
            inputEventsEnabled: true
            touchEventsEnabled: true
            onSurfaceDestroyed: windows.removeWindow(root.shellSurface)
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 18
        height: 18
        color: "transparent"
        visible: !root.maximized
        DragHandler {
            target: null
            cursorShape: Qt.SizeFDiagCursor
            onActiveChanged: {
                if (active) {
                    root.resizeStartWidth = root.windowWidth
                    root.resizeStartHeight = root.windowHeight
                }
            }
            onTranslationChanged: {
                if (active)
                    windows.setGeometry(root.windowIndex, root.posX, root.posY,
                                        Math.max(520, root.resizeStartWidth + translation.x),
                                        Math.max(360, root.resizeStartHeight + translation.y))
            }
        }
    }
}
