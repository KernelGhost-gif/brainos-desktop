import QtQuick
import QtQuick.Controls
import BrainOS

Item {
    id: root

    property var desktop
    property var history: []
    property int historyIndex: 0
    property string output: "BrainOS Terminal\nSZH shell is the default command environment.\n"

    function append(rawText) {
        let text = String(rawText)
        // The terminal view is text-based: strip ANSI drawing/colour sequences
        // while preserving command output and readline prompt text.
        text = text.replace(/\u001b\][^\u0007]*(?:\u0007|\u001b\\)/g, "")
        text = text.replace(/\u001b\[[0-?]*[ -/]*[@-~]/g, "")
        text = text.replace(/\r\n/g, "\n").replace(/\r/g, "\n")
        if (text.length === 0)
            return

        output += text
        if (output.length > 400000)
            output = output.slice(-320000)

        Qt.callLater(function() {
            terminalView.cursorPosition = terminalView.length
            outputScroll.contentY = Math.max(0, outputScroll.contentHeight - outputScroll.height)
        })
    }

    function clearScreen() {
        output = ""
        terminalView.cursorPosition = 0
    }

    function run() {
        const raw = commandField.text
        if (raw.trim().length === 0)
            return

        history = history.concat([raw])
        if (history.length > 300)
            history = history.slice(-300)
        historyIndex = history.length
        commandField.text = ""

        const trimmed = raw.trim()
        if (trimmed === "clear") {
            clearScreen()
            return
        }

        if (trimmed === "apps") {
            if (desktop)
                desktop.applicationsOpen = true
            return
        }

        if (trimmed === "help") {
            append("\nBrainOS commands: apps, wallpaper 1|2|3, open PATH, clear\n")
            append("SZH commands are provided by the bundled Toybox applet set. Try: ls, cat, grep, find, ps, uname, tar, ping, df, du.\n")
            append("This view supports line-oriented commands; full-screen apps such as vi and top are not supported yet.\n")
            append("The SZH shell runs as your current BrainOS user on the host filesystem.\n")
            return
        }

        if (trimmed === "open" || trimmed.startsWith("open ")) {
            const target = trimmed.length > 5 ? trimmed.substring(5).trim() : system.homePath
            if (!system.openPath(system.resolvePath(target)))
                append("open: could not open " + target + "\n")
            return
        }

        if (trimmed === "wallpaper" || trimmed.startsWith("wallpaper ")) {
            const parts = trimmed.split(/\s+/)
            if (parts.length === 2 && Number(parts[1]) >= 1 && Number(parts[1]) <= 3)
                brain.wallpaperIndex = Number(parts[1]) - 1
            else
                append("usage: wallpaper 1|2|3\n")
            return
        }

        if (!szhTerminal.sendInput(raw + "\n"))
            append("[terminal] No active shell. Use Restart to start a session.\n")
    }

    function switchShell(name) {
        const started = name === "SZH" ? szhTerminal.startSzh() : szhTerminal.startHost()
        if (started) {
            output = "BrainOS Terminal\n" + name + " shell session started.\n"
            commandField.forceActiveFocus()
        } else if (name === "SZH") {
            append("[SZH runtime unavailable; starting the BrainOS host shell instead.]\n")
            if (szhTerminal.startHost())
                append("Host shell session started.\n")
        }
    }

    function restartSession() {
        switchShell(szhTerminal.shellName === "Host" ? "Host" : "SZH")
    }

    Connections {
        target: szhTerminal

        function onTerminalOutput(text) {
            root.append(text)
        }

        function onSessionFinished(exitCode) {
            root.append("\n[session exited with status " + exitCode + "]\n")
        }

        function onRunningChanged() {
            if (szhTerminal.running)
                commandField.forceActiveFocus()
        }
    }

    Component.onCompleted: {
        if (!szhTerminal.startSzh()) {
            append("[SZH runtime unavailable; using the BrainOS host shell.]\n")
            szhTerminal.startHost()
        }
    }

    Component.onDestruction: szhTerminal.stop()

    Rectangle {
        anchors.fill: parent
        color: "#080B11"
    }

    Column {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            width: parent.width
            height: 42
            color: "#111621"
            border.color: Theme.border

            Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 10
                spacing: 7

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8
                    height: 8
                    radius: 4
                    color: szhTerminal.running ? Theme.green : Theme.textDim
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: szhTerminal.running ? szhTerminal.shellName + " shell" : "Shell stopped"
                    color: Theme.text
                    font.family: Theme.monoFont
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                Item { width: 6; height: 1 }

                Button {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "SZH"
                    highlighted: szhTerminal.shellName === "SZH"
                    onClicked: root.switchShell("SZH")
                }

                Button {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Host"
                    highlighted: szhTerminal.shellName === "Host"
                    onClicked: root.switchShell("Host")
                }

                Item { width: 6; height: 1 }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: system.userName + "@" + system.hostName
                    color: Theme.textMuted
                    font.family: Theme.monoFont
                    font.pixelSize: 10
                }

                Button {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Clear"
                    onClicked: root.clearScreen()
                }

                Button {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Restart"
                    onClicked: root.restartSession()
                }
            }
        }

        Flickable {
            id: outputScroll
            width: parent.width
            height: parent.height - 88
            clip: true
            contentWidth: width
            contentHeight: terminalView.height
            boundsBehavior: Flickable.StopAtBounds

            TextArea {
                id: terminalView
                width: outputScroll.width
                height: Math.max(outputScroll.height, implicitHeight)
                readOnly: true
                text: root.output
                color: "#DCE5F5"
                selectionColor: Theme.accent
                selectedTextColor: "white"
                font.family: Theme.monoFont
                font.pixelSize: 12
                wrapMode: TextEdit.WrapAnywhere
                selectByMouse: true
                leftPadding: 14
                rightPadding: 14
                topPadding: 12
                bottomPadding: 12
                background: Rectangle { color: "#080B11" }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
        }

        Rectangle {
            width: parent.width
            height: 46
            color: "#10151F"
            border.color: Theme.border

            Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "❯"
                    color: Theme.green
                    font.pixelSize: 15
                    font.weight: Font.Bold
                }

                TextField {
                    id: commandField
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 45
                    height: 36
                    color: Theme.text
                    font.family: Theme.monoFont
                    font.pixelSize: 12
                    focus: true
                    placeholderText: szhTerminal.shellName === "SZH"
                                     ? "Enter an SZH / Toybox command"
                                     : "Enter a host shell command"
                    placeholderTextColor: Theme.textDim
                    background: Rectangle { color: "transparent" }
                    onAccepted: root.run()

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_C && (event.modifiers & Qt.ControlModifier)) {
                            szhTerminal.sendInterrupt()
                            event.accepted = true
                        } else if (event.key === Qt.Key_D && (event.modifiers & Qt.ControlModifier)) {
                            szhTerminal.sendEof()
                            event.accepted = true
                        } else if (event.key === Qt.Key_L && (event.modifiers & Qt.ControlModifier)) {
                            root.clearScreen()
                            event.accepted = true
                        }
                    }

                    Keys.onUpPressed: {
                        if (root.history.length > 0) {
                            root.historyIndex = Math.max(0, root.historyIndex - 1)
                            text = root.history[root.historyIndex]
                        }
                    }

                    Keys.onDownPressed: {
                        root.historyIndex = Math.min(root.history.length, root.historyIndex + 1)
                        text = root.historyIndex < root.history.length
                               ? root.history[root.historyIndex] : ""
                    }
                }
            }
        }
    }
}
