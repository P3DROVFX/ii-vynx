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
    signal outlineRequested()
    signal revisionsRequested()
    signal focusModeToggled()

    // Clipped at the pane's own bounds.
    //
    // The slab below is a *sibling* of the content, so its own `clip` contains nothing —
    // a list long enough to scroll had cards drawn outside the rounded rectangle they are
    // supposed to live in. Clipping belongs to whatever owns the bounds, which is this.
    clip: true

    /// Puts the caret in the note. Called when one is created, not when one is selected.
    function focusEditor() {
        editor.requestAutoFocus();
    }

    readonly property string noteId: root.note ? root.note.id : ""
    /// Empty means the note has not chosen one, which is plain.
    readonly property string paperStyle: root.note && root.note.paper.length > 0 ? root.note.paper : "plain"
    readonly property var backlinks: root.note
        ? SearchIndex.findBacklinks(root.note.id, root.note.title, NotesService.notes, null)
        : []

    readonly property var editorBlocks: editor ? editor.blocks : []
    readonly property int charCount: {
        let count = 0;
        const b = root.editorBlocks;
        if (Array.isArray(b)) {
            for (let i = 0; i < b.length; i++) {
                if (b[i] && typeof b[i].text === "string")
                    count += b[i].text.length;
            }
        }
        return count;
    }
    readonly property int wordCount: {
        let count = 0;
        const b = root.editorBlocks;
        if (Array.isArray(b)) {
            for (let i = 0; i < b.length; i++) {
                if (b[i] && typeof b[i].text === "string" && b[i].text.trim().length > 0) {
                    count += b[i].text.trim().split(/\s+/).length;
                }
            }
        }
        return count;
    }
    readonly property int readingMinutes: Math.max(1, Math.ceil(root.wordCount / 200))
    readonly property var reminderTimestamp: root.note && root.note.meta && root.note.meta.reminder ? root.note.meta.reminder : 0

    property bool unlockedThisSession: false
    onNoteIdChanged: root.unlockedThisSession = false

    readonly property bool isLocked: {
        if (!root.note) return false;
        if (root.note.meta && root.note.meta.locked) return true;
        if (Persistent.ready && Persistent.states.notes?.lockedNotes && Persistent.states.notes.lockedNotes[root.noteId]) return true;
        return false;
    }

    readonly property string storedPin: {
        if (!root.note) return "1234";
        if (root.note.meta && root.note.meta.pin) return String(root.note.meta.pin);
        if (Persistent.ready && Persistent.states.notes?.lockedNotes && Persistent.states.notes.lockedNotes[root.noteId]?.pin)
            return String(Persistent.states.notes.lockedNotes[root.noteId].pin);
        return "1234";
    }

    function setReminder(timestamp) {
        if (!root.noteId) return;
        const meta = Object.assign({}, root.note ? root.note.meta : {}, { reminder: timestamp, reminderNotified: false });
        NotesService.updateMeta(root.noteId, { meta: meta });
    }

    function clearReminder() {
        if (!root.noteId) return;
        const meta = Object.assign({}, root.note ? root.note.meta : {});
        delete meta.reminder;
        delete meta.reminderNotified;
        NotesService.updateMeta(root.noteId, { meta: meta });
    }

    function setLock(pin) {
        if (!root.noteId) return;
        if (!Persistent.ready || !Persistent.states.notes) return;
        const locked = Object.assign({}, Persistent.states.notes.lockedNotes || {});
        locked[root.noteId] = { pin: pin || "1234" };
        Persistent.states.notes.lockedNotes = locked;
        const meta = Object.assign({}, root.note ? root.note.meta : {}, { locked: true, pin: pin || "1234" });
        NotesService.updateMeta(root.noteId, { meta: meta });
        root.unlockedThisSession = true;
    }

    function removeLock() {
        if (!root.noteId) return;
        if (Persistent.ready && Persistent.states.notes?.lockedNotes) {
            const locked = Object.assign({}, Persistent.states.notes.lockedNotes);
            delete locked[root.noteId];
            Persistent.states.notes.lockedNotes = locked;
        }
        const meta = Object.assign({}, root.note ? root.note.meta : {}, { locked: false });
        delete meta.pin;
        NotesService.updateMeta(root.noteId, { meta: meta });
        root.unlockedThisSession = false;
    }

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

    function openExportSheet() {
        exportSheet.visible = true;
    }

    Rectangle {
        id: reminderPopup
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: NotesMetrics.panePadding
        anchors.topMargin: 68
        width: 220
        height: reminderLayout.implicitHeight + 24
        z: 15
        visible: false
        radius: Appearance.rounding.medium
        color: Appearance.colors.colLayer2
        border.color: Appearance.colors.colLayer3
        border.width: 1

        ColumnLayout {
            id: reminderLayout
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            StyledText {
                text: Translation.tr("Set Reminder")
                font.pixelSize: Appearance.font.pixelSize.base
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer0
            }

            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 32
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.colors.colLayer3
                colBackgroundHover: Appearance.colors.colLayer3Hover
                contentItem: StyledText {
                    anchors.centerIn: parent
                    text: Translation.tr("In 1 hour")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnLayer0
                }
                onClicked: {
                    root.setReminder(Date.now() + 3600 * 1000);
                    reminderPopup.visible = false;
                }
            }

            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 32
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.colors.colLayer3
                colBackgroundHover: Appearance.colors.colLayer3Hover
                contentItem: StyledText {
                    anchors.centerIn: parent
                    text: Translation.tr("Tomorrow 09:00")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnLayer0
                }
                onClicked: {
                    const d = new Date();
                    d.setDate(d.getDate() + 1);
                    d.setHours(9, 0, 0, 0);
                    root.setReminder(d.getTime());
                    reminderPopup.visible = false;
                }
            }

            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 32
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.colors.colLayer3
                colBackgroundHover: Appearance.colors.colLayer3Hover
                contentItem: StyledText {
                    anchors.centerIn: parent
                    text: Translation.tr("In 2 days")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnLayer0
                }
                onClicked: {
                    root.setReminder(Date.now() + 2 * 86400 * 1000);
                    reminderPopup.visible = false;
                }
            }

            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 32
                visible: root.reminderTimestamp > 0
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.m3colors.m3errorContainer
                colBackgroundHover: Appearance.m3colors.m3errorContainer
                contentItem: StyledText {
                    anchors.centerIn: parent
                    text: Translation.tr("Clear reminder")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.m3colors.m3onErrorContainer
                }
                onClicked: {
                    root.clearReminder();
                    reminderPopup.visible = false;
                }
            }
        }
    }

    Rectangle {
        id: lockModal
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: NotesMetrics.panePadding
        anchors.topMargin: 68
        width: 240
        height: lockModalLayout.implicitHeight + 24
        z: 16
        visible: false
        radius: Appearance.rounding.medium
        color: Appearance.colors.colLayer2
        border.color: Appearance.colors.colLayer3
        border.width: 1

        ColumnLayout {
            id: lockModalLayout
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            StyledText {
                text: root.isLocked ? Translation.tr("Manage Lock") : Translation.tr("Lock Note")
                font.pixelSize: Appearance.font.pixelSize.base
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer0
            }

            StyledText {
                text: root.isLocked ? Translation.tr("PIN is currently active.") : Translation.tr("Set a 4-digit PIN:")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                visible: !root.isLocked

                StyledTextInput {
                    id: newPinInput
                    anchors.fill: parent
                    echoMode: TextInput.Password
                    font.pixelSize: Appearance.font.pixelSize.base
                    color: Appearance.colors.colOnLayer0
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "1234"
                    font.pixelSize: Appearance.font.pixelSize.base
                    color: Appearance.colors.colSubtext
                    visible: newPinInput.text.length === 0
                }
            }

            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 32
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.colors.colPrimary
                colBackgroundHover: Appearance.colors.colPrimaryHover
                contentItem: StyledText {
                    anchors.centerIn: parent
                    text: root.isLocked ? Translation.tr("Remove Lock") : Translation.tr("Lock Note")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnPrimary
                }
                onClicked: {
                    if (root.isLocked) {
                        root.removeLock();
                    } else {
                        root.setLock(newPinInput.text || "1234");
                        newPinInput.text = "";
                    }
                    lockModal.visible = false;
                }
            }
        }
    }

    Rectangle {
        id: lockGuard
        anchors.fill: parent
        z: 25
        visible: root.note !== null && root.isLocked && !root.unlockedThisSession
        color: Appearance.m3colors.m3surfaceContainerHigh
        radius: Appearance.rounding.large

        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(parent.width - 64, 380)
            spacing: 16

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: "lock"
                iconSize: 56
                color: Appearance.colors.colPrimary
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("This note is locked")
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer0
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("Enter your PIN to unlock this note.")
                font.pixelSize: Appearance.font.pixelSize.base
                color: Appearance.colors.colSubtext
            }

            StyledTextInput {
                id: pinEntryField
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 160
                Layout.preferredHeight: 44
                echoMode: TextInput.Password
                horizontalAlignment: TextInput.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.Bold
                color: Appearance.colors.colOnLayer0
                activeFocusOnTab: true
                onAccepted: {
                    if (pinEntryField.text === root.storedPin) {
                        root.unlockedThisSession = true;
                        pinEntryField.text = "";
                        pinErrorText.visible = false;
                    } else {
                        pinErrorText.visible = true;
                    }
                }
            }

            StyledText {
                id: pinErrorText
                Layout.alignment: Qt.AlignHCenter
                visible: false
                text: Translation.tr("Incorrect PIN")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.m3colors.m3error
            }

            RippleButton {
                Layout.alignment: Qt.AlignHCenter
                implicitHeight: 40
                implicitWidth: 120
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.colors.colPrimary
                colBackgroundHover: Appearance.colors.colPrimaryHover
                colBackgroundActive: Appearance.colors.colPrimaryActive

                contentItem: StyledText {
                    anchors.centerIn: parent
                    text: Translation.tr("Unlock")
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnPrimary
                }

                onClicked: {
                    if (pinEntryField.text === root.storedPin) {
                        root.unlockedThisSession = true;
                        pinEntryField.text = "";
                        pinErrorText.visible = false;
                    } else {
                        pinErrorText.visible = true;
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: 12
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: Translation.tr("Note: Locked notes are protected within Quickshell UI. Files are stored unencrypted on disk.")
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
            }
        }
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
                symbol: "format_list_bulleted"
                tooltipText: Translation.tr("Table of contents")
                colIcon: Appearance.colors.colOnLayer1
                visible: !root.trash
                onTriggered: root.outlineRequested()
            }

            NotesIconButton {
                symbol: "history"
                tooltipText: Translation.tr("Version history")
                colIcon: Appearance.colors.colOnLayer1
                visible: !root.trash
                onTriggered: root.revisionsRequested()
            }

            NotesIconButton {
                symbol: root.reminderTimestamp > 0 ? "notifications_active" : "notifications"
                tooltipText: Translation.tr("Reminder")
                colIcon: root.reminderTimestamp > 0 ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                visible: !root.trash
                onTriggered: reminderPopup.visible = !reminderPopup.visible
            }

            NotesIconButton {
                symbol: root.isLocked ? "lock" : "lock_open"
                tooltipText: root.isLocked ? Translation.tr("Note locked") : Translation.tr("Lock note")
                colIcon: root.isLocked ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                visible: !root.trash
                onTriggered: lockModal.visible = !lockModal.visible
            }

            NotesIconButton {
                symbol: "fullscreen"
                tooltipText: Translation.tr("Focus mode")
                colIcon: Appearance.colors.colOnLayer1
                visible: !root.trash
                onTriggered: root.focusModeToggled()
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

            StyledText {
                text: Translation.tr("%1 words").arg(root.wordCount)
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                visible: root.wordCount > 0
            }

            StyledText {
                text: Translation.tr("%1 min read").arg(root.readingMinutes)
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                visible: root.wordCount > 0
            }

            Item {
                Layout.fillWidth: true
            }

            RowLayout {
                visible: root.reminderTimestamp > 0
                spacing: 4
                MaterialSymbol {
                    text: "notifications"
                    iconSize: 14
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: Translation.tr("Reminder: %1").arg(Qt.formatDateTime(new Date(root.reminderTimestamp), "d MMM, HH:mm"))
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colPrimary
                }
                NotesIconButton {
                    symbol: "close"
                    tooltipText: Translation.tr("Clear reminder")
                    colIcon: Appearance.colors.colSubtext
                    onTriggered: root.clearReminder()
                }
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
