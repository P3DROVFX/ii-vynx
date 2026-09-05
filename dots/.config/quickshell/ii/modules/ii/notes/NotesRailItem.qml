import QtQuick
import QtQuick.Layouts

import qs.modules.common
import qs.modules.common.widgets

/// One place in the rail. A pill when it is where you are, nothing when it is not.
RippleButton {
    id: root

    property bool expanded: true
    property string symbol: "circle"
    property string label: ""
    property int count: 0
    property bool current: false

    signal triggered()

    implicitHeight: 48
    // Full when selected, small otherwise: the shape is what says "here", which survives a
    // theme where the container colour is quiet.
    buttonRadius: root.current ? Appearance.rounding.full : Appearance.rounding.small
    toggled: root.current
    colBackgroundToggled: Appearance.colors.colSecondaryContainer

    onClicked: root.triggered()

    Behavior on buttonRadius {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    contentItem: RowLayout {
        spacing: 12

        Item {
            Layout.preferredWidth: 24
            Layout.leftMargin: root.expanded ? 8 : 0
            Layout.fillHeight: true
            Layout.alignment: root.expanded ? Qt.AlignLeft : Qt.AlignHCenter

            MaterialSymbol {
                anchors.centerIn: parent
                text: root.symbol
                iconSize: 22
                fill: root.current ? 1 : 0
                color: root.current
                    ? Appearance.m3colors.m3onSecondaryContainer
                    : Appearance.colors.colOnLayer1

                Behavior on fill {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: root.label
            visible: root.expanded
            elide: Text.ElideRight
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: root.current ? Font.DemiBold : Font.Normal
            color: root.current
                ? Appearance.m3colors.m3onSecondaryContainer
                : Appearance.colors.colOnLayer1
        }

        StyledText {
            Layout.rightMargin: 14
            text: root.count
            visible: root.expanded && root.count > 0
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: root.current
                ? Appearance.m3colors.m3onSecondaryContainer
                : Appearance.colors.colSubtext
        }
    }

    StyledToolTip {
        text: root.label
        extraVisibleCondition: !root.expanded
    }
}
