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
    property color backgroundColor: "transparent"

    property int startHour: 0
    property int startMinute: 0
    property int endHour: 24
    property int slotDuration: 60 // in minutes
    property int slotHeight: 60 // in pixels
    property int timeColumnWidth: 100
    property real maxContentWidth: 1350

    readonly property int totalSlots: Math.floor(((endHour * 60) - (startHour * 60 + startMinute)) / slotDuration)
    readonly property real pixelsPerMinute: slotHeight / slotDuration
    readonly property int contentHeight: totalSlots * slotHeight

    property real maxHeight: 700
    property real headerHeight: 64 // Material 3 standard header height
    property real currentTimeY: -1
    property bool initialScrollApplied: false
    readonly property real dayColumnWidth: Math.min(180, (maxContentWidth - timeColumnWidth - (days.length + 1) * spacing) / days.length)
    readonly property int currentDayIndex: (DateTime.clock.date.getDay() - Config.options.time.firstDayOfWeek+ 6)%7

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

        return (start === "00:00" && end === "23:59") ||
               (start === "00:00" && end === "00:00") ||
               (!event.start && !event.end);
    }

    function getAllDayEvents(events) {
        if (!events || !events.length)
            return [];

        return events.filter(function(evt) { return root.isAllDayEvent(evt); });
    }

    function getTimedEvents(events) {
        if (!events || !events.length)
            return [];

        return events.filter(function(evt) { return !root.isAllDayEvent(evt); });
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

        let formatTime = (totalMinutes) => {
            if (totalMinutes === null)
                return "";
            let hour = Math.floor(totalMinutes / 60);
            let minute = totalMinutes % 60;
            let date = new Date();
            date.setHours(hour, minute, 0, 0);
            return Qt.formatTime(date, Config.options?.time.format ?? "hh:mm");
        };

        let startStr = formatTime(startTotal) || event.start || "";
        let endStr = formatTime(endTotal) || event.end || "";
        let range = startStr && endStr ? startStr + " - " + endStr : startStr || endStr;
        return range ? description ? "•  " + title + "\n•  " + range + "\n•  " + description : "•  " +  title + "\n•  " + range : "•  " + title;
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

    function scrollToFirstEvent() {
        if (!styledFlickable)
            return;

        let earliest = root.earliestEventStartMinutes();
        let minOfDay = earliest;

        if (minOfDay === -1 || minOfDay <= (root.startHour * 60 + root.startMinute)) {
            styledFlickable.contentY = 0;
            return;
        }

        let diff = minOfDay - (root.startHour * 60 + root.startMinute);
        if (diff < 0)
            diff = 0;

        let targetY = diff * root.pixelsPerMinute - root.slotHeight;
        targetY = Math.max(0, targetY);

        let maxScroll = Math.max(0, styledFlickable.contentHeight - styledFlickable.height);
        if (styledFlickable.height <= 0) {
            Qt.callLater(root.scrollToFirstEvent);
            return;
        }
        styledFlickable.contentY = Math.min(targetY, maxScroll);
    }

    function maybeApplyInitialScroll() {
        if (root.initialScrollApplied)
            return;

        if (!styledFlickable || styledFlickable.height <= 0 || !root.days || root.days.length === 0) {
            Qt.callLater(root.maybeApplyInitialScroll);
            return;
        }

        root.scrollToFirstEvent();
        root.initialScrollApplied = true;
    }

    Connections {
        target: DateTime.clock
        function onDateChanged() {
            root.updateCurrentTimeLine();
        }
    }

    Connections {
        target: CalendarService
        function onEventsInWeekChanged() {
            Qt.callLater(root.maybeApplyInitialScroll);
        }
    }

    Component.onCompleted: {
        root.updateCurrentTimeLine();
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
                        property bool isToday: index === root.currentDayIndex

                        anchors.centerIn: parent
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
        

                         Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width - 4
                            spacing: root.allDayChipSpacing

                            Repeater {
                                model: allDayEvents
                                delegate: Rectangle {
                                    width: parent.width
                                    height: root.allDayChipHeight
                                    color: 'transparent' 

                                   
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
                                    let hour = root.startHour + Math.floor(totalMinutes / 60);
                                    let minute = totalMinutes % 60;

                                    // Format time based on DateTime format
                                    let testDate = new Date();
                                    testDate.setHours(hour, minute, 0);
                                    return Qt.formatTime(testDate, Config.options?.time.format ?? "hh:mm");
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
                            width: root.dayColumnWidth
                            height: parent.height
                            clip: true
                            
                            property bool isToday: index === root.currentDayIndex
                            property var timedEvents: root.getTimedEvents(modelData.events)

                            Rectangle {
                                anchors.fill: parent
                                radius: Appearance.rounding.large
                                color: isToday ? root.todayHighlightFill : index % 2 == 0 ? root.dayBackgroundFill : root.dayBackgroundFillVariant
                                border.width: isToday ? 1 : 0
                                border.color: isToday ? root.todayHighlightBorder : "transparent"
                            }

                            Repeater {
                                model: timedEvents
                                Rectangle {
                                    width: parent.width - 10
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    radius: Appearance.rounding.normal
                                    clip: true
                                    y: {
                                        let startHr = parseInt(modelData.start.split(":")[0]);
                                        let startMin = parseInt(modelData.start.split(":")[1]);
                                        let baseTotalMinutes = root.startHour * 60 + root.startMinute;
                                        let eventTotalMinutes = startHr * 60 + startMin;
                                        let diffMinutes = eventTotalMinutes - baseTotalMinutes;
                                        return diffMinutes * root.pixelsPerMinute;
                                    }
                                    height: {
                                        let startHr = parseInt(modelData.start.split(":")[0]);
                                        let endHr = parseInt(modelData.end.split(":")[0]);
                                        let startMin = parseInt(modelData.start.split(":")[1]);
                                        let endMin = parseInt(modelData.end.split(":")[1]);
                                        let totalMins = (endHr * 60 + endMin) - (startHr * 60 + startMin);
                                        return Math.max(totalMins * root.pixelsPerMinute - 4, 48); // Minimum height for touch targets
                                    }

                                    color: modelData.color || Appearance.colors.colTertiaryContainer

                                    HoverHandler {
                                        id: eventHover
                                    }

                                    StyledToolTip {
                                        extraVisibleCondition: eventHover.hovered
                                        text: root.formatEventTooltip(modelData)
                                    }

                                    Column {
                                        anchors {
                                            fill: parent
                                            margins: 8
                                        }
                                        spacing: 4

                                        StyledText {
                                            id: eventTitle
                                            text: modelData.title

                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                            width: parent.width
                                            color: ColorUtils.getContrastingTextColor(modelData.color)
                                        }

                                        StyledText {
                                            text: {
                                                let startHr = parseInt(modelData.start.split(":")[0]);
                                                let startMin = parseInt(modelData.start.split(":")[1]);
                                                let endHr = parseInt(modelData.end.split(":")[0]);
                                                let endMin = parseInt(modelData.end.split(":")[1]);

                                                let formatTime = (hour, minute) => {
                                                    let testDate = new Date();
                                                    testDate.setHours(hour, minute, 0);
                                                    return Qt.formatTime(testDate, Config.options?.time.format ?? "hh:mm");
                                                };

                                                return formatTime(startHr, startMin) + " - " + formatTime(endHr, endMin);
                                            }
                                            font.weight: Font.Medium
                                            width: parent.width
                                            wrapMode: Text.NoWrap
                                            color: ColorUtils.getContrastingTextColor(modelData.color)
                                            elide: Text.ElideRight
                                            visible: !truncated
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

                    Text {
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
}

