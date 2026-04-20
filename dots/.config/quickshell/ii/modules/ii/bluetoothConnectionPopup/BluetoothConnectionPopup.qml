import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    // Auto-dismiss timer
    Timer {
        id: dismissTimer
        interval: 8000
        running: GlobalStates.bluetoothConnectionPopupOpen
        onTriggered: GlobalStates.bluetoothConnectionPopupOpen = false
    }

    // Listen for new connections
    Connections {
        target: BluetoothStatus
        function onDeviceConnected(device) {
            GlobalStates.bluetoothConnectionPopupDevice = device;
            GlobalStates.bluetoothConnectionPopupOpen = true;
            dismissTimer.restart();
        }
    }

    // Listen for disconnections to close the popup if the shown device disconnects
    Connections {
        target: BluetoothStatus
        function onDeviceDisconnected(device) {
            if (GlobalStates.bluetoothConnectionPopupDevice &&
                GlobalStates.bluetoothConnectionPopupDevice.address === device.address) {
                GlobalStates.bluetoothConnectionPopupOpen = false;
            }
        }
    }

    // Dismiss popup when sidebar opens (avoids input conflicts)
    Connections {
        target: GlobalStates
        function onDashboardPanelOpenChanged() {
            if (GlobalStates.dashboardPanelOpen) {
                GlobalStates.bluetoothConnectionPopupOpen = false;
            }
        }
        function onPoliciesPanelOpenChanged() {
            if (GlobalStates.policiesPanelOpen) {
                GlobalStates.bluetoothConnectionPopupOpen = false;
            }
        }
    }

    LazyLoader {
        id: popupLoader
        active: GlobalStates.bluetoothConnectionPopupOpen

        component: PanelWindow {
            id: popupWindow
            color: "transparent"
            visible: true
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

            readonly property real screenWidth: popupWindow.screen?.width ?? 0
            readonly property real screenHeight: popupWindow.screen?.height ?? 0

            WlrLayershell.namespace: "quickshell:bluetoothConnectionPopup"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0

            // Position: anchored to top+right for horizontal bar (like other bar popups)
            anchors {
                top: Config.options.bar.vertical || (!Config.options.bar.vertical && !Config.options.bar.bottom)
                bottom: !Config.options.bar.vertical && Config.options.bar.bottom
                left: Config.options.bar.vertical && !Config.options.bar.bottom
                right: (!Config.options.bar.vertical) || (Config.options.bar.vertical && Config.options.bar.bottom)
            }

            margins {
                top: Config.options.bar.vertical ? 0 : Appearance.sizes.barHeight
                bottom: Config.options.bar.vertical ? 0 : Appearance.sizes.barHeight
                left: Config.options.bar.vertical ? Appearance.sizes.verticalBarWidth : 0
                // Push popup away from the right edge to avoid overlapping with sidebar
                right: {
                    if (Config.options.bar.vertical) {
                        return Appearance.sizes.verticalBarWidth;
                    }
                    // Position popup on the right side with some spacing from edge
                    return Appearance.sizes.hyprlandGapsOut + 4;
                }
            }

            implicitWidth: popupContent.implicitWidth
            implicitHeight: popupContent.implicitHeight

            mask: Region {
                item: popupContent.contentBackground
            }

            BluetoothConnectionPopupContent {
                id: popupContent
                device: GlobalStates.bluetoothConnectionPopupDevice

                onDismissed: {
                    GlobalStates.bluetoothConnectionPopupOpen = false;
                }
                onDisconnectRequested: {
                    if (GlobalStates.bluetoothConnectionPopupDevice) {
                        GlobalStates.bluetoothConnectionPopupDevice.connecting = false;
                        GlobalStates.bluetoothConnectionPopupDevice.connected = false;
                    }
                    GlobalStates.bluetoothConnectionPopupOpen = false;
                }
            }
        }
    }
}
