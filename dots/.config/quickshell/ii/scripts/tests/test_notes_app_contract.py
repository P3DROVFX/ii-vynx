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
        # A one-pixel Rectangle spanning a pane is how that decision gets undone by
        # accident, so it is refused here rather than noticed later in a screenshot.
        for path in app_files():
            body = read(path)
            for marker in ("colOutlineVariant", "colOutline\b"):
                self.assertNotIn("colOutlineVariant", body,
                                 f"{path.name} draws a divider line")

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
        content = read(CONTENT)
        self.assertIn("Qt.Key_Escape", content)
        self.assertIn("closeRequested()", content)

    def test_no_active_element_is_a_full_pill(self):
        # `height / 2` is the classic pill formula and it breaks on anything tall: the
        # curve eats the content's corners and leaves crescent gaps against the rows above
        # and below. The Settings design system caps it at the `large` token, and that cap
        # lives in one function so it cannot be forgotten in one file.
        self.assertIn("function pillRadius", read(APP_DIR / "NotesMetrics.qml"))
        self.assertIn("Math.min(itemHeight / 2, Appearance.rounding.large)",
                      read(APP_DIR / "NotesMetrics.qml"))
        for name in ("NotesRailItem.qml", "NotesListCard.qml", "NotesNavigationRail.qml"):
            body = read(APP_DIR / name)
            self.assertNotIn("Appearance.rounding.full", body,
                             f"{name} uses an uncapped pill radius")

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
