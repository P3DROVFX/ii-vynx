import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import Quickshell.Io

MouseArea {
    id: indicator
    property bool vertical: false

    implicitWidth: 40
    implicitHeight: Appearance.sizes.barHeight

    property bool activelyScreenSharing: false
    
    hoverEnabled: true

    Process {
        id: screenShareProc
        running: true
        command: ["bash", "-c", Directories.screenshareStateScript]
    }
    
    FileView {
        id: stateFile
        path: Directories.screenshareStatePath
        watchChanges: true
        onFileChanged: this.reload()
        onLoaded: {
            indicator.activelyScreenSharing = !stateFile.text().trim().toLowerCase().includes("none")
            rootItem.toggleVisible(indicator.activelyScreenSharing)
        }
    }

    MaterialSymbol {
        id: iconIndicator
        z: 1
        text: "cast"
        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        color: Appearance.colors.colOnPrimary
        font.pixelSize: Appearance.font.pixelSize.huge
    }

    StyledPopup {
        hoverTarget: indicator
        contentItem: ColumnLayout {
            anchors.centerIn: parent
            RowLayout {
                MaterialSymbol {
                    Layout.bottomMargin: 2
                    text: "cast"
                }
                StyledText {
                    text: Translation.tr("**%1** is using your screen").arg(stateFile.text().trim())
                    textFormat: Text.MarkdownText
                }
            }
            
        }
    }
}