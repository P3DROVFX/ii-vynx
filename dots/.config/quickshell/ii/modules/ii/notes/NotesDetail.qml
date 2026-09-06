pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.notes
import qs.modules.ii.notes.editor

/**
 * The note itself.
 *
 * The title is edited here because renaming is a property of the note, not of its text —
 * it belongs to the same row as pinning and deleting. The body is rendered from the
 * document; the block editor that makes it typeable is the next piece of work, and it
 * replaces this reader rather than wrapping it.
 */
Item {
    id: root

    property var note: null
    property bool trash: false

    signal deleteRequested()
    signal restoreRequested()
    signal favoriteToggled()
    signal pinToggled()
    signal titleEdited(string title)

    // Clipped at the pane's own bounds.
    //
    // The slab below is a *sibling* of the content, so its own `clip` contains nothing —
    // a list long enough to scroll had cards drawn outside the rounded rectangle they are
    // supposed to live in. Clipping belongs to whatever owns the bounds, which is this.
    clip: true

    /// Puts the caret in the note. Called when one is created, not when one is selected.
    function focusEditor(): void {
        editor.requestAutoFocus();
    }

    readonly property string noteId: root.note ? root.note.id : ""
    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: Appearance.m3colors.m3surfaceContainerHigh
        clip: true
    }

    PagePlaceholder {
        anchors.centerIn: parent
        width: Math.min(parent.width - 60, 420)
        visible: root.note === null
        icon: "edit_note"
        title: Translation.tr("No note selected")
        description: Translation.tr("Pick one from the list, or start a new one.")
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0
        visible: root.note !== null

        RowLayout {
            Layout.fillWidth: true
            // The title, the metadata and the prose all start on the same line. They were
            // 28, 30 and 30, which is invisible as a decision and obvious as a wobble.
            Layout.leftMargin: NotesMetrics.readingPadding
            Layout.rightMargin: NotesMetrics.panePadding
            Layout.topMargin: 22
            spacing: 4

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: titleField.implicitHeight

                StyledTextInput {
                    id: titleField
                    anchors.fill: parent
                    // Never claimed by the window's focus chain. The note's body is what
                    // somebody opening a note wants to type in; the title is renamed
                    // deliberately, by clicking it.
                    activeFocusOnTab: false
                    focus: false
                    // Bound from the note, but only while nobody is typing in it: rebinding
                    // under the cursor is how a rename loses the last character typed.
                    text: root.note && !titleField.activeFocus ? root.note.title : titleField.text
                    font.pixelSize: Appearance.font.pixelSize.hugeass
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer0
                    readOnly: root.trash

                    onEditingFinished: root.titleEdited(titleField.text)
                    onAccepted: titleField.focus = false
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Translation.tr("Untitled note")
                    font: titleField.font
                    color: Appearance.colors.colOnLayer1Inactive
                    visible: titleField.text.length === 0
                }
            }

            NotesIconButton {
                symbol: "keep"
                tooltipText: Translation.tr("Pin to the top of the list")
                colIcon: root.note && root.note.pinned ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                visible: !root.trash
                onTriggered: root.pinToggled()
            }

            NotesIconButton {
                symbol: "star"
                tooltipText: Translation.tr("Add to favourites")
                colIcon: root.note && root.note.favorite ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                visible: !root.trash
                onTriggered: root.favoriteToggled()
            }

            NotesIconButton {
                symbol: "restore_from_trash"
                tooltipText: Translation.tr("Put this note back")
                visible: root.trash
                onTriggered: root.restoreRequested()
            }

            NotesIconButton {
                symbol: root.trash ? "delete_forever" : "delete"
                tooltipText: root.trash
                    ? Translation.tr("Delete permanently")
                    : Translation.tr("Move to the trash")
                colIcon: root.trash ? Appearance.m3colors.m3error : Appearance.colors.colOnLayer1
                onTriggered: root.deleteRequested()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: NotesMetrics.readingPadding
            Layout.rightMargin: NotesMetrics.readingPadding
            Layout.topMargin: 0
            spacing: 12

            StyledText {
                text: root.note
                    ? Translation.tr("Edited %1").arg(Qt.formatDateTime(new Date(root.note.modified), "d MMM yyyy, HH:mm"))
                    : ""
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }

            StyledText {
                text: root.note ? Translation.tr("%1 blocks").arg(root.note.blockCount) : ""
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                visible: root.note && root.note.blockCount > 1
            }

            Item {
                Layout.fillWidth: true
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 12

            NotesEditor {
                id: editor
                anchors.fill: parent
                noteId: root.noteId
            }

            // Floating at the foot of the page rather than pinned above it: it belongs to
            // the block the caret is in, and following the page keeps it near the hand.
            NotesEditorToolbar {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                editor: editor
                opacity: editor.activeBlockId.length > 0 ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }
    }
}
