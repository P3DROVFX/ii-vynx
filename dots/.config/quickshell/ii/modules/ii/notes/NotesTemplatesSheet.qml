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
 * Template selection sheet for the Notes app.
 *
 * Lets users pick from rich, structured templates for meetings, daily journaling,
 * tasks, code snippets, recipes, and reviews, or from user-saved templates.
 */
Item {
    id: root

    signal closed()
    signal templateSelected(string title, var tags, var blocks)

    readonly property var builtinTemplates: Templates.getBuiltinTemplates()
    readonly property var customTemplates: (Persistent.ready && Persistent.states.notes?.customTemplates)
        ? Persistent.states.notes.customTemplates
        : []
    readonly property var allTemplates: [].concat(root.builtinTemplates, root.customTemplates)

    property int selectedIndex: 0
    readonly property var selectedTemplate: root.allTemplates[root.selectedIndex] ?? root.builtinTemplates[0]

    function applyTemplate(tmpl) {
        const item = tmpl || root.selectedTemplate;
        if (!item)
            return;
        const blocks = Templates.instantiateBlocks(item);
        const title = item.name ? Translation.tr(item.name) : Translation.tr("New Note");
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
                    text: Translation.tr("Note Templates")
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer0
                }

                NotesIconButton {
                    symbol: "close"
                    size: 34
                    iconSize: 20
                    tooltipText: Translation.tr("Close")
                    onTriggered: root.closed()
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
                    radius: Appearance.rounding.medium
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
                            colBackground: toggled
                                ? Appearance.colors.colSecondaryContainer
                                : Appearance.colors.colLayer2
                            colBackgroundHover: toggled
                                ? Appearance.colors.colSecondaryContainerHover
                                : Appearance.colors.colLayer2Hover

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
                                        text: Translation.tr(tmplBtn.modelData.name || "Template")
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        font.weight: tmplBtn.toggled ? Font.DemiBold : Font.Normal
                                        color: tmplBtn.toggled
                                            ? Appearance.colors.colOnSecondaryContainer
                                            : Appearance.colors.colOnLayer2
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: Translation.tr(tmplBtn.modelData.description || "")
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
                    radius: Appearance.rounding.medium
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
                                text: root.selectedTemplate ? Translation.tr(root.selectedTemplate.name || "") : ""
                                font.pixelSize: Appearance.font.pixelSize.large
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colOnLayer1
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.selectedTemplate ? Translation.tr(root.selectedTemplate.description || "") : ""
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
                                model: root.selectedTemplate ? (root.selectedTemplate.blocks || []) : []

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
                                        text: {
                                            const txt = modelData.text || modelData.type || "";
                                            return txt.length > 0 ? txt : Translation.tr("(empty line)");
                                        }
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
                    implicitHeight: 38
                    implicitWidth: 100
                    buttonRadius: Appearance.rounding.small
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
                    implicitHeight: 38
                    implicitWidth: 180
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    onClicked: root.applyTemplate()

                    contentItem: RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        MaterialSymbol {
                            text: "add"
                            iconSize: 18
                            color: Appearance.colors.colOnPrimary
                        }

                        StyledText {
                            text: Translation.tr("Use Template")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnPrimary
                        }
                    }
                }
            }
        }
    }
}
