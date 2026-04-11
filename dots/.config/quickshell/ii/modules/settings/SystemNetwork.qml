import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common.functions as CF
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell

ColumnLayout {
    id: page
    spacing: 30
    width: parent ? parent.width : implicitWidth

    ContentSection {
        icon: "wifi"
        title: Translation.tr("Wi-Fi")

        ConfigRow {
            ConfigSwitch {
                buttonIcon: Network.wifiEnabled ? "wifi" : "wifi_off"
                text: Translation.tr("Enable Wi-Fi")
                checked: Network.wifiEnabled
                onCheckedChanged: Network.enableWifi(checked)
            }
        }

        ConfigRow {
            uniform: true
            RippleButtonWithIcon {
                Layout.fillWidth: true
                buttonRadius: Appearance.rounding.full
                materialIcon: "refresh"
                mainText: Translation.tr("Refresh Networks")
                onClicked: Network.rescanWifi()
                
                MaterialSymbol {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "autorenew"
                    iconSize: 20
                    color: Appearance.colors.colOnLayer1
                    visible: Network.wifiScanning
                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: Network.wifiScanning
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Available Networks")
            visible: Network.wifiEnabled && Network.friendlyWifiNetworks.length > 0
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Repeater {
                    model: Network.friendlyWifiNetworks
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: networkCol.implicitHeight
                        color: {
                            if (modelData.active) return CF.ColorUtils.mix(Appearance.colors.colLayer1Base, Appearance.colors.colPrimary, 0.85);
                            return Appearance.colors.colLayer1Base;
                        }
                        radius: 12

                        property bool expanded: modelData.askingPassword

                        ColumnLayout {
                            id: networkCol
                            width: parent.width
                            spacing: 0

                            RippleButton {
                                Layout.fillWidth: true
                                implicitHeight: 60
                                buttonRadius: 12
                                colBackground: "transparent"
                                
                                onClicked: {
                                    if (modelData.active) {
                                        Network.disconnectWifiNetwork();
                                    } else {
                                        modelData.askingPassword = !modelData.askingPassword;
                                    }
                                }

                                RowLayout {
                                    width: parent.width
                                    anchors.margins: 12
                                    spacing: 12

                                    MaterialSymbol {
                                        text: {
                                            const s = modelData.strength
                                            if (s > 80) return "signal_wifi_4_bar"
                                            if (s > 60) return "network_wifi_3_bar"
                                            if (s > 40) return "network_wifi_2_bar"
                                            if (s > 20) return "network_wifi_1_bar"
                                            return "signal_wifi_0_bar"
                                        }
                                        iconSize: 24
                                        color: modelData.active ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        StyledText {
                                            text: modelData.ssid
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                            font.weight: modelData.active ? Font.DemiBold : Font.Normal
                                            color: Appearance.colors.colOnLayer1
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        StyledText {
                                            text: modelData.active ? "Connected" : (modelData.isSecure ? "Secured" : "Open")
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            color: Appearance.colors.colSubtext
                                            Layout.fillWidth: true
                                        }
                                    }

                                    MaterialSymbol {
                                        visible: modelData.active
                                        text: "check"
                                        iconSize: 24
                                        color: Appearance.colors.colPrimary
                                    }
                                    MaterialSymbol {
                                        visible: modelData.isSecure && !modelData.active
                                        text: "lock"
                                        iconSize: 20
                                        color: Appearance.colors.colSubtext
                                    }
                                }
                            }

                            // Expanded password entry
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: expanded ? passContent.implicitHeight + 24 : 0
                                color: Appearance.colors.colLayer2Base
                                radius: 12
                                clip: true
                                opacity: expanded ? 1 : 0
                                Behavior on Layout.preferredHeight { NumberAnimation { duration: 200 } }
                                Behavior on opacity { NumberAnimation { duration: 200 } }

                                ColumnLayout {
                                    id: passContent
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 12
                                    spacing: 12

                                    MaterialTextArea {
                                        id: passInput
                                        Layout.fillWidth: true
                                        placeholderText: Translation.tr("Enter password...")
                                    }
                                    
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Item { Layout.fillWidth: true }
                                        RippleButtonWithIcon {
                                            materialIcon: "login"
                                            mainText: Translation.tr("Connect")
                                            buttonRadius: Appearance.rounding.full
                                            onClicked: {
                                                Network.connectWithPassword ? Network.connectWithPassword(modelData.ssid, passInput.text, false, true) : Network.changePassword(modelData, passInput.text);
                                                modelData.askingPassword = false;
                                                //Fallback if connectWithPassword doesn't exist uses changePassword 
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
}
