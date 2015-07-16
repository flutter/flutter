/*
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2010 Apple Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#ifndef SKY_ENGINE_CORE_EDITING_EDITINGBEHAVIOR_H_
#define SKY_ENGINE_CORE_EDITING_EDITINGBEHAVIOR_H_

namespace blink {
class KeyboardEvent;

class EditingBehavior {

public:
    explicit EditingBehavior()
    {
    }

    // Individual functions for each case where we have more than one style of editing behavior.
    // Create a new function for any platform difference so we can control it here.

    // When extending a selection beyond the top or bottom boundary of an editable area,
    // maintain the horizontal position on Windows and Android but extend it to the boundary of
    // the editable content on Mac and Linux.
    bool shouldMoveCaretToHorizontalBoundaryWhenPastTopOrBottom() const
    {
        return false;
    }

    // On Windows, selections should always be considered as directional, regardless if it is
    // mouse-based or keyboard-based.
    bool shouldConsiderSelectionAsDirectional() const { return true; }

    // On Mac, style is considered present when present at the beginning of selection. On other platforms,
    // style has to be present throughout the selection.
    bool shouldToggleStyleBasedOnStartOfSelection() const { return false; }

    // Standard Mac behavior when extending to a boundary is grow the selection rather than leaving the base
    // in place and moving the extent. Matches NSTextView.
    bool shouldAlwaysGrowSelectionWhenExtendingToBoundary() const { return false; }

    // On Mac, when processing a contextual click, the object being clicked upon should be selected.
    bool shouldSelectOnContextualMenuClick() const { return false; }

    // On Mac and Windows, pressing backspace (when it isn't handled otherwise) should navigate back.
    bool shouldNavigateBackOnBackspace() const
    {
        return false;
    }

    // On Mac, selecting backwards by word/line from the middle of a word/line, and then going
    // forward leaves the caret back in the middle with no selection, instead of directly selecting
    // to the other end of the line/word (Unix/Windows behavior).
    bool shouldExtendSelectionByWordOrLineAcrossCaret() const { return true; }

    // Based on native behavior, when using ctrl(alt)+arrow to move caret by word, ctrl(alt)+left arrow moves caret to
    // immediately before the word in all platforms, for example, the word break positions are: "|abc |def |hij |opq".
    // But ctrl+right arrow moves caret to "abc |def |hij |opq" on Windows and "abc| def| hij| opq|" on Mac and Linux.
    bool shouldSkipSpaceWhenMovingRight() const { return false; }

    // On Mac, undo of delete/forward-delete of text should select the deleted text. On other platforms deleted text
    // should not be selected and the cursor should be placed where the deletion started.
    bool shouldUndoOfDeleteSelectText() const { return false; }

    // Support for global selections, used on platforms like the X Window
    // System that treat selection as a type of clipboard.
    bool supportsGlobalSelection() const
    {
        return false;
    }

    // Convert a KeyboardEvent to a command name like "Copy", "Undo" and so on.
    // If nothing, return empty string.
    const char* interpretKeyEvent(const KeyboardEvent&) const;

    bool shouldInsertCharacter(const KeyboardEvent&) const;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_EDITING_EDITINGBEHAVIOR_H_
