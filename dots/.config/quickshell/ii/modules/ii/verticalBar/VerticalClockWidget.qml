import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar as Bar

MouseArea {
    id: root
    implicitHeight: clockColumn.implicitHeight + 10
    implicitWidth: Appearance.sizes.verticalBarWidth

    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    ColumnLayout {
        id: clockColumn
        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: DateTime.time.split(/[: ]/)
            delegate: StyledText {
                required property string modelData
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: modelData.match(/am|pm/i) ? Appearance.font.pixelSize.smaller // Smaller "am"/"pm" text
                : Appearance.font.pixelSize.large
                color: Appearance.colors.colOnLayer1
                text: modelData.padStart(2, "0")
            }
        }
    }

    property bool compactMode: Config.options.bar.tooltips.compactPopups

    Loader {
        active: true
        sourceComponent: root.compactMode ? clockPopupCompact : clockPopup
    }
    Component {
        id: clockPopup
        Bar.ClockWidgetPopup {
            hoverTarget: root
        }
    }
    Component {
        id: clockPopupCompact
        Bar.ClockWidgetPopupCompact {
            hoverTarget: root
        }
    }
}
