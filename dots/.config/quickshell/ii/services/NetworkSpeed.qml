pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real downloadSpeed: 0
    property real uploadSpeed: 0
    property real maxSpeed: 100
    property string activeInterface: ""
    property bool monitoring: false

    property real _prevRxBytes: 0
    property real _prevTxBytes: 0
    property bool _hasBaseline: false

    function start(): void {
        monitoring = true
        detectInterface.exec(["sh", "-c", "nmcli -t -f DEVICE,TYPE d status | grep wifi | head -1 | cut -d: -f1"])
    }

    function stop(): void {
        monitoring = false
        pollTimer.running = false
        downloadSpeed = 0
        uploadSpeed = 0
        _hasBaseline = false
    }

    // Detect active wifi interface
    Process {
        id: detectInterface
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: SplitParser {
            onRead: data => {
                root.activeInterface = data.trim()
                if (root.activeInterface.length > 0) {
                    pollTimer.running = true
                }
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            if (root.activeInterface !== "") {
                readStats.exec([
                    "sh", "-c",
                    "cat /sys/class/net/" + root.activeInterface + "/statistics/rx_bytes /sys/class/net/" + root.activeInterface + "/statistics/tx_bytes 2>/dev/null"
                ])
            }
        }
    }

    // read bytes from /sys/class/net/<iface>/statistics/
    Process {
        id: readStats
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n')
                if (lines.length < 2) return
                const rxBytes = parseFloat(lines[0]) || 0
                const txBytes = parseFloat(lines[1]) || 0

                if (root._hasBaseline) {
                    const deltaRx = rxBytes - root._prevRxBytes
                    const deltaTx = txBytes - root._prevTxBytes
                    // Convert bytes/second to Mbps
                    root.downloadSpeed = Math.max(0, (deltaRx * 8) / 1000000)
                    root.uploadSpeed = Math.max(0, (deltaTx * 8) / 1000000)
                    // Adjust max
                    root.maxSpeed = Math.max(root.maxSpeed, root.downloadSpeed, root.uploadSpeed)
                }
                root._prevRxBytes = rxBytes
                root._prevTxBytes = txBytes
                root._hasBaseline = true
            }
        }
    }
}
