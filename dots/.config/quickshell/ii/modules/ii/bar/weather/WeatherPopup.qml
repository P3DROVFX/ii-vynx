import qs.services
import qs.modules.common
import qs.modules.common.widgets

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.modules.ii.bar

StyledPopup {
    id: root

    // Forecast data model
    property var forecastData: []
    property var hourlyData: []
    property bool forecastLoading: true
    property int maxHourlyBars: 5
    property var filteredHourlyData: {
        const now = new Date();
        const currentHr = now.getHours();
        // Round down to nearest 3-hour slot (API intervals: 0, 3, 6, 9, 12, 15, 18, 21)
        const currentSlot = Math.floor(currentHr / 3) * 3;
        let futureHours = [];
        let passedMidnight = false;
        
        for (let i = 0; i < hourlyData.length; i++) {
            const item = hourlyData[i];
            const itemHour = Math.floor(parseInt(item.time) / 100);
            
            if (i > 0 && itemHour < Math.floor(parseInt(hourlyData[i-1].time) / 100)) {
                passedMidnight = true;
            }
            
            if (passedMidnight || itemHour >= currentSlot) {
                futureHours.push(item);
            }
        }
        return futureHours.slice(0, maxHourlyBars);
    }

    function fetchForecast() {
        forecastLoading = true;
        let city = Config.options.bar.weather.city || "auto";
        city = city.trim().split(/\s+/).join('+');
        // Fetch hourly data from today and tomorrow to ensure we have enough hours
        forecastFetcher.command[2] = `curl -s "wttr.in/${city}?format=j1" | jq '{daily: [.weather[] | {date: .date, maxC: .maxtempC, minC: .mintempC, maxF: .maxtempF, minF: .mintempF, code: .hourly[4].weatherCode}], hourly: [.weather[0].hourly[], .weather[1].hourly[] | {time: .time, tempC: .tempC, tempF: .tempF, code: .weatherCode}]}'`;
        forecastFetcher.running = true;
    }

    function getDayName(dateStr, index) {
        if (index === 0) return Translation.tr("Today");
        if (index === 1) return Translation.tr("Tomorrow");
        const date = new Date(dateStr);
        const days = [
            Translation.tr("Sun"), Translation.tr("Mon"), Translation.tr("Tue"),
            Translation.tr("Wed"), Translation.tr("Thu"), Translation.tr("Fri"), Translation.tr("Sat")
        ];
        return days[date.getDay()];
    }

    function formatHour(timeStr) {
        const hour = Math.floor(parseInt(timeStr) / 100);
        return hour.toString().padStart(2, '0') + ":00";
    }

    function getHourlyTempRange() {
        const data = filteredHourlyData.length > 0 ? filteredHourlyData : hourlyData;
        if (data.length === 0) return { min: 0, max: 100 };
        const temps = data.map(h => Weather.useUSCS ? parseInt(h.tempF) : parseInt(h.tempC));
        const min = Math.min(...temps);
        const max = Math.max(...temps);
        // Add 20% padding (minimum 2°) to make small differences more visible
        // e.g., temps 20-21 become range 18-23, making 1° difference span ~20% of bar height
        const padding = Math.max(2, (max - min) * 0.2);
        return { min: min - padding, max: max + padding };
    }

    Component.onCompleted: fetchForecast()

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16

        Item {
            width: 0
            height: 0
            visible: false
            
            Process {
                id: forecastFetcher
                command: ["bash", "-c", ""]
                stdout: StdioCollector {
                    onStreamFinished: {
                        if (text.length === 0) {
                            root.forecastLoading = false;
                            return;
                        }
                        try {
                            const data = JSON.parse(text);
                            root.forecastData = data.daily || [];
                            root.hourlyData = data.hourly || [];
                        } catch (e) {
                            console.error(`[WeatherPopup] Forecast parse error: ${e.message}`);
                        }
                        root.forecastLoading = false;
                    }
                }
            }
        }

        // hero card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: heroRow.implicitHeight + 48
            Layout.minimumWidth: 360
            color: Appearance.colors.colPrimaryContainer
            radius: Appearance.rounding.normal

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
                }

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
                        color: Appearance.colors.colOnPrimaryContainer
                        Layout.alignment: Qt.AlignRight
                    }

                    StyledText {
                        text: Weather.data.wDesc || "--"
                        font.weight: Font.DemiBold
                        font.pixelSize: Appearance.font.pixelSize.large
                        color: Appearance.colors.colOnPrimaryContainer
                        Layout.alignment: Qt.AlignRight
                    }

                    StyledText {
                        text: Translation.tr("Feels like %1").arg(Weather.data.tempFeelsLike || "--")
                        font.italic: true
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnPrimaryContainer
                        Layout.alignment: Qt.AlignRight
                        Layout.topMargin: 4
                    }
                }
            }
        }

        // divider line
        Rectangle {
            Layout.fillWidth: true
            height: 2
            color: Appearance.colors.colSurfaceContainerHighest
            radius: 1
        }

        // hourly forecast chart
        // Bar height calculation: (dont know how it works but it does)
        //   normalized = (temp - rangeMin) / rangeSpan  -> value between 0 and 1
        //   barHeight = 50 + normalized * 90            -> height between 50px and 140px
        Rectangle {
            Layout.fillWidth: true
            Layout.minimumWidth: 360
            implicitHeight: hourlyColumn.implicitHeight + 24
            color: Appearance.colors.colSurfaceContainerHigh
            radius: Appearance.rounding.normal

            ColumnLayout {
                id: hourlyColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    MaterialShape {
                        shapeString: "Clover4Leaf"
                        implicitSize: 36
                        color: Appearance.colors.colPrimaryContainer

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "schedule"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Hourly")
                        font.family: Appearance.font.family.title
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnSurface
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        text: Translation.tr("Last refresh: %1").arg(Weather.data.lastRefresh || "--").slice(0, 20)
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }

                // Bar chart
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 160
                    visible: !root.forecastLoading && root.filteredHourlyData.length > 0

                    property var tempRange: root.getHourlyTempRange()
                    property real tempSpan: Math.max(tempRange.max - tempRange.min, 1)

                    RowLayout {
                        anchors.fill: parent
                        spacing: 6

                        Repeater {
                            model: root.filteredHourlyData

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                required property var modelData
                                required property int index

                                property int hourValue: Math.floor(parseInt(modelData.time) / 100)
                                // First bar is always the current/closest time slot
                                property bool isCurrentHour: index === 0
                                property real temp: Weather.useUSCS ? parseInt(modelData.tempF) : parseInt(modelData.tempC)
                                property var parentTempRange: root.getHourlyTempRange()
                                property real parentTempSpan: Math.max(parentTempRange.max - parentTempRange.min, 1)
                                // Normalize temp to 0-1 range based on visible data min/max
                                property real normalized: (temp - parentTempRange.min) / parentTempSpan
                                // Bar height: 50px (coldest) to 140px (hottest)
                                property real barHeight: 50 + normalized * 90

                                // Bar container
                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 4

                                    // Spacer to push bar down based on temp
                                    Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: barHeight
                                        Layout.maximumHeight: 130
                                        radius: Appearance.rounding.normal
                                        color: isCurrentHour ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSecondaryContainer

                                        ColumnLayout {
                                            anchors.top: parent.top
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.topMargin: 8
                                            spacing: 2

                                            MaterialSymbol {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: Icons.getWeatherIcon(modelData.code)
                                                iconSize: Appearance.font.pixelSize.large
                                                color: isCurrentHour ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSecondaryContainer
                                            }

                                            StyledText {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: temp + "°"
                                                font.pixelSize: Appearance.font.pixelSize.normal
                                                font.weight: Font.Bold
                                                color: isCurrentHour ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSecondaryContainer
                                            }
                                        }

                                        // Highlight indicator for current hour
                                        Rectangle {
                                            visible: isCurrentHour
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 6
                                            width: 20
                                            height: 20
                                            radius: 10
                                            color: Appearance.colors.colPrimary

                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: 8
                                                height: 8
                                                radius: 4
                                                color: Appearance.colors.colOnPrimary
                                            }
                                        }
                                    }

                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: root.formatHour(modelData.time)
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        font.weight: isCurrentHour ? Font.Bold : Font.Normal
                                        color: isCurrentHour ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
                                    }
                                }
                            }
                        }
                    }
                }

                // Loading placeholder
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 160
                    visible: root.forecastLoading || root.filteredHourlyData.length === 0
                    color: "transparent"
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        MaterialLoadingIndicator {
                            Layout.alignment: Qt.AlignHCenter
                            loading: root.forecastLoading
                            visible: root.forecastLoading
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.forecastLoading ? Translation.tr("Loading forecast...") : Translation.tr("No forecast data")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }
                }
            }
        }

        // metrics grid
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
                title: Translation.tr("Precipitation")
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

        // 3-day forecast
        // May differ from Hero (real-time) and Hourly (3-hour interval forecasts), need check if its API data
        Rectangle {
            Layout.fillWidth: true
            Layout.minimumWidth: 360
            implicitHeight: forecastColumn.implicitHeight + 32
            color: Appearance.colors.colSurfaceContainerHigh
            radius: Appearance.rounding.normal

            ColumnLayout {
                id: forecastColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 12

                // Section Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    MaterialShape {
                        shapeString: "Cookie6Sided"
                        implicitSize: 36
                        color: Appearance.colors.colSecondaryContainer

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "calendar_month"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnSecondaryContainer
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Forecast")
                        font.family: Appearance.font.family.title
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnSurface
                    }
                }

                // Forecast Days Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: !root.forecastLoading && root.forecastData.length > 0

                    Repeater {
                        model: root.forecastData

                        Rectangle {
                            id: dayCard
                            Layout.fillWidth: true
                            Layout.preferredHeight: 140
                            radius: Appearance.rounding.normal
                            
                            // tried a gradient-like effect, but dont know if i should switch secondary and tertiary colors
                            color: {
                                const colors = [
                                    Appearance.colors.colPrimaryContainer,
                                    Appearance.colors.colSecondaryContainer,
                                    Appearance.colors.colTertiaryContainer
                                ];
                                return colors[index % 3];
                            }

                            property color textColor: {
                                const colors = [
                                    Appearance.colors.colOnPrimaryContainer,
                                    Appearance.colors.colOnSecondaryContainer,
                                    Appearance.colors.colOnTertiaryContainer
                                ];
                                return colors[index % 3];
                            }

                            ColumnLayout {
                                id: dayColumn
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: root.getDayName(modelData.date, index)
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.weight: Font.Bold
                                    color: dayCard.textColor
                                }

                                // Weather shape
                                MaterialShape {
                                    Layout.alignment: Qt.AlignHCenter
                                    shapeString: index === 0 ? "Cookie9Sided" : (index === 1 ? "Flower" : "Clover4Leaf")
                                    implicitSize: 52
                                    color: Qt.rgba(dayCard.textColor.r, dayCard.textColor.g, dayCard.textColor.b, 0.15)

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: Icons.getWeatherIcon(modelData.code)
                                        iconSize: Appearance.font.pixelSize.large * 1.2
                                        color: dayCard.textColor
                                    }
                                }

                                ColumnLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 0

                                    // Max temp
                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: Weather.useUSCS ? modelData.maxF + "°" : modelData.maxC + "°"
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        font.weight: Font.Bold
                                        color: dayCard.textColor
                                    }

                                    // Min temp
                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: Weather.useUSCS ? modelData.minF + "°" : modelData.minC + "°"
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        font.weight: Font.DemiBold
                                        color: Qt.rgba(dayCard.textColor.r, dayCard.textColor.g, dayCard.textColor.b, 0.7)
                                    }
                                }
                            }
                        }
                    }
                }

                // Loading placeholder
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 140
                    visible: root.forecastLoading || root.forecastData.length === 0
                    color: "transparent"
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        MaterialLoadingIndicator {
                            Layout.alignment: Qt.AlignHCenter
                            loading: root.forecastLoading
                            visible: root.forecastLoading
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.forecastLoading ? Translation.tr("Loading forecast...") : Translation.tr("No forecast data")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }
                }
            }
        }
    }
}
