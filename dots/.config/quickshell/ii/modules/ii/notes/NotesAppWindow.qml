pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * The window the notes app lives in.
 *
 * A layer-shell surface covering the screen, with the app drawn as a floating panel in the
 * middle of it and the input mask limited to that panel — so everything outside stays
 * clickable and the compositor dims rather than blocks. The Cheatsheet works exactly this
 * way; a note-taking window that stole every click on the desktop would be a window people
 * close before they use it.
 *
 * Size is remembered, position is not: the panel is centred. A remembered position is a
 * promise the shell cannot keep across a monitor being unplugged, and centring is right
 * every time.
 */
PanelWindow {
    id: root

    signal closeRequested()

    readonly property var state: Persistent.states.notes
    property bool animateIn: false

    /// Comfortable at any size, but not smaller than the three panels can be read at.
    readonly property real minimumWidth: 720
    readonly property real minimumHeight: 480

    readonly property real availableWidth: root.width - Appearance.sizes.elevationMargin * 4
    readonly property real availableHeight: root.height - Appearance.sizes.elevationMargin * 4

    readonly property real panelWidth: root.state.maximized
        ? root.availableWidth
        : Math.max(root.minimumWidth, Math.min(root.state.width, root.availableWidth))
    readonly property real panelHeight: root.state.maximized
        ? root.availableHeight
        : Math.max(root.minimumHeight, Math.min(root.state.height, root.availableHeight))

    visible: true
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "quickshell:notes"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: GlobalStates.notesAppOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Only the panel takes input. Everything around it belongs to whatever is underneath.
    mask: Region {
        item: inputMask
    }

    Item {
        id: inputMask
        anchors.centerIn: parent
        width: root.panelWidth
        height: root.panelHeight
    }

    Timer {
        id: animateInTimer
        interval: 10
        onTriggered: root.animateIn = true
    }

    Timer {
        id: registerGrabTimer
        // A grab registered in the same turn as the window appears catches the click that
        // opened it and closes the window immediately.
        interval: 150
        onTriggered: GlobalFocusGrab.addDismissable(root)
    }

    Connections {
        target: GlobalFocusGrab
        function onDismissed() {
            root.closeRequested();
        }
    }

    Component.onCompleted: {
        animateInTimer.start();
        registerGrabTimer.start();
    }

    Component.onDestruction: {
        registerGrabTimer.stop();
        GlobalFocusGrab.removeDismissable(root);
        // Whatever is still in a debounce belongs to the user, and this object going away
        // is not a reason to lose it.
        NotesService.flush();
    }

    Rectangle {
        id: dim
        anchors.fill: parent
        // Below Hyprland's 0.3 ignore_alpha threshold, so the compositor softens the
        // background instead of blurring it into unreadability.
        color: Qt.rgba(0, 0, 0, 0.25)
        opacity: root.animateIn && GlobalStates.notesAppOpen ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    Item {
        id: wrap
        anchors.centerIn: parent
        width: root.panelWidth
        height: root.panelHeight
        transformOrigin: Item.Center
        scale: root.animateIn && GlobalStates.notesAppOpen ? 1.0 : 0.94
        opacity: root.animateIn && GlobalStates.notesAppOpen ? 1.0 : 0.0

        Behavior on scale {
            NumberAnimation {
                duration: 250
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasized
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 220
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasized
            }
        }

        StyledRectangularShadow {
            target: surface
        }

        Rectangle {
            id: surface
            anchors.fill: parent
            radius: Appearance.rounding.verylarge
            color: Appearance.colors.colLayer0
            clip: true

            NotesAppContent {
                anchors.fill: parent
                focus: true

                onCloseRequested: root.closeRequested()
                onMaximizeToggled: root.state.maximized = !root.state.maximized
            }
        }

        /**
         * The resize grip.
         *
         * One corner rather than eight edges: a layer-shell surface has no compositor
         * chrome to grab, so every edge would need its own hit area drawn over content the
         * user is trying to click. The corner is the affordance people already look for,
         * and the window is centred so it grows in both directions at once.
         */
        MouseArea {
            id: grip
            width: 22
            height: 22
            anchors {
                right: parent.right
                bottom: parent.bottom
            }
            enabled: !root.state.maximized
            visible: enabled
            cursorShape: Qt.SizeFDiagCursor

            property real pressWidth: 0
            property real pressHeight: 0
            property point pressPoint: Qt.point(0, 0)

            onPressed: mouse => {
                grip.pressWidth = root.panelWidth;
                grip.pressHeight = root.panelHeight;
                grip.pressPoint = grip.mapToItem(root.contentItem, mouse.x, mouse.y);
            }

            onPositionChanged: mouse => {
                if (!grip.pressed)
                    return;
                const now = grip.mapToItem(root.contentItem, mouse.x, mouse.y);
                // Doubled: the panel is centred, so it grows by the drag distance at both
                // ends and the corner would otherwise run away from the pointer.
                root.state.width = Math.max(root.minimumWidth,
                    Math.min(root.availableWidth, grip.pressWidth + (now.x - grip.pressPoint.x) * 2));
                root.state.height = Math.max(root.minimumHeight,
                    Math.min(root.availableHeight, grip.pressHeight + (now.y - grip.pressPoint.y) * 2));
            }

            MaterialSymbol {
                anchors.centerIn: parent
                text: "drag_handle"
                rotation: -45
                iconSize: 16
                color: Appearance.colors.colOnLayer1Inactive
                opacity: grip.containsMouse || grip.pressed ? 1 : 0.5
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }

            hoverEnabled: true
        }
    }
}
