import QtQuick
import qs.modules.common
import qs.modules.common.widgets

MaterialShape {
    id: root
    property alias text: symbol.text
    property alias iconSize: symbol.iconSize
    property alias font: symbol.font
    property alias colSymbol: symbol.color
    property alias fill: symbol.fill
    property alias animateChange: symbol.animateChange
    property real padding: 8

    color: Appearance.colors.colSecondaryContainer
    colSymbol: Appearance.colors.colOnSecondaryContainer
    shape: MaterialShape.Shape.Clover4Leaf
    implicitSize: iconSize + padding * 2

    Behavior on rotation {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    MaterialSymbol {
        id: symbol
        anchors.centerIn: parent
        color: root.colSymbol
        width: root.iconSize
        height: root.iconSize
        rotation: 360 - root.rotation
    }
}
