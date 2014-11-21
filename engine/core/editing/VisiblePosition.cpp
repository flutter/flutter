/*
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
 * Portions Copyright (c) 2011 Motorola Mobility, Inc.  All rights reserved.
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
#include "sky/engine/core/editing/VisiblePosition.h"

#include "sky/engine/bindings/core/v8/ExceptionState.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Range.h"
#include "sky/engine/core/dom/Text.h"
#include "sky/engine/core/editing/VisibleUnits.h"
#include "sky/engine/core/editing/htmlediting.h"
#include "sky/engine/core/html/HTMLElement.h"
#include "sky/engine/core/rendering/RenderBlock.h"
#include "sky/engine/core/rendering/RootInlineBox.h"
#include "sky/engine/platform/geometry/FloatQuad.h"
#include "sky/engine/wtf/text/CString.h"

#ifndef NDEBUG
#include <stdio.h>
#endif

namespace blink {

VisiblePosition::VisiblePosition(const Position &pos, EAffinity affinity)
{
    init(pos, affinity);
}

VisiblePosition::VisiblePosition(const PositionWithAffinity& positionWithAffinity)
{
    init(positionWithAffinity.position(), positionWithAffinity.affinity());
}

void VisiblePosition::init(const Position& position, EAffinity affinity)
{
    m_affinity = affinity;

    m_deepPosition = canonicalPosition(position);

    // When not at a line wrap, make sure to end up with DOWNSTREAM affinity.
    if (m_affinity == UPSTREAM && (isNull() || inSameLine(VisiblePosition(position, DOWNSTREAM), *this)))
        m_affinity = DOWNSTREAM;
}

VisiblePosition VisiblePosition::next(EditingBoundaryCrossingRule rule) const
{
    VisiblePosition next(nextVisuallyDistinctCandidate(m_deepPosition), m_affinity);

    switch (rule) {
    case CanCrossEditingBoundary:
        return next;
    case CannotCrossEditingBoundary:
        return honorEditingBoundaryAtOrAfter(next);
    case CanSkipOverEditingBoundary:
        return skipToEndOfEditingBoundary(next);
    }
    ASSERT_NOT_REACHED();
    return honorEditingBoundaryAtOrAfter(next);
}

VisiblePosition VisiblePosition::previous(EditingBoundaryCrossingRule rule) const
{
    Position pos = previousVisuallyDistinctCandidate(m_deepPosition);

    // return null visible position if there is no previous visible position
    if (pos.atStartOfTree())
        return VisiblePosition();

    VisiblePosition prev = VisiblePosition(pos, DOWNSTREAM);
    ASSERT(prev != *this);

#if ENABLE(ASSERT)
    // we should always be able to make the affinity DOWNSTREAM, because going previous from an
    // UPSTREAM position can never yield another UPSTREAM position (unless line wrap length is 0!).
    if (prev.isNotNull() && m_affinity == UPSTREAM) {
        VisiblePosition temp = prev;
        temp.setAffinity(UPSTREAM);
        ASSERT(inSameLine(temp, prev));
    }
#endif

    switch (rule) {
    case CanCrossEditingBoundary:
        return prev;
    case CannotCrossEditingBoundary:
        return honorEditingBoundaryAtOrBefore(prev);
    case CanSkipOverEditingBoundary:
        return skipToStartOfEditingBoundary(prev);
    }

    ASSERT_NOT_REACHED();
    return honorEditingBoundaryAtOrBefore(prev);
}

Position VisiblePosition::leftVisuallyDistinctCandidate() const
{
    Position p = m_deepPosition;
    if (p.isNull())
        return Position();

    Position downstreamStart = p.downstream();
    TextDirection primaryDirection = p.primaryDirection();

    while (true) {
        InlineBox* box;
        int offset;
        p.getInlineBoxAndOffset(m_affinity, primaryDirection, box, offset);
        if (!box)
            return primaryDirection == LTR ? previousVisuallyDistinctCandidate(m_deepPosition) : nextVisuallyDistinctCandidate(m_deepPosition);

        RenderObject* renderer = &box->renderer();

        while (true) {
            if (renderer->isReplaced() && offset == box->caretRightmostOffset())
                return box->isLeftToRightDirection() ? previousVisuallyDistinctCandidate(m_deepPosition) : nextVisuallyDistinctCandidate(m_deepPosition);

            if (!renderer->node()) {
                box = box->prevLeafChild();
                if (!box)
                    return primaryDirection == LTR ? previousVisuallyDistinctCandidate(m_deepPosition) : nextVisuallyDistinctCandidate(m_deepPosition);
                renderer = &box->renderer();
                offset = box->caretRightmostOffset();
                continue;
            }

            offset = box->isLeftToRightDirection() ? renderer->previousOffset(offset) : renderer->nextOffset(offset);

            int caretMinOffset = box->caretMinOffset();
            int caretMaxOffset = box->caretMaxOffset();

            if (offset > caretMinOffset && offset < caretMaxOffset)
                break;

            if (box->isLeftToRightDirection() ? offset < caretMinOffset : offset > caretMaxOffset) {
                // Overshot to the left.
                InlineBox* prevBox = box->prevLeafChildIgnoringLineBreak();
                if (!prevBox) {
                    Position positionOnLeft = primaryDirection == LTR ? previousVisuallyDistinctCandidate(m_deepPosition) : nextVisuallyDistinctCandidate(m_deepPosition);
                    if (positionOnLeft.isNull())
                        return Position();

                    InlineBox* boxOnLeft;
                    int offsetOnLeft;
                    positionOnLeft.getInlineBoxAndOffset(m_affinity, primaryDirection, boxOnLeft, offsetOnLeft);
                    if (boxOnLeft && boxOnLeft->root() == box->root())
                        return Position();
                    return positionOnLeft;
                }

                // Reposition at the other logical position corresponding to our edge's visual position and go for another round.
                box = prevBox;
                renderer = &box->renderer();
                offset = prevBox->caretRightmostOffset();
                continue;
            }

            ASSERT(offset == box->caretLeftmostOffset());

            unsigned char level = box->bidiLevel();
            InlineBox* prevBox = box->prevLeafChild();

            if (box->direction() == primaryDirection) {
                if (!prevBox) {
                    InlineBox* logicalStart = 0;
                    if (primaryDirection == LTR ? box->root().getLogicalStartBoxWithNode(logicalStart) : box->root().getLogicalEndBoxWithNode(logicalStart)) {
                        box = logicalStart;
                        renderer = &box->renderer();
                        offset = primaryDirection == LTR ? box->caretMinOffset() : box->caretMaxOffset();
                    }
                    break;
                }
                if (prevBox->bidiLevel() >= level)
                    break;

                level = prevBox->bidiLevel();

                InlineBox* nextBox = box;
                do {
                    nextBox = nextBox->nextLeafChild();
                } while (nextBox && nextBox->bidiLevel() > level);

                if (nextBox && nextBox->bidiLevel() == level)
                    break;

                box = prevBox;
                renderer = &box->renderer();
                offset = box->caretRightmostOffset();
                if (box->direction() == primaryDirection)
                    break;
                continue;
            }

            while (prevBox && !prevBox->renderer().node())
                prevBox = prevBox->prevLeafChild();

            if (prevBox) {
                box = prevBox;
                renderer = &box->renderer();
                offset = box->caretRightmostOffset();
                if (box->bidiLevel() > level) {
                    do {
                        prevBox = prevBox->prevLeafChild();
                    } while (prevBox && prevBox->bidiLevel() > level);

                    if (!prevBox || prevBox->bidiLevel() < level)
                        continue;
                }
            } else {
                // Trailing edge of a secondary run. Set to the leading edge of the entire run.
                while (true) {
                    while (InlineBox* nextBox = box->nextLeafChild()) {
                        if (nextBox->bidiLevel() < level)
                            break;
                        box = nextBox;
                    }
                    if (box->bidiLevel() == level)
                        break;
                    level = box->bidiLevel();
                    while (InlineBox* prevBox = box->prevLeafChild()) {
                        if (prevBox->bidiLevel() < level)
                            break;
                        box = prevBox;
                    }
                    if (box->bidiLevel() == level)
                        break;
                    level = box->bidiLevel();
                }
                renderer = &box->renderer();
                offset = primaryDirection == LTR ? box->caretMinOffset() : box->caretMaxOffset();
            }
            break;
        }

        p = createLegacyEditingPosition(renderer->node(), offset);

        if ((p.isCandidate() && p.downstream() != downstreamStart) || p.atStartOfTree() || p.atEndOfTree())
            return p;

        ASSERT(p != m_deepPosition);
    }
}

VisiblePosition VisiblePosition::left(bool stayInEditableContent) const
{
    Position pos = leftVisuallyDistinctCandidate();
    // FIXME: Why can't we move left from the last position in a tree?
    if (pos.atStartOfTree() || pos.atEndOfTree())
        return VisiblePosition();

    VisiblePosition left = VisiblePosition(pos, DOWNSTREAM);
    ASSERT(left != *this);

    if (!stayInEditableContent)
        return left;

    // FIXME: This may need to do something different from "before".
    return honorEditingBoundaryAtOrBefore(left);
}

Position VisiblePosition::rightVisuallyDistinctCandidate() const
{
    Position p = m_deepPosition;
    if (p.isNull())
        return Position();

    Position downstreamStart = p.downstream();
    TextDirection primaryDirection = p.primaryDirection();

    while (true) {
        InlineBox* box;
        int offset;
        p.getInlineBoxAndOffset(m_affinity, primaryDirection, box, offset);
        if (!box)
            return primaryDirection == LTR ? nextVisuallyDistinctCandidate(m_deepPosition) : previousVisuallyDistinctCandidate(m_deepPosition);

        RenderObject* renderer = &box->renderer();

        while (true) {
            if (renderer->isReplaced() && offset == box->caretLeftmostOffset())
                return box->isLeftToRightDirection() ? nextVisuallyDistinctCandidate(m_deepPosition) : previousVisuallyDistinctCandidate(m_deepPosition);

            if (!renderer->node()) {
                box = box->nextLeafChild();
                if (!box)
                    return primaryDirection == LTR ? nextVisuallyDistinctCandidate(m_deepPosition) : previousVisuallyDistinctCandidate(m_deepPosition);
                renderer = &box->renderer();
                offset = box->caretLeftmostOffset();
                continue;
            }

            offset = box->isLeftToRightDirection() ? renderer->nextOffset(offset) : renderer->previousOffset(offset);

            int caretMinOffset = box->caretMinOffset();
            int caretMaxOffset = box->caretMaxOffset();

            if (offset > caretMinOffset && offset < caretMaxOffset)
                break;

            if (box->isLeftToRightDirection() ? offset > caretMaxOffset : offset < caretMinOffset) {
                // Overshot to the right.
                InlineBox* nextBox = box->nextLeafChildIgnoringLineBreak();
                if (!nextBox) {
                    Position positionOnRight = primaryDirection == LTR ? nextVisuallyDistinctCandidate(m_deepPosition) : previousVisuallyDistinctCandidate(m_deepPosition);
                    if (positionOnRight.isNull())
                        return Position();

                    InlineBox* boxOnRight;
                    int offsetOnRight;
                    positionOnRight.getInlineBoxAndOffset(m_affinity, primaryDirection, boxOnRight, offsetOnRight);
                    if (boxOnRight && boxOnRight->root() == box->root())
                        return Position();
                    return positionOnRight;
                }

                // Reposition at the other logical position corresponding to our edge's visual position and go for another round.
                box = nextBox;
                renderer = &box->renderer();
                offset = nextBox->caretLeftmostOffset();
                continue;
            }

            ASSERT(offset == box->caretRightmostOffset());

            unsigned char level = box->bidiLevel();
            InlineBox* nextBox = box->nextLeafChild();

            if (box->direction() == primaryDirection) {
                if (!nextBox) {
                    InlineBox* logicalEnd = 0;
                    if (primaryDirection == LTR ? box->root().getLogicalEndBoxWithNode(logicalEnd) : box->root().getLogicalStartBoxWithNode(logicalEnd)) {
                        box = logicalEnd;
                        renderer = &box->renderer();
                        offset = primaryDirection == LTR ? box->caretMaxOffset() : box->caretMinOffset();
                    }
                    break;
                }

                if (nextBox->bidiLevel() >= level)
                    break;

                level = nextBox->bidiLevel();

                InlineBox* prevBox = box;
                do {
                    prevBox = prevBox->prevLeafChild();
                } while (prevBox && prevBox->bidiLevel() > level);

                if (prevBox && prevBox->bidiLevel() == level)   // For example, abc FED 123 ^ CBA
                    break;

                // For example, abc 123 ^ CBA or 123 ^ CBA abc
                box = nextBox;
                renderer = &box->renderer();
                offset = box->caretLeftmostOffset();
                if (box->direction() == primaryDirection)
                    break;
                continue;
            }

            while (nextBox && !nextBox->renderer().node())
                nextBox = nextBox->nextLeafChild();

            if (nextBox) {
                box = nextBox;
                renderer = &box->renderer();
                offset = box->caretLeftmostOffset();

                if (box->bidiLevel() > level) {
                    do {
                        nextBox = nextBox->nextLeafChild();
                    } while (nextBox && nextBox->bidiLevel() > level);

                    if (!nextBox || nextBox->bidiLevel() < level)
                        continue;
                }
            } else {
                // Trailing edge of a secondary run. Set to the leading edge of the entire run.
                while (true) {
                    while (InlineBox* prevBox = box->prevLeafChild()) {
                        if (prevBox->bidiLevel() < level)
                            break;
                        box = prevBox;
                    }
                    if (box->bidiLevel() == level)
                        break;
                    level = box->bidiLevel();
                    while (InlineBox* nextBox = box->nextLeafChild()) {
                        if (nextBox->bidiLevel() < level)
                            break;
                        box = nextBox;
                    }
                    if (box->bidiLevel() == level)
                        break;
                    level = box->bidiLevel();
                }
                renderer = &box->renderer();
                offset = primaryDirection == LTR ? box->caretMaxOffset() : box->caretMinOffset();
            }
            break;
        }

        p = createLegacyEditingPosition(renderer->node(), offset);

        if ((p.isCandidate() && p.downstream() != downstreamStart) || p.atStartOfTree() || p.atEndOfTree())
            return p;

        ASSERT(p != m_deepPosition);
    }
}

VisiblePosition VisiblePosition::right(bool stayInEditableContent) const
{
    Position pos = rightVisuallyDistinctCandidate();
    // FIXME: Why can't we move left from the last position in a tree?
    if (pos.atStartOfTree() || pos.atEndOfTree())
        return VisiblePosition();

    VisiblePosition right = VisiblePosition(pos, DOWNSTREAM);
    ASSERT(right != *this);

    if (!stayInEditableContent)
        return right;

    // FIXME: This may need to do something different from "after".
    return honorEditingBoundaryAtOrAfter(right);
}

VisiblePosition VisiblePosition::honorEditingBoundaryAtOrBefore(const VisiblePosition &pos) const
{
    if (pos.isNull())
        return pos;

    ContainerNode* highestRoot = highestEditableRoot(deepEquivalent());

    // Return empty position if pos is not somewhere inside the editable region containing this position
    if (highestRoot && !pos.deepEquivalent().deprecatedNode()->isDescendantOf(highestRoot))
        return VisiblePosition();

    // Return pos itself if the two are from the very same editable region, or both are non-editable
    // FIXME: In the non-editable case, just because the new position is non-editable doesn't mean movement
    // to it is allowed.  VisibleSelection::adjustForEditableContent has this problem too.
    if (highestEditableRoot(pos.deepEquivalent()) == highestRoot)
        return pos;

    // Return empty position if this position is non-editable, but pos is editable
    // FIXME: Move to the previous non-editable region.
    if (!highestRoot)
        return VisiblePosition();

    // Return the last position before pos that is in the same editable region as this position
    return lastEditableVisiblePositionBeforePositionInRoot(pos.deepEquivalent(), highestRoot);
}

VisiblePosition VisiblePosition::honorEditingBoundaryAtOrAfter(const VisiblePosition &pos) const
{
    if (pos.isNull())
        return pos;

    ContainerNode* highestRoot = highestEditableRoot(deepEquivalent());

    // Return empty position if pos is not somewhere inside the editable region containing this position
    if (highestRoot && !pos.deepEquivalent().deprecatedNode()->isDescendantOf(highestRoot))
        return VisiblePosition();

    // Return pos itself if the two are from the very same editable region, or both are non-editable
    // FIXME: In the non-editable case, just because the new position is non-editable doesn't mean movement
    // to it is allowed.  VisibleSelection::adjustForEditableContent has this problem too.
    if (highestEditableRoot(pos.deepEquivalent()) == highestRoot)
        return pos;

    // Return empty position if this position is non-editable, but pos is editable
    // FIXME: Move to the next non-editable region.
    if (!highestRoot)
        return VisiblePosition();

    // Return the next position after pos that is in the same editable region as this position
    return firstEditableVisiblePositionAfterPositionInRoot(pos.deepEquivalent(), highestRoot);
}

VisiblePosition VisiblePosition::skipToStartOfEditingBoundary(const VisiblePosition &pos) const
{
    if (pos.isNull())
        return pos;

    ContainerNode* highestRoot = highestEditableRoot(deepEquivalent());
    ContainerNode* highestRootOfPos = highestEditableRoot(pos.deepEquivalent());

    // Return pos itself if the two are from the very same editable region, or both are non-editable.
    if (highestRootOfPos == highestRoot)
        return pos;

    // If |pos| has an editable root, skip to the start
    if (highestRootOfPos)
        return VisiblePosition(previousVisuallyDistinctCandidate(Position(highestRootOfPos, Position::PositionIsBeforeAnchor).parentAnchoredEquivalent()));

    // That must mean that |pos| is not editable. Return the last position before pos that is in the same editable region as this position
    return lastEditableVisiblePositionBeforePositionInRoot(pos.deepEquivalent(), highestRoot);
}

VisiblePosition VisiblePosition::skipToEndOfEditingBoundary(const VisiblePosition &pos) const
{
    if (pos.isNull())
        return pos;

    ContainerNode* highestRoot = highestEditableRoot(deepEquivalent());
    ContainerNode* highestRootOfPos = highestEditableRoot(pos.deepEquivalent());

    // Return pos itself if the two are from the very same editable region, or both are non-editable.
    if (highestRootOfPos == highestRoot)
        return pos;

    // If |pos| has an editable root, skip to the end
    if (highestRootOfPos)
        return VisiblePosition(Position(highestRootOfPos, Position::PositionIsAfterAnchor).parentAnchoredEquivalent());

    // That must mean that |pos| is not editable. Return the next position after pos that is in the same editable region as this position
    return firstEditableVisiblePositionAfterPositionInRoot(pos.deepEquivalent(), highestRoot);
}

static Position canonicalizeCandidate(const Position& candidate)
{
    if (candidate.isNull())
        return Position();
    ASSERT(candidate.isCandidate());
    Position upstream = candidate.upstream();
    if (upstream.isCandidate())
        return upstream;
    return candidate;
}

Position VisiblePosition::canonicalPosition(const Position& passedPosition)
{
    // The updateLayout call below can do so much that even the position passed
    // in to us might get changed as a side effect. Specifically, there are code
    // paths that pass selection endpoints, and updateLayout can change the selection.
    Position position = passedPosition;

    // FIXME (9535):  Canonicalizing to the leftmost candidate means that if we're at a line wrap, we will
    // ask renderers to paint downstream carets for other renderers.
    // To fix this, we need to either a) add code to all paintCarets to pass the responsibility off to
    // the appropriate renderer for VisiblePosition's like these, or b) canonicalize to the rightmost candidate
    // unless the affinity is upstream.
    if (position.isNull())
        return Position();

    ASSERT(position.document());
    position.document()->updateLayoutIgnorePendingStylesheets();

    Node* node = position.containerNode();

    Position candidate = position.upstream();
    if (candidate.isCandidate())
        return candidate;
    candidate = position.downstream();
    if (candidate.isCandidate())
        return candidate;

    // When neither upstream or downstream gets us to a candidate (upstream/downstream won't leave
    // blocks or enter new ones), we search forward and backward until we find one.
    Position next = canonicalizeCandidate(nextCandidate(position));
    Position prev = canonicalizeCandidate(previousCandidate(position));
    Node* nextNode = next.deprecatedNode();
    Node* prevNode = prev.deprecatedNode();

    // The new position must be in the same editable element. Enforce that first.
    Element* editingRoot = editableRootForPosition(position);

    // If the html element is editable, descending into its body will look like a descent
    // from non-editable to editable content since rootEditableElement() always stops at the body.
    if (position.deprecatedNode()->isDocumentNode())
        return next.isNotNull() ? next : prev;

    bool prevIsInSameEditableElement = prevNode && editableRootForPosition(prev) == editingRoot;
    bool nextIsInSameEditableElement = nextNode && editableRootForPosition(next) == editingRoot;
    if (prevIsInSameEditableElement && !nextIsInSameEditableElement)
        return prev;

    if (nextIsInSameEditableElement && !prevIsInSameEditableElement)
        return next;

    if (!nextIsInSameEditableElement && !prevIsInSameEditableElement)
        return Position();

    // The new position should be in the same block flow element. Favor that.
    Element* originalBlock = node ? enclosingBlockFlowElement(*node) : 0;
    bool nextIsOutsideOriginalBlock = !nextNode->isDescendantOf(originalBlock) && nextNode != originalBlock;
    bool prevIsOutsideOriginalBlock = !prevNode->isDescendantOf(originalBlock) && prevNode != originalBlock;
    if (nextIsOutsideOriginalBlock && !prevIsOutsideOriginalBlock)
        return prev;

    return next;
}

UChar32 VisiblePosition::characterAfter() const
{
    // We canonicalize to the first of two equivalent candidates, but the second of the two candidates
    // is the one that will be inside the text node containing the character after this visible position.
    Position pos = m_deepPosition.downstream();
    if (!pos.containerNode() || !pos.containerNode()->isTextNode())
        return 0;
    switch (pos.anchorType()) {
    case Position::PositionIsAfterChildren:
    case Position::PositionIsAfterAnchor:
    case Position::PositionIsBeforeAnchor:
    case Position::PositionIsBeforeChildren:
        return 0;
    case Position::PositionIsOffsetInAnchor:
        break;
    }
    unsigned offset = static_cast<unsigned>(pos.offsetInContainerNode());
    Text* textNode = pos.containerText();
    unsigned length = textNode->length();
    if (offset >= length)
        return 0;

    return textNode->data().characterStartingAt(offset);
}

LayoutRect VisiblePosition::localCaretRect(RenderObject*& renderer) const
{
    PositionWithAffinity positionWithAffinity(m_deepPosition, m_affinity);
    return localCaretRectOfPosition(positionWithAffinity, renderer);
}

IntRect VisiblePosition::absoluteCaretBounds() const
{
    RenderObject* renderer;
    LayoutRect localRect = localCaretRect(renderer);
    if (localRect.isEmpty() || !renderer)
        return IntRect();

    return renderer->localToAbsoluteQuad(FloatRect(localRect)).enclosingBoundingBox();
}

int VisiblePosition::lineDirectionPointForBlockDirectionNavigation() const
{
    RenderObject* renderer;
    LayoutRect localRect = localCaretRect(renderer);
    if (localRect.isEmpty() || !renderer)
        return 0;

    // This ignores transforms on purpose, for now. Vertical navigation is done
    // without consulting transforms, so that 'up' in transformed text is 'up'
    // relative to the text, not absolute 'up'.
    FloatPoint caretPoint = renderer->localToAbsolute(localRect.location());
    RenderObject* containingBlock = renderer->containingBlock();
    if (!containingBlock)
        containingBlock = renderer; // Just use ourselves to determine the writing mode if we have no containing block.
    return caretPoint.x();
}

#ifndef NDEBUG

void VisiblePosition::debugPosition(const char* msg) const
{
    if (isNull())
        fprintf(stderr, "Position [%s]: null\n", msg);
    else {
        fprintf(stderr, "Position [%s]: %s, ", msg, m_deepPosition.deprecatedNode()->nodeName().utf8().data());
        m_deepPosition.showAnchorTypeAndOffset();
    }
}

void VisiblePosition::formatForDebugger(char* buffer, unsigned length) const
{
    m_deepPosition.formatForDebugger(buffer, length);
}

void VisiblePosition::showTreeForThis() const
{
    m_deepPosition.showTreeForThis();
}

#endif

PassRefPtr<Range> makeRange(const VisiblePosition &start, const VisiblePosition &end)
{
    if (start.isNull() || end.isNull())
        return nullptr;

    Position s = start.deepEquivalent().parentAnchoredEquivalent();
    Position e = end.deepEquivalent().parentAnchoredEquivalent();
    if (s.isNull() || e.isNull())
        return nullptr;

    return Range::create(s.containerNode()->document(), s.containerNode(), s.offsetInContainerNode(), e.containerNode(), e.offsetInContainerNode());
}

VisiblePosition startVisiblePosition(const Range *r, EAffinity affinity)
{
    return VisiblePosition(r->startPosition(), affinity);
}

bool setStart(Range *r, const VisiblePosition &visiblePosition)
{
    if (!r)
        return false;
    Position p = visiblePosition.deepEquivalent().parentAnchoredEquivalent();
    TrackExceptionState exceptionState;
    r->setStart(p.containerNode(), p.offsetInContainerNode(), exceptionState);
    return !exceptionState.hadException();
}

bool setEnd(Range *r, const VisiblePosition &visiblePosition)
{
    if (!r)
        return false;
    Position p = visiblePosition.deepEquivalent().parentAnchoredEquivalent();
    TrackExceptionState exceptionState;
    r->setEnd(p.containerNode(), p.offsetInContainerNode(), exceptionState);
    return !exceptionState.hadException();
}

Element* enclosingBlockFlowElement(const VisiblePosition& visiblePosition)
{
    if (visiblePosition.isNull())
        return 0;

    return enclosingBlockFlowElement(*visiblePosition.deepEquivalent().deprecatedNode());
}

bool isFirstVisiblePositionInNode(const VisiblePosition& visiblePosition, const ContainerNode* node)
{
    if (visiblePosition.isNull())
        return false;

    if (!visiblePosition.deepEquivalent().containerNode()->isDescendantOf(node))
        return false;

    VisiblePosition previous = visiblePosition.previous();
    return previous.isNull() || !previous.deepEquivalent().deprecatedNode()->isDescendantOf(node);
}

bool isLastVisiblePositionInNode(const VisiblePosition& visiblePosition, const ContainerNode* node)
{
    if (visiblePosition.isNull())
        return false;

    if (!visiblePosition.deepEquivalent().containerNode()->isDescendantOf(node))
        return false;

    VisiblePosition next = visiblePosition.next();
    return next.isNull() || !next.deepEquivalent().deprecatedNode()->isDescendantOf(node);
}

}  // namespace blink

#ifndef NDEBUG

void showTree(const blink::VisiblePosition* vpos)
{
    if (vpos)
        vpos->showTreeForThis();
}

void showTree(const blink::VisiblePosition& vpos)
{
    vpos.showTreeForThis();
}

#endif
