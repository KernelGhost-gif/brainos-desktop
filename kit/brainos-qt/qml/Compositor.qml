import QtQuick
import QtQuick.Window
import QtWayland.Compositor
import QtWayland.Compositor.XdgShell
import BrainOS

WaylandCompositor {
    id: compositor
    socketName: waylandSocketName

    XdgShell {
        onToplevelCreated: (xdgToplevel, xdgSurface) => {
            windows.addWindow(xdgSurface, xdgToplevel)
        }
        onPopupCreated: (popup, xdgSurface) => {
            windows.addWindow(xdgSurface, popup)
        }
    }

    XdgDecorationManagerV1 {
        preferredMode: XdgToplevel.ServerSideDecoration
    }

    WaylandOutput {
        scaleFactor: 1
        automaticFrameCallback: true

        Window {
            id: rootWindow
            visible: true
            width: Screen.width
            height: Screen.height
            color: "black"
            flags: Qt.FramelessWindowHint | Qt.Window

            DesktopSurface {
                id: desktop
                anchors.fill: parent
                externalWindowModel: windows
                opacity: brain.desktopReady ? 1 : 0
                enabled: brain.desktopReady
                Behavior on opacity {
                    NumberAnimation { duration: 560; easing.type: Easing.OutCubic }
                }
            }

            BootSplash {
                anchors.fill: parent
                running: !brain.desktopReady
                message: brain.bootMessage
            }
        }
    }
}
