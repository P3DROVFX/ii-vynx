import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root
    property string formattedDate: Qt.locale().toString(DateTime.clock.date, "MMMM dd, dddd")
    property string formattedTime: DateTime.time
    property string formattedUptime: DateTime.uptime
    property string todosSection: getUpcomingTodos(Todo.list)
    property bool todosEmpty: todosSection === ""

    function getUpcomingTodos(todos) {
        const unfinishedTodos = todos.filter(function (item) {
            return !item.done;
        });
        if (unfinishedTodos.length === 0) {
            return "";
        }

        // Limit to first 3 todos
        const limitedTodos = unfinishedTodos.slice(0, 3);
        let todoText = limitedTodos.map(function (item, index) {
            return `  • ${item.content}`;
        }).join('\n');

        if (unfinishedTodos.length > 3) {
            todoText += `\n  ${Translation.tr("... and %1 more").arg(unfinishedTodos.length - 3)}`;
        }

        return todoText;
    }

    function formatTimerDisplay(seconds) {
        let m = Math.floor(seconds / 60);
        let s = seconds % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 12

        // Hero date time card
        Rectangle {
            Layout.fillWidth: true
            Layout.minimumWidth: 320
            implicitHeight: 160
            color: Appearance.colors.colPrimaryContainer
            radius: Appearance.rounding.normal

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                MaterialShape {
                    shapeString: "Cookie9Sided"
                    implicitSize: 96
                    color: Appearance.colors.colPrimary

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "schedule"
                        iconSize: 48
                        color: Appearance.colors.colOnPrimary
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                ColumnLayout {
                    spacing: -8
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                    StyledText {
                        text: root.formattedTime
                        font.pixelSize: Appearance.font.pixelSize.hugeass * 2.5
                        font.family: Appearance.font.family.title
                        font.weight: Font.Black
                        color: Appearance.colors.colOnPrimaryContainer
                        horizontalAlignment: Text.AlignRight
                        Layout.alignment: Qt.AlignRight
                    }

                    StyledText {
                        text: root.formattedDate
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.family: Appearance.font.family.main
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnPrimaryContainer
                        horizontalAlignment: Text.AlignRight
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }
        }

        // 2 middle shapes
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            // Uptime pill
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 64
                radius: 32
                color: Appearance.colors.colSecondaryContainer

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    MaterialShape {
                        shapeString: "Circle"
                        implicitSize: 40
                        color: Appearance.colors.colSecondary

                        CustomIcon {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            source: SystemInfo.distroIcon
                            colorize: true
                            color: Appearance.colors.colOnSecondary
                        }
                    }

                    StyledText {
                        text: root.formattedUptime
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.family: Appearance.font.family.title
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnSecondaryContainer
                    }

                    Item {
                        width: 8
                    }
                }
            }

            // Timer Pill
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 64
                radius: 32 // Full Pill shape
                color: TimerService.pomodoroBreak ? Appearance.colors.colTertiaryContainer : (TimerService.pomodoroRunning || TimerService.stopwatchRunning ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSecondaryContainer)

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    MaterialShape {
                        shapeString: "Circle"
                        implicitSize: 40
                        color: TimerService.pomodoroBreak ? Appearance.colors.colTertiary : (TimerService.pomodoroRunning || TimerService.stopwatchRunning ? Appearance.colors.colPrimary : Appearance.colors.colSecondary)

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: TimerService.pomodoroBreak ? "coffee" : "timer"
                            iconSize: Appearance.font.pixelSize.large
                            color: TimerService.pomodoroBreak ? Appearance.colors.colOnTertiary : (TimerService.pomodoroRunning || TimerService.stopwatchRunning ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondary)
                        }
                    }

                    StyledText {
                        text: TimerService.pomodoroRunning ? root.formatTimerDisplay(TimerService.pomodoroSecondsLeft) : (TimerService.stopwatchRunning ? root.formatTimerDisplay(TimerService.stopwatchTime) : Translation.tr("Timer Off"))
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.family: Appearance.font.family.title
                        font.weight: Font.Bold
                        color: TimerService.pomodoroBreak ? Appearance.colors.colOnTertiaryContainer : (TimerService.pomodoroRunning || TimerService.stopwatchRunning ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSecondaryContainer)
                    }

                    Item {
                        width: 8
                    }
                }
            }
        }

        // To-dos List Card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: todosLayout.implicitHeight + 32
            color: Appearance.colors.colSurfaceContainerHigh
            radius: Appearance.rounding.large

            ColumnLayout {
                id: todosLayout
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    MaterialShape {
                        shapeString: "Slanted"
                        implicitSize: 36
                        color: Appearance.colors.colTertiaryContainer

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "checklist"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnTertiaryContainer
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("To-Do Tasks")
                        font.family: Appearance.font.family.expressive
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnSurface
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 2
                    color: Appearance.colors.colSurfaceContainerHighest
                    radius: 1
                }

                StyledText {
                    visible: !root.todosEmpty
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.Wrap
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnSurfaceVariant
                    text: root.todosSection
                    lineHeight: 1.4
                }

                // using loading indicator on empty state for now
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    visible: root.todosEmpty
                    color: "transparent"

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        MaterialLoadingIndicator {
                            Layout.alignment: Qt.AlignHCenter
                            loading: true
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Translation.tr("No pending tasks")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }
                }
            }
        }
    }
}
