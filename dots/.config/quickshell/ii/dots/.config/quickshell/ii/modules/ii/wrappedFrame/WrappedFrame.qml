import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: wrappedFrame

    property int frameThickness: Config.options.appearance.wrappedFrameThickness
    property bool barVertical: Config.options.bar.vertical
    property bool barBottom: Config.options.bar.bottom

    component HorizontalFrame: PanelWindow {
        id: cornerPanelWindow
        property bool showBackground: true

        color: showBackground ? Appearance.colors.colLayer0 : "transparent"
        implicitWidth: frameThickness;implicitHeight: frameThickness

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        anchors {
            left: true
            right: true
        }
    }

    component VerticalFrame: PanelWindow {
        id: cornerPanelWindow
        property bool showBackground: true

        color: showBackground ? Appearance.colors.colLayer0 : "transparent"
        implicitWidth: frameThickness;implicitHeight: frameThickness

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        anchors {
            bottom: true
            top: true
        }
    }

    component ScreenCorner: PanelWindow {
        id: screenCornerWindow
        property bool left
        property bool bottom
        property bool showBackground: true
        screen: monitorScope.modelData
        anchors {
            bottom: bottom
            top: !bottom
            left: left
            right: !left
        }
        implicitHeight: Appearance.rounding.screenRounding
        implicitWidth: Appearance.rounding.screenRounding
        color: "transparent"
            
        RoundCorner {
            id: leftCorner
            anchors {
                top: !bottom ? parent.top : undefined
                bottom: bottom ? parent.bottom : undefined
                left: left ? parent.left : undefined
                right: !left ? parent.right : undefined
            }

            implicitSize: Appearance.rounding.screenRounding
            color: showBackground ? Appearance.colors.colLayer0 : "transparent"

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }

            corner: screenCornerWindow.left ? 
                (screenCornerWindow.bottom ? RoundCorner.CornerEnum.BottomLeft : RoundCorner.CornerEnum.TopLeft) :
                (screenCornerWindow.bottom ? RoundCorner.CornerEnum.BottomRight : RoundCorner.CornerEnum.TopRight)
        }
    }

    Loader {
        active: Config.options.appearance.fakeScreenRounding == 3
        sourceComponent: Variants {
            id: wrappedFrameVariant
            property var variantModel: Quickshell.screens
            model: variantModel

            Scope {
                id: monitorScope
                required property var modelData

                property int index: wrappedFrameVariant.variantModel.indexOf(monitorScope.modelData)
                property bool hasActiveWindows: false
                property bool showBarBackground: monitorScope.hasActiveWindows && Config.options.bar.barBackgroundStyle === 2 || Config.options.bar.barBackgroundStyle === 1

                Connections {
                    enabled: Config.options.bar.barBackgroundStyle === 2
                    target: HyprlandData
                    function onWindowListChanged() {
                        const monitor = HyprlandData.monitors.find(m => m.id === monitorScope.index);
                        const wsId = monitor?.activeWorkspace?.id;

                        const hasWindow = wsId ? HyprlandData.windowList.some(w => w.workspace.id === wsId && !w.floating) : false;

                        monitorScope.hasActiveWindows = hasWindow
                    }
                }

                // SCREEN CORNERS
                Loader {
                    active: !(barBottom && !barVertical) && !(barVertical && !barBottom)
                    sourceComponent: ScreenCorner {
                        left: true
                        bottom: true
                        showBackground: monitorScope.showBarBackground
                    }
                }
                Loader {
                    active: barBottom
                    sourceComponent: ScreenCorner {
                        left: true
                        bottom: false
                        showBackground: showBarBackground
                    }
                }
                Loader {
                    active: !(!barBottom && !barVertical) && !(barVertical && barBottom)
                    sourceComponent: ScreenCorner {
                        left: false
                        bottom: false
                        showBackground: monitorScope.showBarBackground
                    }
                }
                Loader {
                    active:  !barBottom
                    sourceComponent: ScreenCorner {
                        left: false
                        bottom: true
                        showBackground: showBarBackground
                    }
                }

                // FRAMES

                Loader {
                    active: !(!barVertical && barBottom)
                    sourceComponent: HorizontalFrame {
                        screen: monitorScope.modelData
                        anchors.bottom: true
                        showBackground: monitorScope.showBarBackground
                    }
                }
                Loader {
                    active: !(!barVertical && !barBottom)
                    sourceComponent: HorizontalFrame {
                        screen: monitorScope.modelData
                        anchors.top: true
                        showBackground: showBarBackground
                    }
                }
                Loader {
                    active: !(barVertical && barBottom)
                    sourceComponent: VerticalFrame {
                        screen: monitorScope.modelData
                        anchors.right: true
                        showBackground: showBarBackground
                    }
                }
                Loader {
                    active: !(barVertical && !barBottom)
                    sourceComponent: VerticalFrame {
                        screen: monitorScope.modelData
                        anchors.left: true
                        showBackground: showBarBackground
                    }
                }
            }
        }
    }
}