import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs
import qs.services
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Io
import "./widgets"

DockButton {
    id: root

    property var dockContent: null
    property int delegateIndex: -1
    property string filePath: ""

    property int buttonSize: Appearance.sizes.dockButtonSize
    property int dotMargin: Math.round((Config.options?.dock.height ?? 60) * 0.2)

    readonly property bool isVertical: dockContent?.isVertical ?? false

    readonly property string fileName: {
        const parts = filePath.split("/").filter(s => s.length > 0)
        return parts[parts.length - 1] ?? filePath
    }

    readonly property string containingDir: {
        const idx = filePath.lastIndexOf("/")
        return idx > 0 ? filePath.substring(0, idx) : filePath
    }

    readonly property string mimeIcon: dockContent?.mimeIconFromPath(filePath) ?? "insert_drive_file"

    readonly property bool isDirectory: {
        const lastPart = filePath.toString().split("/").filter(s => s).pop() ?? ""
        return !lastPart.includes(".") || filePath.endsWith("/")
    }

    readonly property bool isImage: /\.(png|jpe?g|webp|gif|svg|bmp|ico)$/i.test(filePath)

    property string cachedXdgIcon: ""

    Process {
        id: mimeQueryProcess
        command: ["xdg-mime", "query", "filetype", root.filePath]
        stdout: SplitParser {
            onRead: (line) => {
                const mime = line.trim()
                // Convert MIME type (e.g. "text/plain") to XDG icon name ("text-plain")
                if (mime !== "") root.cachedXdgIcon = mime.replace("/", "-")
            }
        }
    }

    Component.onCompleted: {
        if (!root.isImage && root.filePath !== "" && !root.isDirectory)
            mimeQueryProcess.running = true
    }

    onFilePathChanged: {
        if (!root.isImage && root.filePath !== "" && !root.isDirectory) {
            root.cachedXdgIcon = ""
            mimeQueryProcess.running = true
        }
    }

    readonly property string resolvedXdgIcon: {
        TaskbarApps.iconThemeRevision   // reactive dependency — retriggers on theme change
        const dirs = TaskbarApps.xdgUserDirs

        if (root.isDirectory) {
            const map = {
                [dirs.downloads]: "folder-downloads",
                [dirs.documents]: "folder-documents",
                [dirs.pictures]: "folder-pictures",
                [dirs.music]: "folder-music",
                [dirs.videos]: "folder-videos",
                [dirs.desktop]: "folder-desktop",
                [dirs.publicshare]: "folder-publicshare",
                [dirs.templates]: "folder-templates",
            }
            return Quickshell.iconPath(map[filePath.toString()] ?? "folder", "folder")
        }

        if (root.isImage) return ""

        if (root.cachedXdgIcon !== "")
            return Quickshell.iconPath(root.cachedXdgIcon, "text-x-generic")

        return Quickshell.iconPath("text-x-generic", "application-x-generic")
    }

    readonly property bool isDragging: dockContent?.fileDragActive === true
                                    && dockContent?.fileDraggedIndex === delegateIndex

    // Computes how much this delegate should shift to make room for the dragged item
    readonly property real shiftOffset: {
        if (!dockContent?.fileDragActive || dockContent.fileDraggedIndex < 0 || delegateIndex === dockContent.fileDraggedIndex) return 0

        const dragIdx = dockContent.fileDraggedIndex
        const dropIdx = dockContent.fileDropIndex
        const step = buttonSize + dotMargin * 2

        if (dockContent.fileDragIntent === "unpin")
            return delegateIndex > dragIdx ? -step : 0

        if (dockContent.fileDragIntent === "reorder") {
            if (dragIdx < dropIdx && delegateIndex > dragIdx && delegateIndex <= dropIdx) return -step
            if (dragIdx > dropIdx && delegateIndex >= dropIdx && delegateIndex < dragIdx) return step
        }

        return 0
    }

    width: buttonSize + dotMargin * 2
    height: buttonSize + dotMargin * 2

    opacity: isDragging ? 0.0 : 1.0
    Behavior on opacity {
        enabled: !isDragging && !(dockContent?.fileSuppressAnim ?? false)
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(root)
    }

    z: isDragging ? 100 : 0

    transform: Translate {
        x: root.isVertical ? 0 : root.shiftOffset
        y: root.isVertical ? root.shiftOffset : 0
        Behavior on x {
            enabled: !root.isDragging && !(dockContent?.fileSuppressAnim ?? false)
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on y {
            enabled: !root.isDragging && !(dockContent?.fileSuppressAnim ?? false)
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    pointingHandCursor: false

    MouseArea {
        id: fileMouseArea
        anchors.centerIn: parent
        width: root.buttonSize
        height: root.buttonSize
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        preventStealing: drag.active
        cursorShape: Qt.PointingHandCursor

        drag.target: dockContent?.fileDragGhostItem ?? null
        drag.axis: root.isVertical ? Drag.YAxis : Drag.XAxis
        drag.threshold: 0

        readonly property real ghostHalf: (dockContent?.fileDragGhostItem?.width ?? 0) / 2
        drag.minimumX: root.isVertical ? 0 : (dockContent?.pinButtonCenter ?? 0) - ghostHalf
        drag.maximumX: root.isVertical ? 0 : (dockContent?.unpinButtonCenter ?? 0) - ghostHalf
        drag.minimumY: root.isVertical ? (dockContent?.pinButtonCenter ?? 0) - ghostHalf : 0
        drag.maximumY: root.isVertical ? (dockContent?.unpinButtonCenter ?? 0) - ghostHalf : 0

        property bool wasDragging: false

        onPressed: {
            wasDragging = false
            if (dockContent?.fileDragGhostItem) {
                const p = root.mapToItem(dockContent, 0, 0)
                dockContent.fileDragGhostItem.x = p.x + root.dotMargin
                dockContent.fileDragGhostItem.y = p.y + root.dotMargin
            }
        }

        onPositionChanged: {
            if (!drag.active) return
            if (!wasDragging) {
                wasDragging = true
                dockContent.startFileDrag(root.delegateIndex)
            }
            dockContent.moveFileDrag()
        }

        onReleased: (mouse) => {
            if (wasDragging) {
                wasDragging = false
                dockContent.endFileDrag()
                return
            }
            if (mouse.button === Qt.RightButton) {
                dockContent.buttonHovered = false
                dockContent.lastHoveredButton = null
                fileContextMenu.open()
                return
            }

            Quickshell.execDetached({ command: ["xdg-open", root.filePath] })
        }
    }

    DockFileContextMenu {
        id: fileContextMenu
        filePath: root.filePath
        anchorItem: root
    }

    Connections {
        target: fileContextMenu
        function onActiveChanged() {
            if (dockContent) dockContent.anyContextMenuOpen = fileContextMenu.active
        }
    }

    DockTooltip {
        id: fileTooltip
        parentItem: root
        text: root.fileName
        showTooltip: fileMouseArea.containsMouse && !(dockContent?.fileDragActive ?? false)
        tooltipOffset: -root.dotMargin
    }

    contentItem: Item {
        anchors.fill: parent

        Item {
            width: root.buttonSize
            height: root.buttonSize
            anchors.centerIn: parent

            // Image thumbnail (shown for recognized image files)
            Image {
                id: thumbnailImage
                anchors.fill: parent
                visible: root.isImage
                source: root.isImage ? ("file://" + root.filePath) : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                sourceSize: Qt.size(root.buttonSize * 2, root.buttonSize * 2)

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: thumbnailImage.width
                        height: thumbnailImage.height
                        radius: Appearance.rounding.small
                    }
                }
            }

            // Placeholder shown while the image thumbnail is loading
            MaterialSymbol {
                anchors.centerIn: parent
                visible: root.isImage && thumbnailImage.status !== Image.Ready
                text: "image"
                iconSize: root.buttonSize
                color: Appearance.colors.colOnLayer0
            }

            // XDG icon for non-image files
            IconImage {
                id: xdgIcon
                anchors.centerIn: parent
                visible: !root.isImage && root.resolvedXdgIcon !== ""

                implicitSize: root.buttonSize
                width: root.buttonSize
                height: root.buttonSize

                source: root.resolvedXdgIcon

                // Force icon reload when the theme changes
                backer.sourceSize: Qt.size(
                    root.buttonSize + TaskbarApps.iconThemeRevision,
                    root.buttonSize + TaskbarApps.iconThemeRevision
                )
            }

            // Fallback folder icon for directories with no specific XDG icon
            MaterialSymbol {
                anchors.centerIn: parent
                visible: !root.isImage && root.resolvedXdgIcon === "" && root.isDirectory
                text: "folder"
                iconSize: root.buttonSize
                color: Appearance.colors.colOnLayer0
            }
        }
    }
}
