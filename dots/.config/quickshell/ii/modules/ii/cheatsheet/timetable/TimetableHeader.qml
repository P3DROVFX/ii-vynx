import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import "."
import "TimetableHelpers.js" as H

Row {
    id: headerRow
    
    property real headerHeight
    property real spacing
    property int timeColumnWidth
    property real dayColumnWidth
    property var days
    property int currentDayIndex
    property int allDayChipHeight
    property int allDayChipSpacing

    width: parent.width
    height: headerHeight
    spacing: spacing

    Item {
        width: timeColumnWidth
        height: headerHeight

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
        model: days
        delegate: Item {
            width: dayColumnWidth
            height: headerHeight

            property var allDayEvents: H.getAllDayEvents(modelData.events)

            Rectangle {
                id: dayTitleRect
                property bool isToday: index === currentDayIndex

                anchors.top: parent.top
                anchors.topMargin: 12
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 4
                height: 40
                radius: Appearance.rounding.windowRounding
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
                anchors.topMargin: allDayChipSpacing
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 4
                spacing: allDayChipSpacing

                Repeater {
                    model: allDayEvents
                    delegate: Rectangle {
                        width: parent.width
                        height: allDayChipHeight
                        color: Appearance.colors.colSecondaryContainer
                        radius: Appearance.rounding.verysmall
                        border.width: 1
                        border.color: H.withOpacity(Appearance.colors.colOnSecondaryContainer, 0.1)

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
                            text: Translation.tr("All day event:") + "\n" + modelData.title
                        }
                    }
                }
            }
        }
    }
}
