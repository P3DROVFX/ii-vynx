import QtQuick

DockIcon {
    id: iconContainer
    appId: root.appToplevel?.appId ?? ""
    isRunning: root.appIsRunning
    width: root.buttonSize
    height: root.buttonSize
    anchors.centerIn: parent
}