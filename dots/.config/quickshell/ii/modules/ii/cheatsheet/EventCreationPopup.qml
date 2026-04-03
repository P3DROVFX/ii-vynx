import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

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
    property string editEventTitle: ""

    // Output
    signal eventCreated(string title, string description, color eventColor)
    signal eventDeleted(string title)
    signal cancelled

    // Preset colors
    readonly property var colorOptions: [Appearance.m3colors.m3primary, Appearance.m3colors.m3secondary, Appearance.m3colors.m3tertiary, Appearance.m3colors.m3error, "#4CAF50"  // Green
        , "#FF9800"  // Orange
        , "#9C27B0"  // Purple
        , "#00BCD4"  // Cyan
        ,]

    property color selectedColor: colorOptions[0]

    function open(startTime, endTime, date, dayIdx, posX, posY) {
        popup.startTimeStr = startTime;
        popup.endTimeStr = endTime;
        popup.eventDate = date;
        popup.dayIndex = dayIdx;
        popup.anchorX = posX;
        popup.anchorY = posY;
        popup.isEditMode = false;
        popup.editEventTitle = "";
        popup.selectedColor = colorOptions[0];
        titleField.text = "";
        descriptionField.text = "";
        popup.visible = true;
        titleField.forceActiveFocus();
    }

    function close() {
        popup.visible = false;
        titleField.text = "";
        descriptionField.text = "";
    }

    // Backdrop — tap outside to dismiss
    MouseArea {
        anchors.fill: parent
        onClicked: {
            popup.cancelled();
            popup.close();
        }
    }

    // Balloon card — positioned near ghost block
    Rectangle {
        id: card
        width: 280
        height: cardContent.implicitHeight + 32

        // Position: try to show to the right of the ghost, otherwise left
        x: {
            let targetX = popup.anchorX + 8;
            if (targetX + width > popup.width)
                targetX = popup.anchorX - width - 8;
            return Math.max(4, Math.min(targetX, popup.width - width - 4));
        }
        y: {
            let targetY = popup.anchorY;
            if (targetY + height > popup.height)
                targetY = popup.height - height - 4;
            return Math.max(4, targetY);
        }

        radius: Appearance.rounding.large
        color: Appearance.colors.colLayer1Base
        border.width: 1
        border.color: Appearance.colors.colLayer1Border
        opacity: popup.visible ? 1 : 0
        scale: popup.visible ? 1 : 0.9

        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        // Prevent clicks on card from closing
        MouseArea {
            anchors.fill: parent
            z: -1
        }

        ColumnLayout {
            id: cardContent
            anchors {
                fill: parent
                margins: 16
            }
            spacing: 10

            // Time chip
            RowLayout {
                spacing: 6

                MaterialSymbol {
                    text: "schedule"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnSurfaceVariant
                }

                StyledText {
                    text: popup.startTimeStr + " — " + popup.endTimeStr
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnSurface
                    Layout.fillWidth: true
                }
            }

            // Title field
            MaterialTextField {
                id: titleField
                Layout.fillWidth: true
                placeholderText: Translation.tr("Event title")
                font.pixelSize: Appearance.font.pixelSize.small

                Keys.onReturnPressed: {
                    if (titleField.text.length > 0) {
                        popup.eventCreated(titleField.text, descriptionField.text, popup.selectedColor);
                        popup.close();
                    }
                }

                Keys.onEscapePressed: {
                    popup.cancelled();
                    popup.close();
                }
            }

            // Description field
            MaterialTextField {
                id: descriptionField
                Layout.fillWidth: true
                placeholderText: Translation.tr("Description (optional)")
                font.pixelSize: Appearance.font.pixelSize.smaller

                Keys.onReturnPressed: {
                    if (titleField.text.length > 0) {
                        popup.eventCreated(titleField.text, descriptionField.text, popup.selectedColor);
                        popup.close();
                    }
                }

                Keys.onEscapePressed: {
                    popup.cancelled();
                    popup.close();
                }
            }

            // Color picker row
            Row {
                spacing: 6
                Layout.alignment: Qt.AlignHCenter

                Repeater {
                    model: popup.colorOptions
                    delegate: Rectangle {
                        width: 24
                        height: 24
                        radius: Appearance.rounding.full
                        color: modelData
                        border.width: popup.selectedColor === modelData ? 2 : 0
                        border.color: Appearance.colors.colOnSurface
                        scale: colorMouse.containsMouse ? 1.2 : 1

                        Behavior on scale {
                            NumberAnimation {
                                duration: 80
                            }
                        }

                        // Checkmark
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "check"
                            font.pixelSize: 14
                            color: ColorUtils.getContrastingTextColor(modelData)
                            visible: popup.selectedColor === modelData
                        }

                        MouseArea {
                            id: colorMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                popup.selectedColor = modelData;
                            }
                        }
                    }
                }
            }

            // Action buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // Delete button (edit mode only)
                RippleButton {
                    visible: popup.isEditMode
                    implicitWidth: 32
                    implicitHeight: 32
                    buttonRadius: Appearance.rounding.full

                    onClicked: {
                        popup.eventDeleted(popup.editEventTitle);
                        popup.close();
                    }

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.normal
                        text: "delete"
                        color: Appearance.m3colors.m3error
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                // Cancel
                DialogButton {
                    buttonText: Translation.tr("Cancel")
                    onClicked: {
                        popup.cancelled();
                        popup.close();
                    }
                }

                // Create
                DialogButton {
                    buttonText: Translation.tr("Create")
                    enabled: titleField.text.length > 0
                    opacity: enabled ? 1 : 0.5
                    onClicked: {
                        popup.eventCreated(titleField.text, descriptionField.text, popup.selectedColor);
                        popup.close();
                    }
                }
            }
        }
    }
}
