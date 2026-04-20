import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Rectangle {
    id: root
    property alias text: textField.text
    implicitHeight: 48
    radius: Appearance.rounding.full
    color: Appearance.colors.colLayer1Base
    border.width: 1
    border.color: Appearance.m3colors.m3outlineVariant

    RowLayout {
        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
        spacing: 8

        MaterialSymbol {
            text: "search"
            iconSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colSubtext
            Layout.alignment: Qt.AlignVCenter
        }

        MaterialTextField {
            id: textField
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            placeholderText: Translation.tr("Search for networks...")
            background: Item {} // transparente, remove o estilo default do MaterialTextField
        }
    }
}
