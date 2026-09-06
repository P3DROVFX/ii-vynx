pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.notes
import "../../../../services/notes/NotesDocument.js" as Doc
import "../../../../services/notes/NotesShortcuts.js" as Shortcuts

/**
 * The editor: a list of blocks, and the one place operations are applied.
 *
 * The structural rule that everything else follows: **a text edit never rebuilds the
 * list.** The delegate owns its own text while it is being typed in, and reports it on a
 * debounce; the local `blocks` array is only replaced when the note changes or when a
 * block is inserted, removed, moved or retyped. Feeding every keystroke back through the
 * model would rebuild the delegate the cursor is sitting in, and the caret would jump to
 * the start of the line on every character.
 */
Item {
    id: root

    property string noteId: ""
    /// Blocks as the list draws them. Structural changes replace this; typing does not.
    property var blocks: []
    property bool ready: false

    readonly property int count: root.blocks.length

    signal blockFocused(string blockId)

    // ── Loading ───────────────────────────────────────────────────────────

    /// The shape of what is loaded: which blocks, in which order, of which type. Text is
    /// deliberately not part of it — that is the thing the delegates own while they are
    /// being typed in.
    function structureOf(blocks): string {
        return Doc.asArray(blocks).map(item => `${item.id}:${item.type}:${item.indent ?? 0}`).join("|");
    }

    /**
     * Reads the document again.
     *
     * Safe to call at any time, because it replaces `blocks` only when the *structure*
     * changed. That matters more than it sounds: a document can arrive after the note has
     * been selected — the file is read asynchronously — and an editor that only looked
     * once would show an empty page over a note that has text in it. The first thing typed
     * would then be saved over the real content.
     */
    function syncFromDocument(): void {
        const document = root.noteId.length > 0 ? NotesService.documentOf(root.noteId) : null;
        const next = document ? Doc.asArray(document.blocks) : [];
        root.ready = document !== null;
        if (root.structureOf(next) !== root.structureOf(root.blocks))
            root.blocks = next;
        if (root.pendingAutoFocus && root.blocks.length > 0) {
            root.pendingAutoFocus = false;
            root.focusFirstBlock();
        }
    }

    onNoteIdChanged: {
        root.undoStack = [];
        root.redoStack = [];
        root.syncFromDocument();
    }

    Connections {
        target: NotesService
        function onNoteChanged(noteId) {
            // Only when somebody else changed it. Our own writes already match what the
            // delegates are showing, and resyncing would rebuild the row being typed in.
            if (noteId === root.noteId && !root.writingOurselves)
                root.syncFromDocument();
        }
        function onDataChanged() {
            // Not gated on readiness any more: this is how a document that finished
            // loading after its note was selected reaches the editor at all.
            root.syncFromDocument();
        }
    }

    property bool writingOurselves: false

    /**
     * Whether the caret should land in the note as soon as it loads.
     *
     * Set by whoever *made* the note, not by whoever opened one. Selecting a note in the
     * list should leave the keyboard where it was so the list can still be walked with the
     * arrows; a note that was just created has nowhere else the caret could reasonably be.
     */
    property bool pendingAutoFocus: false

    function focusFirstBlock(): void {
        const typable = root.blocks.find(item =>
            ["text", "heading", "list", "quote", "callout"].includes(item.type));
        if (typable)
            root.focusRequest = typable.id;
    }

    function requestAutoFocus(): void {
        if (root.blocks.length > 0)
            root.focusFirstBlock();
        else
            root.pendingAutoFocus = true;
    }

    // ── Operations ────────────────────────────────────────────────────────

    property var undoStack: []
    property var redoStack: []
    readonly property int undoLimit: 200

    /**
     * The single way anything changes.
     *
     * `structural` says whether the list has to be rebuilt afterwards. A text update does
     * not: the delegate already shows what was written.
     */
    function apply(ops, structural = true, recordUndo = true): bool {
        if (root.noteId.length === 0)
            return false;
        root.writingOurselves = true;
        const result = NotesService.applyOps(root.noteId, ops);
        root.writingOurselves = false;
        if (!result.ok || !result.changed)
            return false;
        if (recordUndo) {
            root.undoStack = root.undoStack.concat([result.inverse]).slice(-root.undoLimit);
            root.redoStack = [];
        }
        if (structural)
            root.syncFromDocument();
        return true;
    }

    function undo(): void {
        if (root.undoStack.length === 0)
            return;
        const ops = root.undoStack[root.undoStack.length - 1];
        root.undoStack = root.undoStack.slice(0, -1);
        root.writingOurselves = true;
        const result = NotesService.applyOps(root.noteId, ops);
        root.writingOurselves = false;
        if (result.ok && result.changed)
            root.redoStack = root.redoStack.concat([result.inverse]);
        root.syncFromDocument();
    }

    function redo(): void {
        if (root.redoStack.length === 0)
            return;
        const ops = root.redoStack[root.redoStack.length - 1];
        root.redoStack = root.redoStack.slice(0, -1);
        root.writingOurselves = true;
        const result = NotesService.applyOps(root.noteId, ops);
        root.writingOurselves = false;
        if (result.ok && result.changed)
            root.undoStack = root.undoStack.concat([result.inverse]);
        root.syncFromDocument();
    }

    function blockAt(index): var {
        return index >= 0 && index < root.blocks.length ? root.blocks[index] : null;
    }

    function indexOfBlock(blockId): int {
        return root.blocks.findIndex(item => item.id === blockId);
    }

    // ── What the delegates ask for ────────────────────────────────────────

    /// Text as it is typed. Not structural: the delegate is already showing this.
    function commitText(blockId, text): void {
        root.apply([{ op: "update", id: blockId, patch: { text: text } }], false);
    }

    /**
     * A markdown prefix was typed. The block becomes what it says and the prefix goes.
     *
     * Returns the text the delegate should now show, or null when nothing applied — the
     * delegate cannot read it back from the model, because the model is not rebuilt for
     * text edits.
     */
    function tryShortcut(blockId, text): var {
        const index = root.indexOfBlock(blockId);
        const block = root.blockAt(index);
        if (!block)
            return null;
        const conversion = Shortcuts.conversionFor(block, text);
        if (!conversion)
            return null;
        if (!root.apply(Shortcuts.conversionOperations(block, conversion, index)))
            return null;
        root.focusRequest = conversion.type === "divider"
            ? root.blockIdAt(index + 1)
            : blockId;
        return conversion.text;
    }

    function blockIdAt(index): string {
        const block = root.blockAt(index);
        return block ? block.id : "";
    }

    /// Enter. Splits here, or leaves the list when the item is empty.
    function splitAt(blockId, offset, text): void {
        const index = root.indexOfBlock(blockId);
        const block = root.blockAt(index);
        if (!block)
            return;
        const current = Object.assign({}, block, { text: text });
        if (Shortcuts.shouldExit(current)) {
            root.apply(Shortcuts.exitOperations(current));
            root.focusRequest = blockId;
            return;
        }
        // The typed text has to land first: the split reads the block's text from the
        // document, and the document has not seen this keystroke yet.
        root.apply([{ op: "update", id: blockId, patch: { text: text } }], false, false);
        if (root.apply([{ op: "split", id: blockId, offset: offset }]))
            root.focusRequest = root.blockIdAt(index + 1);
    }

    /// Backspace at the very start. Joins this block onto the one above.
    function mergeInto(blockId, text): void {
        const index = root.indexOfBlock(blockId);
        const block = root.blockAt(index);
        if (!block || index <= 0)
            return;
        // A structured empty block becomes a paragraph first: backspace at the start of a
        // bullet should undo the bullet, not eat the line above it.
        if (block.type !== "text" && String(text).length === 0) {
            root.apply([{ op: "setType", id: blockId, type: "text", props: { text: "", indent: block.indent ?? 0 } }]);
            root.focusRequest = blockId;
            return;
        }
        const previous = root.blockAt(index - 1);
        root.apply([{ op: "update", id: blockId, patch: { text: text } }], false, false);
        const caret = previous && previous.hasOwnProperty("text") ? String(previous.text).length : 0;
        if (root.apply([{ op: "merge", id: blockId }])) {
            root.focusRequest = previous.id;
            root.focusCaret = caret;
        }
    }

    function indent(blockId, delta): void {
        root.apply([{ op: "indent", id: blockId, delta: delta }]);
        root.focusRequest = blockId;
    }

    function setType(blockId, type, props = null): void {
        root.apply([{ op: "setType", id: blockId, type: type, props: props ?? {} }]);
        root.focusRequest = blockId;
    }

    function toggleChecked(blockId): void {
        const block = root.blockAt(root.indexOfBlock(blockId));
        if (!block || block.type !== "list" || block.style !== "checkbox")
            return;
        root.apply([{ op: "update", id: blockId, patch: { checked: !block.checked } }]);
    }

    function removeBlock(blockId): void {
        const index = root.indexOfBlock(blockId);
        root.apply([{ op: "delete", id: blockId }]);
        root.focusRequest = root.blockIdAt(Math.max(0, index - 1));
    }

    function moveFocus(blockId, delta): void {
        const index = root.indexOfBlock(blockId);
        const next = index + delta;
        if (next < 0 || next >= root.blocks.length)
            return;
        root.focusRequest = root.blockIdAt(next);
        root.focusCaret = delta < 0 ? -1 : 0;
    }

    /// Which block should take the caret next, and where in it. Consumed by the delegate
    /// that matches, because only it knows when it is ready to be focused.
    property string focusRequest: ""
    /// -1 means the end of the block; 0 or more is an offset.
    property int focusCaret: -1

    /**
     * Bumped to ask the delegates to look again.
     *
     * A structural change rebuilds every delegate, and the one that should take the caret
     * may not exist yet when the request is made — its `Component.onCompleted` runs before
     * the Loader has even handed it a reference to this editor, so it has nothing to ask.
     * Rather than depend on the order those things happen in, the request is repeated a
     * frame later and the delegates check again.
     */
    property int focusTick: 0

    onFocusRequestChanged: {
        if (root.focusRequest.length > 0)
            refocusTimer.restart();
    }

    Timer {
        id: refocusTimer
        // As short as a timer can be. The caret has to come back within one frame of the
        // conversion, or a keystroke typed in that gap has nowhere to land — which costs
        // the first character of whatever follows a markdown prefix.
        interval: 1
        repeat: false
        onTriggered: root.focusTick++
    }

    /**
     * Whether this block is the one that should take the caret, and where in it.
     *
     * A *look*, not a claim. Clearing the request here is what broke the caret after a
     * markdown conversion: the delegate that answered was rebuilt an instant later and
     * died before it could act, and by then the request it had already cleared was gone —
     * so nothing took the focus and the next keystroke went nowhere.
     *
     * `-2` means "not you".
     */
    function peekFocus(blockId): int {
        return root.focusRequest === blockId ? root.focusCaret : -2;
    }

    /// Called by the delegate once it actually has the caret.
    function clearFocusRequest(blockId): void {
        if (root.focusRequest !== blockId)
            return;
        root.focusRequest = "";
        root.focusCaret = -1;
    }

    /// The block the caret is in, for the toolbar.
    property string activeBlockId: ""
    readonly property var activeBlock: root.blockAt(root.indexOfBlock(root.activeBlockId))

    // ── The list ──────────────────────────────────────────────────────────

    ListView {
        id: list
        anchors.fill: parent
        model: root.blocks
        spacing: 2
        clip: true
        // Every block has to exist for the caret to be able to reach it with the keyboard,
        // and a note is a page rather than a feed.
        cacheBuffer: 20000

        delegate: NoteBlockDelegate {
            required property var modelData
            required property int index
            width: list.width
            editor: root
            block: modelData
            blockIndex: index
        }

        footer: Item {
            // A fixed height. Sizing it from the space left in the view reads
            // `contentHeight`, which the footer is part of — a binding loop that keeps the
            // list relaying out, rebuilding the delegate the caret is in and dropping the
            // focus on every pass.
            height: 200

            // Clicking the space under the last block puts the caret in it, or makes a
            // paragraph when the note ends in something you cannot type into.
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    const last = root.blockAt(root.blocks.length - 1);
                    if (last && ["text", "heading", "list", "quote", "callout"].includes(last.type))
                        root.focusRequest = last.id;
                    else
                        root.apply([{ op: "insert", index: root.blocks.length, block: { type: "text" } }]);
                }
            }
        }
    }

    Component.onCompleted: root.syncFromDocument()
}
