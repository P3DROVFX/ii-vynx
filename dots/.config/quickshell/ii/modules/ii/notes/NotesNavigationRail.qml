pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.notes

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
    property string scope: "all"

    signal scopePicked(string scope)
    signal expandToggled()
    signal createRequested()

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

    // A slab. Opaque on purpose: the theme's layered colours are transparency-adjusted
    // and collapse into each other over a wallpaper — measured on a real screenshot, two
    // adjacent panes came out one channel-step apart, which is not a boundary anyone can
    // see. The Cheatsheet's pages all use this surface for the same reason.
    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: Appearance.m3colors.m3surfaceContainerHigh
        clip: true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: NotesMetrics.panePadding
        anchors.bottomMargin: NotesMetrics.panePadding
        anchors.leftMargin: NotesMetrics.panePadding
        anchors.rightMargin: NotesMetrics.panePadding
        spacing: 4

        /**
         * The one thing this app is for, at the top of the rail.
         *
         * It used to float over the list, where it covered the text of whichever note
         * happened to be under it. The Cheatsheet's mail sidebar puts Compose here, and it
         * is the right place for the same reason: it is always visible, it never lands on
         * top of content, and it is the first thing the eye reaches.
         */
        RippleButton {
            Layout.fillWidth: true
            Layout.bottomMargin: 8
            implicitHeight: 56
            buttonRadius: Appearance.rounding.full
            colBackground: Appearance.colors.colPrimary
            colBackgroundHover: Appearance.colors.colPrimaryHover
            colBackgroundActive: Appearance.colors.colPrimaryActive

            onClicked: root.createRequested()

            contentItem: RowLayout {
                spacing: 12

                Item {
                    Layout.preferredWidth: NotesMetrics.rowHeight - 8
                    Layout.fillWidth: !root.expanded
                    Layout.fillHeight: true

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "edit_square"
                        iconSize: 24
                        color: Appearance.colors.colOnPrimary
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("New note")
                    visible: root.expanded
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnPrimary
                    elide: Text.ElideRight
                }
            }

            StyledToolTip {
                text: Translation.tr("New note")
                extraVisibleCondition: !root.expanded
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: railColumn.implicitHeight
            clip: true

            ColumnLayout {
                id: railColumn
                width: parent.width
                // Rows in a group touch, so their shaped ends read as one block.
                spacing: 2

                Repeater {
                    model: root.places
                    delegate: NotesRailItem {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        isFirst: index === 0
                        isLast: index === root.places.length - 1
                        expanded: root.expanded
                        symbol: modelData.icon
                        label: modelData.name
                        count: root.countFor(modelData.id)
                        current: root.scope === modelData.id
                        onTriggered: root.scopePicked(modelData.id)
                    }
                }

                StyledText {
                    // On the same line as the rows' text, not their icons: it is a heading
                    // for what they say, not for what they show.
                    Layout.leftMargin: NotesMetrics.rowHeight
                    Layout.topMargin: 14
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
                        required property int index
                        Layout.fillWidth: true
                        isFirst: index === 0
                        isLast: index === root.notebooks.length - 1
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

        Item {
            // Air, where a rule used to be.
            Layout.preferredHeight: 8
        }

        NotesRailItem {
            Layout.fillWidth: true
            isFirst: true
            isLast: true
            expanded: root.expanded
            symbol: "delete"
            label: Translation.tr("Trash")
            count: root.trashCount
            current: root.scope === "trash"
            onTriggered: root.scopePicked("trash")
        }
    }
}
