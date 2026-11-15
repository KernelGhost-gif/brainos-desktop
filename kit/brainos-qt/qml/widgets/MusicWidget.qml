import QtQuick
import QtQuick.Layouts
import BrainOS

SectionCard {
    id: root
    signal openPlayer()
    implicitHeight: 114
    depth: 0.9
    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.space4
        spacing: Theme.space3
        AppIcon { Layout.preferredWidth: 58; Layout.preferredHeight: 58; source: "image://brainos-icons/music"; backgroundColor: system.mediaAvailable ? Theme.wallpaperAccent(brain.wallpaperIndex) : "#354052" }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Text { Layout.fillWidth: true; text: system.mediaAvailable ? (system.mediaTitle || "Unknown track") : "No active media"; color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold; elide: Text.ElideRight }
            Text { Layout.fillWidth: true; text: system.mediaAvailable ? (system.mediaArtist || "Unknown artist") : "Open a compatible MPRIS player"; color: Theme.textMuted; font.pixelSize: 10; elide: Text.ElideRight }
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space3
                visible: system.mediaAvailable
                opacity: visible ? 1.0 : 0.35
                IconButton { width: 26; height: 26; iconSource: "image://brainos-icons/previous"; label: "Previous"; onClicked: system.mediaAction("Previous") }
                IconButton { width: 26; height: 26; iconSource: system.mediaPlaying ? "../assets/icons/pause.svg" : "../assets/icons/play.svg"; label: system.mediaPlaying ? "Pause" : "Play"; onClicked: system.mediaAction("PlayPause") }
                IconButton { width: 26; height: 26; iconSource: "image://brainos-icons/next"; label: "Next"; onClicked: system.mediaAction("Next") }
                Item { Layout.fillWidth: true }
            }
        }
    }
    TapHandler { acceptedButtons: Qt.LeftButton; onTapped: root.openPlayer() }
}
