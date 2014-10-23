/*
 * Copyright (C) 2004, 2005, 2006 Apple Computer, Inc.  All rights reserved.
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
#include "core/editing/VisibleSelection.h"

#include "bindings/core/v8/ExceptionState.h"
#include "core/dom/Document.h"
#include "core/dom/Element.h"
#include "core/dom/Range.h"
#include "core/editing/TextIterator.h"
#include "core/editing/VisibleUnits.h"
#include "core/editing/htmlediting.h"
#include "core/rendering/RenderObject.h"
#include "platform/geometry/LayoutPoint.h"
#include "wtf/Assertions.h"
#include "wtf/text/CString.h"
#include "wtf/text/StringBuilder.h"
#include "wtf/unicode/CharacterNames.h"

#ifndef NDEBUG
#include <stdio.h>
#endif

namespace blink {

VisibleSelection::VisibleSelection()
    : m_affinity(DOWNSTREAM)
    , m_changeObserver(nullptr)
    , m_selectionType(NoSelection)
    , m_baseIsFirst(true)
    , m_isDirectional(false)
{
}

VisibleSelection::VisibleSelection(const Position& pos, EAffinity affinity, bool isDirectional)
    : m_base(pos)
    , m_extent(pos)
    , m_affinity(affinity)
    , m_changeObserver(nullptr)
    , m_isDirectional(isDirectional)
{
    validate();
}

VisibleSelection::VisibleSelection(const Position& base, const Position& extent, EAffinity affinity, bool isDirectional)
    : m_base(base)
    , m_extent(extent)
    , m_affinity(affinity)
    , m_changeObserver(nullptr)
    , m_isDirectional(isDirectional)
{
    validate();
}

VisibleSelection::VisibleSelection(const VisiblePosition& pos, bool isDirectional)
    : m_base(pos.deepEquivalent())
    , m_extent(pos.deepEquivalent())
    , m_affinity(pos.affinity())
    , m_changeObserver(nullptr)
    , m_isDirectional(isDirectional)
{
    validate();
}

VisibleSelection::VisibleSelection(const VisiblePosition& base, const VisiblePosition& extent, bool isDirectional)
    : m_base(base.deepEquivalent())
    , m_extent(extent.deepEquivalent())
    , m_affinity(base.affinity())
    , m_changeObserver(nullptr)
    , m_isDirectional(isDirectional)
{
    validate();
}

VisibleSelection::VisibleSelection(const Range* range, EAffinity affinity, bool isDirectional)
    : m_base(range->startPosition())
    , m_extent(range->endPosition())
    , m_affinity(affinity)
    , m_changeObserver(nullptr)
    , m_isDirectional(isDirectional)
{
    validate();
}

VisibleSelection::VisibleSelection(const VisibleSelection& other)
    : m_base(other.m_base)
    , m_extent(other.m_extent)
    , m_start(other.m_start)
    , m_end(other.m_end)
    , m_affinity(other.m_affinity)
    , m_changeObserver(nullptr) // Observer is associated with only one VisibleSelection, so this should not be copied.
    , m_selectionType(other.m_selectionType)
    , m_baseIsFirst(other.m_baseIsFirst)
    , m_isDirectional(other.m_isDirectional)
{
}

VisibleSelection& VisibleSelection::operator=(const VisibleSelection& other)
{
    didChange();

    m_base = other.m_base;
    m_extent = other.m_extent;
    m_start = other.m_start;
    m_end = other.m_end;
    m_affinity = other.m_affinity;
    m_changeObserver = nullptr;
    m_selectionType = other.m_selectionType;
    m_baseIsFirst = other.m_baseIsFirst;
    m_isDirectional = other.m_isDirectional;
    return *this;
}

VisibleSelection::~VisibleSelection()
{
#if !ENABLE(OILPAN)
    didChange();
#endif
}

VisibleSelection VisibleSelection::selectionFromContentsOfNode(Node* node)
{
    ASSERT(!editingIgnoresContent(node));
    return VisibleSelection(firstPositionInNode(node), lastPositionInNode(node), DOWNSTREAM);
}

void VisibleSelection::setBase(const Position& position)
{
    Position oldBase = m_base;
    m_base = position;
    validate();
    if (m_base != oldBase)
        didChange();
}

void VisibleSelection::setBase(const VisiblePosition& visiblePosition)
{
    Position oldBase = m_base;
    m_base = visiblePosition.deepEquivalent();
    validate();
    if (m_base != oldBase)
        didChange();
}

void VisibleSelection::setExtent(const Position& position)
{
    Position oldExtent = m_extent;
    m_extent = position;
    validate();
    if (m_extent != oldExtent)
        didChange();
}

void VisibleSelection::setExtent(const VisiblePosition& visiblePosition)
{
    Position oldExtent = m_extent;
    m_extent = visiblePosition.deepEquivalent();
    validate();
    if (m_extent != oldExtent)
        didChange();
}

PassRefPtrWillBeRawPtr<Range> VisibleSelection::firstRange() const
{
    if (isNone())
        return nullptr;
    Position start = m_start.parentAnchoredEquivalent();
    Position end = m_end.parentAnchoredEquivalent();
    return Range::create(*start.document(), start, end);
}

PassRefPtrWillBeRawPtr<Range> VisibleSelection::toNormalizedRange() const
{
    if (isNone())
        return nullptr;

    // Make sure we have an updated layout since this function is called
    // in the course of running edit commands which modify the DOM.
    // Failing to call this can result in equivalentXXXPosition calls returning
    // incorrect results.
    m_start.document()->updateLayout();

    // Check again, because updating layout can clear the selection.
    if (isNone())
        return nullptr;

    Position s, e;
    if (isCaret()) {
        // If the selection is a caret, move the range start upstream. This helps us match
        // the conventions of text editors tested, which make style determinations based
        // on the character before the caret, if any.
        s = m_start.upstream().parentAnchoredEquivalent();
        e = s;
    } else {
        // If the selection is a range, select the minimum range that encompasses the selection.
        // Again, this is to match the conventions of text editors tested, which make style
        // determinations based on the first character of the selection.
        // For instance, this operation helps to make sure that the "X" selected below is the
        // only thing selected. The range should not be allowed to "leak" out to the end of the
        // previous text node, or to the beginning of the next text node, each of which has a
        // different style.
        //
        // On a treasure map, <b>X</b> marks the spot.
        //                       ^ selected
        //
        ASSERT(isRange());
        s = m_start.downstream();
        e = m_end.upstream();
        if (comparePositions(s, e) > 0) {
            // Make sure the start is before the end.
            // The end can wind up before the start if collapsed whitespace is the only thing selected.
            Position tmp = s;
            s = e;
            e = tmp;
        }
        s = s.parentAnchoredEquivalent();
        e = e.parentAnchoredEquivalent();
    }

    if (!s.containerNode() || !e.containerNode())
        return nullptr;

    // VisibleSelections are supposed to always be valid.  This constructor will ASSERT
    // if a valid range could not be created, which is fine for this callsite.
    return Range::create(*s.document(), s, e);
}

bool VisibleSelection::expandUsingGranularity(TextGranularity granularity)
{
    if (isNone())
        return false;

    // FIXME: Do we need to check all of them?
    Position oldBase = m_base;
    Position oldExtent = m_extent;
    Position oldStart = m_start;
    Position oldEnd = m_end;
    validate(granularity);
    if (m_base != oldBase || m_extent != oldExtent || m_start != oldStart || m_end != oldEnd)
        didChange();
    return true;
}

static PassRefPtrWillBeRawPtr<Range> makeSearchRange(const Position& pos)
{
    Node* node = pos.deprecatedNode();
    if (!node)
        return nullptr;
    Document& document = node->document();
    if (!document.documentElement())
        return nullptr;
    Element* boundary = enclosingBlockFlowElement(*node);
    if (!boundary)
        return nullptr;

    RefPtrWillBeRawPtr<Range> searchRange(Range::create(document));
    TrackExceptionState exceptionState;

    Position start(pos.parentAnchoredEquivalent());
    searchRange->selectNodeContents(boundary, exceptionState);
    searchRange->setStart(start.containerNode(), start.offsetInContainerNode(), exceptionState);

    ASSERT(!exceptionState.hadException());
    if (exceptionState.hadException())
        return nullptr;

    return searchRange.release();
}

void VisibleSelection::appendTrailingWhitespace()
{
    RefPtrWillBeRawPtr<Range> searchRange = makeSearchRange(m_end);
    if (!searchRange)
        return;

    CharacterIterator charIt(searchRange.get(), TextIteratorEmitsCharactersBetweenAllVisiblePositions);
    bool changed = false;

    for (; charIt.length(); charIt.advance(1)) {
        UChar c = charIt.characterAt(0);
        if ((!isSpaceOrNewline(c) && c != noBreakSpace) || c == '\n')
            break;
        m_end = charIt.range()->endPosition();
        changed = true;
    }
    if (changed)
        didChange();
}

void VisibleSelection::setBaseAndExtentToDeepEquivalents()
{
    // Move the selection to rendered positions, if possible.
    bool baseAndExtentEqual = m_base == m_extent;
    if (m_base.isNotNull()) {
        m_base = VisiblePosition(m_base, m_affinity).deepEquivalent();
        if (baseAndExtentEqual)
            m_extent = m_base;
    }
    if (m_extent.isNotNull() && !baseAndExtentEqual)
        m_extent = VisiblePosition(m_extent, m_affinity).deepEquivalent();

    // Make sure we do not have a dangling base or extent.
    if (m_base.isNull() && m_extent.isNull())
        m_baseIsFirst = true;
    else if (m_base.isNull()) {
        m_base = m_extent;
        m_baseIsFirst = true;
    } else if (m_extent.isNull()) {
        m_extent = m_base;
        m_baseIsFirst = true;
    } else
        m_baseIsFirst = comparePositions(m_base, m_extent) <= 0;
}

void VisibleSelection::setStartAndEndFromBaseAndExtentRespectingGranularity(TextGranularity granularity)
{
    if (m_baseIsFirst) {
        m_start = m_base;
        m_end = m_extent;
    } else {
        m_start = m_extent;
        m_end = m_base;
    }

    switch (granularity) {
        case CharacterGranularity:
            // Don't do any expansion.
            break;
        case WordGranularity: {
            // General case: Select the word the caret is positioned inside of, or at the start of (RightWordIfOnBoundary).
            // Edge case: If the caret is after the last word in a soft-wrapped line or the last word in
            // the document, select that last word (LeftWordIfOnBoundary).
            // Edge case: If the caret is after the last word in a paragraph, select from the the end of the
            // last word to the line break (also RightWordIfOnBoundary);
            VisiblePosition start = VisiblePosition(m_start, m_affinity);
            VisiblePosition originalEnd(m_end, m_affinity);
            EWordSide side = RightWordIfOnBoundary;
            if (isEndOfEditableOrNonEditableContent(start) || (isEndOfLine(start) && !isStartOfLine(start) && !isEndOfParagraph(start)))
                side = LeftWordIfOnBoundary;
            m_start = startOfWord(start, side).deepEquivalent();
            side = RightWordIfOnBoundary;
            if (isEndOfEditableOrNonEditableContent(originalEnd) || (isEndOfLine(originalEnd) && !isStartOfLine(originalEnd) && !isEndOfParagraph(originalEnd)))
                side = LeftWordIfOnBoundary;

            VisiblePosition wordEnd(endOfWord(originalEnd, side));
            VisiblePosition end(wordEnd);

            if (isEndOfParagraph(originalEnd) && !isEmptyTableCell(m_start.deprecatedNode())) {
                // Select the paragraph break (the space from the end of a paragraph to the start of
                // the next one) to match TextEdit.
                end = wordEnd.next();

                if (Element* table = isFirstPositionAfterTable(end)) {
                    // The paragraph break after the last paragraph in the last cell of a block table ends
                    // at the start of the paragraph after the table.
                    if (isBlock(table))
                        end = end.next(CannotCrossEditingBoundary);
                    else
                        end = wordEnd;
                }

                if (end.isNull())
                    end = wordEnd;

            }

            m_end = end.deepEquivalent();
            break;
        }
        case SentenceGranularity: {
            m_start = startOfSentence(VisiblePosition(m_start, m_affinity)).deepEquivalent();
            m_end = endOfSentence(VisiblePosition(m_end, m_affinity)).deepEquivalent();
            break;
        }
        case LineGranularity: {
            m_start = startOfLine(VisiblePosition(m_start, m_affinity)).deepEquivalent();
            VisiblePosition end = endOfLine(VisiblePosition(m_end, m_affinity));
            // If the end of this line is at the end of a paragraph, include the space
            // after the end of the line in the selection.
            if (isEndOfParagraph(end)) {
                VisiblePosition next = end.next();
                if (next.isNotNull())
                    end = next;
            }
            m_end = end.deepEquivalent();
            break;
        }
        case LineBoundary:
            m_start = startOfLine(VisiblePosition(m_start, m_affinity)).deepEquivalent();
            m_end = endOfLine(VisiblePosition(m_end, m_affinity)).deepEquivalent();
            break;
        case ParagraphGranularity: {
            VisiblePosition pos(m_start, m_affinity);
            if (isStartOfLine(pos) && isEndOfEditableOrNonEditableContent(pos))
                pos = pos.previous();
            m_start = startOfParagraph(pos).deepEquivalent();
            VisiblePosition visibleParagraphEnd = endOfParagraph(VisiblePosition(m_end, m_affinity));

            // Include the "paragraph break" (the space from the end of this paragraph to the start
            // of the next one) in the selection.
            VisiblePosition end(visibleParagraphEnd.next());

            if (Element* table = isFirstPositionAfterTable(end)) {
                // The paragraph break after the last paragraph in the last cell of a block table ends
                // at the start of the paragraph after the table, not at the position just after the table.
                if (isBlock(table))
                    end = end.next(CannotCrossEditingBoundary);
                // There is no parargraph break after the last paragraph in the last cell of an inline table.
                else
                    end = visibleParagraphEnd;
            }

            if (end.isNull())
                end = visibleParagraphEnd;

            m_end = end.deepEquivalent();
            break;
        }
        case DocumentBoundary:
            m_start = startOfDocument(VisiblePosition(m_start, m_affinity)).deepEquivalent();
            m_end = endOfDocument(VisiblePosition(m_end, m_affinity)).deepEquivalent();
            break;
        case ParagraphBoundary:
            m_start = startOfParagraph(VisiblePosition(m_start, m_affinity)).deepEquivalent();
            m_end = endOfParagraph(VisiblePosition(m_end, m_affinity)).deepEquivalent();
            break;
        case SentenceBoundary:
            m_start = startOfSentence(VisiblePosition(m_start, m_affinity)).deepEquivalent();
            m_end = endOfSentence(VisiblePosition(m_end, m_affinity)).deepEquivalent();
            break;
    }

    // Make sure we do not have a dangling start or end.
    if (m_start.isNull())
        m_start = m_end;
    if (m_end.isNull())
        m_end = m_start;
}

void VisibleSelection::updateSelectionType()
{
    if (m_start.isNull()) {
        ASSERT(m_end.isNull());
        m_selectionType = NoSelection;
    } else if (m_start == m_end || m_start.upstream() == m_end.upstream()) {
        m_selectionType = CaretSelection;
    } else
        m_selectionType = RangeSelection;

    // Affinity only makes sense for a caret
    if (m_selectionType != CaretSelection)
        m_affinity = DOWNSTREAM;
}

void VisibleSelection::validate(TextGranularity granularity)
{
    setBaseAndExtentToDeepEquivalents();
    setStartAndEndFromBaseAndExtentRespectingGranularity(granularity);
    adjustSelectionToAvoidCrossingShadowBoundaries();
    adjustSelectionToAvoidCrossingEditingBoundaries();
    updateSelectionType();

    if (selectionType() == RangeSelection) {
        // "Constrain" the selection to be the smallest equivalent range of nodes.
        // This is a somewhat arbitrary choice, but experience shows that it is
        // useful to make to make the selection "canonical" (if only for
        // purposes of comparing selections). This is an ideal point of the code
        // to do this operation, since all selection changes that result in a RANGE
        // come through here before anyone uses it.
        // FIXME: Canonicalizing is good, but haven't we already done it (when we
        // set these two positions to VisiblePosition deepEquivalent()s above)?
        m_start = m_start.downstream();
        m_end = m_end.upstream();

        // FIXME: Position::downstream() or Position::upStream() might violate editing boundaries
        // if an anchor node has a Shadow DOM. So we adjust selection to avoid crossing editing
        // boundaries again. See https://bugs.webkit.org/show_bug.cgi?id=87463
        adjustSelectionToAvoidCrossingEditingBoundaries();
    }
}

// FIXME: This function breaks the invariant of this class.
// But because we use VisibleSelection to store values in editing commands for use when
// undoing the command, we need to be able to create a selection that while currently
// invalid, will be valid once the changes are undone. This is a design problem.
// To fix it we either need to change the invariants of VisibleSelection or create a new
// class for editing to use that can manipulate selections that are not currently valid.
void VisibleSelection::setWithoutValidation(const Position& base, const Position& extent)
{
    ASSERT(!base.isNull());
    ASSERT(!extent.isNull());
    ASSERT(m_affinity == DOWNSTREAM);
    m_base = base;
    m_extent = extent;
    m_baseIsFirst = comparePositions(base, extent) <= 0;
    if (m_baseIsFirst) {
        m_start = base;
        m_end = extent;
    } else {
        m_start = extent;
        m_end = base;
    }
    m_selectionType = base == extent ? CaretSelection : RangeSelection;
    didChange();
}

static Position adjustPositionForEnd(const Position& currentPosition, Node* startContainerNode)
{
    TreeScope& treeScope = startContainerNode->treeScope();

    ASSERT(currentPosition.containerNode()->treeScope() != treeScope);

    if (Node* ancestor = treeScope.ancestorInThisScope(currentPosition.containerNode())) {
        if (ancestor->contains(startContainerNode))
            return positionAfterNode(ancestor);
        return positionBeforeNode(ancestor);
    }

    if (Node* lastChild = treeScope.rootNode().lastChild())
        return positionAfterNode(lastChild);

    return Position();
}

static Position adjustPositionForStart(const Position& currentPosition, Node* endContainerNode)
{
    TreeScope& treeScope = endContainerNode->treeScope();

    ASSERT(currentPosition.containerNode()->treeScope() != treeScope);

    if (Node* ancestor = treeScope.ancestorInThisScope(currentPosition.containerNode())) {
        if (ancestor->contains(endContainerNode))
            return positionBeforeNode(ancestor);
        return positionAfterNode(ancestor);
    }

    if (Node* firstChild = treeScope.rootNode().firstChild())
        return positionBeforeNode(firstChild);

    return Position();
}

void VisibleSelection::adjustSelectionToAvoidCrossingShadowBoundaries()
{
    if (m_base.isNull() || m_start.isNull() || m_end.isNull())
        return;

    if (m_start.anchorNode()->treeScope() == m_end.anchorNode()->treeScope())
        return;

    if (m_baseIsFirst) {
        m_extent = adjustPositionForEnd(m_end, m_start.containerNode());
        m_end = m_extent;
    } else {
        m_extent = adjustPositionForStart(m_start, m_end.containerNode());
        m_start = m_extent;
    }

    ASSERT(m_start.anchorNode()->treeScope() == m_end.anchorNode()->treeScope());
}

void VisibleSelection::adjustSelectionToAvoidCrossingEditingBoundaries()
{
    if (m_base.isNull() || m_start.isNull() || m_end.isNull())
        return;

    ContainerNode* baseRoot = highestEditableRoot(m_base);
    ContainerNode* startRoot = highestEditableRoot(m_start);
    ContainerNode* endRoot = highestEditableRoot(m_end);

    Element* baseEditableAncestor = lowestEditableAncestor(m_base.containerNode());

    // The base, start and end are all in the same region.  No adjustment necessary.
    if (baseRoot == startRoot && baseRoot == endRoot)
        return;

    // The selection is based in editable content.
    if (baseRoot) {
        // If the start is outside the base's editable root, cap it at the start of that root.
        // If the start is in non-editable content that is inside the base's editable root, put it
        // at the first editable position after start inside the base's editable root.
        if (startRoot != baseRoot) {
            VisiblePosition first = firstEditableVisiblePositionAfterPositionInRoot(m_start, baseRoot);
            m_start = first.deepEquivalent();
            if (m_start.isNull()) {
                ASSERT_NOT_REACHED();
                m_start = m_end;
            }
        }
        // If the end is outside the base's editable root, cap it at the end of that root.
        // If the end is in non-editable content that is inside the base's root, put it
        // at the last editable position before the end inside the base's root.
        if (endRoot != baseRoot) {
            VisiblePosition last = lastEditableVisiblePositionBeforePositionInRoot(m_end, baseRoot);
            m_end = last.deepEquivalent();
            if (m_end.isNull())
                m_end = m_start;
        }
    // The selection is based in non-editable content.
    } else {
        // FIXME: Non-editable pieces inside editable content should be atomic, in the same way that editable
        // pieces in non-editable content are atomic.

        // The selection ends in editable content or non-editable content inside a different editable ancestor,
        // move backward until non-editable content inside the same lowest editable ancestor is reached.
        Element* endEditableAncestor = lowestEditableAncestor(m_end.containerNode());
        if (endRoot || endEditableAncestor != baseEditableAncestor) {

            Position p = previousVisuallyDistinctCandidate(m_end);
            Element* shadowAncestor = endRoot ? endRoot->shadowHost() : 0;
            if (p.isNull() && shadowAncestor)
                p = positionAfterNode(shadowAncestor);
            while (p.isNotNull() && !(lowestEditableAncestor(p.containerNode()) == baseEditableAncestor && !isEditablePosition(p))) {
                Element* root = editableRootForPosition(p);
                shadowAncestor = root ? root->shadowHost() : 0;
                p = isAtomicNode(p.containerNode()) ? positionInParentBeforeNode(*p.containerNode()) : previousVisuallyDistinctCandidate(p);
                if (p.isNull() && shadowAncestor)
                    p = positionAfterNode(shadowAncestor);
            }
            VisiblePosition previous(p);

            if (previous.isNull()) {
                // The selection crosses an Editing boundary.  This is a
                // programmer error in the editing code.  Happy debugging!
                ASSERT_NOT_REACHED();
                m_base = Position();
                m_extent = Position();
                validate();
                return;
            }
            m_end = previous.deepEquivalent();
        }

        // The selection starts in editable content or non-editable content inside a different editable ancestor,
        // move forward until non-editable content inside the same lowest editable ancestor is reached.
        Element* startEditableAncestor = lowestEditableAncestor(m_start.containerNode());
        if (startRoot || startEditableAncestor != baseEditableAncestor) {
            Position p = nextVisuallyDistinctCandidate(m_start);
            Element* shadowAncestor = startRoot ? startRoot->shadowHost() : 0;
            if (p.isNull() && shadowAncestor)
                p = positionBeforeNode(shadowAncestor);
            while (p.isNotNull() && !(lowestEditableAncestor(p.containerNode()) == baseEditableAncestor && !isEditablePosition(p))) {
                Element* root = editableRootForPosition(p);
                shadowAncestor = root ? root->shadowHost() : 0;
                p = isAtomicNode(p.containerNode()) ? positionInParentAfterNode(*p.containerNode()) : nextVisuallyDistinctCandidate(p);
                if (p.isNull() && shadowAncestor)
                    p = positionBeforeNode(shadowAncestor);
            }
            VisiblePosition next(p);

            if (next.isNull()) {
                // The selection crosses an Editing boundary.  This is a
                // programmer error in the editing code.  Happy debugging!
                ASSERT_NOT_REACHED();
                m_base = Position();
                m_extent = Position();
                validate();
                return;
            }
            m_start = next.deepEquivalent();
        }
    }

    // Correct the extent if necessary.
    if (baseEditableAncestor != lowestEditableAncestor(m_extent.containerNode()))
        m_extent = m_baseIsFirst ? m_end : m_start;
}

VisiblePosition VisibleSelection::visiblePositionRespectingEditingBoundary(const LayoutPoint& localPoint, Node* targetNode) const
{
    if (!targetNode->renderer())
        return VisiblePosition();

    LayoutPoint selectionEndPoint = localPoint;
    Element* editableElement = rootEditableElement();

    if (editableElement && !editableElement->contains(targetNode)) {
        if (!editableElement->renderer())
            return VisiblePosition();

        FloatPoint absolutePoint = targetNode->renderer()->localToAbsolute(FloatPoint(selectionEndPoint));
        selectionEndPoint = roundedLayoutPoint(editableElement->renderer()->absoluteToLocal(absolutePoint));
        targetNode = editableElement;
    }

    return VisiblePosition(targetNode->renderer()->positionForPoint(selectionEndPoint));
}


bool VisibleSelection::isContentEditable() const
{
    return isEditablePosition(start());
}

bool VisibleSelection::hasEditableStyle() const
{
    return isEditablePosition(start(), ContentIsEditable, DoNotUpdateStyle);
}

bool VisibleSelection::isContentRichlyEditable() const
{
    return isRichlyEditablePosition(start());
}

Element* VisibleSelection::rootEditableElement() const
{
    return editableRootForPosition(start());
}

Node* VisibleSelection::nonBoundaryShadowTreeRootNode() const
{
    return start().deprecatedNode() ? start().deprecatedNode()->nonBoundaryShadowTreeRootNode() : 0;
}

VisibleSelection::ChangeObserver::ChangeObserver()
{
}

VisibleSelection::ChangeObserver::~ChangeObserver()
{
}

void VisibleSelection::setChangeObserver(ChangeObserver& observer)
{
    ASSERT(!m_changeObserver);
    m_changeObserver = &observer;
}

void VisibleSelection::clearChangeObserver()
{
    ASSERT(m_changeObserver);
    m_changeObserver = nullptr;
}

void VisibleSelection::didChange()
{
    if (m_changeObserver)
        m_changeObserver->didChangeVisibleSelection();
}

void VisibleSelection::trace(Visitor* visitor)
{
    visitor->trace(m_base);
    visitor->trace(m_extent);
    visitor->trace(m_start);
    visitor->trace(m_end);
    visitor->trace(m_changeObserver);
}

static bool isValidPosition(const Position& position)
{
    if (!position.inDocument())
        return false;

    if (position.anchorType() != Position::PositionIsOffsetInAnchor)
        return true;

    if (position.offsetInContainerNode() < 0)
        return false;

    const unsigned offset = static_cast<unsigned>(position.offsetInContainerNode());
    const unsigned nodeLength = position.anchorNode()->lengthOfContents();
    return offset <= nodeLength;
}

void VisibleSelection::validatePositionsIfNeeded()
{
    if (!isValidPosition(m_base) || !isValidPosition(m_extent) || !isValidPosition(m_start) || !isValidPosition(m_end))
        validate();
}

#ifndef NDEBUG

void VisibleSelection::debugPosition() const
{
    fprintf(stderr, "VisibleSelection ===============\n");

    if (!m_start.anchorNode())
        fputs("pos:   null", stderr);
    else if (m_start == m_end) {
        fprintf(stderr, "pos:   %s ", m_start.anchorNode()->nodeName().utf8().data());
        m_start.showAnchorTypeAndOffset();
    } else {
        fprintf(stderr, "start: %s ", m_start.anchorNode()->nodeName().utf8().data());
        m_start.showAnchorTypeAndOffset();
        fprintf(stderr, "end:   %s ", m_end.anchorNode()->nodeName().utf8().data());
        m_end.showAnchorTypeAndOffset();
    }

    fprintf(stderr, "================================\n");
}

void VisibleSelection::formatForDebugger(char* buffer, unsigned length) const
{
    StringBuilder result;
    String s;

    if (isNone()) {
        result.appendLiteral("<none>");
    } else {
        const int FormatBufferSize = 1024;
        char s[FormatBufferSize];
        result.appendLiteral("from ");
        start().formatForDebugger(s, FormatBufferSize);
        result.append(s);
        result.appendLiteral(" to ");
        end().formatForDebugger(s, FormatBufferSize);
        result.append(s);
    }

    strncpy(buffer, result.toString().utf8().data(), length - 1);
}

void VisibleSelection::showTreeForThis() const
{
    if (start().anchorNode()) {
        start().anchorNode()->showTreeAndMark(start().anchorNode(), "S", end().anchorNode(), "E");
        fputs("start: ", stderr);
        start().showAnchorTypeAndOffset();
        fputs("end: ", stderr);
        end().showAnchorTypeAndOffset();
    }
}

#endif

} // namespace blink

#ifndef NDEBUG

void showTree(const blink::VisibleSelection& sel)
{
    sel.showTreeForThis();
}

void showTree(const blink::VisibleSelection* sel)
{
    if (sel)
        sel->showTreeForThis();
}

#endif
