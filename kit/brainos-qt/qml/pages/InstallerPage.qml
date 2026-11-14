import QtQuick
import QtQuick.Controls
import BrainOS

Item {
    id: root
    property var desktop
    property int step: 0
    property var selectedDisk: targetDisk.currentIndex >= 0 ? installer.disks[targetDisk.currentIndex] : null

    function canContinue() {
        if (step === 0)
            return selectedDisk && !selectedDisk.systemDisk
        if (step === 1)
            return userName.text.length > 0 && hostName.text.length > 0 && password.text.length >= 8
        if (step === 2)
            return selectedDisk && confirmation.text === "ERASE " + selectedDisk.path
        return false
    }

    function beginInstall() {
        if (!canContinue())
            return
        installer.startInstall({
            "device": selectedDisk.path,
            "userName": userName.text,
            "hostName": hostName.text,
            "password": password.text,
            "timezone": timezone.currentText,
            "firmware": firmware.currentValue,
            "confirmation": confirmation.text
        })
        step = 3
    }

    Rectangle { anchors.fill: parent; color: Theme.surfaceStrong }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.space5
        spacing: Theme.space4

        Row {
            width: parent.width
            Text { text: "Install BrainOS"; color: Theme.text; font.pixelSize: 22; font.weight: Font.DemiBold }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: installer.efiDetected ? "EFI environment detected" : "Legacy BIOS environment detected"
                color: Theme.textMuted
                font.pixelSize: 10
            }
        }

        Row {
            width: parent.width
            spacing: 6
            Repeater {
                model: ["Target", "User", "Review", "Install"]
                delegate: Item {
                    width: (parent.width - 18) / 4
                    height: 30
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 4
                        radius: 2
                        color: index <= root.step ? Theme.wallpaperAccent(brain.wallpaperIndex) : "#24FFFFFF"
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        text: modelData
                        color: index <= root.step ? Theme.text : Theme.textDim
                        font.pixelSize: 9
                    }
                }
            }
        }

        SectionCard {
            width: parent.width
            height: parent.height - 128
            depth: 1.2

            Item {
                anchors.fill: parent
                anchors.margins: Theme.space5

                Column {
                    anchors.fill: parent
                    spacing: Theme.space4
                    visible: root.step === 0

                    Text { text: "Choose an installation disk"; color: Theme.text; font.pixelSize: 16; font.weight: Font.DemiBold }
                    Text {
                        width: parent.width
                        text: "The selected disk will be repartitioned. The running system disk is blocked."
                        color: Theme.textMuted
                        font.pixelSize: 11
                        wrapMode: Text.Wrap
                    }
                    Row {
                        width: parent.width
                        spacing: Theme.space3
                        ComboBox {
                            id: targetDisk
                            width: parent.width - 118
                            height: 42
                            model: installer.disks
                            textRole: "path"
                            displayText: root.selectedDisk
                                ? root.selectedDisk.path + "  •  " + (root.selectedDisk.model || "Disk")
                                  + "  •  " + (root.selectedDisk.size / 1000000000).toFixed(1) + " GB"
                                : "No target disk detected"
                        }
                        Button {
                            width: 106
                            height: 42
                            text: "Refresh"
                            onClicked: installer.refreshHardware()
                        }
                    }

                    SectionCard {
                        width: parent.width
                        height: 132
                        visible: root.selectedDisk !== null
                        Column {
                            anchors.fill: parent
                            anchors.margins: Theme.space4
                            spacing: 8
                            Text { text: root.selectedDisk ? (root.selectedDisk.model || root.selectedDisk.name) : ""; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                            Text { text: root.selectedDisk ? root.selectedDisk.path : ""; color: Theme.textMuted; font.pixelSize: 11 }
                            Text { text: root.selectedDisk ? "Partition table: " + (root.selectedDisk.partitionTable || "none") + "  •  Existing partitions: " + root.selectedDisk.partitions : ""; color: Theme.textMuted; font.pixelSize: 10 }
                            Text {
                                text: root.selectedDisk && root.selectedDisk.systemDisk ? "This is the running system disk and cannot be selected." : "Available for installation"
                                color: root.selectedDisk && root.selectedDisk.systemDisk ? Theme.red : Theme.green
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    Text {
                        visible: installer.disks.length === 0
                        text: "No physical disks were reported by lsblk."
                        color: Theme.textMuted
                        font.pixelSize: 11
                    }
                }

                Column {
                    anchors.fill: parent
                    spacing: Theme.space4
                    visible: root.step === 1

                    Text { text: "Create the primary user"; color: Theme.text; font.pixelSize: 16; font.weight: Font.DemiBold }
                    Grid {
                        width: parent.width
                        columns: 2
                        columnSpacing: Theme.space4
                        rowSpacing: Theme.space3

                        Column {
                            width: (parent.width - Theme.space4) / 2
                            spacing: 5
                            Text { text: "User name"; color: Theme.textMuted; font.pixelSize: 10 }
                            TextField { id: userName; width: parent.width; placeholderText: "brain"; color: Theme.text }
                        }
                        Column {
                            width: (parent.width - Theme.space4) / 2
                            spacing: 5
                            Text { text: "Computer name"; color: Theme.textMuted; font.pixelSize: 10 }
                            TextField { id: hostName; width: parent.width; text: "brainos"; color: Theme.text }
                        }
                        Column {
                            width: (parent.width - Theme.space4) / 2
                            spacing: 5
                            Text { text: "Password"; color: Theme.textMuted; font.pixelSize: 10 }
                            TextField { id: password; width: parent.width; echoMode: TextInput.Password; placeholderText: "Minimum 8 characters"; color: Theme.text }
                        }
                        Column {
                            width: (parent.width - Theme.space4) / 2
                            spacing: 5
                            Text { text: "Timezone"; color: Theme.textMuted; font.pixelSize: 10 }
                            ComboBox { id: timezone; width: parent.width; model: ["Asia/Kolkata", "UTC", "Europe/London", "America/New_York", "America/Los_Angeles", "Asia/Tokyo"] }
                        }
                        Column {
                            width: (parent.width - Theme.space4) / 2
                            spacing: 5
                            Text { text: "Firmware"; color: Theme.textMuted; font.pixelSize: 10 }
                            ComboBox {
                                id: firmware
                                width: parent.width
                                textRole: "text"
                                valueRole: "value"
                                model: [
                                    { text: "Automatic", value: "auto" },
                                    { text: "UEFI", value: "efi" },
                                    { text: "Legacy BIOS", value: "bios" }
                                ]
                            }
                        }
                    }
                }

                Column {
                    anchors.fill: parent
                    spacing: Theme.space4
                    visible: root.step === 2

                    Text { text: "Review destructive changes"; color: Theme.text; font.pixelSize: 16; font.weight: Font.DemiBold }
                    Text {
                        width: parent.width
                        text: root.selectedDisk
                            ? root.selectedDisk.path + " will be erased, formatted with GPT, and configured for " + firmware.currentText + "."
                            : ""
                        color: Theme.red
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                    }
                    SectionCard {
                        width: parent.width
                        height: 130
                        Column {
                            anchors.fill: parent
                            anchors.margins: Theme.space4
                            spacing: 7
                            Text { text: "User: " + userName.text; color: Theme.text; font.pixelSize: 11 }
                            Text { text: "Host: " + hostName.text; color: Theme.textMuted; font.pixelSize: 11 }
                            Text { text: "Timezone: " + timezone.currentText; color: Theme.textMuted; font.pixelSize: 11 }
                            Text { text: "Bootloader: GRUB (" + firmware.currentText + ")"; color: Theme.textMuted; font.pixelSize: 11 }
                        }
                    }
                    Text {
                        text: root.selectedDisk ? "Type ERASE " + root.selectedDisk.path + " to continue" : ""
                        color: Theme.textMuted
                        font.pixelSize: 10
                    }
                    TextField {
                        id: confirmation
                        width: parent.width
                        color: Theme.text
                        selectByMouse: true
                    }
                }

                Column {
                    anchors.fill: parent
                    spacing: Theme.space4
                    visible: root.step === 3

                    Text { text: installer.status; color: Theme.text; font.pixelSize: 16; font.weight: Font.DemiBold }
                    ProgressBar { width: parent.width; value: installer.progress }
                    TextArea {
                        width: parent.width
                        height: parent.height - 92
                        readOnly: true
                        text: installer.log
                        color: Theme.textMuted
                        font.family: Theme.monoFont
                        font.pixelSize: 10
                        wrapMode: TextEdit.WrapAnywhere
                        background: Rectangle { radius: 10; color: "#70000000"; border.color: Theme.border }
                    }
                }
            }
        }

        Row {
            anchors.right: parent.right
            spacing: Theme.space3
            Button {
                width: 96
                text: installer.running ? "Cancel" : "Back"
                enabled: root.step > 0
                onClicked: {
                    if (installer.running)
                        installer.cancel()
                    else
                        root.step = Math.max(0, root.step - 1)
                }
            }
            Button {
                width: 132
                text: root.step === 2 ? "Erase and install" : "Continue"
                visible: root.step < 3
                enabled: root.canContinue()
                onClicked: {
                    if (root.step === 2)
                        root.beginInstall()
                    else
                        root.step += 1
                }
            }
        }
    }
}
