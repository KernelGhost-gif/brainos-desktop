import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BrainOS

SectionCard {
    implicitHeight: 176
    depth: 0.9
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space2
        Text { text: "Quick note"; color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold }
        TextArea {
            id: noteEditor
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: brain.quickNote
            placeholderText: "Write a note…"
            placeholderTextColor: Theme.textDim
            color: Theme.textMuted
            font.pixelSize: 11
            wrapMode: TextEdit.Wrap
            selectByMouse: true
            leftPadding: Theme.space3
            rightPadding: Theme.space3
            topPadding: Theme.space3
            bottomPadding: Theme.space3
            background: Rectangle { radius: 12; color: "#0A0D13"; border.color: Theme.border }
            onTextChanged: { if (brain.quickNote !== text) brain.quickNote = text }
        }
    }
}
