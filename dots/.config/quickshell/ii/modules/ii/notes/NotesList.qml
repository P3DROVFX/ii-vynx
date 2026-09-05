pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.services
import qs.modules.common
import qs.modules.common.widgets

/// Which note. A list of cards, and the one button that makes another one.
Item {
    id: root

    property var notes: []
    property string selectedId: ""
    property bool searching: false
    property bool trash: false

    signal notePicked(string noteId)
    signal createRequested()

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colLayer1
    }

    StyledListView {
        id: list
        anchors.fill: parent
        anchors.margins: 10
        anchors.bottomMargin: 0
        spacing: 6
        clip: true
        model: root.notes
        // The cards arrive one after another rather than all at once. It is the app's
        // entrance, and a list that snaps into place reads as a redraw rather than a view.
        staggerStep: 18

        delegate: NotesListCard {
            required property var modelData
            width: list.width
            note: modelData
            current: modelData.id === root.selectedId
            onTriggered: root.notePicked(modelData.id)
        }

        // Room for the button that floats over the end of the list.
        footer: Item {
            width: 1
            height: 78
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

    /**
     * The one thing this pane is for, floating over it.
     *
     * Expressive puts the primary action on top of the content rather than in a bar above
     * it, so it stays in the same place whether the list is empty or long.
     */
    FloatingActionButton {
        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: 16
            bottomMargin: 16
        }
        iconText: "add"
        buttonText: Translation.tr("New note")
        expanded: !root.trash && root.width > 240
        visible: !root.trash
        onClicked: root.createRequested()
    }
}
