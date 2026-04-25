import QtQuick
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.functions

ScrollBar {
    id: root

    property color thumbColor: Appearance.colors.colOnSurfaceVariant
    property color trackColor: Qt.rgba(thumbColor.r, thumbColor.g, thumbColor.b, 0.25)
    property real trackGap: 6
    property real barWidth: 6

    policy: ScrollBar.AsNeeded
    topPadding: Appearance.rounding.normal
    bottomPadding: Appearance.rounding.normal
    active: hovered || pressed

    background: Item {
        implicitWidth: root.barWidth
        opacity: root.contentItem.opacity

        // Top track
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.barWidth
            y: root.topPadding
            height: Math.max(0, root.contentItem.y - y - root.trackGap)
            color: root.trackColor
            radius: width / 2
            visible: height > 0
        }

        // Bottom track
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.barWidth
            property real startY: root.contentItem.y + root.contentItem.height + root.trackGap
            y: Math.min(root.height - root.bottomPadding, startY)
            height: Math.max(0, root.height - root.bottomPadding - y)
            color: root.trackColor
            radius: width / 2
            visible: height > 0
        }
    }

    contentItem: Item {
        implicitWidth: root.barWidth
        implicitHeight: root.visualSize

        opacity: root.policy === ScrollBar.AlwaysOn || (root.active && root.size < 1.0) ? 0.8 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 350
                easing.type: Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            width: root.hovered || root.pressed ? root.barWidth * 4 : root.barWidth
            color: root.thumbColor

            // Keep right side small
            topRightRadius: root.barWidth / 2
            bottomRightRadius: root.barWidth / 2

            // expand left side
            topLeftRadius: root.hovered || root.pressed ? Appearance.rounding.large : root.barWidth / 2
            bottomLeftRadius: root.hovered || root.pressed ? Appearance.rounding.large : root.barWidth / 2

            Behavior on width {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on topLeftRadius {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on bottomLeftRadius {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: -4
                opacity: root.hovered || root.pressed ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }
                }

                MaterialSymbol {
                    text: "expand_less"
                    iconSize: 20
                    color: Appearance.colors.colLayer0
                }
                MaterialSymbol {
                    text: "expand_more"
                    iconSize: 20
                    color: Appearance.colors.colLayer0
                }
            }
        }
    }
}
