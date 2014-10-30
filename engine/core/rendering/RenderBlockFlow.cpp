/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/rendering/RenderBlockFlow.h"

#include "core/frame/FrameView.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/rendering/HitTestLocation.h"
#include "core/rendering/RenderLayer.h"
#include "core/rendering/RenderText.h"
#include "core/rendering/RenderView.h"
#include "core/rendering/line/LineWidth.h"
#include "platform/text/BidiTextRun.h"

namespace blink {

bool RenderBlockFlow::s_canPropagateFloatIntoSibling = false;

struct SameSizeAsMarginInfo {
    uint16_t bitfields;
    LayoutUnit margins[2];
};

COMPILE_ASSERT(sizeof(RenderBlockFlow::MarginValues) == sizeof(LayoutUnit[4]), MarginValues_should_stay_small);

class MarginInfo {
    // Collapsing flags for whether we can collapse our margins with our children's margins.
    bool m_canCollapseWithChildren : 1;
    bool m_canCollapseMarginBeforeWithChildren : 1;
    bool m_canCollapseMarginAfterWithChildren : 1;
    bool m_canCollapseMarginAfterWithLastChild: 1;

    // This flag tracks whether we are still looking at child margins that can all collapse together at the beginning of a block.
    // They may or may not collapse with the top margin of the block (|m_canCollapseTopWithChildren| tells us that), but they will
    // always be collapsing with one another. This variable can remain set to true through multiple iterations
    // as long as we keep encountering self-collapsing blocks.
    bool m_atBeforeSideOfBlock : 1;

    // This flag is set when we know we're examining bottom margins and we know we're at the bottom of the block.
    bool m_atAfterSideOfBlock : 1;

    // These variables are used to detect quirky margins that we need to collapse away (in table cells
    // and in the body element).
    bool m_hasMarginBeforeQuirk : 1;
    bool m_hasMarginAfterQuirk : 1;
    bool m_determinedMarginBeforeQuirk : 1;

    bool m_discardMargin : 1;

    // These flags track the previous maximal positive and negative margins.
    LayoutUnit m_positiveMargin;
    LayoutUnit m_negativeMargin;

public:
    MarginInfo(RenderBlockFlow*, LayoutUnit beforeBorderPadding, LayoutUnit afterBorderPadding);

    void setAtBeforeSideOfBlock(bool b) { m_atBeforeSideOfBlock = b; }
    void setAtAfterSideOfBlock(bool b) { m_atAfterSideOfBlock = b; }
    void clearMargin()
    {
        m_positiveMargin = 0;
        m_negativeMargin = 0;
    }
    void setHasMarginBeforeQuirk(bool b) { m_hasMarginBeforeQuirk = b; }
    void setHasMarginAfterQuirk(bool b) { m_hasMarginAfterQuirk = b; }
    void setDeterminedMarginBeforeQuirk(bool b) { m_determinedMarginBeforeQuirk = b; }
    void setPositiveMargin(LayoutUnit p) { ASSERT(!m_discardMargin); m_positiveMargin = p; }
    void setNegativeMargin(LayoutUnit n) { ASSERT(!m_discardMargin); m_negativeMargin = n; }
    void setPositiveMarginIfLarger(LayoutUnit p)
    {
        ASSERT(!m_discardMargin);
        if (p > m_positiveMargin)
            m_positiveMargin = p;
    }
    void setNegativeMarginIfLarger(LayoutUnit n)
    {
        ASSERT(!m_discardMargin);
        if (n > m_negativeMargin)
            m_negativeMargin = n;
    }

    void setMargin(LayoutUnit p, LayoutUnit n) { ASSERT(!m_discardMargin); m_positiveMargin = p; m_negativeMargin = n; }
    void setCanCollapseMarginAfterWithChildren(bool collapse) { m_canCollapseMarginAfterWithChildren = collapse; }
    void setCanCollapseMarginAfterWithLastChild(bool collapse) { m_canCollapseMarginAfterWithLastChild = collapse; }
    void setDiscardMargin(bool value) { m_discardMargin = value; }

    bool atBeforeSideOfBlock() const { return m_atBeforeSideOfBlock; }
    bool canCollapseWithMarginBefore() const { return m_atBeforeSideOfBlock && m_canCollapseMarginBeforeWithChildren; }
    bool canCollapseWithMarginAfter() const { return m_atAfterSideOfBlock && m_canCollapseMarginAfterWithChildren; }
    bool canCollapseMarginBeforeWithChildren() const { return m_canCollapseMarginBeforeWithChildren; }
    bool canCollapseMarginAfterWithChildren() const { return m_canCollapseMarginAfterWithChildren; }
    bool canCollapseMarginAfterWithLastChild() const { return m_canCollapseMarginAfterWithLastChild; }
    bool determinedMarginBeforeQuirk() const { return m_determinedMarginBeforeQuirk; }
    bool hasMarginBeforeQuirk() const { return m_hasMarginBeforeQuirk; }
    bool hasMarginAfterQuirk() const { return m_hasMarginAfterQuirk; }
    LayoutUnit positiveMargin() const { return m_positiveMargin; }
    LayoutUnit negativeMargin() const { return m_negativeMargin; }
    bool discardMargin() const { return m_discardMargin; }
    LayoutUnit margin() const { return m_positiveMargin - m_negativeMargin; }
};

void RenderBlockFlow::RenderBlockFlowRareData::trace(Visitor* visitor)
{
}

RenderBlockFlow::RenderBlockFlow(ContainerNode* node)
    : RenderBlock(node)
{
    COMPILE_ASSERT(sizeof(MarginInfo) == sizeof(SameSizeAsMarginInfo), MarginInfo_should_stay_small);
    setChildrenInline(true);
}

RenderBlockFlow::~RenderBlockFlow()
{
}

void RenderBlockFlow::trace(Visitor* visitor)
{
    visitor->trace(m_rareData);
    RenderBlock::trace(visitor);
}

RenderBlockFlow* RenderBlockFlow::createAnonymous(Document* document)
{
    RenderBlockFlow* renderer = new RenderBlockFlow(0);
    renderer->setDocumentForAnonymous(document);
    return renderer;
}

bool RenderBlockFlow::updateLogicalWidthAndColumnWidth()
{
    return RenderBlock::updateLogicalWidthAndColumnWidth();
}

void RenderBlockFlow::setBreakAtLineToAvoidWidow(int lineToBreak)
{
    ASSERT(lineToBreak >= 0);
    ensureRareData();
    ASSERT(!m_rareData->m_didBreakAtLineToAvoidWidow);
    m_rareData->m_lineBreakToAvoidWidow = lineToBreak;
}

void RenderBlockFlow::setDidBreakAtLineToAvoidWidow()
{
    ASSERT(!shouldBreakAtLineToAvoidWidow());

    // This function should be called only after a break was applied to avoid widows
    // so assert |m_rareData| exists.
    ASSERT(m_rareData);

    m_rareData->m_didBreakAtLineToAvoidWidow = true;
}

void RenderBlockFlow::clearDidBreakAtLineToAvoidWidow()
{
    if (!m_rareData)
        return;

    m_rareData->m_didBreakAtLineToAvoidWidow = false;
}

void RenderBlockFlow::clearShouldBreakAtLineToAvoidWidow() const
{
    ASSERT(shouldBreakAtLineToAvoidWidow());
    if (!m_rareData)
        return;

    m_rareData->m_lineBreakToAvoidWidow = -1;
}

bool RenderBlockFlow::isSelfCollapsingBlock() const
{
    m_hasOnlySelfCollapsingChildren = RenderBlock::isSelfCollapsingBlock();
    return m_hasOnlySelfCollapsingChildren;
}

void RenderBlockFlow::layoutBlock(bool relayoutChildren)
{
    ASSERT(needsLayout());
    ASSERT(isInlineBlock() || !isInline());

    // If we are self-collapsing with self-collapsing descendants this will get set to save us burrowing through our
    // descendants every time in |isSelfCollapsingBlock|. We reset it here so that |isSelfCollapsingBlock| attempts to burrow
    // at least once and so that it always gives a reliable result reflecting the latest layout.
    m_hasOnlySelfCollapsingChildren = false;

    if (!relayoutChildren && simplifiedLayout())
        return;

    SubtreeLayoutScope layoutScope(*this);

    // Multiple passes might be required for column and pagination based layout
    // In the case of the old column code the number of passes will only be two
    // however, in the newer column code the number of passes could equal the
    // number of columns.
    bool done = false;
    while (!done)
        done = layoutBlockFlow(relayoutChildren, layoutScope);

    fitBorderToLinesIfNeeded();

    updateLayerTransformAfterLayout();

    // Update our scroll information if we're overflow:auto/scroll/hidden now that we know if
    // we overflow or not.
    updateScrollInfoAfterLayout();

    if (m_paintInvalidationLogicalTop != m_paintInvalidationLogicalBottom)
        setShouldInvalidateOverflowForPaint(true);

    clearNeedsLayout();
}

inline bool RenderBlockFlow::layoutBlockFlow(bool relayoutChildren, SubtreeLayoutScope& layoutScope)
{
    LayoutUnit oldLeft = logicalLeft();
    bool logicalWidthChanged = updateLogicalWidthAndColumnWidth();
    relayoutChildren |= logicalWidthChanged;

    rebuildFloatsFromIntruding();

    LayoutState state(*this, locationOffset(), logicalWidthChanged);

    // We use four values, maxTopPos, maxTopNeg, maxBottomPos, and maxBottomNeg, to track
    // our current maximal positive and negative margins. These values are used when we
    // are collapsed with adjacent blocks, so for example, if you have block A and B
    // collapsing together, then you'd take the maximal positive margin from both A and B
    // and subtract it from the maximal negative margin from both A and B to get the
    // true collapsed margin. This algorithm is recursive, so when we finish layout()
    // our block knows its current maximal positive/negative values.
    initMaxMarginValues();
    setHasMarginBeforeQuirk(style()->hasMarginBeforeQuirk());
    setHasMarginAfterQuirk(style()->hasMarginAfterQuirk());

    LayoutUnit beforeEdge = borderBefore() + paddingBefore();
    LayoutUnit afterEdge = borderAfter() + paddingAfter() + scrollbarLogicalHeight();
    LayoutUnit previousHeight = logicalHeight();
    setLogicalHeight(beforeEdge);

    m_paintInvalidationLogicalTop = 0;
    m_paintInvalidationLogicalBottom = 0;
    if (!firstChild() && !isAnonymousBlock())
        setChildrenInline(true);

    if (childrenInline())
        layoutInlineChildren(relayoutChildren, m_paintInvalidationLogicalTop, m_paintInvalidationLogicalBottom, afterEdge);
    else
        layoutBlockChildren(relayoutChildren, layoutScope, beforeEdge, afterEdge);

    // Expand our intrinsic height to encompass floats.
    if (lowestFloatLogicalBottom() > (logicalHeight() - afterEdge) && createsBlockFormattingContext())
        setLogicalHeight(lowestFloatLogicalBottom() + afterEdge);

    if (shouldBreakAtLineToAvoidWidow()) {
        setEverHadLayout(true);
        return false;
    }

    // Calculate our new height.
    LayoutUnit oldHeight = logicalHeight();
    LayoutUnit oldClientAfterEdge = clientLogicalBottom();

    updateLogicalHeight();
    LayoutUnit newHeight = logicalHeight();
    if (oldHeight > newHeight && !childrenInline()) {
        // One of our children's floats may have become an overhanging float for us.
        for (RenderObject* child = lastChild(); child; child = child->previousSibling()) {
            if (child->isRenderBlockFlow() && !child->isFloatingOrOutOfFlowPositioned()) {
                RenderBlockFlow* block = toRenderBlockFlow(child);
                if (block->lowestFloatLogicalBottom() + block->logicalTop() <= newHeight)
                    break;
                addOverhangingFloats(block, false);
            }
        }
    }

    bool heightChanged = (previousHeight != newHeight);
    if (heightChanged)
        relayoutChildren = true;

    layoutPositionedObjects(relayoutChildren || isDocumentElement(), oldLeft != logicalLeft() ? ForcedLayoutAfterContainingBlockMoved : DefaultLayout);

    // Add overflow from children (unless we're multi-column, since in that case all our child overflow is clipped anyway).
    computeOverflow(oldClientAfterEdge);

    m_descendantsWithFloatsMarkedForLayout = false;
    return true;
}

void RenderBlockFlow::determineLogicalLeftPositionForChild(RenderBox* child)
{
    LayoutUnit startPosition = borderStart() + paddingStart();
    LayoutUnit initialStartPosition = startPosition;
    if (style()->shouldPlaceBlockDirectionScrollbarOnLogicalLeft())
        startPosition -= verticalScrollbarWidth();
    LayoutUnit totalAvailableLogicalWidth = borderAndPaddingLogicalWidth() + availableLogicalWidth();

    LayoutUnit childMarginStart = marginStartForChild(child);
    LayoutUnit newPosition = startPosition + childMarginStart;

    LayoutUnit positionToAvoidFloats;
    if (child->avoidsFloats() && containsFloats())
        positionToAvoidFloats = startOffsetForLine(logicalTopForChild(child), false, logicalHeightForChild(child));

    // If the child has an offset from the content edge to avoid floats then use that, otherwise let any negative
    // margin pull it back over the content edge or any positive margin push it out.
    // If the child is being centred then the margin calculated to do that has factored in any offset required to
    // avoid floats, so use it if necessary.
    if (style()->textAlign() == WEBKIT_CENTER || child->style()->marginStartUsing(style()).isAuto())
        newPosition = std::max(newPosition, positionToAvoidFloats + childMarginStart);
    else if (positionToAvoidFloats > initialStartPosition)
        newPosition = std::max(newPosition, positionToAvoidFloats);

    setLogicalLeftForChild(child, style()->isLeftToRightDirection() ? newPosition : totalAvailableLogicalWidth - newPosition - logicalWidthForChild(child));
}

void RenderBlockFlow::setLogicalLeftForChild(RenderBox* child, LayoutUnit logicalLeft)
{
    child->setX(logicalLeft);
}

void RenderBlockFlow::setLogicalTopForChild(RenderBox* child, LayoutUnit logicalTop)
{
    child->setY(logicalTop);
}

void RenderBlockFlow::layoutBlockChild(RenderBox* child, MarginInfo& marginInfo, LayoutUnit& previousFloatLogicalBottom)
{
    LayoutUnit oldPosMarginBefore = maxPositiveMarginBefore();
    LayoutUnit oldNegMarginBefore = maxNegativeMarginBefore();

    // The child is a normal flow object. Compute the margins we will use for collapsing now.
    child->computeAndSetBlockDirectionMargins(this);

    // Try to guess our correct logical top position. In most cases this guess will
    // be correct. Only if we're wrong (when we compute the real logical top position)
    // will we have to potentially relayout.
    LayoutUnit logicalTopEstimate = estimateLogicalTopPosition(child, marginInfo);

    // Cache our old rect so that we can dirty the proper paint invalidation rects if the child moves.
    LayoutRect oldRect = child->frameRect();
    LayoutUnit oldLogicalTop = logicalTopForChild(child);

    // Go ahead and position the child as though it didn't collapse with the top.
    setLogicalTopForChild(child, logicalTopEstimate);

    RenderBlockFlow* childRenderBlockFlow = child->isRenderBlockFlow() ? toRenderBlockFlow(child) : 0;
    bool markDescendantsWithFloats = false;
    if (logicalTopEstimate != oldLogicalTop && childRenderBlockFlow && !childRenderBlockFlow->avoidsFloats() && childRenderBlockFlow->containsFloats()) {
        markDescendantsWithFloats = true;
    } else if (UNLIKELY(logicalTopEstimate.mightBeSaturated())) {
        // logicalTopEstimate, returned by estimateLogicalTopPosition, might be saturated for
        // very large elements. If it does the comparison with oldLogicalTop might yield a
        // false negative as adding and removing margins, borders etc from a saturated number
        // might yield incorrect results. If this is the case always mark for layout.
        markDescendantsWithFloats = true;
    } else if (!child->avoidsFloats() || child->shrinkToAvoidFloats()) {
        // If an element might be affected by the presence of floats, then always mark it for
        // layout.
        LayoutUnit fb = std::max(previousFloatLogicalBottom, lowestFloatLogicalBottom());
        if (fb > logicalTopEstimate)
            markDescendantsWithFloats = true;
    }

    if (childRenderBlockFlow) {
        if (markDescendantsWithFloats)
            childRenderBlockFlow->markAllDescendantsWithFloatsForLayout();
        if (!child->isWritingModeRoot())
            previousFloatLogicalBottom = std::max(previousFloatLogicalBottom, oldLogicalTop + childRenderBlockFlow->lowestFloatLogicalBottom());
    }

    SubtreeLayoutScope layoutScope(*child);

    bool childHadLayout = child->everHadLayout();
    bool childNeededLayout = child->needsLayout();
    if (childNeededLayout)
        child->layout();

    // Cache if we are at the top of the block right now.
    bool childIsSelfCollapsing = child->isSelfCollapsingBlock();

    // Now determine the correct ypos based off examination of collapsing margin
    // values.
    LayoutUnit logicalTopBeforeClear = collapseMargins(child, marginInfo, childIsSelfCollapsing);

    // Now check for clear.
    LayoutUnit logicalTopAfterClear = clearFloatsIfNeeded(child, marginInfo, oldPosMarginBefore, oldNegMarginBefore, logicalTopBeforeClear, childIsSelfCollapsing);

    setLogicalTopForChild(child, logicalTopAfterClear);

    // Now we have a final top position. See if it really does end up being different from our estimate.
    // clearFloatsIfNeeded can also mark the child as needing a layout even though we didn't move. This happens
    // when collapseMargins dynamically adds overhanging floats because of a child with negative margins.
    if (logicalTopAfterClear != logicalTopEstimate || child->needsLayout()) {
        SubtreeLayoutScope layoutScope(*child);
        if (child->shrinkToAvoidFloats()) {
            // The child's width depends on the line width.
            // When the child shifts to clear an item, its width can
            // change (because it has more available line width).
            // So go ahead and mark the item as dirty.
            layoutScope.setChildNeedsLayout(child);
        }

        if (childRenderBlockFlow && !childRenderBlockFlow->avoidsFloats() && childRenderBlockFlow->containsFloats())
            childRenderBlockFlow->markAllDescendantsWithFloatsForLayout();

        // Our guess was wrong. Make the child lay itself out again.
        child->layoutIfNeeded();
    }

    // If we previously encountered a self-collapsing sibling of this child that had clearance then
    // we set this bit to ensure we would not collapse the child's margins, and those of any subsequent
    // self-collapsing siblings, with our parent. If this child is not self-collapsing then it can
    // collapse its margins with the parent so reset the bit.
    if (!marginInfo.canCollapseMarginAfterWithLastChild() && !childIsSelfCollapsing)
        marginInfo.setCanCollapseMarginAfterWithLastChild(true);

    // We are no longer at the top of the block if we encounter a non-empty child.
    // This has to be done after checking for clear, so that margins can be reset if a clear occurred.
    if (marginInfo.atBeforeSideOfBlock() && !childIsSelfCollapsing)
        marginInfo.setAtBeforeSideOfBlock(false);

    // Now place the child in the correct left position
    determineLogicalLeftPositionForChild(child);

    LayoutSize childOffset = child->location() - oldRect.location();

    // Update our height now that the child has been placed in the correct position.
    setLogicalHeight(logicalHeight() + logicalHeightForChild(child));
    if (mustSeparateMarginAfterForChild(child)) {
        setLogicalHeight(logicalHeight() + marginAfterForChild(child));
        marginInfo.clearMargin();
    }
    // If the child has overhanging floats that intrude into following siblings (or possibly out
    // of this block), then the parent gets notified of the floats now.
    if (childRenderBlockFlow)
        addOverhangingFloats(childRenderBlockFlow, !childNeededLayout);

    // If the child moved, we have to invalidate it's paint  as well as any floating/positioned
    // descendants. An exception is if we need a layout. In this case, we know we're going to
    // invalidate our paint (and the child) anyway.
    bool didNotDoFullLayoutAndMoved = childHadLayout && !selfNeedsLayout() && (childOffset.width() || childOffset.height());
    bool didNotLayoutAndNeedsPaintInvalidation = !childHadLayout && child->checkForPaintInvalidation();

    if (didNotDoFullLayoutAndMoved || didNotLayoutAndNeedsPaintInvalidation)
        child->invalidatePaintForOverhangingFloats(true);
}

void RenderBlockFlow::rebuildFloatsFromIntruding()
{
    // FIXME(sky): Remove this.
}

void RenderBlockFlow::layoutBlockChildren(bool relayoutChildren, SubtreeLayoutScope& layoutScope, LayoutUnit beforeEdge, LayoutUnit afterEdge)
{
    dirtyForLayoutFromPercentageHeightDescendants(layoutScope);

    // The margin struct caches all our current margin collapsing state. The compact struct caches state when we encounter compacts,
    MarginInfo marginInfo(this, beforeEdge, afterEdge);

    LayoutUnit previousFloatLogicalBottom = 0;

    RenderBox* next = firstChildBox();
    RenderBox* lastNormalFlowChild = 0;

    while (next) {
        RenderBox* child = next;
        next = child->nextSiblingBox();

        // FIXME: this should only be set from clearNeedsLayout crbug.com/361250
        child->setLayoutDidGetCalled(true);

        updateBlockChildDirtyBitsBeforeLayout(relayoutChildren, child);

        if (child->isOutOfFlowPositioned()) {
            child->containingBlock()->insertPositionedObject(child);
            adjustPositionedBlock(child, marginInfo);
            continue;
        }

        // Lay out the child.
        layoutBlockChild(child, marginInfo, previousFloatLogicalBottom);
        lastNormalFlowChild = child;
    }

    // Now do the handling of the bottom of the block, adding in our bottom border/padding and
    // determining the correct collapsed bottom margin information.
    handleAfterSideOfBlock(lastNormalFlowChild, beforeEdge, afterEdge, marginInfo);
}

// Our MarginInfo state used when laying out block children.
MarginInfo::MarginInfo(RenderBlockFlow* blockFlow, LayoutUnit beforeBorderPadding, LayoutUnit afterBorderPadding)
    : m_canCollapseMarginAfterWithLastChild(true)
    , m_atBeforeSideOfBlock(true)
    , m_atAfterSideOfBlock(false)
    , m_hasMarginBeforeQuirk(false)
    , m_hasMarginAfterQuirk(false)
    , m_determinedMarginBeforeQuirk(false)
    , m_discardMargin(false)
{
    RenderStyle* blockStyle = blockFlow->style();
    ASSERT(blockFlow->isRenderView() || blockFlow->parent());
    m_canCollapseWithChildren = !blockFlow->createsBlockFormattingContext() && !blockFlow->isRenderView();

    m_canCollapseMarginBeforeWithChildren = m_canCollapseWithChildren && !beforeBorderPadding && blockStyle->marginBeforeCollapse() != MSEPARATE;

    // If any height other than auto is specified in CSS, then we don't collapse our bottom
    // margins with our children's margins. To do otherwise would be to risk odd visual
    // effects when the children overflow out of the parent block and yet still collapse
    // with it. We also don't collapse if we have any bottom border/padding.
    m_canCollapseMarginAfterWithChildren = m_canCollapseWithChildren && !afterBorderPadding
        && (blockStyle->logicalHeight().isAuto() && !blockStyle->logicalHeight().value()) && blockStyle->marginAfterCollapse() != MSEPARATE;

    m_discardMargin = m_canCollapseMarginBeforeWithChildren && blockFlow->mustDiscardMarginBefore();

    m_positiveMargin = (m_canCollapseMarginBeforeWithChildren && !blockFlow->mustDiscardMarginBefore()) ? blockFlow->maxPositiveMarginBefore() : LayoutUnit();
    m_negativeMargin = (m_canCollapseMarginBeforeWithChildren && !blockFlow->mustDiscardMarginBefore()) ? blockFlow->maxNegativeMarginBefore() : LayoutUnit();
}

RenderBlockFlow::MarginValues RenderBlockFlow::marginValuesForChild(RenderBox* child) const
{
    LayoutUnit childBeforePositive = 0;
    LayoutUnit childBeforeNegative = 0;
    LayoutUnit childAfterPositive = 0;
    LayoutUnit childAfterNegative = 0;

    LayoutUnit beforeMargin = 0;
    LayoutUnit afterMargin = 0;

    RenderBlockFlow* childRenderBlockFlow = child->isRenderBlockFlow() ? toRenderBlockFlow(child) : 0;

    if (childRenderBlockFlow) {
        childBeforePositive = childRenderBlockFlow->maxPositiveMarginBefore();
        childBeforeNegative = childRenderBlockFlow->maxNegativeMarginBefore();
        childAfterPositive = childRenderBlockFlow->maxPositiveMarginAfter();
        childAfterNegative = childRenderBlockFlow->maxNegativeMarginAfter();
    } else {
        beforeMargin = child->marginBefore();
        afterMargin = child->marginAfter();
    }

    // Resolve uncollapsing margins into their positive/negative buckets.
    if (beforeMargin) {
        if (beforeMargin > 0)
            childBeforePositive = beforeMargin;
        else
            childBeforeNegative = -beforeMargin;
    }
    if (afterMargin) {
        if (afterMargin > 0)
            childAfterPositive = afterMargin;
        else
            childAfterNegative = -afterMargin;
    }

    return RenderBlockFlow::MarginValues(childBeforePositive, childBeforeNegative, childAfterPositive, childAfterNegative);
}

LayoutUnit RenderBlockFlow::collapseMargins(RenderBox* child, MarginInfo& marginInfo, bool childIsSelfCollapsing)
{
    bool childDiscardMarginBefore = mustDiscardMarginBeforeForChild(child);
    bool childDiscardMarginAfter = mustDiscardMarginAfterForChild(child);

    // The child discards the before margin when the the after margin has discard in the case of a self collapsing block.
    childDiscardMarginBefore = childDiscardMarginBefore || (childDiscardMarginAfter && childIsSelfCollapsing);

    // Get the four margin values for the child and cache them.
    const RenderBlockFlow::MarginValues childMargins = marginValuesForChild(child);

    // Get our max pos and neg top margins.
    LayoutUnit posTop = childMargins.positiveMarginBefore();
    LayoutUnit negTop = childMargins.negativeMarginBefore();

    // For self-collapsing blocks, collapse our bottom margins into our
    // top to get new posTop and negTop values.
    if (childIsSelfCollapsing) {
        posTop = std::max(posTop, childMargins.positiveMarginAfter());
        negTop = std::max(negTop, childMargins.negativeMarginAfter());
    }

    // See if the top margin is quirky. We only care if this child has
    // margins that will collapse with us.
    bool topQuirk = hasMarginBeforeQuirk(child);

    if (marginInfo.canCollapseWithMarginBefore()) {
        if (!childDiscardMarginBefore && !marginInfo.discardMargin()) {
            // This child is collapsing with the top of the
            // block. If it has larger margin values, then we need to update
            // our own maximal values.
            setMaxMarginBeforeValues(std::max(posTop, maxPositiveMarginBefore()), std::max(negTop, maxNegativeMarginBefore()));

            // The minute any of the margins involved isn't a quirk, don't
            // collapse it away, even if the margin is smaller (www.webreference.com
            // has an example of this, a <dt> with 0.8em author-specified inside
            // a <dl> inside a <td>.
            if (!marginInfo.determinedMarginBeforeQuirk() && !topQuirk && (posTop - negTop)) {
                setHasMarginBeforeQuirk(false);
                marginInfo.setDeterminedMarginBeforeQuirk(true);
            }

            if (!marginInfo.determinedMarginBeforeQuirk() && topQuirk && !marginBefore()) {
                // We have no top margin and our top child has a quirky margin.
                // We will pick up this quirky margin and pass it through.
                // This deals with the <td><div><p> case.
                // Don't do this for a block that split two inlines though. You do
                // still apply margins in this case.
                setHasMarginBeforeQuirk(true);
            }
        } else {
            // The before margin of the container will also discard all the margins it is collapsing with.
            setMustDiscardMarginBefore();
        }
    }

    // Once we find a child with discardMarginBefore all the margins collapsing with us must also discard.
    if (childDiscardMarginBefore) {
        marginInfo.setDiscardMargin(true);
        marginInfo.clearMargin();
    }

    LayoutUnit beforeCollapseLogicalTop = logicalHeight();
    LayoutUnit logicalTop = beforeCollapseLogicalTop;

    LayoutUnit clearanceForSelfCollapsingBlock;
    RenderObject* prev = child->previousSibling();
    RenderBlockFlow* previousBlockFlow =  prev && prev->isRenderBlockFlow() && !prev->isFloatingOrOutOfFlowPositioned() ? toRenderBlockFlow(prev) : 0;
    // If the child's previous sibling is a self-collapsing block that cleared a float then its top border edge has been set at the bottom border edge
    // of the float. Since we want to collapse the child's top margin with the self-collapsing block's top and bottom margins we need to adjust our parent's height to match the
    // margin top of the self-collapsing block. If the resulting collapsed margin leaves the child still intruding into the float then we will want to clear it.
    if (!marginInfo.canCollapseWithMarginBefore() && previousBlockFlow && previousBlockFlow->isSelfCollapsingBlock()) {
        clearanceForSelfCollapsingBlock = previousBlockFlow->marginOffsetForSelfCollapsingBlock();
        setLogicalHeight(logicalHeight() - clearanceForSelfCollapsingBlock);
    }

    if (childIsSelfCollapsing) {
        // For a self collapsing block both the before and after margins get discarded. The block doesn't contribute anything to the height of the block.
        // Also, the child's top position equals the logical height of the container.
        if (!childDiscardMarginBefore && !marginInfo.discardMargin()) {
            // This child has no height. We need to compute our
            // position before we collapse the child's margins together,
            // so that we can get an accurate position for the zero-height block.
            LayoutUnit collapsedBeforePos = std::max(marginInfo.positiveMargin(), childMargins.positiveMarginBefore());
            LayoutUnit collapsedBeforeNeg = std::max(marginInfo.negativeMargin(), childMargins.negativeMarginBefore());
            marginInfo.setMargin(collapsedBeforePos, collapsedBeforeNeg);

            // Now collapse the child's margins together, which means examining our
            // bottom margin values as well.
            marginInfo.setPositiveMarginIfLarger(childMargins.positiveMarginAfter());
            marginInfo.setNegativeMarginIfLarger(childMargins.negativeMarginAfter());

            if (!marginInfo.canCollapseWithMarginBefore()) {
                // We need to make sure that the position of the self-collapsing block
                // is correct, since it could have overflowing content
                // that needs to be positioned correctly (e.g., a block that
                // had a specified height of 0 but that actually had subcontent).
                logicalTop = logicalHeight() + collapsedBeforePos - collapsedBeforeNeg;
            }
        }
    } else {
        if (mustSeparateMarginBeforeForChild(child)) {
            ASSERT(!marginInfo.discardMargin() || (marginInfo.discardMargin() && !marginInfo.margin()));
            // If we are at the before side of the block and we collapse, ignore the computed margin
            // and just add the child margin to the container height. This will correctly position
            // the child inside the container.
            LayoutUnit separateMargin = !marginInfo.canCollapseWithMarginBefore() ? marginInfo.margin() : LayoutUnit(0);
            setLogicalHeight(logicalHeight() + separateMargin + marginBeforeForChild(child));
            logicalTop = logicalHeight();
        } else if (!marginInfo.discardMargin() && (!marginInfo.atBeforeSideOfBlock()
            || (!marginInfo.canCollapseMarginBeforeWithChildren()))) {
            // We're collapsing with a previous sibling's margins and not
            // with the top of the block.
            setLogicalHeight(logicalHeight() + std::max(marginInfo.positiveMargin(), posTop) - std::max(marginInfo.negativeMargin(), negTop));
            logicalTop = logicalHeight();
        }

        marginInfo.setDiscardMargin(childDiscardMarginAfter);

        if (!marginInfo.discardMargin()) {
            marginInfo.setPositiveMargin(childMargins.positiveMarginAfter());
            marginInfo.setNegativeMargin(childMargins.negativeMarginAfter());
        } else {
            marginInfo.clearMargin();
        }

        if (marginInfo.margin())
            marginInfo.setHasMarginAfterQuirk(hasMarginAfterQuirk(child));
    }

    if (previousBlockFlow) {
        // If |child| is a self-collapsing block it may have collapsed into a previous sibling and although it hasn't reduced the height of the parent yet
        // any floats from the parent will now overhang.
        LayoutUnit oldLogicalHeight = logicalHeight();
        setLogicalHeight(logicalTop);
        if (!previousBlockFlow->avoidsFloats() && (previousBlockFlow->logicalTop() + previousBlockFlow->lowestFloatLogicalBottom()) > logicalTop)
            addOverhangingFloats(previousBlockFlow, false);
        setLogicalHeight(oldLogicalHeight);

        // If |child|'s previous sibling is a self-collapsing block that cleared a float and margin collapsing resulted in |child| moving up
        // into the margin area of the self-collapsing block then the float it clears is now intruding into |child|. Layout again so that we can look for
        // floats in the parent that overhang |child|'s new logical top.
        bool logicalTopIntrudesIntoFloat = clearanceForSelfCollapsingBlock > 0 && logicalTop < beforeCollapseLogicalTop;
        if (logicalTopIntrudesIntoFloat && containsFloats() && !child->avoidsFloats() && lowestFloatLogicalBottom() > logicalTop)
            child->setNeedsLayoutAndFullPaintInvalidation();
    }

    return logicalTop;
}

void RenderBlockFlow::adjustPositionedBlock(RenderBox* child, const MarginInfo& marginInfo)
{
    bool hasStaticBlockPosition = child->style()->hasStaticBlockPosition();

    LayoutUnit logicalTop = logicalHeight();
    updateStaticInlinePositionForChild(child, logicalTop);

    if (!marginInfo.canCollapseWithMarginBefore()) {
        // Positioned blocks don't collapse margins, so add the margin provided by
        // the container now. The child's own margin is added later when calculating its logical top.
        LayoutUnit collapsedBeforePos = marginInfo.positiveMargin();
        LayoutUnit collapsedBeforeNeg = marginInfo.negativeMargin();
        logicalTop += collapsedBeforePos - collapsedBeforeNeg;
    }

    RenderLayer* childLayer = child->layer();
    if (childLayer->staticBlockPosition() != logicalTop) {
        childLayer->setStaticBlockPosition(logicalTop);
        if (hasStaticBlockPosition)
            child->setChildNeedsLayout(MarkOnlyThis);
    }
}

LayoutUnit RenderBlockFlow::clearFloatsIfNeeded(RenderBox* child, MarginInfo& marginInfo, LayoutUnit oldTopPosMargin, LayoutUnit oldTopNegMargin, LayoutUnit yPos, bool childIsSelfCollapsing)
{
    LayoutUnit heightIncrease = getClearDelta(child, yPos);
    if (!heightIncrease)
        return yPos;

    if (childIsSelfCollapsing) {
        bool childDiscardMargin = mustDiscardMarginBeforeForChild(child) || mustDiscardMarginAfterForChild(child);

        // For self-collapsing blocks that clear, they can still collapse their
        // margins with following siblings. Reset the current margins to represent
        // the self-collapsing block's margins only.
        // If DISCARD is specified for -webkit-margin-collapse, reset the margin values.
        RenderBlockFlow::MarginValues childMargins = marginValuesForChild(child);
        if (!childDiscardMargin) {
            marginInfo.setPositiveMargin(std::max(childMargins.positiveMarginBefore(), childMargins.positiveMarginAfter()));
            marginInfo.setNegativeMargin(std::max(childMargins.negativeMarginBefore(), childMargins.negativeMarginAfter()));
        } else {
            marginInfo.clearMargin();
        }
        marginInfo.setDiscardMargin(childDiscardMargin);

        // CSS2.1 states:
        // "If the top and bottom margins of an element with clearance are adjoining, its margins collapse with
        // the adjoining margins of following siblings but that resulting margin does not collapse with the bottom margin of the parent block."
        // So the parent's bottom margin cannot collapse through this block or any subsequent self-collapsing blocks. Set a bit to ensure
        // this happens; it will get reset if we encounter an in-flow sibling that is not self-collapsing.
        marginInfo.setCanCollapseMarginAfterWithLastChild(false);

        // For now set the border-top of |child| flush with the bottom border-edge of the float so it can layout any floating or positioned children of
        // its own at the correct vertical position. If subsequent siblings attempt to collapse with |child|'s margins in |collapseMargins| we will
        // adjust the height of the parent to |child|'s margin top (which if it is positive sits up 'inside' the float it's clearing) so that all three
        // margins can collapse at the correct vertical position.
        // Per CSS2.1 we need to ensure that any negative margin-top clears |child| beyond the bottom border-edge of the float so that the top border edge of the child
        // (i.e. its clearance)  is at a position that satisfies the equation: "the amount of clearance is set so that clearance + margin-top = [height of float],
        // i.e., clearance = [height of float] - margin-top".
        setLogicalHeight(child->logicalTop() + childMargins.negativeMarginBefore());
    } else {
        // Increase our height by the amount we had to clear.
        setLogicalHeight(logicalHeight() + heightIncrease);
    }

    if (marginInfo.canCollapseWithMarginBefore()) {
        // We can no longer collapse with the top of the block since a clear
        // occurred. The empty blocks collapse into the cleared block.
        setMaxMarginBeforeValues(oldTopPosMargin, oldTopNegMargin);
        marginInfo.setAtBeforeSideOfBlock(false);

        // In case the child discarded the before margin of the block we need to reset the mustDiscardMarginBefore flag to the initial value.
        setMustDiscardMarginBefore(style()->marginBeforeCollapse() == MDISCARD);
    }

    return yPos + heightIncrease;
}

void RenderBlockFlow::setCollapsedBottomMargin(const MarginInfo& marginInfo)
{
    if (marginInfo.canCollapseWithMarginAfter() && !marginInfo.canCollapseWithMarginBefore()) {
        // Update the after side margin of the container to discard if the after margin of the last child also discards and we collapse with it.
        // Don't update the max margin values because we won't need them anyway.
        if (marginInfo.discardMargin()) {
            setMustDiscardMarginAfter();
            return;
        }

        // Update our max pos/neg bottom margins, since we collapsed our bottom margins
        // with our children.
        setMaxMarginAfterValues(std::max(maxPositiveMarginAfter(), marginInfo.positiveMargin()), std::max(maxNegativeMarginAfter(), marginInfo.negativeMargin()));

        if (!marginInfo.hasMarginAfterQuirk())
            setHasMarginAfterQuirk(false);

        if (marginInfo.hasMarginAfterQuirk() && !marginAfter()) {
            // We have no bottom margin and our last child has a quirky margin.
            // We will pick up this quirky margin and pass it through.
            // This deals with the <td><div><p> case.
            setHasMarginAfterQuirk(true);
        }
    }
}

void RenderBlockFlow::marginBeforeEstimateForChild(RenderBox* child, LayoutUnit& positiveMarginBefore, LayoutUnit& negativeMarginBefore, bool& discardMarginBefore) const
{
    // Give up if in quirks mode and we're a body/table cell and the top margin of the child box is quirky.
    // Give up if the child specified -webkit-margin-collapse: separate that prevents collapsing.
    // FIXME: Use writing mode independent accessor for marginBeforeCollapse.
    if (child->style()->marginBeforeCollapse() == MSEPARATE)
        return;

    // The margins are discarded by a child that specified -webkit-margin-collapse: discard.
    // FIXME: Use writing mode independent accessor for marginBeforeCollapse.
    if (child->style()->marginBeforeCollapse() == MDISCARD) {
        positiveMarginBefore = 0;
        negativeMarginBefore = 0;
        discardMarginBefore = true;
        return;
    }

    LayoutUnit beforeChildMargin = marginBeforeForChild(child);
    positiveMarginBefore = std::max(positiveMarginBefore, beforeChildMargin);
    negativeMarginBefore = std::max(negativeMarginBefore, -beforeChildMargin);

    if (!child->isRenderBlockFlow())
        return;

    RenderBlockFlow* childBlockFlow = toRenderBlockFlow(child);
    if (childBlockFlow->childrenInline() || childBlockFlow->isWritingModeRoot())
        return;

    MarginInfo childMarginInfo(childBlockFlow, childBlockFlow->borderBefore() + childBlockFlow->paddingBefore(), childBlockFlow->borderAfter() + childBlockFlow->paddingAfter());
    if (!childMarginInfo.canCollapseMarginBeforeWithChildren())
        return;

    RenderBox* grandchildBox = childBlockFlow->firstChildBox();
    for ( ; grandchildBox; grandchildBox = grandchildBox->nextSiblingBox()) {
        if (!grandchildBox->isFloatingOrOutOfFlowPositioned())
            break;
    }

    // Give up if there is clearance on the box, since it probably won't collapse into us.
    if (!grandchildBox || grandchildBox->style()->clear() != CNONE)
        return;

    // Make sure to update the block margins now for the grandchild box so that we're looking at current values.
    if (grandchildBox->needsLayout()) {
        grandchildBox->computeAndSetBlockDirectionMargins(this);
        if (grandchildBox->isRenderBlock()) {
            RenderBlock* grandchildBlock = toRenderBlock(grandchildBox);
            grandchildBlock->setHasMarginBeforeQuirk(grandchildBox->style()->hasMarginBeforeQuirk());
            grandchildBlock->setHasMarginAfterQuirk(grandchildBox->style()->hasMarginAfterQuirk());
        }
    }

    // Collapse the margin of the grandchild box with our own to produce an estimate.
    childBlockFlow->marginBeforeEstimateForChild(grandchildBox, positiveMarginBefore, negativeMarginBefore, discardMarginBefore);
}

LayoutUnit RenderBlockFlow::estimateLogicalTopPosition(RenderBox* child, const MarginInfo& marginInfo)
{
    // FIXME: We need to eliminate the estimation of vertical position, because when it's wrong we sometimes trigger a pathological
    // relayout if there are intruding floats.
    LayoutUnit logicalTopEstimate = logicalHeight();
    if (!marginInfo.canCollapseWithMarginBefore()) {
        LayoutUnit positiveMarginBefore = 0;
        LayoutUnit negativeMarginBefore = 0;
        bool discardMarginBefore = false;
        if (child->selfNeedsLayout()) {
            // Try to do a basic estimation of how the collapse is going to go.
            marginBeforeEstimateForChild(child, positiveMarginBefore, negativeMarginBefore, discardMarginBefore);
        } else {
            // Use the cached collapsed margin values from a previous layout. Most of the time they
            // will be right.
            RenderBlockFlow::MarginValues marginValues = marginValuesForChild(child);
            positiveMarginBefore = std::max(positiveMarginBefore, marginValues.positiveMarginBefore());
            negativeMarginBefore = std::max(negativeMarginBefore, marginValues.negativeMarginBefore());
            discardMarginBefore = mustDiscardMarginBeforeForChild(child);
        }

        // Collapse the result with our current margins.
        if (!discardMarginBefore)
            logicalTopEstimate += std::max(marginInfo.positiveMargin(), positiveMarginBefore) - std::max(marginInfo.negativeMargin(), negativeMarginBefore);
    }

    logicalTopEstimate += getClearDelta(child, logicalTopEstimate);
    return logicalTopEstimate;
}

LayoutUnit RenderBlockFlow::marginOffsetForSelfCollapsingBlock()
{
    ASSERT(isSelfCollapsingBlock());
    RenderBlockFlow* parentBlock = toRenderBlockFlow(parent());
    if (parentBlock && style()->clear() && parentBlock->getClearDelta(this, logicalHeight()))
        return marginValuesForChild(this).positiveMarginBefore();
    return LayoutUnit();
}

void RenderBlockFlow::adjustFloatingBlock(const MarginInfo& marginInfo)
{
    // The float should be positioned taking into account the bottom margin
    // of the previous flow. We add that margin into the height, get the
    // float positioned properly, and then subtract the margin out of the
    // height again. In the case of self-collapsing blocks, we always just
    // use the top margins, since the self-collapsing block collapsed its
    // own bottom margin into its top margin.
    //
    // Note also that the previous flow may collapse its margin into the top of
    // our block. If this is the case, then we do not add the margin in to our
    // height when computing the position of the float. This condition can be tested
    // for by simply calling canCollapseWithMarginBefore. See
    // http://www.hixie.ch/tests/adhoc/css/box/block/margin-collapse/046.html for
    // an example of this scenario.
    LayoutUnit marginOffset = marginInfo.canCollapseWithMarginBefore() ? LayoutUnit() : marginInfo.margin();
    setLogicalHeight(logicalHeight() + marginOffset);
    positionNewFloats();
    setLogicalHeight(logicalHeight() - marginOffset);
}

void RenderBlockFlow::handleAfterSideOfBlock(RenderBox* lastChild, LayoutUnit beforeSide, LayoutUnit afterSide, MarginInfo& marginInfo)
{
    marginInfo.setAtAfterSideOfBlock(true);

    // If our last child was a self-collapsing block with clearance then our logical height is flush with the
    // bottom edge of the float that the child clears. The correct vertical position for the margin-collapsing we want
    // to perform now is at the child's margin-top - so adjust our height to that position.
    if (lastChild && lastChild->isRenderBlockFlow() && lastChild->isSelfCollapsingBlock())
        setLogicalHeight(logicalHeight() - toRenderBlockFlow(lastChild)->marginOffsetForSelfCollapsingBlock());

    if (marginInfo.canCollapseMarginAfterWithChildren() && !marginInfo.canCollapseMarginAfterWithLastChild())
        marginInfo.setCanCollapseMarginAfterWithChildren(false);

    // If we can't collapse with children then go ahead and add in the bottom margin.
    if (!marginInfo.discardMargin() && (!marginInfo.canCollapseWithMarginAfter() && !marginInfo.canCollapseWithMarginBefore()))
        setLogicalHeight(logicalHeight() + marginInfo.margin());

    // Now add in our bottom border/padding.
    setLogicalHeight(logicalHeight() + afterSide);

    // Negative margins can cause our height to shrink below our minimal height (border/padding).
    // If this happens, ensure that the computed height is increased to the minimal height.
    setLogicalHeight(std::max(logicalHeight(), beforeSide + afterSide));

    // Update our bottom collapsed margin info.
    setCollapsedBottomMargin(marginInfo);
}

void RenderBlockFlow::setMustDiscardMarginBefore(bool value)
{
    if (style()->marginBeforeCollapse() == MDISCARD) {
        ASSERT(value);
        return;
    }

    if (!m_rareData && !value)
        return;

    if (!m_rareData)
        m_rareData = adoptPtr(new RenderBlockFlowRareData(this));

    m_rareData->m_discardMarginBefore = value;
}

void RenderBlockFlow::setMustDiscardMarginAfter(bool value)
{
    if (style()->marginAfterCollapse() == MDISCARD) {
        ASSERT(value);
        return;
    }

    if (!m_rareData && !value)
        return;

    if (!m_rareData)
        m_rareData = adoptPtr(new RenderBlockFlowRareData(this));

    m_rareData->m_discardMarginAfter = value;
}

bool RenderBlockFlow::mustDiscardMarginBefore() const
{
    return style()->marginBeforeCollapse() == MDISCARD || (m_rareData && m_rareData->m_discardMarginBefore);
}

bool RenderBlockFlow::mustDiscardMarginAfter() const
{
    return style()->marginAfterCollapse() == MDISCARD || (m_rareData && m_rareData->m_discardMarginAfter);
}

bool RenderBlockFlow::mustDiscardMarginBeforeForChild(const RenderBox* child) const
{
    ASSERT(!child->selfNeedsLayout());
    return child->isRenderBlockFlow() ? toRenderBlockFlow(child)->mustDiscardMarginBefore() : (child->style()->marginBeforeCollapse() == MDISCARD);
}

bool RenderBlockFlow::mustDiscardMarginAfterForChild(const RenderBox* child) const
{
    ASSERT(!child->selfNeedsLayout());
    return child->isRenderBlockFlow() ? toRenderBlockFlow(child)->mustDiscardMarginAfter() : (child->style()->marginAfterCollapse() == MDISCARD);
}

void RenderBlockFlow::setMaxMarginBeforeValues(LayoutUnit pos, LayoutUnit neg)
{
    if (!m_rareData) {
        if (pos == RenderBlockFlowRareData::positiveMarginBeforeDefault(this) && neg == RenderBlockFlowRareData::negativeMarginBeforeDefault(this))
            return;
        m_rareData = adoptPtr(new RenderBlockFlowRareData(this));
    }
    m_rareData->m_margins.setPositiveMarginBefore(pos);
    m_rareData->m_margins.setNegativeMarginBefore(neg);
}

void RenderBlockFlow::setMaxMarginAfterValues(LayoutUnit pos, LayoutUnit neg)
{
    if (!m_rareData) {
        if (pos == RenderBlockFlowRareData::positiveMarginAfterDefault(this) && neg == RenderBlockFlowRareData::negativeMarginAfterDefault(this))
            return;
        m_rareData = adoptPtr(new RenderBlockFlowRareData(this));
    }
    m_rareData->m_margins.setPositiveMarginAfter(pos);
    m_rareData->m_margins.setNegativeMarginAfter(neg);
}

bool RenderBlockFlow::mustSeparateMarginBeforeForChild(const RenderBox* child) const
{
    ASSERT(!child->selfNeedsLayout());
    const RenderStyle* childStyle = child->style();
    if (!child->isWritingModeRoot())
        return childStyle->marginBeforeCollapse() == MSEPARATE;
    return childStyle->marginAfterCollapse() == MSEPARATE;
}

bool RenderBlockFlow::mustSeparateMarginAfterForChild(const RenderBox* child) const
{
    ASSERT(!child->selfNeedsLayout());
    const RenderStyle* childStyle = child->style();
    if (!child->isWritingModeRoot())
        return childStyle->marginAfterCollapse() == MSEPARATE;
    return childStyle->marginBeforeCollapse() == MSEPARATE;
}

void RenderBlockFlow::addOverflowFromFloats()
{
    // FIXME(sky): Remove this.
}

void RenderBlockFlow::computeOverflow(LayoutUnit oldClientAfterEdge, bool recomputeFloats)
{
    RenderBlock::computeOverflow(oldClientAfterEdge, recomputeFloats);
    if (recomputeFloats || createsBlockFormattingContext() || hasSelfPaintingLayer())
        addOverflowFromFloats();
}

RootInlineBox* RenderBlockFlow::createAndAppendRootInlineBox()
{
    RootInlineBox* rootBox = createRootInlineBox();
    m_lineBoxes.appendLineBox(rootBox);

    return rootBox;
}

void RenderBlockFlow::deleteLineBoxTree()
{
    m_lineBoxes.deleteLineBoxTree();
}

void RenderBlockFlow::markAllDescendantsWithFloatsForLayout(RenderBox* floatToRemove, bool inLayout)
{
    // FIXME(sky): Remove this.
}

void RenderBlockFlow::markSiblingsWithFloatsForLayout(RenderBox* floatToRemove)
{
    // FIXME(sky): Remove this.
}

LayoutUnit RenderBlockFlow::getClearDelta(RenderBox* child, LayoutUnit logicalTop)
{
    // FIXME(sky): Remove this.
    return 0;
}

void RenderBlockFlow::styleWillChange(StyleDifference diff, const RenderStyle& newStyle)
{
    RenderStyle* oldStyle = style();
    s_canPropagateFloatIntoSibling = oldStyle ? !isFloatingOrOutOfFlowPositioned() && !avoidsFloats() : false;
    if (oldStyle && parent() && diff.needsFullLayout() && oldStyle->position() != newStyle.position()
        && containsFloats() && !isFloating() && !isOutOfFlowPositioned() && newStyle.hasOutOfFlowPosition())
            markAllDescendantsWithFloatsForLayout();

    RenderBlock::styleWillChange(diff, newStyle);
}

void RenderBlockFlow::styleDidChange(StyleDifference diff, const RenderStyle* oldStyle)
{
    // FIXME(sky): Remove this.
    RenderBlock::styleDidChange(diff, oldStyle);
}

void RenderBlockFlow::updateStaticInlinePositionForChild(RenderBox* child, LayoutUnit logicalTop)
{
    if (child->style()->isOriginalDisplayInlineType())
        setStaticInlinePositionForChild(child, startAlignedOffsetForLine(logicalTop, false));
    else
        setStaticInlinePositionForChild(child, startOffsetForContent());
}

void RenderBlockFlow::setStaticInlinePositionForChild(RenderBox* child, LayoutUnit inlinePosition)
{
    child->layer()->setStaticInlinePosition(inlinePosition);
}

void RenderBlockFlow::addChild(RenderObject* newChild, RenderObject* beforeChild)
{
    RenderBlock::addChild(newChild, beforeChild);
}

void RenderBlockFlow::moveAllChildrenIncludingFloatsTo(RenderBlock* toBlock, bool fullRemoveInsert)
{
    // FIXME(sky): Merge this into callers.
    RenderBlockFlow* toBlockFlow = toRenderBlockFlow(toBlock);
    moveAllChildrenTo(toBlockFlow, fullRemoveInsert);
}

void RenderBlockFlow::invalidatePaintForOverhangingFloats(bool paintAllDescendants)
{
    // FIXME(sky): Remove this.
}

void RenderBlockFlow::invalidatePaintForOverflow()
{
    // FIXME: We could tighten up the left and right invalidation points if we let layoutInlineChildren fill them in based off the particular lines
    // it had to lay out. We wouldn't need the hasOverflowClip() hack in that case either.
    LayoutUnit paintInvalidationLogicalLeft = logicalLeftVisualOverflow();
    LayoutUnit paintInvalidationLogicalRight = logicalRightVisualOverflow();
    if (hasOverflowClip()) {
        // If we have clipped overflow, we should use layout overflow as well, since visual overflow from lines didn't propagate to our block's overflow.
        // Note the old code did this as well but even for overflow:visible. The addition of hasOverflowClip() at least tightens up the hack a bit.
        // layoutInlineChildren should be patched to compute the entire paint invalidation rect.
        paintInvalidationLogicalLeft = std::min(paintInvalidationLogicalLeft, logicalLeftLayoutOverflow());
        paintInvalidationLogicalRight = std::max(paintInvalidationLogicalRight, logicalRightLayoutOverflow());
    }

    LayoutRect paintInvalidationRect = LayoutRect(paintInvalidationLogicalLeft, m_paintInvalidationLogicalTop, paintInvalidationLogicalRight - paintInvalidationLogicalLeft, m_paintInvalidationLogicalBottom - m_paintInvalidationLogicalTop);

    if (hasOverflowClip()) {
        // Adjust the paint invalidation rect for scroll offset
        paintInvalidationRect.move(-scrolledContentOffset());

        // Don't allow this rect to spill out of our overflow box.
        paintInvalidationRect.intersect(LayoutRect(LayoutPoint(), size()));
    }

    // Make sure the rect is still non-empty after intersecting for overflow above
    if (!paintInvalidationRect.isEmpty()) {
        // Hits in media/event-attributes.html
        DisableCompositingQueryAsserts disabler;

        invalidatePaintRectangle(paintInvalidationRect); // We need to do a partial paint invalidation of our content.
    }

    m_paintInvalidationLogicalTop = 0;
    m_paintInvalidationLogicalBottom = 0;
}

void RenderBlockFlow::paintFloats(PaintInfo& paintInfo, const LayoutPoint& paintOffset, bool preservePhase)
{
    // FIXME(sky): Remove this.
}

void RenderBlockFlow::clearFloats(EClear clear)
{
    // FIXME(sky): Remove this.
}

LayoutPoint RenderBlockFlow::flipFloatForWritingModeForChild(const FloatingObject* child, const LayoutPoint& point) const
{
    // FIXME(sky): Remove this.
    return LayoutPoint();
}

LayoutUnit RenderBlockFlow::logicalLeftOffsetForPositioningFloat(LayoutUnit logicalTop, LayoutUnit fixedOffset, bool applyTextIndent, LayoutUnit* heightRemaining) const
{
    // FIXME(sky): Remove this.
    LayoutUnit offset = fixedOffset;
    return adjustLogicalLeftOffsetForLine(offset, applyTextIndent);
}

LayoutUnit RenderBlockFlow::logicalRightOffsetForPositioningFloat(LayoutUnit logicalTop, LayoutUnit fixedOffset, bool applyTextIndent, LayoutUnit* heightRemaining) const
{
    // FIXME(sky): Remove this.
    LayoutUnit offset = fixedOffset;
    return adjustLogicalRightOffsetForLine(offset, applyTextIndent);
}

LayoutUnit RenderBlockFlow::adjustLogicalLeftOffsetForLine(LayoutUnit offsetFromFloats, bool applyTextIndent) const
{
    LayoutUnit left = offsetFromFloats;

    if (applyTextIndent && style()->isLeftToRightDirection())
        left += textIndentOffset();

    return left;
}

LayoutUnit RenderBlockFlow::adjustLogicalRightOffsetForLine(LayoutUnit offsetFromFloats, bool applyTextIndent) const
{
    LayoutUnit right = offsetFromFloats;

    if (applyTextIndent && !style()->isLeftToRightDirection())
        right -= textIndentOffset();

    return right;
}

LayoutPoint RenderBlockFlow::computeLogicalLocationForFloat(const FloatingObject* floatingObject, LayoutUnit logicalTopOffset) const
{
    // FIXME(sky): Remove this.
    return LayoutPoint();
}

bool RenderBlockFlow::positionNewFloats()
{
    // FIXME(sky): Remove this.
    return false;
}

bool RenderBlockFlow::hasOverhangingFloat(RenderBox* renderer)
{
    // FIXME(sky): Remove this.
    return false;
}

void RenderBlockFlow::addIntrudingFloats(RenderBlockFlow* prev, LayoutUnit logicalLeftOffset, LayoutUnit logicalTopOffset)
{
    // FIXME(sky): Remove this.
}

void RenderBlockFlow::addOverhangingFloats(RenderBlockFlow* child, bool makeChildPaintOtherFloats)
{
    // FIXME(sky): Remove this.
}

bool RenderBlockFlow::hitTestFloats(const HitTestRequest& request, HitTestResult& result, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset)
{
    // FIXME(sky): Remove this.
    return false;
}

void RenderBlockFlow::adjustForBorderFit(LayoutUnit x, LayoutUnit& left, LayoutUnit& right) const
{
    // We don't deal with relative positioning. Our assumption is that you shrink to fit the lines without accounting
    // for either overflow or translations via relative positioning.
    if (childrenInline()) {
        for (RootInlineBox* box = firstRootBox(); box; box = box->nextRootBox()) {
            if (box->firstChild())
                left = std::min(left, x + static_cast<LayoutUnit>(box->firstChild()->x()));
            if (box->lastChild())
                right = std::max(right, x + static_cast<LayoutUnit>(ceilf(box->lastChild()->logicalRight())));
        }
    } else {
        for (RenderBox* obj = firstChildBox(); obj; obj = obj->nextSiblingBox()) {
            if (!obj->isFloatingOrOutOfFlowPositioned()) {
                if (obj->isRenderBlockFlow() && !obj->hasOverflowClip()) {
                    toRenderBlockFlow(obj)->adjustForBorderFit(x + obj->x(), left, right);
                } else {
                    // We are a replaced element or some kind of non-block-flow object.
                    left = std::min(left, x + obj->x());
                    right = std::max(right, x + obj->x() + obj->width());
                }
            }
        }
    }
}

void RenderBlockFlow::fitBorderToLinesIfNeeded()
{
    if (style()->borderFit() == BorderFitBorder || hasOverrideWidth())
        return;

    // Walk any normal flow lines to snugly fit.
    LayoutUnit left = LayoutUnit::max();
    LayoutUnit right = LayoutUnit::min();
    LayoutUnit oldWidth = contentWidth();
    adjustForBorderFit(0, left, right);

    // Clamp to our existing edges. We can never grow. We only shrink.
    LayoutUnit leftEdge = borderLeft() + paddingLeft();
    LayoutUnit rightEdge = leftEdge + oldWidth;
    left = std::min(rightEdge, std::max(leftEdge, left));
    right = std::max(left, std::min(rightEdge, right));

    LayoutUnit newContentWidth = right - left;
    if (newContentWidth == oldWidth)
        return;

    setOverrideLogicalContentWidth(newContentWidth);
    layoutBlock(false);
    clearOverrideLogicalContentWidth();
}

LayoutUnit RenderBlockFlow::logicalLeftFloatOffsetForLine(LayoutUnit logicalTop, LayoutUnit fixedOffset, LayoutUnit logicalHeight) const
{
    // FIXME(sky): remove this.
    return fixedOffset;
}

LayoutUnit RenderBlockFlow::logicalRightFloatOffsetForLine(LayoutUnit logicalTop, LayoutUnit fixedOffset, LayoutUnit logicalHeight) const
{
    // FIXME(sky): remove this.
    return fixedOffset;
}

GapRects RenderBlockFlow::inlineSelectionGaps(RenderBlock* rootBlock, const LayoutPoint& rootBlockPhysicalPosition, const LayoutSize& offsetFromRootBlock,
    LayoutUnit& lastLogicalTop, LayoutUnit& lastLogicalLeft, LayoutUnit& lastLogicalRight, const PaintInfo* paintInfo)
{
    GapRects result;

    bool containsStart = selectionState() == SelectionStart || selectionState() == SelectionBoth;

    if (!firstLineBox()) {
        if (containsStart) {
            // Go ahead and update our lastLogicalTop to be the bottom of the block.  <hr>s or empty blocks with height can trip this
            // case.
            lastLogicalTop = rootBlock->blockDirectionOffset(offsetFromRootBlock) + logicalHeight();
            lastLogicalLeft = logicalLeftSelectionOffset(rootBlock, logicalHeight());
            lastLogicalRight = logicalRightSelectionOffset(rootBlock, logicalHeight());
        }
        return result;
    }

    RootInlineBox* lastSelectedLine = 0;
    RootInlineBox* curr;
    for (curr = firstRootBox(); curr && !curr->hasSelectedChildren(); curr = curr->nextRootBox()) { }

    // Now paint the gaps for the lines.
    for (; curr && curr->hasSelectedChildren(); curr = curr->nextRootBox()) {
        LayoutUnit selTop =  curr->selectionTopAdjustedForPrecedingBlock();
        LayoutUnit selHeight = curr->selectionHeightAdjustedForPrecedingBlock();

        if (!containsStart && !lastSelectedLine && selectionState() != SelectionStart && selectionState() != SelectionBoth) {
            result.uniteCenter(blockSelectionGap(rootBlock, rootBlockPhysicalPosition, offsetFromRootBlock, lastLogicalTop,
                lastLogicalLeft, lastLogicalRight, selTop, paintInfo));
        }

        LayoutRect logicalRect(curr->logicalLeft(), selTop, curr->logicalWidth(), selTop + selHeight);
        logicalRect.move(offsetFromRootBlock);
        LayoutRect physicalRect = rootBlock->logicalRectToPhysicalRect(rootBlockPhysicalPosition, logicalRect);
        if (!paintInfo || (physicalRect.y() < paintInfo->rect.maxY() && physicalRect.maxY() > paintInfo->rect.y()))
            result.unite(curr->lineSelectionGap(rootBlock, rootBlockPhysicalPosition, offsetFromRootBlock, selTop, selHeight, paintInfo));

        lastSelectedLine = curr;
    }

    if (containsStart && !lastSelectedLine) {
        // VisibleSelection must start just after our last line.
        lastSelectedLine = lastRootBox();
    }

    if (lastSelectedLine && selectionState() != SelectionEnd && selectionState() != SelectionBoth) {
        // Go ahead and update our lastY to be the bottom of the last selected line.
        lastLogicalTop = rootBlock->blockDirectionOffset(offsetFromRootBlock) + lastSelectedLine->selectionBottom();
        lastLogicalLeft = logicalLeftSelectionOffset(rootBlock, lastSelectedLine->selectionBottom());
        lastLogicalRight = logicalRightSelectionOffset(rootBlock, lastSelectedLine->selectionBottom());
    }
    return result;
}

bool RenderBlockFlow::avoidsFloats() const
{
    return RenderBox::avoidsFloats();
}

LayoutUnit RenderBlockFlow::logicalLeftSelectionOffset(RenderBlock* rootBlock, LayoutUnit position)
{
    LayoutUnit logicalLeft = logicalLeftOffsetForLine(position, false);
    if (logicalLeft == logicalLeftOffsetForContent())
        return RenderBlock::logicalLeftSelectionOffset(rootBlock, position);

    RenderBlock* cb = this;
    while (cb != rootBlock) {
        logicalLeft += cb->logicalLeft();
        cb = cb->containingBlock();
    }
    return logicalLeft;
}

LayoutUnit RenderBlockFlow::logicalRightSelectionOffset(RenderBlock* rootBlock, LayoutUnit position)
{
    LayoutUnit logicalRight = logicalRightOffsetForLine(position, false);
    if (logicalRight == logicalRightOffsetForContent())
        return RenderBlock::logicalRightSelectionOffset(rootBlock, position);

    RenderBlock* cb = this;
    while (cb != rootBlock) {
        logicalRight += cb->logicalLeft();
        cb = cb->containingBlock();
    }
    return logicalRight;
}

RootInlineBox* RenderBlockFlow::createRootInlineBox()
{
    return new RootInlineBox(*this);
}

RenderBlockFlow::RenderBlockFlowRareData& RenderBlockFlow::ensureRareData()
{
    if (m_rareData)
        return *m_rareData;

    m_rareData = adoptPtr(new RenderBlockFlowRareData(this));
    return *m_rareData;
}

} // namespace blink
