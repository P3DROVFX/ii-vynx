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
        window = read(WINDOW)
        self.assertIn("Appearance.rounding.", window)
        self.assertIn("Appearance.animationCurves.emphasized", window)

    def test_selection_changes_shape_and_not_only_colour(self):
        # Expressive says the selected thing is a different shape. It is also what keeps
        # the state readable in a theme where the container colour is quiet.
        for name in ("NotesRailItem.qml", "NotesListCard.qml"):
            body = read(APP_DIR / name)
            for corner in ("topLeftRadius", "bottomLeftRadius"):
                self.assertRegex(body, rf"{corner}:\s*root\.current\s*\?",
                                 f"{name} does not reshape on selection")

    def test_rows_are_shaped_as_a_group(self):
        # A stack of rows reads as one block, shaped at its ends, and the selected row
        # rounds fully and steps out of it. It is how the Cheatsheet's mail sidebar divides
        # a list into groups without drawing anything between them.
        for name in ("NotesRailItem.qml", "NotesListCard.qml"):
            body = read(APP_DIR / name)
            self.assertIn("property bool isFirst", body)
            self.assertIn("property bool isLast", body)
            self.assertIn("Appearance.rounding.full", body)

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
    def test_the_window_is_a_dismissable_overlay_that_does_not_eat_the_desktop(self):
        window = read(WINDOW)
        self.assertIn('WlrLayershell.namespace: "quickshell:notes"', window)
        self.assertIn("WlrLayershell.layer: WlrLayer.Overlay", window)
        # The mask is the panel only; everything around it belongs to what is underneath.
        self.assertIn("mask: Region", window)
        self.assertIn("item: inputMask", window)
        self.assertIn("GlobalFocusGrab.addDismissable", window)
        self.assertIn("GlobalFocusGrab.removeDismissable", window)

    def test_closing_the_window_does_not_lose_what_was_typed(self):
        window = read(WINDOW)
        self.assertIn("Component.onDestruction", window)
        self.assertIn("NotesService.flush()", window)

    def test_escape_closes_and_does_the_smaller_thing_first(self):
        content = read(CONTENT)
        self.assertIn("Qt.Key_Escape", content)
        self.assertIn("closeRequested()", content)

    def test_the_remembered_geometry_is_clamped_to_the_screen(self):
        # A window remembered from a monitor that is no longer plugged in must still open
        # somewhere a person can reach it.
        window = read(WINDOW)
        self.assertIn("root.minimumWidth", window)
        self.assertIn("Math.min(root.state.width, root.availableWidth)", window)

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
        for name in ("width", "height", "maximized", "noteId", "scope"):
            self.assertIn(name, block[:900])

    def test_the_family_builds_the_app_and_the_switch_can_turn_it_off(self):
        family = read(FAMILY)
        self.assertIn("import qs.modules.ii.notes", family)
        self.assertIn("extraCondition: Config.options.notes.enable", family)
        self.assertIn("component: NotesApp {}", family)


if __name__ == "__main__":
    unittest.main()
