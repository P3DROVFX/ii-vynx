import qs.services
import QtQuick
import qs.modules.ii.onScreenDisplay
import qs.modules.common.widgets

OsdValueIndicator {
    id: osdValues
    value: MprisController.activePlayer?.volume ?? 0
    icon: "music_note"
    name: Translation.tr("Music")
    shape: MaterialShape.Shape.Cookie4Sided
}
