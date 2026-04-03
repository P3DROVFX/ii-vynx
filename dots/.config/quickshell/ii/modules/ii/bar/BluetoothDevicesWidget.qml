import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool vertical: false

    readonly property var activeDevices: BluetoothStatus.connectedDevices
    readonly property var primaryDevice: activeDevices.length > 0 ? activeDevices[0] : null
    
    // Hide entirely if no devices are connected
    visible: activeDevices.length > 0

    implicitWidth: visible ? layout.implicitWidth + 16 : 0
    implicitHeight: visible ? Appearance.sizes.barHeight : 0

    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 6

        MaterialSymbol {
            iconSize: Appearance.font.pixelSize.large
            text: root.primaryDevice ? Icons.getBluetoothDeviceMaterialSymbol(root.primaryDevice.icon) : "bluetooth_connected"
            color: Appearance.colors.colOnLayer1
        }

        // Horizontal battery bar
        Item {
            id: batteryContainer
            visible: root.primaryDevice ? root.primaryDevice.batteryAvailable : false
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 12
            Layout.preferredWidth: 26

            // Background of bar
            Rectangle {
                anchors.fill: parent
                radius: 4
                color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.2)
            }

            // Fill
            Rectangle {
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                width: parent.width * (root.primaryDevice ? root.primaryDevice.battery : 0)
                radius: 4
                color: {
                    if (!root.primaryDevice) return Appearance.colors.colPrimary;
                    if (root.primaryDevice.battery <= 0.15) return Appearance.m3colors.m3error;
                    return Appearance.colors.colPrimary;
                }
            }
        }
        
        // Show count if there are multiple devices connected
        StyledText {
            visible: root.activeDevices.length > 1
            text: "+" + (root.activeDevices.length - 1)
            font.pixelSize: Appearance.font.pixelSize.small
            font.family: Appearance.font.family.title
            color: Appearance.colors.colOnLayer1
            font.weight: Font.Bold
            Layout.alignment: Qt.AlignVCenter
        }
    }

    BluetoothDevicesPopup {
        id: popup
        hoverTarget: root
    }
}
