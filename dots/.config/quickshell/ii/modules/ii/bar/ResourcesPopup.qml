import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "./cards"
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root
    popupRadius: Appearance.rounding.large

    readonly property int cardWidth: 150
    readonly property int cardHeight: 130
    readonly property int cardPadding: 14

    function formatKBValue(kb) {
        return (kb / (1024 * 1024)).toFixed(1);
    }

    function formatKBTotal(kb) {
        return "/" + (kb / (1024 * 1024)).toFixed(0) + "GB";
    }

    function formatBytesValue(bytes) {
        return (bytes / (1024 * 1024 * 1024)).toFixed(1);
    }

    function formatBytesTotal(bytes) {
        return "/" + (bytes / (1024 * 1024 * 1024)).toFixed(0) + "GB";
    }

    // Reusable card component (for RAM, Storage)
    component ResourceCard: Rectangle {
        id: card
        width: root.cardWidth
        height: root.cardHeight
        radius: Appearance.rounding.normal
        color: Appearance.colors.colPrimaryContainer

        property string icon: ""
        property string label: ""
        property string value: ""
        property string total: ""
        property real percentage: 0

        Column {
            anchors.fill: parent
            anchors.margins: root.cardPadding
            spacing: 6

            // Header: icon + label
            Row {
                spacing: 8
                Rectangle {
                    width: 20
                    height: 20
                    radius: Appearance.rounding.verysmall
                    color: Appearance.colors.colPrimary
                    anchors.verticalCenter: parent.verticalCenter

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: card.icon
                        iconSize: 12
                        fill: 1
                        color: Appearance.colors.colOnPrimary
                    }
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: card.label
                    font.weight: Font.DemiBold
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colPrimary
                }
            }

            // Value row: large value + total
            Row {
                spacing: 2
                anchors.left: parent.left

                StyledText {
                    id: valueText
                    text: card.value
                    font.pixelSize: Appearance.font.pixelSize.hugeass
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer2
                }
                StyledText {
                    text: card.total
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Normal
                    color: Appearance.colors.colOnSurfaceVariant
                    anchors.baseline: valueText.baseline
                }
            }

            // Percentage
            StyledText {
                text: Math.round(card.percentage * 100) + "%"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
            }

            // Progress bar - Material 3 style
            StyledProgressBar {
                valueBarWidth: parent.width
                valueBarHeight: 8
                value: card.percentage
                highlightColor: Appearance.colors.colPrimary
                trackColor: Appearance.m3colors.m3secondaryContainer
            }
        }
    }

    // Reusable stats card component (for CPU/GPU) — percentage + progress bar at bottom
    component StatsCard: Rectangle {
        id: statsCard
        width: root.cardWidth
        height: root.cardHeight
        radius: Appearance.rounding.normal
        color: Appearance.colors.colPrimaryContainer

        property string icon: ""
        property string label: ""
        property var stats: []
        property real loadPercentage: 0   // 0..1 for progress bar

        Column {
            anchors.fill: parent
            anchors.margins: root.cardPadding
            spacing: 6

            // Header: icon + label
            Row {
                spacing: 8
                Rectangle {
                    width: 20
                    height: 20
                    radius: Appearance.rounding.verysmall
                    color: Appearance.colors.colPrimary
                    anchors.verticalCenter: parent.verticalCenter

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: statsCard.icon
                        iconSize: 12
                        fill: 1
                        color: Appearance.colors.colOnPrimary
                    }
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: statsCard.label
                    font.weight: Font.DemiBold
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colPrimary
                }
            }

            // Stats rows (temp, freq/power — no load row)
            Column {
                spacing: 4
                Repeater {
                    model: statsCard.stats
                    Row {
                        spacing: 8
                        MaterialSymbol {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.icon
                            iconSize: 14
                            fill: 1
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.text
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnLayer2
                        }
                    }
                }
            }

            // Percentage label above progress bar
            StyledText {
                text: Math.round(statsCard.loadPercentage * 100) + "%"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
            }

            // Progress bar at bottom for load
            StyledProgressBar {
                valueBarWidth: parent.width
                valueBarHeight: 8
                value: statsCard.loadPercentage
                highlightColor: Appearance.colors.colPrimary
                trackColor: Appearance.m3colors.m3secondaryContainer
            }
        }
    }

    contentItem: ColumnLayout {
        anchors.centerIn: parent
        spacing: 12

        // Custom hero card for hardware info
        Rectangle {
            id: resourcesHero
            Layout.fillWidth: true
            implicitWidth: root.cardWidth * 2 + 12
            implicitHeight: heroRow.implicitHeight + 32
            radius: Appearance.rounding.normal
            color: Appearance.colors.colPrimaryContainer

            Row {
                id: heroRow
                anchors.centerIn: parent
                spacing: 16

                MaterialShape {
                    shapeString: "Cookie9Sided"
                    implicitSize: 80
                    color: Appearance.colors.colPrimary
                    anchors.verticalCenter: parent.verticalCenter

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "memory_alt"
                        iconSize: 36
                        color: Appearance.colors.colOnPrimary
                    }
                }

                Column {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.cardWidth * 2 + 12 - 80 - 16 - 32

                    StyledText {
                        text: ResourceUsage.cpuModel
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.family: Appearance.font.family.title
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnPrimaryContainer
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    StyledText {
                        text: ResourceUsage.gpuModel
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.family: Appearance.font.family.title
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnPrimaryContainer
                        opacity: 0.8
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }
            }
        }

        // Main grid layout 2x2
        Grid {
            id: mainGrid
            Layout.alignment: Qt.AlignHCenter
            columns: 2
            spacing: 12

            // RAM Card
            ResourceCard {
                icon: "memory"
                label: "RAM"
                value: root.formatKBValue(ResourceUsage.memoryUsed) + "GB"
                total: root.formatKBTotal(ResourceUsage.memoryTotal)
                percentage: ResourceUsage.memoryUsedPercentage
            }

            // Storage Card
            ResourceCard {
                icon: "hard_drive"
                label: Translation.tr("Storage")
                value: root.formatBytesValue(ResourceUsage.diskUsed) + "GB"
                total: root.formatBytesTotal(ResourceUsage.diskTotal)
                percentage: ResourceUsage.diskUsedPercentage
            }

            // CPU Card
            StatsCard {
                icon: "speed"
                label: "CPU"
                loadPercentage: ResourceUsage.cpuUsage
                stats: [
                    {
                        icon: "thermostat",
                        text: ResourceUsage.cpuTemp + "°C"
                    },
                    {
                        icon: "pace",
                        text: ResourceUsage.cpuFreqMhz + " MHz"
                    }
                ]
            }

            // GPU Card
            StatsCard {
                icon: "display_settings"
                label: "GPU"
                loadPercentage: ResourceUsage.gpuUsage
                stats: [
                    {
                        icon: "thermostat",
                        text: ResourceUsage.gpuTemp + "°C"
                    },
                    {
                        icon: "electric_bolt",
                        text: Math.round(ResourceUsage.gpuPowerW) + " W"
                    }
                ]
            }
        }
    }
}
