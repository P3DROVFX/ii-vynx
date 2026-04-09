import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material
import qs.modules.common.functions

Item {
    id: popup
    visible: false
    z: 100

    // Input properties
    property string startTimeStr: ""
    property string endTimeStr: ""
    property var eventDate: new Date()
    property int dayIndex: -1

    // Positioning relative to ghost block
    property real anchorX: 0
    property real anchorY: 0

    // Edit mode (for existing events)
    property bool isEditMode: false
    property var editEventData: null

    // Output
    signal eventCreated(string title, string description)
    signal eventUpdated(string oldTitle, string title, string description)
    signal eventDeleted(string title)
    signal cancelled

    function open(startTime, endTime, date, dayIdx, posX, posY) {
        popup.startTimeStr = startTime;
        popup.endTimeStr = endTime;
        popup.eventDate = date;
        popup.dayIndex = dayIdx;
        popup.anchorX = posX;
        popup.anchorY = posY;
        popup.isEditMode = false;
        popup.editEventData = null;
        titleField.text = "";
        descriptionField.text = "";
        popup.visible = true;
        titleField.forceActiveFocus();
    }

    function openForEdit(startTime, endTime, date, dayIdx, posX, posY, eventData) {
        popup.startTimeStr = startTime;
        popup.endTimeStr = endTime;
        popup.eventDate = date;
        popup.dayIndex = dayIdx;
        popup.anchorX = posX;
        popup.anchorY = posY;
        popup.isEditMode = true;
        popup.editEventData = eventData;
        titleField.text = eventData.title || "";
        descriptionField.text = eventData.description || "";
        popup.visible = true;
        titleField.forceActiveFocus();
    }

    function close() {
        popup.visible = false;
        titleField.text = "";
        descriptionField.text = "";
    }

    // Scrim background — blocks all events behind the dialog
    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.small
        color: popup.visible ? Appearance.colors.colScrim : "transparent"
        opacity: popup.visible ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        MouseArea {
            hoverEnabled: true
            anchors.fill: parent
            preventStealing: true
            propagateComposedEvents: false
        }
    }

    // Dialog card
    Rectangle {
        id: card
        width: 320
        height: cardContent.implicitHeight + 48

        // Centered with offset based on anchor
        x: {
            let targetX = popup.anchorX - width / 2;
            return Math.max(16, Math.min(targetX, popup.width - width - 16));
        }
        y: {
            let targetY = popup.anchorY;
            if (targetY + height > popup.height - 16)
                targetY = popup.height - height - 16;
            return Math.max(16, targetY);
        }

        radius: Appearance.rounding.large
        color: Appearance.m3colors.m3surfaceContainerHigh
        opacity: popup.visible ? 1 : 0
        scale: popup.visible ? 1 : 0.92

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on y {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        // Card-level MouseArea: intercepts presses on non-interactive areas
        // (header, margins, separators) so they don't fall through to the scrim.
        // Using z: -1 so it sits behind the ColumnLayout children (TextFields, buttons).
        MouseArea {
            anchors.fill: parent
            z: -1
            onPressed: function(mouse) {
                // Accept the press so the scrim doesn't get it,
                // but immediately give focus back to title field
                mouse.accepted = true;
                titleField.forceActiveFocus();
            }
        }

        ColumnLayout {
            id: cardContent
            anchors {
                fill: parent
                margins: 24
            }
            spacing: 16

            // Header with icon
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    width: 40
                    height: 40
                    radius: Appearance.rounding.full
                    color: Appearance.m3colors.m3primary

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: popup.isEditMode ? "edit_calendar" : "event"
                        font.pixelSize: 20
                        color: Appearance.m3colors.m3onPrimary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        text: popup.isEditMode ? Translation.tr("Edit event") : Translation.tr("New event")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnSurface
                    }

                    RowLayout {
                        spacing: 4

                        MaterialSymbol {
                            text: "schedule"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSurfaceVariant
                        }

                        StyledText {
                            text: popup.startTimeStr + " — " + popup.endTimeStr
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Appearance.colors.colOutlineVariant
            }

            // Title field
            MaterialTextField {
                id: titleField
                Layout.fillWidth: true
                placeholderText: Translation.tr("Event title")
                font.pixelSize: Appearance.font.pixelSize.normal
                focus: popup.visible

                onAccepted: {
                    if (titleField.text.length > 0) {
                        submitEvent();
                    }
                }

                Keys.onEscapePressed: {
                    popup.cancelled();
                    popup.close();
                }
                Keys.onTabPressed: {
                    descriptionField.forceActiveFocus();
                }
            }

            // Description field
            MaterialTextField {
                id: descriptionField
                Layout.fillWidth: true
                placeholderText: Translation.tr("Add description (optional)")

                Keys.onEscapePressed: {
                    popup.cancelled();
                    popup.close();
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Appearance.colors.colOutlineVariant
            }

            // Action buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Delete button (edit mode only)
                RippleButton {
                    visible: popup.isEditMode
                    implicitWidth: 36
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.full
                    buttonColor: ColorUtils.transparentize(Appearance.m3colors.m3errorContainer, 0.5)
                    colBackgroundHover: Appearance.m3colors.m3errorContainer

                    onClicked: {
                        popup.eventDeleted(popup.editEventData.title);
                        popup.close();
                    }

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 18
                        text: "delete"
                        color: Appearance.m3colors.m3error
                    }

                    StyledToolTip {
                        extraVisibleCondition: parent.hovered
                        text: Translation.tr("Delete event")
                    }
                }

                Item { Layout.fillWidth: true }

                // Cancel
                RippleButton {
                    implicitWidth: cancelText.implicitWidth + 24
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.full
                    buttonColor: "transparent"
                    colBackgroundHover: Appearance.colors.colSurfaceContainerHighest

                    onClicked: {
                        popup.cancelled();
                        popup.close();
                    }

                    contentItem: StyledText {
                        id: cancelText
                        anchors.centerIn: parent
                        text: Translation.tr("Cancel")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }

                // Save/Create
                RippleButton {
                    implicitWidth: saveText.implicitWidth + 32
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.full
                    buttonColor: Appearance.colors.colPrimary
                    enabled: titleField.text.length > 0
                    opacity: enabled ? 1 : 0.5

                    onClicked: submitEvent()

                    contentItem: Item {
                        anchors.fill: parent
                        
                        StyledText {
                            id: saveText
                            anchors.centerIn: parent
                            text: popup.isEditMode ? Translation.tr("Save") : Translation.tr("Create")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnPrimary
                        }
                    }
                }
            }
        }
    }

    // Click-to-dismiss: separate MouseArea covering only the scrim area (outside card)
    // This is separate so it doesn't interfere with the card's event handling
    MouseArea {
        anchors.fill: parent
        z: -1  // Behind the card
        onClicked: {
            popup.cancelled();
            popup.close();
        }
    }

    function submitEvent() {
        if (titleField.text.length === 0) return;

        if (popup.isEditMode) {
            popup.eventUpdated(popup.editEventData.title, titleField.text, descriptionField.text);
        } else {
            popup.eventCreated(titleField.text, descriptionField.text);
        }
        popup.close();
    }
}
