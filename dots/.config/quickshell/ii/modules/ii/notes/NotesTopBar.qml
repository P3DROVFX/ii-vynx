pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * The bar across the top: where you are, what you are looking for, and the way out.
 *
 * Search sits in the middle rather than in the list pane because it searches everything,
 * not the pane beside it. Putting it over the list would say the opposite.
 */
Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property bool showBack: false
    property bool maximized: false

    readonly property string query: field.text

    signal backRequested()
    signal maximizeRequested()
    signal closeRequested()

    function focusSearch(): void {
        field.forceActiveFocus();
        field.selectAll();
    }

    function clearSearch(): void {
        field.text = "";
    }

    implicitHeight: 64

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        NotesIconButton {
            symbol: "arrow_back"
            tooltipText: Translation.tr("Back to the list")
            visible: root.showBack
            onTriggered: root.backRequested()
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: 260
            Layout.leftMargin: root.showBack ? 0 : 8
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.title.length > 0 ? root.title : Translation.tr("Untitled note")
                // Expressive typography leans on contrast between the title and everything
                // around it, so this is deliberately large for a bar.
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer0
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: root.subtitle
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 12
        }

        Rectangle {
            id: searchBox
            Layout.preferredWidth: Math.min(360, root.width * 0.36)
            Layout.preferredHeight: 44
            Layout.alignment: Qt.AlignVCenter
            radius: Appearance.rounding.full
            color: field.activeFocus ? Appearance.colors.colLayer2 : Appearance.colors.colLayer1
            visible: Layout.preferredWidth > 140

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 8
                spacing: 8

                MaterialSymbol {
                    text: "search"
                    iconSize: 20
                    color: Appearance.colors.colOnLayer1
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    StyledTextInput {
                        id: field
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        color: Appearance.colors.colOnLayer1
                        clip: true
                        onAccepted: field.focus = false
                    }

                    // `StyledTextInput` is a bare `TextInput`; there is no placeholder to
                    // set, so it is drawn here rather than swapped in for a heavier field.
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Translation.tr("Search notes")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1Inactive
                        visible: field.text.length === 0 && !field.activeFocus
                    }
                }

                NotesIconButton {
                    symbol: "close"
                    size: 30
                    iconSize: 16
                    tooltipText: Translation.tr("Clear the search")
                    visible: field.text.length > 0
                    onTriggered: root.clearSearch()
                }
            }
        }

        NotesIconButton {
            symbol: root.maximized ? "close_fullscreen" : "open_in_full"
            tooltipText: root.maximized ? Translation.tr("Restore the window") : Translation.tr("Fill the screen")
            onTriggered: root.maximizeRequested()
        }

        NotesIconButton {
            symbol: "close"
            tooltipText: Translation.tr("Close notes")
            onTriggered: root.closeRequested()
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Appearance.colors.colOutlineVariant
    }
}
