import QtQuick
import QtQuick.Layouts
import BrainOS

SectionCard {
    id: root
    property string clockText: ""
    property string dateText: ""
    property date visibleMonth: new Date()
    property date selectedDate: new Date()
    implicitHeight: 216
    depth: 1.15
    function monthTitle() { return Qt.formatDate(visibleMonth, "MMMM yyyy") }
    function daysModel() {
        const year = visibleMonth.getFullYear()
        const month = visibleMonth.getMonth()
        const firstDay = new Date(year, month, 1).getDay()
        const mondayOffset = (firstDay + 6) % 7
        const days = new Date(year, month + 1, 0).getDate()
        const result = []
        for (let i = 0; i < mondayOffset; ++i) result.push({ day: "", date: null })
        for (let day = 1; day <= days; ++day) result.push({ day: String(day), date: new Date(year, month, day) })
        return result
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space3
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: root.clockText; color: Theme.text; font.family: Theme.uiFont; font.pixelSize: 42; font.weight: Font.Light; lineHeightMode: Text.FixedHeight; lineHeight: 38 }
                Text { text: root.dateText; color: Theme.textMuted; font.family: Theme.uiFont; font.pixelSize: 11 }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space2
            Text { Layout.fillWidth: true; text: root.monthTitle(); color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold }
            IconButton { width: 24; height: 24; iconSource: "image://brainos-icons/back"; label: "Previous month"; onClicked: root.visibleMonth = new Date(root.visibleMonth.getFullYear(), root.visibleMonth.getMonth() - 1, 1) }
            IconButton { width: 24; height: 24; iconSource: "image://brainos-icons/forward"; label: "Next month"; onClicked: root.visibleMonth = new Date(root.visibleMonth.getFullYear(), root.visibleMonth.getMonth() + 1, 1) }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            Repeater { model: ["M", "T", "W", "T", "F", "S", "S"]; delegate: Text { Layout.fillWidth: true; text: modelData; color: Theme.textDim; font.pixelSize: 9; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter } }
        }
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: 6
            columnSpacing: 0
            Repeater {
                model: root.daysModel()
                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: 24
                    radius: 8
                    readonly property bool today: modelData.date && modelData.date.toDateString() === new Date().toDateString()
                    readonly property bool selected: modelData.date && modelData.date.toDateString() === root.selectedDate.toDateString()
                    color: selected ? Theme.wallpaperAccent(brain.wallpaperIndex) : today ? "#327A6BE8" : dayHover.hovered ? "#20FFFFFF" : "transparent"
                    Text { anchors.centerIn: parent; text: modelData.day; color: parent.selected ? "white" : Theme.textMuted; font.pixelSize: 9 }
                    HoverHandler { id: dayHover; enabled: modelData.date !== null; cursorShape: Qt.PointingHandCursor }
                    TapHandler { enabled: modelData.date !== null; onTapped: root.selectedDate = modelData.date }
                }
            }
        }
    }
}
