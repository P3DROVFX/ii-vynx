import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    required property var device
    property bool isFirst: false
    property bool isLast: false
    property bool isPairedSection: true
    property bool hovered: itemMouseArea.containsMouse
    property bool isProcessing: false

    Connections {
        target: root.device
        function onConnectedChanged() {
            root.isProcessing = false;
        }
    }

    property bool isActive: root.device?.connected ?? false

    implicitHeight: contentColumn.implicitHeight + 32
    color: {
        let base = isActive ? Appearance.colors.colPrimary : Appearance.colors.colPrimaryContainer;
        if (root.isProcessing)
            return ColorUtils.mix(base, Appearance.colors.colOutline, 0.15);
        if (itemMouseArea.containsPress)
            return isActive ? Appearance.colors.colPrimaryActive : Appearance.colors.colPrimaryContainerActive;
        if (hovered)
            return isActive ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimaryContainerHover;
        return base;
    }

    Behavior on color {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }

    topLeftRadius: (root.isPairedSection && !root.isFirst) ? 0 : 24
    topRightRadius: (root.isPairedSection && !root.isFirst) ? 0 : 24
    bottomLeftRadius: (root.isPairedSection && !root.isLast) ? 0 : 24
    bottomRightRadius: (root.isPairedSection && !root.isLast) ? 0 : 24

    MouseArea {
        id: itemMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        enabled: !root.isProcessing
    }

    ColumnLayout {
        id: contentColumn
        anchors {
            fill: parent
            margins: 16
            leftMargin: 24
            rightMargin: 24
        }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Device icon container
            Item {
                width: 48
                height: 48

                // Device icon
                MaterialSymbol {
                    anchors.centerIn: parent
                    iconSize: 48
                    text: Icons.getBluetoothDeviceMaterialSymbol(root.device?.icon || "")
                    color: isActive ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2

                    scale: root.isProcessing ? 0 : 1
                    opacity: root.isProcessing ? 0 : 1

                    Behavior on scale {
                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.5
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                // M3 Expressive Loading Indicator
                Item {
                    id: loaderContainer
                    anchors.centerIn: parent
                    width: 24
                    height: 24

                    scale: root.isProcessing ? 1 : 0
                    opacity: root.isProcessing ? 1 : 0

                    Behavior on scale {
                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.5
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.InOutQuad
                        }
                    }

                    // M3 Cookie shape loader
                    MaterialShape {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        shape: MaterialShape.Shape.Cookie7Sided
                        color: isActive ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2

                        RotationAnimator on rotation {
                            from: 0
                            to: 360
                            duration: 2000
                            loops: Animation.Infinite
                            running: root.isProcessing
                        }
                    }
                }
            }

            // Content for paired devices
            ColumnLayout {
                visible: root.isPairedSection
                Layout.fillWidth: true
                spacing: 10

                // Name and status row
                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        text: root.device?.name || Translation.tr("Unknown device")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Bold
                        color: isActive ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Item { // Spacer
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: {
                            if (root.isProcessing)
                                return root.device?.connected ? Translation.tr("Disconnecting...") : Translation.tr("Connecting...");
                            return root.device?.connected ? Translation.tr("Connected") : Translation.tr("Paired");
                        }
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: root.device?.connected && !root.isProcessing ? Font.Bold : Font.Medium
                        color: ColorUtils.transparentize(isActive ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2, 0.25)
                    }
                }

                // Battery bar (only for connected devices with battery)
                RowLayout {
                    visible: root.device?.connected && (root.device?.batteryAvailable ?? false)
                    Layout.fillWidth: true
                    spacing: 10

                    StyledProgressBar {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        valueBarHeight: 12
                        value: root.device?.battery ?? 0
                        highlightColor: {
                            if (root.device?.battery <= 0.15)
                                return Appearance.m3colors.m3error;
                            return isActive ? Appearance.colors.colOnPrimary : Appearance.colors.colPrimary;
                        }
                        trackColor: ColorUtils.transparentize(isActive ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2, 0.7)
                    }

                    StyledText {
                        text: Math.round((root.device?.battery ?? 0) * 100) + "%"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Bold
                        color: ColorUtils.transparentize(isActive ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2, 0.15)
                    }
                }

                // Action buttons - M3 Expressive connected style
                Row {
                    Layout.alignment: Qt.AlignRight
                    spacing: 2

                    // Forget button (left pill)
                    Item {
                        id: forgetBtn
                        height: 26
                        width: forgetText.implicitWidth + 24

                        scale: forgetMouseArea.containsPress ? 0.95 : 1
                        Behavior on scale {
                            animation: Appearance.animation.clickBounce.numberAnimation.createObject(forgetBtn)
                        }

                        // Filter transparent overlap by clipping a single rectangle
                        Item {
                            anchors.fill: parent
                            clip: true
                            Rectangle {
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                width: parent.width + parent.height / 2
                                radius: parent.height / 2
                                color: {
                                    if (forgetMouseArea.containsPress)
                                        return Appearance.colors.colSecondaryContainerActive;
                                    if (forgetMouseArea.containsMouse)
                                        return Appearance.colors.colSecondaryContainerHover;
                                    return Appearance.colors.colSecondaryContainer;
                                }

                                Behavior on color {
                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                }
                            }
                        }

                        StyledText {
                            id: forgetText
                            anchors.centerIn: parent
                            text: Translation.tr("Forget")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Bold
                            color: isActive ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer2
                        }

                        MouseArea {
                            id: forgetMouseArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            enabled: !root.isProcessing
                            onClicked: root.device?.forget()
                        }
                    }

                    // Disconnect button (right pill)
                    Item {
                        id: disconnectBtn
                        height: 26
                        width: disconnectText.implicitWidth + 24

                        scale: disconnectMouseArea.containsPress ? 0.95 : 1
                        Behavior on scale {
                            animation: Appearance.animation.clickBounce.numberAnimation.createObject(disconnectBtn)
                        }

                        // Filter transparent overlap by clipping a single rectangle
                        Item {
                            anchors.fill: parent
                            clip: true
                            Rectangle {
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                width: parent.width + parent.height / 2
                                radius: parent.height / 2
                                color: {
                                    if (root.isProcessing)
                                        return ColorUtils.mix(Appearance.colors.colSecondary, Appearance.colors.colOutline, 0.4);
                                    if (disconnectMouseArea.containsPress)
                                        return Appearance.colors.colSecondaryActive;
                                    if (disconnectMouseArea.containsMouse)
                                        return Appearance.colors.colSecondaryHover;
                                    return Appearance.colors.colSecondaryContainer;
                                }

                                Behavior on color {
                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                }
                            }
                        }

                        StyledText {
                            id: disconnectText
                            anchors.centerIn: parent
                            text: root.device?.connected ? Translation.tr("Disconnect") : Translation.tr("Connect")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Bold
                            color: root.isProcessing ? ColorUtils.transparentize(Appearance.colors.colOnSecondary, 0.5) : Appearance.colors.colOnSecondaryContainer
                        }

                        MouseArea {
                            id: disconnectMouseArea
                            anchors.fill: parent
                            cursorShape: root.isProcessing ? Qt.WaitCursor : Qt.PointingHandCursor
                            hoverEnabled: true
                            enabled: !root.isProcessing
                            onClicked: {
                                if (root.device?.connected) {
                                    root.isProcessing = true;
                                    root.device.disconnect();
                                } else {
                                    root.isProcessing = true;
                                    root.device.connect();
                                }
                            }
                        }
                    }
                }
            }

            // Content for available devices (horizontal layout)
            ColumnLayout {
                visible: !root.isPairedSection
                Layout.fillWidth: true
                spacing: 4

                StyledText {
                    text: root.device?.name || Translation.tr("Unknown device")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer2
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                StyledText {
                    text: root.isProcessing ? Translation.tr("Connecting...") : Translation.tr("Available")
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: root.isProcessing ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colOnLayer2, 0.25)
                }
            }

            // Connect button for available devices
            Rectangle {
                id: connectBtn
                visible: !root.isPairedSection
                height: 32
                width: connectText.implicitWidth + 48
                radius: 16
                color: {
                    if (root.isProcessing)
                        return ColorUtils.mix(Appearance.colors.colLayer2, Appearance.colors.colOutline, 0.4);
                    if (connectMouseArea.containsPress)
                        return Appearance.colors.colPrimaryActive;
                    if (connectMouseArea.containsMouse)
                        return Appearance.colors.colPrimaryHover;
                    return Appearance.colors.colPrimary;
                }

                scale: connectMouseArea.containsPress ? 0.95 : 1
                Behavior on scale {
                    animation: Appearance.animation.clickBounce.numberAnimation.createObject(connectBtn)
                }

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }

                StyledText {
                    id: connectText
                    anchors.centerIn: parent
                    text: Translation.tr("Connect")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Bold
                    color: root.isProcessing ? ColorUtils.transparentize(Appearance.colors.colOnPrimary, 0.5) : Appearance.colors.colOnPrimary
                }

                MouseArea {
                    id: connectMouseArea
                    anchors.fill: parent
                    cursorShape: root.isProcessing ? Qt.WaitCursor : Qt.PointingHandCursor
                    hoverEnabled: true
                    enabled: !root.isProcessing
                    onClicked: {
                        root.isProcessing = true;
                        root.device?.connect();
                    }
                }
            }
        }
    }
}
