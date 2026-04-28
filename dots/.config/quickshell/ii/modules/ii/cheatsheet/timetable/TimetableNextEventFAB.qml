import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import "."
import "TimetableHelpers.js" as H

Rectangle {
    id: nextEventIndicator
    
    property var nextEventData
    property real headerHeight
    property int timeColumnWidth
    property real dayColumnWidth
    property real spacing
    property real contentY
    property real flickableHeight
    property real flickableContentHeight
    property real pixelsPerMinute
    property int startHour
    property int startMinute

    signal scrollRequested(real targetY)

    readonly property real nextEventY: nextEventData ? H.minutesToY(nextEventData.startMinutes, startHour, startMinute, pixelsPerMinute) : -1
    readonly property bool isAbove: nextEventData && (nextEventY + 20 < contentY)
    readonly property bool isBelow: nextEventData && (nextEventY > contentY + flickableHeight - 40)
    
    visible: nextEventData !== null && (isAbove || isBelow)
    
    width: 40
    height: 40
    radius: Appearance.rounding.full
    color: Appearance.colors.colPrimary
    border.width: 1
    border.color: H.withOpacity(Appearance.colors.colOnPrimary, 0.3)
    z: 100
    antialiasing: true
    
    x: {
        if (!nextEventData) return 0;
        return timeColumnWidth + spacing + (nextEventData.dayIndex * (dayColumnWidth + spacing)) + (dayColumnWidth / 2) - (width / 2);
    }
    
    y: isAbove ? headerHeight + 20 : parent.height - height - 20
    
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
            if (nextEventData) {
                let targetY = nextEventIndicator.nextEventY - flickableHeight / 3;
                targetY = Math.max(0, targetY);
                scrollRequested(targetY);
            }
        }
    }
}
