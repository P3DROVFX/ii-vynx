import qs
import qs.services
import qs.services.network
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

WindowDialog {
    id: root
    backgroundHeight: 600

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        
        // Icon with rounded background
        Rectangle {
            width: 24
            height: 24
            radius: 6
            color: Appearance.colors.colPrimaryContainer
            
            MaterialSymbol {
                anchors.centerIn: parent
                iconSize: 16
                text: "wifi"
                color: Appearance.colors.colOnPrimaryContainer
            }
        }
        
        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Connect to Wi-Fi")
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.Bold
            color: Appearance.colors.colOnLayer1
        }
        
        StyledSwitch {
            checked: Network.wifiStatus !== "disabled"
            onToggled: Network.toggleWifi()
        }
    }

    StyledIndeterminateProgressBar {
        visible: Network.wifiScanning
        Layout.fillWidth: true
        Layout.topMargin: -4
        Layout.bottomMargin: -4
    }

    StyledListView {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 8
        Layout.leftMargin: -Appearance.rounding.large
        Layout.rightMargin: -Appearance.rounding.large
        visible: Network.wifiStatus !== "disabled" && Network.friendlyWifiNetworks.length > 0

        clip: true
        spacing: 4
        animateAppearance: false

        model: ScriptModel {
            values: Network.friendlyWifiNetworks
        }
        delegate: WifiNetworkItem {
            required property WifiAccessPoint modelData
            required property int index
            wifiNetwork: modelData
            isFirst: index === 0
            isLast: index === ListView.view.count - 1

            anchors {
                left: parent?.left
                right: parent?.right
                leftMargin: Appearance.rounding.large
                rightMargin: Appearance.rounding.large
            }
        }
    }
    
    PagePlaceholder {
        Layout.fillHeight: true
        Layout.fillWidth: true
        icon: "wifi_off"
        title: Translation.tr("Wi-Fi is off")
        description: Translation.tr("Turn on Wi-Fi to see networks")
        shape: MaterialShape.Shape.Cookie7Sided
        shown: Network.wifiStatus === "disabled"
    }

    PagePlaceholder {
        Layout.fillHeight: true
        Layout.fillWidth: true
        icon: "wifi_find"
        title: Translation.tr("No networks found")
        shape: MaterialShape.Shape.Cookie7Sided
        shown: Network.wifiStatus !== "disabled" && Network.friendlyWifiNetworks.length === 0 && !Network.wifiScanning
    }

    WindowDialogSeparator {}
    WindowDialogButtonRow {
        DialogButton {
            buttonText: Translation.tr("Details")
            onClicked: {
                Quickshell.execDetached(["bash", "-c", `${Network.ethernet ? Config.options.apps.networkEthernet : Config.options.apps.network}`]);
                GlobalStates.sidebarRightOpen = false;
            }
        }

        Item {
            Layout.fillWidth: true
        }

        DialogButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
}