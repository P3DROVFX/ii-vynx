import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

import "./widgets"

DockButton {
    id: root

    property int symbolSize: Math.round(root.buttonSize * 0.5)
    property string symbolName: ""
    property color activeColor: Appearance.m3colors.m3onPrimary
    property color inactiveColor: Appearance.colors.colOnLayer0
    property bool dragActive: false
    property string dragSymbol: ""
    property int normalShape: MaterialShape.Shape.Pill
    property int activeShape: MaterialShape.Shape.Cookie9Sided
    property bool dragOver: false
    property string fileDropIcon: ""
    property bool fileDropActive: false
    readonly property bool isDragging: dragActive || fileDropActive

    background.implicitWidth: 0
    background.implicitHeight: 0

    contentItem: Item {
        MaterialShapeWrappedMaterialSymbol {
            id: shapeSymbol
            anchors.centerIn: parent

            shape: root.isDragging ? root.activeShape : root.normalShape

            implicitSize: root.dragOver ? root.buttonSize * 1.1 : root.buttonSize * 0.9
            Behavior on implicitSize {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
            }

            rotation: root.dragOver ? 90 : (root.isDragging ? 45 : 0)
            Behavior on rotation {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            color: {
                if (root.isDragging) {
                    return root.down ? Appearance.colors.colSecondaryContainerActive :
                           root.hovered ? Appearance.colors.colSecondaryContainerHover :
                           Appearance.colors.colSecondaryContainer
                }

                if (root.toggled) {
                    return root.down ? Appearance.colors.colPrimaryActive :
                           root.hovered ? Appearance.colors.colPrimaryHover :
                           Appearance.colors.colPrimary
                }
                return root.down ? Appearance.colors.colLayer1Active :
                       root.hovered ? Appearance.colors.colLayer1Hover :
                       "transparent"
            }

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }

            text: root.fileDropActive ? root.fileDropIcon
                : root.dragActive ? root.dragSymbol
                : root.symbolName

            iconSize: root.isDragging
                ? Math.round(root.buttonSize * 0.4)
                : root.symbolSize
            Behavior on iconSize {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
            }

            colSymbol: root.isDragging
                ? Appearance.colors.colOnSecondaryContainer
                : (root.toggled ? root.activeColor : root.inactiveColor)
            Behavior on colSymbol {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }
}
