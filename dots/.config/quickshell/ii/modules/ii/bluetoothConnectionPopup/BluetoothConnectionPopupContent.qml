import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var device
    signal dismissed()
    signal disconnectRequested()

    // Expose contentBackground for mask in parent PanelWindow
    property alias contentBackground: contentBackground

    // Known device image mapping by MAC address
    readonly property var deviceImageMap: ({
        "E8:EE:CC:96:31:3A": Qt.resolvedUrl("../../../assets/images/devices/anker_q30_.png"),
        "40:35:E6:31:8B:AC": Qt.resolvedUrl("../../../assets/images/devices/galaxy_buds_3.png"),
        "64:1B:2F:9B:95:CE": Qt.resolvedUrl("../../../assets/images/devices/samsung_s23.png")
    })

    readonly property string deviceName: device?.name ?? Translation.tr("Unknown Device")
    readonly property string deviceIcon: device ? Icons.getBluetoothDeviceMaterialSymbol(device.icon || "") : "headphones"
    readonly property string deviceImageSource: {
        if (!device) return "";
        const img = deviceImageMap[device.address];
        return img || "";
    }
    readonly property bool hasCustomImage: deviceImageSource !== ""

    // Sizing
    property real popupWidth: 300
    property real horizontalPadding: 20
    property real verticalPadding: 20

    implicitWidth: popupWidth + 2 * Appearance.sizes.elevationMargin
    implicitHeight: contentLayout.implicitHeight + verticalPadding * 2 + 2 * Appearance.sizes.elevationMargin

    // === ANIMATIONS ===
    NumberAnimation on opacity {
        from: 0; to: 1
        duration: 350
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
        running: true
    }

    NumberAnimation on scale {
        from: 0.85; to: 1
        duration: 400
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
        running: true
    }

    transformOrigin: Item.TopRight

    // Shadow
    StyledRectangularShadow {
        target: contentBackground
    }

    Rectangle {
        id: contentBackground
        x: Appearance.sizes.elevationMargin
        y: Appearance.sizes.elevationMargin
        width: popupWidth
        height: contentLayout.implicitHeight + verticalPadding * 2
        radius: Appearance.rounding.large
        color: Appearance.m3colors.m3surfaceContainer
        border.width: 1
        border.color: Appearance.colors.colLayer0Border

        ColumnLayout {
            id: contentLayout
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: root.horizontalPadding
                topMargin: root.verticalPadding
                bottomMargin: root.verticalPadding
            }
            spacing: 12

            // === HEADER ROW ===
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

            // === DIVIDER LINE ===
            Rectangle {
                Layout.fillWidth: true
                height: 2
                color: Appearance.colors.colSurfaceContainerHighest
                radius: 1
            }

            // === DEVICE NAME ===
            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: 4
                horizontalAlignment: Text.AlignLeft
                text: root.deviceName
                font.pixelSize: 26
                font.family: Appearance.font.family.title
                font.weight: Font.Bold
                color: Appearance.colors.colOnSurface
                elide: Text.ElideRight
            }

            // === STATUS TEXT ===
            StyledText {
                Layout.topMargin: -8
                horizontalAlignment: Text.AlignLeft
                text: Translation.tr("Connected")
                font.pixelSize: Appearance.font.pixelSize.normal
                font.family: Appearance.font.family.main
                color: Appearance.colors.colOnSurfaceVariant
            }

            // === DEVICE IMAGE / ICON AREA ===
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 160
                Layout.topMargin: 4

                // Cookie shape background (centered)
                MaterialCookie {
                    id: cookieShape
                    anchors.centerIn: parent
                    implicitSize: 150
                    color: Appearance.colors.colPrimaryContainer

                    RotationAnimation on rotation {
                        from: 0; to: 360
                        duration: 15000
                        loops: Animation.Infinite
                        running: true
                    }

                    NumberAnimation on scale {
                        from: 0; to: 1
                        duration: 650
                        easing.type: Easing.OutBack
                        easing.overshoot: 2.5
                    }
                }

                // Device image or icon on top of the cookie shape
                Loader {
                    anchors.centerIn: parent
                    active: root.hasCustomImage
                    sourceComponent: Image {
                        source: root.deviceImageSource
                        width: 110
                        height: 110
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        
                        NumberAnimation on scale {
                            from: 0; to: 1
                            duration: 750
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.5
                        }
                    }
                }

                // Fallback MaterialSymbol icon when no custom image
                Loader {
                    anchors.centerIn: parent
                    active: !root.hasCustomImage
                    sourceComponent: MaterialSymbol {
                        text: root.deviceIcon
                        iconSize: 64
                        color: Appearance.colors.colOnPrimaryContainer

                        NumberAnimation on scale {
                            from: 0; to: 1
                            duration: 750
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.5
                        }
                    }
                }
            }

            // === BATTERY INDICATOR (M3 Expressive StyledProgressBar) ===
            RowLayout {
                visible: root.device?.batteryAvailable ?? false
                Layout.fillWidth: true
                spacing: 12

                StyledProgressBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 10
                    valueBarHeight: 10
                    from: 0
                    to: 1
                    value: root.device?.battery ?? 0
                    highlightColor: {
                        const battery = root.device?.battery ?? 0;
                        if (battery <= 0.15) return Appearance.m3colors.m3error;
                        return Appearance.colors.colPrimary;
                    }
                    trackColor: Appearance.colors.colSurfaceContainerHighest
                }

                StyledText {
                    text: Math.round((root.device?.battery ?? 0) * 100) + "%"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Bold
                    color: {
                        const battery = root.device?.battery ?? 0;
                        if (battery <= 0.15) return Appearance.m3colors.m3error;
                        return Appearance.colors.colOnSurface;
                    }
                }
            }

            // === ACTION BUTTONS ===
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 8

                // Disconnect button
                Rectangle {
                    id: disconnectBtnRect
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 40
                    radius: Appearance.rounding.full
                    color: disconnectMa.containsMouse
                        ? Appearance.colors.colErrorContainerHover
                        : Appearance.m3colors.m3errorContainer

                    scale: disconnectMa.pressed ? 0.92 : (disconnectMa.containsMouse ? 1.05 : 1.0)

                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }

                    Behavior on scale {
                        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "bluetooth_disabled"
                        iconSize: Appearance.font.pixelSize.large
                        color: Appearance.m3colors.m3onErrorContainer
                    }

                    MouseArea {
                        id: disconnectMa
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: root.disconnectRequested()
                    }
                }

                // Settings / Open BT settings button
                Rectangle {
                    id: settingsBtnRect
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: Appearance.rounding.full
                    color: settingsMa.containsMouse
                        ? Appearance.colors.colSurfaceContainerHighestHover
                        : Appearance.colors.colSurfaceContainerHighest

                    scale: settingsMa.pressed ? 0.96 : (settingsMa.containsMouse ? 1.02 : 1.0)

                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }

                    Behavior on scale {
                        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        MaterialSymbol {
                            text: "settings"
                            iconSize: Appearance.font.pixelSize.large
                            color: Appearance.colors.colOnSurface
                        }

                        StyledText {
                            text: Translation.tr("Settings")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnSurface
                        }
                    }

                    MouseArea {
                        id: settingsMa
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            root.dismissed();
                        }
                    }
                }
            }
        }

        // Click anywhere on the card to dismiss
        MouseArea {
            anchors.fill: parent
            z: -1  // Behind the buttons
            onClicked: root.dismissed()
        }
    }
}
