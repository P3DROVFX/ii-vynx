pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.notes

/**
 * Universal export dialog for the Notes app.
 *
 * Lets users export the current note or their entire notes collection
 * into open, portable formats:
 * - Markdown with external assets
 * - Self-contained HTML
 * - Portable PDF
 * - Complete ZIP store backup
 */
Item {
    id: root

    property string noteId: ""
    property var note: null
    property int allNotesCount: NotesService.notes ? NotesService.notes.length : 0

    signal closed()

    property string selectedFormat: "markdown" // "markdown" | "html" | "pdf" | "zip"
    property string scope: "current" // "current" | "all"
    property string destDirectory: `${Directories.documents}/NotesExport`
    property bool exporting: false
    property string statusMessage: ""
    property bool exportSuccess: false
    property string lastExportPath: ""

    function runExport(): void {
        root.exporting = true;
        root.statusMessage = Translation.tr("Exporting notes...");
        root.exportSuccess = false;
        NotesSync.exportNotes(root.selectedFormat, root.destDirectory, root.noteId, root.scope === "all");
    }

    Connections {
        target: NotesSync
        function onExportFinished(success, message, outputPath) {
            root.exporting = false;
            root.exportSuccess = success;
            root.statusMessage = message;
            if (success)
                root.lastExportPath = outputPath || root.destDirectory;
        }
    }

    // ── Scrim ─────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.65)

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }
    }

    // ── Dialog Card ───────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(parent.width - 32, 600)
        height: Math.min(parent.height - 32, 540)
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
                    text: "file_export"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Export Notes")
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

            // ── Scope Selector ────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    buttonRadius: Appearance.rounding.small
                    toggled: root.scope === "current"
                    colBackground: toggled ? Appearance.colors.colSecondaryContainer : Appearance.colors.colLayer1
                    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                    enabled: root.note !== null
                    onClicked: root.scope = "current"

                    contentItem: StyledText {
                        anchors.centerIn: parent
                        text: root.note ? Translation.tr("This Note (%1)").arg(root.note.title || Translation.tr("Untitled")) : Translation.tr("No Note Selected")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: root.scope === "current" ? Font.DemiBold : Font.Normal
                        color: root.scope === "current" ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                        elide: Text.ElideRight
                    }
                }

                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    buttonRadius: Appearance.rounding.small
                    toggled: root.scope === "all"
                    colBackground: toggled ? Appearance.colors.colSecondaryContainer : Appearance.colors.colLayer1
                    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                    onClicked: root.scope = "all"

                    contentItem: StyledText {
                        anchors.centerIn: parent
                        text: Translation.tr("All Notes (%1)").arg(root.allNotesCount)
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: root.scope === "all" ? Font.DemiBold : Font.Normal
                        color: root.scope === "all" ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                    }
                }
            }

            // ── Format Options ────────────────────────────────────────────
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 8

                Repeater {
                    model: [
                        { id: "markdown", title: "Markdown (.md)", icon: "description", desc: Translation.tr("Standard markdown with assets folder. Compatible with Obsidian & Logseq.") },
                        { id: "html", title: "HTML Autocontido", icon: "language", desc: Translation.tr("Portable web page with embedded Base64 images and CSS.") },
                        { id: "pdf", title: "Documento PDF", icon: "picture_as_pdf", desc: Translation.tr("Ready for printing via weasyprint or wkhtmltopdf.") },
                        { id: "zip", title: "Backup Completo (.zip)", icon: "folder_zip", desc: Translation.tr("Full archive of the notes store, documents and assets.") }
                    ]

                    delegate: RippleButton {
                        id: fmtBtn
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 74
                        buttonRadius: Appearance.rounding.normal
                        toggled: root.selectedFormat === fmtBtn.modelData.id
                        colBackground: toggled ? Appearance.colors.colSecondaryContainer : Appearance.colors.colLayer1
                        colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                        onClicked: root.selectedFormat = fmtBtn.modelData.id

                        contentItem: RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            MaterialSymbol {
                                text: fmtBtn.modelData.icon
                                iconSize: 26
                                color: fmtBtn.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colPrimary
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    text: fmtBtn.modelData.title
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.weight: Font.DemiBold
                                    color: fmtBtn.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0
                                }

                                StyledText {
                                    text: fmtBtn.modelData.desc
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    color: fmtBtn.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colSubtext
                                    wrapMode: Text.Wrap
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }

            // ── Destination Folder ────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    MaterialSymbol {
                        text: "folder"
                        iconSize: 18
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.destDirectory
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colOnLayer0
                        elide: Text.ElideMiddle
                    }
                }
            }

            // ── Status & Feedback Banner ──────────────────────────────────
            Rectangle {
                visible: root.statusMessage.length > 0
                Layout.fillWidth: true
                implicitHeight: statusRow.implicitHeight + 16
                radius: Appearance.rounding.small
                color: root.exportSuccess
                    ? Appearance.m3colors.m3primaryContainer
                    : Appearance.m3colors.m3errorContainer

                RowLayout {
                    id: statusRow
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    MaterialSymbol {
                        text: root.exportSuccess ? "check_circle" : (root.exporting ? "hourglass_top" : "error")
                        iconSize: 20
                        color: root.exportSuccess
                            ? Appearance.m3colors.m3onPrimaryContainer
                            : Appearance.m3colors.m3onErrorContainer
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.statusMessage
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: root.exportSuccess
                            ? Appearance.m3colors.m3onPrimaryContainer
                            : Appearance.m3colors.m3onErrorContainer
                        wrapMode: Text.Wrap
                    }

                    RippleButton {
                        visible: root.exportSuccess && root.lastExportPath.length > 0
                        implicitHeight: 28
                        implicitWidth: 90
                        buttonRadius: Appearance.rounding.verysmall
                        colBackground: Appearance.colors.colPrimary
                        colBackgroundHover: Appearance.colors.colPrimaryHover
                        onClicked: Quickshell.execDetached(["xdg-open", root.lastExportPath])

                        contentItem: StyledText {
                            anchors.centerIn: parent
                            text: Translation.tr("Open Folder")
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnPrimary
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // ── Footer Action Buttons ─────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                RippleButton {
                    implicitHeight: 38
                    implicitWidth: 90
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.colors.colLayer2
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    onClicked: root.closed()

                    contentItem: StyledText {
                        anchors.centerIn: parent
                        text: Translation.tr("Cancel")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                    }
                }

                Item { Layout.fillWidth: true }

                RippleButton {
                    implicitHeight: 38
                    implicitWidth: 120
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.m3colors.m3primary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    enabled: !root.exporting
                    onClicked: root.runExport()

                    contentItem: RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        MaterialSymbol {
                            text: "download"
                            iconSize: 18
                            color: Appearance.m3colors.m3onPrimary
                        }

                        StyledText {
                            text: root.exporting ? Translation.tr("Exporting...") : Translation.tr("Export")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            color: Appearance.m3colors.m3onPrimary
                        }
                    }
                }
            }
        }
    }
}
