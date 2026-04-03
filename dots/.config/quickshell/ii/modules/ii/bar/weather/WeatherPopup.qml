import qs.services
import qs.modules.common
import qs.modules.common.widgets

import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar

StyledPopup {
    id: root

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16

        // Big Hero Card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: heroRow.implicitHeight + 48
            Layout.minimumWidth: 360
            color: Appearance.colors.colPrimaryContainer
            radius: Appearance.rounding.large

            RowLayout {
                id: heroRow
                anchors.fill: parent
                anchors.margins: 24
                spacing: 20

                MaterialShape {
                    shapeString: "Cookie9Sided"
                    implicitSize: 110
                    color: Appearance.colors.colPrimary

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: Icons.getWeatherIcon(Weather.data.wCode)
                        iconSize: Appearance.font.pixelSize.hugeass * 1.5
                        color: Appearance.colors.colOnPrimary
                    }
                }

                Item {
                    Layout.fillWidth: true
                } // Spacer

                // Typography Column
                ColumnLayout {
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    Layout.fillWidth: true
                    spacing: -2

                    // City Pill
                    Rectangle {
                        Layout.alignment: Qt.AlignRight
                        implicitHeight: cityRow.implicitHeight + 12
                        implicitWidth: cityRow.implicitWidth + 20
                        radius: 100
                        color: Appearance.colors.colSecondaryContainer

                        RowLayout {
                            id: cityRow
                            anchors.centerIn: parent
                            spacing: 6

                            MaterialSymbol {
                                text: "location_on"
                                iconSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                            StyledText {
                                text: Weather.data.city || "--"
                                font.weight: Font.Bold
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnSecondaryContainer
                                elide: Text.ElideRight
                                Layout.maximumWidth: 120
                            }
                        }
                    }

                    StyledText {
                        text: Weather.data.temp
                        font.family: Appearance.font.family.title
                        font.weight: Font.Black
                        font.pixelSize: Appearance.font.pixelSize.hugeass * 2.5
                        color: Appearance.colors.colOnSurface
                        Layout.alignment: Qt.AlignRight
                    }

                    StyledText {
                        text: Weather.data.wDesc || "--"
                        font.weight: Font.DemiBold
                        font.pixelSize: Appearance.font.pixelSize.large
                        color: Appearance.colors.colOnSurface
                        Layout.alignment: Qt.AlignRight
                    }

                    StyledText {
                        text: Translation.tr("Feels like %1").arg(Weather.data.tempFeelsLike || "--")
                        font.italic: true
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnSurface
                        Layout.alignment: Qt.AlignRight
                        Layout.topMargin: 4
                    }
                }
            }
        }

        // Animated Divider (just a styled line)
        Rectangle {
            Layout.fillWidth: true
            height: 2
            color: Appearance.colors.colSurfaceContainerHighest
            radius: 1
        }

        // Expressive Metrics Grid
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 12
            columnSpacing: 12
            uniformCellWidths: true

            WeatherCard {
                title: Translation.tr("UV Index")
                symbol: "wb_sunny"
                value: Weather.data.uv
                accentColor: Appearance.colors.colTertiaryContainer
                onAccentColor: Appearance.colors.colOnTertiaryContainer
            }
            WeatherCard {
                title: Translation.tr("Wind")
                symbol: "air"
                value: `(${Weather.data.windDir}) ${Weather.data.wind}`
                accentColor: Appearance.colors.colSecondaryContainer
                onAccentColor: Appearance.colors.colOnSecondaryContainer
            }
            WeatherCard {
                title: Translation.tr("Rainfall")
                symbol: "rainy_light"
                value: Weather.data.precip
                accentColor: Appearance.colors.colPrimaryContainer
                onAccentColor: Appearance.colors.colOnPrimaryContainer
            }
            WeatherCard {
                title: Translation.tr("Humidity")
                symbol: "humidity_low"
                value: Weather.data.humidity
                accentColor: Appearance.colors.colTertiaryContainer
                onAccentColor: Appearance.colors.colOnTertiaryContainer
            }
        }
    }
}
