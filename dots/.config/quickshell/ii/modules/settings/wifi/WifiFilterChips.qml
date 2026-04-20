import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

RowLayout {
    id: root
    property string currentFilter: "all"
    signal filterChanged(string filter)
    spacing: 8

    // Filter chip component
    component FilterChip: Rectangle {
        id: chip
        property bool selected: false
        property string chipIcon: ""
        property string chipLabel: ""
        signal clicked()

        implicitHeight: 36
        implicitWidth: chipRow.implicitWidth + 32
        radius: Appearance.rounding.full
        color: selected ? Appearance.colors.colSecondaryContainer : "transparent"
        border.width: selected ? 0 : 1
        border.color: selected ? "transparent" : Appearance.m3colors.m3outlineVariant

        Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }

        RowLayout {
            id: chipRow
            anchors.centerIn: parent
            spacing: 6

            MaterialSymbol {
                visible: chip.chipIcon !== ""
                text: chip.chipIcon
                iconSize: Appearance.font.pixelSize.small
                color: chip.selected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colSubtext
            }
            StyledText {
                text: chip.chipLabel
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
                color: chip.selected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colSubtext
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }

    FilterChip {
        chipLabel: Translation.tr("All")
        selected: root.currentFilter === "all"
        onClicked: { root.currentFilter = "all"; root.filterChanged("all") }
    }
    FilterChip {
        chipIcon: "lock"
        chipLabel: Translation.tr("Secured")
        selected: root.currentFilter === "secured"
        onClicked: { root.currentFilter = "secured"; root.filterChanged("secured") }
    }
    FilterChip {
        chipIcon: "wifi"
        chipLabel: Translation.tr("Open")
        selected: root.currentFilter === "open"
        onClicked: { root.currentFilter = "open"; root.filterChanged("open") }
    }
}
