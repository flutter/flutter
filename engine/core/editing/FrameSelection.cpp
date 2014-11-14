/*
 * Copyright (C) 2004, 2008, 2009, 2010 Apple Inc. All rights reserved.
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
#include "core/editing/FrameSelection.h"

#include "bindings/core/v8/ExceptionState.h"
#include "core/css/StylePropertySet.h"
#include "core/dom/CharacterData.h"
#include "core/dom/Document.h"
#include "core/dom/Element.h"
#include "core/dom/ElementTraversal.h"
#include "core/dom/NodeTraversal.h"
#include "core/dom/Text.h"
#include "core/editing/Editor.h"
#include "core/editing/InputMethodController.h"
#include "core/editing/RenderedPosition.h"
#include "core/editing/SpellChecker.h"
#include "core/editing/TextIterator.h"
#include "core/editing/TypingCommand.h"
#include "core/editing/VisibleUnits.h"
#include "core/editing/htmlediting.h"
#include "core/events/Event.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/frame/LocalFrame.h"
#include "core/page/EditorClient.h"
#include "core/page/EventHandler.h"
#include "core/page/FocusController.h"
#include "core/frame/FrameView.h"
#include "core/page/Page.h"
#include "core/frame/Settings.h"
#include "core/rendering/HitTestRequest.h"
#include "core/rendering/HitTestResult.h"
#include "core/rendering/InlineTextBox.h"
#include "core/rendering/RenderLayer.h"
#include "core/rendering/RenderText.h"
#include "core/rendering/RenderTheme.h"
#include "core/rendering/RenderView.h"
#include "platform/geometry/FloatQuad.h"
#include "platform/graphics/GraphicsContext.h"
#include "wtf/text/CString.h"
#include <stdio.h>

#define EDIT_DEBUG 0

namespace blink {

static inline LayoutUnit NoXPosForVerticalArrowNavigation()
{
    return LayoutUnit::min();
}

static inline bool shouldAlwaysUseDirectionalSelection(LocalFrame* frame)
{
    return !frame || frame->editor().behavior().shouldConsiderSelectionAsDirectional();
}

FrameSelection::FrameSelection(LocalFrame* frame)
    : m_frame(frame)
    , m_xPosForVerticalArrowNavigation(NoXPosForVerticalArrowNavigation())
    , m_observingVisibleSelection(false)
    , m_granularity(CharacterGranularity)
    , m_caretBlinkTimer(this, &FrameSelection::caretBlinkTimerFired)
    , m_caretRectDirty(true)
    , m_shouldPaintCaret(true)
    , m_isCaretBlinkingSuspended(false)
    , m_focused(frame && frame->page() && frame->page()->focusController().focusedFrame() == frame)
    , m_shouldShowBlockCursor(false)
{
    if (shouldAlwaysUseDirectionalSelection(m_frame))
        m_selection.setIsDirectional(true);
}

FrameSelection::~FrameSelection()
{
#if !ENABLE(OILPAN)
    // Oilpan: No need to clear out VisibleSelection observer;
    // it is finalized as a part object of FrameSelection.
    stopObservingVisibleSelectionChangeIfNecessary();
#endif
}

Element* FrameSelection::rootEditableElementOrDocumentElement() const
{
    Element* selectionRoot = m_selection.rootEditableElement();
    return selectionRoot ? selectionRoot : m_frame->document()->documentElement();
}

ContainerNode* FrameSelection::rootEditableElementOrTreeScopeRootNode() const
{
    Element* selectionRoot = m_selection.rootEditableElement();
    if (selectionRoot)
        return selectionRoot;

    Node* node = m_selection.base().containerNode();
    return node ? &node->treeScope().rootNode() : 0;
}

void FrameSelection::moveTo(const VisiblePosition &pos, EUserTriggered userTriggered, CursorAlignOnScroll align)
{
    SetSelectionOptions options = CloseTyping | ClearTypingStyle | userTriggered;
    setSelection(VisibleSelection(pos.deepEquivalent(), pos.deepEquivalent(), pos.affinity(), m_selection.isDirectional()), options, align);
}

void FrameSelection::moveTo(const VisiblePosition &base, const VisiblePosition &extent, EUserTriggered userTriggered)
{
    const bool selectionHasDirection = true;
    SetSelectionOptions options = CloseTyping | ClearTypingStyle | userTriggered;
    setSelection(VisibleSelection(base.deepEquivalent(), extent.deepEquivalent(), base.affinity(), selectionHasDirection), options);
}

void FrameSelection::moveTo(const Position &pos, EAffinity affinity, EUserTriggered userTriggered)
{
    SetSelectionOptions options = CloseTyping | ClearTypingStyle | userTriggered;
    setSelection(VisibleSelection(pos, affinity, m_selection.isDirectional()), options);
}

static void adjustEndpointsAtBidiBoundary(VisiblePosition& visibleBase, VisiblePosition& visibleExtent)
{
    RenderedPosition base(visibleBase);
    RenderedPosition extent(visibleExtent);

    if (base.isNull() || extent.isNull() || base.isEquivalent(extent))
        return;

    if (base.atLeftBoundaryOfBidiRun()) {
        if (!extent.atRightBoundaryOfBidiRun(base.bidiLevelOnRight())
            && base.isEquivalent(extent.leftBoundaryOfBidiRun(base.bidiLevelOnRight()))) {
            visibleBase = VisiblePosition(base.positionAtLeftBoundaryOfBiDiRun());
            return;
        }
        return;
    }

    if (base.atRightBoundaryOfBidiRun()) {
        if (!extent.atLeftBoundaryOfBidiRun(base.bidiLevelOnLeft())
            && base.isEquivalent(extent.rightBoundaryOfBidiRun(base.bidiLevelOnLeft()))) {
            visibleBase = VisiblePosition(base.positionAtRightBoundaryOfBiDiRun());
            return;
        }
        return;
    }

    if (extent.atLeftBoundaryOfBidiRun() && extent.isEquivalent(base.leftBoundaryOfBidiRun(extent.bidiLevelOnRight()))) {
        visibleExtent = VisiblePosition(extent.positionAtLeftBoundaryOfBiDiRun());
        return;
    }

    if (extent.atRightBoundaryOfBidiRun() && extent.isEquivalent(base.rightBoundaryOfBidiRun(extent.bidiLevelOnLeft()))) {
        visibleExtent = VisiblePosition(extent.positionAtRightBoundaryOfBiDiRun());
        return;
    }
}

void FrameSelection::setNonDirectionalSelectionIfNeeded(const VisibleSelection& passedNewSelection, TextGranularity granularity,
    EndPointsAdjustmentMode endpointsAdjustmentMode)
{
    VisibleSelection newSelection = passedNewSelection;
    bool isDirectional = shouldAlwaysUseDirectionalSelection(m_frame) || newSelection.isDirectional();

    VisiblePosition base = m_originalBase.isNotNull() ? m_originalBase : newSelection.visibleBase();
    VisiblePosition newBase = base;
    VisiblePosition extent = newSelection.visibleExtent();
    VisiblePosition newExtent = extent;
    if (endpointsAdjustmentMode == AdjustEndpointsAtBidiBoundary)
        adjustEndpointsAtBidiBoundary(newBase, newExtent);

    if (newBase != base || newExtent != extent) {
        m_originalBase = base;
        newSelection.setBase(newBase);
        newSelection.setExtent(newExtent);
    } else if (m_originalBase.isNotNull()) {
        if (m_selection.base() == newSelection.base())
            newSelection.setBase(m_originalBase);
        m_originalBase.clear();
    }

    newSelection.setIsDirectional(isDirectional); // Adjusting base and extent will make newSelection always directional
    if (m_selection == newSelection)
        return;

    setSelection(newSelection, granularity);
}

void FrameSelection::setSelection(const VisibleSelection& newSelection, SetSelectionOptions options, CursorAlignOnScroll align, TextGranularity granularity)
{
    bool closeTyping = options & CloseTyping;
    bool shouldClearTypingStyle = options & ClearTypingStyle;
    EUserTriggered userTriggered = selectionOptionsToUserTriggered(options);

    VisibleSelection s = validateSelection(newSelection);
    if (shouldAlwaysUseDirectionalSelection(m_frame))
        s.setIsDirectional(true);

    if (!m_frame) {
        m_selection = s;
        return;
    }

    // <http://bugs.webkit.org/show_bug.cgi?id=23464>: Infinite recursion at FrameSelection::setSelection
    // if document->frame() == m_frame we can get into an infinite loop
    if (s.base().anchorNode()) {
        Document& document = *s.base().document();
        if (document.frame() && document.frame() != m_frame && document != m_frame->document()) {
            RefPtr<LocalFrame> guard = document.frame();
            document.frame()->selection().setSelection(s, options, align, granularity);
            // It's possible that during the above set selection, this FrameSelection has been modified by
            // selectFrameElementInParentIfFullySelected, but that the selection is no longer valid since
            // the frame is about to be destroyed. If this is the case, clear our selection.
            if (guard->hasOneRef() && !m_selection.isNonOrphanedCaretOrRange())
                clear();
            return;
        }
    }

    m_granularity = granularity;

    if (closeTyping)
        TypingCommand::closeTyping(m_frame);

    if (shouldClearTypingStyle)
        clearTypingStyle();

    if (m_selection == s) {
        // Even if selection was not changed, selection offsets may have been changed.
        m_frame->inputMethodController().cancelCompositionIfSelectionIsInvalid();
        notifyRendererOfSelectionChange(userTriggered);
        return;
    }

    VisibleSelection oldSelection = m_selection;

    m_selection = s;
    setCaretRectNeedsUpdate();

    if (!s.isNone() && !(options & DoNotSetFocus))
        setFocusedNodeIfNeeded();

    if (!(options & DoNotUpdateAppearance)) {
        // Hits in compositing/overflow/do-not-paint-outline-into-composited-scrolling-contents.html
        DisableCompositingQueryAsserts disabler;
        updateAppearance(ResetCaretBlink);
    }

    // Always clear the x position used for vertical arrow navigation.
    // It will be restored by the vertical arrow navigation code if necessary.
    m_xPosForVerticalArrowNavigation = NoXPosForVerticalArrowNavigation();
    selectFrameElementInParentIfFullySelected();
    notifyRendererOfSelectionChange(userTriggered);
    m_frame->editor().respondToChangedSelection(oldSelection, options);
    if (userTriggered == UserTriggered) {
        ScrollAlignment alignment;

        if (m_frame->editor().behavior().shouldCenterAlignWhenSelectionIsRevealed())
            alignment = (align == AlignCursorOnScrollAlways) ? ScrollAlignment::alignCenterAlways : ScrollAlignment::alignCenterIfNeeded;
        else
            alignment = (align == AlignCursorOnScrollAlways) ? ScrollAlignment::alignTopAlways : ScrollAlignment::alignToEdgeIfNeeded;

        revealSelection(alignment, RevealExtent);
    }

    notifyAccessibilityForSelectionChange();
    notifyCompositorForSelectionChange();
    m_frame->domWindow()->enqueueDocumentEvent(Event::create(EventTypeNames::selectionchange));
}

static bool removingNodeRemovesPosition(Node& node, const Position& position)
{
    if (!position.anchorNode())
        return false;

    if (position.anchorNode() == node)
        return true;

    if (!node.isElementNode())
        return false;

    Element& element = toElement(node);
    return element.containsIncludingShadowDOM(position.anchorNode());
}

void FrameSelection::nodeWillBeRemoved(Node& node)
{
    // There can't be a selection inside a fragment, so if a fragment's node is being removed,
    // the selection in the document that created the fragment needs no adjustment.
    if (isNone() || !node.inActiveDocument())
        return;

    respondToNodeModification(node, removingNodeRemovesPosition(node, m_selection.base()), removingNodeRemovesPosition(node, m_selection.extent()),
        removingNodeRemovesPosition(node, m_selection.start()), removingNodeRemovesPosition(node, m_selection.end()));
}

void FrameSelection::respondToNodeModification(Node& node, bool baseRemoved, bool extentRemoved, bool startRemoved, bool endRemoved)
{
    ASSERT(node.document().isActive());

    bool clearRenderTreeSelection = false;
    bool clearDOMTreeSelection = false;

    if (startRemoved || endRemoved) {
        Position start = m_selection.start();
        Position end = m_selection.end();
        if (startRemoved)
            updatePositionForNodeRemoval(start, node);
        if (endRemoved)
            updatePositionForNodeRemoval(end, node);

        if (start.isNotNull() && end.isNotNull()) {
            if (m_selection.isBaseFirst())
                m_selection.setWithoutValidation(start, end);
            else
                m_selection.setWithoutValidation(end, start);
        } else
            clearDOMTreeSelection = true;

        clearRenderTreeSelection = true;
    } else if (baseRemoved || extentRemoved) {
        // The base and/or extent are about to be removed, but the start and end aren't.
        // Change the base and extent to the start and end, but don't re-validate the
        // selection, since doing so could move the start and end into the node
        // that is about to be removed.
        if (m_selection.isBaseFirst())
            m_selection.setWithoutValidation(m_selection.start(), m_selection.end());
        else
            m_selection.setWithoutValidation(m_selection.end(), m_selection.start());
    } else if (RefPtr<Range> range = m_selection.firstRange()) {
        TrackExceptionState exceptionState;
        Range::CompareResults compareResult = range->compareNode(&node, exceptionState);
        if (!exceptionState.hadException() && (compareResult == Range::NODE_BEFORE_AND_AFTER || compareResult == Range::NODE_INSIDE)) {
            // If we did nothing here, when this node's renderer was destroyed, the rect that it
            // occupied would be invalidated, but, selection gaps that change as a result of
            // the removal wouldn't be invalidated.
            // FIXME: Don't do so much unnecessary invalidation.
            clearRenderTreeSelection = true;
        }
    }

    if (clearRenderTreeSelection)
        m_selection.start().document()->renderView()->clearSelection();

    if (clearDOMTreeSelection)
        setSelection(VisibleSelection(), DoNotSetFocus);
}

static Position updatePositionAfterAdoptingTextReplacement(const Position& position, CharacterData* node, unsigned offset, unsigned oldLength, unsigned newLength)
{
    if (!position.anchorNode() || position.anchorNode() != node || position.anchorType() != Position::PositionIsOffsetInAnchor)
        return position;

    // See: http://www.w3.org/TR/DOM-Level-2-Traversal-Range/ranges.html#Level-2-Range-Mutation
    ASSERT(position.offsetInContainerNode() >= 0);
    unsigned positionOffset = static_cast<unsigned>(position.offsetInContainerNode());
    // Replacing text can be viewed as a deletion followed by insertion.
    if (positionOffset >= offset && positionOffset <= offset + oldLength)
        positionOffset = offset;

    // Adjust the offset if the position is after the end of the deleted contents
    // (positionOffset > offset + oldLength) to avoid having a stale offset.
    if (positionOffset > offset + oldLength)
        positionOffset = positionOffset - oldLength + newLength;

    ASSERT_WITH_SECURITY_IMPLICATION(positionOffset <= node->length());
    // CharacterNode in VisibleSelection must be Text node, because Comment
    // and ProcessingInstruction node aren't visible.
    return Position(toText(node), positionOffset);
}

void FrameSelection::didUpdateCharacterData(CharacterData* node, unsigned offset, unsigned oldLength, unsigned newLength)
{
    // The fragment check is a performance optimization. See http://trac.webkit.org/changeset/30062.
    if (isNone() || !node || !node->inDocument())
        return;

    Position base = updatePositionAfterAdoptingTextReplacement(m_selection.base(), node, offset, oldLength, newLength);
    Position extent = updatePositionAfterAdoptingTextReplacement(m_selection.extent(), node, offset, oldLength, newLength);
    Position start = updatePositionAfterAdoptingTextReplacement(m_selection.start(), node, offset, oldLength, newLength);
    Position end = updatePositionAfterAdoptingTextReplacement(m_selection.end(), node, offset, oldLength, newLength);
    updateSelectionIfNeeded(base, extent, start, end);
}

static Position updatePostionAfterAdoptingTextNodesMerged(const Position& position, const Text& oldNode, unsigned offset)
{
    if (!position.anchorNode() || position.anchorType() != Position::PositionIsOffsetInAnchor)
        return position;

    ASSERT(position.offsetInContainerNode() >= 0);
    unsigned positionOffset = static_cast<unsigned>(position.offsetInContainerNode());

    if (position.anchorNode() == &oldNode)
        return Position(toText(oldNode.previousSibling()), positionOffset + offset);

    if (position.anchorNode() == oldNode.parentNode() && positionOffset == offset)
        return Position(toText(oldNode.previousSibling()), offset);

    return position;
}

void FrameSelection::didMergeTextNodes(const Text& oldNode, unsigned offset)
{
    if (isNone() || !oldNode.inDocument())
        return;
    Position base = updatePostionAfterAdoptingTextNodesMerged(m_selection.base(), oldNode, offset);
    Position extent = updatePostionAfterAdoptingTextNodesMerged(m_selection.extent(), oldNode, offset);
    Position start = updatePostionAfterAdoptingTextNodesMerged(m_selection.start(), oldNode, offset);
    Position end = updatePostionAfterAdoptingTextNodesMerged(m_selection.end(), oldNode, offset);
    updateSelectionIfNeeded(base, extent, start, end);
}

static Position updatePostionAfterAdoptingTextNodeSplit(const Position& position, const Text& oldNode)
{
    if (!position.anchorNode() || position.anchorNode() != &oldNode || position.anchorType() != Position::PositionIsOffsetInAnchor)
        return position;
    // See: http://www.w3.org/TR/DOM-Level-2-Traversal-Range/ranges.html#Level-2-Range-Mutation
    ASSERT(position.offsetInContainerNode() >= 0);
    unsigned positionOffset = static_cast<unsigned>(position.offsetInContainerNode());
    unsigned oldLength = oldNode.length();
    if (positionOffset <= oldLength)
        return position;
    return Position(toText(oldNode.nextSibling()), positionOffset - oldLength);
}

void FrameSelection::didSplitTextNode(const Text& oldNode)
{
    if (isNone() || !oldNode.inDocument())
        return;
    Position base = updatePostionAfterAdoptingTextNodeSplit(m_selection.base(), oldNode);
    Position extent = updatePostionAfterAdoptingTextNodeSplit(m_selection.extent(), oldNode);
    Position start = updatePostionAfterAdoptingTextNodeSplit(m_selection.start(), oldNode);
    Position end = updatePostionAfterAdoptingTextNodeSplit(m_selection.end(), oldNode);
    updateSelectionIfNeeded(base, extent, start, end);
}

void FrameSelection::updateSelectionIfNeeded(const Position& base, const Position& extent, const Position& start, const Position& end)
{
    if (base == m_selection.base() && extent == m_selection.extent() && start == m_selection.start() && end == m_selection.end())
        return;
    VisibleSelection newSelection;
    if (m_selection.isBaseFirst())
        newSelection.setWithoutValidation(start, end);
    else
        newSelection.setWithoutValidation(end, start);
    setSelection(newSelection, DoNotSetFocus);
}

TextDirection FrameSelection::directionOfEnclosingBlock()
{
    return blink::directionOfEnclosingBlock(m_selection.extent());
}

TextDirection FrameSelection::directionOfSelection()
{
    InlineBox* startBox = 0;
    InlineBox* endBox = 0;
    int unusedOffset;
    // Cache the VisiblePositions because visibleStart() and visibleEnd()
    // can cause layout, which has the potential to invalidate lineboxes.
    VisiblePosition startPosition = m_selection.visibleStart();
    VisiblePosition endPosition = m_selection.visibleEnd();
    if (startPosition.isNotNull())
        startPosition.getInlineBoxAndOffset(startBox, unusedOffset);
    if (endPosition.isNotNull())
        endPosition.getInlineBoxAndOffset(endBox, unusedOffset);
    if (startBox && endBox && startBox->direction() == endBox->direction())
        return startBox->direction();

    return directionOfEnclosingBlock();
}

void FrameSelection::didChangeFocus()
{
    // Hits in virtual/gpu/compositedscrolling/scrollbars/scrollbar-miss-mousemove-disabled.html
    DisableCompositingQueryAsserts disabler;
    updateAppearance();
}

void FrameSelection::willBeModified(EAlteration alter, SelectionDirection direction)
{
    if (alter != AlterationExtend)
        return;

    Position start = m_selection.start();
    Position end = m_selection.end();

    bool baseIsStart = true;

    if (m_selection.isDirectional()) {
        // Make base and extent match start and end so we extend the user-visible selection.
        // This only matters for cases where base and extend point to different positions than
        // start and end (e.g. after a double-click to select a word).
        if (m_selection.isBaseFirst())
            baseIsStart = true;
        else
            baseIsStart = false;
    } else {
        switch (direction) {
        case DirectionRight:
            if (directionOfSelection() == LTR)
                baseIsStart = true;
            else
                baseIsStart = false;
            break;
        case DirectionForward:
            baseIsStart = true;
            break;
        case DirectionLeft:
            if (directionOfSelection() == LTR)
                baseIsStart = false;
            else
                baseIsStart = true;
            break;
        case DirectionBackward:
            baseIsStart = false;
            break;
        }
    }
    if (baseIsStart) {
        m_selection.setBase(start);
        m_selection.setExtent(end);
    } else {
        m_selection.setBase(end);
        m_selection.setExtent(start);
    }
}

VisiblePosition FrameSelection::positionForPlatform(bool isGetStart) const
{
    // FIXME: VisibleSelection should be fixed to ensure as an invariant that
    // base/extent always point to the same nodes as start/end, but which points
    // to which depends on the value of isBaseFirst. Then this can be changed
    // to just return m_sel.extent().
    return m_selection.isBaseFirst() ? m_selection.visibleEnd() : m_selection.visibleStart();
}

VisiblePosition FrameSelection::startForPlatform() const
{
    return positionForPlatform(true);
}

VisiblePosition FrameSelection::endForPlatform() const
{
    return positionForPlatform(false);
}

VisiblePosition FrameSelection::nextWordPositionForPlatform(const VisiblePosition &originalPosition)
{
    VisiblePosition positionAfterCurrentWord = nextWordPosition(originalPosition);

    if (m_frame && m_frame->editor().behavior().shouldSkipSpaceWhenMovingRight()) {
        // In order to skip spaces when moving right, we advance one
        // word further and then move one word back. Given the
        // semantics of previousWordPosition() this will put us at the
        // beginning of the word following.
        VisiblePosition positionAfterSpacingAndFollowingWord = nextWordPosition(positionAfterCurrentWord);
        if (positionAfterSpacingAndFollowingWord.isNotNull() && positionAfterSpacingAndFollowingWord != positionAfterCurrentWord)
            positionAfterCurrentWord = previousWordPosition(positionAfterSpacingAndFollowingWord);

        bool movingBackwardsMovedPositionToStartOfCurrentWord = positionAfterCurrentWord == previousWordPosition(nextWordPosition(originalPosition));
        if (movingBackwardsMovedPositionToStartOfCurrentWord)
            positionAfterCurrentWord = positionAfterSpacingAndFollowingWord;
    }
    return positionAfterCurrentWord;
}

static void adjustPositionForUserSelectAll(VisiblePosition& pos, bool isForward)
{
    if (Node* rootUserSelectAll = Position::rootUserSelectAllForNode(pos.deepEquivalent().anchorNode()))
        pos = VisiblePosition(isForward ? positionAfterNode(rootUserSelectAll).downstream(CanCrossEditingBoundary) : positionBeforeNode(rootUserSelectAll).upstream(CanCrossEditingBoundary));
}

VisiblePosition FrameSelection::modifyExtendingRight(TextGranularity granularity)
{
    VisiblePosition pos(m_selection.extent(), m_selection.affinity());

    // The difference between modifyExtendingRight and modifyExtendingForward is:
    // modifyExtendingForward always extends forward logically.
    // modifyExtendingRight behaves the same as modifyExtendingForward except for extending character or word,
    // it extends forward logically if the enclosing block is LTR direction,
    // but it extends backward logically if the enclosing block is RTL direction.
    switch (granularity) {
    case CharacterGranularity:
        if (directionOfEnclosingBlock() == LTR)
            pos = pos.next(CanSkipOverEditingBoundary);
        else
            pos = pos.previous(CanSkipOverEditingBoundary);
        break;
    case WordGranularity:
        if (directionOfEnclosingBlock() == LTR)
            pos = nextWordPositionForPlatform(pos);
        else
            pos = previousWordPosition(pos);
        break;
    case LineBoundary:
        if (directionOfEnclosingBlock() == LTR)
            pos = modifyExtendingForward(granularity);
        else
            pos = modifyExtendingBackward(granularity);
        break;
    case SentenceGranularity:
    case LineGranularity:
    case ParagraphGranularity:
    case SentenceBoundary:
    case ParagraphBoundary:
    case DocumentBoundary:
        // FIXME: implement all of the above?
        pos = modifyExtendingForward(granularity);
        break;
    }
    adjustPositionForUserSelectAll(pos, directionOfEnclosingBlock() == LTR);
    return pos;
}

VisiblePosition FrameSelection::modifyExtendingForward(TextGranularity granularity)
{
    VisiblePosition pos(m_selection.extent(), m_selection.affinity());
    switch (granularity) {
    case CharacterGranularity:
        pos = pos.next(CanSkipOverEditingBoundary);
        break;
    case WordGranularity:
        pos = nextWordPositionForPlatform(pos);
        break;
    case SentenceGranularity:
        pos = nextSentencePosition(pos);
        break;
    case LineGranularity:
        pos = nextLinePosition(pos, lineDirectionPointForBlockDirectionNavigation(EXTENT));
        break;
    case ParagraphGranularity:
        pos = nextParagraphPosition(pos, lineDirectionPointForBlockDirectionNavigation(EXTENT));
        break;
    case SentenceBoundary:
        pos = endOfSentence(endForPlatform());
        break;
    case LineBoundary:
        pos = logicalEndOfLine(endForPlatform());
        break;
    case ParagraphBoundary:
        pos = endOfParagraph(endForPlatform());
        break;
    case DocumentBoundary:
        pos = endForPlatform();
        if (isEditablePosition(pos.deepEquivalent()))
            pos = endOfEditableContent(pos);
        else
            pos = endOfDocument(pos);
        break;
    }
    adjustPositionForUserSelectAll(pos, directionOfEnclosingBlock() == LTR);
    return pos;
}

VisiblePosition FrameSelection::modifyMovingRight(TextGranularity granularity)
{
    VisiblePosition pos;
    switch (granularity) {
    case CharacterGranularity:
        if (isRange()) {
            if (directionOfSelection() == LTR)
                pos = VisiblePosition(m_selection.end(), m_selection.affinity());
            else
                pos = VisiblePosition(m_selection.start(), m_selection.affinity());
        } else
            pos = VisiblePosition(m_selection.extent(), m_selection.affinity()).right(true);
        break;
    case WordGranularity: {
        bool skipsSpaceWhenMovingRight = m_frame && m_frame->editor().behavior().shouldSkipSpaceWhenMovingRight();
        pos = rightWordPosition(VisiblePosition(m_selection.extent(), m_selection.affinity()), skipsSpaceWhenMovingRight);
        break;
    }
    case SentenceGranularity:
    case LineGranularity:
    case ParagraphGranularity:
    case SentenceBoundary:
    case ParagraphBoundary:
    case DocumentBoundary:
        // FIXME: Implement all of the above.
        pos = modifyMovingForward(granularity);
        break;
    case LineBoundary:
        pos = rightBoundaryOfLine(startForPlatform(), directionOfEnclosingBlock());
        break;
    }
    return pos;
}

VisiblePosition FrameSelection::modifyMovingForward(TextGranularity granularity)
{
    VisiblePosition pos;
    // FIXME: Stay in editable content for the less common granularities.
    switch (granularity) {
    case CharacterGranularity:
        if (isRange())
            pos = VisiblePosition(m_selection.end(), m_selection.affinity());
        else
            pos = VisiblePosition(m_selection.extent(), m_selection.affinity()).next(CanSkipOverEditingBoundary);
        break;
    case WordGranularity:
        pos = nextWordPositionForPlatform(VisiblePosition(m_selection.extent(), m_selection.affinity()));
        break;
    case SentenceGranularity:
        pos = nextSentencePosition(VisiblePosition(m_selection.extent(), m_selection.affinity()));
        break;
    case LineGranularity: {
        // down-arrowing from a range selection that ends at the start of a line needs
        // to leave the selection at that line start (no need to call nextLinePosition!)
        pos = endForPlatform();
        if (!isRange() || !isStartOfLine(pos))
            pos = nextLinePosition(pos, lineDirectionPointForBlockDirectionNavigation(START));
        break;
    }
    case ParagraphGranularity:
        pos = nextParagraphPosition(endForPlatform(), lineDirectionPointForBlockDirectionNavigation(START));
        break;
    case SentenceBoundary:
        pos = endOfSentence(endForPlatform());
        break;
    case LineBoundary:
        pos = logicalEndOfLine(endForPlatform());
        break;
    case ParagraphBoundary:
        pos = endOfParagraph(endForPlatform());
        break;
    case DocumentBoundary:
        pos = endForPlatform();
        if (isEditablePosition(pos.deepEquivalent()))
            pos = endOfEditableContent(pos);
        else
            pos = endOfDocument(pos);
        break;
    }
    return pos;
}

VisiblePosition FrameSelection::modifyExtendingLeft(TextGranularity granularity)
{
    VisiblePosition pos(m_selection.extent(), m_selection.affinity());

    // The difference between modifyExtendingLeft and modifyExtendingBackward is:
    // modifyExtendingBackward always extends backward logically.
    // modifyExtendingLeft behaves the same as modifyExtendingBackward except for extending character or word,
    // it extends backward logically if the enclosing block is LTR direction,
    // but it extends forward logically if the enclosing block is RTL direction.
    switch (granularity) {
    case CharacterGranularity:
        if (directionOfEnclosingBlock() == LTR)
            pos = pos.previous(CanSkipOverEditingBoundary);
        else
            pos = pos.next(CanSkipOverEditingBoundary);
        break;
    case WordGranularity:
        if (directionOfEnclosingBlock() == LTR)
            pos = previousWordPosition(pos);
        else
            pos = nextWordPositionForPlatform(pos);
        break;
    case LineBoundary:
        if (directionOfEnclosingBlock() == LTR)
            pos = modifyExtendingBackward(granularity);
        else
            pos = modifyExtendingForward(granularity);
        break;
    case SentenceGranularity:
    case LineGranularity:
    case ParagraphGranularity:
    case SentenceBoundary:
    case ParagraphBoundary:
    case DocumentBoundary:
        pos = modifyExtendingBackward(granularity);
        break;
    }
    adjustPositionForUserSelectAll(pos, !(directionOfEnclosingBlock() == LTR));
    return pos;
}

VisiblePosition FrameSelection::modifyExtendingBackward(TextGranularity granularity)
{
    VisiblePosition pos(m_selection.extent(), m_selection.affinity());

    // Extending a selection backward by word or character from just after a table selects
    // the table.  This "makes sense" from the user perspective, esp. when deleting.
    // It was done here instead of in VisiblePosition because we want VPs to iterate
    // over everything.
    switch (granularity) {
    case CharacterGranularity:
        pos = pos.previous(CanSkipOverEditingBoundary);
        break;
    case WordGranularity:
        pos = previousWordPosition(pos);
        break;
    case SentenceGranularity:
        pos = previousSentencePosition(pos);
        break;
    case LineGranularity:
        pos = previousLinePosition(pos, lineDirectionPointForBlockDirectionNavigation(EXTENT));
        break;
    case ParagraphGranularity:
        pos = previousParagraphPosition(pos, lineDirectionPointForBlockDirectionNavigation(EXTENT));
        break;
    case SentenceBoundary:
        pos = startOfSentence(startForPlatform());
        break;
    case LineBoundary:
        pos = logicalStartOfLine(startForPlatform());
        break;
    case ParagraphBoundary:
        pos = startOfParagraph(startForPlatform());
        break;
    case DocumentBoundary:
        pos = startForPlatform();
        if (isEditablePosition(pos.deepEquivalent()))
            pos = startOfEditableContent(pos);
        else
            pos = startOfDocument(pos);
        break;
    }
    adjustPositionForUserSelectAll(pos, !(directionOfEnclosingBlock() == LTR));
    return pos;
}

VisiblePosition FrameSelection::modifyMovingLeft(TextGranularity granularity)
{
    VisiblePosition pos;
    switch (granularity) {
    case CharacterGranularity:
        if (isRange())
            if (directionOfSelection() == LTR)
                pos = VisiblePosition(m_selection.start(), m_selection.affinity());
            else
                pos = VisiblePosition(m_selection.end(), m_selection.affinity());
        else
            pos = VisiblePosition(m_selection.extent(), m_selection.affinity()).left(true);
        break;
    case WordGranularity: {
        bool skipsSpaceWhenMovingRight = m_frame && m_frame->editor().behavior().shouldSkipSpaceWhenMovingRight();
        pos = leftWordPosition(VisiblePosition(m_selection.extent(), m_selection.affinity()), skipsSpaceWhenMovingRight);
        break;
    }
    case SentenceGranularity:
    case LineGranularity:
    case ParagraphGranularity:
    case SentenceBoundary:
    case ParagraphBoundary:
    case DocumentBoundary:
        // FIXME: Implement all of the above.
        pos = modifyMovingBackward(granularity);
        break;
    case LineBoundary:
        pos = leftBoundaryOfLine(startForPlatform(), directionOfEnclosingBlock());
        break;
    }
    return pos;
}

VisiblePosition FrameSelection::modifyMovingBackward(TextGranularity granularity)
{
    VisiblePosition pos;
    switch (granularity) {
    case CharacterGranularity:
        if (isRange())
            pos = VisiblePosition(m_selection.start(), m_selection.affinity());
        else
            pos = VisiblePosition(m_selection.extent(), m_selection.affinity()).previous(CanSkipOverEditingBoundary);
        break;
    case WordGranularity:
        pos = previousWordPosition(VisiblePosition(m_selection.extent(), m_selection.affinity()));
        break;
    case SentenceGranularity:
        pos = previousSentencePosition(VisiblePosition(m_selection.extent(), m_selection.affinity()));
        break;
    case LineGranularity:
        pos = previousLinePosition(startForPlatform(), lineDirectionPointForBlockDirectionNavigation(START));
        break;
    case ParagraphGranularity:
        pos = previousParagraphPosition(startForPlatform(), lineDirectionPointForBlockDirectionNavigation(START));
        break;
    case SentenceBoundary:
        pos = startOfSentence(startForPlatform());
        break;
    case LineBoundary:
        pos = logicalStartOfLine(startForPlatform());
        break;
    case ParagraphBoundary:
        pos = startOfParagraph(startForPlatform());
        break;
    case DocumentBoundary:
        pos = startForPlatform();
        if (isEditablePosition(pos.deepEquivalent()))
            pos = startOfEditableContent(pos);
        else
            pos = startOfDocument(pos);
        break;
    }
    return pos;
}

static bool isBoundary(TextGranularity granularity)
{
    return granularity == LineBoundary || granularity == ParagraphBoundary || granularity == DocumentBoundary;
}

bool FrameSelection::modify(EAlteration alter, SelectionDirection direction, TextGranularity granularity, EUserTriggered userTriggered)
{
    if (userTriggered == UserTriggered) {
        OwnPtr<FrameSelection> trialFrameSelection = FrameSelection::create();
        trialFrameSelection->setSelection(m_selection);
        trialFrameSelection->modify(alter, direction, granularity, NotUserTriggered);

        if (trialFrameSelection->selection().isRange() && m_selection.isCaret() && !dispatchSelectStart())
            return false;
    }

    willBeModified(alter, direction);

    VisiblePosition originalStartPosition = m_selection.visibleStart();
    VisiblePosition position;
    switch (direction) {
    case DirectionRight:
        if (alter == AlterationMove)
            position = modifyMovingRight(granularity);
        else
            position = modifyExtendingRight(granularity);
        break;
    case DirectionForward:
        if (alter == AlterationExtend)
            position = modifyExtendingForward(granularity);
        else
            position = modifyMovingForward(granularity);
        break;
    case DirectionLeft:
        if (alter == AlterationMove)
            position = modifyMovingLeft(granularity);
        else
            position = modifyExtendingLeft(granularity);
        break;
    case DirectionBackward:
        if (alter == AlterationExtend)
            position = modifyExtendingBackward(granularity);
        else
            position = modifyMovingBackward(granularity);
        break;
    }

    if (position.isNull())
        return false;

    // Some of the above operations set an xPosForVerticalArrowNavigation.
    // Setting a selection will clear it, so save it to possibly restore later.
    // Note: the START position type is arbitrary because it is unused, it would be
    // the requested position type if there were no xPosForVerticalArrowNavigation set.
    LayoutUnit x = lineDirectionPointForBlockDirectionNavigation(START);
    m_selection.setIsDirectional(shouldAlwaysUseDirectionalSelection(m_frame) || alter == AlterationExtend);

    switch (alter) {
    case AlterationMove:
        moveTo(position, userTriggered);
        break;
    case AlterationExtend:

        if (!m_selection.isCaret()
            && (granularity == WordGranularity || granularity == ParagraphGranularity || granularity == LineGranularity)
            && m_frame && !m_frame->editor().behavior().shouldExtendSelectionByWordOrLineAcrossCaret()) {
            // Don't let the selection go across the base position directly. Needed to match mac
            // behavior when, for instance, word-selecting backwards starting with the caret in
            // the middle of a word and then word-selecting forward, leaving the caret in the
            // same place where it was, instead of directly selecting to the end of the word.
            VisibleSelection newSelection = m_selection;
            newSelection.setExtent(position);
            if (m_selection.isBaseFirst() != newSelection.isBaseFirst())
                position = m_selection.visibleBase();
        }

        // Standard Mac behavior when extending to a boundary is grow the selection rather than leaving the
        // base in place and moving the extent. Matches NSTextView.
        if (!m_frame || !m_frame->editor().behavior().shouldAlwaysGrowSelectionWhenExtendingToBoundary() || m_selection.isCaret() || !isBoundary(granularity))
            setExtent(position, userTriggered);
        else {
            TextDirection textDirection = directionOfEnclosingBlock();
            if (direction == DirectionForward || (textDirection == LTR && direction == DirectionRight) || (textDirection == RTL && direction == DirectionLeft))
                setEnd(position, userTriggered);
            else
                setStart(position, userTriggered);
        }
        break;
    }

    if (granularity == LineGranularity || granularity == ParagraphGranularity)
        m_xPosForVerticalArrowNavigation = x;

    if (userTriggered == UserTriggered)
        m_granularity = CharacterGranularity;

    setCaretRectNeedsUpdate();

    return true;
}

// FIXME: Maybe baseline would be better?
static bool absoluteCaretY(const VisiblePosition &c, int &y)
{
    IntRect rect = c.absoluteCaretBounds();
    if (rect.isEmpty())
        return false;
    y = rect.y() + rect.height() / 2;
    return true;
}

bool FrameSelection::modify(EAlteration alter, unsigned verticalDistance, VerticalDirection direction, EUserTriggered userTriggered, CursorAlignOnScroll align)
{
    if (!verticalDistance)
        return false;

    if (userTriggered == UserTriggered) {
        OwnPtr<FrameSelection> trialFrameSelection = FrameSelection::create();
        trialFrameSelection->setSelection(m_selection);
        trialFrameSelection->modify(alter, verticalDistance, direction, NotUserTriggered);
    }

    willBeModified(alter, direction == DirectionUp ? DirectionBackward : DirectionForward);

    VisiblePosition pos;
    LayoutUnit xPos = 0;
    switch (alter) {
    case AlterationMove:
        pos = VisiblePosition(direction == DirectionUp ? m_selection.start() : m_selection.end(), m_selection.affinity());
        xPos = lineDirectionPointForBlockDirectionNavigation(direction == DirectionUp ? START : END);
        m_selection.setAffinity(direction == DirectionUp ? UPSTREAM : DOWNSTREAM);
        break;
    case AlterationExtend:
        pos = VisiblePosition(m_selection.extent(), m_selection.affinity());
        xPos = lineDirectionPointForBlockDirectionNavigation(EXTENT);
        m_selection.setAffinity(DOWNSTREAM);
        break;
    }

    int startY;
    if (!absoluteCaretY(pos, startY))
        return false;
    if (direction == DirectionUp)
        startY = -startY;
    int lastY = startY;

    VisiblePosition result;
    VisiblePosition next;
    for (VisiblePosition p = pos; ; p = next) {
        if (direction == DirectionUp)
            next = previousLinePosition(p, xPos);
        else
            next = nextLinePosition(p, xPos);

        if (next.isNull() || next == p)
            break;
        int nextY;
        if (!absoluteCaretY(next, nextY))
            break;
        if (direction == DirectionUp)
            nextY = -nextY;
        if (nextY - startY > static_cast<int>(verticalDistance))
            break;
        if (nextY >= lastY) {
            lastY = nextY;
            result = next;
        }
    }

    if (result.isNull())
        return false;

    switch (alter) {
    case AlterationMove:
        moveTo(result, userTriggered, align);
        break;
    case AlterationExtend:
        setExtent(result, userTriggered);
        break;
    }

    if (userTriggered == UserTriggered)
        m_granularity = CharacterGranularity;

    m_selection.setIsDirectional(shouldAlwaysUseDirectionalSelection(m_frame) || alter == AlterationExtend);

    return true;
}

LayoutUnit FrameSelection::lineDirectionPointForBlockDirectionNavigation(EPositionType type)
{
    LayoutUnit x = 0;

    if (isNone())
        return x;

    Position pos;
    switch (type) {
    case START:
        pos = m_selection.start();
        break;
    case END:
        pos = m_selection.end();
        break;
    case BASE:
        pos = m_selection.base();
        break;
    case EXTENT:
        pos = m_selection.extent();
        break;
    }

    LocalFrame* frame = pos.document()->frame();
    if (!frame)
        return x;

    if (m_xPosForVerticalArrowNavigation == NoXPosForVerticalArrowNavigation()) {
        VisiblePosition visiblePosition(pos, m_selection.affinity());
        // VisiblePosition creation can fail here if a node containing the selection becomes visibility:hidden
        // after the selection is created and before this function is called.
        x = visiblePosition.isNotNull() ? visiblePosition.lineDirectionPointForBlockDirectionNavigation() : 0;
        m_xPosForVerticalArrowNavigation = x;
    } else
        x = m_xPosForVerticalArrowNavigation;

    return x;
}

void FrameSelection::clear()
{
    m_granularity = CharacterGranularity;
    setSelection(VisibleSelection());
}

void FrameSelection::prepareForDestruction()
{
    m_granularity = CharacterGranularity;

    m_caretBlinkTimer.stop();

    RenderView* view = m_frame->contentRenderer();
    if (view)
        view->clearSelection();

    setSelection(VisibleSelection(), CloseTyping | ClearTypingStyle | DoNotUpdateAppearance);
    m_previousCaretNode.clear();
}

void FrameSelection::setStart(const VisiblePosition &pos, EUserTriggered trigger)
{
    if (m_selection.isBaseFirst())
        setBase(pos, trigger);
    else
        setExtent(pos, trigger);
}

void FrameSelection::setEnd(const VisiblePosition &pos, EUserTriggered trigger)
{
    if (m_selection.isBaseFirst())
        setExtent(pos, trigger);
    else
        setBase(pos, trigger);
}

void FrameSelection::setBase(const VisiblePosition &pos, EUserTriggered userTriggered)
{
    const bool selectionHasDirection = true;
    setSelection(VisibleSelection(pos.deepEquivalent(), m_selection.extent(), pos.affinity(), selectionHasDirection), CloseTyping | ClearTypingStyle | userTriggered);
}

void FrameSelection::setExtent(const VisiblePosition &pos, EUserTriggered userTriggered)
{
    const bool selectionHasDirection = true;
    setSelection(VisibleSelection(m_selection.base(), pos.deepEquivalent(), pos.affinity(), selectionHasDirection), CloseTyping | ClearTypingStyle | userTriggered);
}

RenderBlock* FrameSelection::caretRenderer() const
{
    return CaretBase::caretRenderer(m_selection.start().deprecatedNode());
}

static bool isNonOrphanedCaret(const VisibleSelection& selection)
{
    return selection.isCaret() && !selection.start().isOrphan() && !selection.end().isOrphan();
}

IntRect FrameSelection::absoluteCaretBounds()
{
    ASSERT(m_frame->document()->lifecycle().state() != DocumentLifecycle::InPaintInvalidation);
    m_frame->document()->updateLayoutIgnorePendingStylesheets();
    if (!isNonOrphanedCaret(m_selection)) {
        clearCaretRect();
    } else {
        updateCaretRect(m_frame->document(), VisiblePosition(m_selection.start(), m_selection.affinity()));
    }
    return absoluteBoundsForLocalRect(m_selection.start().deprecatedNode(), localCaretRectWithoutUpdate());
}

static LayoutRect localCaretRect(const VisibleSelection& m_selection, const PositionWithAffinity& caretPosition, RenderObject*& renderer)
{
    renderer = nullptr;
    if (!isNonOrphanedCaret(m_selection))
        return LayoutRect();

    return localCaretRectOfPosition(caretPosition, renderer);
}

void FrameSelection::invalidateCaretRect()
{
    if (!m_caretRectDirty)
        return;
    m_caretRectDirty = false;

    RenderObject* renderer = nullptr;
    LayoutRect newRect = localCaretRect(m_selection, PositionWithAffinity(m_selection.start(), m_selection.affinity()), renderer);
    Node* newNode = renderer ? renderer->node() : nullptr;

    if (!m_caretBlinkTimer.isActive() && newNode == m_previousCaretNode && newRect == m_previousCaretRect)
        return;

    if (m_previousCaretNode && m_previousCaretNode->isContentEditable())
        invalidateLocalCaretRect(m_previousCaretNode.get(), m_previousCaretRect);
    if (newNode && newNode->isContentEditable())
        invalidateLocalCaretRect(newNode, newRect);

    m_previousCaretNode = newNode;
    m_previousCaretRect = newRect;
}

void FrameSelection::paintCaret(GraphicsContext* context, const LayoutPoint& paintOffset, const LayoutRect& clipRect)
{
    if (m_selection.isCaret() && m_shouldPaintCaret) {
        updateCaretRect(m_frame->document(), PositionWithAffinity(m_selection.start(), m_selection.affinity()));
        CaretBase::paintCaret(m_selection.start().deprecatedNode(), context, paintOffset, clipRect);
    }
}

bool FrameSelection::contains(const LayoutPoint& point)
{
    Document* document = m_frame->document();

    // Treat a collapsed selection like no selection.
    if (!isRange())
        return false;
    if (!document->renderView())
        return false;

    HitTestRequest request(HitTestRequest::ReadOnly | HitTestRequest::Active);
    HitTestResult result(point);
    document->renderView()->hitTest(request, result);
    Node* innerNode = result.innerNode();
    if (!innerNode || !innerNode->renderer())
        return false;

    VisiblePosition visiblePos(innerNode->renderer()->positionForPoint(result.localPoint()));
    if (visiblePos.isNull())
        return false;

    if (m_selection.visibleStart().isNull() || m_selection.visibleEnd().isNull())
        return false;

    Position start(m_selection.visibleStart().deepEquivalent());
    Position end(m_selection.visibleEnd().deepEquivalent());
    Position p(visiblePos.deepEquivalent());

    return comparePositions(start, p) <= 0 && comparePositions(p, end) <= 0;
}

// Workaround for the fact that it's hard to delete a frame.
// Call this after doing user-triggered selections to make it easy to delete the frame you entirely selected.
// Can't do this implicitly as part of every setSelection call because in some contexts it might not be good
// for the focus to move to another frame. So instead we call it from places where we are selecting with the
// mouse or the keyboard after setting the selection.
void FrameSelection::selectFrameElementInParentIfFullySelected()
{

}

void FrameSelection::selectAll()
{
    Document* document = m_frame->document();

    RefPtr<Node> root = nullptr;
    Node* selectStartTarget = 0;
    if (isContentEditable()) {
        root = highestEditableRoot(m_selection.start());
        if (Node* shadowRoot = m_selection.nonBoundaryShadowTreeRootNode())
            selectStartTarget = shadowRoot->shadowHost();
        else
            selectStartTarget = root.get();
    } else {
        root = m_selection.nonBoundaryShadowTreeRootNode();
        if (root)
            selectStartTarget = root->shadowHost();
        else {
            root = document->documentElement();
            selectStartTarget = document->documentElement();
        }
    }
    if (!root)
        return;

    if (selectStartTarget && !selectStartTarget->dispatchEvent(Event::createCancelableBubble(EventTypeNames::selectstart)))
        return;

    VisibleSelection newSelection(VisibleSelection::selectionFromContentsOfNode(root.get()));
    setSelection(newSelection);
    notifyRendererOfSelectionChange(UserTriggered);
}

bool FrameSelection::setSelectedRange(Range* range, EAffinity affinity, DirectoinalOption directional, SetSelectionOptions options)
{
    if (!range || !range->startContainer() || !range->endContainer())
        return false;
    ASSERT(range->startContainer()->document() == range->endContainer()->document());

    // Non-collapsed ranges are not allowed to start at the end of a line that is wrapped,
    // they start at the beginning of the next line instead
    m_logicalRange = nullptr;
    stopObservingVisibleSelectionChangeIfNecessary();

    VisibleSelection newSelection(range, affinity, directional == Directional);
    setSelection(newSelection, options);

    m_logicalRange = range->cloneRange();
    startObservingVisibleSelectionChange();

    return true;
}

PassRefPtr<Range> FrameSelection::firstRange() const
{
    if (m_logicalRange)
        return m_logicalRange->cloneRange();
    return m_selection.firstRange();
}

bool FrameSelection::isInPasswordField() const
{
    return false;
}

void FrameSelection::notifyAccessibilityForSelectionChange()
{
}

void FrameSelection::notifyCompositorForSelectionChange()
{
    if (!RuntimeEnabledFeatures::compositedSelectionUpdatesEnabled())
        return;

    scheduleVisualUpdate();
}

void FrameSelection::focusedOrActiveStateChanged()
{
    bool activeAndFocused = isFocusedAndActive();

    RefPtr<Document> document = m_frame->document();
    document->updateRenderTreeIfNeeded();

    // Because RenderObject::selectionBackgroundColor() and
    // RenderObject::selectionForegroundColor() check if the frame is active,
    // we have to update places those colors were painted.
    if (RenderView* view = document->renderView())
        view->invalidatePaintForSelection();

    // Caret appears in the active frame.
    if (activeAndFocused)
        setSelectionFromNone();
    else
        m_frame->spellChecker().spellCheckAfterBlur();
    setCaretVisibility(activeAndFocused ? Visible : Hidden);

    // Update for caps lock state
    m_frame->eventHandler().capsLockStateMayHaveChanged();

    // We may have lost active status even though the focusElement hasn't changed
    // give the element a chance to recalc style if its affected by focus.
    if (Element* element = document->focusedElement())
        element->focusStateChanged();
}

void FrameSelection::pageActivationChanged()
{
    focusedOrActiveStateChanged();
}

void FrameSelection::setFocused(bool flag)
{
    if (m_focused == flag)
        return;
    m_focused = flag;

    focusedOrActiveStateChanged();
}

bool FrameSelection::isFocusedAndActive() const
{
    return m_focused && m_frame->page() && m_frame->page()->focusController().isActive();
}

inline static bool shouldStopBlinkingDueToTypingCommand(LocalFrame* frame)
{
    return frame->editor().lastEditCommand() && frame->editor().lastEditCommand()->shouldStopCaretBlinking();
}

void FrameSelection::updateAppearance(ResetCaretBlinkOption option)
{
    // Paint a block cursor instead of a caret in overtype mode unless the caret is at the end of a line (in this case
    // the FrameSelection will paint a blinking caret as usual).
    bool paintBlockCursor = m_shouldShowBlockCursor && m_selection.isCaret() && !isLogicalEndOfLine(m_selection.visibleEnd());

    bool shouldBlink = !paintBlockCursor && shouldBlinkCaret();

    bool willNeedCaretRectUpdate = false;

    // If the caret moved, stop the blink timer so we can restart with a
    // black caret in the new location.
    if (option == ResetCaretBlink || !shouldBlink || shouldStopBlinkingDueToTypingCommand(m_frame)) {
        m_caretBlinkTimer.stop();

        m_shouldPaintCaret = false;
        willNeedCaretRectUpdate = true;
    }

    // Start blinking with a black caret. Be sure not to restart if we're
    // already blinking in the right location.
    if (shouldBlink && !m_caretBlinkTimer.isActive()) {
        if (double blinkInterval = RenderTheme::theme().caretBlinkInterval())
            m_caretBlinkTimer.startRepeating(blinkInterval, FROM_HERE);

        m_shouldPaintCaret = true;
        willNeedCaretRectUpdate = true;
    }

    if (willNeedCaretRectUpdate)
        setCaretRectNeedsUpdate();

    RenderView* view = m_frame->contentRenderer();
    if (!view)
        return;

    // Construct a new VisibleSolution, since m_selection is not necessarily valid, and the following steps
    // assume a valid selection. See <https://bugs.webkit.org/show_bug.cgi?id=69563> and <rdar://problem/10232866>.

    VisibleSelection selection;
    VisiblePosition endVisiblePosition = paintBlockCursor ? modifyExtendingForward(CharacterGranularity) : m_selection.visibleEnd();
    selection = VisibleSelection(m_selection.visibleStart(), endVisiblePosition);

    if (!selection.isRange()) {
        view->clearSelection();
        return;
    }

    m_frame->document()->updateLayoutIgnorePendingStylesheets();

    // Use the rightmost candidate for the start of the selection, and the leftmost candidate for the end of the selection.
    // Example: foo <a>bar</a>.  Imagine that a line wrap occurs after 'foo', and that 'bar' is selected.   If we pass [foo, 3]
    // as the start of the selection, the selection painting code will think that content on the line containing 'foo' is selected
    // and will fill the gap before 'bar'.
    Position startPos = selection.start();
    Position candidate = startPos.downstream();
    if (candidate.isCandidate())
        startPos = candidate;
    Position endPos = selection.end();
    candidate = endPos.upstream();
    if (candidate.isCandidate())
        endPos = candidate;

    // We can get into a state where the selection endpoints map to the same VisiblePosition when a selection is deleted
    // because we don't yet notify the FrameSelection of text removal.
    if (startPos.isNotNull() && endPos.isNotNull() && selection.visibleStart() != selection.visibleEnd()) {
        RenderObject* startRenderer = startPos.deprecatedNode()->renderer();
        RenderObject* endRenderer = endPos.deprecatedNode()->renderer();
        if (startRenderer->view() == view && endRenderer->view() == view)
            view->setSelection(startRenderer, startPos.deprecatedEditingOffset(), endRenderer, endPos.deprecatedEditingOffset());
    }
}

void FrameSelection::setCaretVisibility(CaretVisibility visibility)
{
    if (caretVisibility() == visibility)
        return;

    CaretBase::setCaretVisibility(visibility);

    updateAppearance();
}

bool FrameSelection::shouldBlinkCaret() const
{
    if (!caretIsVisible() || !isCaret())
        return false;

    Element* root = rootEditableElement();
    if (!root)
        return false;

    Element* focusedElement = root->document().focusedElement();
    if (!focusedElement)
        return false;

    return focusedElement->containsIncludingShadowDOM(m_selection.start().anchorNode());
}

void FrameSelection::caretBlinkTimerFired(Timer<FrameSelection>*)
{
    ASSERT(caretIsVisible());
    ASSERT(isCaret());
    if (isCaretBlinkingSuspended() && m_shouldPaintCaret)
        return;
    m_shouldPaintCaret = !m_shouldPaintCaret;
    setCaretRectNeedsUpdate();
}

void FrameSelection::notifyRendererOfSelectionChange(EUserTriggered userTriggered)
{
}

// Helper function that tells whether a particular node is an element that has an entire
// LocalFrame and FrameView, a <frame>, <iframe>, or <object>.
static bool isFrameElement(const Node* n)
{
    // FIXME(sky): Remove this.
    return false;
}

void FrameSelection::setFocusedNodeIfNeeded()
{
    if (isNone() || !isFocused())
        return;

    if (Element* target = rootEditableElement()) {
        // Walk up the DOM tree to search for a node to focus.
        while (target) {
            // We don't want to set focus on a subframe when selecting in a parent frame,
            // so add the !isFrameElement check here. There's probably a better way to make this
            // work in the long term, but this is the safest fix at this time.
            if (target->isMouseFocusable() && !isFrameElement(target)) {
                m_frame->page()->focusController().setFocusedElement(target, m_frame);
                return;
            }
            target = target->parentOrShadowHostElement();
        }
        m_frame->document()->setFocusedElement(nullptr);
    }
}

String FrameSelection::selectedText() const
{
    // We remove '\0' characters because they are not visibly rendered to the user.
    return plainText(toNormalizedRange().get()).replace(0, "");
}

FloatRect FrameSelection::bounds(bool clipToVisibleContent) const
{
    m_frame->document()->updateRenderTreeIfNeeded();

    FrameView* view = m_frame->view();
    RenderView* renderView = m_frame->contentRenderer();

    if (!view || !renderView)
        return FloatRect();

    LayoutRect selectionRect = renderView->selectionBounds(clipToVisibleContent);
    return clipToVisibleContent ? intersection(selectionRect, view->visibleContentRect()) : selectionRect;
}

void FrameSelection::revealSelection(const ScrollAlignment& alignment, RevealExtentOption revealExtentOption)
{
    LayoutRect rect;

    switch (selectionType()) {
    case NoSelection:
        return;
    case CaretSelection:
        rect = absoluteCaretBounds();
        break;
    case RangeSelection:
        rect = revealExtentOption == RevealExtent ? VisiblePosition(extent()).absoluteCaretBounds() : enclosingIntRect(bounds(false));
        break;
    }

    Position start = this->start();
    ASSERT(start.deprecatedNode());
    if (start.deprecatedNode() && start.deprecatedNode()->renderer()) {
        // FIXME: This code only handles scrolling the startContainer's layer, but
        // the selection rect could intersect more than just that.
        // See <rdar://problem/4799899>.
        if (start.deprecatedNode()->renderer()->scrollRectToVisible(rect, alignment, alignment))
            updateAppearance();
    }
}

void FrameSelection::setSelectionFromNone()
{
    // Put a caret inside the body if the entire frame is editable (either the
    // entire WebView is editable or designMode is on for this document).

    // FIXME(sky): We have no body.
}

bool FrameSelection::dispatchSelectStart()
{
    Node* selectStartTarget = m_selection.extent().containerNode();
    if (!selectStartTarget)
        return true;

    return selectStartTarget->dispatchEvent(Event::createCancelableBubble(EventTypeNames::selectstart));
}

void FrameSelection::setShouldShowBlockCursor(bool shouldShowBlockCursor)
{
    m_shouldShowBlockCursor = shouldShowBlockCursor;

    m_frame->document()->updateLayoutIgnorePendingStylesheets();

    updateAppearance();
}

void FrameSelection::didChangeVisibleSelection()
{
    ASSERT(m_observingVisibleSelection);
    // Invalidate the logical range when the underlying VisibleSelection has changed.
    m_logicalRange = nullptr;
    m_selection.clearChangeObserver();
    m_observingVisibleSelection = false;
}

VisibleSelection FrameSelection::validateSelection(const VisibleSelection& selection)
{
    if (!m_frame || selection.isNone())
        return selection;

    Position base = selection.base();
    Position extent = selection.extent();
    bool isBaseValid = base.document() == m_frame->document();
    bool isExtentValid = extent.document() == m_frame->document();

    if (isBaseValid && isExtentValid)
        return selection;

    VisibleSelection newSelection;
    if (isBaseValid) {
        newSelection.setWithoutValidation(base, base);
    } else if (isExtentValid) {
        newSelection.setWithoutValidation(extent, extent);
    }
    return newSelection;
}

void FrameSelection::startObservingVisibleSelectionChange()
{
    ASSERT(!m_observingVisibleSelection);
    m_selection.setChangeObserver(*this);
    m_observingVisibleSelection = true;
}

void FrameSelection::stopObservingVisibleSelectionChangeIfNecessary()
{
    if (m_observingVisibleSelection) {
        m_selection.clearChangeObserver();
        m_observingVisibleSelection = false;
    }
}

#ifndef NDEBUG

void FrameSelection::formatForDebugger(char* buffer, unsigned length) const
{
    m_selection.formatForDebugger(buffer, length);
}

void FrameSelection::showTreeForThis() const
{
    m_selection.showTreeForThis();
}

#endif

void FrameSelection::setCaretRectNeedsUpdate()
{
    m_caretRectDirty = true;

    scheduleVisualUpdate();
}

void FrameSelection::scheduleVisualUpdate() const
{
    if (!m_frame)
        return;
    if (Page* page = m_frame->page())
        page->animator().scheduleVisualUpdate();
}

}

#ifndef NDEBUG

void showTree(const blink::FrameSelection& sel)
{
    sel.showTreeForThis();
}

void showTree(const blink::FrameSelection* sel)
{
    if (sel)
        sel->showTreeForThis();
}

#endif
