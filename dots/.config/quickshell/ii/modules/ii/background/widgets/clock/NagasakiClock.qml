pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property int implicitSize: 230
    implicitWidth: implicitSize
    implicitHeight: implicitSize

    FontLoader {
        id: nagasakiFont
        source: Directories.home + "/.local/share/fonts/nagasaki.ttf"
    }

    StyledDropShadow {
        target: mainRect
    }

    Rectangle {
        id: mainRect
        anchors.fill: parent
        color: Appearance.colors.colPrimaryContainer
        radius: Appearance.rounding.large
        clip: true

        readonly property string hour: DateTime.time.split(":")[0].padStart(2, "0")
        readonly property string minute: DateTime.time.split(":")[1].split(" ")[0].padStart(2, "0")

        Column {
            anchors.centerIn: parent
            spacing: -35 // Ajuste para aproximar as linhas verticalmente

            // Linha das Horas
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2 // Espaçamento horizontal mínimo entre dígitos

                Text {
                    text: mainRect.hour[0]
                    font.family: nagasakiFont.name
                    font.pixelSize: 130
                    color: Appearance.colors.colPrimary
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    text: mainRect.hour[1]
                    font.family: nagasakiFont.name
                    font.pixelSize: 130
                    color: Appearance.colors.colPrimary
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // Linha dos Minutos
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2

                Text {
                    text: mainRect.minute[0]
                    font.family: nagasakiFont.name
                    font.pixelSize: 130
                    color: Appearance.colors.colSecondary
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    text: mainRect.minute[1]
                    font.family: nagasakiFont.name
                    font.pixelSize: 130
                    color: Appearance.colors.colSecondary
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
