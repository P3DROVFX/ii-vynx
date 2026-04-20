import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import qs
import qs.modules.common.functions as CF
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell
import "./wifi"

// WiFi Settings Page — Material 3 Expressive Redesign
ColumnLayout {
    id: page
    spacing: 30
    width: parent ? parent.width : implicitWidth

    property var filteredNetworks: {
        let nets = Network.friendlyWifiNetworks || []
        if (searchField.text && searchField.text.length > 0) {
            const q = searchField.text.toLowerCase()
            nets = nets.filter(function(n) {
                return n ? n.ssid.toLowerCase().includes(q) : false
            })
        }
        if (filterChips.currentFilter === "secured") {
            nets = nets.filter(function(n) { return n ? n.isSecure : false })
        } else if (filterChips.currentFilter === "open") {
            nets = nets.filter(function(n) { return n ? !n.isSecure : false })
        }
        return nets
    }

    Component.onCompleted: {
        if (Network.wifiEnabled)
            NetworkSpeed.start()
    }
    Component.onDestruction: {
        NetworkSpeed.stop()
    }
    Connections {
        target: Network
        function onWifiEnabledChanged() {
            if (Network.wifiEnabled)
                NetworkSpeed.start()
            else
                NetworkSpeed.stop()
        }
    }

    // ═══ Seção 1: Wi-Fi Toggle ═══
    ContentSection {
        icon: "wifi"
        title: Translation.tr("Wi-Fi")

        WifiToggleCard {
            Layout.fillWidth: true
            onToggled: function(enabled) {
                Network.enableWifi(enabled)
                if (enabled)
                    NetworkSpeed.start()
                else
                    NetworkSpeed.stop()
            }
        }

        // Speed gauges
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            visible: Network.wifiEnabled && (Network.active !== null)
            opacity: visible ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                }
            }

            SpeedGauge {
                Layout.fillWidth: true
                label: Translation.tr("Download")
                iconName: "download"
                value: NetworkSpeed.downloadSpeed
                maxValue: Math.max(NetworkSpeed.maxSpeed, 1)
                accentColor: Appearance.colors.colPrimary
            }
            SpeedGauge {
                Layout.fillWidth: true
                label: Translation.tr("Upload")
                iconName: "upload"
                value: NetworkSpeed.uploadSpeed
                maxValue: Math.max(NetworkSpeed.maxSpeed, 1)
                accentColor: Appearance.colors.colTertiary
            }
        }
    }

    // ═══ Seção 2: Available Networks ═══
    ContentSection {
        icon: "wifi_find"
        title: Translation.tr("Available Networks")
        visible: Network.wifiEnabled

        // Scan button inline with section header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40
                radius: Appearance.rounding.full
                color: scanArea.containsMouse ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1Base
                Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    MaterialSymbol {
                        text: Network.wifiScanning ? "autorenew" : "refresh"
                        iconSize: 20
                        color: Appearance.colors.colOnLayer1

                        RotationAnimation on rotation {
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                            running: Network.wifiScanning
                        }
                    }

                    StyledText {
                        text: Network.wifiScanning ? Translation.tr("Scanning...") : Translation.tr("Scan")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }

                MouseArea {
                    id: scanArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Network.rescanWifi()
                }
            }
        }

        WifiSearchField {
            id: searchField
            Layout.fillWidth: true
        }

        WifiFilterChips {
            id: filterChips
        }

        // Network list
        Rectangle {
            Layout.fillWidth: true
            visible: page.filteredNetworks.length > 0
            implicitHeight: networkListCol.implicitHeight + 12
            radius: Appearance.rounding.large
            color: Appearance.colors.colLayer1Base

            ColumnLayout {
                id: networkListCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 6
                }
                spacing: 2

                Repeater {
                    model: ScriptModel { values: page.filteredNetworks }
                    delegate: WifiNetworkCard {
                        Layout.fillWidth: true
                        onConnectRequested: function(ap) {
                            if (ap && ap.isSecure) {
                                connectionDialog.targetNetwork = ap
                                connectionDialog.show = true
                            } else if (ap) {
                                Network.connectToWifiNetwork(ap)
                            }
                        }
                        onDisconnectRequested: {
                            Network.disconnectWifiNetwork()
                        }
                    }
                }
            }
        }

        // Empty state
        ColumnLayout {
            visible: page.filteredNetworks.length === 0 && !Network.wifiScanning
            Layout.fillWidth: true
            spacing: 8
            Layout.topMargin: 20
            Layout.bottomMargin: 20

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: "wifi_find"
                iconSize: 48
                color: Appearance.colors.colSubtext
                opacity: 0.5
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("No networks found")
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
            }
        }
    }

    // ═══ Seção 3: Connection Details ═══
    ContentSection {
        icon: "info"
        title: Translation.tr("Connection Details")
        visible: Network.wifiEnabled && (Network.active !== null)

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: detailsCol.implicitHeight + 40
            radius: Appearance.rounding.large
            color: Appearance.colors.colLayer1Base

            ColumnLayout {
                id: detailsCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 20
                }
                spacing: 14

                Repeater {
                    model: [
                        { label: Translation.tr("IP Address"), value: Network.ipAddress || "—" },
                        { label: Translation.tr("Gateway"), value: Network.gateway || "—" },
                        { label: Translation.tr("DNS"), value: Network.dns || "—" },
                        { label: Translation.tr("Subnet Mask"), value: Network.subnetMask || "—" }
                    ]

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        required property var modelData

                        RowLayout {
                            Layout.fillWidth: true
                            StyledText {
                                text: modelData.label
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                            Item { Layout.fillWidth: true }
                            StyledText {
                                text: modelData.value
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 1
                            color: Appearance.m3colors.m3outlineVariant
                            opacity: 0.5
                            Layout.topMargin: 10
                        }
                    }
                }
            }
        }
    }

    // Dialog overlay — fora do layout flow
    Item {
        Layout.preferredWidth: 0
        Layout.preferredHeight: 0
        WifiConnectionDialog {
            id: connectionDialog
            parent: Overlay.overlay ? Overlay.overlay : page
            anchors.fill: parent
            z: 100
            onConnectRequested: function(password) {
                if (connectionDialog.targetNetwork) {
                    if (password === "" && Network.savedSsids.includes(connectionDialog.targetNetwork.ssid)) {
                        Network.connectToWifiNetwork(connectionDialog.targetNetwork);
                    } else {
                        Network.connectWithPassword(
                            connectionDialog.targetNetwork.ssid,
                            password, "", false
                        );
                    }
                }
            }
            onDismissed: {
                connectionDialog.show = false
                connectionDialog.targetNetwork = null
            }
        }
    }
}
