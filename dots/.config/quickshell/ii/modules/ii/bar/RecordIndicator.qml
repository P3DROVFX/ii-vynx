import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell


MouseArea {
    id: indicator
    property bool vertical: false

    property bool activelyRecording: Persistent.states.screenRecord.active

    property color colText: Appearance.colors.colOnPrimary

    hoverEnabled: true
    implicitWidth: vertical ? 20 : 80 // we have to enter a fixed size to make it dull 
    implicitHeight: vertical ? 75 : 20

    Component.onCompleted: updateVisibility()
    onActivelyRecordingChanged: updateVisibility()

    function updateVisibility() {
        rootItem.toggleVisible(activelyRecording)
    }

    function formatTime(totalSeconds) {
        let mins = Math.floor(totalSeconds / 60);
        let secs = totalSeconds % 60;
        return String(mins).padStart(2, '0') + ":" + String(secs).padStart(2, '0');
    }

    RippleButton {
        anchors.centerIn: parent
        implicitWidth: indicator.vertical ? 20 : parent.implicitWidth
        implicitHeight: indicator.vertical ? parent.implicitHeight : 20
        colBackgroundHover: "transparent"
        colRipple: "transparent"
        
        onClicked: {
            Quickshell.execDetached(Directories.recordScriptPath)
        }
        StyledPopup {
            hoverTarget: indicator
            contentItem: PopupContent {}
        }
    }

    Loader {
        active: !indicator.vertical
        anchors.centerIn: parent
        sourceComponent: RowLayout {
            id: contentLayout
            anchors.centerIn: parent
            spacing: 4

            MaterialSymbol {
                Layout.bottomMargin: 2
                id: iconIndicator
                z: 1
                text: "screen_record"
                color: indicator.colText
            }
            
            StyledText {
                id: textIndicator                
                Layout.topMargin: 2

                text: indicator.formatTime(Persistent.states.screenRecord.seconds)
                color: indicator.colText
            }
        }
    }

    Loader {
        active: indicator.vertical
        anchors.centerIn: parent
        sourceComponent: ColumnLayout {
            id: contentLayout
            anchors.centerIn: parent
            spacing: 4

            MaterialSymbol {
                Layout.alignment: Text.AlignHCenter
                id: iconIndicator
                text: "screen_record"
                color: indicator.colText
                iconSize: Appearance.font.pixelSize.larger
                horizontalAlignment: Text.AlignHCenter
            }

            StyledText {              
                Layout.alignment: Text.AlignHCenter
                text: indicator.formatTime(Persistent.states.screenRecord.seconds).substring(0,2)
                color: indicator.colText
            }
            
            StyledText {      
                text: indicator.formatTime(Persistent.states.screenRecord.seconds).substring(3,5)
                color: indicator.colText
                Layout.alignment: Text.AlignHCenter
            }

        }
    }
    
    component PopupContent: ColumnLayout {
        anchors.centerIn: parent
        RowLayout {
            MaterialSymbol {
                Layout.bottomMargin: 2
                text: "screen_record"
            }
            StyledText {
                text: Translation.tr("Recording...   %1").arg(indicator.formatTime(Persistent.states.screenRecord.seconds))
            }
        }
        RowLayout {
            MaterialSymbol {
                Layout.bottomMargin: 2
                text: "ads_click"
            }
            StyledText {
                text: Translation.tr("Click to stop the recording")
            }
        }  
    }
    
}