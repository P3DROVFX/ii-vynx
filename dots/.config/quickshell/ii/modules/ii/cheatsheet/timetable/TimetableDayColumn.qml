import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material
import qs.modules.common.functions
import "."
import "TimetableHelpers.js" as H

Item {
    id: dayColumn

    property int dayIdx
    property var dayData
    property bool isToday
    property real dayColumnWidth
    property real contentHeight
    property real pixelsPerMinute
    property int startHour
    property int startMinute
    property int snapInterval
    
    // Ghost state
    property bool ghostVisible
    property int ghostDayIndex
    property real ghostTopY
    property real ghostHeight

    // Drag state (internal or external)
    property bool isDragging: false
    property int dragDayIndex: -1
    property real dragStartY: 0
    property real dragCurrentY: 0

    // For events
    property var nextEventData
    property real maxLogicalDistance: 1.0

    // Colors
    property color todayHighlightFill
    property color todayHighlightBorder
    property color dayBackgroundFill
    property color dayBackgroundFillVariant

    signal dragRequestInteractivity(bool interactive)
    signal dragStarted(int dayIndex, real startY)
    signal dragPositionChanged(int dayIndex, real currentY)
    signal dragReleased(int dayIndex, real startY, real currentY)
    signal editRequested(var event, int dayIndex)

    width: dayColumnWidth
    height: contentHeight
    clip: true

    readonly property var timedEvents: H.getTimedEvents(dayData.events)

    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.windowRounding
        color: isToday ? todayHighlightFill : dayIdx % 2 == 0 ? dayBackgroundFill : dayBackgroundFillVariant
        border.width: isToday ? 1 : 0
        border.color: isToday ? todayHighlightBorder : "transparent"
    }

    // ─── Drag-to-create MouseArea ─────────────
    MouseArea {
        id: dayDragArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: ghostVisible && ghostDayIndex === dayIdx ? Qt.ArrowCursor : Qt.CrossCursor
        z: 0

        onPressed: function (mouse) {
            if (ghostVisible) return;
            dragRequestInteractivity(false);
            isDragging = true;
            dragDayIndex = dayIdx;
            dragStartY = mouse.y;
            dragCurrentY = mouse.y;
            dragStarted(dayIdx, mouse.y);
        }

        onPositionChanged: function (mouse) {
            if (isDragging && dragDayIndex === dayIdx) {
                dragCurrentY = Math.max(0, Math.min(mouse.y, contentHeight));
                dragPositionChanged(dayIdx, dragCurrentY);
            }
        }

        onReleased: function (mouse) {
            dragRequestInteractivity(true);
            if (isDragging && dragDayIndex === dayIdx) {
                isDragging = false;
                dragReleased(dayIdx, dragStartY, dragCurrentY);
                dragDayIndex = -1;
            }
        }

        onCanceled: {
            dragRequestInteractivity(true);
            isDragging = false;
            dragDayIndex = -1;
        }
    }

    // ─── Drag preview (during drag) ───────────
    Rectangle {
        id: dragPreview
        visible: isDragging && dragDayIndex === dayIdx
        width: parent.width - 10
        anchors.horizontalCenter: parent.horizontalCenter
        radius: Appearance.rounding.normal
        color: H.withOpacity(Appearance.colors.colPrimary, 0.25)
        border.width: 2
        border.color: H.withOpacity(Appearance.colors.colPrimary, 0.6)
        z: 5

        y: {
            let topMin = H.snapToGrid(H.yToMinutes(Math.min(dragStartY, dragCurrentY), startHour, startMinute, pixelsPerMinute), snapInterval);
            return H.minutesToY(topMin, startHour, startMinute, pixelsPerMinute);
        }
        height: {
            let topMin = H.snapToGrid(H.yToMinutes(Math.min(dragStartY, dragCurrentY), startHour, startMinute, pixelsPerMinute), snapInterval);
            let botMin = H.snapToGrid(H.yToMinutes(Math.max(dragStartY, dragCurrentY), startHour, startMinute, pixelsPerMinute), snapInterval);
            if (botMin - topMin < snapInterval)
                botMin = topMin + snapInterval;
            return H.minutesToY(botMin, startHour, startMinute, pixelsPerMinute) - H.minutesToY(topMin, startHour, startMinute, pixelsPerMinute);
        }

        StyledText {
            anchors.centerIn: parent
            text: {
                let topMin = H.snapToGrid(H.yToMinutes(Math.min(dragStartY, dragCurrentY), startHour, startMinute, pixelsPerMinute), snapInterval);
                let botMin = H.snapToGrid(H.yToMinutes(Math.max(dragStartY, dragCurrentY), startHour, startMinute, pixelsPerMinute), snapInterval);
                if (botMin - topMin < snapInterval)
                    botMin = topMin + snapInterval;
                return H.minutesToTimeStr(topMin, Config.options?.time.format) + " — " + H.minutesToTimeStr(botMin, Config.options?.time.format);
            }
            font.weight: Font.Medium
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colPrimary
        }
    }

    // ─── Ghost block (post-drag, before confirm) ──
    Rectangle {
        id: ghostBlock
        visible: ghostVisible && ghostDayIndex === dayIdx
        width: parent.width - 10
        anchors.horizontalCenter: parent.horizontalCenter
        radius: Appearance.rounding.normal
        color: H.withOpacity(Appearance.colors.colPrimary, 0.35)
        border.width: 2
        border.color: Appearance.colors.colPrimary
        z: 8
        y: ghostTopY
        height: ghostHeight

        Column {
            anchors {
                fill: parent
                margins: 8
            }
            spacing: 2

            StyledText {
                text: Translation.tr("New event")
                font.weight: Font.DemiBold
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnPrimary
                visible: parent.height > 40
            }

            StyledText {
                text: {
                    let topMin = H.snapToGrid(H.yToMinutes(ghostTopY, startHour, startMinute, pixelsPerMinute), snapInterval);
                    let botMin = H.snapToGrid(H.yToMinutes(ghostTopY + ghostHeight, startHour, startMinute, pixelsPerMinute), snapInterval);
                    return H.minutesToTimeStr(topMin, Config.options?.time.format) + " — " + H.minutesToTimeStr(botMin, Config.options?.time.format);
                }
                font.weight: Font.Medium
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnPrimary
            }
        }
    }

    // ─── Existing event blocks ────────────────
    Repeater {
        model: H.computeEventLayout(dayData.events, H.parseTimeToMinutes)
        delegate: EventBlock {
            eventData: modelData.event
            colIndex: modelData.colIndex
            totalCols: modelData.totalCols
            dayIdx: dayColumn.dayIdx
            nextEventData: dayColumn.nextEventData
            maxLogicalDistance: dayColumn.maxLogicalDistance
            pixelsPerMinute: dayColumn.pixelsPerMinute
            startHour: dayColumn.startHour
            startMinute: dayColumn.startMinute
            onEditRequested: (evt, dIdx) => dayColumn.editRequested(evt, dIdx)
        }
    }
}
