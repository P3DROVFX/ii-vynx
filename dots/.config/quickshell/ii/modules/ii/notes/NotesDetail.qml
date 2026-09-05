pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.notes
import "../../../services/notes/NotesMarkdown.js" as Markdown

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

    readonly property string noteId: root.note ? root.note.id : ""
    readonly property var document: root.noteId.length > 0 ? NotesService.documentOf(root.noteId) : null

    /// The body as markdown, which is what a reader can render without a block editor.
    readonly property string bodyText: {
        // Touched so the binding re-evaluates when a document finishes loading; the
        // document itself is reached through a function call, which nothing would notify.
        NotesService.tabsData;
        const document = root.noteId.length > 0 ? NotesService.documentOf(root.noteId) : null;
        if (!document)
            return "";
        // Pictures are drawn below, from absolute paths. Left in the markdown they would
        // be relative links, which `Text.MarkdownText` resolves against this QML file's
        // own directory and then fails to open — noisily, once per repaint.
        const prose = Array.from(document.blocks)
            .filter(item => item.type !== "ink" && item.type !== "image");
        return Markdown.toMarkdown({ id: root.noteId, blocks: prose });
    }

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

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 18
            Layout.bottomMargin: NotesMetrics.panePadding
            contentHeight: bodyColumn.implicitHeight
            clip: true

            ColumnLayout {
                id: bodyColumn
                width: parent.width
                spacing: 16

                StyledText {
                    Layout.fillWidth: true
                    Layout.leftMargin: NotesMetrics.readingPadding
                    Layout.rightMargin: NotesMetrics.readingPadding
                    Layout.maximumWidth: NotesMetrics.readingWidth
                    text: root.bodyText
                    textFormat: Text.MarkdownText
                    wrapMode: Text.WordWrap
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer0
                    visible: root.bodyText.trim().length > 0
                }

                Repeater {
                    // The drawings a note carries, under its text. They are files beside
                    // the note; the reader shows them, and editing them comes with the ink
                    // surface rather than here.
                    model: {
                        NotesService.tabsData;
                        const document = root.noteId.length > 0 ? NotesService.documentOf(root.noteId) : null;
                        if (!document)
                            return [];
                        return Array.from(document.blocks)
                            .filter(item => item.type === "ink" || item.type === "image")
                            .map(item => NotesService.assetPath(root.noteId, item.asset));
                    }

                    delegate: Image {
                        required property string modelData
                        Layout.leftMargin: NotesMetrics.readingPadding
                        Layout.rightMargin: NotesMetrics.readingPadding
                        // Bounded by the pane, not only by the reading measure: a drawing
                        // wider than the window ran off the right edge of its own note.
                        readonly property real available: Math.max(80,
                            Math.min(NotesMetrics.readingWidth,
                                     bodyColumn.width - NotesMetrics.readingPadding * 2))
                        Layout.maximumWidth: available
                        Layout.preferredWidth: Math.min(available, implicitWidth)
                        Layout.preferredHeight: implicitWidth > 0
                            ? Layout.preferredWidth * (implicitHeight / implicitWidth)
                            : 0
                        source: modelData.length > 0 ? `file://${modelData}` : ""
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                        // Bounded so a large drawing is decoded at the size it is shown at
                        // rather than at whatever the pen produced.
                        sourceSize.width: 1240
                    }
                }

                Item {
                    Layout.preferredHeight: NotesMetrics.readingPadding
                }
            }
        }
    }
}
