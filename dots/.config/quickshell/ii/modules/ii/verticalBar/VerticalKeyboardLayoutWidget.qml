import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.ii.bar as Bar

MouseArea {
    id: root

    readonly property bool hasMultipleLayouts: HyprlandXkb.layoutCodes.length > 1

    visible: HyprlandXkb.layoutCodes.length > 1

    implicitWidth: Appearance.sizes.baseVerticalBarWidth
    implicitHeight: visible ? layout.implicitHeight + 12 : 0

    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    function abbreviateLayoutCode(fullCode) {
        if (!fullCode)
            return "";
        return fullCode.split(':').map(layout => {
            const baseLayout = layout.split('-')[0];
            return baseLayout.slice(0, 2);
        }).join('\n').toUpperCase();
    }

    Process {
        id: switchProc
        command: ["bash", "-c", "hyprctl switchxkblayout all next"]
    }

    onClicked: {
        if (hasMultipleLayouts) {
            switchProc.running = false
            switchProc.running = true
        }
    }

    ColumnLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 2

        MaterialSymbol {
            Layout.alignment: Qt.AlignHCenter
            iconSize: Appearance.font.pixelSize.large
            text: "keyboard"
            color: Appearance.colors.colOnLayer1
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.abbreviateLayoutCode(HyprlandXkb.currentLayoutCode)
            font.pixelSize: Appearance.font.pixelSize.small
            font.family: Appearance.font.family.title
            color: Appearance.colors.colOnLayer1
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignHCenter
            animateChange: true
        }
    }

    Bar.KeyboardLayoutPopup {
        id: popup
        hoverTarget: root
    }
}
