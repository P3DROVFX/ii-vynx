import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Rectangle {
    id: root

    property real value: 0
    property real maxValue: 500
    property string label: "Download"
    property string unit: "Mbps"
    property string iconName: "download"
    property color accentColor: Appearance.colors.colPrimary

    implicitHeight: gaugeCol.implicitHeight + 40
    radius: Appearance.rounding.large
    color: Appearance.colors.colLayer2Base

    ColumnLayout {
        id: gaugeCol
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 20
        }
        spacing: 12

        RowLayout {
            spacing: 8
            MaterialSymbol {
                text: root.iconName
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
            }
            StyledText {
                text: root.label
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
            }
        }

        RowLayout {
            spacing: 4
            StyledText {
                text: root.value < 10 ? root.value.toFixed(1) : Math.round(root.value).toString()
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.Bold
                color: root.accentColor
            }
            StyledText {
                text: root.unit
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 4
            }
        }

        StyledProgressBar {
            Layout.fillWidth: true
            value: root.maxValue > 0 ? (root.value / root.maxValue) : 0
            highlightColor: root.accentColor
            trackColor: Appearance.colors.colLayer2Base
            valueBarHeight: 8
            Behavior on value {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                }
            }
        }
    }
}
