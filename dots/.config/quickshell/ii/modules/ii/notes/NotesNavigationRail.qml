pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * Where you are, and everything that is about the whole app rather than one note.
 *
 * New note at the top, where the mail sidebar puts Compose. The places and the notebooks
 * in the middle, each a group shaped at its ends. And at the bottom the three things that
 * are not places at all — search, the trash, and the app's own settings — because a rail
 * that mixes "which notes am I looking at" with "find something" and "change something"
 * in one column makes all three harder to find.
 *
 * The bottom is a field and then a row, not three stacked buttons: three full-width
 * buttons in a column read as three more places.
 */
Item {
    id: root

    property bool expanded: true
    property string scope: "all"
    readonly property string query: searchInput.text

    signal scopePicked(string scope)
    signal createRequested()
    signal settingsRequested()

    function clearSearch(): void {
        searchInput.text = "";
    }

    function focusSearch(): void {
        searchInput.forceActiveFocus();
        searchInput.selectAll();
    }

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

    // A slab. Opaque on purpose: the theme's layered colours are transparency-adjusted and
    // collapse into each other over a wallpaper, so a boundary drawn with them is not one
    // anybody can see. Every Cheatsheet page uses this surface for the same reason.
    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: Appearance.m3colors.m3surfaceContainerHigh
        clip: true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: NotesMetrics.panePadding
        spacing: 4

        RippleButton {
            id: composeButton
            Layout.fillWidth: true
            Layout.bottomMargin: 8
            implicitHeight: 56
            buttonRadius: NotesMetrics.pillRadius(composeButton.implicitHeight)
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
                spacing: 2

                Repeater {
                    model: root.places
                    delegate: NotesRailItem {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        isFirst: index === 0
                        isLast: index === root.places.length - 1
                        prevIsCurrent: index > 0 && root.scope === root.places[index - 1].id
                        nextIsCurrent: index < root.places.length - 1 && root.scope === root.places[index + 1].id
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
                        prevIsCurrent: index > 0 && root.scope === root.notebooks[index - 1].id
                        nextIsCurrent: index < root.notebooks.length - 1 && root.scope === root.notebooks[index + 1].id
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

        /**
         * Search, at the foot of the rail.
         *
         * It looks for notes anywhere, which is what the rail is about — not what the list
         * beside it currently shows. Over the list it would have claimed the opposite.
         */
        Rectangle {
            id: searchBox
            Layout.fillWidth: true
            Layout.topMargin: 8
            implicitHeight: 44
            radius: NotesMetrics.pillRadius(searchBox.implicitHeight)
            color: searchInput.activeFocus
                ? Appearance.m3colors.m3surfaceContainerHighest
                : Appearance.colors.colLayer2

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                onClicked: searchInput.forceActiveFocus()
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 6
                spacing: 10

                MaterialSymbol {
                    text: "search"
                    iconSize: 20
                    color: Appearance.colors.colOnLayer2
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.expanded

                    StyledTextInput {
                        id: searchInput
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        color: Appearance.colors.colOnLayer2
                        clip: true
                        onAccepted: searchInput.focus = false
                    }

                    // `StyledTextInput` is a bare `TextInput`; there is no placeholder to
                    // set, so it is drawn here rather than swapping in a heavier field.
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Translation.tr("Search notes")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1Inactive
                        visible: searchInput.text.length === 0 && !searchInput.activeFocus
                    }
                }

                NotesIconButton {
                    symbol: "close"
                    size: 32
                    iconSize: 17
                    tooltipText: Translation.tr("Clear the search")
                    visible: root.expanded && searchInput.text.length > 0
                    onTriggered: root.clearSearch()
                }
            }

            StyledToolTip {
                text: Translation.tr("Search notes")
                extraVisibleCondition: !root.expanded
            }
        }

        // A row, not two more full-width buttons. Stacked, they would read as two more
        // places to go rather than as what they are.
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6
            spacing: 4

            NotesRailItem {
                id: trashRow
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

            NotesIconButton {
                symbol: "tune"
                size: NotesMetrics.rowHeight
                tooltipText: Translation.tr("Notes settings")
                visible: root.expanded
                onTriggered: root.settingsRequested()
            }
        }
    }
}
