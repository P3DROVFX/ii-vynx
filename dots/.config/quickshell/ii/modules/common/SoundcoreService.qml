pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import qs.modules.common
import qs.services

Singleton {
    id: root

    property string currentMode: "Normal"
    property bool isConnected: BluetoothStatus.connectedDevices.some(d => d.name === root.targetDeviceName)
    
    // Q30 device details
    property string targetDeviceName: "Soundcore Life Q30"
    property string macAddress: "E8:EE:CC:96:31:3A"

    readonly property string scriptPath: Quickshell.shellPath("scripts/soundcore/soundcore_anc.sh")
    
    function setMode(mode) {
        Quickshell.execDetached([scriptPath, "set", root.macAddress, mode]);
        // Optimistic update
        currentMode = mode;
    }

    function refreshMode() {
        if (!isConnected) return;
        getProc.command = [scriptPath, "get", root.macAddress];
        getProc.running = true;
    }

    Process {
        id: getProc
        onExited: (code, stdout, stderr) => {
            if (code === 0) {
                let trimmed = stdout.trim();
                if (trimmed.length > 0) {
                    root.currentMode = trimmed;
                }
            }
        }
    }


    onIsConnectedChanged: {
        if (isConnected) {
            refreshMode();
        }
    }
}
