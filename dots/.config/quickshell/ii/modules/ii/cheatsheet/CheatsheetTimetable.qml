import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material
import qs.modules.common.functions

Item {
    id: root
    property real spacing: 8

    readonly property bool eventPopupVisible: eventPopup.visible

    property int startHour: 0
    property int startMinute: 0
    property int endHour: 24
    property int slotDuration: 60 // in minutes
    property int slotHeight: 120 // in pixels
    property int timeColumnWidth: 100
    property real maxContentWidth: 1350

    readonly property int totalSlots: Math.floor(((endHour * 60) - (startHour * 60 + startMinute)) / slotDuration)
    readonly property real pixelsPerMinute: slotHeight / slotDuration
    readonly property int contentHeight: totalSlots * slotHeight

    property real maxHeight: 700
    property real headerHeight: 64 + (hasAllDayEvents ? maxAllDayEventCount * (allDayChipHeight + allDayChipSpacing) + 8 : 0) // Dynamic height for all-day events
    property real currentTimeY: -1
    property bool initialScrollApplied: false
    readonly property real dayColumnWidth: Math.min(180, (maxContentWidth - timeColumnWidth - (days.length + 1) * spacing) / days.length)
    readonly property int currentDayIndex: (DateTime.clock.date.getDay() - Config.options.time.firstDayOfWeek + 6) % 7

    implicitWidth: Math.min(maxContentWidth, timeColumnWidth + (dayColumnWidth * days.length) + ((days.length + 1) * spacing))
    implicitHeight: Math.min(headerHeight + contentHeight, maxHeight)
    property var days: CalendarService.eventsInWeek
    readonly property int allDayChipHeight: 36
    readonly property int allDayChipSpacing: 6
    readonly property int maxAllDayEventCount: {
        if (!root.days || root.days.length === 0)
            return 0;

        var maxCount = 0;
        for (var i = 0; i < root.days.length; i++) {
            var day = root.days[i];
            if (!day || !day.events)
                continue;

            var count = 0;
            for (var j = 0; j < day.events.length; j++) {
                if (root.isAllDayEvent(day.events[j]))
                    count++;
            }
            if (count > maxCount)
                maxCount = count;
        }
        return maxCount;
    }
    readonly property bool hasAllDayEvents: maxAllDayEventCount > 0
    readonly property color todayHighlightFill: withOpacity(Appearance.colors.colPrimary, 0.12)
    readonly property color todayHighlightBorder: withOpacity(Appearance.colors.colPrimary, 0.28)
    readonly property color dayBackgroundFill: withOpacity(Appearance.colors.colSecondary, 0.04)
    readonly property color dayBackgroundFillVariant: withOpacity(Appearance.colors.colSecondary, 0.08)

    // ─── Next Event & Gradient state ──────────────────────────────
    property var nextEventData: null
    property real maxLogicalDistance: 1.0

    // ─── Drag-to-create state ─────────────────────────────────────
    property bool isDragging: false
    property int dragDayIndex: -1
    property real dragStartY: 0
    property real dragCurrentY: 0

    // Ghost block state (post-drag, before popup)
    property bool ghostVisible: false
    property int ghostDayIndex: -1
    property real ghostTopY: 0
    property real ghostHeight: 0

    // Snap interval in minutes
    readonly property int snapInterval: 15

    function snapToGrid(minutes) {
        return Math.round(minutes / root.snapInterval) * root.snapInterval;
    }

    function yToMinutes(y) {
        return root.startHour * 60 + root.startMinute + (y / root.pixelsPerMinute);
    }

    function minutesToY(totalMinutes) {
        return (totalMinutes - (root.startHour * 60 + root.startMinute)) * root.pixelsPerMinute;
    }

    function minutesToTimeStr(totalMinutes) {
        let clamped = Math.max(0, Math.min(totalMinutes, 24 * 60));
        let hour = Math.floor(clamped / 60);
        let minute = Math.round(clamped % 60);
        let d = new Date();
        d.setHours(hour, minute, 0, 0);
        return Qt.formatTime(d, Config.options?.time.format ?? "hh:mm");
    }

    function minutesToKhalTimeStr(totalMinutes) {
        let clamped = Math.max(0, Math.min(totalMinutes, 24 * 60));
        let hour = Math.floor(clamped / 60);
        let minute = Math.round(clamped % 60);
        return (hour < 10 ? "0" : "") + hour + ":" + (minute < 10 ? "0" : "") + minute;
    }

    function getDateForDayIndex(dayIndex) {
        let d = new Date();
        let currentConfigDayIndex = (d.getDay() - Config.options.time.firstDayOfWeek + 6) % 7;
        d.setDate(d.getDate() - currentConfigDayIndex + dayIndex);
        return d;
    }

    function beginGhost(dayIndex, startY, endY) {
        let topY = Math.min(startY, endY);
        let botY = Math.max(startY, endY);

        // Enforce minimum 15 min
        let topMin = root.snapToGrid(root.yToMinutes(topY));
        let botMin = root.snapToGrid(root.yToMinutes(botY));
        if (botMin - topMin < root.snapInterval)
            botMin = topMin + root.snapInterval;

        root.ghostDayIndex = dayIndex;
        root.ghostTopY = root.minutesToY(topMin);
        root.ghostHeight = root.minutesToY(botMin) - root.ghostTopY;
        root.ghostVisible = true;
    }

    function openPopupForGhost() {
        let topMin = root.snapToGrid(root.yToMinutes(root.ghostTopY));
        let botMin = root.snapToGrid(root.yToMinutes(root.ghostTopY + root.ghostHeight));
        let startStr = root.minutesToTimeStr(topMin);
        let endStr = root.minutesToTimeStr(botMin);
        let eventDate = root.getDateForDayIndex(root.ghostDayIndex);

        // Calculate popup anchor position relative to root
        let colX = root.timeColumnWidth + (root.ghostDayIndex * (root.dayColumnWidth + root.spacing)) + root.dayColumnWidth;
        let colY = root.ghostTopY + root.headerHeight - styledFlickable.contentY + 20;
        eventPopup.open(startStr, endStr, eventDate, root.ghostDayIndex, colX, colY);
    }

    function cancelGhost() {
        root.ghostVisible = false;
        root.ghostDayIndex = -1;
    }

    // ─── Edit mode helpers ────────────────────────────────────────
    function openPopupForEdit(event, dayIndex) {
        let startMin = root.parseTimeToMinutes(event.start);
        let endMin = root.parseTimeToMinutes(event.end);
        let startStr = root.minutesToTimeStr(startMin);
        let endStr = root.minutesToTimeStr(endMin);
        let eventDate = root.getDateForDayIndex(dayIndex);

        // Position popup near event
        let colX = root.timeColumnWidth + (dayIndex * (root.dayColumnWidth + root.spacing)) + root.dayColumnWidth;
        let evtY = root.minutesToY(startMin);
        let colY = evtY + root.headerHeight - styledFlickable.contentY + 20;

        eventPopup.openForEdit(startStr, endStr, eventDate, dayIndex, colX, colY, event);
    }

    // ──────────────────────────────────────────────────────────────

    function updateCurrentTimeLine() {
        let time = DateTime.clock.date;
        let hours = time.getHours();
        let minutes = time.getMinutes();

        let baseTotalMinutes = root.startHour * 60 + root.startMinute;
        let currentTotalMinutes = hours * 60 + minutes;
        let diffMinutes = currentTotalMinutes - baseTotalMinutes;

        currentTimeY = diffMinutes * root.pixelsPerMinute;
    }

    function withOpacity(colorValue, alpha) {
        if (!colorValue)
            return Qt.rgba(0, 0, 0, alpha);

        let color = Qt.color(colorValue);
        return Qt.rgba(color.r, color.g, color.b, alpha);
    }

    function isAllDayEvent(event) {
        if (!event)
            return false;

        let start = event.start || "";
        let end = event.end || "";

        return (start === "00:00" && end === "23:59") || (start === "00:00" && end === "00:00") || (!event.start && !event.end);
    }

    function getAllDayEvents(events) {
        if (!events || !events.length)
            return [];

        return events.filter(function (evt) {
            return root.isAllDayEvent(evt);
        });
    }

    function getTimedEvents(events) {
        if (!events || !events.length)
            return [];

        return events.filter(function (evt) {
            return !root.isAllDayEvent(evt);
        });
    }

    function formatEventTooltip(event) {
        if (!event)
            return "";

        let title = event.title || qsTr("Event");
        if (root.isAllDayEvent(event))
            return Translation.tr("All day event:") + "\n" + title;

        let description = event.description || "";

        let startTotal = root.parseTimeToMinutes(event.start);
        let endTotal = root.parseTimeToMinutes(event.end);

        let startStr = root.minutesToTimeStr(startTotal) || event.start || "";
        let endStr = root.minutesToTimeStr(endTotal) || event.end || "";
        let range = startStr && endStr ? startStr + " - " + endStr : startStr || endStr;
        return range ? description ? "•  " + title + "\n•  " + range + "\n•  " + description : "•  " + title + "\n•  " + range : "•  " + title;
    }

    function parseTimeToMinutes(timeStr) {
        if (!timeStr)
            return null;
        let parts = timeStr.split(":");
        if (parts.length < 2)
            return null;
        let hour = parseInt(parts[0]);
        let minute = parseInt(parts[1]);
        if (isNaN(hour) || isNaN(minute))
            return null;
        return hour * 60 + minute;
    }

    function updateNextEvent() {
        if (!root.days || root.days.length === 0) {
            root.nextEventData = null;
            root.maxLogicalDistance = 1.0;
            return;
        }

        let now = DateTime.clock.date;
        let currentDayIdx = root.currentDayIndex;
        let currentMins = now.getHours() * 60 + now.getMinutes();
        let nowTotalMins = currentDayIdx * 24 * 60 + currentMins;

        let bestDiff = Infinity;
        let nextEvt = null;

        for (let i = 0; i < root.days.length; i++) {
            let day = root.days[i];
            if (!day || !day.events) continue;
            
            let events = root.getTimedEvents(day.events);
            for (let j = 0; j < events.length; j++) {
                let evt = events[j];
                let startMins = root.parseTimeToMinutes(evt.start);
                let endMins = root.parseTimeToMinutes(evt.end);
                if (startMins === null) continue;
                if (endMins === null || (endMins === 0 && startMins > 0)) endMins = 24 * 60;
                
                let evtStartTotal = i * 24 * 60 + startMins;
                let evtEndTotal = i * 24 * 60 + endMins;

                if (evtEndTotal > nowTotalMins) {
                    let diff = evtStartTotal - nowTotalMins;
                    if (diff < 0) diff = 0;
                    
                    if (diff < bestDiff) {
                        bestDiff = diff;
                        nextEvt = {
                            dayIndex: i,
                            startMinutes: startMins,
                            endMinutes: endMins
                        };
                    }
                }
            }
        }
        
        if (!nextEvt) {
            let earliestTotal = Infinity;
            for (let i = 0; i < root.days.length; i++) {
                let day = root.days[i];
                if (!day || !day.events) continue;
                
                let events = root.getTimedEvents(day.events);
                for (let j = 0; j < events.length; j++) {
                    let evt = events[j];
                    let startMins = root.parseTimeToMinutes(evt.start);
                    if (startMins === null) continue;
                    
                    let evtStartTotal = i * 24 * 60 + startMins;
                    if (evtStartTotal < earliestTotal) {
                        earliestTotal = evtStartTotal;
                        nextEvt = {
                            dayIndex: i,
                            startMinutes: startMins,
                            endMinutes: root.parseTimeToMinutes(evt.end)
                        };
                    }
                }
            }
        }

        root.nextEventData = nextEvt;

        let maxDist = 0;
        if (nextEvt) {
            for (let i = 0; i < root.days.length; i++) {
                let day = root.days[i];
                if (!day || !day.events) continue;
                
                let events = root.getTimedEvents(day.events);
                for (let j = 0; j < events.length; j++) {
                    let evt = events[j];
                    let startMins = root.parseTimeToMinutes(evt.start);
                    if (startMins === null) continue;
                    
                    let dx = i - nextEvt.dayIndex;
                    let dy = (startMins - nextEvt.startMinutes) / 60.0;
                    let dist = Math.sqrt(dx * dx + dy * dy);
                    if (dist > maxDist) maxDist = dist;
                }
            }
        }
        root.maxLogicalDistance = Math.max(1.0, maxDist);
    }

    function lerpColor(color1, color2, factor) {
        let c1 = Qt.color(color1);
        let c2 = Qt.color(color2);
        let f = Math.max(0, Math.min(1, factor));
        let r = c1.r + (c2.r - c1.r) * f;
        let g = c1.g + (c2.g - c1.g) * f;
        let b = c1.b + (c2.b - c1.b) * f;
        let a = c1.a + (c2.a - c1.a) * f;
        return Qt.rgba(r, g, b, a);
    }

    function getEventColorRadial(dayIndex, startMinutes, nextEvtData, maxDist) {
        if (!nextEvtData) return Appearance.colors.colSurfaceContainerHigh;

        let nextDay = nextEvtData.dayIndex;
        let nextStart = nextEvtData.startMinutes;

        let dx = dayIndex - nextDay;
        let dy = (startMinutes - nextStart) / 60.0;
        
        if (dx === 0 && dy === 0) {
            return Appearance.colors.colPrimary;
        }

        let distance = Math.sqrt(dx * dx + dy * dy);
        let normalizedDist = Math.min(1.0, distance / maxDist);

        let c1, c2, ratio;
        if (normalizedDist < 0.33) {
            c1 = Appearance.colors.colPrimary;
            c2 = Appearance.colors.colSecondary;
            ratio = normalizedDist / 0.33;
        } else if (normalizedDist < 0.66) {
            c1 = Appearance.colors.colSecondary;
            c2 = Appearance.colors.colTertiary;
            ratio = (normalizedDist - 0.33) / 0.33;
        } else {
            c1 = Appearance.colors.colTertiary;
            c2 = Appearance.colors.colSurfaceContainerHighest;
            ratio = (normalizedDist - 0.66) / 0.34;
        }

        return root.lerpColor(c1, c2, ratio);
    }

    function earliestEventStartMinutes() {
        if (!root.days || root.days.length === 0)
            return -1;

        var earliest = -1;
        for (var i = 0; i < root.days.length; i++) {
            var timed = root.getTimedEvents(root.days[i]?.events);
            for (var j = 0; j < timed.length; j++) {
                var start = root.parseTimeToMinutes(timed[j].start);
                if (start === null)
                    continue;
                if (earliest === -1 || start < earliest)
                    earliest = start;
            }
        }
        return earliest;
    }

    function scrollToCurrentTime() {
        if (!styledFlickable)
            return;

        if (styledFlickable.height <= 0) {
            Qt.callLater(root.scrollToCurrentTime);
            return;
        }

        let now = DateTime.clock.date;
        let currentMinutes = now.getHours() * 60 + now.getMinutes();
        let baseMinutes = root.startHour * 60 + root.startMinute;
        let diff = currentMinutes - baseMinutes;

        if (diff < 0)
            diff = 0;

        // Position current time ~1/3 from the top of the view
        let targetY = diff * root.pixelsPerMinute - (styledFlickable.height / 3);
        targetY = Math.max(0, targetY);

        let maxScroll = Math.max(0, styledFlickable.contentHeight - styledFlickable.height);
        styledFlickable.contentY = Math.min(targetY, maxScroll);
    }

    function maybeApplyInitialScroll() {
        if (root.initialScrollApplied)
            return;

        if (!styledFlickable || styledFlickable.height <= 0 || !root.days || root.days.length === 0) {
            Qt.callLater(root.maybeApplyInitialScroll);
            return;
        }

        root.scrollToCurrentTime();
        root.initialScrollApplied = true;
    }

    Connections {
        target: DateTime.clock
        function onDateChanged() {
            root.updateCurrentTimeLine();
            root.updateNextEvent();
        }
    }

    Connections {
        target: CalendarService
        function onEventsInWeekChanged() {
            root.updateNextEvent();
            Qt.callLater(root.maybeApplyInitialScroll);
        }
    }

    Component.onCompleted: {
        root.updateCurrentTimeLine();
        root.updateNextEvent();
        Qt.callLater(root.maybeApplyInitialScroll);
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colSurfaceContainer
        radius: Appearance.rounding.large
        border.width: 1
        border.color: Appearance.colors.colOutlineVariant
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Row {
            id: headerRow
            Layout.fillWidth: true
            Layout.preferredHeight: root.headerHeight
            spacing: root.spacing

            Item {
                width: root.timeColumnWidth
                height: root.headerHeight

                // Current time indicator
                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(timeHeaderText.implicitWidth + 16, parent.width - 4)
                    height: 32
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colPrimary

                    StyledText {
                        id: timeHeaderText
                        anchors.centerIn: parent
                        text: DateTime.time
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnPrimary
                        elide: Text.ElideRight
                    }
                }
            }

            Repeater {
                model: root.days
                delegate: Item {
                    width: root.dayColumnWidth
                    height: root.headerHeight

                    property var allDayEvents: root.getAllDayEvents(modelData.events)

                    Rectangle {
                        id: dayTitleRect
                        property bool isToday: index === root.currentDayIndex

                        anchors.top: parent.top
                        anchors.topMargin: 12
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 4
                        height: 40
                        radius: Appearance.rounding.large
                        color: allDayEvents.length > 0 ? Appearance.colors.colPrimaryContainer : isToday ? Appearance.colors.colPrimary : Appearance.colors.colSurfaceContainerHigh

                        StyledText {
                            id: dayTitle
                            anchors.centerIn: parent
                            font.weight: Font.Medium
                            color: allDayEvents.length > 0 ? Appearance.colors.colOnPrimaryContainer : parent.isToday ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
                            text: modelData.name
                            elide: Text.ElideRight
                        }

                        HoverHandler {
                            id: allDayHover
                        }
                    }

                    Column {
                        anchors.top: dayTitleRect.bottom
                        anchors.topMargin: root.allDayChipSpacing
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 4
                        spacing: root.allDayChipSpacing

                        Repeater {
                            model: allDayEvents
                            delegate: Rectangle {
                                width: parent.width
                                height: root.allDayChipHeight
                                color: Appearance.colors.colSecondaryContainer
                                radius: Appearance.rounding.verysmall
                                border.width: 1
                                border.color: withOpacity(Appearance.colors.colOnSecondaryContainer, 0.1)

                                StyledText {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.title
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnSecondaryContainer
                                    elide: Text.ElideRight
                                }

                                StyledToolTip {
                                    extraVisibleCondition: allDayHover.hovered
                                    text: root.formatEventTooltip(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }

        // Subtle separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Appearance.colors.colOutlineVariant
            Layout.bottomMargin: 8
        }

        // TODO: replace or check for StyledScrollBar
        StyledFlickable {
            id: styledFlickable
            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true
            contentWidth: width
            contentHeight: root.contentHeight
            topMargin: 20
            bottomMargin: 20

            Row {
                id: contentRow
                spacing: root.spacing

                Column {
                    id: timeColumn
                    width: root.timeColumnWidth

                    Repeater {
                        model: root.totalSlots
                        delegate: Item {
                            width: parent.width
                            height: root.slotHeight

                            StyledText {
                                text: {
                                    let totalMinutes = root.startMinute + (index * root.slotDuration);
                                    return root.minutesToTimeStr(totalMinutes);
                                }
                                anchors.top: parent.top
                                anchors.topMargin: -font.pixelSize / 2
                                anchors.horizontalCenter: parent.horizontalCenter
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnSurfaceVariant
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                Row {
                    id: eventsRow
                    height: root.contentHeight
                    spacing: root.spacing

                    Repeater {
                        id: daysRepeater
                        model: root.days
                        delegate: Item {
                            id: dayColumnDelegate
                            width: root.dayColumnWidth
                            height: parent.height
                            clip: true

                            property bool isToday: index === root.currentDayIndex
                            property var timedEvents: root.getTimedEvents(modelData.events)
                            property int dayIdx: index

                            Rectangle {
                                anchors.fill: parent
                                radius: Appearance.rounding.large
                                color: isToday ? root.todayHighlightFill : index % 2 == 0 ? root.dayBackgroundFill : root.dayBackgroundFillVariant
                                border.width: isToday ? 1 : 0
                                border.color: isToday ? root.todayHighlightBorder : "transparent"
                            }

                            // ─── Drag-to-create MouseArea ─────────────
                            // This has z: 0 so event blocks (z: 3+) are on top
                            MouseArea {
                                id: dayDragArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: root.ghostVisible && root.ghostDayIndex === dayIdx ? Qt.ArrowCursor : Qt.CrossCursor
                                z: 0

                                onPressed: function (mouse) {
                                    // Don't start drag if ghost is visible (handled by ghost interactions)
                                    if (root.ghostVisible)
                                        return;

                                    // Block Flickable from intercepting the drag
                                    styledFlickable.interactive = false;

                                    root.isDragging = true;
                                    root.dragDayIndex = dayIdx;
                                    root.dragStartY = mouse.y;
                                    root.dragCurrentY = mouse.y;
                                }

                                onPositionChanged: function (mouse) {
                                    if (root.isDragging && root.dragDayIndex === dayIdx) {
                                        root.dragCurrentY = Math.max(0, Math.min(mouse.y, root.contentHeight));
                                    }
                                }

                                onReleased: function (mouse) {
                                    // Re-enable Flickable scrolling
                                    styledFlickable.interactive = true;

                                    if (root.isDragging && root.dragDayIndex === dayIdx) {
                                        root.isDragging = false;

                                        let dist = Math.abs(root.dragCurrentY - root.dragStartY);
                                        if (dist < 10) {
                                            // Single click: create a 1-hour default ghost block
                                            let clickMin = root.snapToGrid(root.yToMinutes(root.dragStartY));
                                            let endMin = clickMin + 60; // 1 hour default
                                            root.ghostDayIndex = dayIdx;
                                            root.ghostTopY = root.minutesToY(clickMin);
                                            root.ghostHeight = root.minutesToY(endMin) - root.ghostTopY;
                                            root.ghostVisible = true;
                                        } else {
                                            root.beginGhost(dayIdx, root.dragStartY, root.dragCurrentY);
                                        }
                                        root.dragDayIndex = -1;

                                        // Open popup immediately
                                        Qt.callLater(root.openPopupForGhost);
                                    }
                                }

                                onCanceled: {
                                    // Also re-enable if the press is cancelled
                                    styledFlickable.interactive = true;
                                    root.isDragging = false;
                                    root.dragDayIndex = -1;
                                }


                            }

                            // ─── Drag preview (during drag) ───────────
                            Rectangle {
                                id: dragPreview
                                visible: root.isDragging && root.dragDayIndex === dayIdx
                                width: parent.width - 10
                                anchors.horizontalCenter: parent.horizontalCenter
                                radius: Appearance.rounding.normal
                                color: withOpacity(Appearance.colors.colPrimary, 0.25)
                                border.width: 2
                                border.color: withOpacity(Appearance.colors.colPrimary, 0.6)
                                z: 5

                                y: {
                                    let topMin = root.snapToGrid(root.yToMinutes(Math.min(root.dragStartY, root.dragCurrentY)));
                                    return root.minutesToY(topMin);
                                }
                                height: {
                                    let topMin = root.snapToGrid(root.yToMinutes(Math.min(root.dragStartY, root.dragCurrentY)));
                                    let botMin = root.snapToGrid(root.yToMinutes(Math.max(root.dragStartY, root.dragCurrentY)));
                                    if (botMin - topMin < root.snapInterval)
                                        botMin = topMin + root.snapInterval;
                                    return root.minutesToY(botMin) - root.minutesToY(topMin);
                                }

                                // Time label during drag
                                StyledText {
                                    anchors.centerIn: parent
                                    text: {
                                        let topMin = root.snapToGrid(root.yToMinutes(Math.min(root.dragStartY, root.dragCurrentY)));
                                        let botMin = root.snapToGrid(root.yToMinutes(Math.max(root.dragStartY, root.dragCurrentY)));
                                        if (botMin - topMin < root.snapInterval)
                                            botMin = topMin + root.snapInterval;
                                        return root.minutesToTimeStr(topMin) + " — " + root.minutesToTimeStr(botMin);
                                    }
                                    font.weight: Font.Medium
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colPrimary
                                }
                            }

                            // ─── Ghost block (post-drag, before confirm) ──
                            Rectangle {
                                id: ghostBlock
                                visible: root.ghostVisible && root.ghostDayIndex === dayIdx
                                width: parent.width - 10
                                anchors.horizontalCenter: parent.horizontalCenter
                                radius: Appearance.rounding.normal
                                color: withOpacity(Appearance.colors.colPrimary, 0.35)
                                border.width: 2
                                border.color: Appearance.colors.colPrimary
                                z: 8
                                y: root.ghostTopY
                                height: root.ghostHeight

                                // Time label on ghost
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
                                            let topMin = root.snapToGrid(root.yToMinutes(root.ghostTopY));
                                            let botMin = root.snapToGrid(root.yToMinutes(root.ghostTopY + root.ghostHeight));
                                            return root.minutesToTimeStr(topMin) + " — " + root.minutesToTimeStr(botMin);
                                        }
                                        font.weight: Font.Medium
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnPrimary
                                    }
                                }
                            }

                            // ─── Existing event blocks ────────────────
                            Repeater {
                                model: timedEvents

                                Rectangle {
                                    id: eventBlock

                                    property bool isNextEvent: root.nextEventData && root.nextEventData.dayIndex === dayIdx && root.nextEventData.startMinutes === eventStartMinutes

                                    property int eventStartMinutes: {
                                        let parts = modelData.start.split(":");
                                        return parseInt(parts[0]) * 60 + parseInt(parts[1]);
                                    }
                                    property int eventEndMinutes: {
                                        let parts = modelData.end.split(":");
                                        let endTotal = parseInt(parts[0]) * 60 + parseInt(parts[1]);
                                        if (endTotal === 0 && eventStartMinutes > 0)
                                            endTotal = 24 * 60;
                                        return endTotal;
                                    }

                                    width: parent.width - 10
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    radius: Appearance.rounding.normal
                                    clip: true
                                    z: isNextEvent ? 4 : 3
                                    color: root.getEventColorRadial(dayIdx, eventStartMinutes, root.nextEventData, root.maxLogicalDistance)
                                    border.width: isNextEvent ? 2 : 0
                                    border.color: isNextEvent ? root.withOpacity(Appearance.colors.colOnPrimary, 0.8) : "transparent"
                                    y: root.minutesToY(eventStartMinutes)
                                    height: Math.max((eventEndMinutes - eventStartMinutes) * root.pixelsPerMinute - 4, 48)

                                    // Decorative watermark icon for the next event
                                    MaterialSymbol {
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        anchors.margins: -10
                                        text: "event_upcoming"
                                        font.pixelSize: Math.min(parent.height, parent.width) * 0.8
                                        color: ColorUtils.getContrastingTextColor(eventBlock.color)
                                        opacity: 0.15
                                        visible: isNextEvent
                                        z: 0
                                        antialiasing: true
                                    }

                                    HoverHandler {
                                        id: eventHover
                                    }

                                    StyledToolTip {
                                        extraVisibleCondition: eventHover.hovered
                                        text: root.formatEventTooltip(modelData)
                                    }

                                    // Click to edit
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.openPopupForEdit(modelData, dayIdx)
                                    }

                                    // Delete button
                                    RippleButton {
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 4
                                        implicitWidth: 24
                                        implicitHeight: 24
                                        buttonRadius: Appearance.rounding.full
                                        buttonColor: withOpacity(Appearance.colors.colOnSurface, 0.15)
                                        opacity: eventHover.hovered ? 1 : 0
                                        visible: opacity > 0
                                        z: 15

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: Appearance.animation.elementMoveFast.duration
                                                easing.type: Appearance.animation.elementMoveFast.type
                                                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                            }
                                        }

                                        onClicked: {
                                            if (modelData.uid) {
                                                CalendarService.removeEventByUid(modelData.uid);
                                            } else {
                                                CalendarService.removeEvent(modelData.title);
                                            }
                                        }

                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            horizontalAlignment: Text.AlignHCenter
                                            font.pixelSize: Appearance.font.pixelSize.smallie
                                            text: "close"
                                            color: ColorUtils.getContrastingTextColor(eventBlock.color)
                                        }
                                    }

                                    // Event content
                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 4
                                        z: 1

                                        StyledText {
                                            text: modelData.title
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                            width: parent.width - 28
                                            color: ColorUtils.getContrastingTextColor(eventBlock.color)
                                        }

                                        Row {
                                            spacing: 6
                                            width: parent.width
                                            // Show row if it's the next event OR if there is enough height for the time
                                            visible: eventBlock.isNextEvent || eventBlock.height > 60

                                            Rectangle {
                                                visible: eventBlock.isNextEvent
                                                width: nextText.implicitWidth + 8
                                                height: nextText.implicitHeight + 2
                                                color: ColorUtils.getContrastingTextColor(eventBlock.color)
                                                radius: Appearance.rounding.full
                                                anchors.verticalCenter: parent.verticalCenter

                                                StyledText {
                                                    id: nextText
                                                    anchors.centerIn: parent
                                                    text: "NEXT"
                                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                                    font.weight: Font.Bold
                                                    color: eventBlock.color
                                                }
                                            }

                                            StyledText {
                                                text: root.minutesToTimeStr(eventBlock.eventStartMinutes) + " - " + root.minutesToTimeStr(eventBlock.eventEndMinutes)
                                                font.weight: Font.Medium
                                                color: ColorUtils.getContrastingTextColor(eventBlock.color)
                                                elide: Text.ElideRight
                                                anchors.verticalCenter: parent.verticalCenter
                                                // Only hide the text itself if not enough space and it's NOT the next event
                                                visible: eventBlock.height > 60 || eventBlock.isNextEvent
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: currentTimeLine
                width: contentRow.width + 20
                height: 3
                color: Appearance.colors.colPrimary
                y: root.currentTimeY
                visible: root.currentTimeY >= 0 && root.currentTimeY <= contentRow.height
                z: 10
                radius: Appearance.rounding.unsharpen

                // Material 3 time chip
                Rectangle {
                    x: (timeColumn.width / 2) - (width / 2)
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(timeText.implicitWidth + 20, timeColumn.width - 4)
                    height: 32
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colPrimary

                    StyledText {
                        id: timeText
                        anchors.centerIn: parent
                        text: DateTime.time
                        color: Appearance.colors.colOnPrimary
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    // ─── Floating Indicator for Next Event ────────────────────────
    Rectangle {
        id: nextEventIndicator
        
        property real nextEventY: root.nextEventData ? root.minutesToY(root.nextEventData.startMinutes) : -1
        property bool isAbove: root.nextEventData && (nextEventY + 20 < styledFlickable.contentY)
        property bool isBelow: root.nextEventData && (nextEventY > styledFlickable.contentY + styledFlickable.height - 40)
        
        visible: root.nextEventData !== null && (isAbove || isBelow)
        
        width: 40
        height: 40
        radius: Appearance.rounding.full
        color: Appearance.colors.colPrimary
        border.width: 1
        border.color: root.withOpacity(Appearance.colors.colOnPrimary, 0.3)
        z: 100
        antialiasing: true
        
        x: {
            if (!root.nextEventData) return 0;
            return root.timeColumnWidth + root.spacing + (root.nextEventData.dayIndex * (root.dayColumnWidth + root.spacing)) + (root.dayColumnWidth / 2) - (width / 2);
        }
        
        y: isAbove ? root.headerHeight + 20 : parent.height - height - 20
        
        MaterialSymbol {
            anchors.centerIn: parent
            text: parent.isAbove ? "arrow_upward" : "arrow_downward"
            font.pixelSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colOnPrimary
            antialiasing: true
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.nextEventData) {
                    let targetY = nextEventIndicator.nextEventY - styledFlickable.height / 3;
                    targetY = Math.max(0, targetY);
                    let maxScroll = Math.max(0, styledFlickable.contentHeight - styledFlickable.height);
                    styledFlickable.contentY = Math.min(targetY, maxScroll);
                }
            }
        }


    }

    // ─── Event Creation Popup ─────────────────────────────────────
    EventCreationPopup {
        id: eventPopup
        anchors.fill: parent
        z: 50

        onEventCreated: function (title, description) {
            let topMin = root.snapToGrid(root.yToMinutes(root.ghostTopY));
            let botMin = root.snapToGrid(root.yToMinutes(root.ghostTopY + root.ghostHeight));
            let startTimeKhal = root.minutesToKhalTimeStr(topMin);
            let endTimeKhal = root.minutesToKhalTimeStr(botMin);
            let eventDate = root.getDateForDayIndex(root.ghostDayIndex);

            CalendarService.addEvent(eventDate, startTimeKhal, endTimeKhal, title, description);
            root.cancelGhost();
        }

        onEventUpdated: function (oldTitle, title, description) {
            // Remove old event and create new one with updated info
            // Note: khal doesn't support updating events directly, so we delete and recreate
            let eventData = eventPopup.editEventData;
            if (!eventData)
                return;

            let startMin = root.parseTimeToMinutes(eventData.start);
            let endMin = root.parseTimeToMinutes(eventData.end);
            if (endMin === 0 && startMin > 0)
                endMin = 24 * 60;

            let startTimeKhal = root.minutesToKhalTimeStr(startMin);
            let endTimeKhal = root.minutesToKhalTimeStr(endMin);
            let eventDate = root.getDateForDayIndex(eventPopup.dayIndex);

            // Use UID if available for precise deletion
            if (eventData.uid) {
                CalendarService.removeEventByUid(eventData.uid);
            } else {
                CalendarService.removeEvent(oldTitle);
            }
            CalendarService.addEvent(eventDate, startTimeKhal, endTimeKhal, title, description);
        }

        onEventDeleted: function (title) {
            let eventData = eventPopup.editEventData;
            if (eventData && eventData.uid) {
                CalendarService.removeEventByUid(eventData.uid);
            } else {
                CalendarService.removeEvent(title);
            }
            root.cancelGhost();
        }

        onCancelled: {
            root.cancelGhost();
        }
    }
}
