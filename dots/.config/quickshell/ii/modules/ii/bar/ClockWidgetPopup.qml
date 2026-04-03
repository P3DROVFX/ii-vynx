import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root
    property string formattedDate: Qt.locale().toString(DateTime.clock.date, "dd MMMM, dddd")
    property string formattedTime: DateTime.time
    property string formattedUptime: DateTime.uptime
    property string todosSection: getUpcomingTodos()

    function getUpcomingTodos() {
        const unfinishedTodos = Todo.list.filter(function (item) {
            return !item.done;
        });
        if (unfinishedTodos.length === 0) {
            return Translation.tr("No pending tasks");
        }

        // Limit to first 3 todos to keep popup manageable and visually clean
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

        // Large Expressive Time & Date Card
        Rectangle {
            Layout.fillWidth: true
            Layout.minimumWidth: 320
            implicitHeight: 160
            color: Appearance.colors.colPrimaryContainer
            radius: Appearance.rounding.large

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
                } // Spacer

                ColumnLayout {
                    spacing: -8
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                    StyledText {
                        text: root.formattedTime
                        font.pixelSize: Appearance.font.pixelSize.hugeass * 2.5
                        font.family: Appearance.font.family.title
                        font.weight: Font.Black
                        color: Appearance.colors.colOnSurface
                        horizontalAlignment: Text.AlignRight
                        Layout.alignment: Qt.AlignRight
                    }

                    StyledText {
                        text: root.formattedDate
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.family: Appearance.font.family.main
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnSurface
                        horizontalAlignment: Text.AlignRight
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }
        }

        // Quick info stack
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            // Uptime pill
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 64
                radius: 32 // Full Pill shape
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
                    } // Small padding on the right for symmetry
                }
            }

            // Timer Pill
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 64
                radius: 32 // Full Pill shape
                color: TimerService.pomodoroBreak ? Appearance.colors.colTertiaryContainer : Appearance.colors.colSecondaryContainer

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    MaterialShape {
                        shapeString: "Circle"
                        implicitSize: 40
                        color: TimerService.pomodoroBreak ? Appearance.colors.colTertiary : Appearance.colors.colPrimary

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: TimerService.pomodoroBreak ? "coffee" : "timer"
                            iconSize: Appearance.font.pixelSize.large
                            color: TimerService.pomodoroBreak ? Appearance.colors.colOnTertiary : Appearance.colors.colOnPrimary
                        }
                    }

                    StyledText {
                        text: TimerService.pomodoroRunning ? root.formatTimerDisplay(TimerService.pomodoroSecondsLeft) : Translation.tr("Timer Off")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.family: Appearance.font.family.title
                        font.weight: Font.Bold
                        color: TimerService.pomodoroBreak ? Appearance.colors.colOnTertiaryContainer : Appearance.colors.colOnSecondaryContainer
                    }

                    Item {
                        width: 8
                    } // Small padding on the right for symmetry
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
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.Wrap
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnSurfaceVariant
                    text: root.todosSection
                    lineHeight: 1.4
                }
            }
        }
    }
}
