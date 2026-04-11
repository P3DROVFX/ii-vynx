import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    width: 200; height: 200
    
    Rectangle { anchors.fill: parent; color: "blue" } // Fake panel background

    Item {
        id: base
        width: 100; height: 50; x: 20; y: 20
        visible: false
        Rectangle { anchors.fill: parent; color: "green" }
    }

    Item {
        id: mask
        width: 100; height: 50; x: 20; y: 20
        visible: false
        Rectangle { width: 30; height: 30; x: 80; y: 10; color: "black", radius: 15 } // Overlapping circle
    }

    OpacityMask {
        anchors.fill: base
        source: base
        maskSource: mask
        invert: true
    }
}
