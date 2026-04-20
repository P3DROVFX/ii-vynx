import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.services.network

Rectangle {
    id: root
    required property WifiAccessPoint modelData
    property var accessPoint: modelData
    property bool isConnected: accessPoint ? accessPoint.active : false
    property bool expanded: false
    signal connectRequested(var ap)
    signal disconnectRequested()

    readonly property string ssid: accessPoint ? accessPoint.ssid : ""
    readonly property int strength: accessPoint ? accessPoint.strength : 0
    readonly property bool isSecure: accessPoint ? accessPoint.isSecure : false
    readonly property int frequency: accessPoint ? accessPoint.frequency : 0
    readonly property string security: accessPoint ? accessPoint.security : ""

    Layout.fillWidth: true
    implicitHeight: cardCol.implicitHeight
    radius: Appearance.rounding.large
    color: isConnected ? Appearance.colors.colPrimaryContainer : "transparent"
    Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }

    ColumnLayout {
        id: cardCol
        width: parent.width
        spacing: 0

        // Main row
        MouseArea {
            id: mainClickArea
            Layout.fillWidth: true
            implicitHeight: mainRow.implicitHeight + 24
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                if (root.isConnected) {
                    root.expanded = !root.expanded
                } else if (root.isSecure) {
                    root.connectRequested(root.accessPoint)
                } else {
                    root.connectRequested(root.accessPoint)
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: Appearance.rounding.large
                color: mainClickArea.containsMouse ? (root.isConnected ? Qt.rgba(1, 1, 1, 0.05) : Appearance.colors.colLayer1Hover) : "transparent"
                Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
            }

            RowLayout {
                id: mainRow
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 12
                }
                spacing: 14

                // Avatar circle
                Rectangle {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    Layout.alignment: Qt.AlignVCenter
                    radius: Appearance.rounding.normal
                    color: root.isConnected ? Appearance.colors.colPrimary : Appearance.colors.colLayer2Base

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: {
                            if (root.strength > 80) return "signal_wifi_4_bar"
                            if (root.strength > 60) return "network_wifi_3_bar"
                            if (root.strength > 40) return "network_wifi_2_bar"
                            if (root.strength > 20) return "network_wifi_1_bar"
                            return "signal_wifi_0_bar"
                        }
                        iconSize: 22
                        color: root.isConnected ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
                    }
                }

                // Info
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    StyledText {
                        text: root.ssid
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: root.isConnected ? Font.DemiBold : Font.Normal
                        color: root.isConnected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: 4
                        StyledText {
                            visible: root.isConnected
                            text: Translation.tr("Connected") + " •"
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: root.isConnected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                            opacity: 0.8
                        }
                        MaterialSymbol {
                            visible: root.isSecure
                            text: "lock"
                            iconSize: Appearance.font.pixelSize.smaller
                            color: root.isConnected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                            opacity: 0.8
                        }
                        StyledText {
                            text: root.isSecure ? Translation.tr("Secured") : Translation.tr("Open")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: root.isConnected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                            opacity: 0.8
                        }
                        StyledText {
                            visible: root.frequency > 0
                            text: "• " + (root.frequency > 5000 ? "5 GHz" : "2.4 GHz")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: root.isConnected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                            opacity: 0.8
                        }
                    }
                }

                // Connect button (non-connected)
                Rectangle {
                    visible: !root.isConnected
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: connectText.implicitWidth + 36
                    implicitHeight: 32
                    radius: Appearance.rounding.full
                    color: connectBtnArea.containsMouse ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary
                    Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }

                    StyledText {
                        id: connectText
                        anchors.centerIn: parent
                        text: Translation.tr("Connect")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnPrimary
                    }

                    MouseArea {
                        id: connectBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.connectRequested(root.accessPoint)
                    }
                }

                // Chevron
                MaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    text: "chevron_right"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colSubtext
                    rotation: root.expanded ? 90 : 0
                    Behavior on rotation {
                        NumberAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                        }
                    }
                }
            }
        }

        // Expanded details
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.expanded ? expandedRow.implicitHeight + 28 : 0
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.bottomMargin: root.expanded ? 8 : 0
            color: root.isConnected ? Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.1) : Appearance.colors.colLayer2Base
            radius: Appearance.rounding.normal
            clip: true
            opacity: root.expanded ? 1 : 0
            Behavior on Layout.preferredHeight {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                }
            }
            Behavior on opacity {
                NumberAnimation { duration: Appearance.animation.elementMoveFast.duration }
            }

            RowLayout {
                id: expandedRow
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 14
                }
                spacing: 8

                // Speed cell
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: speedCol.implicitHeight + 20
                    radius: Appearance.rounding.normal
                    color: root.isConnected ? Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.15) : Appearance.colors.colLayer2Base

                    ColumnLayout {
                        id: speedCol
                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 10 }
                        spacing: 4
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 4
                            MaterialSymbol { text: "speed"; iconSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext }
                            StyledText { text: Translation.tr("Signal"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext }
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.strength + "%"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.DemiBold
                            color: root.isConnected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                        }
                    }
                }

                // Band cell
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: bandCol.implicitHeight + 20
                    radius: Appearance.rounding.normal
                    color: root.isConnected ? Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.15) : Appearance.colors.colLayer2Base

                    ColumnLayout {
                        id: bandCol
                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 10 }
                        spacing: 4
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 4
                            MaterialSymbol { text: "wifi"; iconSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext }
                            StyledText { text: Translation.tr("Band"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext }
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.frequency > 5000 ? "5 GHz" : "2.4 GHz"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.DemiBold
                            color: root.isConnected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                        }
                    }
                }

                // Security cell
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: secCol.implicitHeight + 20
                    radius: Appearance.rounding.normal
                    color: root.isConnected ? Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.15) : Appearance.colors.colLayer2Base

                    ColumnLayout {
                        id: secCol
                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 10 }
                        spacing: 4
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 4
                            MaterialSymbol { text: "lock"; iconSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext }
                            StyledText { text: Translation.tr("Security"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext }
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.isSecure ? root.security : "None"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.DemiBold
                            color: root.isConnected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                        }
                    }
                }
            }
        }
    }
}
