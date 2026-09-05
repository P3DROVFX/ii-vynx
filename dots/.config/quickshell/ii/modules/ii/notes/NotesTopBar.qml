pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.notes

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
    property bool showRailToggle: false
    property bool railExpanded: true

    readonly property string query: field.text

    signal backRequested()
    signal railToggled()
    signal maximizeRequested()
    signal closeRequested()

    function focusSearch(): void {
        field.forceActiveFocus();
        field.selectAll();
    }

    function clearSearch(): void {
        field.text = "";
    }

    implicitHeight: NotesMetrics.topBarHeight

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 0
        spacing: 8

        NotesIconButton {
            symbol: "arrow_back"
            tooltipText: Translation.tr("Back to the list")
            visible: root.showBack
            onTriggered: root.backRequested()
        }

        // Where a navigation toggle belongs. On top of the rail it sat above the button
        // that makes notes, which is the one thing there that should be first.
        NotesIconButton {
            symbol: root.railExpanded ? "menu_open" : "menu"
            tooltipText: root.railExpanded ? Translation.tr("Collapse the sidebar") : Translation.tr("Expand the sidebar")
            visible: root.showRailToggle && !root.showBack
            onTriggered: root.railToggled()
        }

        ColumnLayout {
            // Its natural width, not a share of the bar. Given `fillWidth` it claimed
            // room it had no text for, and the search box ended up marooned in the middle
            // of a gap.
            Layout.maximumWidth: 280
            Layout.leftMargin: root.showBack ? 0 : NotesMetrics.panePadding - 4
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

        Rectangle {
            id: searchBox
            // Takes the space between the title and the actions, up to a width past which
            // a search field stops looking like one.
            Layout.fillWidth: true
            Layout.maximumWidth: NotesMetrics.searchMaximumWidth
            Layout.leftMargin: 16
            Layout.rightMargin: 8
            Layout.preferredHeight: NotesMetrics.iconButtonSize
            Layout.alignment: Qt.AlignVCenter
            radius: Appearance.rounding.full
            color: field.activeFocus
                ? Appearance.m3colors.m3surfaceContainerHighest
                : Appearance.m3colors.m3surfaceContainerHigh
            // Hidden only when the bar is genuinely too narrow for a search field. Read
            // from the bar's own width: `Layout.preferredWidth` is -1 once the box fills
            // the space, which silently hid it altogether.
            visible: root.width > 560

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: NotesMetrics.cardPadding
                anchors.rightMargin: 6
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

}
