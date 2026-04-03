import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower

Rectangle {
    id: root

    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)

    implicitWidth: contentItem.implicitWidth + root.horizontalPadding * 2
    implicitHeight: contentItem.implicitHeight + root.verticalPadding * 2
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    property real verticalPadding: 4
    property real horizontalPadding: 12

    property bool showBrightness: Config.options.sidebar.quickSliders.showBrightness
    property bool showVolume: Config.options.sidebar.quickSliders.showVolume
    property bool showGamma: Config.options.sidebar.quickSliders.showGamma
    property bool showMic: Config.options.sidebar.quickSliders.showMic

    ColumnLayout {
        id: contentItem
        anchors {
            fill: parent
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
            topMargin: root.verticalPadding
            bottomMargin: root.verticalPadding
        }

        spacing: 4

        property int activeCount: {
            let count = 0;
            for (let i = 0; i < repeater.count; i++) {
                if (repeater.itemAt(i) && repeater.itemAt(i).visible)
                    count++;
            }
            return count;
        }

        Repeater {
            id: repeater
            model: [
                {
                    show: true,
                    icon: "brightness_6",
                    getVal: () => root.brightnessMonitor.brightness,
                    setVal: v => root.brightnessMonitor.setBrightness(v)
                },
                {
                    show: true,
                    icon: "volume_up",
                    getVal: () => Audio.sink.audio.volume,
                    setVal: v => {
                        Audio.sink.audio.volume = v;
                    }
                }
            ]

            QuickSlider {
                required property var modelData
                Layout.fillWidth: true
                visible: modelData.show
                materialSymbol: modelData.icon
                secondaryMaterialSymbol: modelData?.secondaryIcon ?? ""
                value: modelData.getVal()
                onMoved: modelData.setVal(value)
            }
        }
    }

    component QuickSlider: StyledSlider {
        id: quickSlider
        required property string materialSymbol
        property string secondaryMaterialSymbol
        configuration: StyledSlider.Configuration.M
        topPadding: 0
        bottomPadding: 0
        stopIndicatorValues: []
        dividerValues: secondaryMaterialSymbol.length > 0 ? [secondaryIcon.iconLocation] : []

        MaterialSymbol {
            id: icon
            property bool nearFull: quickSlider.value >= 0.82
            anchors {
                verticalCenter: quickSlider.verticalCenter
                right: nearFull ? quickSlider.handle.right : quickSlider.right
                rightMargin: nearFull ? 14 : 8
            }
            iconSize: 20
            color: nearFull ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
            text: quickSlider.materialSymbol

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
            Behavior on anchors.rightMargin {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }

        MaterialSymbol {
            id: secondaryIcon
            visible: secondaryMaterialSymbol.length > 0
            property real iconLocation: 0.3
            property bool nearIcon: iconLocation - quickSlider.value <= 0.1 && iconLocation - quickSlider.value > (quickSlider.handleWidth + 8 - 14) / quickSlider.effectiveDraggingWidth
            anchors {
                verticalCenter: quickSlider.verticalCenter
                right: nearIcon ? quickSlider.handle.right : quickSlider.right
                rightMargin: nearIcon ? 14 : (1 - iconLocation) * quickSlider.effectiveDraggingWidth + quickSlider.rightPadding + 8
            }
            iconSize: 20
            color: quickSlider.value >= iconLocation - 0.1 ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
            text: secondaryMaterialSymbol

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }
}
