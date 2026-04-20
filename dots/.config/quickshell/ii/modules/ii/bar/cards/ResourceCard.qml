import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

SectionCard {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredWidth: 180
    showDivider: false

    property string resourceName: ""
    property string resourceValueText: ""
    property real resourcePercentage: 0
    property color highlightColor: Appearance.colors.colPrimary

    // Expose extra content below the progress bar
    default property alias extraContent: extraColumn.data

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: root.resourceName
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnSurfaceVariant
            }
            Item {
                Layout.fillWidth: true
            }
            StyledText {
                text: root.resourceValueText
                font.weight: Font.DemiBold
            }
        }

        StyledProgressBar {
            visible: root.resourcePercentage >= 0
            Layout.fillWidth: true
            value: root.resourcePercentage
            highlightColor: root.highlightColor
        }

        ColumnLayout {
            id: extraColumn
            visible: root.extraContent.length > 0
            Layout.fillWidth: true
            Layout.topMargin: parent.spacing * 2
            spacing: 12
        }
    }
}
