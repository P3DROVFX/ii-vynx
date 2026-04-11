import QtQuick
import QtQuick.Layouts
import qs
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell
import Quickshell.Services.Pipewire

ColumnLayout {
    id: page
    spacing: 30
    width: parent ? parent.width : implicitWidth

    ContentSection {
        icon: "volume_up"
        title: Translation.tr("Audio Output")

        ConfigRow {
            StyledText {
                text: Translation.tr("Output Volume")
                color: Appearance.colors.colOnLayer1
                Layout.alignment: Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }
            StyledText {
                text: Audio.sink ? Math.round(Audio.sink.audio.volume * 100) + "%" : "0%"
                color: Appearance.colors.colOnLayer1
                Layout.alignment: Qt.AlignVCenter
            }
        }
        
        ConfigRow {
            uniform: true
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                RippleButton {
                    implicitWidth: 36
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.full
                    onClicked: Audio.toggleMute()
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: (Audio.sink && Audio.sink.audio.muted) ? "volume_off" : "volume_up"
                        iconSize: 20
                        color: Appearance.colors.colOnLayer1
                    }
                }
                
                StyledSlider {
                    Layout.fillWidth: true
                    from: 0
                    to: 1
                    value: Audio.sink ? Audio.sink.audio.volume : 0
                    onMoved: if (Audio.sink) Audio.sink.audio.volume = value
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Output Devices")
            visible: Audio.outputDevices.length > 0
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: Audio.outputDevices
                    
                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 50
                        buttonRadius: 12
                        colBackground: (Audio.sink && Audio.sink.id === modelData.id) ? Appearance.colors.colPrimary : Appearance.colors.colLayer1Base
                        onClicked: Audio.setDefaultSink(modelData)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            MaterialSymbol {
                                text: {
                                    const desc = modelData.description.toLowerCase();
                                    if (desc.includes("headset") || desc.includes("headphones")) return "headphones";
                                    if (desc.includes("bluetooth")) return "bluetooth_audio";
                                    return "speaker";
                                }
                                iconSize: 24
                                color: (Audio.sink && Audio.sink.id === modelData.id) ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                            }

                            StyledText {
                                text: Audio.friendlyDeviceName(modelData)
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: (Audio.sink && Audio.sink.id === modelData.id) ? Font.DemiBold : Font.Normal
                                color: (Audio.sink && Audio.sink.id === modelData.id) ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            
                            MaterialSymbol {
                                visible: Audio.sink && Audio.sink.id === modelData.id
                                text: "check_circle"
                                iconSize: 20
                                color: Appearance.colors.colOnPrimary
                            }
                        }
                    }
                }
            }
        }
    }
    
    ContentSection {
        icon: "mic"
        title: Translation.tr("Audio Input")

        ConfigRow {
            StyledText {
                text: Translation.tr("Input Volume")
                color: Appearance.colors.colOnLayer1
                Layout.alignment: Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }
            StyledText {
                text: Audio.source ? Math.round(Audio.source.audio.volume * 100) + "%" : "0%"
                color: Appearance.colors.colOnLayer1
                Layout.alignment: Qt.AlignVCenter
            }
        }
        
        ConfigRow {
            uniform: true
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                RippleButton {
                    implicitWidth: 36
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.full
                    onClicked: Audio.toggleMicMute()
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: (Audio.source && Audio.source.audio.muted) ? "mic_off" : "mic"
                        iconSize: 20
                        color: Appearance.colors.colOnLayer1
                    }
                }
                
                StyledSlider {
                    Layout.fillWidth: true
                    from: 0
                    to: 1
                    value: Audio.source ? Audio.source.audio.volume : 0
                    onMoved: if (Audio.source) Audio.source.audio.volume = value
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Input Devices")
            visible: Audio.inputDevices.length > 0
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: Audio.inputDevices
                    
                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 50
                        buttonRadius: 12
                        colBackground: (Audio.source && Audio.source.id === modelData.id) ? Appearance.colors.colPrimary : Appearance.colors.colLayer1Base
                        onClicked: Audio.setDefaultSource(modelData)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            MaterialSymbol {
                                text: {
                                    const desc = modelData.description.toLowerCase();
                                    if (desc.includes("headset")) return "headset_mic";
                                    return "mic";
                                }
                                iconSize: 24
                                color: (Audio.source && Audio.source.id === modelData.id) ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                            }

                            StyledText {
                                text: Audio.friendlyDeviceName(modelData)
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: (Audio.source && Audio.source.id === modelData.id) ? Font.DemiBold : Font.Normal
                                color: (Audio.source && Audio.source.id === modelData.id) ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            
                            MaterialSymbol {
                                visible: Audio.source && Audio.source.id === modelData.id
                                text: "check_circle"
                                iconSize: 20
                                color: Appearance.colors.colOnPrimary
                            }
                        }
                    }
                }
            }
        }
    }
}
