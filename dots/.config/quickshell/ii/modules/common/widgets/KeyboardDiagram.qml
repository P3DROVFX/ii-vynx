pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common
import qs.modules.common.functions
import "../functions/KeyboardMap.js" as KeyboardMap

// Shared KLE renderer for the typing preview and the editable cheatsheet.
Item {
    id: root
    property var keys: []
    property var entries: []
    property real unitWidth: 1
    property real unitHeight: 1
    property real unit: 40
    property real keySpacing: 5
    property real labelSize: Appearance.font.pixelSize.normal
    property bool interactive: false
    property bool showSymbols: false
    property int selectedKey: -1
    property string nextChar: ""
    property string pressedChar: ""
    signal keyClicked(int keyIndex)

    implicitWidth: root.unitWidth * root.unit
    implicitHeight: root.unitHeight * root.unit

    Repeater {
        model: root.keys
        delegate: Item {
            id: cap
            required property int index
            required property var modelData
            readonly property var entry: root.entries[index] ?? ({})
            readonly property bool chosen: root.interactive && root.selectedKey === index
            readonly property bool pressed: root.pressedChar.length > 0 && entry.char === root.pressedChar
            readonly property bool next: root.nextChar.length > 0 && entry.char === root.nextChar
            readonly property string superGlyph: root.showSymbols && !entry.icon && (entry.label === "Super" || entry.label === "R\nSuper")
                ? String(Config.options.cheatsheet.superKey || "") : ""
            readonly property string symbol: !root.showSymbols || superGlyph || entry.icon === "none" ? "" : (entry.icon || KeyboardMap.automaticIcon(entry.label))
            readonly property color foreground: chosen || pressed ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurface
            x: modelData.x * root.unit
            y: modelData.y * root.unit
            width: Math.max(1, modelData.w * root.unit - root.keySpacing)
            height: Math.max(1, modelData.h * root.unit - root.keySpacing)
            opacity: entry.inherited && !chosen ? 0.55 : 1
            transform: Rotation {
                angle: cap.modelData.r
                origin.x: (cap.modelData.rx - cap.modelData.x) * root.unit
                origin.y: (cap.modelData.ry - cap.modelData.y) * root.unit
            }

            KeyboardKey {
                anchors.fill: parent
                key: cap.symbol || cap.superGlyph ? "" : (cap.entry.label || (root.interactive ? "—" : ""))
                fitText: true
                horizontalPadding: 3
                verticalPadding: 2
                borderWidth: 0
                extraBottomBorderWidth: 0
                borderColor: "transparent"
                borderRadius: Appearance.rounding.verysmall
                pixelSize: root.labelSize
                textColor: cap.foreground
                keyColor: cap.chosen || cap.pressed ? Appearance.colors.colPrimary
                    : cap.next ? Appearance.colors.colPrimaryContainer
                    : ColorUtils.transparentize(Appearance.colors.colOnSurface, root.interactive ? 0.90 : 0.88)
                Behavior on keyColor {
                    ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                }
            }
            MaterialSymbol {
                anchors.centerIn: parent
                visible: cap.symbol.length > 0
                text: cap.symbol
                iconSize: Math.min(root.labelSize * 1.35, cap.height * 0.55)
                color: cap.foreground
            }
            StyledText {
                anchors.fill: parent
                anchors.margins: 4
                visible: cap.superGlyph.length > 0
                text: cap.superGlyph
                font.family: Appearance.font.family.iconNerd
                font.pixelSize: root.labelSize * 1.35
                fontSizeMode: Text.Fit
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: cap.foreground
            }
            RippleButton {
                anchors.fill: parent
                visible: root.interactive
                scale: 1
                buttonRadius: Appearance.rounding.verysmall
                colBackground: "transparent"
                colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.82)
                Accessible.name: (cap.entry.label || Translation.tr("Unassigned key")) + (cap.entry.description ? ": " + cap.entry.description : "")
                onClicked: root.keyClicked(cap.index)
                StyledToolTip { text: cap.entry.description || cap.entry.label || Translation.tr("Unassigned key") }
            }
        }
    }
}
