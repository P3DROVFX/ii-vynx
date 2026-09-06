pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.notes
import qs.modules.ii.usage

/**
 * Global statistics and writing analytics sheet for the Notes app.
 *
 * Visualizes total notes, word volume, estimated reading duration,
 * notebook distribution charts, and weekly activity heatmaps.
 */
Item {
    id: root

    signal closed()

    readonly property var allNotes: Array.from(NotesService.notes ?? [])
    readonly property var allNotebooks: Array.from(NotesService.notebooks ?? [])
    readonly property var allTrash: Array.from(NotesService.trash ?? [])

    readonly property int totalNotes: root.allNotes.length
    readonly property int totalTrash: root.allTrash.length
    readonly property int totalNotebooks: root.allNotebooks.length

    readonly property int totalFavorites: {
        let count = 0;
        for (let i = 0; i < root.allNotes.length; i++) {
            if (root.allNotes[i].isFavorite) count++;
        }
        return count;
    }

    readonly property int totalWords: {
        let count = 0;
        for (let i = 0; i < root.allNotes.length; i++) {
            count += Number(root.allNotes[i].words || 0);
        }
        return count;
    }

    readonly property int totalChars: {
        let count = 0;
        for (let i = 0; i < root.allNotes.length; i++) {
            count += Number(root.allNotes[i].characters || 0);
        }
        return count;
    }

    readonly property int estReadingMinutes: Math.ceil(root.totalWords / 200)

    // Distribution by notebook for UsageColumnChart
    readonly property list<string> chartLabels: {
        const labels = [];
        for (let i = 0; i < root.allNotebooks.length; i++) {
            labels.push(root.allNotebooks[i].name || Translation.tr("Notebook"));
        }
        if (labels.length === 0)
            labels.push(Translation.tr("Default"));
        return labels;
    }

    readonly property list<real> chartValues: {
        const counts = [];
        if (root.allNotebooks.length === 0) {
            counts.push(root.totalNotes);
            return counts;
        }
        for (let i = 0; i < root.allNotebooks.length; i++) {
            const nbId = root.allNotebooks[i].id;
            let n = 0;
            for (let j = 0; j < root.allNotes.length; j++) {
                if (root.allNotes[j].notebookId === nbId)
                    n++;
            }
            counts.push(n);
        }
        return counts;
    }

    // Heatmap cells (6 weeks * 7 days = 42 cells)
    readonly property list<var> heatmapCells: {
        const cells = [];
        const now = new Date();
        const dateMap = {};

        for (let i = 0; i < root.allNotes.length; i++) {
            const m = root.allNotes[i].modified;
            if (m) {
                const dayKey = new Date(m).toISOString().slice(0, 10);
                dateMap[dayKey] = (dateMap[dayKey] || 0) + 1;
            }
        }

        // Generate past 42 days backwards to align with 6 weeks
        for (let d = 41; d >= 0; d--) {
            const target = new Date(now.getTime() - d * 86400000);
            const key = target.toISOString().slice(0, 10);
            const val = dateMap[key] || 0;
            cells.push({
                date: key,
                value: val,
                label: `${key}: ${val} ${Translation.tr("notes modified")}`
            });
        }
        return cells;
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
        width: Math.min(parent.width - 32, 800)
        height: Math.min(parent.height - 32, 620)
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
                    text: "analytics"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Notes Analytics & Statistics")
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

            // ── KPI Metrics Row ───────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Total Notes
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 70
                    radius: Appearance.rounding.medium
                    color: Appearance.colors.colLayer1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 2

                        StyledText {
                            text: Translation.tr("Total Notes")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }

                        StyledText {
                            text: String(root.totalNotes)
                            font.pixelSize: Appearance.font.pixelSize.larger
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colPrimary
                        }
                    }
                }

                // Total Words
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 70
                    radius: Appearance.rounding.medium
                    color: Appearance.colors.colLayer1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 2

                        StyledText {
                            text: Translation.tr("Words Written")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }

                        StyledText {
                            text: String(root.totalWords)
                            font.pixelSize: Appearance.font.pixelSize.larger
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colSecondary
                        }
                    }
                }

                // Reading Time
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 70
                    radius: Appearance.rounding.medium
                    color: Appearance.colors.colLayer1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 2

                        StyledText {
                            text: Translation.tr("Reading Time")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }

                        StyledText {
                            text: Translation.tr("~%1 min").arg(root.estReadingMinutes)
                            font.pixelSize: Appearance.font.pixelSize.larger
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colTertiary
                        }
                    }
                }

                // Notebooks & Favorites
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 70
                    radius: Appearance.rounding.medium
                    color: Appearance.colors.colLayer1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 2

                        StyledText {
                            text: Translation.tr("Notebooks / Favs")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }

                        StyledText {
                            text: `${root.totalNotebooks} / ${root.totalFavorites}`
                            font.pixelSize: Appearance.font.pixelSize.larger
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                }
            }

            // ── Analytics Charts ──────────────────────────────────────────
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: 14

                    // Section 1: Notebook Distribution Chart
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 210
                        radius: Appearance.rounding.medium
                        color: Appearance.colors.colLayer1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            StyledText {
                                text: Translation.tr("Notes per Notebook")
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colOnLayer1
                            }

                            UsageColumnChart {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                values: root.chartValues
                                labels: root.chartLabels
                                barColor: Appearance.colors.colPrimary
                            }
                        }
                    }

                    // Section 2: Activity Heatmap
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 180
                        radius: Appearance.rounding.medium
                        color: Appearance.colors.colLayer1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            StyledText {
                                text: Translation.tr("Recent Activity Heatmap (6 Weeks)")
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colOnLayer1
                            }

                            UsageActivityHeatmap {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                cells: root.heatmapCells
                                weekCount: 6
                                dayCount: 7
                                activeColor: Appearance.colors.colPrimary
                            }
                        }
                    }
                }
            }

            // ── Footer ────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item { Layout.fillWidth: true }

                RippleButton {
                    implicitHeight: 38
                    implicitWidth: 110
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    onClicked: root.closed()

                    contentItem: StyledText {
                        anchors.centerIn: parent
                        text: Translation.tr("Close")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnPrimary
                    }
                }
            }
        }
    }
}
