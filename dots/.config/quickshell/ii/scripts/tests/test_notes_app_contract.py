#!/usr/bin/env python3
"""Contract for the notes app window.

What a screenshot cannot tell you: that the colours come from the theme rather than from
literals, that every visible string can be translated, that the panes do not open files
behind the service's back, and that the window still behaves like a window — dismissable,
escapable, and flushing what the user typed on the way out.
"""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
APP_DIR = ROOT / "modules/ii/notes"

APP = APP_DIR / "NotesApp.qml"
WINDOW = APP_DIR / "NotesAppWindow.qml"
CONTENT = APP_DIR / "NotesAppContent.qml"
ICON_BUTTON = APP_DIR / "NotesIconButton.qml"

GLOBAL_STATES = ROOT / "GlobalStates.qml"
CONFIG = ROOT / "modules/common/Config.qml"
PERSISTENT = ROOT / "modules/common/Persistent.qml"
FAMILY = ROOT / "panelFamilies/IllogicalImpulseFamily.qml"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def app_files():
    return sorted(APP_DIR.glob("*.qml"))


class LayoutTests(unittest.TestCase):
    def test_the_app_is_where_the_family_expects_it(self):
        self.assertTrue(APP.exists())
        self.assertTrue(WINDOW.exists())
        self.assertTrue(CONTENT.exists())
        self.assertGreaterEqual(len(app_files()), 8)


class ThemeTests(unittest.TestCase):
    def test_no_colour_is_written_by_hand(self):
        # Every colour has to come from Appearance, or the app stops following the
        # wallpaper the moment somebody changes it.
        for path in app_files():
            for number, line in enumerate(read(path).splitlines(), start=1):
                if "Qt.rgba(0, 0, 0," in line:
                    # The scrim behind the panel. It is darkness, not a theme colour, and
                    # the game overlay's dim is written the same way for the same reason.
                    continue
                found = re.search(r'"#[0-9a-fA-F]{3,8}"', line)
                if found:
                    self.fail(f"{path.name}:{number} hardcodes {found.group(0)}")

    def test_shape_and_motion_come_from_the_tokens(self):
        # The window itself draws no chrome any more — the compositor frames a toplevel —
        # so the shape tokens live where the shapes are.
        for name in ("NotesNavigationRail.qml", "NotesList.qml", "NotesDetail.qml"):
            self.assertIn("Appearance.rounding.", read(APP_DIR / name))
        for name in ("NotesRailItem.qml", "NotesListCard.qml"):
            self.assertIn("Appearance.animation.elementMoveFast", read(APP_DIR / name))

    def test_selection_changes_shape_and_not_only_colour(self):
        # Expressive says the selected thing is a different shape. It is also what keeps
        # the state readable in a theme where the container colour is quiet.
        for name in ("NotesRailItem.qml", "NotesListCard.qml"):
            body = read(APP_DIR / name)
            self.assertIn("topIsPill", body, f"{name} does not reshape on selection")
            self.assertIn("bottomIsPill", body)
            self.assertIn("NotesMetrics.pillRadius", body)

    def test_rows_are_shaped_as_a_group(self):
        # A stack of rows reads as one block, shaped at its ends, and the selected row
        # rounds fully and steps out of it. It is how the Cheatsheet's mail sidebar divides
        # a list into groups without drawing anything between them.
        for name in ("NotesRailItem.qml", "NotesListCard.qml"):
            body = read(APP_DIR / name)
            self.assertIn("property bool isFirst", body)
            self.assertIn("property bool isLast", body)
            self.assertIn("NotesMetrics.groupEndRadius", body)

    def test_nothing_is_separated_by_a_line(self):
        # The house style separates sections with air and a corner radius, never a rule.
        # What that forbids is a hairline rectangle spanning a pane — not the outline
        # colour itself. The mail sidebar's own search field is an outlined pill, and an
        # outline around a control is not a divider between sections.
        hairline = re.compile(r"^\s*(?:Layout\.preferred)?(?:width|height|Width|Height):\s*1\s*$")
        for path in app_files():
            for number, line in enumerate(read(path).splitlines(), start=1):
                if hairline.match(line):
                    self.fail(f"{path.name}:{number} looks like a divider rule")

    def test_each_pane_contains_its_own_content(self):
        # The slab is a sibling of the content, so its own `clip` contains nothing. Without
        # a clip on the pane itself, a list long enough to scroll draws cards outside the
        # rounded rectangle they are supposed to live in.
        for name in ("NotesNavigationRail.qml", "NotesList.qml", "NotesDetail.qml"):
            body = read(APP_DIR / name)
            head = body[:body.index("Rectangle {")]
            self.assertIn("clip: true", head, f"{name} does not clip its own bounds")

    def test_the_gap_between_panes_survives_a_collapsed_rail(self):
        # The splitter *is* the gap — the row carries no spacing of its own — so hiding it
        # with the rail collapsed left the two slabs touching.
        content = read(CONTENT)
        self.assertIn("visible: !root.compact\n", content)
        self.assertIn("resizable: root.railExpanded", content)
        self.assertIn("spacing: 0", content)

    def test_panes_are_opaque_slabs(self):
        # The theme's layered colours are transparency-adjusted and collapse into each
        # other over a wallpaper: measured on a real screenshot, two adjacent panes came
        # out one channel-step apart. These surfaces are opaque, and they are the ones the
        # Cheatsheet's own pages use.
        for name in ("NotesNavigationRail.qml", "NotesList.qml", "NotesDetail.qml"):
            body = read(APP_DIR / name)
            self.assertIn("Appearance.m3colors.m3surfaceContainerHigh", body,
                          f"{name} is not drawn as a slab")
            self.assertIn("radius: Appearance.rounding.large", body)


class PageAndMediaTests(unittest.TestCase):
    def test_the_page_is_drawn_procedurally_and_scrolls_with_the_text(self):
        # A tiled image would have to be regenerated whenever the spacing, the colour or
        # the theme changed, and would stretch its squares out of square with the pane.
        paper = read(APP_DIR / "NotesPaper.qml")
        self.assertIn("ShaderEffect", paper)
        self.assertIn('fragmentShader: "shaders/paper.frag.qsb"', paper)
        self.assertIn("property real scrollOffset", paper)
        self.assertTrue((APP_DIR / "shaders/paper.frag").exists(), "the shader source is missing")
        self.assertTrue((APP_DIR / "shaders/paper.frag.qsb").exists(), "the shader is not compiled")

    def test_the_page_colour_comes_from_the_theme(self):
        # Paper that stayed the same shade when the wallpaper changed would be the one
        # surface in the app that did.
        paper = read(APP_DIR / "NotesPaper.qml")
        self.assertIn("Appearance.colors.colOutlineVariant", paper)

    def test_a_picture_is_never_enlarged_past_its_own_size(self):
        # A 320px screenshot stretched to the reading measure is a blurred screenshot.
        block = read(APP_DIR / "editor/NoteImageBlock.qml")
        self.assertIn("image.implicitWidth", block)
        self.assertIn("Math.min(root.available * root.widthFraction", block)

    def test_a_picture_keeps_its_place_at_any_window_size(self):
        # Stored as a fraction of the reading measure, so the same note does not disagree
        # with itself on two monitors.
        block = read(APP_DIR / "editor/NoteImageBlock.qml")
        self.assertIn("widthFraction", block)
        self.assertIn("patch: { width: fraction }", read(APP_DIR / "editor/NotesEditor.qml"))

    def test_a_pasted_file_is_copied_into_the_note(self):
        # By name, from the store: the helper renames around a collision, so a block
        # written before the copy answered could point at a name that was changed.
        editor = read(APP_DIR / "editor/NotesEditor.qml")
        self.assertIn("NotesService.importAsset", editor)
        self.assertIn("onAssetImported", editor)
        self.assertIn("DropArea", editor)

    def test_code_and_table_do_not_take_part_in_the_typing_shortcuts(self):
        # Inside code, "# " is a comment and "- " is a flag; a block that converted itself
        # while somebody pasted a diff would be unusable.
        shortcuts = read(ROOT / "services/notes/NotesShortcuts.js")
        self.assertIn('if (block.type !== "text")', shortcuts)


class InkTests(unittest.TestCase):
    def test_the_drawing_engine_is_reused_not_rewritten(self):
        # Pressure through a PointHandler, three smoothing passes, pressure into width with
        # a floor — none of that arithmetic is reimplemented here.
        sheet = read(APP_DIR / "sketch/NotesInkSheet.qml")
        self.assertIn("DrawSurface", sheet)
        self.assertIn("StrokeGeometry", sheet)
        # As a declaration, not as a substring: the file's own comment explains that
        # `DrawSurface` uses one, and matching prose is not a contract.
        self.assertNotIn("PointHandler {", sheet, "the sheet should not reimplement input")

    def test_the_strokes_are_kept_beside_the_picture(self):
        # The picture is what every surface shows. The strokes are what makes a second
        # edit continue the drawing instead of painting over a flat image.
        sheet = read(APP_DIR / "sketch/NotesInkSheet.qml")
        self.assertIn("NotesService.readStrokes", sheet)
        self.assertIn("NotesService.writeStrokes", sheet)
        self.assertIn("property var undone", sheet)

    def test_the_image_is_written_only_once_the_folder_exists(self):
        # A grab written into a folder that a fired-and-forgotten mkdir had not created is
        # a race whose loser is the drawing.
        sheet = read(APP_DIR / "sketch/NotesInkSheet.qml")
        self.assertIn("NotesService.prepareAssets", sheet)
        self.assertIn("onAssetsReady", sheet)
        self.assertIn("grabToImage", sheet)
        self.assertIn("saveToFile", sheet)
        # Canvas.save resolves against the component's base URL, which under Quickshell is
        # always a qs: URL, and then fails for a perfectly valid absolute path.
        self.assertNotIn("Canvas.save(", sheet)

    def test_a_drawing_is_saved_as_ink_on_transparency(self):
        # The tablet's live draw has always saved that way, which is why the migrated
        # sketches have an alpha channel and sit on whatever is behind them. Baking the
        # sheet's surface into the file put every drawing in a black box.
        sheet = read(APP_DIR / "sketch/NotesInkSheet.qml")
        self.assertIn("property bool grabbing", sheet)
        self.assertIn('color: root.grabbing ? "transparent"', sheet)
        self.assertIn("visible: !root.grabbing", sheet)
        # And nothing paints a slab behind it afterwards.
        block = read(APP_DIR / "editor/NoteInkBlock.qml")
        self.assertIn('color: "transparent"', block)

    def test_the_capture_waits_a_frame(self):
        # Hiding the surface and grabbing in the same turn captures the frame already on
        # screen, which is the one with the surface still in it.
        sheet = read(APP_DIR / "sketch/NotesInkSheet.qml")
        self.assertIn("grabTimer.restart()", sheet)
        self.assertIn("function captureImage()", sheet)

    def test_the_ink_colour_is_measured_against_the_paper(self):
        # "Darkest in the palette" is right only half the time: on a dark theme the darkest
        # ink is invisible and the pen looks broken.
        sheet = read(APP_DIR / "sketch/NotesInkSheet.qml")
        # Against the surface the drawing will be *shown* on, which is the reading pane's.
        self.assertIn("hslLightness", sheet)
        self.assertIn("m3surfaceContainerHigh", sheet)

    def test_a_pen_tap_on_a_tool_is_not_a_stroke(self):
        # A MouseArea never sees a tablet event: Qt synthesises a mouse event from a stylus
        # one only if nobody accepted the stylus event first, and the drawing surface is a
        # PointHandler, which accepts them natively.
        button = read(APP_DIR / "sketch/NotesInkToolButton.qml")
        self.assertIn("acceptedDevices: PointerDevice.Stylus", button)
        sheet = read(APP_DIR / "sketch/NotesInkSheet.qml")
        self.assertIn("excludeItem: tray", sheet)

    def test_the_ink_palette_is_the_documented_exception(self):
        # Pigment, not chrome. Ink that re-tinted itself with the theme would be ink nobody
        # could trust — and it is the same palette the tablet's live draw uses.
        sheet = read(APP_DIR / "sketch/NotesInkSheet.qml")
        self.assertIn("Config.options?.tablet?.liveDraw", sheet)


class TranslationTests(unittest.TestCase):
    def test_every_visible_string_can_be_translated(self):
        # A literal in a `text:` assignment is a string nobody outside en_US will read.
        pattern = re.compile(r'^\s*(?:text|title|description|tooltipText|buttonText|label):\s*"([^"]+)"')
        for path in app_files():
            for number, line in enumerate(read(path).splitlines(), start=1):
                # `GlobalShortcut.description` is compositor metadata — it shows up in
                # `hyprctl globalshortcuts`, not in the app — and the rest of the shell
                # writes those in plain English too.
                if path.name == "NotesApp.qml" and line.strip().startswith("description:"):
                    continue
                # The window title is an identifier, not a label: the Hyprland rule that
                # floats and centres this window matches on it, and a translated one would
                # match nothing on a system that is not in English.
                if path.name == "NotesAppWindow.qml" and line.strip().startswith("title:"):
                    continue
                found = pattern.match(line)
                if not found:
                    continue
                value = found.group(1)
                # Material Symbol names and other identifiers are not prose.
                if re.fullmatch(r"[a-z0-9_]*", value):
                    continue
                self.fail(f"{path.name}:{number} has an untranslated string: {value!r}")


class OwnershipTests(unittest.TestCase):
    def test_the_panes_never_open_a_file(self):
        # One writer. The service owns the store; a pane that read it directly would race
        # the debounce it cannot see.
        for path in app_files():
            body = read(path)
            self.assertNotIn("FileView", body, f"{path.name} opens a file itself")
            self.assertNotIn("Directories.notes", body, f"{path.name} reaches for a store path")

    def test_the_list_is_drawn_from_the_index_alone(self):
        # Not one card opens a document to render itself. That is the entire reason the
        # store keeps an index.
        card = read(APP_DIR / "NotesListCard.qml")
        self.assertNotIn("documentOf", card)
        self.assertIn("root.note.preview", card)


class WindowBehaviourTests(unittest.TestCase):
    def test_the_window_is_an_ordinary_application_window(self):
        # Not a layer surface. A layer surface floats above every workspace, belongs to
        # none, and is dismissed by a click anywhere outside it — right for a reference
        # card, wrong for somewhere you write, where clicking another window to read
        # something must not throw away what you were looking at.
        window = read(WINDOW)
        self.assertIn("FloatingWindow {", window)
        self.assertIn('title: "ii Notes"', window)
        for overlay_only in ("WlrLayershell", "mask: Region", "GlobalFocusGrab"):
            self.assertNotIn(overlay_only, window,
                             f"the window still behaves like an overlay ({overlay_only})")

    def test_the_window_opens_large(self):
        # A document window. Two panes of chrome and a page to write on do not fit in the
        # size a dialog gets.
        window = read(WINDOW)
        self.assertIn("implicitWidth: Math.max(", window)
        self.assertIn("minimumSize", window)

    def test_closing_the_window_does_not_lose_what_was_typed(self):
        window = read(WINDOW)
        self.assertIn("Component.onDestruction", window)
        self.assertIn("NotesService.flush()", window)

    def test_a_compositor_close_clears_the_shell_state(self):
        # The compositor can close a toplevel without asking. If the flag it was opened
        # with is not cleared, the next open only toggles something that was never reset.
        self.assertIn("onVisibleChanged", read(WINDOW))
        self.assertIn("GlobalStates.notesAppOpen = false", read(WINDOW))

    def test_escape_closes_and_does_the_smaller_thing_first(self):
        # A window shortcut, not a key handler on an item. `Keys.onPressed` fires only
        # while something focusable holds focus, so the moment the note title stopped
        # claiming focus on open, every one of these stopped existing.
        content = read(CONTENT)
        self.assertIn('sequences: ["Escape"]', content)
        self.assertIn("context: Qt.WindowShortcut", content)
        self.assertIn("closeRequested()", content)
        # Checked as a binding, not as a substring: the file's own comment explains why
        # `Keys.onPressed` is not used here, and matching prose is not a contract.
        # The per-block editing keys in NoteTextBlock are a different thing and correct —
        # those belong to the text item that has the caret.
        for line in content.splitlines():
            self.assertFalse(line.strip().startswith("Keys.onPressed"),
                             "app-level keys must be window shortcuts")

    def test_the_editor_is_the_one_place_blocks_change(self):
        # Undo, redo and revision history all read the inverse of an operation. A pane
        # that mutated a block on its own would produce none.
        editor = read(APP_DIR / "editor/NotesEditor.qml")
        self.assertIn("function apply(", editor)
        self.assertIn("NotesService.applyOps", editor)
        for name in ("NoteTextBlock.qml", "NoteDividerBlock.qml", "NoteMediaBlock.qml"):
            self.assertNotIn("applyOps", read(APP_DIR / "editor" / name),
                             f"{name} applies operations itself")

    def test_typing_never_rebuilds_the_row_the_caret_is_in(self):
        # The delegate owns its text while it is being typed in. Feeding every keystroke
        # back through the model rebuilds the row and drops the caret to the start of the
        # line on every character.
        editor = read(APP_DIR / "editor/NotesEditor.qml")
        # Everything except the text has to reach the delegate. An earlier version
        # compared only id, type and indent, and a drawing then saved its picture and its
        # strokes to disk while the block on screen never heard about either.
        self.assertIn("function signatureOf(", editor)
        self.assertIn("root.signatureOf(next) !== root.signatureOf(root.blocks)", editor)
        self.assertIn('if (key !== "text")', editor)
        self.assertIn("commitText(blockId, text)", editor)

    def test_a_focus_request_is_only_spent_once_it_lands(self):
        # Clearing it when a delegate merely answered let one that was about to be rebuilt
        # swallow the request, and the caret never came back after a markdown conversion.
        editor = read(APP_DIR / "editor/NotesEditor.qml")
        self.assertIn("function peekFocus(", editor)
        self.assertIn("function clearFocusRequest(", editor)
        block = read(APP_DIR / "editor/NoteTextBlock.qml")
        self.assertIn("if (editText.activeFocus)", block)
        self.assertIn("clearFocusRequest", block)

    def test_no_active_element_is_a_full_pill(self):
        # `height / 2` is the classic pill formula and it breaks on anything tall: the
        # curve eats the content's corners and leaves crescent gaps against the rows above
        # and below. The Settings design system caps it at the `large` token, and that cap
        # lives in one function so it cannot be forgotten in one file.
        self.assertIn("function pillRadius", read(APP_DIR / "NotesMetrics.qml"))
        self.assertIn("Math.min(itemHeight / 2, Appearance.rounding.large)",
                      read(APP_DIR / "NotesMetrics.qml"))
        # Only the corner radii of the big rows are checked. `rounding.full` on a 26px
        # count badge is a circle, which is what it should be; the rule is about elements
        # tall enough for a half-height radius to swallow their own content.
        corners = re.compile(r"^\s*(?:top|bottom)(?:Left|Right)Radius:.*rounding\.full")
        for name in ("NotesRailItem.qml", "NotesListCard.qml", "NotesNavigationRail.qml",
                     "NotesSearchBox.qml"):
            body = read(APP_DIR / name)
            for number, line in enumerate(body.splitlines(), start=1):
                if corners.match(line):
                    self.fail(f"{name}:{number} rounds a row with an uncapped pill")
            # A row's own height must go through the cap, so a future edit cannot quietly
            # reintroduce a raw half-height on something tall.
            if name != "NotesNavigationRail.qml":
                self.assertIn("NotesMetrics.pillRadius", body,
                              f"{name} does not cap its pill radius")

    def test_selection_reshapes_its_neighbours_too(self):
        # The Settings sidebar's scheme: the edges facing the selected row round as well,
        # so the selection presses a notch into the group instead of floating in a hole cut
        # out of it.
        for name in ("NotesRailItem.qml", "NotesListCard.qml"):
            body = read(APP_DIR / name)
            self.assertIn("prevIsCurrent", body)
            self.assertIn("nextIsCurrent", body)

    def test_touch_targets_are_not_smaller_than_the_project_allows(self):
        # The app runs on the tablet family too.
        self.assertIn("property real size: 44", read(ICON_BUTTON))


class WiringTests(unittest.TestCase):
    def test_the_app_has_its_own_open_state_separate_from_the_overlay_widget(self):
        # `notesOpen` has meant the small game-overlay note for a long time. One flag for
        # both would make opening the app close the note somebody was reading.
        states = read(GLOBAL_STATES)
        self.assertIn("property bool notesAppOpen: false", states)
        self.assertIn("property bool notesOpen: false", states)
        self.assertIn("function openNotes(", states)

    def test_every_way_in_ends_at_the_same_state(self):
        app = read(APP)
        for shortcut in ("notesToggle", "notesOpen", "notesClose"):
            self.assertIn(f'name: "{shortcut}"', app)
        self.assertIn('target: "notes"', app)
        for command in ("open", "close", "toggle", "openNote", "capture", "list"):
            self.assertIn(f"function {command}(", app)

    def test_only_the_switches_that_belong_outside_the_app_are_outside_it(self):
        # Everything about how notes look and behave lives in the app, where the person
        # changing it can see what they are changing.
        config = read(CONFIG)
        opening = "property JsonObject notes: JsonObject {"
        block = config[config.index(opening) + len(opening):]
        block = block[:block.index("}")]
        self.assertIn("property bool enable: true", block)
        self.assertEqual(block.count("property"), 1, "general settings gained a notes option")

    def test_the_window_geometry_is_a_fact_about_this_machine(self):
        # Persistent, not Config: a preset carrying somebody else's geometry would put the
        # window on a monitor that does not exist here.
        persistent = read(PERSISTENT)
        block = persistent[persistent.index("property JsonObject notes: JsonObject {"):]
        for name in ("width", "height", "noteId", "scope"):
            self.assertIn(name, block[:900])

    def test_the_family_builds_the_app_and_the_switch_can_turn_it_off(self):
        family = read(FAMILY)
        self.assertIn("import qs.modules.ii.notes", family)
        self.assertIn("extraCondition: Config.options.notes.enable", family)
        self.assertIn("component: NotesApp {}", family)


if __name__ == "__main__":
    unittest.main()
