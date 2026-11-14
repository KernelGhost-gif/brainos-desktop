pragma Singleton
import QtQuick

QtObject {
    readonly property color background: "#070912"
    readonly property color surface: "#E5121622"
    readonly property color surfaceStrong: "#F2141826"
    readonly property color surfaceRaised: "#F31A1F2D"
    readonly property color surfaceHover: "#FF252B3C"
    readonly property color border: "#2EFFFFFF"
    readonly property color borderStrong: "#557A6BE8"
    readonly property color text: "#F4F5FA"
    readonly property color textMuted: "#A6ADBF"
    readonly property color textDim: "#747D92"
    readonly property color accent: "#8B5CF6"
    readonly property color accentLight: "#B69AFD"
    readonly property color cyan: "#5DD6E8"
    readonly property color green: "#54D69A"
    readonly property color yellow: "#F5C95C"
    readonly property color red: "#FF6B73"
    readonly property color shadow: "#99000000"
    readonly property int topBarHeight: 56
    readonly property int dockHeight: 86
    readonly property int windowRadius: 20
    readonly property int panelRadius: 18
    readonly property int space1: 4
    readonly property int space2: 8
    readonly property int space3: 12
    readonly property int space4: 16
    readonly property int space5: 20
    readonly property int space6: 24
    readonly property int motionFast: 140
    readonly property int motionNormal: 220
    readonly property int motionSlow: 300
    readonly property string uiFont: "Inter"
    readonly property string monoFont: "JetBrains Mono"
    function clamp(value, minimum, maximum) { return Math.max(minimum, Math.min(maximum, value)) }
    function wallpaperAccent(index) { return [accent, "#A56BEA", "#668BFF"][clamp(index, 0, 2)] }
}
