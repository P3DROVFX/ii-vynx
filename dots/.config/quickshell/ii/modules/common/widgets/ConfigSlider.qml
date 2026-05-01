import qs.modules.common.widgets
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import qs.services

RowLayout {
    id: root
    spacing: 10
    Layout.leftMargin: 8
    Layout.rightMargin: 8
    Layout.fillWidth: true
    Layout.topMargin: 4
    Layout.bottomMargin: 4

    property string text: ""
    property string buttonIcon: ""
    property alias value: slider.value
    property alias stopIndicatorValues: slider.stopIndicatorValues
    property bool usePercentTooltip: true
    property real from: slider.from
    property real to: slider.to
    property alias stepSize: slider.stepSize
    property alias snapMode: slider.snapMode
    property real textWidth: 180

    readonly property string currentSearch: SearchRegistry.currentSearch
    onCurrentSearchChanged: {
        if (SearchRegistry.currentSearch.toLowerCase() === root.text.toLowerCase()) {
            highlightOverlay.startAnimation()
        }
    }

    ColumnLayout {
        RowLayout {
            id: row
            spacing: 10
            Layout.preferredWidth: root.textWidth

            OptionalMaterialSymbol {
                opacity: 1 - highlightOverlay.opacity
                id: iconWidget
                icon: root.buttonIcon
                iconSize: Appearance.font.pixelSize.larger
            }
            StyledText {
                opacity: 1 - highlightOverlay.opacity
                id: labelWidget
                Layout.fillWidth: true
                text: root.text
                color: Appearance.colors.colOnSecondaryContainer
                elide: Text.ElideRight
            }
            HighlightOverlay {
                id: highlightOverlay
                visible: false
            }
        }
        
        StyledSlider {
            id: slider
            configuration: StyledSlider.Configuration.M
            usePercentTooltip: root.usePercentTooltip
            value: root.value
            from: root.from
            to: root.to
            Layout.fillWidth: true
        }
    }
}