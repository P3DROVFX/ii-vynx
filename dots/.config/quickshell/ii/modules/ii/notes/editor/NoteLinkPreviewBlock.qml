pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.services
import qs.services.notes
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.notes

/**
 * A rich card preview for a web URL.
 *
 * Shows the page title, description, domain, favicon and thumbnail image.
 * Metadata is retrieved asynchronously by NotesLinkPreview.
 */
Item {
    id: root

    property var editor: null
    property var block: null
    property int blockIndex: 0

    readonly property string url: root.block ? String(root.block.url ?? "") : ""
    readonly property string domain: {
        try {
            const match = root.url.match(/^https?:\/\/([^\/?#]+)/i);
            return match ? match[1] : root.url;
        } catch (e) {
            return root.url;
        }
    }

    readonly property bool loading: root.block && (!root.block.title || root.block.title.length === 0) && (root.block.fetchedAt === 0 || root.block.fetchedAt === undefined)

    implicitHeight: card.height + 16

    function refreshPreview(): void {
        if (!root.url || !root.editor || !root.block)
            return;
        NotesLinkPreview.fetchPreview(root.url, data => {
            if (!root.block || !root.editor)
                return;
            const success = data && data.ok;
            root.editor.apply([{
                op: "update",
                id: root.block.id,
                patch: {
                    title: (success && data.title) ? data.title : root.domain,
                    description: (success && data.description) ? data.description : "",
                    image: (success && data.image) ? data.image : "",
                    favicon: (success && data.favicon) ? data.favicon : "",
                    fetchedAt: (data && data.fetchedAt) ? data.fetchedAt : Math.floor(Date.now() / 1000)
                }
            }], false);
        });
    }

    Component.onCompleted: {
        if (root.block && (!root.block.title || root.block.title.length === 0 || root.block.fetchedAt === 0))
            root.refreshPreview();
    }

    Rectangle {
        id: card
        x: NotesMetrics.readingPadding
        y: 8
        width: Math.max(160, Math.min(NotesMetrics.readingWidth,
            root.width - NotesMetrics.readingPadding * 2))
        height: contentLayout.implicitHeight + 24
        radius: Appearance.rounding.normal
        color: Appearance.m3colors.m3surfaceContainerLowest
        clip: true

        // Subtle hover indicator
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Appearance.colors.colOnSurface
            opacity: cardHover.containsMouse ? 0.04 : 0

            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }

        MouseArea {
            id: cardHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.url.length > 0)
                    Qt.openUrlExternally(root.url);
            }
        }

        ColumnLayout {
            id: contentLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 8

            // ── Header line: favicon, domain, and actions ─────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16

                    Image {
                        anchors.fill: parent
                        source: root.block && root.block.favicon ? root.block.favicon : ""
                        fillMode: Image.PreserveAspectFit
                        visible: status === Image.Ready
                        asynchronous: true
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "language"
                        iconSize: 15
                        color: Appearance.colors.colSubtext
                        visible: !root.block || !root.block.favicon
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.domain
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }

                NotesIconButton {
                    symbol: "refresh"
                    size: 30
                    iconSize: 16
                    tooltipText: Translation.tr("Refresh preview")
                    onTriggered: {
                        if (root.url.length > 0) {
                            NotesLinkPreview.invalidate(root.url);
                            root.refreshPreview();
                        }
                    }
                }

                NotesIconButton {
                    symbol: "open_in_new"
                    size: 30
                    iconSize: 16
                    tooltipText: Translation.tr("Open in browser")
                    onTriggered: {
                        if (root.url.length > 0)
                            Qt.openUrlExternally(root.url);
                    }
                }

                NotesIconButton {
                    symbol: "content_copy"
                    size: 30
                    iconSize: 16
                    tooltipText: Translation.tr("Copy link")
                    onTriggered: {
                        if (root.url.length > 0)
                            Quickshell.exec(["wl-copy", root.url]);
                    }
                }

                NotesIconButton {
                    symbol: "delete"
                    size: 30
                    iconSize: 16
                    colIcon: Appearance.colors.colSubtext
                    tooltipText: Translation.tr("Remove block")
                    onTriggered: {
                        if (root.editor && root.block)
                            root.editor.removeBlock(root.block.id);
                    }
                }
            }

            // ── Body line: title & description on the left, thumbnail on right ─
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    StyledText {
                        Layout.fillWidth: true
                        text: root.loading ? Translation.tr("Loading preview…") : (root.block && root.block.title ? root.block.title : root.domain)
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer0
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.block && root.block.description ? root.block.description : root.url
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }

                // Thumbnail image if present
                Item {
                    Layout.preferredWidth: 84
                    Layout.preferredHeight: 64
                    visible: thumbImage.status === Image.Ready

                    Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.small
                        clip: true
                        color: Appearance.m3colors.m3surfaceContainerHigh

                        Image {
                            id: thumbImage
                            anchors.fill: parent
                            source: root.block && root.block.image ? (root.block.image.startsWith("/") ? "file://" + root.block.image : root.block.image) : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                        }
                    }
                }
            }
        }
    }
}
