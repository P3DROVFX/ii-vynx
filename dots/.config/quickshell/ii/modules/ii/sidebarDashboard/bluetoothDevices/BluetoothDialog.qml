import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../bar/cards"

WindowDialog {
    id: root
    backgroundHeight: 700

    readonly property var pairedDevices: BluetoothStatus.friendlyDeviceList.filter(d => d.paired || d.connected)
    readonly property var availableDevices: BluetoothStatus.friendlyDeviceList.filter(d => !d.paired && !d.connected)

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        
        // Icon with circular background
        Rectangle {
            width: 24
            height: 24
            radius: 12
            color: Appearance.colors.colPrimaryContainer
            
            MaterialSymbol {
                anchors.centerIn: parent
                iconSize: 16
                text: "bluetooth_connected"
                color: Appearance.colors.colOnPrimaryContainer
            }
        }
        
        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Bluetooth Devices")
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.Bold
            color: Appearance.colors.colOnLayer1
        }

        StyledSwitch {
            checked: Bluetooth.defaultAdapter?.enabled ?? false
            onToggled: {
                if (Bluetooth.defaultAdapter) {
                    Bluetooth.defaultAdapter.enabled = checked;
                }
            }
        }
    }

    // Progress bar when discovering
    StyledProgressBar {
        indeterminate: true
        visible: Bluetooth.defaultAdapter?.discovering ?? false
        Layout.fillWidth: true
        Layout.topMargin: -4
        Layout.bottomMargin: -4
    }

    // Paired/Connected devices section
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        visible: (Bluetooth.defaultAdapter?.enabled ?? false) && root.pairedDevices.length > 0

        Repeater {
            model: ScriptModel {
                values: root.pairedDevices
            }
            delegate: BluetoothDeviceItem {
                required property BluetoothDevice modelData
                required property int index
                device: modelData
                isFirst: index === 0
                isLast: index === root.pairedDevices.length - 1
                isPairedSection: true
                Layout.fillWidth: true
            }
        }
    }

    // Available Devices header
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 10
        spacing: 8
        visible: (Bluetooth.defaultAdapter?.enabled ?? false) && (root.availableDevices.length > 0 || (Bluetooth.defaultAdapter?.discovering ?? false))

        // Checkmark icon with circular background
        Rectangle {
            width: 24
            height: 24
            radius: 12
            color: Appearance.colors.colPrimaryContainer
            
            MaterialSymbol {
                anchors.centerIn: parent
                iconSize: 16
                text: "bluetooth_searching"
                color: Appearance.colors.colOnPrimaryContainer
            }
        }
        
        StyledText {
            text: Translation.tr("Available Devices")
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.Bold
            color: Appearance.colors.colOnLayer1
            Layout.fillWidth: true
        }

        // Scan button with hover effect
        Rectangle {
            id: scanButton
            Layout.preferredHeight: 28
            Layout.preferredWidth: scanRow.implicitWidth + 16
            radius: 14
            color: scanMouseArea.containsPress ? Appearance.colors.colPrimaryContainerActive 
                 : scanMouseArea.containsMouse ? Appearance.colors.colPrimaryContainerHover 
                 : Appearance.colors.colPrimaryContainer

            scale: scanMouseArea.containsPress ? 0.95 : 1
            Behavior on scale {
                animation: Appearance.animation.clickBounce.numberAnimation.createObject(this)
            }

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }

            RowLayout {
                id: scanRow
                anchors.centerIn: parent
                spacing: 6

                StyledText {
                    text: Translation.tr("Scan")
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnPrimaryContainer
                }
                MaterialSymbol {
                    iconSize: 16
                    text: "search"
                    color: Appearance.colors.colOnPrimaryContainer
                }
            }

            MouseArea {
                id: scanMouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    if (Bluetooth.defaultAdapter?.discovering) {
                        Bluetooth.defaultAdapter.stopDiscovery();
                    } else {
                        Bluetooth.defaultAdapter?.startDiscovery();
                    }
                }
            }
        }
    }

    // Available devices list
    StyledListView {
        id: availableDevicesList
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 8
        visible: (Bluetooth.defaultAdapter?.enabled ?? false) && root.availableDevices.length > 0

        clip: true
        spacing: 8
        animateAppearance: false

        model: ScriptModel {
            values: root.availableDevices
        }
        delegate: BluetoothDeviceItem {
            required property BluetoothDevice modelData
            device: modelData
            width: ListView.view.width
            isPairedSection: false
        }
    }

    PagePlaceholder {
        id: offPlaceholder
        Layout.fillHeight: true
        Layout.fillWidth: true
        icon: "bluetooth_disabled"
        title: Translation.tr("Bluetooth is off")
        description: Translation.tr("Turn on Bluetooth to see devices")
        shape: MaterialShape.Shape.Cookie7Sided
        shown: !(Bluetooth.defaultAdapter?.enabled ?? false)
    }

    LoadingPlaceholder {
        id: availableDevicesPlaceholder
        Layout.fillHeight: true
        Layout.fillWidth: true
        visible: (Bluetooth.defaultAdapter?.enabled ?? false) && root.availableDevices.length === 0
        loading: Bluetooth.defaultAdapter?.discovering ?? false
        loadingText: Translation.tr("Searching...")
        emptyText: Translation.tr("No devices found")
        indicatorSize: 72
    }

    Item {
        Layout.fillHeight: true
        visible: !availableDevicesList.visible && !availableDevicesPlaceholder.visible && !offPlaceholder.visible
    }

    WindowDialogSeparator {}
    WindowDialogButtonRow {
        DialogButton {
            buttonText: Translation.tr("Details")
            onClicked: {
                Quickshell.execDetached(["bash", "-c", `${Config.options.apps.bluetooth}`]);
                GlobalStates.sidebarRightOpen = false;
            }
        }

        Item {
            Layout.fillWidth: true
        }

        DialogButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
}
