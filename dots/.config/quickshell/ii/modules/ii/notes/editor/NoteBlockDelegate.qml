import QtQuick

import qs.modules.common

/// Picks the delegate for a block. A Loader rather than a DelegateChooser so the block
/// keeps its identity across a type change — the id survives `setType`, and so should the
/// row the caret is in.
Item {
    id: root

    required property var editor
    required property var block
    required property int blockIndex

    implicitHeight: loader.item ? loader.item.implicitHeight : 0

    Loader {
        id: loader
        width: parent.width
        sourceComponent: {
            if (root.block.type === "divider")
                return dividerComponent;
            // A file, not prose. Read-only until the ink surface and the image block land;
            // without this a migrated sketch would open as an empty paragraph.
            if (["ink", "image"].includes(root.block.type))
                return mediaComponent;
            return textComponent;
        }

        onLoaded: {
            item.editor = Qt.binding(() => root.editor);
            item.block = Qt.binding(() => root.block);
            item.blockIndex = Qt.binding(() => root.blockIndex);
        }
    }

    Component {
        id: textComponent
        NoteTextBlock {}
    }

    Component {
        id: dividerComponent
        NoteDividerBlock {}
    }

    Component {
        id: mediaComponent
        NoteMediaBlock {}
    }
}
