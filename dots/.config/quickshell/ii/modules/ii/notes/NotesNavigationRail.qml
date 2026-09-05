pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * Where you are: the fixed places, then the notebooks, then the trash.
 *
 * Expressive treats selection as a change of *shape*, not only of colour, so the current
 * place is a full pill while the others are transparent. That is also the reason the
 * selected item stays legible with the theme in either mode — the shape carries the state
 * even where the colour contrast is subtle.
 */
Item {
    id: root

    property bool expanded: true
    property bool canExpand: true
    property string scope: "all"

    signal scopePicked(string scope)
    signal expandToggled()

    readonly property var places: [
        { id: "all", icon: "description", name: Translation.tr("All notes") },
        { id: "recent", icon: "history", name: Translation.tr("Recent") },
        { id: "favorites", icon: "star", name: Translation.tr("Favourites") }
    ]

    readonly property var notebooks: Array.from(NotesService.notebooks ?? [])

    readonly property int trashCount: Array.from(NotesService.index.notes ?? [])
        .filter(note => note.trashedAt > 0).length

    function countFor(scopeId) {
        const live = Array.from(NotesService.index.notes ?? []).filter(note => note.trashedAt === 0);
        if (scopeId === "all")
            return live.length;
        if (scopeId === "favorites")
            return live.filter(note => note.favorite).length;
        if (scopeId === "recent")
            return Math.min(20, live.length);
        return live.filter(note => note.notebookId === scopeId || note.sectionId === scopeId).length;
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colLayer1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 4

        NotesIconButton {
            Layout.leftMargin: 16
            symbol: root.expanded ? "menu_open" : "menu"
            tooltipText: root.expanded ? Translation.tr("Collapse") : Translation.tr("Expand")
            visible: root.canExpand
            onTriggered: root.expandToggled()
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: railColumn.implicitHeight
            clip: true

            ColumnLayout {
                id: railColumn
                width: parent.width
                spacing: 2

                Repeater {
                    model: root.places
                    delegate: NotesRailItem {
                        required property var modelData
                        Layout.fillWidth: true
                        expanded: root.expanded
                        symbol: modelData.icon
                        label: modelData.name
                        count: root.countFor(modelData.id)
                        current: root.scope === modelData.id
                        onTriggered: root.scopePicked(modelData.id)
                    }
                }

                StyledText {
                    Layout.leftMargin: 24
                    Layout.topMargin: 12
                    Layout.bottomMargin: 2
                    text: Translation.tr("Notebooks")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colSubtext
                    visible: root.expanded && root.notebooks.length > 0
                }

                Repeater {
                    model: root.notebooks
                    delegate: NotesRailItem {
                        required property var modelData
                        Layout.fillWidth: true
                        expanded: root.expanded
                        symbol: modelData.icon.length > 0 ? modelData.icon : "book"
                        label: modelData.title
                        count: root.countFor(modelData.id)
                        current: root.scope === modelData.id
                        onTriggered: root.scopePicked(modelData.id)
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.preferredHeight: 1
            color: Appearance.colors.colOutlineVariant
        }

        NotesRailItem {
            Layout.fillWidth: true
            Layout.topMargin: 4
            expanded: root.expanded
            symbol: "delete"
            label: Translation.tr("Trash")
            count: root.trashCount
            current: root.scope === "trash"
            onTriggered: root.scopePicked("trash")
        }
    }
}
