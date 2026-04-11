import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar as Bar

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless

    // ── Propriedades reativas ──
    readonly property var chargeState: Battery.chargeState
    readonly property bool isCharging: Battery.isCharging
    readonly property bool isPluggedIn: Battery.isPluggedIn
    readonly property real percentage: Battery.percentage
    readonly property bool isFull: Battery.isFull
    readonly property bool isLow: percentage <= Config.options.battery.low / 100
    readonly property bool isCritical: percentage <= Config.options.battery.critical / 100

    // Cor do preenchimento
    readonly property color fillColor: {
        if (root.isCritical && !root.isCharging)
            return "#E53935";
        if (root.isLow && !root.isCharging)
            return "#FB8C00";
        return "#43A047";
    }

    // Cor da moldura
    readonly property color frameColor: {
        if (root.isCritical && !root.isCharging)
            return Appearance.m3colors.m3error;
        if (root.isLow && !root.isCharging)
            return Appearance.m3colors.m3error;
        return Appearance.colors.colOnSecondaryContainer;
    }

    implicitWidth: Appearance.sizes.baseVerticalBarWidth
    implicitHeight: Config.options.battery.style === "android16" ? (14 * 2) + 12 : batteryContainer.height + 12

    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined

    Loader {
        anchors.centerIn: parent
        active: Config.options.battery.style === "android16"
        sourceComponent: Android16Battery {
            height: 14
            width: height * 2
            batteryLevel: Math.round(root.percentage * 100)
            isCharging: root.isCharging || root.isPluggedIn
            isPowerSaving: false
        }    }

    Item {
        id: batteryContainer
        visible: Config.options.battery.style !== "android16"
        anchors.centerIn: parent
        height: 14
        width: height * (28 / 13)

        // ── Camada 1: Fill (sem clipping, com rounding próprio) ──
        Rectangle {
            id: fillBar
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 3

            readonly property real bodyInnerWidth: (parent.width * (24 / 28)) - 6
            readonly property real clampedPct: Math.max(0, Math.min(1, root.percentage))

            height: parent.height - 6
            width: Math.max(0, bodyInnerWidth * clampedPct)
            radius: 1.5
            color: root.fillColor
            z: 0

            Behavior on width {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }
        }

        // ── Camada 2: Moldura SVG ──
        CustomIcon {
            anchors.fill: parent
            source: "Battery.svg"
            colorize: true
            color: root.frameColor
            z: 1

            Behavior on color {
                ColorAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }
        }

        // ── Camada 3: Bolt outline (knockout — cor de fundo anula fill e frame) ──
        MaterialSymbol {
            visible: root.isCharging || root.isPluggedIn

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: -(parent.width * (4 / 28)) / 2

            anchors.top: parent.top
            anchors.topMargin: -5

            text: "bolt"
            iconSize: 17
            fill: 1
            color: Appearance.colors.colLayer0
            z: 2
        }

        // ── Camada 4: Bolt principal (por cima do knockout) ──
        MaterialSymbol {
            visible: root.isCharging || root.isPluggedIn

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: -(parent.width * (4 / 28)) / 2

            anchors.top: parent.top
            anchors.topMargin: -6

            text: "bolt"
            iconSize: 16
            fill: 1
            color: Appearance.colors.colOnSecondaryContainer
            z: 3
        }
    }

    Bar.BatteryPopup {
        id: batteryPopup
        hoverTarget: root
    }
}
