import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    // Helper function to format KB to GB
    function formatKB(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    function formatBytes(bytes) {
        return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GB";
    }

    Row {
        id: mainRow
        anchors.centerIn: parent
        spacing: 16

        // ── RAM Section ──
        Column {
            id: ramSection
            width: 150
            spacing: 6

            // Header: icon + label
            Row {
                spacing: 6
                MaterialSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "memory"
                    iconSize: 18
                    fill: 1
                    color: Appearance.colors.colOnSurfaceVariant
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "RAM"
                    font.weight: Font.DemiBold
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }

            // Large value: used
            StyledText {
                text: root.formatKB(ResourceUsage.memoryUsed)
                font.pixelSize: 26
                font.weight: Font.Bold
                color: Appearance.colors.colOnLayer1
            }

            // Subtitle: total
            StyledText {
                text: "/ " + root.formatKB(ResourceUsage.memoryTotal)
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
            }

            // Percentage above bar
            StyledText {
                text: Math.round(ResourceUsage.memoryUsedPercentage * 100) + "%"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
            }

            // Progress bar
            StyledProgressBar {
                valueBarWidth: ramSection.width
                valueBarHeight: 6
                value: ResourceUsage.memoryUsedPercentage
                highlightColor: Appearance.colors.colPrimary
                trackColor: Appearance.m3colors.m3secondaryContainer
            }
        }

        // Vertical separator
        Rectangle {
            width: 1
            height: ramSection.height
            color: Appearance.colors.colOnSurfaceVariant
            opacity: 0.2
            anchors.verticalCenter: parent.verticalCenter
        }

        // ── Storage Section ──
        Column {
            id: storageSection
            width: 140
            spacing: 6

            // Header: icon + label
            Row {
                spacing: 6
                MaterialSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "hard_drive"
                    iconSize: 18
                    fill: 1
                    color: Appearance.colors.colOnSurfaceVariant
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Translation.tr("Storage")
                    font.weight: Font.DemiBold
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }

            // Large value: used
            StyledText {
                text: root.formatBytes(ResourceUsage.diskUsed)
                font.pixelSize: 26
                font.weight: Font.Bold
                color: Appearance.colors.colOnLayer1
            }

            // Subtitle: total
            StyledText {
                text: "/ " + root.formatBytes(ResourceUsage.diskTotal)
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
            }

            // Percentage above bar
            StyledText {
                text: Math.round(ResourceUsage.diskUsedPercentage * 100) + "%"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
            }

            // Progress bar
            StyledProgressBar {
                valueBarWidth: storageSection.width
                valueBarHeight: 6
                value: ResourceUsage.diskUsedPercentage
                highlightColor: Appearance.colors.colPrimary
                trackColor: Appearance.m3colors.m3secondaryContainer
            }
        }

        // Vertical separator
        Rectangle {
            width: 1
            height: ramSection.height
            color: Appearance.colors.colOnSurfaceVariant
            opacity: 0.2
            anchors.verticalCenter: parent.verticalCenter
        }

        // ── CPU Section ──
        Column {
            id: cpuSection
            width: 150
            spacing: 8

            // Header: icon + label
            Row {
                spacing: 6
                MaterialSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "speed"
                    iconSize: 18
                    fill: 1
                    color: Appearance.colors.colOnSurfaceVariant
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "CPU"
                    font.weight: Font.DemiBold
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }

            // CPU stats rows
            Column {
                spacing: 10

                // Load row
                Row {
                    spacing: 8
                    MaterialSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "bolt"
                        iconSize: 20
                        fill: 1
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Translation.tr("Load:") + " " + Math.round(ResourceUsage.cpuUsage * 100) + "%"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                    }
                }

                // Temp row
                Row {
                    spacing: 8
                    MaterialSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "thermostat"
                        iconSize: 20
                        fill: 1
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Translation.tr("Temp:") + " " + ResourceUsage.cpuTemp + "°C"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                    }
                }

                // Clock row
                Row {
                    spacing: 8
                    MaterialSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "timer"
                        iconSize: 20
                        fill: 1
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Translation.tr("Clock:") + " " + ResourceUsage.cpuFreqMhz + " MHz"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                    }
                }
            }
        }

        // Vertical separator (before GPU)
        Rectangle {
            width: 1
            height: ramSection.height
            color: Appearance.colors.colOnSurfaceVariant
            opacity: 0.2
            anchors.verticalCenter: parent.verticalCenter
        }

        // ── GPU Section ──
        Column {
            id: gpuSection
            width: 150
            spacing: 8

            // Header: icon + label
            Row {
                spacing: 6
                MaterialSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "video_settings"
                    iconSize: 18
                    fill: 1
                    color: Appearance.colors.colOnSurfaceVariant
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "GPU"
                    font.weight: Font.DemiBold
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }

            // GPU stats rows
            Column {
                spacing: 10

                // Load row
                Row {
                    spacing: 8
                    MaterialSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "bolt"
                        iconSize: 20
                        fill: 1
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Translation.tr("Load:") + " " + ResourceUsage.gpuUsage + "%"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                    }
                }

                // Power row
                Row {
                    spacing: 8
                    MaterialSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "flash_on"
                        iconSize: 20
                        fill: 1
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Translation.tr("Power:") + " " + Math.round(ResourceUsage.gpuPowerW) + " W"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                    }
                }

                // Temp row
                Row {
                    spacing: 8
                    MaterialSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "thermostat"
                        iconSize: 20
                        fill: 1
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Translation.tr("Temp:") + " " + ResourceUsage.gpuTemp + "°C"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                    }
                }
            }
        }
    }
}
