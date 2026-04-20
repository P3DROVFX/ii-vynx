import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Rectangle {
    id: root

    property bool wifiEnabled: Network.wifiEnabled
    signal toggled(bool enabled)

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + 24
    radius: Appearance.rounding.large
    color: wifiEnabled ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1Base

    Behavior on color {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }

    RowLayout {
        id: layout
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 16

        // Icon container
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 52
            Layout.preferredHeight: 52
            radius: Appearance.rounding.large
            color: Appearance.colors.colPrimary

            MaterialSymbol {
                anchors.centerIn: parent
                text: "wifi"
                iconSize: 24
                color: Appearance.colors.colOnPrimary
            }
        }

        // Text
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            StyledText {
                text: "Wi-Fi"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.DemiBold
                color: root.wifiEnabled ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }

            StyledText {
                text: {
                    if (!root.wifiEnabled)
                        return "Disabled";
                    const ssid = Network.active ? Network.active.ssid : "";
                    return ssid !== "" ? ("Connected to " + ssid) : "Not connected";
                }
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.wifiEnabled ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                opacity: 0.8
                Layout.fillWidth: true
            }
        }

        // Switch
        StyledSwitch {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 52
            scale: 1.6
            checked: root.wifiEnabled
            onClicked: function () {
                root.toggled(!root.wifiEnabled);
            }
        }
    }
}
