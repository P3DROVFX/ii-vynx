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
    property bool showRailToggle: false
    property bool railExpanded: true

    signal backRequested()
    signal railToggled()
    signal settingsRequested()
    signal closeRequested()

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

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        NotesIconButton {
            symbol: "tune"
            tooltipText: Translation.tr("Notes settings")
            onTriggered: root.settingsRequested()
        }

        NotesIconButton {
            symbol: "close"
            tooltipText: Translation.tr("Close notes")
            onTriggered: root.closeRequested()
        }
    }

}
