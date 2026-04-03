import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    function formatTime(seconds) {
        var h = Math.floor(seconds / 3600);
        var m = Math.floor((seconds % 3600) / 60);
        if (h > 0)
            return `${h}h ${m}m`;
        else
            return `${m}m`;
    }

    readonly property bool hasTimeData: {
        let timeValue = Battery.isCharging ? Battery.timeToFull : Battery.timeToEmpty;
        let power = Battery.energyRate;
        return !(Battery.chargeState == 4 || timeValue <= 0 || power <= 0.01);
    }

    Row {
        id: mainRow
        anchors.centerIn: parent
        spacing: 16

        // ── Battery Level Section ──
        Column {
            id: levelSection
            width: 150
            spacing: 6

            // Header: icon + label
            Row {
                spacing: 6
                MaterialSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "battery_full"
                    iconSize: 18
                    fill: 1
                    color: Appearance.colors.colOnSurfaceVariant
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Translation.tr("Battery")
                    font.weight: Font.DemiBold
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }

            // Main percentage value
            StyledText {
                text: Math.floor(Battery.percentage * 100) + "%"
                font.pixelSize: 26
                font.weight: Font.Bold
                color: Appearance.colors.colOnLayer1
            }

            // Status subtitle
            StyledText {
                text: {
                    if (Battery.chargeState == 4)
                        return Translation.tr("Fully charged");
                    else if (Battery.isCharging)
                        return Translation.tr("Charging");
                    else
                        return Translation.tr("Discharging");
                }
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
            }

            // Percentage above bar
            StyledText {
                text: Math.floor(Battery.percentage * 100) + "%"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
            }

            // Progress bar
            StyledProgressBar {
                valueBarWidth: levelSection.width
                valueBarHeight: 6
                value: Battery.percentage
                highlightColor: {
                    if (Battery.percentage <= 0.15 && !Battery.isCharging)
                        return Appearance.m3colors.m3error;
                    else if (Battery.isCharging)
                        return Appearance.colors.colPrimary;
                    else
                        return Appearance.colors.colPrimary;
                }
                trackColor: Appearance.m3colors.m3secondaryContainer
            }
        }

        // Vertical separator
        Rectangle {
            width: 1
            height: levelSection.height
            color: Appearance.colors.colOnSurfaceVariant
            opacity: 0.2
            anchors.verticalCenter: parent.verticalCenter
        }

        // ── Details Section ──
        Column {
            id: detailsSection
            width: 160
            spacing: 8

            // Header: icon + label
            Row {
                spacing: 6
                MaterialSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "info"
                    iconSize: 18
                    fill: 1
                    color: Appearance.colors.colOnSurfaceVariant
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Translation.tr("Details")
                    font.weight: Font.DemiBold
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }

            // Detail rows
            Column {
                spacing: 10

                // Power row
                Row {
                    visible: !(Battery.chargeState != 4 && Battery.energyRate == 0)
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
                        text: {
                            if (Battery.chargeState == 4)
                                return Translation.tr("Power:") + " 0W";
                            else
                                return Translation.tr("Power:") + ` ${Battery.energyRate.toFixed(2)}W`;
                        }
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                    }
                }

                // Time row
                Row {
                    visible: root.hasTimeData
                    spacing: 8
                    MaterialSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "schedule"
                        iconSize: 20
                        fill: 1
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            if (Battery.isCharging)
                                return Translation.tr("Full in:") + " " + root.formatTime(Battery.timeToFull);
                            else
                                return Translation.tr("Left:") + " " + root.formatTime(Battery.timeToEmpty);
                        }
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                    }
                }

                // Health row
                Row {
                    spacing: 8
                    MaterialSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "heart_check"
                        iconSize: 20
                        fill: 1
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Translation.tr("Health:") + ` ${Battery.health.toFixed(1)}%`
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                    }
                }
            }
        }
    }
}
