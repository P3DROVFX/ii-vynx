import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Quickshell

ContentPage {
    id: root
    forceWidth: true
    
    // Config properties needed by parent usually
    property int index: 5
    property bool register: parent.register ?? false

    property int currentSubPageIndex: 0
    property var subPages: [
        { name: Translation.tr("Network"), icon: "wifi", component: "SystemNetwork.qml" },
        { name: Translation.tr("Bluetooth"), icon: "bluetooth", component: "SystemBluetooth.qml" },
        { name: Translation.tr("Audio"), icon: "volume_up", component: "SystemAudio.qml" },
        { name: Translation.tr("Display"), icon: "monitor", component: "SystemDisplay.qml" }
    ]

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 20

        // Internal Tab Navigation
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 12
            
            Item { Layout.fillWidth: true } // spacer
            
            Repeater {
                model: root.subPages
                RippleButton {
                    property bool selected: root.currentSubPageIndex === index
                    buttonRadius: Appearance.rounding.full
                    implicitWidth: 130
                    implicitHeight: 40
                    colBackground: selected ? Appearance.colors.colPrimary : Appearance.colors.colLayer1Base
                    onClicked: root.currentSubPageIndex = index
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        MaterialSymbol {
                            text: modelData.icon
                            iconSize: 18
                            color: selected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: modelData.name
                            font.weight: selected ? Font.DemiBold : Font.Normal
                            color: selected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                        }
                    }
                }
            }
            
            Item { Layout.fillWidth: true } // spacer
        }

        // Subpage content loader
        Loader {
            id: subLoader
            Layout.fillWidth: true
            source: root.subPages[root.currentSubPageIndex].component
            onStatusChanged: { if (status === Loader.Error) { Quickshell.execDetached(["bash", "-c", "echo Error loading >> /tmp/qs_loader_err.log"]); } else if (status === Loader.Ready) { Quickshell.execDetached(["bash", "-c", "echo Ready loading >> /tmp/qs_loader_err.log"]); } }
            
            SequentialAnimation on opacity {
                id: fadeIn
                running: false
                NumberAnimation { from: 0; to: 1; duration: 200; easing.type: Easing.OutSine }
            }
            
            Connections {
                target: root
                function onCurrentSubPageIndexChanged() {
                    fadeIn.restart()
                }
            }
        }
    }
}
