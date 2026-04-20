import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Rectangle {
    id: root

    property bool show: false
    property var targetNetwork: null
    signal connectRequested(string password)
    signal dismissed

    readonly property string networkName: targetNetwork ? targetNetwork.ssid : ""
    readonly property bool networkSecured: targetNetwork ? targetNetwork.isSecure : true
    readonly property int networkFrequency: targetNetwork ? targetNetwork.frequency : 0
    readonly property string networkSecurity: targetNetwork ? targetNetwork.security : ""

    property real backgroundWidth: 350
    property real backgroundAnimationMovementDistance: 60
    property bool passwordVisible: false
    property bool localConnecting: false
    readonly property bool isSaved: Network.savedSsids.includes(root.networkName)

    Connections {
        target: Network
        function onWifiConnectingChanged() {
            if (root.show && root.localConnecting && !Network.wifiConnecting) {
                if (Network.lastWifiExitCode === 0) {
                    root.localConnecting = false;
                    root.dismissed();
                } else {
                    root.localConnecting = false;
                }
            }
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.dismissed();
            event.accepted = true;
        }
    }

    color: root.show ? Appearance.colors.colScrim : "transparent"
    Behavior on color {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }
    visible: root.show || dialogBackground.implicitHeight > 0

    onShowChanged: {
        dialogBackgroundHeightAnimation.easing.bezierCurve = (show ? Appearance.animationCurves.emphasizedDecel : Appearance.animationCurves.emphasizedAccel);
        if (!show) {
            passwordField.text = "";
            passwordVisible = false;
            localConnecting = false;
            Network.lastWifiError = "";
        } else {
            passwordField.forceActiveFocus();
        }
    }

    radius: 0

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        onPressed: root.dismissed()
    }

    Rectangle {
        id: dialogBackground
        anchors.horizontalCenter: parent.horizontalCenter
        radius: Appearance.rounding.large
        color: Appearance.m3colors.m3surfaceContainerHigh
        layer.enabled: true
        layer.samples: 8
        layer.smooth: true
        antialiasing: true

        property real targetY: root.height / 2 - dialogBackground.implicitHeight / 2
        y: root.show ? targetY : (targetY - root.backgroundAnimationMovementDistance)
        implicitWidth: root.backgroundWidth
        implicitHeight: root.show ? (contentColumn.implicitHeight + dialogBackground.radius * 3) : 0

        Behavior on implicitHeight {
            NumberAnimation {
                id: dialogBackgroundHeightAnimation
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: dialogBackgroundHeightAnimation.duration
                easing.type: dialogBackgroundHeightAnimation.easing.type
                easing.bezierCurve: dialogBackgroundHeightAnimation.easing.bezierCurve
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
        }

        // Close button (X)
        RippleButton {
            anchors {
                top: parent.top
                right: parent.right
                margins: 12
            }
            implicitWidth: 36
            implicitHeight: 36
            buttonRadius: Appearance.rounding.full
            colBackground: "transparent"
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "close"
                iconSize: 20
                color: Appearance.colors.colSubtext
            }
            onClicked: root.dismissed()
            z: 10
            opacity: root.show ? 1 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }

        ColumnLayout {
            id: contentColumn
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 24
            }
            spacing: 24
            opacity: root.show ? 1 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            // Header Icon
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 72

                Item {
                    anchors.centerIn: parent
                    width: 72
                    height: 72
                    scale: root.show ? 1.0 : 0.0
                    rotation: root.show ? 0 : -180

                    Behavior on scale {
                        NumberAnimation {
                            duration: 500
                            easing.type: Easing.OutElastic
                            easing.amplitude: 2.0
                            easing.period: 0.8
                        }
                    }
                    Behavior on rotation {
                        NumberAnimation {
                            duration: 400
                            easing.type: Easing.OutQuad
                        }
                    }

                    Rectangle {
                        id: iconRect
                        anchors.fill: parent
                        radius: Appearance.rounding.large // 20px
                        color: Appearance.colors.colPrimary

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "wifi"
                            iconSize: 36
                            color: Appearance.colors.colOnPrimary
                        }
                    }
                }
            }

            // Title & Name
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("Connect to Network")
                    font.pixelSize: Appearance.font.pixelSize.huge
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.networkName
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: Appearance.colors.colPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // Badges
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                scale: root.show ? 1.0 : 0.0
                Behavior on scale {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutBack
                    }
                }

                Rectangle {
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colLayer1Base
                    implicitWidth: secLayout.implicitWidth + 24
                    implicitHeight: 28
                    RowLayout {
                        id: secLayout
                        anchors.centerIn: parent
                        spacing: 4
                        MaterialSymbol {
                            text: root.networkSecured ? "lock_outline" : "wifi"
                            iconSize: 16
                            color: Appearance.colors.colSubtext
                        }
                        StyledText {
                            text: root.networkSecured ? Translation.tr("Secured") : Translation.tr("Open")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
                Rectangle {
                    visible: root.networkFrequency > 0
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colLayer1Base
                    implicitWidth: freqLayout.implicitWidth + 24
                    implicitHeight: 28
                    RowLayout {
                        id: freqLayout
                        anchors.centerIn: parent
                        spacing: 4
                        MaterialSymbol {
                            text: "wifi"
                            iconSize: 16
                            color: Appearance.colors.colSubtext
                        }
                        StyledText {
                            text: root.networkFrequency > 5000 ? "5 GHz" : "2.4 GHz"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }

            // Input field and visibility toggle
            Item {
                visible: root.networkSecured && (!root.isSaved || (root.targetNetwork && root.targetNetwork.askingPassword))
                Layout.fillWidth: true
                implicitHeight: 64

                transform: Translate {
                    y: root.show ? 0 : 10
                }
                Behavior on transform {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutQuad
                    }
                }

                // Input border
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 8
                    radius: Appearance.rounding.large
                    border.width: passwordField.activeFocus ? 2 : 1
                    border.color: passwordField.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colPrimaryContainer
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 8
                        spacing: 8

                        TextInput {
                            id: passwordField
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            font.family: Appearance.font.family.main
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                            echoMode: root.passwordVisible ? TextInput.Normal : TextInput.Password
                            clip: true

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                text: Translation.tr("Enter network password")
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.normal
                                visible: passwordField.text.length === 0
                            }

                            onAccepted: {
                                if (connectBtn.canConnect && !root.localConnecting) {
                                    root.localConnecting = true;
                                    root.connectRequested(passwordField.text);
                                }
                            }
                        }

                        RippleButton {
                            implicitWidth: 40
                            implicitHeight: 40
                            buttonRadius: Appearance.rounding.full
                            colBackground: "transparent"
                            onClicked: root.passwordVisible = !root.passwordVisible
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: root.passwordVisible ? "visibility_off" : "visibility"
                                iconSize: 20
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }
                }

                // Floating label
                Rectangle {
                    x: 16
                    y: 0
                    width: labelRow.implicitWidth + 8
                    height: 16
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RowLayout {
                        id: labelRow
                        anchors.centerIn: parent
                        spacing: 0
                        StyledText {
                            text: Translation.tr("Password")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }

            // Saved indicator
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: savedRow.implicitHeight + 20
                radius: Appearance.rounding.normal
                color: Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.1)
                border.color: Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.3)
                border.width: 1
                visible: root.isSaved && !root.localConnecting && !(root.targetNetwork && root.targetNetwork.askingPassword)
                RowLayout {
                    id: savedRow
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: 14
                    }
                    spacing: 8
                    MaterialSymbol {
                        text: "verified"
                        iconSize: 18
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("This network is already saved.")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            // Info box
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: infoRow.implicitHeight + 20
                radius: Appearance.rounding.normal
                color: Qt.rgba(Appearance.colors.colPrimaryContainer.r, Appearance.colors.colPrimaryContainer.g, Appearance.colors.colPrimaryContainer.b, 0.2) // 33 hex is 20%
                border.color: Qt.rgba(Appearance.colors.colPrimaryContainer.r, Appearance.colors.colPrimaryContainer.g, Appearance.colors.colPrimaryContainer.b, 0.4) // 66 hex is 40%
                border.width: 1
                visible: root.networkSecurity !== "" && Network.lastWifiError === ""
                RowLayout {
                    id: infoRow
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: 14
                    }
                    spacing: 8
                    MaterialSymbol {
                        text: "lock" // filled lock as per TSX
                        iconSize: 16
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("This network is secured with ") + root.networkSecurity + " encryption"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        wrapMode: Text.Wrap
                    }
                }
            }

            // Error Message
            ColumnLayout {
                Layout.fillWidth: true
                visible: Network.lastWifiError !== "" && !root.localConnecting
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: errorText.contentHeight + 24
                    radius: Appearance.rounding.normal
                    color: Qt.rgba(Appearance.m3colors.m3error.r, Appearance.m3colors.m3error.g, Appearance.m3colors.m3error.b, 0.1)
                    border.color: Appearance.m3colors.m3error
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12
                        MaterialSymbol {
                            text: "error"
                            color: Appearance.m3colors.m3error
                            iconSize: 20
                        }
                        StyledText {
                            id: errorText
                            Layout.fillWidth: true
                            text: Network.lastWifiError
                            color: Appearance.m3colors.m3error
                            font.pixelSize: Appearance.font.pixelSize.small
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }

            // Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                transform: Translate {
                    y: root.show ? 0 : 10
                }
                Behavior on transform {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutQuad
                    }
                }

                RippleButton {
                    id: cancelBtn
                    Layout.fillWidth: true
                    implicitHeight: 50
                    buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer1Base
                    onClicked: root.dismissed()

                    scale: down ? 0.95 : hovered ? 1.02 : 1.0
                    Behavior on scale {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }

                    contentItem: Item {
                        anchors.fill: parent
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 12
                            MaterialSymbol {
                                Layout.alignment: Qt.AlignVCenter
                                text: "close"
                                iconSize: 20
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignVCenter
                                text: Translation.tr("Cancel")
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                    }

                    // Outlined Cancel button
                    Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.full
                        border.color: cancelBtn.hovered ? Appearance.colors.colPrimary : Appearance.m3colors.m3outlineVariant
                        border.width: cancelBtn.hovered ? 2 : 1
                        color: "transparent"
                        Behavior on border.color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }
                        Behavior on border.width {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                    }
                }

                RippleButton {
                    id: connectBtn
                    Layout.fillWidth: true
                    implicitHeight: 50
                    buttonRadius: Appearance.rounding.full

                    readonly property bool canConnect: !root.networkSecured || root.isSaved || passwordField.text.length > 0
                    colBackground: (canConnect || root.localConnecting) ? Appearance.colors.colPrimary : Appearance.colors.colSurfaceContainerHighest
                    colBackgroundHover: (canConnect || root.localConnecting) ? Appearance.colors.colPrimaryHover : Appearance.colors.colLayer2Base

                    scale: down ? 0.95 : (hovered && canConnect) ? 1.02 : 1.0
                    Behavior on scale {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }

                    onClicked: {
                        if (canConnect && !root.localConnecting) {
                            root.localConnecting = true;
                            root.connectRequested(passwordField.text);
                        }
                    }

                    // Solid background logic (shadow removed)
                    Rectangle {
                        id: connectBg
                        anchors.fill: parent
                        radius: Appearance.rounding.full
                        color: connectBtn.colBackground
                        visible: false
                        z: -1
                    }

                    contentItem: Item {
                        anchors.fill: parent
                        RowLayout {
                            anchors.centerIn: parent
                            opacity: (connectBtn.canConnect || root.localConnecting) ? 1.0 : 0.5
                            spacing: 12
                            MaterialSymbol {
                                Layout.alignment: Qt.AlignVCenter
                                text: root.localConnecting ? "autorenew" : "login"
                                iconSize: 20
                                color: (connectBtn.canConnect || root.localConnecting) ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext

                                RotationAnimation on rotation {
                                    from: 0
                                    to: 360
                                    duration: 1000
                                    loops: Animation.Infinite
                                    running: root.localConnecting
                                }
                                Behavior on color {
                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                }
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignVCenter
                                text: root.localConnecting ? Translation.tr("Connecting...") : Translation.tr("Connect")
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: (connectBtn.canConnect || root.localConnecting) ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
                                Behavior on color {
                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
