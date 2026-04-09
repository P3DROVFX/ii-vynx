import QtQuick
import Quickshell
import Quickshell.Widgets
import qs
import qs.modules.common
import qs.modules.common.widgets

PopupWindow {
    id: rootToolTipPopup

    property Item parentItem: parent
    property string text: ""
    property bool showTooltip: false
    property int tooltipOffset: -12
    
    property string dockPosition: {
        const pos = Config.options?.dock?.position ?? "bottom"
        if (pos !== "auto") return pos
        return (Config.options?.bar?.bottom && !Config.options?.bar?.vertical) ? "top" : "bottom"
    }

    anchor.window: parentItem?.QsWindow?.window
    implicitWidth: tooltipRect.implicitWidth
    implicitHeight: tooltipRect.implicitHeight

    anchor.rect.x: {
        if (!parentItem) return 0
        let _ = parentItem.x + parentItem.y + parentItem.width + rootToolTipPopup.width
        const mapped = parentItem.mapToItem(null, 0, 0)
        
        if (dockPosition === "left") {
            return mapped.x + parentItem.width + tooltipOffset
        } else if (dockPosition === "right") {
            return mapped.x - rootToolTipPopup.width - tooltipOffset
        } else {
            return mapped.x + (parentItem.width - rootToolTipPopup.width) / 2
        }
    }
    
    anchor.rect.y: {
        if (!parentItem) return 0
        let _ = parentItem.x + parentItem.y + parentItem.height + rootToolTipPopup.height
        const mapped = parentItem.mapToItem(null, 0, 0)
        
        if (dockPosition === "top") {
            return mapped.y + parentItem.height + tooltipOffset
        } else if (dockPosition === "bottom") {
            return mapped.y - rootToolTipPopup.height - tooltipOffset
        } else {
            return mapped.y + (parentItem.height - rootToolTipPopup.height) / 2
        }
    }

    visible: showTooltip || tooltipRect.opacity > 0.01
    color: "transparent"

    Rectangle {
        id: tooltipRect
        implicitWidth: tooltipText.implicitWidth + 24
        implicitHeight: tooltipText.implicitHeight + 12
        opacity: rootToolTipPopup.showTooltip ? 1.0 : 0.0
        scale: rootToolTipPopup.showTooltip ? 1.0 : 0.8
        transformOrigin: {
            if (rootToolTipPopup.dockPosition === "top") return Item.Top
            if (rootToolTipPopup.dockPosition === "bottom") return Item.Bottom
            if (rootToolTipPopup.dockPosition === "left") return Item.Left
            if (rootToolTipPopup.dockPosition === "right") return Item.Right
            return Item.Bottom
        }

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(tooltipRect)
        }
        Behavior on scale {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(tooltipRect)
        }

        color: Appearance.m3colors.m3surfaceContainer
        radius: Appearance.rounding.small
        border.width: 1
        border.color: Appearance.colors.colLayer0Border

        StyledText {
            id: tooltipText
            anchors.centerIn: parent
            text: rootToolTipPopup.text
            color: Appearance.colors.colOnSurface
            font.pixelSize: Appearance.font.pixelSize.small
        }
    }
}
