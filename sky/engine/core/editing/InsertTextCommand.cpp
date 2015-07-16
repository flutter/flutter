/*
 * Copyright (C) 2005 Apple Computer, Inc.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "sky/engine/core/editing/InsertTextCommand.h"

#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/Text.h"
#include "sky/engine/core/editing/Editor.h"
#include "sky/engine/core/editing/VisibleUnits.h"
#include "sky/engine/core/editing/htmlediting.h"
#include "sky/engine/core/frame/LocalFrame.h"

namespace blink {

InsertTextCommand::InsertTextCommand(Document& document, const String& text, bool selectInsertedText, RebalanceType rebalanceType)
    : CompositeEditCommand(document)
    , m_text(text)
    , m_selectInsertedText(selectInsertedText)
    , m_rebalanceType(rebalanceType)
{
}

Position InsertTextCommand::positionInsideTextNode(const Position& p)
{
    Position pos = p;

    // Prepare for text input by looking at the specified position.
    // It may be necessary to insert a text node to receive characters.
    if (!pos.containerNode()->isTextNode()) {
        RefPtr<Text> textNode = document().createEditingTextNode("");
        insertNodeAt(textNode.get(), pos);
        return firstPositionInNode(textNode.get());
    }

    return pos;
}

void InsertTextCommand::setEndingSelectionWithoutValidation(const Position& startPosition, const Position& endPosition)
{
    // We could have inserted a part of composed character sequence,
    // so we are basically treating ending selection as a range to avoid validation.
    // <http://bugs.webkit.org/show_bug.cgi?id=15781>
    VisibleSelection forcedEndingSelection;
    forcedEndingSelection.setWithoutValidation(startPosition, endPosition);
    forcedEndingSelection.setIsDirectional(endingSelection().isDirectional());
    setEndingSelection(forcedEndingSelection);
}

// This avoids the expense of a full fledged delete operation, and avoids a layout that typically results
// from text removal.
bool InsertTextCommand::performTrivialReplace(const String& text, bool selectInsertedText)
{
    if (!endingSelection().isRange())
        return false;

    if (text.contains('\t') || text.contains(' ') || text.contains('\n'))
        return false;

    Position start = endingSelection().start();
    Position endPosition = replaceSelectedTextInNode(text);
    if (endPosition.isNull())
        return false;

    setEndingSelectionWithoutValidation(start, endPosition);
    if (!selectInsertedText)
        setEndingSelection(VisibleSelection(endingSelection().visibleEnd(), endingSelection().isDirectional()));

    return true;
}

bool InsertTextCommand::performOverwrite(const String& text, bool selectInsertedText)
{
    Position start = endingSelection().start();
    RefPtr<Text> textNode = start.containerText();
    if (!textNode)
        return false;

    unsigned count = std::min(text.length(), textNode->length() - start.offsetInContainerNode());
    if (!count)
        return false;

    replaceTextInNode(textNode, start.offsetInContainerNode(), count, text);

    Position endPosition = Position(textNode.release(), start.offsetInContainerNode() + text.length());
    setEndingSelectionWithoutValidation(start, endPosition);
    if (!selectInsertedText)
        setEndingSelection(VisibleSelection(endingSelection().visibleEnd(), endingSelection().isDirectional()));

    return true;
}

void InsertTextCommand::doApply()
{
    ASSERT(m_text.find('\n') == kNotFound);

    if (!endingSelection().isNonOrphanedCaretOrRange())
        return;

    // Delete the current selection.
    // FIXME: This delete operation blows away the typing style.
    if (endingSelection().isRange()) {
        if (performTrivialReplace(m_text, m_selectInsertedText))
            return;
        bool endOfSelectionWasAtStartOfBlock = isStartOfBlock(endingSelection().visibleEnd());
        deleteSelection(false, true, false, false);
        // deleteSelection eventually makes a new endingSelection out of a Position. If that Position doesn't have
        // a renderer (e.g. it is on a <frameset> in the DOM), the VisibleSelection cannot be canonicalized to
        // anything other than NoSelection. The rest of this function requires a real endingSelection, so bail out.
        if (endingSelection().isNone())
            return;
        if (endOfSelectionWasAtStartOfBlock) {
            if (EditingStyle* typingStyle = document().frame()->selection().typingStyle())
                typingStyle->removeBlockProperties();
        }
    } else if (document().frame()->editor().isOverwriteModeEnabled()) {
        if (performOverwrite(m_text, m_selectInsertedText))
            return;
    }

    Position startPosition(endingSelection().start());

    Position placeholder;
    // We want to remove preserved newlines and brs that will collapse (and thus become unnecessary) when content
    // is inserted just before them.
    // FIXME: We shouldn't really have to do this, but removing placeholders is a workaround for 9661.
    // If the caret is just before a placeholder, downstream will normalize the caret to it.
    Position downstream(startPosition.downstream());
    if (lineBreakExistsAtPosition(downstream)) {
        // FIXME: This doesn't handle placeholders at the end of anonymous blocks.
        VisiblePosition caret(startPosition);
        if (isEndOfBlock(caret) && isStartOfParagraph(caret))
            placeholder = downstream;
        // Don't remove the placeholder yet, otherwise the block we're inserting into would collapse before
        // we get a chance to insert into it.  We check for a placeholder now, though, because doing so requires
        // the creation of a VisiblePosition, and if we did that post-insertion it would force a layout.
    }

    // Insert the character at the leftmost candidate.
    startPosition = startPosition.upstream();

    // It is possible for the node that contains startPosition to contain only unrendered whitespace,
    // and so deleteInsignificantText could remove it.  Save the position before the node in case that happens.
    ASSERT(startPosition.containerNode());
    Position positionBeforeStartNode(positionInParentBeforeNode(*startPosition.containerNode()));
    deleteInsignificantText(startPosition, startPosition.downstream());
    if (!startPosition.inDocument())
        startPosition = positionBeforeStartNode;
    if (!startPosition.isCandidate())
        startPosition = startPosition.downstream();

    startPosition = positionAvoidingSpecialElementBoundary(startPosition);

    Position endPosition;

    if (m_text == "\t") {
        endPosition = insertTab(startPosition);
        startPosition = endPosition.previous();
        if (placeholder.isNotNull())
            removePlaceholderAt(placeholder);
    } else {
        // Make sure the document is set up to receive m_text
        startPosition = positionInsideTextNode(startPosition);
        ASSERT(startPosition.anchorType() == Position::PositionIsOffsetInAnchor);
        ASSERT(startPosition.containerNode());
        ASSERT(startPosition.containerNode()->isTextNode());
        if (placeholder.isNotNull())
            removePlaceholderAt(placeholder);
        RefPtr<Text> textNode = startPosition.containerText();
        const unsigned offset = startPosition.offsetInContainerNode();

        insertTextIntoNode(textNode, offset, m_text);
        endPosition = Position(textNode, offset + m_text.length());

        if (m_rebalanceType == RebalanceLeadingAndTrailingWhitespaces) {
            // The insertion may require adjusting adjacent whitespace, if it is present.
            rebalanceWhitespaceAt(endPosition);
            // Rebalancing on both sides isn't necessary if we've inserted only spaces.
            if (!shouldRebalanceLeadingWhitespaceFor(m_text))
                rebalanceWhitespaceAt(startPosition);
        } else {
            ASSERT(m_rebalanceType == RebalanceAllWhitespaces);
            if (canRebalance(startPosition) && canRebalance(endPosition))
                rebalanceWhitespaceOnTextSubstring(textNode, startPosition.offsetInContainerNode(), endPosition.offsetInContainerNode());
        }
    }

    setEndingSelectionWithoutValidation(startPosition, endPosition);

    if (!m_selectInsertedText)
        setEndingSelection(VisibleSelection(endingSelection().end(), endingSelection().affinity(), endingSelection().isDirectional()));
}

Position InsertTextCommand::insertTab(const Position& pos)
{
    return VisiblePosition(pos, DOWNSTREAM).deepEquivalent();
}

}
