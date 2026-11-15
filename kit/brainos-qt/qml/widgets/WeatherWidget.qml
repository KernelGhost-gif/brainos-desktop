import QtQuick
import QtQuick.Layouts
import BrainOS

SectionCard {
    implicitHeight: 94
    depth: 0.85
    RowLayout {
        anchors.fill: parent
        spacing: Theme.space3
        AppIcon { Layout.preferredWidth: 46; Layout.preferredHeight: 46; source: "image://brainos-icons/weather-disabled"; backgroundColor: "#33414F" }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Text { Layout.fillWidth: true; text: "Weather unavailable"; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight }
            Text { Layout.fillWidth: true; text: "Connect a weather provider in Settings."; color: Theme.textMuted; font.pixelSize: 10; wrapMode: Text.Wrap }
        }
    }
}
