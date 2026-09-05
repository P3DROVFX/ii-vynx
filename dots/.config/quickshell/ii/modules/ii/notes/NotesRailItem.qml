import QtQuick
import QtQuick.Layouts

import qs.modules.common
import qs.modules.common.widgets

/**
 * One place in the rail.
 *
 * The shape follows the Settings sidebar's smart-radius scheme, which is the project's
 * current one: the selected row is a pill, **and so are the edges facing it** on the rows
 * immediately above and below, so the selection appears to press a notch into the group
 * rather than to float in a slot cut out of it. Every pill is capped at the `large` token
 * rather than being fully round — an uncapped `height / 2` on a tall row eats its own
 * corners and leaves crescent gaps against its neighbours.
 */
RippleButton {
    id: root

    property bool expanded: true
    property string symbol: "circle"
    property string label: ""
    property int count: 0
    property bool current: false

    /// Where this row sits in its group, and whether its neighbours are the selected one.
    property bool isFirst: false
    property bool isLast: false
    property bool prevIsCurrent: false
    property bool nextIsCurrent: false

    signal triggered()

    implicitHeight: NotesMetrics.rowHeight
    padding: 0
    toggled: root.current
    colBackground: Appearance.colors.colLayer2
    colBackgroundHover: Appearance.colors.colLayer2Hover
    colBackgroundActive: Appearance.colors.colLayer2Active
    // Selection is secondary, the action above it is primary. The Settings sidebar uses
    // primary for its active row, but nothing sits above that one: here it would have put
    // two large blocks of the same colour against each other, and "where I am" would have
    // shouted as loudly as "make a note".
    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colBackgroundToggledActive: Appearance.colors.colSecondaryContainerActive

    onClicked: root.triggered()

    readonly property real pillRadius: NotesMetrics.pillRadius(root.implicitHeight)
    readonly property bool topIsPill: root.current || root.down || root.prevIsCurrent
    readonly property bool bottomIsPill: root.current || root.down || root.nextIsCurrent

    topLeftRadius: root.topIsPill ? root.pillRadius : (root.isFirst ? NotesMetrics.groupEndRadius : NotesMetrics.groupJoinRadius)
    topRightRadius: root.topLeftRadius
    bottomLeftRadius: root.bottomIsPill ? root.pillRadius : (root.isLast ? NotesMetrics.groupEndRadius : NotesMetrics.groupJoinRadius)
    bottomRightRadius: root.bottomLeftRadius

    Behavior on topLeftRadius {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on bottomLeftRadius {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    readonly property color colText: root.current
        ? Appearance.m3colors.m3onSecondaryContainer
        : Appearance.colors.colOnLayer2

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
                color: root.colText

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
            color: root.colText
        }

        StyledText {
            Layout.rightMargin: NotesMetrics.cardPadding
            text: root.count
            visible: root.expanded && root.count > 0
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: root.current ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colSubtext
            opacity: root.current ? 0.85 : 1
        }
    }

    StyledToolTip {
        text: root.label
        extraVisibleCondition: !root.expanded
    }
}
