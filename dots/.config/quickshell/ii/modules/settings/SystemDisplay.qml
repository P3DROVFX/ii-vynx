import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common.functions as CF
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: page
    spacing: 30
    width: parent ? parent.width : implicitWidth

    Timer {
        id: updateTimer
        interval: 500
        onTriggered: HyprlandData.updateMonitors()
    }

    function applyMonitorSettings(name, res, pos, scale, transform, mirror, disabled) {
        let absoluteConf = "/home/pedro/.config/hypr/monitors.conf";
        let cmd = ["/home/pedro/.config/quickshell/ii/scripts/hyprland/monitor_manager.py", "--file", absoluteConf, "--name", name, "--res", res || "preferred", "--pos", pos || "auto", "--scale", scale ? scale.toString() : "1"];

        if (transform !== undefined && transform !== null) {
            cmd.push("--transform", transform.toString());
        }

        if (mirror) {
            cmd.push("--mirror", mirror);
        }

        if (disabled) {
            cmd.push("--disable");
        }

        Quickshell.execDetached(cmd);

        // Also apply immediately via hyprctl for better UX
        if (disabled) {
            Quickshell.execDetached(["hyprctl", "keyword", "monitor", `${name},disable`]);
        } else {
            let hyprctlCmd = `${name},${res},${pos},${scale}`;
            if (transform !== undefined && transform !== null)
                hyprctlCmd += `,transform,${transform}`;
            if (mirror)
                hyprctlCmd += `,mirror,${mirror}`;

            Quickshell.execDetached(["hyprctl", "keyword", "monitor", hyprctlCmd]);
        }

        updateTimer.restart();
    }

    ContentSection {
        icon: "monitor"
        title: Translation.tr("Displays")

        // --- Live Preview ---
        ContentSubsection {
            title: Translation.tr("Arrangement")

            Rectangle {
                id: previewContainer
                Layout.fillWidth: true
                implicitHeight: 300
                color: Appearance.colors.colLayer1
                radius: Appearance.rounding.large
                clip: true

                property real gapFactor: 1.15 // Spreads coordinates to create subtle visual gaps

                property real totalW: {
                    let minX = 0, maxX = 0;
                    for (let m of HyprlandData.monitors) {
                        let x = (m.x || 0) * gapFactor;
                        let isVert = m.transform === 1 || m.transform === 3;
                        let w = (isVert ? (m.height || 1080) : (m.width || 1920)) / (m.scale || 1);
                        minX = Math.min(minX, x);
                        maxX = Math.max(maxX, x + w);
                    }
                    return maxX - minX;
                }

                property real totalH: {
                    let minY = 0, maxY = 0;
                    for (let m of HyprlandData.monitors) {
                        let y = (m.y || 0) * gapFactor;
                        let isVert = m.transform === 1 || m.transform === 3;
                        let h = (isVert ? (m.width || 1920) : (m.height || 1080)) / (m.scale || 1);
                        minY = Math.min(minY, y);
                        maxY = Math.max(maxY, y + h);
                    }
                    return maxY - minY;
                }

                property real previewScale: {
                    if (totalW <= 0)
                        return 1.0;
                    return Math.min((previewContainer.width - 72) / totalW, (previewContainer.height - 72) / totalH);
                }

                property real minX: {
                    let minX = 0;
                    for (let m of HyprlandData.monitors)
                        minX = Math.min(minX, (m.x || 0) * gapFactor);
                    return minX;
                }

                property real minY: {
                    let minY = 0;
                    for (let m of HyprlandData.monitors)
                        minY = Math.min(minY, (m.y || 0) * gapFactor);
                    return minY;
                }

                property real offsetX: -(minX + totalW / 2)
                property real offsetY: -(minY + totalH / 2)

                Item {
                    id: previewAnchor
                    anchors.centerIn: parent
                    width: 1
                    height: 1

                    Repeater {
                        model: HyprlandData.monitors
                        Rectangle {
                            id: monitorPreview
                            property var monitorObj: modelData

                            // Prevent null errors
                            property real mX: (monitorObj && monitorObj.x !== undefined) ? monitorObj.x : 0
                            property real mY: (monitorObj && monitorObj.y !== undefined) ? monitorObj.y : 0
                            property real mScale: (monitorObj && monitorObj.scale !== undefined) ? monitorObj.scale : 1.0
                            property real mWidth: (monitorObj && monitorObj.width !== undefined) ? monitorObj.width : 1920
                            property real mHeight: (monitorObj && monitorObj.height !== undefined) ? monitorObj.height : 1080
                            property bool mDisabled: (monitorObj && monitorObj.disabled !== undefined) ? monitorObj.disabled : false
                            property string mName: (monitorObj && monitorObj.name !== undefined) ? monitorObj.name : "Display"
                            readonly property bool isVertical: (monitorObj && (monitorObj.transform === 1 || monitorObj.transform === 3))

                            x: (mX * previewContainer.gapFactor + previewContainer.offsetX) * previewContainer.previewScale
                            y: (mY * previewContainer.gapFactor + previewContainer.offsetY) * previewContainer.previewScale

                            Behavior on x {
                                NumberAnimation {
                                    duration: 300
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on y {
                                NumberAnimation {
                                    duration: 300
                                    easing.type: Easing.OutCubic
                                }
                            }

                            readonly property real rectWidth: (isVertical ? mHeight : mWidth) / mScale * previewContainer.previewScale
                            readonly property real rectHeight: (isVertical ? mWidth : mHeight) / mScale * previewContainer.previewScale

                            width: rectWidth
                            height: rectHeight

                            Behavior on width {
                                NumberAnimation {
                                    duration: 300
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on height {
                                NumberAnimation {
                                    duration: 300
                                    easing.type: Easing.OutCubic
                                }
                            }

                            radius: Appearance.rounding.small
                            readonly property bool isFocused: monitorObj ? monitorObj.focused : false
                            color: isFocused ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
                            border.color: isFocused ? Appearance.colors.colPrimary : Appearance.colors.colOutline
                            border.width: isFocused ? 3 : 1
                            opacity: mDisabled ? 0.4 : 1.0

                            StyledText {
                                anchors.centerIn: parent
                                text: monitorObj ? (monitorObj.id + 1).toString() : ""
                                font.pixelSize: 32
                                font.weight: Font.Black
                                color: isFocused ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                            }

                            // Primary Label
                            StyledText {
                                visible: isFocused
                                anchors {
                                    bottom: parent.bottom
                                    horizontalCenter: parent.horizontalCenter
                                    bottomMargin: 6
                                }
                                text: Translation.tr("PRIMARY")
                                font.pixelSize: 8
                                font.weight: Font.Bold
                                color: Appearance.colors.colOnPrimary
                                opacity: 0.9
                            }

                            StyledText {
                                anchors {
                                    bottom: parent.bottom
                                    right: parent.right
                                    margins: 4
                                }
                                text: mName
                                font.pixelSize: 8
                                color: isFocused ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                                opacity: 0.6
                            }

                            // Arrangement Controls (Outside Preview)
                            Item {
                                anchors.fill: parent
                                visible: !isFocused && !mDisabled

                                function doJump(dir) {
                                    if (!monitorObj)
                                        return;

                                    // Effective dimensions based on rotation
                                    let myW = (isVertical ? mHeight : mWidth) / mScale;
                                    let myH = (isVertical ? mWidth : mHeight) / mScale;
                                    let nx = mX, ny = mY;

                                    let others = [];
                                    for (let i = 0; i < HyprlandData.monitors.length; i++) {
                                        let m = HyprlandData.monitors[i];
                                        if (m.name !== mName && !m.disabled) {
                                            // Pre-calculate effective size for other monitors
                                            let isOVert = (m.transform === 1 || m.transform === 3);
                                            m.effW = (isOVert ? m.height : m.width) / m.scale;
                                            m.effH = (isOVert ? m.width : m.height) / m.scale;
                                            others.push(m);
                                        }
                                    }
                                    if (others.length === 0)
                                        return;

                                    // Try to find if we are adjacent to someone using effective dimensions
                                    if (dir === "left") {
                                        let adj = others.find(o => Math.abs((o.x + o.effW) - mX) < 40);
                                        if (adj)
                                            nx = adj.x - myW;
                                        else {
                                            let best = others[0];
                                            nx = best.x - myW;
                                            ny = best.y;
                                        }
                                    } else if (dir === "right") {
                                        let adj = others.find(o => Math.abs(o.x - (mX + myW)) < 40);
                                        if (adj)
                                            nx = adj.x + adj.effW;
                                        else {
                                            let best = others[0];
                                            nx = best.x + best.effW;
                                            ny = best.y;
                                        }
                                    } else if (dir === "up") {
                                        let adj = others.find(o => Math.abs((o.y + o.effH) - mY) < 40);
                                        if (adj)
                                            ny = adj.y - myH;
                                        else {
                                            let best = others[0];
                                            ny = best.y - myH;
                                            nx = best.x;
                                        }
                                    } else if (dir === "down") {
                                        let adj = others.find(o => Math.abs(o.y - (mY + myH)) < 40);
                                        if (adj)
                                            ny = adj.y + adj.effH;
                                        else {
                                            let best = others[0];
                                            ny = best.y + best.effH;
                                            nx = best.x;
                                        }
                                    }

                                    page.applyMonitorSettings(mName, mWidth + "x" + mHeight + "@" + monitorObj.refreshRate, Math.round(nx) + "x" + Math.round(ny), mScale, monitorObj.transform, null, false);
                                }

                                // Jump Buttons (Positioned Outside)
                                // Left
                                Rectangle {
                                    id: leftJump
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: maLeft.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colTertiary
                                    opacity: maLeft.containsMouse ? 1.0 : 0.8
                                    scale: maLeft.containsPress ? 0.9 : 1.0
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 100
                                        }
                                    }

                                    anchors {
                                        right: parent.left
                                        rightMargin: 8
                                        verticalCenter: parent.verticalCenter
                                    }
                                    MaterialSymbol {
                                        text: "chevron_left"
                                        iconSize: 18
                                        anchors.centerIn: parent
                                        color: maLeft.containsMouse ? Appearance.colors.colOnPrimary : Appearance.colors.colOnTertiary
                                    }
                                    MouseArea {
                                        id: maLeft
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: parent.parent.doJump("left")
                                    }
                                }
                                // Right
                                Rectangle {
                                    id: rightJump
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: maRight.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colTertiary
                                    opacity: maRight.containsMouse ? 1.0 : 0.8
                                    scale: maRight.containsPress ? 0.9 : 1.0
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 100
                                        }
                                    }

                                    anchors {
                                        left: parent.right
                                        leftMargin: 8
                                        verticalCenter: parent.verticalCenter
                                    }
                                    MaterialSymbol {
                                        text: "chevron_right"
                                        iconSize: 18
                                        anchors.centerIn: parent
                                        color: maRight.containsMouse ? Appearance.colors.colOnPrimary : Appearance.colors.colOnTertiary
                                    }
                                    MouseArea {
                                        id: maRight
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: parent.parent.doJump("right")
                                    }
                                }
                                // Up
                                Rectangle {
                                    id: upJump
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: maUp.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colTertiary
                                    opacity: maUp.containsMouse ? 1.0 : 0.8
                                    scale: maUp.containsPress ? 0.9 : 1.0
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 100
                                        }
                                    }

                                    anchors {
                                        bottom: parent.top
                                        bottomMargin: 8
                                        horizontalCenter: parent.horizontalCenter
                                    }
                                    MaterialSymbol {
                                        text: "expand_less"
                                        iconSize: 18
                                        anchors.centerIn: parent
                                        color: maUp.containsMouse ? Appearance.colors.colOnPrimary : Appearance.colors.colOnTertiary
                                    }
                                    MouseArea {
                                        id: maUp
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: parent.parent.doJump("up")
                                    }
                                }
                                // Down
                                Rectangle {
                                    id: downJump
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: maDown.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colTertiary
                                    opacity: maDown.containsMouse ? 1.0 : 0.8
                                    scale: maDown.containsPress ? 0.9 : 1.0
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 100
                                        }
                                    }

                                    anchors {
                                        top: parent.bottom
                                        topMargin: 8
                                        horizontalCenter: parent.horizontalCenter
                                    }
                                    MaterialSymbol {
                                        text: "expand_more"
                                        iconSize: 18
                                        anchors.centerIn: parent
                                        color: maDown.containsMouse ? Appearance.colors.colOnPrimary : Appearance.colors.colOnTertiary
                                    }
                                    MouseArea {
                                        id: maDown
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: parent.parent.doJump("down")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- Monitor List ---
        ContentSubsection {
            title: Translation.tr("Attached Devices")
            visible: (HyprlandData.monitors ? HyprlandData.monitors.length : 0) > 0

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 16

                Repeater {
                    model: HyprlandData.monitors

                    Rectangle {
                        id: monitorCard
                        property var monitorObj: modelData
                        Layout.fillWidth: true
                        implicitHeight: monitorCardCol.implicitHeight + 32
                        color: Appearance.colors.colLayer1
                        radius: Appearance.rounding.large
                        readonly property bool isFocused: monitorObj ? monitorObj.focused : false
                        border.color: isFocused ? Appearance.colors.colPrimary : "transparent"
                        border.width: 2

                        ColumnLayout {
                            id: monitorCardCol
                            anchors {
                                fill: parent
                                margins: 16
                            }
                            spacing: 16

                            // Header Info
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 16

                                Rectangle {
                                    width: 64
                                    height: 64
                                    radius: Appearance.rounding.normal
                                    color: isFocused ? Appearance.colors.colPrimary : Appearance.colors.colLayer2

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: (monitorObj && (monitorObj.name === "eDP-1" || monitorObj.name.includes("eDP"))) ? "laptop_mac" : "desktop_windows"
                                        iconSize: 32
                                        color: isFocused ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    StyledText {
                                        text: (monitorObj ? (monitorObj.description || monitorObj.name) : "")
                                        font.pixelSize: Appearance.font.pixelSize.large
                                        font.weight: Font.DemiBold
                                        color: Appearance.colors.colOnSurface
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    // Technical Tags
                                    RowLayout {
                                        spacing: 8
                                        Repeater {
                                            model: [
                                                {
                                                    label: "HDR",
                                                    show: monitorObj && monitorObj.hdr
                                                },
                                                {
                                                    label: Translation.tr("Internal"),
                                                    show: monitorObj && (monitorObj.name === "eDP-1" || monitorObj.name.includes("eDP"))
                                                }
                                            ]
                                            Rectangle {
                                                visible: modelData.show
                                                height: 20
                                                width: tagText.implicitWidth + 12
                                                color: Appearance.colors.colLayer3
                                                radius: 4
                                                StyledText {
                                                    id: tagText
                                                    anchors.centerIn: parent
                                                    text: modelData.label
                                                    font.pixelSize: 11
                                                    font.weight: Font.Bold
                                                    color: Appearance.colors.colOnSurface
                                                }
                                            }
                                        }
                                    }

                                    StyledText {
                                        text: (monitorObj ? monitorObj.name : "") + " • " + (monitorObj ? monitorObj.width : 0) + "x" + (monitorObj ? monitorObj.height : 0) + " @ " + (monitorObj ? Math.round(monitorObj.refreshRate) : 60) + "Hz"
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnSurfaceVariant
                                        opacity: 0.8
                                    }
                                }

                                RowLayout {
                                    spacing: 8

                                    RippleButtonWithIcon {
                                        Layout.alignment: Qt.AlignTop
                                        materialIcon: monitorObj.disabled ? "visibility" : "visibility_off"
                                        mainText: monitorObj.disabled ? Translation.tr("Enable") : Translation.tr("Disable")
                                        onClicked: page.applyMonitorSettings(monitorObj.name, monitorObj.width + "x" + monitorObj.height + "@" + monitorObj.refreshRate, monitorObj.x + "x" + monitorObj.y, monitorObj.scale, monitorObj.transform, monitorObj.mirrorOf !== "none" ? monitorObj.mirrorOf : null, !monitorObj.disabled)

                                        // Outline style
                                        colBackground: "transparent"
                                        background: Rectangle {
                                            radius: parent.buttonRadius
                                            color: "transparent"
                                            border.color: Appearance.colors.colOutline
                                            border.width: 1
                                        }
                                    }
                                }
                            }

                            // Settings Layout
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 20

                                // Resolution
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    StyledText {
                                        text: Translation.tr("Resolution & Refresh Rate")
                                        font.weight: Font.DemiBold
                                        opacity: 0.8
                                        font.pixelSize: Appearance.font.pixelSize.small
                                    }

                                    StyledComboBox {
                                        Layout.fillWidth: true
                                        model: monitorObj ? monitorObj.availableModes : []
                                        currentIndex: {
                                            if (!monitorObj)
                                                return -1;
                                            let currentRes = monitorObj.width + "x" + monitorObj.height;
                                            for (let i = 0; i < (model ? model.length : 0); i++) {
                                                if (model[i].includes(currentRes))
                                                    return i;
                                            }
                                            return 0;
                                        }
                                        onActivated: index => {
                                            let mode = model[index];
                                            let parts = mode.split("@");
                                            let res = parts[0];
                                            let refresh = parts[1].replace("Hz", "");
                                            page.applyMonitorSettings(monitorObj.name, res + "@" + refresh, monitorObj.x + "x" + monitorObj.y, monitorObj.scale, monitorObj.transform, null, false);
                                        }
                                    }
                                }

                                // Scaling - Full Width
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    StyledText {
                                        text: Translation.tr("Scaling")
                                        font.weight: Font.DemiBold
                                        opacity: 0.8
                                        font.pixelSize: Appearance.font.pixelSize.small
                                    }

                                    property var scales: [0.5, 0.8, 1.0, 1.25, 1.5, 2.0]

                                    RowLayout {
                                        spacing: 16
                                        Layout.fillWidth: true
                                        StyledSlider {
                                            id: scalingSlider
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 56
                                            from: 0
                                            to: parent.parent.scales.length - 1
                                            stepSize: 1
                                            snapMode: Slider.SnapAlways
                                            value: {
                                                let current = monitorObj ? monitorObj.scale : 1.0;
                                                let bestIdx = 2; // Default to 1.0
                                                let minDiff = 999;
                                                for (let i = 0; i < parent.parent.scales.length; i++) {
                                                    let diff = Math.abs(parent.parent.scales[i] - current);
                                                    if (diff < minDiff) {
                                                        minDiff = diff;
                                                        bestIdx = i;
                                                    }
                                                }
                                                return bestIdx;
                                            }

                                            stopIndicatorValues: [0, 1, 2, 3, 4, 5]
                                            tooltipContent: (parent.parent.scales[Math.round(value)] * 100).toFixed(0) + "%"

                                            onMoved: {
                                                let newVal = parent.parent.scales[Math.round(value)];
                                                page.applyMonitorSettings(monitorObj.name, monitorObj.width + "x" + monitorObj.height + "@" + monitorObj.refreshRate, monitorObj.x + "x" + monitorObj.y, newVal, monitorObj.transform, null, false);
                                            }
                                        }

                                        StyledText {
                                            text: (parent.parent.scales[Math.round(scalingSlider.value)] * 100).toFixed(0) + "%"
                                            font.family: Appearance.font.family.numbers
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            Layout.preferredWidth: 40
                                        }
                                    }
                                }

                                // Row 2: Orientation & Mirroring
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 24

                                    // Orientation
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        StyledText {
                                            text: Translation.tr("Orientation")
                                            font.weight: Font.DemiBold
                                            opacity: 0.8
                                            font.pixelSize: Appearance.font.pixelSize.small
                                        }

                                        ButtonGroup {
                                            id: orientationGroup
                                            spacing: 4
                                            padding: 0
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 45
                                            color: "transparent"

                                            SelectionGroupButton {
                                                buttonText: "0°"
                                                toggled: (monitorObj ? monitorObj.transform : 0) === 0
                                                leftmost: true
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                leftRadius: toggled ? height / 2 : Appearance.rounding.small
                                                rightRadius: toggled ? height / 2 : 4
                                                onClicked: page.applyMonitorSettings(monitorObj.name, monitorObj.width + "x" + monitorObj.height + "@" + monitorObj.refreshRate, monitorObj.x + "x" + monitorObj.y, monitorObj.scale, 0, null, false)
                                            }
                                            SelectionGroupButton {
                                                buttonText: "90°"
                                                toggled: (monitorObj ? monitorObj.transform : 0) === 1
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                leftRadius: toggled ? height / 2 : 4
                                                rightRadius: toggled ? height / 2 : 4
                                                onClicked: page.applyMonitorSettings(monitorObj.name, monitorObj.width + "x" + monitorObj.height + "@" + monitorObj.refreshRate, monitorObj.x + "x" + monitorObj.y, monitorObj.scale, 1, null, false)
                                            }
                                            SelectionGroupButton {
                                                buttonText: "180°"
                                                toggled: (monitorObj ? monitorObj.transform : 0) === 2
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                leftRadius: toggled ? height / 2 : 4
                                                rightRadius: toggled ? height / 2 : 4
                                                onClicked: page.applyMonitorSettings(monitorObj.name, monitorObj.width + "x" + monitorObj.height + "@" + monitorObj.refreshRate, monitorObj.x + "x" + monitorObj.y, monitorObj.scale, 2, null, false)
                                            }
                                            SelectionGroupButton {
                                                buttonText: "270°"
                                                toggled: (monitorObj ? monitorObj.transform : 0) === 3
                                                rightmost: true
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                leftRadius: toggled ? height / 2 : 4
                                                rightRadius: toggled ? height / 2 : Appearance.rounding.small
                                                onClicked: page.applyMonitorSettings(monitorObj.name, monitorObj.width + "x" + monitorObj.height + "@" + monitorObj.refreshRate, monitorObj.x + "x" + monitorObj.y, monitorObj.scale, 3, null, false)
                                            }
                                        }
                                    }

                                    // Mirroring
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        StyledText {
                                            text: Translation.tr("Mirroring")
                                            font.weight: Font.DemiBold
                                            opacity: 0.8
                                            font.pixelSize: Appearance.font.pixelSize.small
                                        }
                                        RowLayout {
                                            spacing: 12

                                            StyledComboBox {
                                                Layout.fillWidth: true
                                                model: ["None"].concat(HyprlandData.monitors.filter(m => m.name !== (monitorObj ? monitorObj.name : "")).map(m => m.name))
                                                currentIndex: (monitorObj && monitorObj.mirrorOf !== "none") ? model.indexOf(monitorObj.mirrorOf) : 0
                                                onActivated: index => {
                                                    if (!monitorObj)
                                                        return;
                                                    let target = model[index] === "None" ? null : model[index];
                                                    page.applyMonitorSettings(monitorObj.name, (monitorObj.width || 1920) + "x" + (monitorObj.height || 1080) + "@" + (monitorObj.refreshRate || 60), (monitorObj.x || 0) + "x" + (monitorObj.y || 0), (monitorObj.scale || 1.0), (monitorObj.transform || 0), target, false);
                                                }
                                            }
                                        }
                                    }
                                }

                                // Row 3: Positioning
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    StyledText {
                                        text: Translation.tr("Positioning & Arrangement")
                                        font.weight: Font.DemiBold
                                        opacity: 0.8
                                        font.pixelSize: Appearance.font.pixelSize.small
                                    }

                                    RowLayout {
                                        spacing: 24
                                        Layout.fillWidth: true

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 4
                                            StyledText {
                                                text: "X: " + (monitorObj ? (monitorObj.x || 0) : 0)
                                                font.pixelSize: 12
                                                opacity: 0.7
                                            }
                                            StyledText {
                                                text: "Y: " + (monitorObj ? (monitorObj.y || 0) : 0)
                                                font.pixelSize: 12
                                                opacity: 0.7
                                            }
                                            StyledText {
                                                text: Translation.tr("Use Arrangement buttons above for quick snap")
                                                font.pixelSize: 10
                                                opacity: 0.5
                                                font.italic: true
                                            }
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                        }

                                        GridLayout {
                                            columns: 3
                                            rows: 3
                                            columnSpacing: 4
                                            rowSpacing: 4

                                            Item {
                                                Layout.preferredWidth: 32
                                                Layout.preferredHeight: 32
                                            }
                                            RippleButton {
                                                implicitWidth: 32
                                                implicitHeight: 32
                                                contentItem: MaterialSymbol {
                                                    text: "arrow_upward"
                                                    anchors.centerIn: parent
                                                    iconSize: 18
                                                }
                                                onClicked: if (monitorObj)
                                                    page.applyMonitorSettings(monitorObj.name, (monitorObj.width || 1920) + "x" + (monitorObj.height || 1080) + "@" + (monitorObj.refreshRate || 60), (monitorObj.x || 0) + "x" + ((monitorObj.y || 0) - 100), (monitorObj.scale || 1.0), (monitorObj.transform || 0), null, false)
                                            }
                                            Item {
                                                Layout.preferredWidth: 32
                                                Layout.preferredHeight: 32
                                            }

                                            RippleButton {
                                                implicitWidth: 32
                                                implicitHeight: 32
                                                contentItem: MaterialSymbol {
                                                    text: "arrow_left"
                                                    anchors.centerIn: parent
                                                    iconSize: 18
                                                }
                                                onClicked: if (monitorObj)
                                                    page.applyMonitorSettings(monitorObj.name, (monitorObj.width || 1920) + "x" + (monitorObj.height || 1080) + "@" + (monitorObj.refreshRate || 60), ((monitorObj.x || 0) - 100) + "x" + (monitorObj.y || 0), (monitorObj.scale || 1.0), (monitorObj.transform || 0), null, false)
                                            }
                                            RippleButton {
                                                implicitWidth: 32
                                                implicitHeight: 32
                                                contentItem: MaterialSymbol {
                                                    text: "center_focus_strong"
                                                    anchors.centerIn: parent
                                                    iconSize: 18
                                                }
                                                onClicked: if (monitorObj)
                                                    page.applyMonitorSettings(monitorObj.name, (monitorObj.width || 1920) + "x" + (monitorObj.height || 1080) + "@" + (monitorObj.refreshRate || 60), "0x0", (monitorObj.scale || 1.0), (monitorObj.transform || 0), null, false)
                                            }
                                            RippleButton {
                                                implicitWidth: 32
                                                implicitHeight: 32
                                                contentItem: MaterialSymbol {
                                                    text: "arrow_right"
                                                    anchors.centerIn: parent
                                                    iconSize: 18
                                                }
                                                onClicked: if (monitorObj)
                                                    page.applyMonitorSettings(monitorObj.name, (monitorObj.width || 1920) + "x" + (monitorObj.height || 1080) + "@" + (monitorObj.refreshRate || 60), ((monitorObj.x || 0) + 100) + "x" + (monitorObj.y || 0), (monitorObj.scale || 1.0), (monitorObj.transform || 0), null, false)
                                            }

                                            Item {
                                                Layout.preferredWidth: 32
                                                Layout.preferredHeight: 32
                                            }
                                            RippleButton {
                                                implicitWidth: 32
                                                implicitHeight: 32
                                                contentItem: MaterialSymbol {
                                                    text: "arrow_downward"
                                                    anchors.centerIn: parent
                                                    iconSize: 18
                                                }
                                                onClicked: if (monitorObj)
                                                    page.applyMonitorSettings(monitorObj.name, (monitorObj.width || 1920) + "x" + (monitorObj.height || 1080) + "@" + (monitorObj.refreshRate || 60), (monitorObj.x || 0) + "x" + ((monitorObj.y || 0) + 100), (monitorObj.scale || 1.0), (monitorObj.transform || 0), null, false)
                                            }
                                            Item {
                                                Layout.preferredWidth: 32
                                                Layout.preferredHeight: 32
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- Global Actions & Save ---
        ContentSubsection {
            title: Translation.tr("Actions")
            RowLayout {
                spacing: 12
                Layout.fillWidth: true

                RippleButtonWithIcon {
                    materialIcon: "grid_view"
                    mainText: Translation.tr("Enable All")
                    onClicked: {
                        for (let m of HyprlandData.monitors) {
                            page.applyMonitorSettings(m.name, (m.width || 1920) + "x" + (m.height || 1080) + "@" + (m.refreshRate || 60), (m.x || 0) + "x" + (m.y || 0), m.scale || 1.0, m.transform || 0, null, false);
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: savePopup
        parent: Overlay.overlay
        visible: true
        closePolicy: Popup.NoAutoClose
        modal: false
        dim: false
        padding: 0
        background: null

        x: parent ? parent.width - width - 32 : 0
        y: parent ? parent.height - height - 32 : 0

        property bool saved: false
        Timer {
            id: feedbackTimer
            interval: 2000
            onTriggered: savePopup.saved = false
        }

        FloatingActionButton {
            buttonText: savePopup.saved ? Translation.tr("Saved!") : Translation.tr("Save Changes")
            iconText: savePopup.saved ? "check_circle" : "save"
            expanded: true
            onClicked: {
                let allData = [];
                for (let m of HyprlandData.monitors) {
                    allData.push({
                        name: m.name,
                        res: (m.width || 1920) + "x" + (m.height || 1080) + "@" + (m.refreshRate || 60),
                        pos: (m.x || 0) + "x" + (m.y || 0),
                        scale: (m.scale || 1.0).toString(),
                        transform: m.transform,
                        mirror: m.mirrorOf !== "none" ? m.mirrorOf : null,
                        disabled: m.disabled
                    });
                }

                let absoluteConf = "/home/pedro/.config/hypr/monitors.conf";
                let jsonStr = JSON.stringify(allData);
                Quickshell.execDetached(["/home/pedro/.config/quickshell/ii/scripts/hyprland/monitor_manager.py", "--file", absoluteConf, "--all", jsonStr]);

                savePopup.saved = true;
                feedbackTimer.restart();
            }
        }
    }
}
