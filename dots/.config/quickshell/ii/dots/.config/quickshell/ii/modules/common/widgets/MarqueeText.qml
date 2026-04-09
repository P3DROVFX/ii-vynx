import qs.modules.common
import QtQuick

Item {
    id: root
    property string text: ""
    property int fontSize: Appearance.font.pixelSize.normal
    property int fontWeight: Font.Normal
    property color textColor: Appearance.colors.colOnLayer0
    property bool running: false

    clip: true
    implicitHeight: innerText.implicitHeight

    StyledText {
        id: innerText
        text: root.text
        font.pixelSize: root.fontSize
        font.weight: root.fontWeight
        color: root.textColor
        elide: Text.ElideNone
        x: 0

        readonly property bool overflows: implicitWidth > root.width + 1
    }

    NumberAnimation {
        target: innerText
        property: "x"
        running: root.running && innerText.overflows
        from: 0
        to: -(innerText.implicitWidth - root.width + 20)
        duration: Math.max(3500, (innerText.implicitWidth - root.width) * 28)
        easing.type: Easing.Linear
        loops: Animation.Infinite
        onStopped: innerText.x = 0
    }
}