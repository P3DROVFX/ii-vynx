import QtQuick
import qs.modules.common
import qs.services
import qs

Item {
    id: root
    
    readonly property string dockEffectivePosition: {
        const pos = Config.options?.dock.position ?? "bottom"
        if (pos !== "auto") return pos
        return (Config.options?.bar.bottom && !Config.options?.bar.vertical) ? "top" : "bottom"
    }
    readonly property bool isVertical: dockEffectivePosition === "left" || dockEffectivePosition === "right"
    property real marginScale: 0.2
    property color color: Appearance.colors.colOutlineVariant

    Rectangle {
        id: line
        readonly property real currentMargin: Math.round((root.isVertical 
            ? root.width : root.height) * root.marginScale)

        anchors.centerIn: parent
        width: root.isVertical ? root.width - currentMargin * 2 : root.width
        height: root.isVertical ? root.height : root.height - currentMargin * 2
        radius: Appearance.rounding.full
        color: root.color
    }
}