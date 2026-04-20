import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    // Native Process avoids qs ipc call round-trip from external shell
    Process {
        id: hyprpickerProcess
        command: ["bash", "-c", "sleep 0.2; hyprpicker -a -f hex"]
        stdout: SplitParser {
            onRead: data => {
                let hex = data.trim();
                if (hex.startsWith("#") && hex.length >= 7) {
                    GlobalStates.pickColor(hex);
                }
            }
        }
    }

    GlobalShortcut {
        name: "colorPickerLaunch"
        description: "Launch color picker (hyprpicker) and show popup with palette"
        onPressed: {
            hyprpickerProcess.running = false;
            Qt.callLater(() => {
                hyprpickerProcess.running = true;
            });
        }
    }

    IpcHandler {
        target: "colorPickerLaunch"
        function trigger(): void {
            hyprpickerProcess.running = false;
            Qt.callLater(() => {
                hyprpickerProcess.running = true;
            });
        }
    }

    Connections {
        target: GlobalStates
        function onDashboardPanelOpenChanged() {
            if (GlobalStates.dashboardPanelOpen) {
                GlobalStates.colorPickerPopupOpen = false;
            }
        }
        function onPoliciesPanelOpenChanged() {
            if (GlobalStates.policiesPanelOpen) {
                GlobalStates.colorPickerPopupOpen = false;
            }
        }
    }

    LazyLoader {
        id: popupLoader
        active: GlobalStates.colorPickerPopupOpen

        component: PanelWindow {
            id: popupWindow
            color: "transparent"
            visible: true
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

            WlrLayershell.namespace: "quickshell:colorPickerPopup"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0

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
                right: {
                    if (Config.options.bar.vertical) {
                        return Appearance.sizes.verticalBarWidth;
                    }
                    return Appearance.sizes.hyprlandGapsOut + 4;
                }
            }

            implicitWidth: popupContent.implicitWidth
            implicitHeight: popupContent.implicitHeight

            mask: Region {
                item: popupContent.contentBackground
            }

            ColorPickerPopupContent {
                id: popupContent
                colorHex: GlobalStates.colorPickerPopupColor

                onDismissed: {
                    GlobalStates.colorPickerPopupOpen = false;
                }
            }
        }
    }
}
