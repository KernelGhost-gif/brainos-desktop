import QtQuick
import BrainOS

Item {
    id: root
    property string appId
    property string title
    property url iconSource
    property Component contentComponent
    property var desktopController
    property bool minimized: false
    property bool maximized: false
    property real restoreX: x
    property real restoreY: y
    property real restoreWidth: width
    property real restoreHeight: height
    property real resizeStartWidth: 0
    property real resizeStartHeight: 0
    property string subtitle: ""
    signal activated()
    signal closed()
    width: parent ? Math.max(1, Math.min(760, parent.width - 16)) : 760
    height: parent ? Math.max(1, Math.min(520, parent.height - 16)) : 520
    opacity: 0
    scale: 0.94
    visible: !minimized && opacity > 0
    function activateWindow() { minimized = false; opacity = 1; scale = 1; activated() }
    function minimizeWindow() { minimized = true }
    function toggleMaximize() {
        if (!maximized) {
            restoreX = x; restoreY = y; restoreWidth = width; restoreHeight = height
            x = 8; y = 8; width = parent.width - 16; height = parent.height - 16; maximized = true
        } else { x = restoreX; y = restoreY; width = restoreWidth; height = restoreHeight; maximized = false }
    }
    function closeWindow() { closeAnimation.start() }
    Component.onCompleted: openAnimation.start()
    Rectangle { anchors.fill: parent; anchors.margins: -14; radius: Theme.windowRadius + 14; color: "#70000000"; opacity: 0.38; z: -2 }
    Rectangle {
        anchors.fill: parent
        radius: Theme.windowRadius
        color: Theme.surfaceStrong
        border.color: Theme.borderStrong
        border.width: 1
        clip: true
        Rectangle {
            id: titleBar
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            height: 42; color: "#F2191D29"; border.color: "#18FFFFFF"
            Row {
                anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 9
                AppIcon { width: 25; height: 25; source: root.iconSource; backgroundColor: "#447A6BE8" }
                Text { text: root.title; color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold }
                Text { visible: root.subtitle.length > 0; text: root.subtitle; color: Theme.textDim; font.pixelSize: 10 }
            }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                Repeater {
                    model: [{symbol:"−",action:"minimize"},{symbol:"□",action:"maximize"},{symbol:"×",action:"close"}]
                    delegate: Rectangle {
                        width: 32; height: 28; radius: 8
                        color: controlHover.hovered ? (modelData.action === "close" ? Theme.red : Theme.surfaceHover) : "transparent"
                        Text { anchors.centerIn: parent; text: modelData.symbol; color: Theme.text; font.pixelSize: modelData.action === "maximize" ? 13 : 17 }
                        HoverHandler { id: controlHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                if (modelData.action === "minimize") root.minimizeWindow()
                                else if (modelData.action === "maximize") root.toggleMaximize()
                                else root.closeWindow()
                            }
                        }
                    }
                }
            }
            DragHandler {
                target: root; enabled: !root.maximized
                xAxis.minimum: 0; xAxis.maximum: Math.max(0, root.parent.width - root.width)
                yAxis.minimum: 0; yAxis.maximum: Math.max(0, root.parent.height - 50)
                onActiveChanged: if (active) root.activated()
            }
            TapHandler { acceptedButtons: Qt.LeftButton; gesturePolicy: TapHandler.WithinBounds; onDoubleTapped: root.toggleMaximize(); onTapped: root.activated() }
        }
        Loader {
            id: contentLoader
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: titleBar.bottom; anchors.bottom: parent.bottom
            sourceComponent: root.contentComponent
            onLoaded: { if (item && item.hasOwnProperty("desktop")) item.desktop = root.desktopController }
        }
    }
    Rectangle {
        anchors.right: parent.right; anchors.bottom: parent.bottom; width: 18; height: 18; color: "transparent"; visible: !root.maximized
        Canvas {
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d"); ctx.strokeStyle = "#6F778A"; ctx.lineWidth = 1; ctx.beginPath()
                ctx.moveTo(6, 16); ctx.lineTo(16, 6); ctx.moveTo(11, 16); ctx.lineTo(16, 11); ctx.stroke()
            }
        }
        DragHandler {
            id: resizeHandler; target: null; cursorShape: Qt.SizeFDiagCursor
            onActiveChanged: { if (active) { root.resizeStartWidth = root.width; root.resizeStartHeight = root.height; root.activated() } }
            onTranslationChanged: {
                if (active) {
                    const maxWidth = Math.max(1, root.parent.width - root.x); const maxHeight = Math.max(1, root.parent.height - root.y)
                    root.width = Theme.clamp(root.resizeStartWidth + translation.x, Math.min(520, maxWidth), maxWidth)
                    root.height = Theme.clamp(root.resizeStartHeight + translation.y, Math.min(360, maxHeight), maxHeight)
                }
            }
        }
    }
    ParallelAnimation {
        id: openAnimation
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: 190; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "scale"; to: 1; duration: 220; easing.type: Easing.OutBack }
    }
    ParallelAnimation {
        id: closeAnimation
        NumberAnimation { target: root; property: "opacity"; to: 0; duration: 130; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "scale"; to: 0.94; duration: 130; easing.type: Easing.InCubic }
        onFinished: root.closed()
    }
    Behavior on x { enabled: root.maximized; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on y { enabled: root.maximized; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on width { enabled: root.maximized; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on height { enabled: root.maximized; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
}
