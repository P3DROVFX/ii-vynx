import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool vertical: false

    // Hide entirely if there is only 1 layout and we're not vertical
    visible: HyprlandXkb.layoutCodes.length > 1

    implicitWidth: visible ? layout.implicitWidth + 16 : 0
    implicitHeight: visible ? Appearance.sizes.barHeight : 0

    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    function abbreviateLayoutCode(fullCode) {
        if (!fullCode) return "";
        return fullCode.split(':').map(layout => {
            const baseLayout = layout.split('-')[0];
            return baseLayout.slice(0, 4);
        }).join('\n').toUpperCase();
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 6

        MaterialSymbol {
            iconSize: Appearance.font.pixelSize.large
            text: "keyboard"
            color: Appearance.colors.colOnLayer1
        }

        StyledText {
            text: root.abbreviateLayoutCode(HyprlandXkb.currentLayoutCode).replace(/\n/g, ' ')
            font.pixelSize: Appearance.font.pixelSize.small
            font.family: Appearance.font.family.title
            color: Appearance.colors.colOnLayer1
            font.weight: Font.Bold
            Layout.alignment: Qt.AlignVCenter
            animateChange: true
        }
    }

    KeyboardLayoutPopup {
        id: popup
        hoverTarget: root
    }
}
