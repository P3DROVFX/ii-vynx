pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.services
import qs.services.notes
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.notes

/**
 * In-app settings sheet for the Notes application.
 *
 * Provides dedicated controls for:
 * - Editor & Paper preferences
 * - Cloud backup (Google Drive, Keep Takeout, Universal Export)
 * - Links and media preview privacy
 * - Trash maintenance
 */
Item {
    id: root

    signal closed()
    signal exportRequested()

    property int currentTab: 0

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
        width: Math.min(parent.width - 32, 640)
        height: Math.min(parent.height - 32, 580)
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
                    text: "settings"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Notes Settings")
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }

                NotesIconButton {
                    symbol: "close"
                    tooltipText: Translation.tr("Close settings")
                    onTriggered: root.closed()
                }
            }

            // ── Tab Bar ───────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        { id: 0, name: Translation.tr("General"), icon: "tune" },
                        { id: 1, name: Translation.tr("Cloud & Backup"), icon: "cloud_sync" },
                        { id: 2, name: Translation.tr("Links & Media"), icon: "link" },
                        { id: 3, name: Translation.tr("Trash"), icon: "delete" }
                    ]

                    delegate: RippleButton {
                        id: tabBtn
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: 38
                        buttonRadius: Appearance.rounding.small
                        colBackground: root.currentTab === tabBtn.modelData.id
                            ? Appearance.colors.colSecondaryContainer
                            : Appearance.colors.colLayer2
                        colBackgroundHover: root.currentTab === tabBtn.modelData.id
                            ? Appearance.colors.colSecondaryContainerHover
                            : Appearance.colors.colLayer2Hover

                        onClicked: root.currentTab = tabBtn.modelData.id

                        contentItem: RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            MaterialSymbol {
                                text: tabBtn.modelData.icon
                                iconSize: 16
                                color: root.currentTab === tabBtn.modelData.id
                                    ? Appearance.colors.colPrimary
                                    : Appearance.colors.colSubtext
                            }

                            StyledText {
                                text: tabBtn.modelData.name
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: root.currentTab === tabBtn.modelData.id ? Font.DemiBold : Font.Normal
                                color: root.currentTab === tabBtn.modelData.id
                                    ? Appearance.colors.colOnLayer1
                                    : Appearance.colors.colSubtext
                            }
                        }
                    }
                }
            }

            // ── Tab Body ──────────────────────────────────────────────────
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.currentTab

                // ── Tab 0: General (Editor & Paper) ───────────────────────
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: 16

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: generalCol.implicitHeight + 24
                            radius: Appearance.rounding.normal
                            color: Appearance.colors.colLayer1

                            ColumnLayout {
                                id: generalCol
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    MaterialSymbol {
                                        text: "grid_on"
                                        iconSize: 20
                                        color: Appearance.colors.colPrimary
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: Translation.tr("Paper styling")
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        font.weight: Font.DemiBold
                                        color: Appearance.colors.colOnLayer1
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: Translation.tr("Notes feature 7 procedural paper styles (ruled, grid, isometric, dots, hexagons, séyès). Individual page styles can be adjusted directly from the header toolbar.")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: shortcutsCol.implicitHeight + 24
                            radius: Appearance.rounding.normal
                            color: Appearance.colors.colLayer1

                            ColumnLayout {
                                id: shortcutsCol
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    MaterialSymbol {
                                        text: "keyboard"
                                        iconSize: 20
                                        color: Appearance.colors.colPrimary
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: Translation.tr("Keyboard shortcuts")
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        font.weight: Font.DemiBold
                                        color: Appearance.colors.colOnLayer1
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: Translation.tr("• Ctrl+N: Create new note\n• Ctrl+F: Search notes\n• Esc: Back / Dismiss selection\n• Super+Shift+N: Toggle Notes app from anywhere")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }

                // ── Tab 1: Cloud & Backup ─────────────────────────────────
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: 16

                        // Google Drive Card
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: driveCol.implicitHeight + 24
                            radius: Appearance.rounding.normal
                            color: Appearance.colors.colLayer1

                            ColumnLayout {
                                id: driveCol
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    MaterialSymbol {
                                        text: "cloud_upload"
                                        iconSize: 22
                                        color: Appearance.colors.colPrimary
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        StyledText {
                                            text: Translation.tr("Google Drive Backup")
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                            font.weight: Font.DemiBold
                                            color: Appearance.colors.colOnLayer1
                                        }

                                        StyledText {
                                            text: Translation.tr("Include notes folder in automatic scheduled cloud backups")
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colSubtext
                                        }
                                    }

                                    Switch {
                                        checked: NotesSync.autoDrive
                                        onToggled: NotesSync.toggleDriveBackup()
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    RippleButton {
                                        implicitHeight: 36
                                        implicitWidth: 140
                                        buttonRadius: Appearance.rounding.small
                                        colBackground: Appearance.colors.colSecondaryContainer
                                        colBackgroundHover: Appearance.colors.colSecondaryContainerHover

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 6

                                            MaterialSymbol {
                                                text: "sync"
                                                iconSize: 16
                                                color: Appearance.colors.colPrimary
                                            }

                                            StyledText {
                                                text: Translation.tr("Sync now")
                                                font.pixelSize: Appearance.font.pixelSize.small
                                                font.weight: Font.DemiBold
                                                color: Appearance.colors.colOnLayer1
                                            }
                                        }

                                        onClicked: NotesSync.syncDriveNow()
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: NotesSync.driveEnabled
                                            ? Translation.tr("Drive backup active via rclone")
                                            : Translation.tr("Configure Google Drive in system settings first")
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colSubtext
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }
                        }

                        // Universal Export Card
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: exportCol.implicitHeight + 24
                            radius: Appearance.rounding.normal
                            color: Appearance.colors.colLayer1

                            ColumnLayout {
                                id: exportCol
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    MaterialSymbol {
                                        text: "file_export"
                                        iconSize: 20
                                        color: Appearance.colors.colPrimary
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: Translation.tr("Universal Export")
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        font.weight: Font.DemiBold
                                        color: Appearance.colors.colOnLayer1
                                    }

                                    RippleButton {
                                        implicitHeight: 34
                                        implicitWidth: 120
                                        buttonRadius: Appearance.rounding.small
                                        colBackground: Appearance.colors.colPrimary
                                        colBackgroundHover: Appearance.colors.colPrimaryHover

                                        StyledText {
                                            anchors.centerIn: parent
                                            text: Translation.tr("Export...")
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            font.weight: Font.DemiBold
                                            color: Appearance.colors.colOnPrimary
                                        }

                                        onClicked: {
                                            root.closed();
                                            root.exportRequested();
                                        }
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: Translation.tr("Export current note or entire store to Markdown, HTML, PDF or ZIP archive.")
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }

                // ── Tab 2: Links & Media ──────────────────────────────────
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: 16

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: linksCol.implicitHeight + 24
                            radius: Appearance.rounding.normal
                            color: Appearance.colors.colLayer1

                            ColumnLayout {
                                id: linksCol
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    MaterialSymbol {
                                        text: "link"
                                        iconSize: 22
                                        color: Appearance.colors.colPrimary
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        StyledText {
                                            text: Translation.tr("Web link previews")
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                            font.weight: Font.DemiBold
                                            color: Appearance.colors.colOnLayer1
                                        }

                                        StyledText {
                                            text: Translation.tr("Fetch metadata and thumbnails when pasting HTTP/HTTPS URLs")
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colSubtext
                                            wrapMode: Text.WordWrap
                                        }
                                    }

                                    Switch {
                                        checked: Persistent.ready ? (Persistent.states.notes?.linkPreviews ?? true) : true
                                        onToggled: {
                                            if (Persistent.ready && Persistent.states.notes)
                                                Persistent.states.notes.linkPreviews = checked;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Tab 3: Trash & Data ────────────────────────────────────
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: 16

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: trashCol.implicitHeight + 24
                            radius: Appearance.rounding.normal
                            color: Appearance.colors.colLayer1

                            ColumnLayout {
                                id: trashCol
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    MaterialSymbol {
                                        text: "delete_sweep"
                                        iconSize: 22
                                        color: Appearance.m3colors.m3error
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        StyledText {
                                            text: Translation.tr("Empty trash")
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                            font.weight: Font.DemiBold
                                            color: Appearance.colors.colOnLayer1
                                        }

                                        StyledText {
                                            text: Translation.tr("Permanently delete all notes currently in the trash")
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colSubtext
                                        }
                                    }

                                    RippleButton {
                                        implicitHeight: 34
                                        implicitWidth: 110
                                        buttonRadius: Appearance.rounding.small
                                        colBackground: Appearance.m3colors.m3errorContainer
                                        colBackgroundHover: Appearance.m3colors.m3error

                                        StyledText {
                                            anchors.centerIn: parent
                                            text: Translation.tr("Empty now")
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            font.weight: Font.DemiBold
                                            color: Appearance.m3colors.m3onErrorContainer
                                        }

                                        onClicked: {
                                            NotesService.purgeTrash();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
