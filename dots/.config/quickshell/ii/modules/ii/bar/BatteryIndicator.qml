import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property var chargeState: Battery.chargeState
    readonly property bool isCharging: Battery.isCharging
    readonly property bool isPluggedIn: Battery.isPluggedIn
    readonly property real percentage: Battery.percentage
    readonly property bool isLow: percentage <= Config.options.battery.low / 100

    implicitWidth: batteryContainer.width + 12
    implicitHeight: Appearance.sizes.barHeight

    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    Item {
        id: batteryContainer
        anchors.centerIn: parent
        height: 14
        width: height * (28 / 13)

        // Camada 1: Preenchimento
        Item {
            id: fillClipping
            clip: true
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left

            // O width define a "linha de corte".
            width: parent.width * root.percentage
            z: 0

            // Preenchimento Sólido (O "Líquido" da bateria)
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left

                // Padding interno visual (Aumentado para 3)
                anchors.leftMargin: 3

                height: parent.height - 6 // Padding vertical (3 em cima, 3 em baixo)
                width: (parent.width * (24 / 28)) - 6 // Largura total da área interna menos padding

                radius: 2 // Borda (Raio) aumentado
                color: root.isLow && !root.isCharging ? Appearance.m3colors.m3error : Appearance.colors.colOnSecondaryContainer
            }
        }

        // Camada 2: Moldura (Por cima de tudo)
        CustomIcon {
            anchors.fill: parent
            source: "Battery.svg"
            colorize: true
            color: root.isLow && !root.isCharging ? Appearance.m3colors.m3error : Appearance.colors.colOnSecondaryContainer
            z: 1
        }

        // Camada 3: Ícone de carregamento
        MaterialSymbol {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 3 // Igual ao leftMargin do fill

            visible: root.isCharging || root.isPluggedIn
            text: "bolt"
            iconSize: 13 // Menor para encaixar perfeitamente dentro do preenchimento
            fill: 1 // Preenchimento sólido no material symbol

            // Falso "vazado": pintado com a cor de fundo da própria Bar
            color: Appearance.colors.colLayer0
            z: 2
        }
    }

    BatteryPopup {
        id: batteryPopup
        hoverTarget: root
    }
}
