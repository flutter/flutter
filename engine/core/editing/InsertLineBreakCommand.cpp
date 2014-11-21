/*
 * Copyright (C) 2005, 2006 Apple Computer, Inc.  All rights reserved.
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

#include "sky/engine/config.h"
#include "sky/engine/core/editing/InsertLineBreakCommand.h"

#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Text.h"
#include "sky/engine/core/editing/EditingStyle.h"
#include "sky/engine/core/editing/FrameSelection.h"
#include "sky/engine/core/editing/VisiblePosition.h"
#include "sky/engine/core/editing/VisibleUnits.h"
#include "sky/engine/core/editing/htmlediting.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/html/HTMLElement.h"
#include "sky/engine/core/rendering/RenderObject.h"
#include "sky/engine/core/rendering/RenderText.h"

namespace blink {

InsertLineBreakCommand::InsertLineBreakCommand(Document& document)
    : CompositeEditCommand(document)
{
}

bool InsertLineBreakCommand::preservesTypingStyle() const
{
    return true;
}

void InsertLineBreakCommand::doApply()
{
    deleteSelection();
    VisibleSelection selection = endingSelection();
    if (!selection.isNonOrphanedCaretOrRange())
        return;

    VisiblePosition caret(selection.visibleStart());
    // FIXME: If the node is hidden, we should still be able to insert text.
    // For now, we return to avoid a crash.  https://bugs.webkit.org/show_bug.cgi?id=40342
    if (caret.isNull())
        return;

    Position pos(caret.deepEquivalent());

    pos = positionAvoidingSpecialElementBoundary(pos);

    pos = positionOutsideTabSpan(pos);

    RefPtr<Node> nodeToInsert = nullptr;
    nodeToInsert = document().createTextNode("\n");

    // FIXME: Need to merge text nodes when inserting just after or before text.

    if (isEndOfParagraph(caret) && !lineBreakExistsAtVisiblePosition(caret)) {
        insertNodeAt(nodeToInsert.get(), pos);
        insertNodeBefore(nodeToInsert->cloneNode(false), nodeToInsert);

        VisiblePosition endingPosition(positionBeforeNode(nodeToInsert.get()));
        setEndingSelection(VisibleSelection(endingPosition, endingSelection().isDirectional()));
    } else if (pos.deprecatedEditingOffset() <= caretMinOffset(pos.deprecatedNode())) {
        insertNodeAt(nodeToInsert.get(), pos);

        // Insert an extra br or '\n' if the just inserted one collapsed.
        if (!isStartOfParagraph(VisiblePosition(positionBeforeNode(nodeToInsert.get()))))
            insertNodeBefore(nodeToInsert->cloneNode(false).get(), nodeToInsert.get());

        setEndingSelection(VisibleSelection(positionInParentAfterNode(*nodeToInsert), DOWNSTREAM, endingSelection().isDirectional()));
    // If we're inserting after all of the rendered text in a text node, or into a non-text node,
    // a simple insertion is sufficient.
    } else if (pos.deprecatedEditingOffset() >= caretMaxOffset(pos.deprecatedNode()) || !pos.deprecatedNode()->isTextNode()) {
        insertNodeAt(nodeToInsert.get(), pos);
        setEndingSelection(VisibleSelection(positionInParentAfterNode(*nodeToInsert), DOWNSTREAM, endingSelection().isDirectional()));
    } else if (pos.deprecatedNode()->isTextNode()) {
        // Split a text node
        Text* textNode = toText(pos.deprecatedNode());
        splitTextNode(textNode, pos.deprecatedEditingOffset());
        insertNodeBefore(nodeToInsert, textNode);
        Position endingPosition = firstPositionInNode(textNode);

        // Handle whitespace that occurs after the split
        document().updateLayoutIgnorePendingStylesheets();
        if (!endingPosition.isRenderedCharacter()) {
            Position positionBeforeTextNode(positionInParentBeforeNode(*textNode));
            // Clear out all whitespace and insert one non-breaking space
            deleteInsignificantTextDownstream(endingPosition);
            ASSERT(!textNode->renderer() || textNode->renderer()->style()->collapseWhiteSpace());
            // Deleting insignificant whitespace will remove textNode if it contains nothing but insignificant whitespace.
            if (textNode->inDocument())
                insertTextIntoNode(textNode, 0, nonBreakingSpaceString());
            else {
                RefPtr<Text> nbspNode = document().createTextNode(nonBreakingSpaceString());
                insertNodeAt(nbspNode.get(), positionBeforeTextNode);
                endingPosition = firstPositionInNode(nbspNode.get());
            }
        }

        setEndingSelection(VisibleSelection(endingPosition, DOWNSTREAM, endingSelection().isDirectional()));
    }

    // Handle the case where there is a typing style.

    RefPtr<EditingStyle> typingStyle = document().frame()->selection().typingStyle();

    if (typingStyle && !typingStyle->isEmpty()) {
        // Even though this applyStyle operates on a Range, it still sets an endingSelection().
        // It tries to set a VisibleSelection around the content it operated on. So, that VisibleSelection
        // will either (a) select the line break we inserted, or it will (b) be a caret just
        // before the line break (if the line break is at the end of a block it isn't selectable).
        // So, this next call sets the endingSelection() to a caret just after the line break
        // that we inserted, or just before it if it's at the end of a block.
        setEndingSelection(endingSelection().visibleEnd());
    }

    rebalanceWhitespace();
}

}
