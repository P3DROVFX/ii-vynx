import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models
import qs.services

Item {
    id: root

    property int entranceTrigger: -1
    // Defensive fallback for alternate hosts smaller than the dashboard's
    // fixed 350px bottom group.
    readonly property bool compact: root.height > 0 && root.height < 300
    readonly property bool dense: root.width > 0 && root.width < 260

    property var tabButtonList: [
        {
            "icon": "checklist",
            "name": Translation.tr("Unfinished")
        },
        {
            "name": Translation.tr("Done"),
            "icon": "check_circle"
        }
    ]
    property int selectedTab: Math.max(0, Math.min(root.tabButtonList.length - 1,
        Persistent.states.sidebar.bottomGroup.todoTab))
    /**
     * Canvas views in the AiChat fashion: the FAB does not open a dialog over
     * the list, it swaps the whole surface for a subpage that slides in from
     * the right while the list leaves to the left.
     */
    property string activeView: ""
    readonly property bool viewOpen: root.activeView.length > 0
    readonly property int canvasSlideDistance: Appearance.font.pixelSize.huge * 1.5
    readonly property int canvasContentPadding: root.dense ? 10 : 16
    // 56 is FloatingActionButton's own baseSize; fabSize was never handed to it,
    // so the button was 56 while the list reserved room for 48. Compact scales
    // both buttons by the same 260/350 the bottom group itself lost.
    property int fabSize: root.dense ? 40 : (root.compact ? 42 : 56)
    property int fabMargins: root.dense ? 6 : (root.compact ? 10 : 14)
    property int syncButtonSize: root.dense ? 36 : (root.compact ? 27 : 36)

    function selectTab(index) {
        if (index < 0 || index >= root.tabButtonList.length || root.selectedTab === index)
            return;

        root.selectedTab = index;
        Persistent.states.sidebar.bottomGroup.todoTab = index;
    }

    function closeView() {
        // Clear while the view still exists: the Loader destroys its item the
        // moment activeView flips, so nothing survives to be cleaned after.
        if (canvasViewLoader.item?.clearInput)
            canvasViewLoader.item.clearInput();
        root.activeView = "";
    }

    Keys.onPressed: event => {
        // Open the new-task subpage on "N" (any modifiers)
        // Close the subpage on Esc if open

        if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) && event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageDown)
                tabBar.incrementCurrentIndex();
            else if (event.key === Qt.Key_PageUp)
                tabBar.decrementCurrentIndex();
            event.accepted = true;
        } else if (event.key === Qt.Key_N) {
            root.activeView = "newTask";
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape && root.viewOpen) {
            root.closeView();
            event.accepted = true;
        }
    }

    onActiveViewChanged: {
        // The view already cleared its own input in closeView(); here the
        // focus is handed back to the FAB that opened it.
        if (!root.viewOpen)
            fabButton.focus = true;
    }

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        spacing: 0

        // Same choreography as the AiChat transcript: the list leaves to the
        // left while the subpage enters from the right, so the widget reads
        // as one surface swapping its content.
        opacity: root.viewOpen ? 0 : 1
        visible: opacity > 0.001
        transform: Translate {
            x: root.viewOpen ? -root.canvasSlideDistance : 0

            Behavior on x {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
            }
        }

        Toolbar {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: root.compact ? 44 : 52
            enableShadow: false
            colBackground: Appearance.colors.colSurfaceContainer
            ToolbarTabBar {
                id: tabBar
                tabButtonList: root.tabButtonList
                collapseInactiveLabels: root.dense
                requestOnly: true
                currentIndex: root.selectedTab
                onIndexSelected: root.selectTab(index)
            }
        }

        SwipeView {
            id: swipeView
            property bool initialized: false

            Layout.topMargin: root.compact ? 4 : 10
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10
            clip: true
            currentIndex: root.selectedTab
            Component.onCompleted: initialized = true
            onCurrentIndexChanged: {
                if (initialized && currentIndex !== root.selectedTab)
                    root.selectTab(currentIndex);
            }

            // To Do tab
            Loader {
                active: root.selectedTab === 0
                asynchronous: true
                sourceComponent: TaskList {
                    dense: root.dense
                    listBottomPadding: root.fabSize + root.fabMargins * 2
                    emptyPlaceholderIcon: "check_circle"
                    emptyPlaceholderText: Translation.tr("Nothing here!")
                    entranceTrigger: root.entranceTrigger
                    taskList: Todo.list.map(function (item, i) {
                        return Object.assign({}, item, {
                            "originalIndex": i
                        });
                    }).filter(function (item) {
                        return !item.done;
                    }).sort(function (a, b) {
                        if (a.hasDate && !b.hasDate)
                            return -1;
                        if (!a.hasDate && b.hasDate)
                            return 1;
                        if (a.hasDate && b.hasDate)
                            return a.date - b.date;
                        return b.originalIndex - a.originalIndex;
                    })
                }
            }

            Loader {
                active: root.selectedTab === 1
                asynchronous: true
                sourceComponent: TaskList {
                    dense: root.dense
                    listBottomPadding: root.fabSize + root.fabMargins * 2
                    emptyPlaceholderIcon: "checklist"
                    emptyPlaceholderText: Translation.tr("Finished tasks will go here")
                    entranceTrigger: root.entranceTrigger
                    taskList: Todo.list.map(function (item, i) {
                        return Object.assign({}, item, {
                            "originalIndex": i
                        });
                    }).filter(function (item) {
                        return item.done;
                    }).sort(function (a, b) {
                        if (a.hasDate && !b.hasDate)
                            return -1;
                        if (!a.hasDate && b.hasDate)
                            return 1;
                        if (a.hasDate && b.hasDate)
                            return b.date - a.date;
                        return b.originalIndex - a.originalIndex;
                    })
                }
            }
        }
    }

    // Provider sync / status indicator
    RippleButton {
        id: syncButton
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.fabMargins
        anchors.bottomMargin: root.fabMargins
        implicitWidth: root.syncButtonSize
        implicitHeight: root.syncButtonSize
        buttonRadius: Appearance.rounding.full
        opacity: root.viewOpen ? 0 : 1
        visible: opacity > 0.001

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
            }
        }

        onClicked: {
            if (Todo.remoteEnabled && Todo.connected) {
                Todo.refresh();
            } else {
                GlobalStates.openSettingsPage("tasksAccounts");
            }
        }

        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            text: {
                if (!Todo.remoteEnabled) {
                    return "save";
                }
                if (!Todo.connected) {
                    return "cloud_off";
                }
                return Todo.syncing ? "sync" : "cloud_done";
            }
            font.pixelSize: root.dense
                ? Appearance.font.pixelSize.normal
                : (root.compact ? Appearance.font.pixelSize.smallie : Appearance.font.pixelSize.larger)
            color: {
                if (!Todo.remoteEnabled) {
                    return Appearance.colors.colOnSurfaceVariant;
                }
                if (!Todo.connected) {
                    return Appearance.colors.colOnSurfaceVariant;
                }
                return Todo.syncing ? Appearance.colors.colPrimary : Appearance.colors.colPrimary;
            }
            opacity: (!Todo.remoteEnabled || Todo.connected) ? 1.0 : 0.4

            RotationAnimation on rotation {
                running: Todo.remoteEnabled && Todo.syncing
                from: 360
                to: 0
                duration: 1000
                loops: Animation.Infinite
            }
        }

        StyledToolTip {
            text: {
                if (Todo.provider === "local") {
                    return Translation.tr("Tasks are stored locally.");
                }
                if (!Todo.connected) {
                    return Todo.providerName + " · " + Translation.tr("Not connected. Click to setup.");
                }
                if (Todo.syncing) {
                    return Todo.providerName + " · " + Translation.tr("Syncing...");
                }
                return Todo.providerName + " · " + Translation.tr("Synced");
            }
        }
    }

    // + FAB
    StyledRectangularShadow {
        target: fabButton
        radius: fabButton.buttonRadius
        blur: 0.6 * Appearance.sizes.elevationMargin
    }

    FloatingActionButton {
        id: fabButton

        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: root.fabMargins
        anchors.bottomMargin: root.fabMargins
        baseSize: root.fabSize
        iconSize: root.compact ? 20 : 26
        opacity: root.viewOpen ? 0 : 1
        visible: opacity > 0.001

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
            }
        }

        onClicked: root.activeView = "newTask"
        iconText: "add"
    }

    /**
     * The subpage shell. Built once per opening and then only swaps what it
     * holds, like ChatControlBar's canvas view: no scrim, nothing anchored —
     * the view slides in from the right over the faded list.
     */
    Loader {
        id: canvasViewLoader
        anchors.fill: parent
        z: 100
        active: root.viewOpen

        sourceComponent: Item {
            id: canvasView

            function clearInput() {
                newTaskInput.text = "";
            }

            function addTask() {
                if (newTaskInput.text.length > 0) {
                    Todo.addTask(newTaskInput.text);
                    newTaskInput.text = "";
                    root.selectTab(0); // Show unfinished tasks
                    root.closeView();
                }
            }

            opacity: 0
            transform: Translate {
                id: canvasViewTransform
                x: root.canvasSlideDistance
            }

            Component.onCompleted: {
                canvasViewEnter.start();
                newTaskInput.forceActiveFocus();
            }

            ParallelAnimation {
                id: canvasViewEnter

                NumberAnimation {
                    target: canvasView
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
                }

                NumberAnimation {
                    target: canvasViewTransform
                    property: "x"
                    from: root.canvasSlideDistance
                    to: 0
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: Appearance.rounding.small
                color: Appearance.colors.colSurfaceContainer
            }

            MouseArea {
                // The list is still behind this view during the cross fade;
                // without this it would take the clicks meant for the page.
                anchors.fill: parent
                onWheel: wheel => wheel.accepted = true
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.canvasContentPadding
                spacing: root.canvasContentPadding

                // One header, one way out: the back button closes the view,
                // mirroring the canvas views of the AI sidebar.
                RowLayout {
                    Layout.fillWidth: true
                    spacing: root.canvasContentPadding

                    RippleButton {
                        implicitWidth: root.fabSize
                        implicitHeight: root.fabSize
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.colors.colSurfaceContainerHighest
                        colBackgroundHover: Appearance.colors.colSurfaceContainerHighestHover
                        colBackgroundActive: Appearance.colors.colSurfaceContainerHighestActive

                        onClicked: root.closeView()

                        contentItem: Item {
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "arrow_back"
                                iconSize: root.compact ? 20 : 24
                                color: Appearance.colors.colOnSurface
                            }
                        }

                        StyledToolTip {
                            text: Translation.tr("Back to tasks")
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Add task")
                        font.pixelSize: Appearance.font.pixelSize.larger
                        font.bold: true
                        color: Appearance.colors.colOnLayer1
                        elide: Text.ElideRight
                    }
                }

                TextField {
                    id: newTaskInput

                    Layout.fillWidth: true
                    padding: 12
                    color: activeFocus ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3onSurfaceVariant
                    renderType: Text.NativeRendering
                    selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
                    selectionColor: Appearance.colors.colSecondaryContainer
                    placeholderText: Translation.tr("Task description")
                    placeholderTextColor: Appearance.m3colors.m3outline
                    wrapMode: TextEdit.NoWrap
                    onAccepted: canvasView.addTask()

                    background: Rectangle {
                        anchors.fill: parent
                        radius: Math.min(height / 2, Appearance.rounding.large)
                        color: newTaskInput.activeFocus
                            ? Appearance.colors.colPrimaryContainer
                            : Appearance.m3colors.m3surfaceContainerHighest
                    }

                    cursorDelegate: Rectangle {
                        width: 1
                        color: newTaskInput.activeFocus ? Appearance.colors.colPrimary : "transparent"
                        radius: 1
                    }

                    StyledTextContextMenu {
                        id: todoContextMenu
                        targetField: newTaskInput
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.IBeamCursor
                        acceptedButtons: Qt.RightButton
                        onPressed: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                newTaskInput.forceActiveFocus();
                                todoContextMenu.popup(mouse.x, mouse.y);
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }

            StyledRectangularShadow {
                target: saveFab
                radius: saveFab.buttonRadius
                blur: 0.6 * Appearance.sizes.elevationMargin
            }

            // Save is a FAB in the same spot the create FAB occupies, so the
            // button the user pressed to get here is the button that commits.
            FloatingActionButton {
                id: saveFab

                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: root.fabMargins
                anchors.bottomMargin: root.fabMargins
                baseSize: root.fabSize
                iconSize: root.compact ? 20 : 26
                enabled: newTaskInput.text.length > 0
                onClicked: canvasView.addTask()
                iconText: "check"
            }
        }
    }
}
