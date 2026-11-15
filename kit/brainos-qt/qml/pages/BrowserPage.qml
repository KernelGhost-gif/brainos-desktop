import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWebEngine
import BrainOS

SectionCard {
    id: root
    implicitHeight: 560
    depth: 1.05

    property string currentUrl: "https://www.gnome.org"

    function normalizeUrl(text) {
        var t = text.trim()
        if (t.length === 0)
            return "https://www.gnome.org"
        if (t.indexOf("://") === -1)
            return "https://" + t
        return t
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space3

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space2

            TextField {
                id: urlField
                Layout.fillWidth: true
                text: root.currentUrl
                placeholderText: "Search or enter address"
                color: Theme.text
                font.pixelSize: 12
                selectByMouse: true
                background: Rectangle {
                    radius: 14
                    color: "#0A0D13"
                    border.color: Theme.border
                }
                leftPadding: Theme.space3
                rightPadding: Theme.space3
                topPadding: Theme.space2
                bottomPadding: Theme.space2

                onAccepted: {
                    root.currentUrl = root.normalizeUrl(text)
                    webView.url = root.currentUrl
                }
            }

            Button {
                text: "Go"
                onClicked: {
                    root.currentUrl = root.normalizeUrl(urlField.text)
                    webView.url = root.currentUrl
                }
            }
        }

        WebEngineView {
            id: webView
            Layout.fillWidth: true
            Layout.fillHeight: true
            url: root.currentUrl
            settings.javascriptEnabled: true
            settings.localStorageEnabled: true
            settings.pluginsEnabled: true
            onLoadingChanged: {
                if (loadRequest.status === WebEngineLoadRequest.LoadSucceededStatus)
                    root.currentUrl = url.toString()
            }
        }
    }
}
