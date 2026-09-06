pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.notes
import "../../../services/notes/NotesTemplates.js" as Templates

/**
 * Starting from something rather than from an empty page.
 *
 * A sheet and not a page, unlike the settings: this is one decision, taken on the way to
 * writing, and it ends with a note open. The list on the left, what you would get on the
 * right, because a template's name never says how much structure it brings.
 */
Item {
    id: root

    signal closed()
    signal templateSelected(string title, var tags, var blocks)

    /// Only the built-in ones. The first version also concatenated
    /// `Persistent.states.notes.customTemplates`, a property that does not exist and that
    /// nothing in the app could have written: there is no way to save a note as a
    /// template yet, so there was nothing to read.
    readonly property var allTemplates: Templates.getBuiltinTemplates()

    property int selectedIndex: 0

    readonly property var previewBlocks: root.selectedTemplate
        ? Templates.instantiateBlocks(root.selectedTemplate)
        : []
    readonly property var selectedTemplate: root.allTemplates[root.selectedIndex] ?? root.allTemplates[0]

    function applyTemplate(tmpl) {
        const item = tmpl || root.selectedTemplate;
        if (!item)
            return;
        const blocks = Templates.instantiateBlocks(item);
        // The catalogue's own words. `Translation.tr` on a variable cannot be extracted
        // and translates nothing; a template's name is data, like a note's title.
        const title = item.name.length > 0 ? item.name : Translation.tr("Untitled note");
        const tags = Array.isArray(item.tags) ? item.tags.slice() : [];

        root.templateSelected(title, tags, blocks);
        root.closed();
    }

    // ── Scrim ─────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.65)

        MouseArea {
            anchors.fill: parent
            onClicked: root.closed()
        }
    }

    // ── Dialog Card ───────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(parent.width - 32, 760)
        height: Math.min(parent.height - 32, 560)
        radius: Appearance.rounding.large
        color: Appearance.m3colors.m3surfaceContainerHighest
        clip: true

        StyledRectangularShadow {
            target: card
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            // ── Header ────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                MaterialSymbol {
                    text: "dashboard_customize"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Start from a template")
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer0
                }

            }

            // ── Body: Two Panes (Template List & Preview) ───────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 14

                // Left: Template Cards
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 320
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    clip: true

                    ListView {
                        id: templateListView
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6
                        model: root.allTemplates
                        currentIndex: root.selectedIndex

                        delegate: RippleButton {
                            id: tmplBtn
                            required property var modelData
                            required property int index

                            width: templateListView.width
                            implicitHeight: 64
                            buttonRadius: Appearance.rounding.small
                            toggled: root.selectedIndex === tmplBtn.index
                            colBackground: Appearance.colors.colLayer2
                            colBackgroundHover: Appearance.colors.colLayer2Hover
                            colBackgroundToggled: Appearance.colors.colSecondaryContainer
                            colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover

                            onClicked: root.selectedIndex = tmplBtn.index
                            onDoubleClicked: root.applyTemplate(tmplBtn.modelData)

                            contentItem: RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                Rectangle {
                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 40
                                    radius: Appearance.rounding.small
                                    color: tmplBtn.toggled
                                        ? Appearance.colors.colPrimary
                                        : Appearance.colors.colLayer3

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: tmplBtn.modelData.icon || "description"
                                        iconSize: 22
                                        color: tmplBtn.toggled
                                            ? Appearance.colors.colOnPrimary
                                            : Appearance.colors.colPrimary
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: tmplBtn.modelData.name
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        font.weight: tmplBtn.toggled ? Font.DemiBold : Font.Normal
                                        color: tmplBtn.toggled
                                            ? Appearance.colors.colOnSecondaryContainer
                                            : Appearance.colors.colOnLayer2
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: tmplBtn.modelData.description
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colSubtext
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }
                                }
                            }
                        }
                    }
                }

                // Right: Structure Preview
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            MaterialSymbol {
                                text: root.selectedTemplate ? (root.selectedTemplate.icon || "description") : "description"
                                iconSize: 20
                                color: Appearance.colors.colPrimary
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: root.selectedTemplate ? root.selectedTemplate.name : ""
                                font.pixelSize: Appearance.font.pixelSize.large
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colOnLayer1
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.selectedTemplate ? root.selectedTemplate.description : ""
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                            wrapMode: Text.WordWrap
                        }

                        // Preview Blocks
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Appearance.rounding.small
                            color: Appearance.colors.colLayer2
                            clip: true

                            ListView {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 6
                                // The instantiated blocks, not the raw definition: the
                                // definition carries a `%date%` token, and a preview that
                                // shows the token is a preview of the source code.
                                model: root.previewBlocks

                                delegate: RowLayout {
                                    required property var modelData
                                    required property int index
                                    width: parent ? parent.width : 200
                                    spacing: 8

                                    MaterialSymbol {
                                        text: {
                                            const t = modelData.type;
                                            if (t === "heading") return "title";
                                            if (t === "list") return modelData.style === "checkbox" ? "check_box" : "format_list_bulleted";
                                            if (t === "callout") return "lightbulb";
                                            if (t === "code") return "code";
                                            if (t === "quote") return "format_quote";
                                            return "short_text";
                                        }
                                        iconSize: 16
                                        color: Appearance.colors.colPrimary
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        // A line the template leaves for you to fill in
                                        // says so. It used to print the block's type name
                                        // — "list", "text" — which reads as content.
                                        text: String(modelData.text ?? "").length > 0
                                            ? modelData.text
                                            : Translation.tr("for you to fill in")
                                        opacity: String(modelData.text ?? "").length > 0 ? 1 : 0.55
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        font.weight: modelData.type === "heading" ? Font.DemiBold : Font.Normal
                                        color: Appearance.colors.colOnLayer2
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Footer Actions ────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item { Layout.fillWidth: true }

                RippleButton {
                    id: cancelButton
                    implicitHeight: 44
                    implicitWidth: 110
                    buttonRadius: NotesMetrics.pillRadius(cancelButton.implicitHeight)
                    colBackground: Appearance.colors.colLayer2
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    onClicked: root.closed()

                    contentItem: StyledText {
                        anchors.centerIn: parent
                        text: Translation.tr("Cancel")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer2
                    }
                }

                RippleButton {
                    id: useButton
                    implicitHeight: 44
                    implicitWidth: 160
                    buttonRadius: NotesMetrics.pillRadius(useButton.implicitHeight)
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    colBackgroundActive: Appearance.colors.colPrimaryActive
                    onClicked: root.applyTemplate()

                    contentItem: StyledText {
                        anchors.centerIn: parent
                        text: Translation.tr("Use this one")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnPrimary
                    }
                }
            }
        }
    }
}
