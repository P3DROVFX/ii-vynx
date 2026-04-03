import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    required property var taskList
    property string emptyPlaceholderIcon
    property string emptyPlaceholderText
    property int todoListItemSpacing: 5
    property int todoListItemPadding: 8
    property int listBottomPadding: 80

    StyledListView {
        id: listView
        anchors.fill: parent
        spacing: root.todoListItemSpacing
        animateAppearance: false
        model: ScriptModel {
            values: root.taskList
        }
        delegate: Item {
            id: todoItem
            required property var modelData
            property bool pendingDoneToggle: false
            property bool pendingDelete: false
            property bool enableHeightAnimation: false
            
            property bool _optimisticDone: modelData.done
            onModelDataChanged: _optimisticDone = modelData.done

            implicitHeight: todoItemRectangle.implicitHeight
            width: ListView.view.width
            clip: true

            Behavior on implicitHeight {
                enabled: enableHeightAnimation
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }

            Rectangle {
                id: todoItemRectangle
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                implicitHeight: Math.max(48, todoContentRowLayout.implicitHeight + 16)
                
                HoverHandler {
                    id: cellHover
                }
                
                color: cellHover.hovered ? Appearance.colors.colSurfaceContainerHigh : Appearance.colors.colLayer2
                radius: Appearance.rounding.small
                
                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    id: todoContentRowLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 12

                    TodoItemActionButton {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 32
                        implicitHeight: 32
                        onClicked: {
                            todoItem._optimisticDone = !todoItem._optimisticDone;
                            checkIconScaleAnim.restart();
                            
                            if (!todoItem.modelData.done)
                                Todo.markDone(todoItem.modelData.originalIndex);
                            else
                                Todo.markUnfinished(todoItem.modelData.originalIndex);
                        }
                        contentItem: MaterialSymbol {
                            id: checkIcon
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            text: todoItem._optimisticDone ? "check_circle" : "radio_button_unchecked"
                            iconSize: Appearance.font.pixelSize.larger
                            color: todoItem._optimisticDone ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                            
                            Behavior on color { ColorAnimation { duration: 150 } }
                            
                            NumberAnimation {
                                id: checkIconScaleAnim
                                target: checkIcon
                                property: "scale"
                                from: 0.5
                                to: 1.0
                                duration: 400
                                easing.type: Easing.OutBack
                            }
                        }
                    }

                    StyledText {
                        id: todoContentText
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        text: todoItem.modelData.content
                        wrapMode: Text.Wrap
                        color: todoItem._optimisticDone ? Appearance.colors.colOnSurfaceVariant : Appearance.colors.colOnSurface
                        font.strikeout: todoItem._optimisticDone
                    }

                    TodoItemActionButton {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 32
                        implicitHeight: 32
                        opacity: cellHover.hovered ? 1 : 0
                        
                        Behavior on opacity { NumberAnimation { duration: Appearance.animation.elementMoveFast.duration } }
                        
                        onClicked: {
                            Todo.deleteItem(todoItem.modelData.originalIndex);
                        }
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            text: "close"
                            iconSize: Appearance.font.pixelSize.larger
                            color: cellHover.hovered ? Appearance.m3colors.m3error : Appearance.colors.colOnLayer1
                        }
                    }
                }
            }
        }
    }

    Item {
        // Placeholder when list is empty
        visible: opacity > 0
        opacity: taskList.length === 0 ? 1 : 0
        anchors.fill: parent

        Behavior on opacity {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 5

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                iconSize: 55
                color: Appearance.m3colors.m3outline
                text: emptyPlaceholderIcon
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.m3colors.m3outline
                horizontalAlignment: Text.AlignHCenter
                text: emptyPlaceholderText
            }
        }
    }
}