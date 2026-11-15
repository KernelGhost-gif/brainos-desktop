import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BrainOS

SectionCard {
    id: root
    implicitHeight: 520
    depth: 1.05

    property string displayText: "0"
    property string expressionText: ""
    property bool replaceNext: true

    // Recursive-descent arithmetic parser. Avoids eval/Function so calculator
    // input can never execute JavaScript, even when pasted into the display.
    function safeEvaluate(expr) {
        var normalized = expr.replace(/÷/g, "/").replace(/×/g, "*").replace(/−/g, "-")
        var tokens = normalized.replace(/\s+/g, "").match(/(?:[0-9]+\.?[0-9]*|\.[0-9]+|[()+\-*\/%])/g) || []
        var compact = normalized.replace(/\s+/g, "")
        if (!compact.length || tokens.join("") !== compact)
            return "Error"

        var cursor = 0
        function parseExpression() {
            var value = parseTerm()
            while (cursor < tokens.length && (tokens[cursor] === "+" || tokens[cursor] === "-")) {
                var operator = tokens[cursor++]
                var rhs = parseTerm()
                value = operator === "+" ? value + rhs : value - rhs
            }
            return value
        }
        function parseTerm() {
            var value = parseUnary()
            while (cursor < tokens.length && ["*", "/", "%"].indexOf(tokens[cursor]) >= 0) {
                var operator = tokens[cursor++]
                var rhs = parseUnary()
                if ((operator === "/" || operator === "%") && rhs === 0)
                    throw new Error("Division by zero")
                if (operator === "*") value *= rhs
                else if (operator === "/") value /= rhs
                else value %= rhs
            }
            return value
        }
        function parseUnary() {
            if (tokens[cursor] === "+") { cursor++; return parseUnary() }
            if (tokens[cursor] === "-") { cursor++; return -parseUnary() }
            return parsePrimary()
        }
        function parsePrimary() {
            if (tokens[cursor] === "(") {
                cursor++
                var value = parseExpression()
                if (tokens[cursor] !== ")") throw new Error("Missing closing parenthesis")
                cursor++
                return value
            }
            var token = tokens[cursor++]
            if (token === undefined || !/^(?:[0-9]+\.?[0-9]*|\.[0-9]+)$/.test(token))
                throw new Error("Expected a number")
            var number = Number(token)
            if (!Number.isFinite(number)) throw new Error("Invalid number")
            return number
        }

        try {
            var result = parseExpression()
            if (cursor !== tokens.length || !Number.isFinite(result))
                return "Error"
            return String(Number(result.toPrecision(12)))
        } catch (error) {
            return "Error"
        }
    }

    function handleKey(token) {
        if (token === "C") {
            expressionText = ""
            displayText = "0"
            replaceNext = true
            return
        }
        if (token === "BACK") {
            if (replaceNext)
                expressionText = displayText
            expressionText = expressionText.slice(0, -1)
            displayText = expressionText.length ? expressionText : "0"
            replaceNext = !expressionText.length
            return
        }

        var isOperator = ["+", "−", "×", "÷", "%"].indexOf(token) >= 0
        if (replaceNext && isOperator) {
            expressionText = displayText + token
        } else if (replaceNext) {
            expressionText = token
        } else {
            expressionText += token
        }
        replaceNext = false
        displayText = expressionText
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space3

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 110
            radius: 18
            color: "#0A0D13"
            border.color: Theme.border

            Column {
                anchors.fill: parent
                anchors.margins: Theme.space4
                spacing: 6

                Text {
                    width: parent.width
                    text: root.expressionText.length ? root.expressionText : "Calculator"
                    color: Theme.textMuted
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }

                Text {
                    width: parent.width
                    text: root.displayText
                    color: Theme.text
                    font.pixelSize: 36
                    font.weight: Font.Light
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 4
            rowSpacing: Theme.space2
            columnSpacing: Theme.space2

            Repeater {
                model: [
                    "C", "BACK", "%", "÷",
                    "7", "8", "9", "×",
                    "4", "5", "6", "−",
                    "1", "2", "3", "+",
                    "0", ".", "(", ")"
                ]

                delegate: Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    text: modelData

                    onClicked: root.handleKey(modelData === "BACK" ? "BACK" : modelData)
                }
            }

            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                Layout.columnSpan: 4
                text: "="
                onClicked: {
                    root.displayText = root.safeEvaluate(root.expressionText)
                    root.expressionText = root.displayText === "Error" ? "" : root.displayText
                    root.replaceNext = true
                }
            }
        }
    }
}
