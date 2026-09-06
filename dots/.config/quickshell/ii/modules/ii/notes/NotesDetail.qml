pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.notes
import qs.modules.ii.notes.editor
import qs.modules.ii.notes.sketch
import "../../../services/notes/NotesSearchIndex.js" as SearchIndex

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
    /// Empty means the note has not chosen one, which is plain.
    readonly property string paperStyle: root.note && root.note.paper.length > 0 ? root.note.paper : "plain"
    readonly property var backlinks: root.note
        ? SearchIndex.findBacklinks(root.note.id, root.note.title, NotesService.notes, null)
        : []

    signal paperPicked(string style)
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

    /**
     * A picture, full size, over the page.
     *
     * Inside the pane rather than a window of its own: it is a closer look at something in
     * this note, not a separate thing, and a second window to dismiss would be one more
     * than the job needs.
     */
    Rectangle {
        id: imageViewer
        anchors.fill: parent
        z: 20
        color: Qt.rgba(0, 0, 0, 0.82)
        visible: editor.viewingImage.length > 0

        MouseArea {
            anchors.fill: parent
            onClicked: editor.viewImage("")
        }

        Image {
            anchors.centerIn: parent
            width: Math.min(parent.width - 64, implicitWidth)
            height: implicitWidth > 0 ? width * (implicitHeight / implicitWidth) : 0
            source: editor.viewingImage.length > 0 ? `file://${editor.viewingImage}` : ""
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
            sourceSize.width: 2400
        }

        NotesIconButton {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 12
            symbol: "close"
            tooltipText: Translation.tr("Close")
            colIcon: Appearance.m3colors.m3onSurface
            onTriggered: editor.viewImage("")
        }
    }

    /**
     * The ink sheet, over the page.
     *
     * Inside the pane and above everything, because drawing wants the whole page and a
     * separate window would be one more thing to arrange and dismiss.
     */
    Loader {
        anchors.fill: parent
        z: 30
        active: editor.editingInk.length > 0 && editor.editingInkBlock !== null

        sourceComponent: NotesInkSheet {
            noteId: root.noteId
            block: editor.editingInkBlock
            editor: editor
            onFinished: editor.editInk("")
        }
    }

    NotesPaperPicker {
        id: paperPicker
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: NotesMetrics.panePadding
        anchors.topMargin: 68
        z: 10
        visible: false
        current: root.paperStyle

        onPicked: style => {
            root.paperPicked(style);
            paperPicker.visible = false;
        }
    }

    NotesExportSheet {
        id: exportSheet
        anchors.fill: parent
        z: 35
        visible: false
        noteId: root.noteId
        note: root.note
        onClosed: exportSheet.visible = false
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
                symbol: "grid_on"
                tooltipText: Translation.tr("Page style")
                colIcon: root.paperStyle !== "plain" ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                visible: !root.trash
                onTriggered: paperPicker.visible = !paperPicker.visible
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
                symbol: "file_export"
                tooltipText: Translation.tr("Export note")
                colIcon: Appearance.colors.colOnLayer1
                visible: !root.trash
                onTriggered: exportSheet.visible = true
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

        // ── Collapsible Backlinks ("Mentioned in") bar ────────────────────
        ColumnLayout {
            id: backlinksBar
            Layout.fillWidth: true
            Layout.leftMargin: NotesMetrics.readingPadding
            Layout.rightMargin: NotesMetrics.readingPadding
            Layout.topMargin: 6
            Layout.bottomMargin: 2
            visible: root.backlinks.length > 0
            spacing: 4

            property bool expanded: false

            RippleButton {
                implicitHeight: 28
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.m3colors.m3surfaceContainerLowest
                colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                leftPadding: 8
                rightPadding: 8

                contentItem: RowLayout {
                    spacing: 6
                    MaterialSymbol {
                        text: "link"
                        iconSize: 15
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: Translation.tr("Mentioned in (%1)").arg(root.backlinks.length)
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colPrimary
                    }
                    MaterialSymbol {
                        text: backlinksBar.expanded ? "expand_less" : "expand_more"
                        iconSize: 15
                        color: Appearance.colors.colPrimary
                    }
                }

                onClicked: backlinksBar.expanded = !backlinksBar.expanded
            }

            Flow {
                Layout.fillWidth: true
                visible: backlinksBar.expanded
                spacing: 6

                Repeater {
                    model: root.backlinks

                    RippleButton {
                        required property var modelData
                        implicitHeight: 28
                        buttonRadius: Appearance.rounding.small
                        colBackground: Appearance.m3colors.m3surfaceContainerLowest
                        colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                        leftPadding: 8
                        rightPadding: 8

                        contentItem: RowLayout {
                            spacing: 4
                            MaterialSymbol {
                                text: "article"
                                iconSize: 14
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                text: modelData.title.length > 0 ? modelData.title : Translation.tr("Untitled note")
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                color: Appearance.colors.colOnLayer0
                            }
                        }

                        onClicked: Persistent.states.notes.noteId = modelData.id
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 12

            // The page, under the text. Its own item rather than a property of the
            // editor: the editor scrolls, and the paper has to stay put and be *offset*
            // instead, or the pattern would slide out from under the words.
            NotesPaper {
                anchors.fill: parent
                paperStyle: root.paperStyle
                scrollOffset: editor.scrollOffset
            }

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
