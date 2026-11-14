import QtQuick
import QtQuick.Controls
import BrainOS

Item {
    id: root
    property var desktop
    property string workingDirectory: system.homePath
    property var history: []
    property int historyIndex: 0
    property string output: "BrainOS Terminal\nRun standard Linux commands. Type 'help' for shell shortcuts.\n\n"

    function append(text) {
        output += text
        terminalView.text = output
        terminalView.cursorPosition = terminalView.length
    }

    function run() {
        const raw = commandField.text.trim()
        if (raw.length === 0)
            return
        append(system.userName + "@" + system.hostName + ":" + workingDirectory + "$ " + raw + "\n")
        history = history.concat([raw])
        historyIndex = history.length
        commandField.text = ""

        const parts = raw.split(/\s+/)
        const name = parts[0]
        if (name === "clear") {
            output = ""
            terminalView.text = ""
        } else if (name === "help") {
            append("Built-ins: help, clear, cd, pwd, open, apps, wallpaper\n"
                   + "All installed non-interactive Linux commands are available through /bin/sh:\n"
                   + "ls, cat, grep, find, cp, mv, mkdir, rm, chmod, ps, df, du, uname, ping, curl, git, python and package tools.\n")
        } else if (name === "cd") {
            const target = parts.length > 1 ? raw.substring(3).trim() : system.homePath
            const resolved = system.resolvePath(target, workingDirectory)
            if (system.directoryExists(resolved))
                workingDirectory = resolved
            else
                append("cd: no such directory: " + target + "\n")
        } else if (name === "pwd") {
            append(workingDirectory + "\n")
        } else if (name === "open") {
            const target = parts.length > 1 ? raw.substring(5).trim() : workingDirectory
            if (!system.openPath(system.resolvePath(target, workingDirectory)))
                append("open: could not open " + target + "\n")
        } else if (name === "apps") {
            if (desktop)
                desktop.applicationsOpen = true
        } else if (name === "wallpaper") {
            if (parts.length === 2 && Number(parts[1]) >= 1 && Number(parts[1]) <= 3)
                brain.wallpaperIndex = Number(parts[1]) - 1
            else
                append("usage: wallpaper 1|2|3\n")
        } else {
            system.runCommand(raw, workingDirectory)
        }
    }

    Connections {
        target: system
        function onCommandOutput(requestId, text) { root.append(text) }
        function onCommandFinished(requestId, exitCode) {
            if (exitCode !== 0)
                root.append("[exit " + exitCode + "]\n")
            root.append("\n")
            commandField.forceActiveFocus()
        }
    }

    Rectangle { anchors.fill: parent; color: "#080B11" }

    Column {
        anchors.fill: parent

        Rectangle {
            width: parent.width
            height: 34
            color: "#111621"
            Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                spacing: 8
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8; height: 8; radius: 4; color: Theme.green
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: system.userName + "@" + system.hostName
                    color: Theme.textMuted
                    font.family: Theme.monoFont
                    font.pixelSize: 10
                }
            }
        }

        TextArea {
            id: terminalView
            width: parent.width
            height: parent.height - 78
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

        Rectangle {
            width: parent.width
            height: 44
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
                    placeholderText: "Enter a command"
                    placeholderTextColor: Theme.textDim
                    background: Rectangle { color: "transparent" }
                    onAccepted: root.run()
                    Keys.onUpPressed: {
                        if (root.history.length > 0) {
                            root.historyIndex = Math.max(0, root.historyIndex - 1)
                            text = root.history[root.historyIndex]
                        }
                    }
                    Keys.onDownPressed: {
                        root.historyIndex = Math.min(root.history.length, root.historyIndex + 1)
                        text = root.historyIndex < root.history.length ? root.history[root.historyIndex] : ""
                    }
                }
            }
        }
    }
}
