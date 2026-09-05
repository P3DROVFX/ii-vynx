pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import qs
import qs.services
import qs.modules.common

/**
 * The notes app: its lifecycle, its ways in, and nothing else.
 *
 * Same shape as the Cheatsheet, and for the same reason. This is a burst-use surface —
 * opened, used, closed — so the whole window tree is built when it is asked for and
 * released after the close animation, rather than every note staying resident for the life
 * of the shell.
 *
 * The ways in are deliberately many, because the app is only useful if capturing something
 * costs nothing: a keybind, an IPC call, a quick toggle, the game overlay, a desktop
 * widget. They all end at `GlobalStates.notesAppOpen`, which is the one piece of state
 * that says whether the window is up.
 */
Scope {
    id: root

    /// Kept true through the close animation so the window can play it before being torn
    /// down; `GlobalStates.notesAppOpen` is the intent, this is the presence.
    property bool activeState: false

    function requestOpen(noteId = ""): void {
        closeTimer.stop();
        root.activeState = true;
        if (String(noteId ?? "").length > 0)
            GlobalStates.notesAppPendingNote = String(noteId);
        if (!GlobalStates.notesAppOpen)
            GlobalStates.notesAppOpen = true;
    }

    function requestClose(): void {
        if (GlobalStates.notesAppOpen)
            GlobalStates.notesAppOpen = false;
        closeTimer.restart();
    }

    function requestToggle(): void {
        if (GlobalStates.notesAppOpen)
            root.requestClose();
        else
            root.requestOpen();
    }

    Timer {
        id: closeTimer
        // Long enough for the exit animation to finish. Tearing the tree down mid-animation
        // makes the window vanish rather than close.
        interval: 400
        onTriggered: root.activeState = false
    }

    Connections {
        target: GlobalStates
        function onNotesAppOpenChanged() {
            if (GlobalStates.notesAppOpen)
                root.requestOpen();
            else
                root.requestClose();
        }
    }

    Loader {
        id: windowLoader
        active: root.activeState
        sourceComponent: NotesAppWindow {
            onCloseRequested: root.requestClose()
        }
    }

    GlobalShortcut {
        name: "notesToggle"
        description: "Toggles the notes app"
        onPressed: root.requestToggle()
    }

    GlobalShortcut {
        name: "notesOpen"
        description: "Opens the notes app"
        onPressed: root.requestOpen()
    }

    GlobalShortcut {
        name: "notesClose"
        description: "Closes the notes app"
        onPressed: root.requestClose()
    }

    IpcHandler {
        target: "notes"

        function open(): void {
            root.requestOpen();
        }

        function close(): void {
            root.requestClose();
        }

        function toggle(): void {
            root.requestToggle();
        }

        /// Opens the app already showing one note. The id comes from `list`.
        function openNote(noteId: string): void {
            root.requestOpen(noteId);
        }

        /// A note from the outside — a script, a hotkey, another program. Capturing has to
        /// cost nothing, and opening a window first is not nothing.
        function capture(text: string): string {
            const result = NotesService.create("", String(text ?? ""), null);
            return result.ok ? "ok" : String(result.error ?? "failed");
        }

        function list(): string {
            return NotesService.notes
                .map(note => `${note.id}\t${note.title}`)
                .join("\n");
        }
    }
}
