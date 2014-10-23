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

#include "config.h"
#include "core/editing/DeleteSelectionCommand.h"

#include "core/dom/Document.h"
#include "core/dom/Element.h"
#include "core/dom/NodeTraversal.h"
#include "core/dom/Text.h"
#include "core/editing/EditingBoundary.h"
#include "core/editing/Editor.h"
#include "core/editing/VisibleUnits.h"
#include "core/editing/htmlediting.h"
#include "core/frame/LocalFrame.h"
#include "core/html/HTMLStyleElement.h"
#include "core/rendering/RenderText.h"

namespace blink {

DeleteSelectionCommand::DeleteSelectionCommand(Document& document, bool smartDelete, bool mergeBlocksAfterDelete, bool expandForSpecialElements, bool sanitizeMarkup)
    : CompositeEditCommand(document)
    , m_hasSelectionToDelete(false)
    , m_smartDelete(smartDelete)
    , m_mergeBlocksAfterDelete(mergeBlocksAfterDelete)
    , m_needPlaceholder(false)
    , m_expandForSpecialElements(expandForSpecialElements)
    , m_pruneStartBlockIfNecessary(false)
    , m_startsAtEmptyLine(false)
    , m_startBlock(nullptr)
    , m_endBlock(nullptr)
    , m_deleteIntoBlockquoteStyle(nullptr)
{
}

DeleteSelectionCommand::DeleteSelectionCommand(const VisibleSelection& selection, bool smartDelete, bool mergeBlocksAfterDelete, bool expandForSpecialElements, bool sanitizeMarkup)
    : CompositeEditCommand(*selection.start().document())
    , m_hasSelectionToDelete(true)
    , m_smartDelete(smartDelete)
    , m_mergeBlocksAfterDelete(mergeBlocksAfterDelete)
    , m_needPlaceholder(false)
    , m_expandForSpecialElements(expandForSpecialElements)
    , m_pruneStartBlockIfNecessary(false)
    , m_startsAtEmptyLine(false)
    , m_selectionToDelete(selection)
    , m_startBlock(nullptr)
    , m_endBlock(nullptr)
    , m_deleteIntoBlockquoteStyle(nullptr)
{
}

void DeleteSelectionCommand::initializeStartEnd(Position& start, Position& end)
{
    HTMLElement* startSpecialContainer = 0;
    HTMLElement* endSpecialContainer = 0;

    start = m_selectionToDelete.start();
    end = m_selectionToDelete.end();

    // FIXME: This is only used so that moveParagraphs can avoid the bugs in special element expansion.
    if (!m_expandForSpecialElements)
        return;

    while (1) {
        startSpecialContainer = 0;
        endSpecialContainer = 0;

        Position s = positionBeforeContainingSpecialElement(start, &startSpecialContainer);
        Position e = positionAfterContainingSpecialElement(end, &endSpecialContainer);

        if (!startSpecialContainer && !endSpecialContainer)
            break;

        if (VisiblePosition(start) != m_selectionToDelete.visibleStart() || VisiblePosition(end) != m_selectionToDelete.visibleEnd())
            break;

        // If we're going to expand to include the startSpecialContainer, it must be fully selected.
        if (startSpecialContainer && !endSpecialContainer && comparePositions(positionInParentAfterNode(*startSpecialContainer), end) > -1)
            break;

        // If we're going to expand to include the endSpecialContainer, it must be fully selected.
        if (endSpecialContainer && !startSpecialContainer && comparePositions(start, positionInParentBeforeNode(*endSpecialContainer)) > -1)
            break;

        if (startSpecialContainer && startSpecialContainer->isDescendantOf(endSpecialContainer))
            // Don't adjust the end yet, it is the end of a special element that contains the start
            // special element (which may or may not be fully selected).
            start = s;
        else if (endSpecialContainer && endSpecialContainer->isDescendantOf(startSpecialContainer))
            // Don't adjust the start yet, it is the start of a special element that contains the end
            // special element (which may or may not be fully selected).
            end = e;
        else {
            start = s;
            end = e;
        }
    }
}

void DeleteSelectionCommand::setStartingSelectionOnSmartDelete(const Position& start, const Position& end)
{
    bool isBaseFirst = startingSelection().isBaseFirst();
    VisiblePosition newBase(isBaseFirst ? start : end);
    VisiblePosition newExtent(isBaseFirst ? end : start);
    setStartingSelection(VisibleSelection(newBase, newExtent, startingSelection().isDirectional()));
}

void DeleteSelectionCommand::initializePositionData()
{
    Position start, end;
    initializeStartEnd(start, end);

    ASSERT(isEditablePosition(start, ContentIsEditable, DoNotUpdateStyle));
    if (!isEditablePosition(end, ContentIsEditable, DoNotUpdateStyle))
        end = lastEditablePositionBeforePositionInRoot(end, highestEditableRoot(start));

    m_upstreamStart = start.upstream();
    m_downstreamStart = start.downstream();
    m_upstreamEnd = end.upstream();
    m_downstreamEnd = end.downstream();

    m_startRoot = editableRootForPosition(start);
    m_endRoot = editableRootForPosition(end);

    // Usually the start and the end of the selection to delete are pulled together as a result of the deletion.
    // Sometimes they aren't (like when no merge is requested), so we must choose one position to hold the caret
    // and receive the placeholder after deletion.
    VisiblePosition visibleEnd(m_downstreamEnd);
    if (m_mergeBlocksAfterDelete && !isEndOfParagraph(visibleEnd))
        m_endingPosition = m_downstreamEnd;
    else
        m_endingPosition = m_downstreamStart;

    // We don't want to merge into a block if it will mean changing the quote level of content after deleting
    // selections that contain a whole number paragraphs plus a line break, since it is unclear to most users
    // that such a selection actually ends at the start of the next paragraph. This matches TextEdit behavior
    // for indented paragraphs.
    // Only apply this rule if the endingSelection is a range selection.  If it is a caret, then other operations have created
    // the selection we're deleting (like the process of creating a selection to delete during a backspace), and the user isn't in the situation described above.
    if (numEnclosingMailBlockquotes(start) != numEnclosingMailBlockquotes(end)
            && isStartOfParagraph(visibleEnd) && isStartOfParagraph(VisiblePosition(start))
            && endingSelection().isRange()) {
        m_mergeBlocksAfterDelete = false;
        m_pruneStartBlockIfNecessary = true;
    }

    // Handle leading and trailing whitespace, as well as smart delete adjustments to the selection
    m_leadingWhitespace = leadingWhitespacePosition(m_upstreamStart, m_selectionToDelete.affinity());
    m_trailingWhitespace = trailingWhitespacePosition(m_downstreamEnd, VP_DEFAULT_AFFINITY);

    if (m_smartDelete) {

        // skip smart delete if the selection to delete already starts or ends with whitespace
        Position pos = VisiblePosition(m_upstreamStart, m_selectionToDelete.affinity()).deepEquivalent();
        bool skipSmartDelete = trailingWhitespacePosition(pos, VP_DEFAULT_AFFINITY, ConsiderNonCollapsibleWhitespace).isNotNull();
        if (!skipSmartDelete)
            skipSmartDelete = leadingWhitespacePosition(m_downstreamEnd, VP_DEFAULT_AFFINITY, ConsiderNonCollapsibleWhitespace).isNotNull();

        // extend selection upstream if there is whitespace there
        bool hasLeadingWhitespaceBeforeAdjustment = leadingWhitespacePosition(m_upstreamStart, m_selectionToDelete.affinity(), ConsiderNonCollapsibleWhitespace).isNotNull();
        if (!skipSmartDelete && hasLeadingWhitespaceBeforeAdjustment) {
            VisiblePosition visiblePos = VisiblePosition(m_upstreamStart, VP_DEFAULT_AFFINITY).previous();
            pos = visiblePos.deepEquivalent();
            // Expand out one character upstream for smart delete and recalculate
            // positions based on this change.
            m_upstreamStart = pos.upstream();
            m_downstreamStart = pos.downstream();
            m_leadingWhitespace = leadingWhitespacePosition(m_upstreamStart, visiblePos.affinity());

            setStartingSelectionOnSmartDelete(m_upstreamStart, m_upstreamEnd);
        }

        // trailing whitespace is only considered for smart delete if there is no leading
        // whitespace, as in the case where you double-click the first word of a paragraph.
        if (!skipSmartDelete && !hasLeadingWhitespaceBeforeAdjustment && trailingWhitespacePosition(m_downstreamEnd, VP_DEFAULT_AFFINITY, ConsiderNonCollapsibleWhitespace).isNotNull()) {
            // Expand out one character downstream for smart delete and recalculate
            // positions based on this change.
            pos = VisiblePosition(m_downstreamEnd, VP_DEFAULT_AFFINITY).next().deepEquivalent();
            m_upstreamEnd = pos.upstream();
            m_downstreamEnd = pos.downstream();
            m_trailingWhitespace = trailingWhitespacePosition(m_downstreamEnd, VP_DEFAULT_AFFINITY);

            setStartingSelectionOnSmartDelete(m_downstreamStart, m_downstreamEnd);
        }
    }

    // We must pass call parentAnchoredEquivalent on the positions since some editing positions
    // that appear inside their nodes aren't really inside them.  [hr, 0] is one example.
    // FIXME: parentAnchoredEquivalent should eventually be moved into enclosing element getters
    // like the one below, since editing functions should obviously accept editing positions.
    // FIXME: Passing false to enclosingNodeOfType tells it that it's OK to return a non-editable
    // node.  This was done to match existing behavior, but it seems wrong.
    m_startBlock = enclosingNodeOfType(m_downstreamStart.parentAnchoredEquivalent(), &isBlock, CanCrossEditingBoundary);
    m_endBlock = enclosingNodeOfType(m_upstreamEnd.parentAnchoredEquivalent(), &isBlock, CanCrossEditingBoundary);
}

// We don't want to inherit style from an element which can't have contents.
static bool shouldNotInheritStyleFrom(const Node& node)
{
    return !node.canContainRangeEndPoint();
}

void DeleteSelectionCommand::saveTypingStyleState()
{
    // A common case is deleting characters that are all from the same text node. In
    // that case, the style at the start of the selection before deletion will be the
    // same as the style at the start of the selection after deletion (since those
    // two positions will be identical). Therefore there is no need to save the
    // typing style at the start of the selection, nor is there a reason to
    // compute the style at the start of the selection after deletion (see the
    // early return in calculateTypingStyleAfterDelete).
    if (m_upstreamStart.deprecatedNode() == m_downstreamEnd.deprecatedNode() && m_upstreamStart.deprecatedNode()->isTextNode())
        return;

    if (shouldNotInheritStyleFrom(*m_selectionToDelete.start().anchorNode()))
        return;

    // If we're deleting into a Mail blockquote, save the style at end() instead of start()
    // We'll use this later in computeTypingStyleAfterDelete if we end up outside of a Mail blockquote
    if (enclosingNodeOfType(m_selectionToDelete.start(), isMailHTMLBlockquoteElement))
        m_deleteIntoBlockquoteStyle = EditingStyle::create(m_selectionToDelete.end());
    else
        m_deleteIntoBlockquoteStyle = nullptr;
}

void DeleteSelectionCommand::removeNode(PassRefPtrWillBeRawPtr<Node> node, ShouldAssumeContentIsAlwaysEditable shouldAssumeContentIsAlwaysEditable)
{
    if (!node)
        return;

    if (m_startRoot != m_endRoot && !(node->isDescendantOf(m_startRoot.get()) && node->isDescendantOf(m_endRoot.get()))) {
        // If a node is not in both the start and end editable roots, remove it only if its inside an editable region.
        if (!node->parentNode()->hasEditableStyle()) {
            // Don't remove non-editable atomic nodes.
            if (!node->hasChildren())
                return;
            // Search this non-editable region for editable regions to empty.
            RefPtrWillBeRawPtr<Node> child = node->firstChild();
            while (child) {
                RefPtrWillBeRawPtr<Node> nextChild = child->nextSibling();
                removeNode(child.get(), shouldAssumeContentIsAlwaysEditable);
                // Bail if nextChild is no longer node's child.
                if (nextChild && nextChild->parentNode() != node)
                    return;
                child = nextChild;
            }

            // Don't remove editable regions that are inside non-editable ones, just clear them.
            return;
        }
    }

    if (node->isRootEditableElement()) {
        // Do not remove an element of table structure; remove its contents.
        // Likewise for the root editable element.
        Node* child = node->firstChild();
        while (child) {
            Node* remove = child;
            child = child->nextSibling();
            removeNode(remove, shouldAssumeContentIsAlwaysEditable);
        }

        // Make sure empty cell has some height, if a placeholder can be inserted.
        document().updateLayoutIgnorePendingStylesheets();
        return;
    }

    if (node == m_startBlock) {
        VisiblePosition previous = VisiblePosition(firstPositionInNode(m_startBlock.get())).previous();
        if (previous.isNotNull() && !isEndOfBlock(previous))
            m_needPlaceholder = true;
    }
    if (node == m_endBlock) {
        VisiblePosition next = VisiblePosition(lastPositionInNode(m_endBlock.get())).next();
        if (next.isNotNull() && !isStartOfBlock(next))
            m_needPlaceholder = true;
    }

    // FIXME: Update the endpoints of the range being deleted.
    updatePositionForNodeRemoval(m_endingPosition, *node);
    updatePositionForNodeRemoval(m_leadingWhitespace, *node);
    updatePositionForNodeRemoval(m_trailingWhitespace, *node);

    CompositeEditCommand::removeNode(node, shouldAssumeContentIsAlwaysEditable);
}

static void updatePositionForTextRemoval(Text* node, int offset, int count, Position& position)
{
    if (position.anchorType() != Position::PositionIsOffsetInAnchor || position.containerNode() != node)
        return;

    if (position.offsetInContainerNode() > offset + count)
        position.moveToOffset(position.offsetInContainerNode() - count);
    else if (position.offsetInContainerNode() > offset)
        position.moveToOffset(offset);
}

void DeleteSelectionCommand::deleteTextFromNode(PassRefPtrWillBeRawPtr<Text> node, unsigned offset, unsigned count)
{
    // FIXME: Update the endpoints of the range being deleted.
    updatePositionForTextRemoval(node.get(), offset, count, m_endingPosition);
    updatePositionForTextRemoval(node.get(), offset, count, m_leadingWhitespace);
    updatePositionForTextRemoval(node.get(), offset, count, m_trailingWhitespace);
    updatePositionForTextRemoval(node.get(), offset, count, m_downstreamEnd);

    CompositeEditCommand::deleteTextFromNode(node, offset, count);
}

void DeleteSelectionCommand::makeStylingElementsDirectChildrenOfEditableRootToPreventStyleLoss()
{
    RefPtrWillBeRawPtr<Range> range = m_selectionToDelete.toNormalizedRange();
    RefPtrWillBeRawPtr<Node> node = range->firstNode();
    while (node && node != range->pastLastNode()) {
        RefPtrWillBeRawPtr<Node> nextNode = NodeTraversal::next(*node);
        if (isHTMLStyleElement(*node) || isHTMLLinkElement(*node)) {
            nextNode = NodeTraversal::nextSkippingChildren(*node);
            RefPtrWillBeRawPtr<Element> rootEditableElement = node->rootEditableElement();
            if (rootEditableElement.get()) {
                removeNode(node);
                appendNode(node, rootEditableElement);
            }
        }
        node = nextNode;
    }
}

void DeleteSelectionCommand::handleGeneralDelete()
{
    if (m_upstreamStart.isNull())
        return;

    int startOffset = m_upstreamStart.deprecatedEditingOffset();
    Node* startNode = m_upstreamStart.deprecatedNode();
    ASSERT(startNode);

    makeStylingElementsDirectChildrenOfEditableRootToPreventStyleLoss();

    // Never remove the start block unless it's a table, in which case we won't merge content in.
    if (startNode->isSameNode(m_startBlock.get()) && !startOffset && canHaveChildrenForEditing(startNode)) {
        startOffset = 0;
        startNode = NodeTraversal::next(*startNode);
        if (!startNode)
            return;
    }

    if (startOffset >= caretMaxOffset(startNode) && startNode->isTextNode()) {
        Text* text = toText(startNode);
        if (text->length() > (unsigned)caretMaxOffset(startNode))
            deleteTextFromNode(text, caretMaxOffset(startNode), text->length() - caretMaxOffset(startNode));
    }

    if (startOffset >= lastOffsetForEditing(startNode)) {
        startNode = NodeTraversal::nextSkippingChildren(*startNode);
        startOffset = 0;
    }

    // Done adjusting the start.  See if we're all done.
    if (!startNode)
        return;

    if (startNode == m_downstreamEnd.deprecatedNode()) {
        if (m_downstreamEnd.deprecatedEditingOffset() - startOffset > 0) {
            if (startNode->isTextNode()) {
                // in a text node that needs to be trimmed
                Text* text = toText(startNode);
                deleteTextFromNode(text, startOffset, m_downstreamEnd.deprecatedEditingOffset() - startOffset);
            } else {
                removeChildrenInRange(startNode, startOffset, m_downstreamEnd.deprecatedEditingOffset());
                m_endingPosition = m_upstreamStart;
            }
        }

        // The selection to delete is all in one node.
        if (!startNode->renderer() || (!startOffset && m_downstreamEnd.atLastEditingPositionForNode()))
            removeNode(startNode);
    }
    else {
        bool startNodeWasDescendantOfEndNode = m_upstreamStart.deprecatedNode()->isDescendantOf(m_downstreamEnd.deprecatedNode());
        // The selection to delete spans more than one node.
        RefPtrWillBeRawPtr<Node> node(startNode);

        if (startOffset > 0) {
            if (startNode->isTextNode()) {
                // in a text node that needs to be trimmed
                Text* text = toText(node);
                deleteTextFromNode(text, startOffset, text->length() - startOffset);
                node = NodeTraversal::next(*node);
            } else {
                node = NodeTraversal::childAt(*startNode, startOffset);
            }
        } else if (startNode == m_upstreamEnd.deprecatedNode() && startNode->isTextNode()) {
            Text* text = toText(m_upstreamEnd.deprecatedNode());
            deleteTextFromNode(text, 0, m_upstreamEnd.deprecatedEditingOffset());
        }

        // handle deleting all nodes that are completely selected
        while (node && node != m_downstreamEnd.deprecatedNode()) {
            if (comparePositions(firstPositionInOrBeforeNode(node.get()), m_downstreamEnd) >= 0) {
                // NodeTraversal::nextSkippingChildren just blew past the end position, so stop deleting
                node = nullptr;
            } else if (!m_downstreamEnd.deprecatedNode()->isDescendantOf(node.get())) {
                RefPtrWillBeRawPtr<Node> nextNode = NodeTraversal::nextSkippingChildren(*node);
                // if we just removed a node from the end container, update end position so the
                // check above will work
                updatePositionForNodeRemoval(m_downstreamEnd, *node);
                removeNode(node.get());
                node = nextNode.get();
            } else {
                Node& n = NodeTraversal::lastWithinOrSelf(*node);
                if (m_downstreamEnd.deprecatedNode() == n && m_downstreamEnd.deprecatedEditingOffset() >= caretMaxOffset(&n)) {
                    removeNode(node.get());
                    node = nullptr;
                } else {
                    node = NodeTraversal::next(*node);
                }
            }
        }

        if (m_downstreamEnd.deprecatedNode() != startNode && !m_upstreamStart.deprecatedNode()->isDescendantOf(m_downstreamEnd.deprecatedNode()) && m_downstreamEnd.inDocument() && m_downstreamEnd.deprecatedEditingOffset() >= caretMinOffset(m_downstreamEnd.deprecatedNode())) {
            if (m_downstreamEnd.atLastEditingPositionForNode() && !canHaveChildrenForEditing(m_downstreamEnd.deprecatedNode())) {
                // The node itself is fully selected, not just its contents.  Delete it.
                removeNode(m_downstreamEnd.deprecatedNode());
            } else {
                if (m_downstreamEnd.deprecatedNode()->isTextNode()) {
                    // in a text node that needs to be trimmed
                    Text* text = toText(m_downstreamEnd.deprecatedNode());
                    if (m_downstreamEnd.deprecatedEditingOffset() > 0) {
                        deleteTextFromNode(text, 0, m_downstreamEnd.deprecatedEditingOffset());
                    }
                // Remove children of m_downstreamEnd.deprecatedNode() that come after m_upstreamStart.
                // Don't try to remove children if m_upstreamStart was inside m_downstreamEnd.deprecatedNode()
                // and m_upstreamStart has been removed from the document, because then we don't
                // know how many children to remove.
                // FIXME: Make m_upstreamStart a position we update as we remove content, then we can
                // always know which children to remove.
                } else if (!(startNodeWasDescendantOfEndNode && !m_upstreamStart.inDocument())) {
                    int offset = 0;
                    if (m_upstreamStart.deprecatedNode()->isDescendantOf(m_downstreamEnd.deprecatedNode())) {
                        Node* n = m_upstreamStart.deprecatedNode();
                        while (n && n->parentNode() != m_downstreamEnd.deprecatedNode())
                            n = n->parentNode();
                        if (n)
                            offset = n->nodeIndex() + 1;
                    }
                    removeChildrenInRange(m_downstreamEnd.deprecatedNode(), offset, m_downstreamEnd.deprecatedEditingOffset());
                    m_downstreamEnd = createLegacyEditingPosition(m_downstreamEnd.deprecatedNode(), offset);
                }
            }
        }
    }
}

void DeleteSelectionCommand::fixupWhitespace()
{
    document().updateLayoutIgnorePendingStylesheets();
    // FIXME: isRenderedCharacter should be removed, and we should use VisiblePosition::characterAfter and VisiblePosition::characterBefore
    if (m_leadingWhitespace.isNotNull() && !m_leadingWhitespace.isRenderedCharacter() && m_leadingWhitespace.deprecatedNode()->isTextNode()) {
        Text* textNode = toText(m_leadingWhitespace.deprecatedNode());
        ASSERT(!textNode->renderer() || textNode->renderer()->style()->collapseWhiteSpace());
        replaceTextInNodePreservingMarkers(textNode, m_leadingWhitespace.deprecatedEditingOffset(), 1, nonBreakingSpaceString());
    }
    if (m_trailingWhitespace.isNotNull() && !m_trailingWhitespace.isRenderedCharacter() && m_trailingWhitespace.deprecatedNode()->isTextNode()) {
        Text* textNode = toText(m_trailingWhitespace.deprecatedNode());
        ASSERT(!textNode->renderer() ||textNode->renderer()->style()->collapseWhiteSpace());
        replaceTextInNodePreservingMarkers(textNode, m_trailingWhitespace.deprecatedEditingOffset(), 1, nonBreakingSpaceString());
    }
}

// If a selection starts in one block and ends in another, we have to merge to bring content before the
// start together with content after the end.
void DeleteSelectionCommand::mergeParagraphs()
{
    if (!m_mergeBlocksAfterDelete) {
        if (m_pruneStartBlockIfNecessary) {
            // We aren't going to merge into the start block, so remove it if it's empty.
            prune(m_startBlock);
            // Removing the start block during a deletion is usually an indication that we need
            // a placeholder, but not in this case.
            m_needPlaceholder = false;
        }
        return;
    }

    // It shouldn't have been asked to both try and merge content into the start block and prune it.
    ASSERT(!m_pruneStartBlockIfNecessary);

    // FIXME: Deletion should adjust selection endpoints as it removes nodes so that we never get into this state (4099839).
    if (!m_downstreamEnd.inDocument() || !m_upstreamStart.inDocument())
         return;

    // FIXME: The deletion algorithm shouldn't let this happen.
    if (comparePositions(m_upstreamStart, m_downstreamEnd) > 0)
        return;

    // There's nothing to merge.
    if (m_upstreamStart == m_downstreamEnd)
        return;

    VisiblePosition startOfParagraphToMove(m_downstreamEnd);
    VisiblePosition mergeDestination(m_upstreamStart);

    // m_downstreamEnd's block has been emptied out by deletion.  There is no content inside of it to
    // move, so just remove it.
    Element* endBlock = enclosingBlock(m_downstreamEnd.deprecatedNode());
    if (!endBlock || !endBlock->contains(startOfParagraphToMove.deepEquivalent().deprecatedNode()) || !startOfParagraphToMove.deepEquivalent().deprecatedNode()) {
        removeNode(enclosingBlock(m_downstreamEnd.deprecatedNode()));
        return;
    }

    // We need to merge into m_upstreamStart's block, but it's been emptied out and collapsed by deletion.
    if (!mergeDestination.deepEquivalent().deprecatedNode() || (!mergeDestination.deepEquivalent().deprecatedNode()->isDescendantOf(enclosingBlock(m_upstreamStart.containerNode())) && (!mergeDestination.deepEquivalent().anchorNode()->hasChildren() || !m_upstreamStart.containerNode()->hasChildren())) || (m_startsAtEmptyLine && mergeDestination != startOfParagraphToMove)) {
        mergeDestination = VisiblePosition(m_upstreamStart);
    }

    if (mergeDestination == startOfParagraphToMove)
        return;

    VisiblePosition endOfParagraphToMove = endOfParagraph(startOfParagraphToMove, CanSkipOverEditingBoundary);

    if (mergeDestination == endOfParagraphToMove)
        return;

    // Block images, tables and horizontal rules cannot be made inline with content at mergeDestination.  If there is
    // any (!isStartOfParagraph(mergeDestination)), don't merge, just move the caret to just before the selection we deleted.
    // See https://bugs.webkit.org/show_bug.cgi?id=25439
    if (isRenderedAsNonInlineTableImageOrHR(startOfParagraphToMove.deepEquivalent().deprecatedNode()) && !isStartOfParagraph(mergeDestination)) {
        m_endingPosition = m_upstreamStart;
        return;
    }

    // moveParagraphs will insert placeholders if it removes blocks that would require their use, don't let block
    // removals that it does cause the insertion of *another* placeholder.
    bool needPlaceholder = m_needPlaceholder;
    bool paragraphToMergeIsEmpty = (startOfParagraphToMove == endOfParagraphToMove);
    moveParagraph(startOfParagraphToMove, endOfParagraphToMove, mergeDestination, false, !paragraphToMergeIsEmpty);
    m_needPlaceholder = needPlaceholder;
    // The endingPosition was likely clobbered by the move, so recompute it (moveParagraph selects the moved paragraph).
    m_endingPosition = endingSelection().start();
}

void DeleteSelectionCommand::calculateTypingStyleAfterDelete()
{
    document().frame()->selection().clearTypingStyle();
}

void DeleteSelectionCommand::clearTransientState()
{
    m_selectionToDelete = VisibleSelection();
    m_upstreamStart.clear();
    m_downstreamStart.clear();
    m_upstreamEnd.clear();
    m_downstreamEnd.clear();
    m_endingPosition.clear();
    m_leadingWhitespace.clear();
    m_trailingWhitespace.clear();
}

// This method removes div elements with no attributes that have only one child or no children at all.
void DeleteSelectionCommand::removeRedundantBlocks()
{
    Node* node = m_endingPosition.containerNode();
    Element* rootElement = node->rootEditableElement();

    while (node != rootElement) {
        if (isRemovableBlock(node)) {
            if (node == m_endingPosition.anchorNode())
                updatePositionForNodeRemovalPreservingChildren(m_endingPosition, *node);

            CompositeEditCommand::removeNodePreservingChildren(node);
            node = m_endingPosition.anchorNode();
        } else
            node = node->parentNode();
    }
}

void DeleteSelectionCommand::doApply()
{
    // If selection has not been set to a custom selection when the command was created,
    // use the current ending selection.
    if (!m_hasSelectionToDelete)
        m_selectionToDelete = endingSelection();

    if (!m_selectionToDelete.isNonOrphanedRange())
        return;

    // save this to later make the selection with
    EAffinity affinity = m_selectionToDelete.affinity();

    Position downstreamEnd = m_selectionToDelete.end().downstream();
    bool rootWillStayOpenWithoutPlaceholder = downstreamEnd.containerNode() == downstreamEnd.containerNode()->rootEditableElement()
        || (downstreamEnd.containerNode()->isTextNode() && downstreamEnd.containerNode()->parentNode() == downstreamEnd.containerNode()->rootEditableElement());
    bool lineBreakAtEndOfSelectionToDelete = lineBreakExistsAtVisiblePosition(m_selectionToDelete.visibleEnd());
    m_needPlaceholder = !rootWillStayOpenWithoutPlaceholder
        && isStartOfParagraph(m_selectionToDelete.visibleStart(), CanCrossEditingBoundary)
        && isEndOfParagraph(m_selectionToDelete.visibleEnd(), CanCrossEditingBoundary)
        && !lineBreakAtEndOfSelectionToDelete;
    if (m_needPlaceholder) {
        // Don't need a placeholder when deleting a selection that starts just before a table
        // and ends inside it (we do need placeholders to hold open empty cells, but that's
        // handled elsewhere).
        if (Element* table = isLastPositionBeforeTable(m_selectionToDelete.visibleStart()))
            if (m_selectionToDelete.end().deprecatedNode()->isDescendantOf(table))
                m_needPlaceholder = false;
    }


    // set up our state
    initializePositionData();

    bool lineBreakBeforeStart = lineBreakExistsAtVisiblePosition(VisiblePosition(m_upstreamStart).previous());

    // Delete any text that may hinder our ability to fixup whitespace after the delete
    deleteInsignificantTextDownstream(m_trailingWhitespace);

    saveTypingStyleState();

    handleGeneralDelete();

    fixupWhitespace();

    mergeParagraphs();

    if (!m_needPlaceholder && rootWillStayOpenWithoutPlaceholder) {
        VisiblePosition visualEnding(m_endingPosition);
        bool hasPlaceholder = lineBreakExistsAtVisiblePosition(visualEnding)
            && visualEnding.next(CannotCrossEditingBoundary).isNull();
        m_needPlaceholder = hasPlaceholder && lineBreakBeforeStart && !lineBreakAtEndOfSelectionToDelete;
    }

    rebalanceWhitespaceAt(m_endingPosition);

    calculateTypingStyleAfterDelete();

    setEndingSelection(VisibleSelection(m_endingPosition, affinity, endingSelection().isDirectional()));
    clearTransientState();
}

EditAction DeleteSelectionCommand::editingAction() const
{
    // Note that DeleteSelectionCommand is also used when the user presses the Delete key,
    // but in that case there's a TypingCommand that supplies the editingAction(), so
    // the Undo menu correctly shows "Undo Typing"
    return EditActionCut;
}

// Normally deletion doesn't preserve the typing style that was present before it.  For example,
// type a character, Bold, then delete the character and start typing.  The Bold typing style shouldn't
// stick around.  Deletion should preserve a typing style that *it* sets, however.
bool DeleteSelectionCommand::preservesTypingStyle() const
{
    return false;
}

void DeleteSelectionCommand::trace(Visitor* visitor)
{
    visitor->trace(m_selectionToDelete);
    visitor->trace(m_upstreamStart);
    visitor->trace(m_downstreamStart);
    visitor->trace(m_upstreamEnd);
    visitor->trace(m_downstreamEnd);
    visitor->trace(m_endingPosition);
    visitor->trace(m_leadingWhitespace);
    visitor->trace(m_trailingWhitespace);
    visitor->trace(m_startBlock);
    visitor->trace(m_endBlock);
    visitor->trace(m_deleteIntoBlockquoteStyle);
    visitor->trace(m_startRoot);
    visitor->trace(m_endRoot);
    visitor->trace(m_temporaryPlaceholder);
    CompositeEditCommand::trace(visitor);
}

} // namespace blink
