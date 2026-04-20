import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF
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

        // Internal Tab Navigation (Material 3 Expressive)
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: navRow.implicitWidth + 16
            implicitHeight: navRow.implicitHeight + 16
            color: Appearance.colors.colLayer1Base
            radius: Appearance.rounding.full
            
            RowLayout {
                id: navRow
                anchors.centerIn: parent
                spacing: 8
                
                Repeater {
                    model: root.subPages
                    RippleButton {
                        property bool selected: root.currentSubPageIndex === index
                        buttonRadius: Appearance.rounding.full
                        implicitWidth: selected ? 140 : 50
                        implicitHeight: 40
                        colBackground: selected ? Appearance.colors.colPrimaryContainer : "transparent"
                        onClicked: root.currentSubPageIndex = index
                        
                        Behavior on implicitWidth {
                            NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
                        }
                        
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            MaterialSymbol {
                                text: modelData.icon
                                iconSize: 20
                                color: selected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                            StyledText {
                                visible: selected
                                text: modelData.name
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colOnPrimaryContainer
                                opacity: selected ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                            }
                        }
                    }
                }
            }
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
