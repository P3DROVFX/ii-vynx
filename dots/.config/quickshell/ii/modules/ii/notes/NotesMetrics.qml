pragma Singleton

import QtQuick
import Quickshell

import qs.modules.common

/**
 * One place for every measurement in the notes app.
 *
 * The alignments went wrong the first time in exactly the way they always do: each file
 * chose its own margin, two of them differed by two pixels, and the result reads as
 * sloppy without anyone being able to point at which number is wrong. So the numbers live
 * here, they are few, and every pane uses them.
 *
 * The scale is 4, which is what the Material spacing scale is built on. Everything below
 * is a multiple of it.
 */
Singleton {
    /// Between the window edge and a pane, and between two panes.
    ///
    /// This gap *is* the separation between sections. The Cheatsheet's pages — timetable,
    /// mail, keybinds — are all built this way: opaque rounded slabs with air between
    /// them, never a rule drawn down the middle. A line says "these are two things"; a gap
    /// and a corner radius show it.
    readonly property int paneGap: 12

    /// Distance from the edge of a pane to its content.
    readonly property int panePadding: 10

    /// Distance from the edge of a card to its text. Larger than the pane padding, so the
    /// text inside a card is never closer to the card edge than the card is to the pane.
    readonly property int cardPadding: 16

    /// Vertical padding inside a list row.
    ///
    /// Smaller than the horizontal padding on purpose. An unfilled row has no edge of its
    /// own, so its padding *is* the space between it and the next one — count it twice,
    /// add the spacing, and generous padding turns a list into a ladder.
    readonly property int rowPaddingVertical: 12

    /// Between two rows. They are filled again, so they carry their own edge and a small
    /// gap is enough to keep them from reading as one block.
    readonly property int cardSpacing: 4

    /// Between the lines inside one card.
    readonly property int cardLineSpacing: 4

    /// The reading pane breathes more than the list: it holds prose, and prose needs a
    /// margin the eye can return to.
    readonly property int readingPadding: 32

    /// A comfortable measure. Text running the whole width of a maximised window is text
    /// nobody finishes a paragraph of.
    readonly property int readingWidth: 720

    /// Rail rows, list rows and icon buttons all sit on this, so a row in one pane lines
    /// up with a row in the next.
    readonly property int rowHeight: 48
    readonly property int iconButtonSize: 44

    /// The floating button, and the space a list keeps free underneath itself so the last
    /// card can be read rather than sat on.
    readonly property int fabMargin: 16
    readonly property int fabClearance: 88

    readonly property int railExpandedWidth: 216
    readonly property int railCollapsedWidth: 76
    readonly property int topBarHeight: 64
    readonly property int searchMaximumWidth: 420
}
