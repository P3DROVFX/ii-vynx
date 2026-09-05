import QtQuick
import QtQuick.Layouts

import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * One note in the list.
 *
 * Everything drawn here comes from the index — title, preview, date, whether there is ink
 * in it. Not one card opens a document to render itself, which is the whole reason the
 * store keeps an index at all.
 */
RippleButton {
    id: root

    required property var note
    property bool current: false

    signal triggered()

    implicitHeight: layout.implicitHeight + 24
    buttonRadius: root.current ? Appearance.rounding.large : Appearance.rounding.normal
    toggled: root.current
    colBackground: Appearance.colors.colLayer2
    colBackgroundToggled: Appearance.colors.colSecondaryContainer

    onClicked: root.triggered()

    Behavior on buttonRadius {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    readonly property color colText: root.current
        ? Appearance.m3colors.m3onSecondaryContainer
        : Appearance.colors.colOnLayer1

    /// Today shows a time, this year a day and month, anything older the year as well.
    /// A list where every row says the same date is a list with no dates in it.
    readonly property string whenText: {
        const stamp = Number(root.note.modified) || Number(root.note.created) || 0;
        if (stamp <= 0)
            return "";
        const when = new Date(stamp);
        const now = new Date();
        if (when.toDateString() === now.toDateString())
            return Qt.formatDateTime(when, "HH:mm");
        if (when.getFullYear() === now.getFullYear())
            return Qt.formatDateTime(when, "d MMM");
        return Qt.formatDateTime(when, "MMM yyyy");
    }

    contentItem: ColumnLayout {
        id: layout
        spacing: 3

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 12
            spacing: 8

            MaterialSymbol {
                text: root.note.icon.length > 0 ? root.note.icon : "article"
                iconSize: 18
                color: root.colText
                opacity: 0.8
            }

            StyledText {
                Layout.fillWidth: true
                text: root.note.title.length > 0 ? root.note.title : Translation.tr("Untitled note")
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.DemiBold
                color: root.colText
                elide: Text.ElideRight
            }

            MaterialSymbol {
                text: "keep"
                iconSize: 15
                fill: 1
                color: root.colText
                visible: root.note.pinned === true
            }

            MaterialSymbol {
                text: "star"
                iconSize: 15
                fill: 1
                color: root.colText
                visible: root.note.favorite === true
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 12
            text: root.note.preview.length > 0 ? root.note.preview : Translation.tr("Empty")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: root.current
                ? Appearance.m3colors.m3onSecondaryContainer
                : Appearance.colors.colSubtext
            opacity: root.note.preview.length > 0 ? 1 : 0.6
            maximumLineCount: 2
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 12
            Layout.topMargin: 2
            spacing: 6

            StyledText {
                text: root.whenText
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: root.current
                    ? Appearance.m3colors.m3onSecondaryContainer
                    : Appearance.colors.colSubtext
                opacity: 0.85
            }

            MaterialSymbol {
                text: "draw"
                iconSize: 13
                color: Appearance.colors.colSubtext
                visible: root.note.hasInk === true
            }

            MaterialSymbol {
                text: "image"
                iconSize: 13
                color: Appearance.colors.colSubtext
                visible: root.note.hasImages === true
            }

            Item {
                Layout.fillWidth: true
            }
        }
    }
}
