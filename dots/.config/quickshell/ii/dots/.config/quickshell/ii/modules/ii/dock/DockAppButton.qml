import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs
import QtQuick

import "./widgets"

DockButton {
    id: root

    property var appToplevel: null
    property var dockContent: null
    property int delegateIndex: -1
    property int lastFocused: -1

    readonly property real dockHeight: Config.options?.dock.height ?? 60
    property int dotMargin: Math.round(dockHeight * 0.2)

    readonly property var desktopEntry: appToplevel ? TaskbarApps.getCachedDesktopEntry(appToplevel.appId) : null
    property bool isVertical: dockContent?.isVertical ?? false


    readonly property bool appIsActive: focusedWindowIndex >= 0
    readonly property int focusedWindowIndex: { // this is computed every frame, we have to somehow cache this
        if (!appToplevel || !appToplevel.toplevels) return -1
        for (let i = 0; i < appToplevel.toplevels.length; i++) {
            if (appToplevel.toplevels[i].activated) return i
        }
        return -1
    }

    readonly property bool isDragging: dockContent?.draggedAppId === appToplevel?.appId
    readonly property string dockPos: dock.dockEffectivePosition
    readonly property bool appIsRunning: appToplevel && appToplevel.toplevels && appToplevel.toplevels.length > 0

    pointingHandCursor: false

    width: buttonSize + dotMargin * 2
    height: buttonSize + dotMargin * 2

    opacity: isDragging ? 0.0 : 1.0

    Behavior on opacity {
        enabled: !isDragging && !(dockContent?.suppressAnimation ?? false)
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    z: isDragging ? 100 : 0

    // Computes how much this delegate should shift to make room for the dragged item
    readonly property real shiftOffset: {
        if (!dockContent || !dockContent.dragActive) return 0
        if (delegateIndex === dockContent.draggedIndex) return 0

        const step = buttonSize + dotMargin * 2
        const isThisPinned = TaskbarApps.isPinned(appToplevel?.appId ?? "")
        const isDraggedPinned = TaskbarApps.isPinned(dockContent.draggedAppId)
        const intent = dockContent.dragIntent

        // Case 1: reordering among pinned apps
        if (isThisPinned && isDraggedPinned) {
            const d = dockContent.draggedIndex

            if (intent === "unpin") {
                if (delegateIndex > d) return step
                return 0
            }

            if (intent === "reorder") {
                const t = dockContent.dropTargetIndex
                if (t > d && delegateIndex > d && delegateIndex <= t) return step
                if (t < d && delegateIndex >= t && delegateIndex < d) return -step
            }
            return 0
        }

        // Case 2: pinning a running app — shift running delegates out of the way
        if (!isDraggedPinned && !isThisPinned && intent === "pin") {
            if (delegateIndex > dockContent.draggedIndex) return -step
        }

        return 0
    }

    transform: Translate {
        x: root.isVertical ? 0 : root.shiftOffset
        y: root.isVertical ? root.shiftOffset : 0

        Behavior on x {
            enabled: !root.isDragging && !(dockContent?.suppressAnimation ?? false)
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on y {
            enabled: !root.isDragging && !(dockContent?.suppressAnimation ?? false)
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    MouseArea {
        id: mainMouseArea
        width: root.buttonSize
        height: root.buttonSize
        anchors.centerIn: parent
        cursorShape: Qt.PointingHandCursor

        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        preventStealing: drag.active

        drag.target: appToplevel ? dockContent.dragGhostItem : null
        drag.axis: root.isVertical ? Drag.YAxis : Drag.XAxis
        drag.threshold: 4

        readonly property real ghostHalf: (dockContent?.dragGhostItem?.width ?? 0) / 2

        drag.minimumX: root.isVertical ? 0 : (dockContent?.pinButtonCenter ?? 0) - ghostHalf
        drag.maximumX: root.isVertical ? 0 : (dockContent?.unpinButtonCenter ?? 0) - ghostHalf
        drag.minimumY: root.isVertical ? (dockContent?.pinButtonCenter ?? 0) - ghostHalf : 0
        drag.maximumY: root.isVertical ? (dockContent?.unpinButtonCenter ?? 0) - ghostHalf : 0

        property bool wasDragging: false

        onEntered: {
            if (dockContent?.suppressHover) return
            if (appToplevel?.toplevels?.length > 0) {
                dockContent.lastHoveredButton = root
                dockContent.buttonHovered = true
            } else {
                dockContent.buttonHovered = false
                dockContent.popupIsResizing = false
            }
            if (appToplevel && appToplevel.toplevels)
                lastFocused = appToplevel.toplevels.length - 1
        }

        onExited: {
            if (dockContent?.lastHoveredButton === root)
                dockContent.buttonHovered = false
        }

        onPressed: (mouse) => {
            wasDragging = false
            if (dockContent?.dragGhostItem && appToplevel) {
                const p = root.mapToItem(dockContent, 0, 0)
                dockContent.dragGhostItem.x = p.x + root.dotMargin
                dockContent.dragGhostItem.y = p.y + root.dotMargin
            }
        }

        onPositionChanged: (mouse) => {
            if (!drag.active || !appToplevel) return
            if (!wasDragging) {
                wasDragging = true
                dockContent.startDrag(root.appToplevel.appId, root.delegateIndex)
            }
            dockContent.moveDrag()
        }

        onReleased: (mouse) => {
            if (wasDragging) {
                wasDragging = false
                dockContent.endDrag()
                return
            }
            if (mouse.button === Qt.RightButton) {
                dockContent.buttonHovered = false
                dockContent.lastHoveredButton = null
                dockContextMenu.open()
                return
            }
            if (mouse.button === Qt.MiddleButton) {
                root.desktopEntry?.execute()
                return
            }
            if (!appToplevel || appToplevel.toplevels.length === 0) {
                root.desktopEntry?.execute()
                return
            }
            // Cycle through open windows on left click
            lastFocused = (lastFocused + 1) % appToplevel.toplevels.length
            appToplevel.toplevels[lastFocused].activate()
        }
    }

    altAction: () => {
        dockContent.buttonHovered = false
        dockContent.lastHoveredButton = null
        dockContextMenu.open()
    }

    DockContextMenu {
        id: dockContextMenu
        appToplevel: root.appToplevel
        desktopEntry: root.desktopEntry
        anchorItem: root
    }

    Connections {
        target: dockContextMenu
        function onActiveChanged() {
            if (dockContent)
                dockContent.anyContextMenuOpen = dockContextMenu.active
        }
    }

    DockAppIcon {}
    DockAppIndicator {}
}
