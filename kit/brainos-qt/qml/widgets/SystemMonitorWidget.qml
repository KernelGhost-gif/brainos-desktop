import QtQuick
import QtQuick.Layouts
import BrainOS

SectionCard {
    id: root
    implicitHeight: 164
    depth: 1.05
    property var metrics: [
        { label: "CPU", color: Theme.cyan, icon: "../assets/icons/cpu.svg" },
        { label: "Memory", color: Theme.accentLight, icon: "../assets/icons/memory.svg" },
        { label: "Disk", color: Theme.yellow, icon: "../assets/icons/disk.svg" },
        { label: "Network", color: "#75A7FF", icon: "../assets/icons/network.svg" }
    ]
    function metricRatio(index) { return index === 0 ? system.cpuUsage : index === 1 ? system.memoryUsage : index === 2 ? system.diskUsage : Math.min(1, system.networkDownKbps / 10240) }
    function metricValue(index) {
        if (index === 0) return Math.round(system.cpuUsage * 100) + "%"
        if (index === 1) return Math.round(system.memoryUsage * 100) + "%"
        if (index === 2) return Math.round(system.diskUsage * 100) + "%"
        return system.networkDownKbps < 1024 ? Math.round(system.networkDownKbps) + " KB/s" : (system.networkDownKbps / 1024).toFixed(1) + " MB/s"
    }
    GridLayout {
        anchors.fill: parent
        columns: 2
        rowSpacing: Theme.space3
        columnSpacing: Theme.space3
        Repeater {
            model: root.metrics
            delegate: Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                radius: 13
                color: Theme.surfaceRaised
                border.color: Theme.border
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space3
                    spacing: 6
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Image { width: 12; height: 12; source: modelData.icon; fillMode: Image.PreserveAspectFit; smooth: true }
                        Text { text: modelData.label; color: Theme.textMuted; font.pixelSize: 10 }
                        Item { Layout.fillWidth: true }
                        Text { text: root.metricValue(index); color: Theme.text; font.pixelSize: 10; font.weight: Font.DemiBold }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 5
                        radius: 3
                        color: "#24FFFFFF"
                        clip: true
                        Rectangle {
                            width: parent.width * root.metricRatio(index)
                            height: parent.height
                            radius: 3
                            color: modelData.color
                            Behavior on width { NumberAnimation { duration: Theme.motionNormal; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
        }
    }
}
