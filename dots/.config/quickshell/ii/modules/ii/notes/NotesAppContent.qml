pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.notes

/**
 * The app inside the window: a rail of places, a list of notes, and the note itself.
 *
 * Three panes because notes are three questions at once — *where am I*, *which note*, and
 * *what does it say* — and answering them in one column means a trip back and forth for
 * every note anyone looks at. It collapses to two and then to one, in that order, because
 * the rail is the part a person can hold in their head and the note is the part they
 * cannot.
 */
Item {
    id: root

    signal closeRequested()

    readonly property var state: Persistent.states.notes

    // ── Breakpoints ───────────────────────────────────────────────────────
    // Measured from the panel, never from the screen: the window is resizable, and a
    // layout that reads the monitor would keep a three-pane layout inside a panel far too
    // narrow for it.
    readonly property bool compact: root.width < 760
    readonly property bool railExpanded: root.width >= 1100 && root.state.railExpanded

    // ── Selection ─────────────────────────────────────────────────────────

    readonly property string query: rail.query

    readonly property bool trashScope: root.state.scope === "trash"

    /// Every note the current place contains, before the search box narrows it.
    readonly property var scopedNotes: {
        const all = Array.from(NotesService.index.notes ?? []);
        const scope = root.state.scope;
        if (scope === "trash")
            return all.filter(note => note.trashedAt > 0);
        const live = all.filter(note => note.trashedAt === 0);
        if (scope === "favorites")
            return live.filter(note => note.favorite);
        if (scope === "recent")
            return live.slice().sort((a, b) => b.modified - a.modified).slice(0, 20);
        if (scope === "all" || scope.length === 0)
            return live;
        return live.filter(note => note.notebookId === scope || note.sectionId === scope);
    }

    readonly property var visibleNotes: {
        const term = root.query.trim().toLowerCase();
        const scoped = root.scopedNotes;
        const matched = term.length === 0 ? scoped : scoped.filter(note =>
            note.title.toLowerCase().includes(term) || note.preview.toLowerCase().includes(term));
        // Pinned first, then most recently touched. Sorted here rather than in the model so
        // the empty state and the count agree with what is drawn.
        return matched.slice().sort((a, b) => {
            if (a.pinned !== b.pinned)
                return a.pinned ? -1 : 1;
            return b.modified - a.modified;
        });
    }

    readonly property string selectedId: {
        const wanted = root.state.noteId;
        if (root.visibleNotes.some(note => note.id === wanted))
            return wanted;
        return root.visibleNotes.length > 0 ? root.visibleNotes[0].id : "";
    }

    readonly property var selectedNote: root.visibleNotes.find(note => note.id === root.selectedId) ?? null

    /// The bar says where you are, not what you have open. The note's own title is right
    /// there in the pane beside it, and printing it twice tells the reader nothing and
    /// costs them the one thing the bar could have said.
    readonly property string scopeName: {
        const scope = root.state.scope;
        if (scope === "trash")
            return Translation.tr("Trash");
        if (scope === "favorites")
            return Translation.tr("Favourites");
        if (scope === "recent")
            return Translation.tr("Recent");
        if (scope === "all" || scope.length === 0)
            return Translation.tr("All notes");
        for (const notebook of NotesService.notebooks) {
            if (notebook.id === scope)
                return notebook.title;
            for (const section of notebook.sections) {
                if (section.id === scope)
                    return `${notebook.title} · ${section.title}`;
            }
        }
        return Translation.tr("All notes");
    }

    function select(noteId): void {
        root.state.noteId = String(noteId ?? "");
        if (root.compact)
            root.showingDetail = true;
    }

    /// Only meaningful in the one-pane layout, where list and note take turns.
    property bool showingDetail: false

    // ── Actions ───────────────────────────────────────────────────────────

    function createNote(): void {
        const noteId = NotesService.createNote({ title: "" });
        root.state.noteId = noteId;
        root.showingDetail = true;
        // On a timer rather than the next turn of the loop. The window's own focus chain
        // hands active focus to the first text item in it — the note's title — when the
        // toplevel is activated, and that happens after the callLater would have run: the
        // caret ended up in the title and the first thing typed renamed the note.
        editorFocusTimer.restart();
    }

    function deleteSelected(): void {
        if (root.selectedId.length === 0)
            return;
        if (root.trashScope)
            NotesService.purgeNote(root.selectedId);
        else
            NotesService.deleteNote(root.selectedId);
        root.state.noteId = "";
    }

    function restoreSelected(): void {
        if (root.selectedId.length > 0)
            NotesService.restoreNote(root.selectedId);
    }

    function toggleFavorite(): void {
        const note = root.selectedNote;
        if (note)
            NotesService.updateMeta(note.id, { favorite: !note.favorite });
    }

    function togglePinned(): void {
        const note = root.selectedNote;
        if (note)
            NotesService.updateMeta(note.id, { pinned: !note.pinned });
    }

    // A note the app was asked to open, from a widget, the overlay or an IPC call.
    function consumePendingNote(): void {
        const wanted = GlobalStates.notesAppPendingNote;
        if (wanted.length === 0)
            return;
        GlobalStates.notesAppPendingNote = "";
        if (NotesService.notes.some(note => note.id === wanted)) {
            root.state.scope = "all";
            root.select(wanted);
            // Asked for by name, from a widget, the overlay or a script: whoever sent that
            // wants to work on this note, not to look at a list with it highlighted.
            editorFocusTimer.restart();
        }
    }

    Timer {
        id: editorFocusTimer
        interval: 120
        onTriggered: detail.focusEditor()
    }

    Component.onCompleted: root.consumePendingNote()

    Connections {
        target: GlobalStates
        function onNotesAppPendingNoteChanged() {
            root.consumePendingNote();
        }
    }

    /**
     * The app's own shortcuts.
     *
     * `Shortcut` rather than `Keys.onPressed`, because these belong to the window and not
     * to whichever item happens to hold focus. The key handler worked only while something
     * focusable was focused, and the moment the note title stopped claiming focus on open,
     * Ctrl+N stopped existing.
     */
    Shortcut {
        sequences: ["Ctrl+N"]
        context: Qt.WindowShortcut
        onActivated: root.createNote()
    }

    Shortcut {
        sequences: ["Ctrl+F"]
        context: Qt.WindowShortcut
        onActivated: rail.focusSearch()
    }

    Shortcut {
        sequences: ["Escape"]
        context: Qt.WindowShortcut
        onActivated: {
            // The smallest thing first: back out of the note, then clear the search, and
            // only close the window when there is nothing left to back out of.
            if (root.compact && root.showingDetail)
                root.showingDetail = false;
            else if (rail.query.length > 0)
                rail.clearSearch();
            else
                root.closeRequested();
        }
    }

    // ── Layout ────────────────────────────────────────────────────────────

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: NotesMetrics.paneGap
        spacing: NotesMetrics.paneGap

        NotesTopBar {
            id: topBar
            Layout.fillWidth: true
            title: root.scopeName
            subtitle: root.query.trim().length > 0
                ? Translation.tr("%1 of %2 notes").arg(root.visibleNotes.length).arg(root.scopedNotes.length)
                : Translation.tr("%1 notes").arg(root.visibleNotes.length)
            showBack: root.compact && root.showingDetail
            showRailToggle: !root.compact && root.width >= 1100
            railExpanded: root.railExpanded

            onRailToggled: root.state.railExpanded = !root.state.railExpanded
            onBackRequested: root.showingDetail = false
            onCloseRequested: root.closeRequested()
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            // Zero, because the gap between panes is now a splitter that occupies it. Two
            // sources of the same space would make the seam twice as wide as it looks.
            spacing: 0

            NotesNavigationRail {
                id: rail
                Layout.fillHeight: true
                Layout.preferredWidth: expanded
                    ? Math.max(NotesMetrics.railMinimumWidth,
                               Math.min(NotesMetrics.railMaximumWidth, root.state.railWidth))
                    : NotesMetrics.railCollapsedWidth
                visible: !root.compact
                expanded: root.railExpanded
                scope: root.state.scope

                onScopePicked: scope => {
                    root.state.scope = scope;
                    root.state.noteId = "";
                }
                onCreateRequested: root.createNote()
                // The app's own settings sheet does not exist yet; until it does this
                // opens the one switch about Notes that lives outside the app, rather
                // than being a button that does nothing.
                onSettingsRequested: GlobalStates.openSettingsPage("overlays", "", "")

                Behavior on Layout.preferredWidth {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }

            NotesPaneSplitter {
                Layout.fillHeight: true
                visible: !root.compact && root.railExpanded
                onMoved: delta => root.state.railWidth = Math.max(NotesMetrics.railMinimumWidth,
                    Math.min(NotesMetrics.railMaximumWidth, root.state.railWidth + delta))
            }

            NotesList {
                id: notesList
                Layout.fillHeight: true
                Layout.preferredWidth: root.compact
                    ? root.width
                    : Math.max(NotesMetrics.listMinimumWidth,
                               Math.min(NotesMetrics.listMaximumWidth, root.state.listWidth))
                Layout.fillWidth: root.compact
                visible: !root.compact || !root.showingDetail
                notes: root.visibleNotes
                selectedId: root.selectedId
                searching: root.query.trim().length > 0
                trash: root.trashScope

                onNotePicked: noteId => root.select(noteId)
            }

            NotesPaneSplitter {
                Layout.fillHeight: true
                visible: !root.compact
                onMoved: delta => root.state.listWidth = Math.max(NotesMetrics.listMinimumWidth,
                    Math.min(NotesMetrics.listMaximumWidth, root.state.listWidth + delta))
            }

            NotesDetail {
                id: detail
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !root.compact || root.showingDetail
                note: root.selectedNote
                trash: root.trashScope

                onDeleteRequested: root.deleteSelected()
                onRestoreRequested: root.restoreSelected()
                onFavoriteToggled: root.toggleFavorite()
                onPinToggled: root.togglePinned()
                onTitleEdited: title => {
                    if (root.selectedId.length > 0)
                        NotesService.updateMeta(root.selectedId, { title: title });
                }
            }
        }
    }
}
