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
#include "sky/engine/core/editing/InsertParagraphSeparatorCommand.h"

#include "gen/sky/core/HTMLNames.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/NodeTraversal.h"
#include "sky/engine/core/dom/Text.h"
#include "sky/engine/core/editing/EditingStyle.h"
#include "sky/engine/core/editing/InsertLineBreakCommand.h"
#include "sky/engine/core/editing/VisibleUnits.h"
#include "sky/engine/core/editing/htmlediting.h"
#include "sky/engine/core/html/HTMLElement.h"
#include "sky/engine/core/rendering/RenderObject.h"
#include "sky/engine/core/rendering/RenderText.h"

namespace blink {

InsertParagraphSeparatorCommand::InsertParagraphSeparatorCommand(Document& document, bool mustUseDefaultParagraphElement, bool pasteBlockquoteIntoUnquotedArea)
    : CompositeEditCommand(document)
    , m_mustUseDefaultParagraphElement(mustUseDefaultParagraphElement)
{
}

bool InsertParagraphSeparatorCommand::preservesTypingStyle() const
{
    return true;
}

void InsertParagraphSeparatorCommand::calculateStyleBeforeInsertion(const Position &pos)
{
    // It is only important to set a style to apply later if we're at the boundaries of
    // a paragraph. Otherwise, content that is moved as part of the work of the command
    // will lend their styles to the new paragraph without any extra work needed.
    VisiblePosition visiblePos(pos, VP_DEFAULT_AFFINITY);
    if (!isStartOfParagraph(visiblePos) && !isEndOfParagraph(visiblePos))
        return;

    ASSERT(pos.isNotNull());
    m_style = EditingStyle::create(pos);
    m_style->mergeTypingStyle(pos.document());
}

bool InsertParagraphSeparatorCommand::shouldUseDefaultParagraphElement(Element* enclosingBlock) const
{
    return m_mustUseDefaultParagraphElement;
}

void InsertParagraphSeparatorCommand::getAncestorsInsideBlock(const Node* insertionNode, Element* outerBlock, Vector<RefPtr<Element> >& ancestors)
{
    ancestors.clear();

    // Build up list of ancestors elements between the insertion node and the outer block.
    if (insertionNode != outerBlock) {
        for (Element* n = insertionNode->parentElement(); n && n != outerBlock; n = n->parentElement())
            ancestors.append(n);
    }
}

PassRefPtr<Element> InsertParagraphSeparatorCommand::cloneHierarchyUnderNewBlock(const Vector<RefPtr<Element> >& ancestors, PassRefPtr<Element> blockToInsert)
{
    // Make clones of ancestors in between the start node and the start block.
    RefPtr<Element> parent = blockToInsert;
    for (size_t i = ancestors.size(); i != 0; --i) {
        RefPtr<Element> child = ancestors[i - 1]->cloneElementWithoutChildren();
        // It should always be okay to remove id from the cloned elements, since the originals are not deleted.
        child->removeAttribute(HTMLNames::idAttr);
        appendNode(child, parent);
        parent = child.release();
    }

    return parent.release();
}

void InsertParagraphSeparatorCommand::doApply()
{
    if (!endingSelection().isNonOrphanedCaretOrRange())
        return;

    Position insertionPosition = endingSelection().start();

    EAffinity affinity = endingSelection().affinity();

    // Delete the current selection.
    if (endingSelection().isRange()) {
        calculateStyleBeforeInsertion(insertionPosition);
        deleteSelection(false, true);
        insertionPosition = endingSelection().start();
        affinity = endingSelection().affinity();
    }

    // FIXME: The parentAnchoredEquivalent conversion needs to be moved into enclosingBlock.
    RefPtr<Element> startBlock = enclosingBlock(insertionPosition.parentAnchoredEquivalent().containerNode());
    Position canonicalPos = VisiblePosition(insertionPosition).deepEquivalent();
    if (!startBlock
        || !startBlock->nonShadowBoundaryParentNode()
        // FIXME: If the node is hidden, we don't have a canonical position so we will do the wrong thing for tables and <hr>. https://bugs.webkit.org/show_bug.cgi?id=40342
        || (!canonicalPos.isNull() && isRenderedTableElement(canonicalPos.deprecatedNode()))) {
        applyCommandToComposite(InsertLineBreakCommand::create(document()));
        return;
    }

    // Use the leftmost candidate.
    insertionPosition = insertionPosition.upstream();
    if (!insertionPosition.isCandidate())
        insertionPosition = insertionPosition.downstream();

    // Adjust the insertion position after the delete
    insertionPosition = positionAvoidingSpecialElementBoundary(insertionPosition);
    VisiblePosition visiblePos(insertionPosition, affinity);
    calculateStyleBeforeInsertion(insertionPosition);

    //---------------------------------------------------------------------
    // Prepare for more general cases.

    bool isFirstInBlock = isStartOfBlock(visiblePos);
    bool isLastInBlock = isEndOfBlock(visiblePos);
    bool nestNewBlock = false;

    // Create block to be inserted.
    RefPtr<Element> blockToInsert = nullptr;
    if (startBlock->isRootEditableElement()) {
        blockToInsert = createDefaultParagraphElement(document());
        nestNewBlock = true;
    } else if (shouldUseDefaultParagraphElement(startBlock.get())) {
        blockToInsert = createDefaultParagraphElement(document());
    } else {
        blockToInsert = startBlock->cloneElementWithoutChildren();
    }

    //---------------------------------------------------------------------
    // Handle case when position is in the last visible position in its block,
    // including when the block is empty.
    if (isLastInBlock) {
        if (nestNewBlock) {
            if (isFirstInBlock && !lineBreakExistsAtVisiblePosition(visiblePos)) {
                // The block is empty.  Create an empty block to
                // represent the paragraph that we're leaving.
                RefPtr<HTMLElement> extraBlock = createDefaultParagraphElement(document());
                appendNode(extraBlock, startBlock);
            }
            appendNode(blockToInsert, startBlock);
        } else {
            // Most of the time we want to stay at the nesting level of the startBlock (e.g., when nesting within lists). However,
            // for div nodes, this can result in nested div tags that are hard to break out of.
            Element* siblingElement = startBlock.get();
            insertNodeAfter(blockToInsert, siblingElement);
        }

        // Recreate the same structure in the new paragraph.

        Vector<RefPtr<Element> > ancestors;
        getAncestorsInsideBlock(positionOutsideTabSpan(insertionPosition).deprecatedNode(), startBlock.get(), ancestors);
        RefPtr<Element> parent = cloneHierarchyUnderNewBlock(ancestors, blockToInsert);

        setEndingSelection(VisibleSelection(firstPositionInNode(parent.get()), DOWNSTREAM, endingSelection().isDirectional()));
        return;
    }


    //---------------------------------------------------------------------
    // Handle case when position is in the first visible position in its block, and
    // similar case where previous position is in another, presumeably nested, block.
    if (isFirstInBlock || !inSameBlock(visiblePos, visiblePos.previous())) {
        Node* refNode = 0;
        insertionPosition = positionOutsideTabSpan(insertionPosition);

        if (isFirstInBlock && !nestNewBlock) {
            refNode = startBlock.get();
        } else if (isFirstInBlock && nestNewBlock) {
            // startBlock should always have children, otherwise isLastInBlock would be true and it's handled above.
            ASSERT(startBlock->hasChildren());
            refNode = startBlock->firstChild();
        }
        else if (insertionPosition.deprecatedNode() == startBlock && nestNewBlock) {
            refNode = NodeTraversal::childAt(*startBlock, insertionPosition.deprecatedEditingOffset());
            ASSERT(refNode); // must be true or we'd be in the end of block case
        } else
            refNode = insertionPosition.deprecatedNode();

        // find ending selection position easily before inserting the paragraph
        insertionPosition = insertionPosition.downstream();

        if (refNode)
            insertNodeBefore(blockToInsert, refNode);

        // Recreate the same structure in the new paragraph.

        Vector<RefPtr<Element> > ancestors;
        getAncestorsInsideBlock(positionAvoidingSpecialElementBoundary(positionOutsideTabSpan(insertionPosition)).deprecatedNode(), startBlock.get(), ancestors);

        // In this case, we need to set the new ending selection.
        setEndingSelection(VisibleSelection(insertionPosition, DOWNSTREAM, endingSelection().isDirectional()));
        return;
    }

    //---------------------------------------------------------------------
    // Handle the (more complicated) general case,

    // Move downstream. Typing style code will take care of carrying along the
    // style of the upstream position.
    insertionPosition = insertionPosition.downstream();

    // At this point, the insertionPosition's node could be a container, and we want to make sure we include
    // all of the correct nodes when building the ancestor list.  So this needs to be the deepest representation of the position
    // before we walk the DOM tree.
    insertionPosition = positionOutsideTabSpan(VisiblePosition(insertionPosition).deepEquivalent());

    // If the returned position lies either at the end or at the start of an element that is ignored by editing
    // we should move to its upstream or downstream position.
    if (editingIgnoresContent(insertionPosition.deprecatedNode())) {
        if (insertionPosition.atLastEditingPositionForNode())
            insertionPosition = insertionPosition.downstream();
        else if (insertionPosition.atFirstEditingPositionForNode())
            insertionPosition = insertionPosition.upstream();
    }

    // Make sure we do not cause a rendered space to become unrendered.
    // FIXME: We need the affinity for pos, but pos.downstream() does not give it
    Position leadingWhitespace = leadingWhitespacePosition(insertionPosition, VP_DEFAULT_AFFINITY);
    // FIXME: leadingWhitespacePosition is returning the position before preserved newlines for positions
    // after the preserved newline, causing the newline to be turned into a nbsp.
    if (leadingWhitespace.isNotNull() && leadingWhitespace.deprecatedNode()->isTextNode()) {
        Text* textNode = toText(leadingWhitespace.deprecatedNode());
        ASSERT(!textNode->renderer() || textNode->renderer()->style()->collapseWhiteSpace());
        replaceTextInNodePreservingMarkers(textNode, leadingWhitespace.deprecatedEditingOffset(), 1, nonBreakingSpaceString());
    }

    // Split at pos if in the middle of a text node.
    Position positionAfterSplit;
    if (insertionPosition.anchorType() == Position::PositionIsOffsetInAnchor && insertionPosition.containerNode()->isTextNode()) {
        RefPtr<Text> textNode = toText(insertionPosition.containerNode());
        bool atEnd = static_cast<unsigned>(insertionPosition.offsetInContainerNode()) >= textNode->length();
        if (insertionPosition.deprecatedEditingOffset() > 0 && !atEnd) {
            splitTextNode(textNode, insertionPosition.offsetInContainerNode());
            positionAfterSplit = firstPositionInNode(textNode.get());
            insertionPosition.moveToPosition(textNode->previousSibling(), insertionPosition.offsetInContainerNode());
            visiblePos = VisiblePosition(insertionPosition);
        }
    }

    // If we got detached due to mutation events, just bail out.
    if (!startBlock->parentNode())
        return;

    // Put the added block in the tree.
    if (nestNewBlock) {
        appendNode(blockToInsert.get(), startBlock);
    } else {
        insertNodeAfter(blockToInsert.get(), startBlock);
    }

    document().updateLayout();

    // Move the start node and the siblings of the start node.
    if (VisiblePosition(insertionPosition) != VisiblePosition(positionBeforeNode(blockToInsert.get()))) {
        Node* n;
        if (insertionPosition.containerNode() == startBlock)
            n = insertionPosition.computeNodeAfterPosition();
        else {
            Node* splitTo = insertionPosition.containerNode();
            if (splitTo->isTextNode() && insertionPosition.offsetInContainerNode() >= caretMaxOffset(splitTo))
                splitTo = NodeTraversal::next(*splitTo, startBlock.get());
            ASSERT(splitTo);
            splitTreeToNode(splitTo, startBlock.get());

            for (n = startBlock->firstChild(); n; n = n->nextSibling()) {
                VisiblePosition beforeNodePosition(positionBeforeNode(n));
                if (!beforeNodePosition.isNull() && comparePositions(VisiblePosition(insertionPosition), beforeNodePosition) <= 0)
                    break;
            }
        }

        moveRemainingSiblingsToNewParent(n, blockToInsert.get(), blockToInsert);
    }

    // Handle whitespace that occurs after the split
    if (positionAfterSplit.isNotNull()) {
        document().updateLayout();
        if (!positionAfterSplit.isRenderedCharacter()) {
            // Clear out all whitespace and insert one non-breaking space
            ASSERT(!positionAfterSplit.containerNode()->renderer() || positionAfterSplit.containerNode()->renderer()->style()->collapseWhiteSpace());
            deleteInsignificantTextDownstream(positionAfterSplit);
            if (positionAfterSplit.deprecatedNode()->isTextNode())
                insertTextIntoNode(toText(positionAfterSplit.containerNode()), 0, nonBreakingSpaceString());
        }
    }

    setEndingSelection(VisibleSelection(firstPositionInNode(blockToInsert.get()), DOWNSTREAM, endingSelection().isDirectional()));
}

} // namespace blink
