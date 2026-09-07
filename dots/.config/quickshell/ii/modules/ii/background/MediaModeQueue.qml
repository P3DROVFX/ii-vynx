pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

/**
 * Local playlist surface for Media Mode.
 *
 * The caller owns eligibility: this component must only be instantiated for a
 * local playlist, never for an application MPRIS player or a single file.
 * `queueSnapshot` comes from the helper's authoritative state, so duplicate
 * tracks remain distinct through their entryId even when their metadata ties.
 */
Item {
    id: root

    property var queueSnapshot: ({})
    property bool expanded: true
    property bool lyricsExpanded: true
    property bool lyricsToggleAvailable: true
    property color accentColor: Appearance.colors.colPrimary
    property color accentContainerColor: Appearance.colors.colPrimaryContainer
    property color onAccentContainerColor: Appearance.colors.colOnPrimaryContainer

    readonly property var entries: queueSnapshot?.entries ?? []
    readonly property string currentEntryId: String(queueSnapshot?.currentEntryId ?? "")
    readonly property int currentIndex: {
        for (let i = 0; i < entries.length; ++i) {
            if (String(entries[i]?.entryId ?? "") === currentEntryId)
                return i;
        }
        return -1;
    }
    readonly property bool shuffleActive: Boolean(queueSnapshot?.shuffle ?? false)
    readonly property real headerButtonSize: Appearance.sizes.minimumTouchTarget - Appearance.sizes.elevationMargin
    readonly property real headerHeight: Appearance.sizes.minimumTouchTarget
        + Appearance.sizes.elevationMargin * 2
    implicitHeight: headerHeight

    signal expandedToggled()
    signal lyricsExpandedToggled()

    function centerCurrentTrack() {
        if (root.currentIndex < 0 || root.currentIndex >= root.entries.length)
            return;
        if (!root.expanded || !root.visible || queueList.height <= 0 || queueList.count <= 0)
            return;
        if (queueList.dragging || queueList.moving)
            return;

        queueList.positionViewAtIndex(root.currentIndex, ListView.Center);
    }

    function scheduleCenterCurrentTrack() {
        if (!root.expanded || root.currentIndex < 0)
            return;

        Qt.callLater(function() {
            root.centerCurrentTrack();
        });
        centerTimer.restart();
    }

    Timer {
        id: centerTimer
        interval: 120
        repeat: false
        onTriggered: root.centerCurrentTrack()
    }

    Component.onCompleted: {
        root.scheduleCenterCurrentTrack();
    }

    onCurrentIndexChanged: {
        root.scheduleCenterCurrentTrack();
    }

    onExpandedChanged: {
        if (root.expanded)
            root.scheduleCenterCurrentTrack();
    }

    onVisibleChanged: {
        if (visible && root.expanded)
            root.scheduleCenterCurrentTrack();
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.verylarge
        color: ColorUtils.transparentize(Appearance.colors.colLayer1Base, 0.35)

        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }
        }

        Item {
            id: headerItem
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.headerHeight

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Appearance.sizes.elevationMargin * 2
                anchors.rightMargin: Appearance.sizes.elevationMargin * 2
                spacing: Appearance.sizes.elevationMargin

                MaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    text: "queue_music"
                    iconSize: Appearance.font.pixelSize.large
                    color: root.accentColor
                }

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    text: Translation.tr("Up next")
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.family: Appearance.font.family.title
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer0
                }

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    text: String(root.entries.length)
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colSubtext
                }

                Item {
                    Layout.fillWidth: true
                }

                RippleButton {
                    visible: root.expanded
                    enabled: root.entries.length > 1
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: root.headerButtonSize
                    implicitHeight: root.headerButtonSize
                    buttonRadius: Appearance.rounding.full
                    colBackground: Appearance.colors.colLayer2
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    colBackgroundActive: Appearance.colors.colLayer2Active
                    onClicked: LocalMediaService.clearFutureQueueEntries()

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "playlist_remove"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer2
                    }

                    PopupToolTip {
                        text: Translation.tr("Clear upcoming tracks")
                    }
                }

                RippleButton {
                    visible: root.expanded
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: root.headerButtonSize
                    implicitHeight: root.headerButtonSize
                    buttonRadius: Appearance.rounding.full
                    colBackground: Appearance.colors.colLayer2
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    colBackgroundActive: Appearance.colors.colLayer2Active
                    onClicked: LocalMediaSelection.chooseMusicFiles("append")

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "playlist_add"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer2
                    }

                    PopupToolTip {
                        text: Translation.tr("Add music to queue")
                    }
                }

                RippleButton {
                    visible: root.expanded
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: root.headerButtonSize
                    implicitHeight: root.headerButtonSize
                    buttonRadius: Appearance.rounding.full
                    colBackground: Appearance.colors.colLayer2
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    colBackgroundActive: Appearance.colors.colLayer2Active
                    onClicked: LocalMediaSelection.chooseMusicFolder("append")

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "create_new_folder"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer2
                    }

                    PopupToolTip {
                        text: Translation.tr("Add folder to queue")
                    }
                }

                RippleButton {
                    visible: root.lyricsToggleAvailable
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: root.headerButtonSize
                    implicitHeight: root.headerButtonSize
                    buttonRadius: Appearance.rounding.full
                    colBackground: Appearance.colors.colLayer2
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    colBackgroundActive: Appearance.colors.colLayer2Active
                    onClicked: root.lyricsExpandedToggled()

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.lyricsExpanded ? "lyrics" : "keyboard_arrow_down"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer2
                    }

                    PopupToolTip {
                        text: root.lyricsExpanded ? Translation.tr("Collapse lyrics") : Translation.tr("Expand lyrics")
                    }
                }

                RippleButton {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: root.headerButtonSize
                    implicitHeight: root.headerButtonSize
                    buttonRadius: Appearance.rounding.full
                    colBackground: root.accentContainerColor
                    colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                    colBackgroundActive: Appearance.colors.colPrimaryContainerActive
                    onClicked: root.expandedToggled()

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.expanded ? "keyboard_arrow_down" : "keyboard_arrow_up"
                        iconSize: Appearance.font.pixelSize.large
                        color: root.onAccentContainerColor
                    }

                    PopupToolTip {
                        text: root.expanded ? Translation.tr("Collapse queue") : Translation.tr("Expand queue")
                    }
                }
            }
        }

        Item {
            id: listContainer
            anchors.top: headerItem.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: Appearance.sizes.elevationMargin * 2
            anchors.rightMargin: Appearance.sizes.elevationMargin * 2
            anchors.bottomMargin: Appearance.sizes.elevationMargin * 2
            visible: root.expanded
            opacity: visible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }

                ListView {
                    id: queueList
                    anchors.fill: parent
                    clip: true
                    model: root.entries
                    currentIndex: root.currentIndex
                    spacing: Appearance.sizes.elevationMargin / 2

                    onCountChanged: {
                        if (queueList.count > 0 && root.expanded)
                            root.scheduleCenterCurrentTrack();
                    }

                    onHeightChanged: {
                        if (queueList.height > 0 && root.expanded && !queueList.dragging && !queueList.moving)
                            centerTimer.restart();
                    }

                    delegate: Item {
                        id: queueRow
                        required property int index
                        required property var modelData

                        readonly property var entry: modelData ?? ({})
                        readonly property string entryId: String(entry.entryId ?? "")
                        readonly property bool current: entryId === root.currentEntryId
                        readonly property bool isCurrent: current
                        readonly property bool isFirst: queueRow.index === 0
                        readonly property bool isLast: queueRow.index === root.entries.length - 1
                        readonly property bool aboveCurrent: root.currentIndex !== -1 && queueRow.index === root.currentIndex - 1
                        readonly property bool belowCurrent: root.currentIndex !== -1 && queueRow.index === root.currentIndex + 1
                        readonly property bool rowHovered: rowHoverArea.containsMouse

                        readonly property real rFull: Appearance.rounding.scale === 0 ? 0 : (height / 2)
                        readonly property real rDynamicFull: Appearance.rounding.scale === 0 ? 0 : Math.min(height / 2, Appearance.rounding.large)
                        readonly property real rOuter: Appearance.rounding.scale === 0 ? 0 : Appearance.rounding.large
                        readonly property real rInner: Appearance.rounding.scale === 0 ? 0 : Appearance.rounding.verysmall

                        readonly property real targetTopRadius: isCurrent
                            ? rFull
                            : (rowHovered
                                ? rDynamicFull
                                : (belowCurrent
                                    ? rDynamicFull
                                    : (isFirst ? rOuter : rInner)))

                        readonly property real targetBottomRadius: isCurrent
                            ? rFull
                            : (rowHovered
                                ? rDynamicFull
                                : (aboveCurrent
                                    ? rDynamicFull
                                    : (isLast ? rOuter : rInner)))

                        width: queueList.width
                        height: Math.max(Appearance.sizes.minimumTouchTarget,
                            queueRowContent.implicitHeight + Appearance.sizes.elevationMargin * 2)

                        Rectangle {
                            id: rowBackground
                            anchors.fill: parent
                            topLeftRadius: queueRow.targetTopRadius
                            topRightRadius: queueRow.targetTopRadius
                            bottomLeftRadius: queueRow.targetBottomRadius
                            bottomRightRadius: queueRow.targetBottomRadius
                            color: queueRow.current
                                ? ColorUtils.transparentize(root.accentContainerColor, 0.34)
                                : (queueRow.rowHovered
                                    ? Appearance.colors.colLayer2Hover
                                    : Appearance.colors.colLayer2)

                            Behavior on topLeftRadius {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(rowBackground)
                            }
                            Behavior on topRightRadius {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(rowBackground)
                            }
                            Behavior on bottomLeftRadius {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(rowBackground)
                            }
                            Behavior on bottomRightRadius {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(rowBackground)
                            }
                            Behavior on color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(rowBackground)
                            }
                        }

                        MouseArea {
                            id: rowHoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }

                        RowLayout {
                            id: queueRowContent
                            anchors.fill: parent
                            anchors.margins: Appearance.sizes.elevationMargin
                            spacing: Appearance.sizes.elevationMargin

                            Item {
                                id: artPreviewContainer
                                Layout.preferredWidth: Appearance.sizes.minimumTouchTarget - Appearance.sizes.elevationMargin
                                Layout.preferredHeight: width

                                readonly property real previewRadius: queueRow.current
                                    ? Appearance.rounding.full
                                    : Math.min(width / 2, Math.max(0, Appearance.rounding.scale === 0 ? 0 : (Appearance.rounding.windowRounding - Appearance.sizes.elevationMargin)))

                                Rectangle {
                                    id: artMask
                                    anchors.fill: parent
                                    radius: artPreviewContainer.previewRadius
                                    color: queueRow.current
                                        ? ColorUtils.transparentize(root.accentColor, 0.75)
                                        : Appearance.colors.colLayer3
                                    clip: true

                                    layer.enabled: true
                                    layer.effect: OpacityMask {
                                        maskSource: Rectangle {
                                            width: artMask.width
                                            height: artMask.height
                                            radius: artPreviewContainer.previewRadius
                                        }
                                    }

                                    Image {
                                        id: artThumb
                                        anchors.fill: parent
                                        asynchronous: true
                                        fillMode: Image.PreserveAspectCrop
                                        source: String(queueRow.entry.artUrl ?? "")
                                        visible: status === Image.Ready
                                    }

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        visible: artThumb.status !== Image.Ready
                                        text: queueRow.current ? "graphic_eq" : "music_note"
                                        iconSize: Appearance.font.pixelSize.large
                                        color: queueRow.current ? root.accentColor : Appearance.colors.colOnLayer2
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: artPreviewContainer.previewRadius
                                        color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.4)
                                        visible: opacity > 0
                                        opacity: (artClickArea.containsMouse && !queueRow.current) ? 1 : 0

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: Appearance.animation.elementMoveFast.duration
                                                easing.type: Appearance.animation.elementMoveFast.type
                                                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                            }
                                        }

                                        MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: "play_arrow"
                                            iconSize: Appearance.font.pixelSize.normal
                                            color: Appearance.colors.colOnLayer0
                                        }
                                    }

                                    MouseArea {
                                        id: artClickArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: LocalMediaService.playQueueEntry(queueRow.entryId)
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    Layout.fillWidth: true
                                    text: String(queueRow.entry.title ?? Translation.tr("Untitled"))
                                    elide: Text.ElideRight
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: queueRow.current ? Font.Bold : Font.Medium
                                    color: queueRow.current
                                        ? (ColorUtils.contrastRatio(root.accentColor, Appearance.colors.colLayer1Base) >= 3.0
                                            ? root.accentColor
                                            : ColorUtils.adaptToAccent(Appearance.colors.colOnLayer0, root.accentColor))
                                        : Appearance.colors.colOnLayer2
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: String(queueRow.entry.artist ?? "")
                                        || String(queueRow.entry.album ?? "")
                                        || Translation.tr("Unknown artist")
                                    elide: Text.ElideRight
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: queueRow.current
                                        ? ColorUtils.mix(root.accentColor, Appearance.colors.colSubtext, 0.4)
                                        : Appearance.colors.colSubtext
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: LocalMediaService.playQueueEntry(queueRow.entryId)
                                }
                            }

                            RippleButton {
                                enabled: !root.shuffleActive && queueRow.index > 0
                                implicitWidth: Appearance.sizes.minimumTouchTarget - Appearance.sizes.elevationMargin
                                implicitHeight: implicitWidth
                                buttonRadius: Appearance.rounding.full
                                colBackground: Appearance.colors.colLayer2Hover
                                colBackgroundHover: Appearance.colors.colLayer2Hover
                                colBackgroundActive: Appearance.colors.colLayer2Active
                                onClicked: LocalMediaService.moveQueueEntry(queueRow.entryId, queueRow.index - 1)

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "keyboard_arrow_up"
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer2
                                }
                            }

                            RippleButton {
                                enabled: !root.shuffleActive && queueRow.index < root.entries.length - 1
                                implicitWidth: Appearance.sizes.minimumTouchTarget - Appearance.sizes.elevationMargin
                                implicitHeight: implicitWidth
                                buttonRadius: Appearance.rounding.full
                                colBackground: Appearance.colors.colLayer2Hover
                                colBackgroundHover: Appearance.colors.colLayer2Hover
                                colBackgroundActive: Appearance.colors.colLayer2Active
                                onClicked: LocalMediaService.moveQueueEntry(queueRow.entryId, queueRow.index + 1)

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "keyboard_arrow_down"
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer2
                                }
                            }

                            RippleButton {
                                implicitWidth: Appearance.sizes.minimumTouchTarget - Appearance.sizes.elevationMargin
                                implicitHeight: implicitWidth
                                buttonRadius: Appearance.rounding.full
                                colBackground: queueRow.current ? root.accentColor : Appearance.colors.colLayer2Hover
                                colBackgroundHover: Appearance.colors.colLayer2Hover
                                colBackgroundActive: Appearance.colors.colLayer2Active
                                onClicked: LocalMediaService.playQueueEntry(queueRow.entryId)

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: queueRow.current ? "play_arrow" : "play_circle"
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: queueRow.current ? ColorUtils.getContrastingTextColor(root.accentColor) : Appearance.colors.colOnLayer2
                                }
                            }

                            RippleButton {
                                enabled: root.entries.length > 1
                                implicitWidth: Appearance.sizes.minimumTouchTarget - Appearance.sizes.elevationMargin
                                implicitHeight: implicitWidth
                                buttonRadius: Appearance.rounding.full
                                colBackground: Appearance.colors.colLayer2Hover
                                colBackgroundHover: Appearance.colors.colErrorContainerHover
                                colBackgroundActive: Appearance.colors.colErrorContainerActive
                                onClicked: LocalMediaService.removeQueueEntries([queueRow.entryId])

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "close"
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer2
                                }
                            }
                        }
                    }
                }
            }
        }
}
