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

RenderBlockFlow::RenderBlockFlow(ContainerNode* node)
    : RenderBlock(node)
{
    setChildrenInline(true);
}

RenderBlockFlow::~RenderBlockFlow()
{
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

void RenderBlockFlow::layoutBlock(bool relayoutChildren)
{
    ASSERT(needsLayout());
    ASSERT(isInlineBlock() || !isInline());

    if (!relayoutChildren && simplifiedLayout())
        return;

    SubtreeLayoutScope layoutScope(*this);

    layoutBlockFlow(relayoutChildren, layoutScope);

    updateLayerTransformAfterLayout();

    // Update our scroll information if we're overflow:auto/scroll/hidden now that we know if
    // we overflow or not.
    updateScrollInfoAfterLayout();

    if (m_paintInvalidationLogicalTop != m_paintInvalidationLogicalBottom)
        setShouldInvalidateOverflowForPaint(true);

    clearNeedsLayout();
}

inline void RenderBlockFlow::layoutBlockFlow(bool relayoutChildren, SubtreeLayoutScope& layoutScope)
{
    LayoutUnit oldLeft = logicalLeft();
    bool logicalWidthChanged = updateLogicalWidthAndColumnWidth();
    relayoutChildren |= logicalWidthChanged;

    LayoutState state(*this, locationOffset(), logicalWidthChanged);

    LayoutUnit beforeEdge = borderBefore() + paddingBefore();
    LayoutUnit afterEdge = borderAfter() + paddingAfter();
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

    LayoutUnit oldClientAfterEdge = clientLogicalBottom();

    updateLogicalHeight();

    if (previousHeight != logicalHeight())
        relayoutChildren = true;

    layoutPositionedObjects(relayoutChildren || isDocumentElement(), oldLeft != logicalLeft() ? ForcedLayoutAfterContainingBlockMoved : DefaultLayout);

    // Add overflow from children (unless we're multi-column, since in that case all our child overflow is clipped anyway).
    computeOverflow(oldClientAfterEdge);
}

void RenderBlockFlow::determineLogicalLeftPositionForChild(RenderBox* child)
{
    LayoutUnit startPosition = borderStart() + paddingStart();
    LayoutUnit totalAvailableLogicalWidth = borderAndPaddingLogicalWidth() + availableLogicalWidth();

    LayoutUnit childMarginStart = marginStartForChild(child);
    LayoutUnit newPosition = startPosition + childMarginStart;

    // If the child has an offset from the content edge to avoid floats then use that, otherwise let any negative
    // margin pull it back over the content edge or any positive margin push it out.
    if (child->style()->marginStartUsing(style()).isAuto())
        newPosition = std::max(newPosition, childMarginStart);

    child->setX(style()->isLeftToRightDirection() ? newPosition : totalAvailableLogicalWidth - newPosition - logicalWidthForChild(child));
}

void RenderBlockFlow::layoutBlockChild(RenderBox* child)
{
    child->computeAndSetBlockDirectionMargins(this);
    LayoutUnit marginBefore = marginBeforeForChild(child);
    child->setY(logicalHeight() + marginBefore);
    child->layoutIfNeeded();
    determineLogicalLeftPositionForChild(child);
    setLogicalHeight(logicalHeight() + marginBefore + logicalHeightForChild(child) + marginAfterForChild(child));
}

void RenderBlockFlow::layoutBlockChildren(bool relayoutChildren, SubtreeLayoutScope& layoutScope, LayoutUnit beforeEdge, LayoutUnit afterEdge)
{
    dirtyForLayoutFromPercentageHeightDescendants(layoutScope);

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
            adjustPositionedBlock(child);
            continue;
        }

        // Lay out the child.
        layoutBlockChild(child);
        lastNormalFlowChild = child;
    }

    // Negative margins can cause our height to shrink below our minimal height (border/padding).
    // If this happens, ensure that the computed height is increased to the minimal height.
    setLogicalHeight(std::max(logicalHeight() + afterEdge, beforeEdge + afterEdge));
}

void RenderBlockFlow::adjustPositionedBlock(RenderBox* child)
{
    bool hasStaticBlockPosition = child->style()->hasStaticBlockPosition();

    LayoutUnit logicalTop = logicalHeight();
    updateStaticInlinePositionForChild(child);

    RenderLayer* childLayer = child->layer();
    if (childLayer->staticBlockPosition() != logicalTop) {
        childLayer->setStaticBlockPosition(logicalTop);
        if (hasStaticBlockPosition)
            child->setChildNeedsLayout(MarkOnlyThis);
    }
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

void RenderBlockFlow::updateStaticInlinePositionForChild(RenderBox* child)
{
    if (child->style()->isOriginalDisplayInlineType())
        setStaticInlinePositionForChild(child, startAlignedOffsetForLine(false));
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

LayoutUnit RenderBlockFlow::logicalLeftSelectionOffset(RenderBlock* rootBlock, LayoutUnit position)
{
    LayoutUnit logicalLeft = logicalLeftOffsetForLine(false);
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
    LayoutUnit logicalRight = logicalRightOffsetForLine(false);
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

} // namespace blink
