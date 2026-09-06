pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.notes

/// Which note. A list of cards, and the one button that makes another one.
Item {
    id: root

    property var notes: []
    property var searchTerms: []
    property string selectedId: ""
    property bool searching: false
    property bool trash: false

    signal notePicked(string noteId)
    signal createRequested()

    // Clipped at the pane's own bounds.
    //
    // The slab below is a *sibling* of the content, so its own `clip` contains nothing —
    // a list long enough to scroll had cards drawn outside the rounded rectangle they are
    // supposed to live in. Clipping belongs to whatever owns the bounds, which is this.
    clip: true

    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: Appearance.m3colors.m3surfaceContainerHigh
        clip: true
    }

    StyledListView {
        id: list
        anchors.fill: parent
        // Symmetric. Zero at the bottom let the last card run to the slab's edge, where a
        // rectangular clip cuts straight across a corner that curves — which is what a
        // card poking out of the pane actually was.
        anchors.margins: NotesMetrics.panePadding
        topMargin: 0
        bottomMargin: NotesMetrics.panePadding
        spacing: NotesMetrics.cardSpacing
        clip: true
        model: root.notes
        // The cards arrive one after another rather than all at once. It is the app's
        // entrance, and a list that snaps into place reads as a redraw rather than a view.
        staggerStep: 18

        delegate: NotesListCard {
            required property var modelData
            required property int index
            width: list.width
            isFirst: index === 0
            isLast: index === root.notes.length - 1
            prevIsCurrent: index > 0 && root.notes[index - 1].id === root.selectedId
            nextIsCurrent: index < root.notes.length - 1 && root.notes[index + 1].id === root.selectedId
            note: modelData
            searchTerms: root.searchTerms
            current: modelData.id === root.selectedId
            onTriggered: root.notePicked(modelData.id)
        }

        // Air after the last card, so it does not end flush against the pane's corner.
        footer: Item {
            height: NotesMetrics.panePadding
        }
    }

    PagePlaceholder {
        anchors.centerIn: parent
        width: parent.width - 40
        visible: root.notes.length === 0
        icon: root.trash ? "delete" : (root.searching ? "search_off" : "note_stack")
        title: root.trash
            ? Translation.tr("The trash is empty")
            : (root.searching ? Translation.tr("Nothing matches") : Translation.tr("No notes yet"))
        description: root.trash
            ? Translation.tr("Notes you delete wait here before they go for good.")
            : (root.searching
                ? Translation.tr("Try fewer words, or search in another notebook.")
                : Translation.tr("Write the first one. It saves itself."))
    }

}
