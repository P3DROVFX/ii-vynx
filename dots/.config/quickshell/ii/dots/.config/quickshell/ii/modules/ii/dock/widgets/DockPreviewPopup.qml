import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

import "../"

PopupWindow {
    id: previewPopup

    property var dockRoot: null
    property var appTopLevel: null
    property var dockWindow: null

    readonly property bool isVertical: dockRoot?.isVertical ?? false
    readonly property string dockPos: dock.dockEffectivePosition
    
    readonly property int maxPreviews: {
        if (!dockWindow || !dockRoot) return 1

        const spacing = 6
        const previewSize = isVertical ? dockRoot.maxWindowPreviewHeight + dockRoot.windowControlsHeight : dockRoot.maxWindowPreviewWidth

        const availableSpace = isVertical ? (dockWindow.height ?? 1080) - popupBackground.margins * 2 - popupBackground.padding * 2 : (dockWindow.width ?? 1920) - popupBackground.margins * 2 - popupBackground.padding * 2
        return Math.max(1, Math.floor((availableSpace + spacing) / (previewSize + spacing)))
    }

    property bool show: false
    readonly property bool shouldShow:
        !dockRoot.dragActive &&
        !dockRoot.anyContextMenuOpen &&
        (backgroundHover.hovered || dockRoot.buttonHovered || dockRoot.popupIsResizing) &&
        (appTopLevel?.toplevels?.length > 0)

    onShouldShowChanged: {
        if (shouldShow)
            show = true
        else if (dockRoot.anyContextMenuOpen)
            show = false
        else
            hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 150
        onTriggered: previewPopup.show = previewPopup.shouldShow
    }

    visible: show || popupBackground.opacity > 0
    color: "transparent"

    anchor {
        window: dockWindow
        adjustment: PopupAdjustment.None

        rect {
            x: dockPos === "left" ? (dockWindow?.width ?? 0) : 0
            y: dockPos === "bottom" ? 0 : dockPos === "top" ? (dockWindow?.height ?? 0) : 0
        }

        gravity: {
            if (dockPos === "left") return Edges.Right | Edges.Bottom
            if (dockPos === "right") return Edges.Left | Edges.Bottom
            if (dockPos === "top") return Edges.Bottom | Edges.Right
            return Edges.Top | Edges.Right
        }

        edges: Edges.Top | Edges.Left
    }

    readonly property int _extra: popupBackground.padding * 2 + popupBackground.margins * 2

    implicitWidth: isVertical ? dockRoot.maxWindowPreviewWidth + dockRoot.windowControlsHeight + _extra - 25 : dockWindow?.width ?? 0
    implicitHeight: isVertical ? dockWindow?.height ?? 0 : dockRoot.maxWindowPreviewHeight + dockRoot.windowControlsHeight + _extra + 5

    StyledRectangularShadow {
        target: popupBackground
        opacity: popupBackground.opacity
        visible: popupBackground.visible
    }

    Rectangle {
        id: popupBackground

        property real margins: 5
        property real padding: 6

        onImplicitWidthChanged: { dockRoot.popupIsResizing = true; resizeTimer.restart() }
        onImplicitHeightChanged: { dockRoot.popupIsResizing = true; resizeTimer.restart() }

        Timer {
            id: resizeTimer
            interval: 500
            onTriggered: dockRoot.popupIsResizing = false
        }

        readonly property real _clampedX: Math.max(margins, Math.min(dockRoot.hoveredButtonCenter.x - implicitWidth  / 2, parent.width  - implicitWidth  - margins))
        readonly property real _clampedY: Math.max(margins, Math.min(dockRoot.hoveredButtonCenter.y - implicitHeight / 2, parent.height - implicitHeight - margins))
        x: isVertical ? (dockPos === "left" ? margins : parent.width - implicitWidth - margins) : _clampedX
        y: isVertical ? _clampedY : (dockPos === "top" ? margins : parent.height - implicitHeight - margins)

        opacity: previewPopup.show ? 1 : 0
        visible: (appTopLevel?.toplevels?.length ?? 0) > 0
        clip: true
        color: Appearance.m3colors.m3surfaceContainer
        radius: Appearance.rounding.normal
        implicitHeight: previewRowLayout.implicitHeight + padding * 2
        implicitWidth: previewRowLayout.implicitWidth + padding * 2

        Behavior on implicitWidth {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on implicitHeight {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(previewPopup)
        }

        HoverHandler {
            id: backgroundHover
        }

        GridLayout {
            id: previewRowLayout
            anchors {
                top: parent.top
                left: parent.left
                topMargin: popupBackground.padding
                leftMargin: popupBackground.padding
            }
            flow: isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
            columnSpacing: 6
            rowSpacing: 6

            Repeater {
                model: ScriptModel { values: (appTopLevel?.toplevels ?? []).slice(0, previewPopup.maxPreviews) }

                delegate: RippleButton {
                    id: windowButton
                    required property var modelData
                    padding: 0

                    onClicked: {
                        modelData?.activate()
                        dockRoot.buttonHovered = false
                        dockRoot.lastHoveredButton = null
                    }
                    middleClickAction: () => modelData?.close()

                    contentItem: ColumnLayout {
                        implicitWidth: screencopyView.implicitWidth
                        implicitHeight: screencopyView.implicitHeight

                        ButtonGroup {
                            contentWidth: parent.width - anchors.margins * 2

                            WrapperRectangle {
                                Layout.fillWidth: true
                                color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer)
                                radius: Appearance.rounding.small
                                margin: 5

                                StyledText {
                                    Layout.fillWidth: true
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    text: windowButton.modelData?.title ?? ""
                                    elide: Text.ElideRight
                                    color: Appearance.m3colors.m3onSurface
                                }
                            }

                            RippleButton {
                                id: closeButton
                                colBackground: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer)
                                implicitWidth: dockRoot.windowControlsHeight
                                implicitHeight: dockRoot.windowControlsHeight
                                buttonRadius: Appearance.rounding.full

                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "close"
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: Appearance.m3colors.m3onSurface
                                }
                                onClicked: windowButton.modelData?.close()
                            }
                        }

                        ScreencopyView {
                            id: screencopyView
                            captureSource: previewPopup.visible ? windowButton.modelData : null
                            live: true
                            paintCursor: true
                            constraintSize: Qt.size(
                                dockRoot.maxWindowPreviewWidth,
                                dockRoot.maxWindowPreviewHeight
                            )
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: screencopyView.width
                                    height: screencopyView.height
                                    radius: Appearance.rounding.small
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
