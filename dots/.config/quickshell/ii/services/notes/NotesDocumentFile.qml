pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import "NotesDocument.js" as Doc

/**
 * One note's document on disk, and the debounce that keeps typing off the filesystem.
 *
 * There is one of these per resident note, which is the whole point of splitting the
 * store: a keystroke in this note rewrites this file and touches nothing else. The old
 * `notes.json` read and rewrote every note on every character, and that is why a drawing
 * had to be stored there as a path rather than as pixels.
 *
 * The debounce is per note rather than global for the same reason. A single shared timer
 * would mean that typing in one note delays the save of another, and that a flush of one
 * writes both.
 */
Scope {
    id: root

    required property string noteId
    required property string path

    /// The document as it currently is. Assigned by the store; written out on a delay.
    property var document: null

    /**
     * The document of a note that was made a moment ago, handed over instead of read.
     *
     * A new note's index entry is written first, so the note exists the instant it is
     * made — which means this object is created before any file exists for it. Reading
     * one anyway works, but it logs a failed read for every note anybody creates, and a
     * log full of "read failed" is a log nobody trusts.
     */
    property var initialDocument: null

    property int debounceInterval: 400
    /// A write happens at least this often while somebody is still typing. Without a
    /// ceiling the debounce never fires during continuous typing, and a long paragraph
    /// exists only in memory until the user pauses.
    property int maximumHold: 3000

    property bool loaded: false
    property bool writing: false
    property bool dirty: false

    signal documentLoaded(string noteId, var value)
    signal documentSaved(string noteId)
    signal documentFailed(string noteId, string reason)

    /// Set the document and schedule a write. The only way content reaches the disk.
    function put(value): void {
        root.document = Doc.normalizeDocument(value, root.noteId);
        root.dirty = true;
        if (!holdTimer.running)
            holdTimer.restart();
        debounce.restart();
    }

    function flush(): void {
        if (!root.dirty || root.document === null)
            return;
        debounce.stop();
        holdTimer.stop();
        const payload = JSON.stringify(root.document, null, 2);
        // FileView drops a setText identical to what it already holds and emits no signal
        // for it, so waiting for one would wait forever.
        if (payload === file.text()) {
            root.dirty = false;
            root.writing = false;
            root.documentSaved(root.noteId);
            return;
        }
        root.dirty = false;
        root.writing = true;
        watchdog.restart();
        file.setText(payload);
    }

    function reload(): void {
        file.reload();
    }

    Timer {
        id: debounce
        interval: root.debounceInterval
        onTriggered: root.flush()
    }

    Timer {
        id: holdTimer
        interval: root.maximumHold
        onTriggered: root.flush()
    }

    Timer {
        // A write that never reports back must not leave the note marked as saving
        // forever; the UI reads that flag.
        id: watchdog
        interval: 2000
        onTriggered: {
            root.writing = false;
            if (root.dirty)
                debounce.restart();
        }
    }

    FileView {
        id: file
        path: Qt.resolvedUrl(root.path)
        atomicWrites: true
        // A FileView reads as soon as it has a path. For a note created a moment ago there
        // is nothing to read, and letting it try logs a failed read for every note anybody
        // makes — which teaches whoever reads the log to ignore failed reads.
        preload: root.initialDocument === null

        onLoaded: {
            root.loaded = true;
            // A reload triggered by our own write must not clobber newer edits sitting in
            // the debounce.
            if (root.writing || root.dirty)
                return;
            var parsed = null;
            try {
                parsed = JSON.parse(file.text());
            } catch (error) {
                parsed = null;
            }
            root.document = Doc.migrateDocument(parsed, root.noteId);
            root.documentLoaded(root.noteId, root.document);
        }

        onSaved: {
            watchdog.stop();
            root.writing = false;
            root.documentSaved(root.noteId);
            if (root.dirty)
                debounce.restart();
        }

        onSaveFailed: error => {
            watchdog.stop();
            root.writing = false;
            root.documentFailed(root.noteId, `could not write ${root.noteId}: ${error}`);
        }

        onLoadFailed: error => {
            root.loaded = true;
            if (error !== FileViewError.FileNotFound) {
                root.documentFailed(root.noteId, `could not read ${root.noteId}: ${error}`);
                return;
            }
            // A note in the index with no document yet. That is a new note, not an error:
            // the index entry is written first so the note exists the instant it is made.
            if (root.document === null)
                root.document = Doc.newDocument(root.noteId);
            root.documentLoaded(root.noteId, root.document);
        }
    }

    Component.onCompleted: {
        if (root.initialDocument !== null)
            root.put(root.initialDocument);
        else
            file.reload();
    }

    Component.onDestruction: {
        // Whatever the debounce was still holding belongs to the user.
        if (root.dirty)
            root.flush();
    }
}
