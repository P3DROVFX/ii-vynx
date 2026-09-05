import QtQuick
import QtQuick.Layouts

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.notes

/// One place in the rail. A pill when it is where you are, nothing when it is not.
RippleButton {
    id: root

    property bool expanded: true
    property string symbol: "circle"
    property string label: ""
    property int count: 0
    property bool current: false
    /// Where this row sits in its group, which is what shapes its corners.
    property bool isFirst: false
    property bool isLast: false

    signal triggered()

    implicitHeight: NotesMetrics.rowHeight
    padding: 0
    toggled: root.current
    colBackground: Appearance.m3colors.m3surfaceContainerHighest
    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover

    onClicked: root.triggered()

    /**
     * A stack of rows reads as one group, and the selected one steps out of it.
     *
     * The group is shaped at its ends only — a large corner at the top of the first row
     * and the bottom of the last, tiny ones everywhere the rows meet — and whichever row
     * you are on rounds fully. It is the Cheatsheet's mail sidebar, and it is what lets a
     * list be divided into groups without drawing a single line.
     */
    readonly property real groupEndRadius: Appearance.rounding.large
    readonly property real groupJoinRadius: Appearance.rounding.verysmall
    readonly property real activeRadius: Appearance.rounding.full

    topLeftRadius: root.current ? root.activeRadius : (root.isFirst ? root.groupEndRadius : root.groupJoinRadius)
    topRightRadius: root.topLeftRadius
    bottomLeftRadius: root.current ? root.activeRadius : (root.isLast ? root.groupEndRadius : root.groupJoinRadius)
    bottomRightRadius: root.bottomLeftRadius

    Behavior on topLeftRadius {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on bottomLeftRadius {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    contentItem: RowLayout {
        spacing: 0

        Item {
            // The icon sits on the same centre whether the rail is open or shut, so
            // collapsing the rail does not shuffle every glyph sideways.
            Layout.preferredWidth: NotesMetrics.rowHeight
            Layout.fillWidth: !root.expanded
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignLeft

            MaterialSymbol {
                anchors.centerIn: parent
                text: root.symbol
                iconSize: 22
                fill: root.current ? 1 : 0
                color: root.current
                    ? Appearance.m3colors.m3onSecondaryContainer
                    : Appearance.colors.colOnSurfaceVariant

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
                : Appearance.colors.colOnSurfaceVariant
        }

        StyledText {
            Layout.rightMargin: NotesMetrics.cardPadding
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
