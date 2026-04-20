import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

Item {
    id: root
    property real spacing: 8

    property string activeTab: "inbox"

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colSurfaceContainer
        radius: Appearance.rounding.large
        border.width: 1
        border.color: Appearance.colors.colOutlineVariant
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10
        // Navigation
        Column {
            id: headerRow
            Layout.fillHeight: true
            Layout.preferredWidth: 300
            spacing: root.spacing
            Rectangle {
                anchors.fill: parent
                width: parent.width
                height: parent.height
                color: Appearance.colors.colSurfaceContainerHigh
                topLeftRadius: Appearance.rounding.large
                topRightRadius: Appearance.rounding.small
                bottomLeftRadius: Appearance.rounding.large
                bottomRightRadius: Appearance.rounding.small

                // Main layout for nav
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: 48

                        RippleButtonWithIcon {
                            Layout.fillWidth: true
                            implicitHeight: 64
                            buttonRadius: Appearance.rounding.full
                            colBackground: root.activeTab === "compose" ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
                            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                            colRipple: Appearance.colors.colSecondaryContainerActive
                            colBackgroundToggled: Appearance.colors.colSecondary
                            colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                            colRippleToggled: Appearance.colors.colSecondaryActive

                            scale: down ? 0.95 : hovered ? 1.02 : 1.0
                            Behavior on scale {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }

                            contentItem: Item {
                                anchors.fill: parent
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 12
                                    MaterialSymbol {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: "edit"
                                        iconSize: 20
                                        color: root.activeTab === "compose" ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                                    }
                                    StyledText {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: Translation.tr("Compose")
                                        font.pixelSize: Appearance.font.pixelSize.huge
                                        font.weight: Font.DemiBold
                                        color: root.activeTab === "compose" ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                                    }
                                }
                            }

                            onClicked: {
                                root.activeTab = "compose"
                            }
                        }

                    VerticalButtonGroup {
                        id: navGroup
                        Layout.fillWidth: true
                        spacing: 4

                        GroupButton {
                            id: inboxBtn
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            baseHeight: 56
                            bounce: false

                            toggled: root.activeTab === "inbox"
                            onClicked: root.activeTab = "inbox"

                            colBackground: root.activeTab === "inbox" ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
                            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                            colBackgroundToggled: Appearance.colors.colPrimary
                            colBackgroundToggledHover: Appearance.colors.colPrimaryHover

                            background: Rectangle {
                                color: inboxBtn.color
                                Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
                                topLeftRadius: inboxBtn.toggled ? Appearance.rounding.full : Appearance.rounding.large
                                topRightRadius: inboxBtn.toggled ? Appearance.rounding.full : Appearance.rounding.large
                                bottomLeftRadius: inboxBtn.toggled ? Appearance.rounding.full : (navGroup.selectedIndex === 1 ? Appearance.rounding.small : Appearance.rounding.verysmall)
                                bottomRightRadius: inboxBtn.toggled ? Appearance.rounding.full : (navGroup.selectedIndex === 1 ? Appearance.rounding.small : Appearance.rounding.verysmall)
                                Behavior on topLeftRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                                Behavior on topRightRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                                Behavior on bottomLeftRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                                Behavior on bottomRightRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                            }

                            scale: down ? 0.95 : hovered ? 1.02 : 1.0
                            Behavior on scale {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }

                            contentItem: Item {
                                implicitHeight: 56
                                anchors.fill: parent
                                RowLayout {
                                    spacing: 12
                                    anchors.centerIn: parent

                                    MaterialSymbol {
                                        text: "inbox"
                                        iconSize: Appearance.font.pixelSize.huge
                                        color: inboxBtn.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: "Inbox"
                                        font.family: Appearance.font.family.main
                                        font.pixelSize: Appearance.font.pixelSize.huge
                                        font.weight: inboxBtn.toggled ? Font.DemiBold : Font.Normal
                                        color: inboxBtn.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
                                    }
                                }
                            }
                        }

                        GroupButton {
                            id: spamBtn
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            baseHeight: 56
                            bounce: false

                            toggled: root.activeTab === "spam"
                            onClicked: root.activeTab = "spam"

                            colBackground: root.activeTab === "spam" ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
                            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                            colBackgroundToggled: Appearance.colors.colPrimary
                            colBackgroundToggledHover: Appearance.colors.colPrimaryHover

                            background: Rectangle {
                                color: spamBtn.color
                                Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
                                topLeftRadius: spamBtn.toggled ? Appearance.rounding.full : (navGroup.selectedIndex === 0 ? Appearance.rounding.small : Appearance.rounding.verysmall)
                                topRightRadius: spamBtn.toggled ? Appearance.rounding.full : (navGroup.selectedIndex === 0 ? Appearance.rounding.small : Appearance.rounding.verysmall)
                                bottomLeftRadius: spamBtn.toggled ? Appearance.rounding.full : (navGroup.selectedIndex === 2 ? Appearance.rounding.small : Appearance.rounding.verysmall)
                                bottomRightRadius: spamBtn.toggled ? Appearance.rounding.full : (navGroup.selectedIndex === 2 ? Appearance.rounding.small : Appearance.rounding.verysmall)
                                Behavior on topLeftRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                                Behavior on topRightRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                                Behavior on bottomLeftRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                                Behavior on bottomRightRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                            }

                            scale: down ? 0.95 : hovered ? 1.02 : 1.0
                            Behavior on scale {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }

                            contentItem: Item {
                                implicitHeight: 56
                                anchors.fill: parent
                                RowLayout {
                                    spacing: 12
                                    anchors.centerIn: parent

                                    MaterialSymbol {
                                        text: "report"
                                        iconSize: Appearance.font.pixelSize.huge
                                        color: spamBtn.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: "Spam"
                                        font.family: Appearance.font.family.main
                                        font.pixelSize: Appearance.font.pixelSize.huge
                                        font.weight: spamBtn.toggled ? Font.DemiBold : Font.Normal
                                        color: spamBtn.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
                                    }
                                }
                            }
                        }

                        GroupButton {
                            id: sentBtn
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            baseHeight: 56
                            bounce: false

                            toggled: root.activeTab === "sent"
                            onClicked: root.activeTab = "sent"

                            colBackground: root.activeTab === "sent" ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
                            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                            colBackgroundToggled: Appearance.colors.colPrimary
                            colBackgroundToggledHover: Appearance.colors.colPrimaryHover

                            background: Rectangle {
                                color: sentBtn.color
                                Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
                                topLeftRadius: sentBtn.toggled ? Appearance.rounding.full : Appearance.rounding.small
                                topRightRadius: sentBtn.toggled ? Appearance.rounding.full : Appearance.rounding.small
                                bottomLeftRadius: sentBtn.toggled ? Appearance.rounding.full : Appearance.rounding.large
                                bottomRightRadius: sentBtn.toggled ? Appearance.rounding.full : Appearance.rounding.large
                                Behavior on topLeftRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                                Behavior on topRightRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                                Behavior on bottomLeftRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                                Behavior on bottomRightRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                            }

                            scale: down ? 0.95 : hovered ? 1.02 : 1.0
                            Behavior on scale {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }

                            contentItem: Item {
                                implicitHeight: 56
                                anchors.fill: parent
                                RowLayout {
                                    spacing: 12
                                    anchors.centerIn: parent

                                    MaterialSymbol {
                                        text: "send"
                                        iconSize: Appearance.font.pixelSize.huge
                                        color: sentBtn.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: "Sent"
                                        font.family: Appearance.font.family.main
                                        font.pixelSize: Appearance.font.pixelSize.huge
                                        font.weight: sentBtn.toggled ? Font.DemiBold : Font.Normal
                                        color: sentBtn.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
                                    }
                                }
                            }
                        }
                    }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 56
                            color: Appearance.colors.colSurfaceContainerHigh
                            radius: Appearance.rounding.full
                            border.width: 1
                            border.color: Appearance.colors.colOutlineVariant

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 24
                                anchors.rightMargin: 24
                                spacing: 24

                                MaterialSymbol {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: "search"
                                    iconSize: Appearance.font.pixelSize.huge
                                    color: Appearance.colors.colOnSurfaceVariant
                                }

                                TextInput {
                                    id: searchInput
                                    Layout.fillWidth: true
                                    text: ""
                                    color: Appearance.colors.colOnSurfaceVariant
                                    font.pixelSize: Appearance.font.pixelSize.huge
                                    font.family: Appearance.font.family.main
                                    verticalAlignment: TextInput.AlignVCenter
                                    //horizontalAlignment: TextInput.AlignHCenter
                                    Text {
                                        //anchors.centerIn: parent
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Search Email"
                                        color: Appearance.colors.colOnSurfaceVariant
                                        font.pixelSize: Appearance.font.pixelSize.huge
                                        font.family: Appearance.font.family.main
                                        visible: searchInput.text.length === 0
                                    }
                                }
                            }
                        }

                        RippleButton {
                            Layout.fillWidth: true
                            implicitHeight: 56

                            buttonRadius: Appearance.rounding.full
                            colBackground: root.activeTab === "settings" ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
                            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                            colRipple: Appearance.colors.colSecondaryContainerActive
                            colBackgroundToggled: Appearance.colors.colSecondary
                            colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                            colRippleToggled: Appearance.colors.colSecondaryActive

                            scale: down ? 0.95 : hovered ? 1.02 : 1.0
                            Behavior on scale {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }

                            contentItem: Item {
                                anchors.fill: parent
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 12
                                    MaterialSymbol {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: "settings"
                                        iconSize: Appearance.font.pixelSize.huge
                                        color: root.activeTab === "settings" ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                                    }
                                    StyledText {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: Translation.tr("Settings")
                                        font.pixelSize: Appearance.font.pixelSize.huge
                                        font.weight: Font.DemiBold
                                        color: root.activeTab === "settings" ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                                    }
                                }
                            }

                            onClicked: {
                                root.activeTab = "settings"
                            }

                        }
                    }   
                }
            }


        }

        // Emails Column
        Column {
            id: emailRow
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: root.spacing

            Rectangle {
                anchors.fill: parent
                width: parent.width
                height: parent.height
                color: Appearance.colors.colSurfaceContainerHigh
                topLeftRadius: Appearance.rounding.small
                bottomLeftRadius: Appearance.rounding.small
                radius: Appearance.rounding.large
            }

            
        }
    }
}
