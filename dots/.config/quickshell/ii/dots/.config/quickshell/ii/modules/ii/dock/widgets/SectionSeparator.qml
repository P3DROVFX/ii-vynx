import QtQuick
import QtQuick.Layouts
import qs.modules.common
import "../"

Item {
    property bool show: true
    visible: show || opacity > 0
    opacity: show ? 1.0 : 0.0
    Layout.alignment: Qt.AlignCenter
    Layout.preferredWidth: root.isVertical ? root.buttonSlotSize : (show ? root.sepThickness : 0)
    Layout.preferredHeight: root.isVertical ? (show ? root.sepThickness : 0) : root.buttonSlotSize
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on Layout.preferredWidth {
        enabled: !root.isVertical
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on Layout.preferredHeight {
        enabled: root.isVertical
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    DockSeparator {
        anchors.fill: parent
    }
}