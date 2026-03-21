import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.utils
import qs.modules.common.functions

Item {
    id: root

    property bool isVertical: false

    // ── Sizing — kept in sync with DockAppButton / DockContent ───────────
    readonly property real buttonSize:   Appearance.sizes.dockButtonSize
    readonly property real dotMargin:    (Config.options?.dock.height ?? 60) * 0.2
    readonly property real slotSize:     buttonSize + dotMargin * 2
    readonly property real fixedSlots:   isVertical ? 2.5 : 3
    readonly property real fixedLength:  fixedSlots * slotSize

    // Pill dimensions: strip dotMargin on all sides to match other dock components
    readonly property real pillW:   fixedLength - dotMargin * 2
    readonly property real pillH:   buttonSize
    readonly property real pillPad: Math.round(dotMargin * 0.45)

    // Artwork: proportional to buttonSize, leaving room for the progress ring
    readonly property real artSize:   Math.round(buttonSize * 0.86)
    readonly property real ringW:     Math.max(2, Math.round(artSize  * 0.05))
    readonly property real artMargin: Math.max(2, Math.round(buttonSize * 0.05))
    readonly property real artInner:  artSize - ringW * 2 - artMargin * 2

    // Text and controls
    readonly property real controlSize: Math.round(buttonSize * 0.52)
    readonly property int  textSizeL:   Math.round(buttonSize * (isVertical ? 0.20 : 0.22))
    readonly property int  textSizeS:   Math.round(buttonSize * (isVertical ? 0.17 : 0.18))

    implicitWidth:  isVertical ? slotSize    : fixedLength
    implicitHeight: isVertical ? fixedLength : slotSize

    // ── Player state ──────────────────────────────────────────────────────
    readonly property MprisPlayer currentPlayer: MprisController.activePlayer
    readonly property bool  isPlaying:    currentPlayer?.isPlaying ?? false
    readonly property real  songPosition: currentPlayer?.position  ?? 0
    readonly property real  songLength:   currentPlayer?.length    ?? 0
    readonly property real  songProgress: songLength > 0
        ? Math.min(1.0, songPosition / songLength) : 0.0

    readonly property string finalTitle:  StringUtils.cleanMusicTitle(currentPlayer?.trackTitle) || Translation.tr("Unknown Title")
    readonly property string finalArtist: currentPlayer?.trackArtist || Translation.tr("Unknown Artist")
    readonly property string finalArtUrl: currentPlayer?.trackArtUrl || ""

    // ── Hover state (drives marquee scroll) ───────────────────────────────
    property bool pillHovered: false
    property bool textHovered: false

    // ── Inline component: circular artwork + progress ring ────────────────
    component ArtworkItem: Item {
        id: art
        property bool artHovered: false

        width:  root.artSize
        height: root.artSize

        CircularProgress {
            anchors.fill: parent
            implicitSize: root.artSize
            lineWidth:    root.ringW
            value:        root.songProgress
            colPrimary:   Appearance.colors.colPrimary
            colSecondary: Appearance.colors.colSecondaryContainer
            gapAngle:          0
            animationDuration: 600
        }

        Rectangle {
            id: artRect
            anchors.centerIn: parent
            width:  root.artInner
            height: root.artInner
            radius: width / 2
            color:  Appearance.colors.colPrimaryContainer

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width:  artRect.width
                    height: artRect.height
                    radius: artRect.radius
                }
            }

            Image {
                id: artImg
                anchors.fill: parent
                source:       root.finalArtUrl
                fillMode:     Image.PreserveAspectCrop
                cache:        true
                antialiasing: true
                asynchronous: true
                visible: status === Image.Ready
                opacity: root.isPlaying ? 1.0 : 0.45
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }

        // Fallback icon shown when no artwork is available
        MaterialSymbol {
            anchors.centerIn: artRect
            visible:  artImg.status !== Image.Ready
            text:     "music_note"
            iconSize: root.artInner * 0.48
            color:    Appearance.colors.colPrimary
        }

        // Dark overlay: always visible when paused, appears on hover when playing
        Rectangle {
            anchors.fill:    artRect
            anchors.margins: 0
            radius:  artRect.radius
            color:   "#000000"
            opacity: {
                if (!root.isPlaying) return 0.38
                if (art.artHovered)  return 0.32
                return 0.0
            }
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }

        // Play/pause icon overlaid on the artwork
        MaterialSymbol {
            anchors.centerIn: artRect
            iconSize: root.artInner * 0.44
            fill:  1
            text:  root.isPlaying ? "pause" : "play_arrow"
            color: "white"
            opacity: root.isPlaying ? (art.artHovered ? 1.0 : 0.0) : 1.0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled:    true
            cursorShape:     Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton
            onEntered: art.artHovered = true
            onExited:  art.artHovered = false
            onClicked: root.currentPlayer?.togglePlaying()
        }
    }

    // ── Inline component: scrolling marquee text ──────────────────────────
    component MarqueeText: Item {
        id: marquee
        property string text:       ""
        property int    fontSize:   root.textSizeL
        property int    fontWeight: Font.Normal
        property color  textColor:  Appearance.colors.colOnLayer0
        property bool   running:    false

        clip: true
        implicitHeight: innerText.implicitHeight

        StyledText {
            id: innerText
            text:           marquee.text
            font.pixelSize: marquee.fontSize
            font.weight:    marquee.fontWeight
            color:          marquee.textColor
            elide:          Text.ElideNone
            x:              0

            readonly property bool overflows: implicitWidth > marquee.width + 1
        }

        NumberAnimation {
            id: scrollAnim
            target:   innerText
            property: "x"
            running:  marquee.running && innerText.overflows
            from:     0
            to:       -(innerText.implicitWidth - marquee.width + 20)
            duration: Math.max(3500, (innerText.implicitWidth - marquee.width) * 28)
            easing.type: Easing.Linear
            loops:       Animation.Infinite
            onStopped:   innerText.x = 0
        }
    }

    // ── Inline component: previous / next pill ────────────────────────────
    component TrackPill: Item {
        id: tpill
        property bool vertical: false

        readonly property real btnSize: root.controlSize

        width:  vertical ? btnSize     : btnSize * 2
        height: vertical ? btnSize * 2 : btnSize

        Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.full
            color:  Appearance.colors.colLayer2
        }

        RippleButton {
            id: nextBtn
            width:  tpill.btnSize
            height: tpill.btnSize
            x: vertical ? 0 : tpill.btnSize
            y: 0
            buttonRadius:       Appearance.rounding.full
            colBackground:      "transparent"
            colBackgroundHover: Appearance.colors.colLayer2Hover
            colRipple:          Appearance.colors.colLayer2Active
            onClicked: root.currentPlayer?.next()

            MaterialSymbol {
                anchors.centerIn: parent
                iconSize: tpill.btnSize * 0.62
                text:  "skip_next"
                fill:  1
                color: Appearance.colors.colOnLayer2
            }
        }

        RippleButton {
            id: prevBtn
            width:  tpill.btnSize
            height: tpill.btnSize
            x: 0
            y: vertical ? tpill.btnSize : 0
            buttonRadius:       Appearance.rounding.full
            colBackground:      "transparent"
            colBackgroundHover: Appearance.colors.colLayer2Hover
            colRipple:          Appearance.colors.colLayer2Active
            onClicked: root.currentPlayer?.previous()

            MaterialSymbol {
                anchors.centerIn: parent
                iconSize: tpill.btnSize * 0.62
                text:  "skip_previous"
                fill:  1
                color: Appearance.colors.colOnLayer2
            }
        }
    }

    // ── Main pill ─────────────────────────────────────────────────────────
    Rectangle {
        id: pill
        anchors.centerIn: parent

        width:  isVertical ? root.buttonSize                        : root.pillW
        height: isVertical ? root.fixedLength - root.dotMargin * 2 : root.pillH

        radius:       Appearance.rounding.full
        color:        Appearance.colors.colLayer1
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        clip: true

        HoverHandler {
            onHoveredChanged: {
                root.pillHovered = hovered
                if (hovered) pill.forceActiveFocus()
                else         pill.focus = false
            }
        }

        focus: true

        // ── Horizontal layout ─────────────────────────────────────────────
        Item {
            visible: !root.isVertical
            anchors.fill: parent

            ArtworkItem {
                id: artH
                anchors.left:           parent.left
                anchors.leftMargin:     root.pillPad - root.artMargin
                anchors.verticalCenter: parent.verticalCenter
            }

            TrackPill {
                id: trackH
                vertical: false
                anchors.right:          parent.right
                anchors.rightMargin:    root.pillPad
                anchors.verticalCenter: parent.verticalCenter
            }

            ColumnLayout {
                anchors.left:           artH.right
                anchors.right:          trackH.left
                anchors.leftMargin:     root.pillPad
                anchors.rightMargin:    root.pillPad
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Item {
                    Layout.fillWidth: true
                    implicitHeight: titleH.implicitHeight
                    clip: true
                    MarqueeText {
                        id: titleH
                        width:      parent.width
                        text:       root.finalTitle
                        fontSize:   root.textSizeL
                        fontWeight: Font.DemiBold
                        textColor:  Appearance.colors.colOnLayer0
                        running:    root.pillHovered
                    }
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: artistH.implicitHeight
                    clip: true
                    MarqueeText {
                        id: artistH
                        width:      parent.width
                        text:       root.finalArtist
                        fontSize:   root.textSizeS
                        fontWeight: Font.Normal
                        textColor:  Appearance.colors.colSubtext
                        running:    root.pillHovered
                    }
                }
            }
        }

        // ── Vertical layout ───────────────────────────────────────────────
        Item {
            visible: root.isVertical
            anchors.fill: parent

            ArtworkItem {
                id: artV
                anchors.top:              parent.top
                anchors.topMargin:        root.pillPad - root.artMargin
                anchors.horizontalCenter: parent.horizontalCenter
            }

            TrackPill {
                id: trackV
                vertical: true
                anchors.bottom:           parent.bottom
                anchors.bottomMargin:     root.pillPad
                anchors.horizontalCenter: parent.horizontalCenter
            }

            ColumnLayout {
                anchors.left:             parent.left
                anchors.right:            parent.right
                anchors.leftMargin:       root.pillPad
                anchors.rightMargin:      root.pillPad
                anchors.verticalCenter:   parent.verticalCenter
                // Offset to keep the text visually centered between artwork and controls
                anchors.verticalCenterOffset: Math.round((artV.height - trackV.height) / 2)
                spacing: 2

                MarqueeText {
                    id: titleV
                    Layout.fillWidth: true
                    text:       root.finalTitle
                    fontSize:   root.textSizeL
                    fontWeight: Font.DemiBold
                    textColor:  Appearance.colors.colOnLayer0
                    running:    root.pillHovered
                }

                MarqueeText {
                    id: artistV
                    Layout.fillWidth: true
                    text:       root.finalArtist
                    fontSize:   root.textSizeS
                    fontWeight: Font.Normal
                    textColor:  Appearance.colors.colSubtext
                    running:    root.pillHovered
                }
            }
        }
    }
}
