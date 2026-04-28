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

Rectangle {
    id: eventBlock

    property var eventData
    property int colIndex: 0
    property int totalCols: 1
    property int dayIdx
    property var nextEventData
    property real maxLogicalDistance: 1.0
    property real pixelsPerMinute
    property int startHour
    property int startMinute

    signal editRequested(var event, int dayIndex)

    readonly property bool isNextEvent: nextEventData && nextEventData.dayIndex === dayIdx && nextEventData.startMinutes === eventStartMinutes

    readonly property int eventStartMinutes: {
        let parts = eventData.start.split(":");
        return parseInt(parts[0]) * 60 + parseInt(parts[1]);
    }
    readonly property int eventEndMinutes: {
        let parts = eventData.end.split(":");
        let endTotal = parseInt(parts[0]) * 60 + parseInt(parts[1]);
        if (endTotal === 0 && eventStartMinutes > 0)
            endTotal = 24 * 60;
        return endTotal;
    }

    // Overlap layout
    width: (parent.width - 10) / totalCols - 2
    x: colIndex * ((parent.width - 10) / totalCols) + 5
    
    radius: Appearance.rounding.normal
    clip: true
    z: isNextEvent ? 4 : 3
    color: H.getEventColorRadial(dayIdx, eventStartMinutes, nextEventData, maxLogicalDistance, Appearance.colors)
    border.width: isNextEvent ? 2 : 0
    border.color: isNextEvent ? H.withOpacity(Appearance.colors.colOnPrimary, 0.8) : "transparent"
    y: H.minutesToY(eventStartMinutes, startHour, startMinute, pixelsPerMinute)
    height: Math.max((eventEndMinutes - eventStartMinutes) * pixelsPerMinute - 4, 48)

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
        text: {
            let title = eventData.title || qsTr("Event");
            let description = eventData.description || "";
            let startStr = H.minutesToTimeStr(eventStartMinutes, Config.options?.time.format) || eventData.start || "";
            let endStr = H.minutesToTimeStr(eventEndMinutes, Config.options?.time.format) || eventData.end || "";
            let range = startStr && endStr ? startStr + " - " + endStr : startStr || endStr;
            return range ? description ? "•  " + title + "\n•  " + range + "\n•  " + description : "•  " + title + "\n•  " + range : "•  " + title;
        }
    }

    // Click to edit
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: editRequested(eventData, dayIdx)
    }

    // Delete button
    RippleButton {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 4
        implicitWidth: 24
        implicitHeight: 24
        buttonRadius: Appearance.rounding.full
        buttonColor: H.withOpacity(Appearance.colors.colOnSurface, 0.15)
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
            if (eventData.uid) {
                CalendarService.removeEventByUid(eventData.uid);
            } else {
                CalendarService.removeEvent(eventData.title);
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
            text: eventData.title
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            width: parent.width - 28
            color: ColorUtils.getContrastingTextColor(eventBlock.color)
        }

        Row {
            spacing: 6
            width: parent.width
            visible: eventBlock.height > 60 || eventBlock.isNextEvent

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
                text: H.minutesToTimeStr(eventBlock.eventStartMinutes, Config.options?.time.format) + " - " + H.minutesToTimeStr(eventBlock.eventEndMinutes, Config.options?.time.format)
                font.weight: Font.Medium
                color: ColorUtils.getContrastingTextColor(eventBlock.color)
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
                visible: eventBlock.height > 60 || eventBlock.isNextEvent
            }
        }
    }
}
