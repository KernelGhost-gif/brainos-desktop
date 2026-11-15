import QtQuick
import BrainOS
Item {
    id: root
    property var desktop
    Rectangle { anchors.fill: parent; color: Theme.surfaceStrong }
    Column {
        anchors.centerIn: parent; width: Math.min(parent.width - 48, 520); spacing: 14
        Image { anchors.horizontalCenter: parent.horizontalCenter; width: 120; height: 120; source: "../assets/brainos-mark.svg"; fillMode: Image.PreserveAspectFit; smooth: true }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "BrainOS"; color: Theme.text; font.pixelSize: 26; font.weight: Font.DemiBold }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Qt 6 • Qt Quick • Qt Wayland Compositor"; color: Theme.textMuted; font.pixelSize: 11 }
        SectionCard {
            width: parent.width; height: 136
            Column {
                anchors.fill: parent; anchors.margins: 14; spacing: 9
                Text { text: "Session"; color: Theme.textDim; font.pixelSize: 9; font.weight: Font.DemiBold }
                Text { text: "Custom BrainOS Wayland shell"; color: Theme.text; font.pixelSize: 12 }
                Text { text: "User: " + system.userName + "@" + system.hostName; color: Theme.textMuted; font.pixelSize: 10 }
                Text { text: "Package backend: " + system.packageBackend; color: Theme.textMuted; font.pixelSize: 10 }
                Text { text: system.wineAvailable ? "Windows compatibility: Wine available" : "Windows compatibility: Wine not installed"; color: Theme.textMuted; font.pixelSize: 10 }
            }
        }
        Text { width: parent.width; text: "BrainOS keeps the Linux and Wayland foundation while providing its own desktop, windows, applications, widgets, and interaction system."; color: Theme.textMuted; font.pixelSize: 11; wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter }
    }
}
