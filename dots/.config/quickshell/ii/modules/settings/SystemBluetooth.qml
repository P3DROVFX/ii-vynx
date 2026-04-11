import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common.functions as CF
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell
import Quickshell.Bluetooth

ColumnLayout {
    width: parent ? parent.width : implicitWidth

    ContentSection {
        icon: "bluetooth"
        title: Translation.tr("Bluetooth")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                text: Translation.tr("Enable Bluetooth")
                checked: BluetoothStatus.enabled
                onCheckedChanged: {
                    if (Bluetooth.defaultAdapter) {
                        Bluetooth.defaultAdapter.enabled = checked;
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Saved Devices")
            visible: BluetoothStatus.enabled
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: BluetoothStatus.connectedDevices
                    
                    Rectangle {
                        property bool isActive: true
                        property bool isProcessing: false
                        
                        Layout.fillWidth: true
                        implicitHeight: contentColumn.implicitHeight + 32
                        radius: Appearance.rounding.large
                        color: {
                            if (isProcessing) return CF.ColorUtils.mix(Appearance.colors.colLayer1Base, Appearance.colors.colOutline, 0.15);
                            if (devMouseArea.containsPress) return Appearance.colors.colLayer1BaseActive;
                            if (devMouseArea.containsMouse) return Appearance.colors.colLayer1BaseHover;
                            return Appearance.colors.colLayer1Base;
                        }
                        
                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }

                        MouseArea {
                            id: devMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !isProcessing
                        }

                        ColumnLayout {
                            id: contentColumn
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

                                // Identificador e Avatar do Dispositivo
                                Rectangle {
                                    width: 42
                                    height: 42
                                    radius: 21
                                    color: isActive ? Appearance.colors.colPrimary : Appearance.colors.colPrimaryContainer
                                    
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: {
                                            const type = modelData.deviceType;
                                            if (type === "phone") return "smartphone";
                                            if (type === "computer") return "computer";
                                            if (type === "audio-card") return "headset";
                                            return "bluetooth";
                                        }
                                        iconSize: 22
                                        color: isActive ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    
                                    RowLayout {
                                        Layout.fillWidth: true
                                        
                                        StyledText {
                                            text: modelData.name || modelData.address || "Unknown"
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                            font.weight: Font.DemiBold
                                            color: Appearance.colors.colOnLayer1
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Item { Layout.fillWidth: true }
                                        
                                        StyledText {
                                            text: Translation.tr("Connected")
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            font.weight: Font.DemiBold
                                            color: Appearance.colors.colPrimary
                                        }
                                    }

                                    RowLayout {
                                        visible: modelData.batteryAvailable
                                        Layout.fillWidth: true
                                        spacing: 8
                    
                                        StyledProgressBar {
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            valueBarHeight: 6
                                            value: modelData.battery || 0.0
                                            highlightColor: {
                                                if (modelData.battery <= 0.15) return Appearance.m3colors.m3error;
                                                return Appearance.colors.colPrimary;
                                            }
                                            trackColor: Appearance.colors.colLayer2Base
                                        }
                    
                                        StyledText {
                                            text: Math.round((modelData.battery || 0) * 100) + "%"
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            font.weight: Font.DemiBold
                                            color: Appearance.colors.colSubtext
                                        }
                                    }
                                }
                            }
                            
                            // Botões Pílula Inline
                            Row {
                                Layout.alignment: Qt.AlignRight
                                spacing: 8
                                
                                Item {
                                    id: forgetBtn
                                    width: forgetText.implicitWidth + 32
                                    height: 32
                                    
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 16
                                        color: {
                                            if (forgetMouseArea.containsPress) return Appearance.colors.colErrorContainerActive || "#ffb4ab"
                                            if (forgetMouseArea.containsMouse) return Appearance.colors.colErrorContainerHover || "#ff897d"
                                            return Appearance.colors.colErrorContainer || "#ffdad6"
                                        }
                                        Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
                                    }
                                    
                                    StyledText {
                                        id: forgetText
                                        anchors.centerIn: parent
                                        text: Translation.tr("Forget")
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: Font.DemiBold
                                        color: Appearance.colors.colOnErrorContainer || "#410002"
                                    }
                                    
                                    MouseArea {
                                        id: forgetMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.forget) modelData.forget();
                                        }
                                    }
                                }

                                Item {
                                    id: primaryBtn
                                    width: primaryText.implicitWidth + 32
                                    height: 32
                                    
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 16
                                        color: {
                                            if (primaryMouseArea.containsPress) return Appearance.colors.colSecondaryContainerActive;
                                            if (primaryMouseArea.containsMouse) return Appearance.colors.colSecondaryContainerHover;
                                            return Appearance.colors.colSecondaryContainer;
                                        }
                                        Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
                                    }
                                    
                                    StyledText {
                                        id: primaryText
                                        anchors.centerIn: parent
                                        text: Translation.tr("Disconnect")
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: Font.DemiBold
                                        color: Appearance.colors.colOnSecondaryContainer
                                    }
                                    
                                    MouseArea {
                                        id: primaryMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.disconnect) modelData.disconnect();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Repeater {
                    model: BluetoothStatus.pairedButNotConnectedDevices
                    
                    Rectangle {
                        property bool isActive: false
                        property bool isProcessing: false
                        
                        Layout.fillWidth: true
                        implicitHeight: contentColumn2.implicitHeight + 32
                        radius: Appearance.rounding.large
                        color: {
                            if (isProcessing) return CF.ColorUtils.mix(Appearance.colors.colLayer1Base, Appearance.colors.colOutline, 0.15);
                            if (devMouseArea2.containsPress) return Appearance.colors.colLayer1BaseActive;
                            if (devMouseArea2.containsMouse) return Appearance.colors.colLayer1BaseHover;
                            return Appearance.colors.colLayer1Base;
                        }

                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }

                        MouseArea {
                            id: devMouseArea2
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !isProcessing
                        }

                        ColumnLayout {
                            id: contentColumn2
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
                                    color: isActive ? Appearance.colors.colPrimary : Appearance.colors.colPrimaryContainer
                                    
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: {
                                            const type = modelData.deviceType;
                                            if (type === "phone") return "smartphone";
                                            if (type === "computer") return "computer";
                                            if (type === "audio-card") return "headset";
                                            return "bluetooth";
                                        }
                                        iconSize: 22
                                        color: isActive ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    
                                    RowLayout {
                                        Layout.fillWidth: true
                                        
                                        StyledText {
                                            text: modelData.name || modelData.address || "Unknown"
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                            font.weight: Font.DemiBold
                                            color: Appearance.colors.colOnLayer1
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Item { Layout.fillWidth: true }
                                        
                                        StyledText {
                                            text: Translation.tr("Paired")
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            color: Appearance.colors.colSubtext
                                        }
                                    }
                                }
                            }
                            
                            Row {
                                Layout.alignment: Qt.AlignRight
                                spacing: 8
                                
                                Item {
                                    id: forgetBtn2
                                    width: forgetText2.implicitWidth + 32
                                    height: 32
                                    
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 16
                                        color: {
                                            if (forgetMouseArea2.containsPress) return Appearance.colors.colErrorContainerActive || "#ffb4ab"
                                            if (forgetMouseArea2.containsMouse) return Appearance.colors.colErrorContainerHover || "#ff897d"
                                            return Appearance.colors.colErrorContainer || "#ffdad6"
                                        }
                                        Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
                                    }
                                    
                                    StyledText {
                                        id: forgetText2
                                        anchors.centerIn: parent
                                        text: Translation.tr("Forget")
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: Font.DemiBold
                                        color: Appearance.colors.colOnErrorContainer || "#410002"
                                    }
                                    
                                    MouseArea {
                                        id: forgetMouseArea2
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.forget) modelData.forget();
                                        }
                                    }
                                }

                                Item {
                                    id: primaryBtn2
                                    width: primaryText2.implicitWidth + 32
                                    height: 32
                                    
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 16
                                        color: {
                                            if (primaryMouseArea2.containsPress) return Appearance.colors.colPrimaryActive;
                                            if (primaryMouseArea2.containsMouse) return Appearance.colors.colPrimaryHover;
                                            return Appearance.colors.colPrimary;
                                        }
                                        Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
                                    }
                                    
                                    StyledText {
                                        id: primaryText2
                                        anchors.centerIn: parent
                                        text: Translation.tr("Connect")
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: Font.DemiBold
                                        color: Appearance.colors.colOnPrimary
                                    }
                                    
                                    MouseArea {
                                        id: primaryMouseArea2
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.connect) modelData.connect();
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
    
    ContentSection {
        icon: "add_circle"
        title: Translation.tr("Pair new device")
        visible: BluetoothStatus.enabled
        
        ConfigRow {
            uniform: true
            RippleButtonWithIcon {
                Layout.fillWidth: true
                buttonRadius: Appearance.rounding.large
                materialIcon: "search"
                mainText: Translation.tr("Start Discovery")
                onClicked: {
                    if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.discovering = true;
                }
                MaterialSymbol {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "autorenew"
                    iconSize: 20
                    color: Appearance.colors.colOnLayer1
                    visible: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.discovering : false
                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.discovering : false
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Available Devices")
            visible: BluetoothStatus.unpairedDevices.length > 0
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: BluetoothStatus.unpairedDevices
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        color: {
                            if (devMouseArea3.containsPress) return Appearance.colors.colLayer1BaseActive;
                            if (devMouseArea3.containsMouse) return Appearance.colors.colLayer1BaseHover;
                            return Appearance.colors.colLayer1Base;
                        }
                        radius: Appearance.rounding.large
                        
                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }

                        MouseArea {
                            id: devMouseArea3
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.pair) modelData.pair()
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 16

                            MaterialSymbol {
                                text: {
                                    const type = modelData.deviceType;
                                    if (type === "phone") return "smartphone";
                                    if (type === "computer") return "computer";
                                    if (type === "audio-card") return "headset";
                                    return "bluetooth";
                                }
                                iconSize: 22
                                color: Appearance.colors.colSubtext
                            }

                            StyledText {
                                text: modelData.name || modelData.address || "Unknown"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            
                            MaterialSymbol {
                                text: "add"
                                iconSize: 20
                                color: Appearance.colors.colPrimary
                            }
                        }
                    }
                }
            }
        }
    }
}
