import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import qs.services.network
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    required property WifiAccessPoint wifiNetwork
    property bool isFirst: false
    property bool isLast: false
    property bool hovered: itemMouseArea.containsMouse

    property bool isActive: (wifiNetwork?.active ?? false)
    property bool isAskingPassword: (wifiNetwork?.askingPassword ?? false)
    property bool isConnecting: Network.wifiConnectTarget === root.wifiNetwork && !isActive

    enabled: !isConnecting

    implicitHeight: contentColumn.implicitHeight + 24

    color: {
        let base = isActive ? Appearance.colors.colPrimary : Appearance.colors.colPrimaryContainer;
        if (itemMouseArea.containsPress)
            return isActive ? Appearance.colors.colPrimaryActive : Appearance.colors.colPrimaryContainerActive;
        if (hovered)
            return isActive ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimaryContainerHover;
        return base;
    }

    Behavior on color {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(root)
    }

    topLeftRadius: root.isFirst ? 16 : 0
    topRightRadius: root.isFirst ? 16 : 0
    bottomLeftRadius: root.isLast ? 16 : 0
    bottomRightRadius: root.isLast ? 16 : 0

    MouseArea {
        id: itemMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: root.isAskingPassword || root.isConnecting ? Qt.NoButton : Qt.LeftButton
        onClicked: {
            Network.connectToWifiNetwork(wifiNetwork);
        }
    }

    ColumnLayout {
        id: contentColumn
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 12
            leftMargin: 20
            rightMargin: 20
        }
        spacing: 12

        RowLayout {
            // Name
            spacing: 12

            Item {
                width: 24
                height: 24

                MaterialSymbol {
                    anchors.centerIn: parent
                    iconSize: Appearance.font.pixelSize.larger
                    property int strength: root.wifiNetwork?.strength ?? 0
                    text: strength > 80 ? "signal_wifi_4_bar" : strength > 60 ? "network_wifi_3_bar" : strength > 40 ? "network_wifi_2_bar" : strength > 20 ? "network_wifi_1_bar" : "signal_wifi_0_bar"
                    color: root.isActive ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2

                    scale: root.isConnecting ? 0 : 1
                    opacity: root.isConnecting ? 0 : 1

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

                // M3 Cookie shape loader
                MaterialShape {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    shape: MaterialShape.Shape.Cookie7Sided
                    color: Appearance.colors.colPrimary

                    scale: root.isConnecting ? 1 : 0
                    opacity: root.isConnecting ? 1 : 0

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

                    RotationAnimator on rotation {
                        from: 0
                        to: 360
                        duration: 2000
                        loops: Animation.Infinite
                        running: root.isConnecting
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                color: root.isActive ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
                elide: Text.ElideRight
                text: root.wifiNetwork?.ssid ?? Translation.tr("Unknown")
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Bold
                textFormat: Text.PlainText
            }

            StyledText {
                visible: root.isActive || root.isConnecting
                text: root.isConnecting ? Translation.tr("Connecting...") : Translation.tr("Connected")
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
                color: ColorUtils.transparentize(root.isActive ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2, 0.25)
            }

            MaterialSymbol {
                visible: (root.wifiNetwork?.isSecure || root.isActive) ?? false
                text: root.isActive ? "check" : "lock"
                iconSize: Appearance.font.pixelSize.normal
                color: root.isActive ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
            }
        }

        ColumnLayout { // Password
            id: passwordPrompt
            Layout.topMargin: 4
            visible: root.isAskingPassword

            MaterialTextField {
                id: passwordField
                Layout.fillWidth: true
                placeholderText: Translation.tr("Password")

                // Password
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData

                onAccepted: {
                    Network.changePassword(root.wifiNetwork, passwordField.text);
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4

                Item {
                    Layout.fillWidth: true
                }

                // Disconnect button (right pill)
                Rectangle {
                    height: 28
                    width: cancelText.implicitWidth + 24
                    color: cancelMouseArea.containsPress ? Appearance.colors.colLayer2Active : cancelMouseArea.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2

                    scale: cancelMouseArea.containsPress ? 0.95 : 1
                    Behavior on scale {
                        animation: Appearance.animation.clickBounce.numberAnimation.createObject(this)
                    }

                    // Shape: pill
                    radius: height / 2

                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }

                    StyledText {
                        id: cancelText
                        anchors.centerIn: parent
                        text: Translation.tr("Cancel")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer1
                    }

                    MouseArea {
                        id: cancelMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            root.wifiNetwork.askingPassword = false;
                        }
                    }
                }

                Rectangle {
                    height: 28
                    width: pconnectText.implicitWidth + 24
                    color: pconnectMouseArea.containsPress ? Appearance.colors.colPrimaryActive : pconnectMouseArea.containsMouse ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary

                    scale: pconnectMouseArea.containsPress ? 0.95 : 1
                    Behavior on scale {
                        animation: Appearance.animation.clickBounce.numberAnimation.createObject(this)
                    }

                    // Shape: pill
                    radius: height / 2

                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }

                    StyledText {
                        id: pconnectText
                        anchors.centerIn: parent
                        text: Translation.tr("Connect")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnPrimary
                    }

                    MouseArea {
                        id: pconnectMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            Network.changePassword(root.wifiNetwork, passwordField.text);
                        }
                    }
                }
            }
        }

        ColumnLayout { // Public wifi login page
            id: publicWifiPortal
            Layout.topMargin: 4
            visible: (root.isActive && (root.wifiNetwork?.security ?? "").trim().length === 0) ?? false

            RowLayout {
                Layout.fillWidth: true

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 16
                    color: portalMouseArea.containsPress ? Appearance.colors.colLayer4Active : portalMouseArea.containsMouse ? Appearance.colors.colLayer4Hover : Appearance.colors.colLayer4

                    scale: portalMouseArea.containsPress ? 0.95 : 1
                    Behavior on scale {
                        animation: Appearance.animation.clickBounce.numberAnimation.createObject(this)
                    }

                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: Translation.tr("Open network portal")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer4
                    }

                    MouseArea {
                        id: portalMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            Network.openPublicWifiPortal();
                            GlobalStates.sidebarRightOpen = false;
                        }
                    }
                }
            }
        }
    }
}
