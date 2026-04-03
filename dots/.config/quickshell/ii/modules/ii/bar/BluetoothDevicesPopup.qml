import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12
        
        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            MaterialShape {
                shapeString: "Circle"
                implicitSize: 32
                color: Appearance.colors.colPrimaryContainer

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "bluetooth"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnPrimaryContainer
                }
            }

            StyledText {
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.expressive
                font.weight: Font.Bold
                text: Translation.tr("Bluetooth Devices")
                color: Appearance.colors.colOnSurface
            }
        }
        
        Rectangle {
            Layout.fillWidth: true
            height: 2
            color: Appearance.colors.colSurfaceContainerHighest
            radius: 1
        }
        
        // Scalable list of devices
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Repeater {
                model: BluetoothStatus.connectedDevices
                delegate: Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 80
                    Layout.minimumWidth: 340
                    radius: Appearance.rounding.large
                    color: Appearance.colors.colSurfaceContainerHigh
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 16
                        
                        // Icon (m3 style slanted)
                        MaterialShape {
                            shapeString: "Slanted"
                            implicitSize: 48
                            color: Appearance.colors.colSecondaryContainer

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: Icons.getBluetoothDeviceMaterialSymbol(modelData.icon || "")
                                iconSize: Appearance.font.pixelSize.huge
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                        }
                        
                        // Details column
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            // Top Row: Name and Status
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                StyledText {
                                    text: modelData.name || Translation.tr("Unknown device")
                                    font.pixelSize: Appearance.font.pixelSize.large
                                    font.weight: Font.Bold
                                    color: Appearance.colors.colOnSurface
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                
                                StyledText {
                                    text: Translation.tr("Connected")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colOnSurfaceVariant
                                }
                            }
                            
                            // Bottom Row: Battery Bar + Percentage
                            RowLayout {
                                visible: modelData.batteryAvailable
                                Layout.fillWidth: true
                                spacing: 12
                                
                                // Horizontal Battery Bar
                                Item {
                                    Layout.fillWidth: true
                                    height: 12
                                    
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 6
                                        color: Appearance.colors.colSurfaceContainerHighest
                                    }
                                    
                                    Rectangle {
                                        anchors {
                                            top: parent.top
                                            bottom: parent.bottom
                                            left: parent.left
                                        }
                                        width: parent.width * (modelData.battery)
                                        radius: 6
                                        color: {
                                            if (modelData.battery <= 0.15) return Appearance.m3colors.m3error;
                                            return Appearance.colors.colPrimary;
                                        }
                                    }
                                }
                                
                                // Percentage text
                                StyledText {
                                    text: Math.round(modelData.battery * 100) + "%"
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Bold
                                    color: {
                                        if (modelData.battery <= 0.15) return Appearance.m3colors.m3error;
                                        return Appearance.colors.colOnSurface;
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
