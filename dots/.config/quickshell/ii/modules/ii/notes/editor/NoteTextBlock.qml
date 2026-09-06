import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.notes

/**
 * Every block you can type in: paragraph, heading, list item, quote, callout.
 *
 * One delegate for all five because they differ in what is drawn *beside* the text — a
 * bullet, a number, a checkbox, a bar, an icon — and in its size and weight, not in how it
 * behaves. Five nearly identical files would drift apart on the first change to key
 * handling, and key handling is the part that has to be identical.
 *
 * The text belongs to this item while it is being typed in. It is reported upwards on a
 * debounce and the editor writes it, but the editor never writes it back: a model that
 * updated per keystroke would rebuild this delegate and drop the caret to the start of the
 * line on every character.
 */
Item {
    id: root

    property var editor: null
    property var block: null
    property int blockIndex: 0

    readonly property string blockType: root.block ? root.block.type : "text"
    readonly property int indent: root.block && root.block.indent !== undefined ? root.block.indent : 0
    readonly property bool isList: root.blockType === "list"
    readonly property bool isChecked: root.isList && root.block.checked === true

    implicitHeight: Math.max(row.implicitHeight, editText.implicitHeight) + verticalPadding * 2

    readonly property int verticalPadding: root.blockType === "heading" ? 10 : 4
    readonly property int indentStep: 26

    readonly property int textSize: {
        if (root.blockType !== "heading")
            return Appearance.font.pixelSize.normal;
        if (root.block.level === 1)
            return Appearance.font.pixelSize.huge;
        return root.block.level === 2 ? Appearance.font.pixelSize.larger : Appearance.font.pixelSize.large;
    }

    readonly property color toneColor: {
        if (root.blockType !== "callout")
            return Appearance.colors.colOnLayer0;
        switch (root.block.tone) {
        case "success": return Appearance.m3colors.m3primary;
        case "warning": return Appearance.m3colors.m3tertiary;
        case "error": return Appearance.m3colors.m3error;
        default: return Appearance.colors.colOnLayer1;
        }
    }

    /// Which number this item shows. Counted from the items above it at the same level,
    /// because the document stores a list style rather than a running number — renumbering
    /// stored values on every insert is how numbered lists get out of step with themselves.
    readonly property int ordinal: {
        if (!root.isList || root.block.style !== "number" || !root.editor)
            return 1;
        let n = 1;
        for (let i = root.blockIndex - 1; i >= 0; i--) {
            const above = root.editor.blockAt(i);
            if (!above || above.type !== "list" || above.indent !== root.indent)
                break;
            if (above.style !== "number")
                break;
            n++;
        }
        return n;
    }

    // ── Focus ─────────────────────────────────────────────────────────────

    function takeFocus(caret): void {
        editText.forceActiveFocus();
        editText.cursorPosition = caret < 0 ? editText.length : Math.min(caret, editText.length);
        // Only now is the request spent. Clearing it before the caret was actually here
        // let a delegate that was about to be rebuilt swallow it.
        if (editText.activeFocus)
            root.editor.clearFocusRequest(root.block.id);
    }

    function checkFocusRequest(): void {
        if (!root.editor || !root.block)
            return;
        const caret = root.editor.peekFocus(root.block.id);
        if (caret !== -2)
            Qt.callLater(() => root.takeFocus(caret));
    }

    Connections {
        target: root.editor
        function onFocusRequestChanged() {
            root.checkFocusRequest();
        }
        function onFocusTickChanged() {
            root.checkFocusRequest();
        }
    }

    Component.onCompleted: root.checkFocusRequest()

    RowLayout {
        id: row
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: root.verticalPadding
        anchors.leftMargin: NotesMetrics.readingPadding + root.indent * root.indentStep
        anchors.rightMargin: NotesMetrics.readingPadding
        spacing: 10

        // ── What sits beside the text ─────────────────────────────────────

        Item {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: root.isList || root.blockType === "callout" ? 24 : 0
            Layout.preferredHeight: root.textSize + 8
            visible: Layout.preferredWidth > 0

            // Bullet
            Rectangle {
                anchors.centerIn: parent
                width: 6
                height: 6
                radius: 3
                color: Appearance.colors.colOnLayer1
                visible: root.isList && root.block.style === "bullet"
            }

            // Number
            StyledText {
                anchors.centerIn: parent
                text: root.ordinal + "."
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
                visible: root.isList && root.block.style === "number"
            }

            // Checkbox
            Rectangle {
                anchors.centerIn: parent
                width: 19
                height: 19
                radius: Appearance.rounding.verysmall
                visible: root.isList && root.block.style === "checkbox"
                color: root.isChecked ? Appearance.colors.colPrimary : "transparent"
                border.width: root.isChecked ? 0 : 2
                border.color: Appearance.colors.colOnLayer1Inactive

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "check"
                    iconSize: 15
                    color: Appearance.colors.colOnPrimary
                    opacity: root.isChecked ? 1 : 0

                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.editor.toggleChecked(root.block.id)
                }
            }

            // Callout icon
            MaterialSymbol {
                anchors.centerIn: parent
                visible: root.blockType === "callout"
                text: {
                    switch (root.block.tone) {
                    case "success": return "check_circle";
                    case "warning": return "warning";
                    case "error": return "error";
                    default: return "info";
                    }
                }
                iconSize: 20
                color: root.toneColor
            }
        }

        // The quote's bar. A shape rather than an icon: a quotation is a run of text set
        // aside, and the bar is what says how far it runs.
        Rectangle {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: root.blockType === "quote" ? 3 : 0
            Layout.preferredHeight: editText.implicitHeight
            radius: 2
            color: Appearance.colors.colPrimary
            visible: root.blockType === "quote"
        }

        TextEdit {
            id: editText
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            // A comfortable measure. A paragraph running the whole width of a maximised
            // window is a paragraph nobody finishes.
            Layout.maximumWidth: NotesMetrics.readingWidth

            text: root.block ? root.block.text : ""
            wrapMode: TextEdit.Wrap
            selectByMouse: true
            persistentSelection: true
            textFormat: TextEdit.PlainText
            renderType: Text.NativeRendering

            color: root.blockType === "callout" ? root.toneColor
                : root.blockType === "quote" ? Appearance.colors.colOnLayer1
                : Appearance.colors.colOnLayer0
            opacity: root.isChecked ? 0.55 : 1
            font {
                family: Appearance.font.family.main
                pixelSize: root.textSize
                weight: root.blockType === "heading" ? Font.DemiBold : Font.Normal
                italic: root.blockType === "quote"
                strikeout: root.isChecked
            }
            selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
            selectionColor: Appearance.colors.colSecondaryContainer

            // The placeholder only ever appears on the block the caret is in: a page of
            // "Write something…" under every empty line would be noise.
            StyledText {
                anchors.left: parent.left
                anchors.top: parent.top
                text: root.blockType === "heading"
                    ? Translation.tr("Heading")
                    : Translation.tr("Write something…")
                font: editText.font
                color: Appearance.colors.colOnLayer1Inactive
                visible: editText.length === 0 && editText.activeFocus
            }

            onActiveFocusChanged: {
                if (activeFocus) {
                    root.editor.activeBlockId = root.block.id;
                } else {
                    // Leaving the block commits whatever the debounce was still holding.
                    saveDebounce.stop();
                    root.commit();
                }
            }

            onTextChanged: {
                if (root.applying)
                    return;
                // Armed *before* the conversion, not after it. Converting the block
                // rebuilds this delegate, and the rebuild takes the focus away while
                // `tryShortcut` is still on the stack — so the focus-out handler ran
                // inside it and committed the text as it was a keystroke ago. That is how
                // a bullet ended up storing the "- " that had just been taken off it.
                root.applying = true;
                const converted = root.editor.tryShortcut(root.block.id, editText.text);
                if (converted !== null && converted !== undefined) {
                    saveDebounce.stop();
                    editText.text = converted;
                    editText.cursorPosition = editText.length;
                    root.endApplying();
                    return;
                }
                root.applying = false;
                saveDebounce.restart();
            }

            Keys.onPressed: event => root.handleKey(event)
        }
    }

    /**
     * True while this delegate is writing its own text, and for a moment afterwards.
     *
     * Two things depend on it. The assignment must not come back through `onTextChanged`
     * as if somebody had typed it. And nothing may *commit* during that window — which is
     * the subtler one: a markdown conversion replaces the block, the delegate loses focus
     * as it is rebuilt, and the focus-out handler would then save the text as it was
     * before the conversion. That is how "- " ended up stored as the content of a bullet
     * whose prefix had already been taken away.
     */
    property bool applying: false

    /// True while this block is the one waiting to hear what the clipboard held.
    property bool pasteTarget: false

    Connections {
        target: root.editor
        enabled: root.pasteTarget
        function onPasteFellThrough() {
            root.pasteTarget = false;
            // No image in the clipboard, so this is an ordinary paste after all — done
            // here rather than by the key handler, which could not have known yet.
            if (editText.activeFocus)
                editText.paste();
        }
    }

    function endApplying(): void {
        Qt.callLater(() => root.applying = false);
    }

    function commit(): void {
        if (root.applying || !root.block || !root.editor)
            return;
        if (editText.text === root.block.text)
            return;
        root.editor.commitText(root.block.id, editText.text);
    }

    Timer {
        id: saveDebounce
        // Short. The store debounces the disk write of its own; this one only decides how
        // often the document in memory is told, which is also how coarse undo is.
        interval: 400
        onTriggered: root.commit()
    }

    function handleKey(event): void {
        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
        const shift = (event.modifiers & Qt.ShiftModifier) !== 0;

        if (ctrl && event.key === Qt.Key_Z) {
            saveDebounce.stop();
            root.commit();
            if (shift)
                root.editor.redo();
            else
                root.editor.undo();
            event.accepted = true;
            return;
        }

        if (ctrl && event.key === Qt.Key_V && !shift) {
            // Handed over rather than decided here: what the clipboard holds can only be
            // learned from a subprocess. If it turns out not to be an image the editor
            // says so and the text paste happens then.
            root.pasteTarget = true;
            root.editor.pasteFromClipboard();
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (shift)
                return; // A soft break inside the block.
            saveDebounce.stop();
            root.editor.splitAt(root.block.id, editText.cursorPosition, editText.text);
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            saveDebounce.stop();
            root.commit();
            root.editor.indent(root.block.id, (shift || event.key === Qt.Key_Backtab) ? -1 : 1);
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Backspace
            && editText.cursorPosition === 0
            && editText.selectionStart === editText.selectionEnd) {
            saveDebounce.stop();
            root.editor.mergeInto(root.block.id, editText.text);
            event.accepted = true;
            return;
        }

        // Up on the first line and down on the last walk to the next block, so the whole
        // note is reachable without touching the mouse.
        if (event.key === Qt.Key_Up && editText.cursorPosition <= editText.text.indexOf("\n") + 1
            && !editText.text.slice(0, editText.cursorPosition).includes("\n")) {
            saveDebounce.stop();
            root.commit();
            root.editor.moveFocus(root.block.id, -1);
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Down
            && !editText.text.slice(editText.cursorPosition).includes("\n")) {
            saveDebounce.stop();
            root.commit();
            root.editor.moveFocus(root.block.id, 1);
            event.accepted = true;
        }
    }
}
