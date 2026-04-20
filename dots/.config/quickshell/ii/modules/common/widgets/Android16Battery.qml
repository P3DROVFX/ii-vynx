import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    // Propriedades expostas (Inputs da UI)
    property int batteryLevel: 100
    property bool isCharging: false
    property bool isPowerSaving: false

    // Garante leitura segura limitando entre 0 e 100
    property real boundedBatteryLevel: Math.max(0, Math.min(100, root.batteryLevel))

    // Proporções
    property real batteryWidthScale: 1.55 // Largura vs altura do corpo
    property real batteryHeightScale: 0.80 // Menor altura da bateria vs painel
    property real batteryRadiusScale: 0.3 // Arredondamento da caixa
    property real capHeightScale: 0.35 // Altura da tampa vs altura do corpo
    property real textSizeScale: 0.85 // Tamanho da fonte vs altura

    // Cores Principais do Preenchimento (Fill)
    property color colorFillNormal: Appearance.colors.colOnSurface
    property color colorFillCharging: "#18CC47" // Verde Vivo
    property color colorFillWarning: "#ea4335" // Vermelho Intenso
    property color colorFillPowerSaving: "#fbbc04" // Amarelo/Dourado

    // Cor de preenchimento dinâmico
    property color currentFillColor: {
        if (isCharging)
            return colorFillCharging;
        if (isPowerSaving)
            return colorFillPowerSaving;
        if (boundedBatteryLevel <= 20)
            return colorFillWarning;
        return colorFillNormal;
    }

    // Fundo Translúcido da Bateria e Tampa
    property color colorEmptyTrack: Qt.rgba(colorFillNormal.r, colorFillNormal.g, colorFillNormal.b, 0.3)

    // Cores dos Textos
    // O texto no lado vazio é da mesma cor normal.
    property color colorTextEmpty: colorFillNormal
    // O texto preenchido fica escuro para destacar na cor viva (ex: verde).
    property color colorInverse: Appearance.m3colors.m3background
    property color colorTextFilled: Appearance.colors.colOnSurface

    // Cores do Ícone Adjunto (Raio / Mais)
    property color colorBolt: colorFillNormal

    // =========================================================================

    property real batteryWidth: root.height * batteryWidthScale
    property real batteryHeight: root.height * batteryHeightScale

    Item {
        id: container
        width: batteryWidth + (root.isCharging || root.isPowerSaving ? root.height * 0.65 : root.height * 0.15)
        height: root.height
        anchors.centerIn: parent

        // Tampa - Container com clip para criar um formato de meia pílula perfeito
        Item {
            id: batteryCapContainer
            visible: !root.isCharging && !root.isPowerSaving
            height: batteryHeight * capHeightScale
            width: batteryHeight * 0.12
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: batteryMaskedRender.right
            anchors.leftMargin: 1 // Pequeno espaçamento
            clip: true

            Rectangle {
                width: parent.width * 2
                height: parent.height
                radius: height / 2
                color: root.colorEmptyTrack
                anchors.right: parent.right
            }
        }

        // Corpo Base (Será escondido e usado como fonte da máscara)
        Item {
            id: batteryBase
            width: batteryWidth
            height: batteryHeight
            anchors.left: container.left
            anchors.verticalCenter: parent.verticalCenter
            visible: false // Hidden

            Rectangle {
                anchors.fill: parent
                radius: batteryHeight * batteryRadiusScale
                color: root.colorEmptyTrack

                // Texto (Área Vazia - Empty Track)
                Text {
                    anchors.fill: parent
                    text: root.boundedBatteryLevel
                    font.family: Appearance.font.family.main
                    font.pixelSize: Math.round(parent.height * textSizeScale)
                    font.bold: true
                    color: root.colorTextEmpty
                    verticalAlignment: Text.AlignTop
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: Math.round(parent.height * 0.01)
                }
            }

            // Máscara (Área Preenchida - Fill)
            Item {
                id: fillWrapper
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * (root.boundedBatteryLevel / 100)
                clip: true

                Rectangle {
                    width: batteryBase.width
                    height: batteryBase.height
                    radius: batteryBase.height * batteryRadiusScale
                    color: root.currentFillColor
                }

                // Texto Interno (Área Preenchida)
                Text {
                    width: batteryBase.width
                    height: batteryBase.height
                    text: root.boundedBatteryLevel

                    font.pixelSize: Math.round(batteryBase.height * textSizeScale)
                    font.family: Appearance.font.family.title
                    font.weight: Font.Black
                    color: root.colorTextFilled
                    verticalAlignment: Text.AlignTop
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: Math.round(batteryBase.height * 0.01)
                }
            }
        }

        // A MÁSCARA DO RAIO (Usada para recortar buracos na bateria)
        Item {
            id: boltMask
            width: batteryBase.width
            height: batteryBase.height
            anchors.left: batteryBase.left
            anchors.verticalCenter: batteryBase.verticalCenter
            visible: false // Hidden

            Item {
                visible: root.isCharging || root.isPowerSaving
                anchors.left: parent.right
                anchors.leftMargin: -batteryHeight * 0.35
                anchors.verticalCenter: parent.verticalCenter
                width: batteryHeight * 1.15
                height: batteryHeight * 1.15

                property string sym: root.isCharging ? "bolt" : "add"
                property real symSize: batteryHeight * 1.15
                property real outline: Math.max(1, Math.round(batteryHeight * 0.08))

                // Os pixels pretos desta máscara APAGAM o conteúdo subjacente graças ao invert: true do OpacityMask
                MaterialSymbol {
                    text: parent.sym
                    iconSize: parent.symSize
                    fill: 1
                    color: "black"
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -parent.outline
                }
                MaterialSymbol {
                    text: parent.sym
                    iconSize: parent.symSize
                    fill: 1
                    color: "black"
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: parent.outline
                }
                MaterialSymbol {
                    text: parent.sym
                    iconSize: parent.symSize
                    fill: 1
                    color: "black"
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -parent.outline
                }
                MaterialSymbol {
                    text: parent.sym
                    iconSize: parent.symSize
                    fill: 1
                    color: "black"
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: parent.outline
                }
                MaterialSymbol {
                    text: parent.sym
                    iconSize: parent.symSize
                    fill: 1
                    color: "black"
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -parent.outline
                    anchors.verticalCenterOffset: -parent.outline
                }
                MaterialSymbol {
                    text: parent.sym
                    iconSize: parent.symSize
                    fill: 1
                    color: "black"
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: parent.outline
                    anchors.verticalCenterOffset: parent.outline
                }
                MaterialSymbol {
                    text: parent.sym
                    iconSize: parent.symSize
                    fill: 1
                    color: "black"
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -parent.outline
                    anchors.verticalCenterOffset: parent.outline
                }
                MaterialSymbol {
                    text: parent.sym
                    iconSize: parent.symSize
                    fill: 1
                    color: "black"
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: parent.outline
                    anchors.verticalCenterOffset: -parent.outline
                }
            }
        }

        // Renderização final da Bateria COM O BURACO do outline recortado
        OpacityMask {
            id: batteryMaskedRender
            anchors.fill: batteryBase
            source: batteryBase
            maskSource: boltMask
            invert: true // pixels opacos do boltMask viram transparentes!
        }

        // O CORE (O miolo do Raio) desenhado normalmente sobre o buraco
        Item {
            visible: root.isCharging || root.isPowerSaving
            anchors.left: batteryMaskedRender.right
            anchors.leftMargin: -batteryHeight * 0.35 // Mesma posição da máscara
            anchors.verticalCenter: parent.verticalCenter
            width: batteryHeight * 1.15
            height: batteryHeight * 1.15

            property string sym: root.isCharging ? "bolt" : "add"
            property real symSize: batteryHeight * 1.15

            MaterialSymbol {
                anchors.centerIn: parent
                text: parent.sym
                iconSize: parent.symSize
                fill: 1
                color: root.colorBolt
            }
        }
    }
}
