import Qt5Compat.GraphicalEffects
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions

Item {
    id: root
    width: Appearance.sizes.dockButtonSize
    height: Appearance.sizes.dockButtonSize

    property string draggedAppId: ""
    property bool willUnpin: false

    property bool isFile: false
    property bool fileIsImage: false
    property string filePath: ""
    property string fileResolvedIcon: ""

    readonly property string renderType: isFile ? (fileIsImage ? "image" : "file") : "app"

    Loader {
        anchors.fill: parent
        sourceComponent: {
            switch (renderType) {
                case "app": return appComponent
                case "image": return imageComponent
                case "file": return fileComponent
            }
        }
    }

    Component {
        id: appComponent
        Item {
            anchors.fill: parent

            DockIcon {
                anchors.centerIn: parent
                implicitWidth: Appearance.sizes.dockButtonSize
                implicitHeight: Appearance.sizes.dockButtonSize
                appId: root.draggedAppId
                isRunning: true
            }
        }
    }
    
    Component {
        id: imageComponent
        Image {
            id: ghostThumbnail
            anchors.fill: parent
            source: root.fileIsImage ? ("file://" + root.filePath) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: ghostThumbnail.width
                    height: ghostThumbnail.height
                    radius: Appearance.rounding.small
                }
            }

            MaterialSymbol { // fallback symbol
                anchors.centerIn: parent
                visible: ghostThumbnail.status !== Image.Ready
                text: "image"
                iconSize: Appearance.sizes.dockButtonSize / 2
                color: Appearance.colors.colOnLayer0
            } 
        }
    }
    
    Component {
        id: fileComponent
        IconImage {
            anchors.fill: parent
            source: root.fileResolvedIcon
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.ClosedHandCursor
        acceptedButtons: Qt.NoButton
    }
}
