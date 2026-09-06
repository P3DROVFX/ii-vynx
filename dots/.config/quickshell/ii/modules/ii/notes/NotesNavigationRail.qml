pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * Where you are, and everything that is about the whole app rather than one note.
 *
 * New note at the top, where the mail sidebar puts Compose. The places and the notebooks
 * in the middle, each a group shaped at its ends. And at the bottom the three things that
 * are not places at all — search, the trash, and the app's own settings — because a rail
 * that mixes "which notes am I looking at" with "find something" and "change something"
 * in one column makes all three harder to find.
 *
 * The bottom is a field and then a row, not three stacked buttons: three full-width
 * buttons in a column read as three more places.
 */
Item {
    id: root

    property bool expanded: true
    property string scope: "all"
    readonly property string query: searchBox.text

    signal scopePicked(string scope)
    signal createRequested()
    signal settingsRequested()

    // Clipped at the pane's own bounds.
    //
    // The slab below is a *sibling* of the content, so its own `clip` contains nothing —
    // a list long enough to scroll had cards drawn outside the rounded rectangle they are
    // supposed to live in. Clipping belongs to whatever owns the bounds, which is this.
    clip: true

    function clearSearch(): void {
        searchBox.text = "";
    }

    function focusSearch(): void {
        searchBox.forceActiveFocus();
    }

    readonly property var places: [
        { id: "all", icon: "description", name: Translation.tr("All notes") },
        { id: "recent", icon: "history", name: Translation.tr("Recent") },
        { id: "favorites", icon: "star", name: Translation.tr("Favourites") },
        { id: "trash", icon: "delete", name: Translation.tr("Trash") }
    ]

    readonly property var notebooks: Array.from(NotesService.notebooks ?? [])

    function countFor(scopeId) {
        const live = Array.from(NotesService.index.notes ?? []).filter(note => note.trashedAt === 0);
        if (scopeId === "all")
            return live.length;
        if (scopeId === "favorites")
            return live.filter(note => note.favorite).length;
        if (scopeId === "recent")
            return Math.min(20, live.length);
        if (scopeId === "trash")
            return Array.from(NotesService.index.notes ?? []).filter(note => note.trashedAt > 0).length;
        return live.filter(note => note.notebookId === scopeId || note.sectionId === scopeId).length;
    }

    // A slab. Opaque on purpose: the theme's layered colours are transparency-adjusted and
    // collapse into each other over a wallpaper, so a boundary drawn with them is not one
    // anybody can see. Every Cheatsheet page uses this surface for the same reason.
    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: Appearance.m3colors.m3surfaceContainerHigh
        clip: true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: NotesMetrics.panePadding
        spacing: 0

        RippleButton {
            id: composeButton
            Layout.fillWidth: true
            Layout.bottomMargin: 24
            implicitHeight: 64
            buttonRadius: NotesMetrics.pillRadius(composeButton.implicitHeight)
            colBackgroundToggled: Appearance.colors.colPrimary
            // The soft container, not primary. Primary belongs to whichever place you are
            // in; two bright blocks stacked made "make a note" and "where I am" shout at
            // each other. It is also exactly how Compose sits in the mail sidebar.
            colBackground: Appearance.colors.colSecondaryContainer
            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
            colBackgroundActive: Appearance.colors.colSecondaryContainerActive

            onClicked: root.createRequested()

            scale: composeButton.down ? 0.95 : (composeButton.hovered ? 1.02 : 1.0)
            Behavior on scale {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            contentItem: RowLayout {
                spacing: 12
                anchors.centerIn: root.expanded ? undefined : parent

                Item {
                    Layout.preferredWidth: root.expanded ? 26 : 0
                    Layout.fillWidth: !root.expanded
                    Layout.fillHeight: true

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "edit"
                        iconSize: Appearance.font.pixelSize.huge
                        color: Appearance.m3colors.m3onSecondaryContainer
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("New note")
                    visible: root.expanded
                    font.pixelSize: Appearance.font.pixelSize.huge
                    font.weight: Font.DemiBold
                    color: Appearance.m3colors.m3onSecondaryContainer
                    elide: Text.ElideRight
                }
            }

            StyledToolTip {
                text: Translation.tr("New note")
                extraVisibleCondition: !root.expanded
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: railColumn.implicitHeight
            clip: true

            ColumnLayout {
                id: railColumn
                width: parent.width
                spacing: 2

                Repeater {
                    model: root.places
                    delegate: NotesRailItem {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        isFirst: index === 0
                        isLast: index === root.places.length - 1
                        prevIsCurrent: index > 0 && root.scope === root.places[index - 1].id
                        nextIsCurrent: index < root.places.length - 1 && root.scope === root.places[index + 1].id
                        expanded: root.expanded
                        symbol: modelData.icon
                        label: modelData.name
                        count: root.countFor(modelData.id)
                        current: root.scope === modelData.id
                        onTriggered: root.scopePicked(modelData.id)
                    }
                }

                StyledText {
                    // On the same line as the rows' text, not their icons: it is a heading
                    // for what they say, not for what they show.
                    Layout.leftMargin: NotesMetrics.rowHeight
                    Layout.topMargin: 14
                    Layout.bottomMargin: 2
                    text: Translation.tr("Notebooks")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colSubtext
                    visible: root.expanded && root.notebooks.length > 0
                }

                Repeater {
                    model: root.notebooks
                    delegate: NotesRailItem {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        isFirst: index === 0
                        isLast: index === root.notebooks.length - 1
                        prevIsCurrent: index > 0 && root.scope === root.notebooks[index - 1].id
                        nextIsCurrent: index < root.notebooks.length - 1 && root.scope === root.notebooks[index + 1].id
                        expanded: root.expanded
                        symbol: modelData.icon.length > 0 ? modelData.icon : "book"
                        label: modelData.title
                        count: root.countFor(modelData.id)
                        current: root.scope === modelData.id
                        onTriggered: root.scopePicked(modelData.id)
                    }
                }
            }
        }

        NotesSearchBox {
            id: searchBox
            Layout.fillWidth: true
            Layout.topMargin: 20
            Layout.bottomMargin: 8
            expanded: root.expanded
            placeholder: Translation.tr("Search notes")
            onCleared: root.clearSearch()
        }

        // Below the search, where the mail sidebar keeps its own Settings.
        RippleButton {
            id: settingsButton
            Layout.fillWidth: true
            implicitHeight: 56
            buttonRadius: NotesMetrics.pillRadius(settingsButton.implicitHeight)
            colBackground: Appearance.colors.colSecondaryContainer
            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
            colBackgroundActive: Appearance.colors.colSecondaryContainerActive
            colRipple: Appearance.colors.colPrimaryActive

            scale: settingsButton.down ? 0.95 : (settingsButton.hovered ? 1.02 : 1.0)
            Behavior on scale {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            onClicked: root.settingsRequested()

            contentItem: Item {
                anchors.fill: parent

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignVCenter
                        text: "settings"
                        iconSize: Appearance.font.pixelSize.huge
                        color: Appearance.m3colors.m3onSecondaryContainer
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignVCenter
                        text: Translation.tr("Settings")
                        visible: root.expanded
                        font.pixelSize: Appearance.font.pixelSize.huge
                        font.weight: Font.DemiBold
                        color: Appearance.m3colors.m3onSecondaryContainer
                    }
                }
            }

            StyledToolTip {
                text: Translation.tr("Notes settings")
                extraVisibleCondition: !root.expanded
            }
        }
    }
}
