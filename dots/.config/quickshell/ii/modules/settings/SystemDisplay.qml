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
        icon: "monitor"
        title: Translation.tr("Monitors")

        ContentSubsection {
            title: Translation.tr("Attached Displays")
            visible: HyprlandData.monitors.length > 0
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: HyprlandData.monitors
                    
                    Rectangle {
                        property var monitorObj: modelData
                        
                        Layout.fillWidth: true
                        implicitHeight: monitorCol.implicitHeight + 32
                        color: Appearance.colors.colLayer1Base
                        radius: Appearance.rounding.large

                        ColumnLayout {
                            id: monitorCol
                            anchors {
                                fill: parent
                                margins: 16
                                leftMargin: 24
                                rightMargin: 24
                            }
                            spacing: 12

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 16

                                Rectangle {
                                    width: 42
                                    height: 42
                                    radius: 21
                                    color: Appearance.colors.colPrimaryContainer
                                    
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: (monitorObj.name === "eDP-1" || monitorObj.name.includes("eDP")) ? "laptop_mac" : "desktop_windows"
                                        iconSize: 22
                                        color: Appearance.colors.colOnPrimaryContainer
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    
                                    RowLayout {
                                        Layout.fillWidth: true
                                        
                                        StyledText {
                                            text: monitorObj.description || monitorObj.name || ""
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                            font.weight: Font.DemiBold
                                            color: Appearance.colors.colOnLayer1
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Item { Layout.fillWidth: true }
                                        
                                        StyledText {
                                            text: ((monitorObj.scale || 1.0) * 100) + "%"
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            font.weight: Font.DemiBold
                                            color: Appearance.colors.colPrimary
                                        }
                                    }

                                    StyledText {
                                        text: (monitorObj.width || 0) + "x" + (monitorObj.height || 0) + " @ " + Math.round(monitorObj.refreshRate || 60) + "Hz"
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colSubtext
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                            
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 4
                                spacing: 8
                                
                                StyledText {
                                    text: Translation.tr("Scale:")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Item { Layout.fillWidth: true }
                                
                                Repeater {
                                    model: [1.0, 1.25, 1.5, 2.0]
                                    
                                    Item {
                                        property bool isActive: Math.abs(modelData - (monitorObj.scale || 1.0)) < 0.01
                                        width: scaleText.implicitWidth + 24
                                        height: 32
                                        
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 16
                                            color: {
                                                if (scaleMouseArea.containsPress) return isActive ? Appearance.colors.colPrimaryActive : Appearance.colors.colLayer2BaseActive;
                                                if (scaleMouseArea.containsMouse) return isActive ? Appearance.colors.colPrimaryHover : Appearance.colors.colLayer2BaseHover;
                                                return isActive ? Appearance.colors.colPrimary : Appearance.colors.colLayer2Base;
                                            }
                                            Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
                                        }
                                        
                                        StyledText {
                                            id: scaleText
                                            anchors.centerIn: parent
                                            text: (modelData * 100) + "%"
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            font.weight: isActive ? Font.DemiBold : Font.Normal
                                            color: isActive ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
                                        }
                                        
                                        MouseArea {
                                            id: scaleMouseArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Quickshell.execDetached(["hyprctl", "keyword", "monitor", `${monitorObj.name},${monitorObj.width}x${monitorObj.height}@${monitorObj.refreshRate},${monitorObj.x}x${monitorObj.y},${modelData}`]);
                                                HyprlandData.updateMonitors();
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
