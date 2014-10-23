/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2007 David Smith (catfish.man@gmail.com)
 * Copyright (C) 2003-2013 Apple Inc. All rights reserved.
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
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

#ifndef RenderBlockFlow_h
#define RenderBlockFlow_h

#include "core/rendering/FloatingObjects.h"
#include "core/rendering/RenderBlock.h"
#include "core/rendering/line/TrailingObjects.h"
#include "core/rendering/style/RenderStyleConstants.h"

namespace blink {

class MarginInfo;
class LineBreaker;
class LineWidth;

class RenderBlockFlow : public RenderBlock {
public:
    explicit RenderBlockFlow(ContainerNode*);
    virtual ~RenderBlockFlow();
    virtual void trace(Visitor*) OVERRIDE;

    static RenderBlockFlow* createAnonymous(Document*);

    virtual bool isRenderBlockFlow() const OVERRIDE FINAL { return true; }

    virtual void layoutBlock(bool relayoutChildren) OVERRIDE;

    virtual void computeOverflow(LayoutUnit oldClientAfterEdge, bool recomputeFloats = false) OVERRIDE;

    virtual void deleteLineBoxTree() OVERRIDE FINAL;

    LayoutUnit availableLogicalWidthForLine(LayoutUnit position, bool shouldIndentText, LayoutUnit logicalHeight = 0) const
    {
        return max<LayoutUnit>(0, logicalRightOffsetForLine(position, shouldIndentText, logicalHeight) - logicalLeftOffsetForLine(position, shouldIndentText, logicalHeight));
    }
    LayoutUnit logicalRightOffsetForLine(LayoutUnit position, bool shouldIndentText, LayoutUnit logicalHeight = 0) const
    {
        return logicalRightOffsetForLine(position, logicalRightOffsetForContent(), shouldIndentText, logicalHeight);
    }
    LayoutUnit logicalLeftOffsetForLine(LayoutUnit position, bool shouldIndentText, LayoutUnit logicalHeight = 0) const
    {
        return logicalLeftOffsetForLine(position, logicalLeftOffsetForContent(), shouldIndentText, logicalHeight);
    }
    LayoutUnit startOffsetForLine(LayoutUnit position, bool shouldIndentText, LayoutUnit logicalHeight = 0) const
    {
        return style()->isLeftToRightDirection() ? logicalLeftOffsetForLine(position, shouldIndentText, logicalHeight)
            : logicalWidth() - logicalRightOffsetForLine(position, shouldIndentText, logicalHeight);
    }
    LayoutUnit endOffsetForLine(LayoutUnit position, bool shouldIndentText, LayoutUnit logicalHeight = 0) const
    {
        return !style()->isLeftToRightDirection() ? logicalLeftOffsetForLine(position, shouldIndentText, logicalHeight)
            : logicalWidth() - logicalRightOffsetForLine(position, shouldIndentText, logicalHeight);
    }

    // FIXME-BLOCKFLOW: Move this into RenderBlockFlow once there are no calls
    // in RenderBlock. http://crbug.com/393945, http://crbug.com/302024
    using RenderBlock::lineBoxes;
    using RenderBlock::firstLineBox;
    using RenderBlock::lastLineBox;
    using RenderBlock::firstRootBox;
    using RenderBlock::lastRootBox;

    virtual LayoutUnit logicalLeftSelectionOffset(RenderBlock* rootBlock, LayoutUnit position) OVERRIDE;
    virtual LayoutUnit logicalRightSelectionOffset(RenderBlock* rootBlock, LayoutUnit position) OVERRIDE;

    RootInlineBox* createAndAppendRootInlineBox();

    void markAllDescendantsWithFloatsForLayout(RenderBox* floatToRemove = 0, bool inLayout = true);
    void markSiblingsWithFloatsForLayout(RenderBox* floatToRemove = 0);

    bool containsFloats() const { return m_floatingObjects && !m_floatingObjects->set().isEmpty(); }
    bool containsFloat(RenderBox*) const;

    void removeFloatingObjects();

    virtual void addChild(RenderObject* newChild, RenderObject* beforeChild = 0) OVERRIDE;

    void moveAllChildrenIncludingFloatsTo(RenderBlock* toBlock, bool fullRemoveInsert);

    bool generatesLineBoxesForInlineChild(RenderObject*);

    LayoutUnit logicalTopForFloat(const FloatingObject* floatingObject) const { return isHorizontalWritingMode() ? floatingObject->y() : floatingObject->x(); }
    LayoutUnit logicalBottomForFloat(const FloatingObject* floatingObject) const { return isHorizontalWritingMode() ? floatingObject->maxY() : floatingObject->maxX(); }
    LayoutUnit logicalLeftForFloat(const FloatingObject* floatingObject) const { return isHorizontalWritingMode() ? floatingObject->x() : floatingObject->y(); }
    LayoutUnit logicalRightForFloat(const FloatingObject* floatingObject) const { return isHorizontalWritingMode() ? floatingObject->maxX() : floatingObject->maxY(); }
    LayoutUnit logicalWidthForFloat(const FloatingObject* floatingObject) const { return isHorizontalWritingMode() ? floatingObject->width() : floatingObject->height(); }
    LayoutUnit logicalHeightForFloat(const FloatingObject* floatingObject) const { return isHorizontalWritingMode() ? floatingObject->height() : floatingObject->width(); }
    LayoutSize logicalSizeForFloat(const FloatingObject* floatingObject) const { return isHorizontalWritingMode() ? LayoutSize(floatingObject->width(), floatingObject->height()) : LayoutSize(floatingObject->height(), floatingObject->width()); }

    int pixelSnappedLogicalTopForFloat(const FloatingObject* floatingObject) const { return isHorizontalWritingMode() ? floatingObject->frameRect().pixelSnappedY() : floatingObject->frameRect().pixelSnappedX(); }
    int pixelSnappedLogicalBottomForFloat(const FloatingObject* floatingObject) const { return isHorizontalWritingMode() ? floatingObject->frameRect().pixelSnappedMaxY() : floatingObject->frameRect().pixelSnappedMaxX(); }
    int pixelSnappedLogicalLeftForFloat(const FloatingObject* floatingObject) const { return isHorizontalWritingMode() ? floatingObject->frameRect().pixelSnappedX() : floatingObject->frameRect().pixelSnappedY(); }
    int pixelSnappedLogicalRightForFloat(const FloatingObject* floatingObject) const { return isHorizontalWritingMode() ? floatingObject->frameRect().pixelSnappedMaxX() : floatingObject->frameRect().pixelSnappedMaxY(); }

    void setLogicalTopForFloat(FloatingObject* floatingObject, LayoutUnit logicalTop)
    {
        if (isHorizontalWritingMode())
            floatingObject->setY(logicalTop);
        else
            floatingObject->setX(logicalTop);
    }
    void setLogicalLeftForFloat(FloatingObject* floatingObject, LayoutUnit logicalLeft)
    {
        if (isHorizontalWritingMode())
            floatingObject->setX(logicalLeft);
        else
            floatingObject->setY(logicalLeft);
    }
    void setLogicalHeightForFloat(FloatingObject* floatingObject, LayoutUnit logicalHeight)
    {
        if (isHorizontalWritingMode())
            floatingObject->setHeight(logicalHeight);
        else
            floatingObject->setWidth(logicalHeight);
    }
    void setLogicalWidthForFloat(FloatingObject* floatingObject, LayoutUnit logicalWidth)
    {
        if (isHorizontalWritingMode())
            floatingObject->setWidth(logicalWidth);
        else
            floatingObject->setHeight(logicalWidth);
    }

    LayoutUnit startAlignedOffsetForLine(LayoutUnit position, bool shouldIndentText);

    void setStaticInlinePositionForChild(RenderBox*, LayoutUnit inlinePosition);
    void updateStaticInlinePositionForChild(RenderBox*, LayoutUnit logicalTop);

    static bool shouldSkipCreatingRunsForObject(RenderObject* obj)
    {
        return obj->isFloating() || (obj->isOutOfFlowPositioned() && !obj->style()->isOriginalDisplayInlineType() && !obj->container()->isRenderInline());
    }

    void addOverflowFromInlineChildren();

    // FIXME: This should be const to avoid a const_cast, but can modify child dirty bits and RenderCombineText
    void computeInlinePreferredLogicalWidths(LayoutUnit& minLogicalWidth, LayoutUnit& maxLogicalWidth);

    GapRects inlineSelectionGaps(RenderBlock* rootBlock, const LayoutPoint& rootBlockPhysicalPosition, const LayoutSize& offsetFromRootBlock,
        LayoutUnit& lastLogicalTop, LayoutUnit& lastLogicalLeft, LayoutUnit& lastLogicalRight, const PaintInfo*);

    virtual bool avoidsFloats() const OVERRIDE;

protected:
    void rebuildFloatsFromIntruding();
    void layoutInlineChildren(bool relayoutChildren, LayoutUnit& paintInvalidationLogicalTop, LayoutUnit& paintInvalidationLogicalBottom, LayoutUnit afterEdge);

    void createFloatingObjects();

    virtual void styleWillChange(StyleDifference, const RenderStyle& newStyle) OVERRIDE;
    virtual void styleDidChange(StyleDifference, const RenderStyle* oldStyle) OVERRIDE;

    void addOverflowFromFloats();

    LayoutUnit logicalRightOffsetForLine(LayoutUnit logicalTop, LayoutUnit fixedOffset, bool applyTextIndent, LayoutUnit logicalHeight = 0) const
    {
        return adjustLogicalRightOffsetForLine(logicalRightFloatOffsetForLine(logicalTop, fixedOffset, logicalHeight), applyTextIndent);
    }
    LayoutUnit logicalLeftOffsetForLine(LayoutUnit logicalTop, LayoutUnit fixedOffset, bool applyTextIndent, LayoutUnit logicalHeight = 0) const
    {
        return adjustLogicalLeftOffsetForLine(logicalLeftFloatOffsetForLine(logicalTop, fixedOffset, logicalHeight), applyTextIndent);
    }

    virtual bool updateLogicalWidthAndColumnWidth() OVERRIDE;

    void setLogicalLeftForChild(RenderBox* child, LayoutUnit logicalLeft);
    void setLogicalTopForChild(RenderBox* child, LayoutUnit logicalTop);
    void determineLogicalLeftPositionForChild(RenderBox* child);

private:
    bool layoutBlockFlow(bool relayoutChildren, SubtreeLayoutScope&);
    void layoutBlockChildren(bool relayoutChildren, SubtreeLayoutScope&, LayoutUnit beforeEdge, LayoutUnit afterEdge);

    void layoutBlockChild(RenderBox* child, MarginInfo&, LayoutUnit& previousFloatLogicalBottom);
    void adjustPositionedBlock(RenderBox* child, const MarginInfo&);
    void adjustFloatingBlock(const MarginInfo&);

    LayoutPoint flipFloatForWritingModeForChild(const FloatingObject*, const LayoutPoint&) const;

    LayoutUnit xPositionForFloatIncludingMargin(const FloatingObject* child) const
    {
        if (isHorizontalWritingMode())
            return child->x() + child->renderer()->marginLeft();

        return child->x() + marginBeforeForChild(child->renderer());
    }

    LayoutUnit yPositionForFloatIncludingMargin(const FloatingObject* child) const
    {
        if (isHorizontalWritingMode())
            return child->y() + marginBeforeForChild(child->renderer());

        return child->y() + child->renderer()->marginTop();
    }

    LayoutPoint computeLogicalLocationForFloat(const FloatingObject*, LayoutUnit logicalTopOffset) const;

    FloatingObject* insertFloatingObject(RenderBox*);
    void removeFloatingObject(RenderBox*);
    void removeFloatingObjectsBelow(FloatingObject*, int logicalOffset);

    // Called from lineWidth, to position the floats added in the last line.
    // Returns true if and only if it has positioned any floats.
    bool positionNewFloats();

    LayoutUnit getClearDelta(RenderBox* child, LayoutUnit yPos);

    bool hasOverhangingFloats() { return parent() && containsFloats() && lowestFloatLogicalBottom() > logicalHeight(); }
    bool hasOverhangingFloat(RenderBox*);
    void addIntrudingFloats(RenderBlockFlow* prev, LayoutUnit xoffset, LayoutUnit yoffset);
    void addOverhangingFloats(RenderBlockFlow* child, bool makeChildPaintOtherFloats);

    LayoutUnit lowestFloatLogicalBottom(FloatingObject::Type = FloatingObject::FloatLeftRight) const;
    LayoutUnit nextFloatLogicalBottomBelow(LayoutUnit, ShapeOutsideFloatOffsetMode = ShapeOutsideFloatMarginBoxOffset) const;

    virtual bool hitTestFloats(const HitTestRequest&, HitTestResult&, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset) OVERRIDE FINAL;

    virtual void invalidatePaintForOverhangingFloats(bool paintAllDescendants) OVERRIDE FINAL;
    virtual void invalidatePaintForOverflow() OVERRIDE FINAL;
    virtual void paintFloats(PaintInfo&, const LayoutPoint&, bool preservePhase = false) OVERRIDE FINAL;
    virtual void clipOutFloatingObjects(RenderBlock*, const PaintInfo*, const LayoutPoint&, const LayoutSize&) OVERRIDE;
    void clearFloats(EClear);

    LayoutUnit logicalRightFloatOffsetForLine(LayoutUnit logicalTop, LayoutUnit fixedOffset, LayoutUnit logicalHeight) const;
    LayoutUnit logicalLeftFloatOffsetForLine(LayoutUnit logicalTop, LayoutUnit fixedOffset, LayoutUnit logicalHeight) const;

    LayoutUnit logicalRightOffsetForPositioningFloat(LayoutUnit logicalTop, LayoutUnit fixedOffset, bool applyTextIndent, LayoutUnit* heightRemaining) const;
    LayoutUnit logicalLeftOffsetForPositioningFloat(LayoutUnit logicalTop, LayoutUnit fixedOffset, bool applyTextIndent, LayoutUnit* heightRemaining) const;

    LayoutUnit adjustLogicalRightOffsetForLine(LayoutUnit offsetFromFloats, bool applyTextIndent) const;
    LayoutUnit adjustLogicalLeftOffsetForLine(LayoutUnit offsetFromFloats, bool applyTextIndent) const;

    void fitBorderToLinesIfNeeded(); // Shrink the box in which the border paints if border-fit is set.
    void adjustForBorderFit(LayoutUnit x, LayoutUnit& left, LayoutUnit& right) const; // Helper function for borderFitAdjust

    virtual RootInlineBox* createRootInlineBox(); // Subclassed by SVG

    void updateLogicalWidthForAlignment(const ETextAlign&, const RootInlineBox*, BidiRun* trailingSpaceRun, float& logicalLeft, float& totalLogicalWidth, float& availableLogicalWidth, unsigned expansionOpportunityCount);

    bool shouldBreakAtLineToAvoidWidow() const { return m_rareData && m_rareData->m_lineBreakToAvoidWidow >= 0; }
    void clearShouldBreakAtLineToAvoidWidow() const;
    int lineBreakToAvoidWidow() const { return m_rareData ? m_rareData->m_lineBreakToAvoidWidow : -1; }
    void setBreakAtLineToAvoidWidow(int);
    void clearDidBreakAtLineToAvoidWidow();
    void setDidBreakAtLineToAvoidWidow();
    bool didBreakAtLineToAvoidWidow() const { return m_rareData && m_rareData->m_didBreakAtLineToAvoidWidow; }

public:
    struct FloatWithRect {
        FloatWithRect(RenderBox* f)
            : object(f)
            , rect(LayoutRect(f->x() - f->marginLeft(), f->y() - f->marginTop(), f->width() + f->marginWidth(), f->height() + f->marginHeight()))
            , everHadLayout(f->everHadLayout())
        {
        }

        RenderBox* object;
        LayoutRect rect;
        bool everHadLayout;
    };

    class MarginValues {
    public:
        MarginValues(LayoutUnit beforePos, LayoutUnit beforeNeg, LayoutUnit afterPos, LayoutUnit afterNeg)
            : m_positiveMarginBefore(beforePos)
            , m_negativeMarginBefore(beforeNeg)
            , m_positiveMarginAfter(afterPos)
            , m_negativeMarginAfter(afterNeg)
        { }

        LayoutUnit positiveMarginBefore() const { return m_positiveMarginBefore; }
        LayoutUnit negativeMarginBefore() const { return m_negativeMarginBefore; }
        LayoutUnit positiveMarginAfter() const { return m_positiveMarginAfter; }
        LayoutUnit negativeMarginAfter() const { return m_negativeMarginAfter; }

        void setPositiveMarginBefore(LayoutUnit pos) { m_positiveMarginBefore = pos; }
        void setNegativeMarginBefore(LayoutUnit neg) { m_negativeMarginBefore = neg; }
        void setPositiveMarginAfter(LayoutUnit pos) { m_positiveMarginAfter = pos; }
        void setNegativeMarginAfter(LayoutUnit neg) { m_negativeMarginAfter = neg; }

    private:
        LayoutUnit m_positiveMarginBefore;
        LayoutUnit m_negativeMarginBefore;
        LayoutUnit m_positiveMarginAfter;
        LayoutUnit m_negativeMarginAfter;
    };
    MarginValues marginValuesForChild(RenderBox* child) const;

    // Allocated only when some of these fields have non-default values
    struct RenderBlockFlowRareData : public NoBaseWillBeGarbageCollected<RenderBlockFlowRareData> {
        WTF_MAKE_NONCOPYABLE(RenderBlockFlowRareData); WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
    public:
        RenderBlockFlowRareData(const RenderBlockFlow* block)
            : m_margins(positiveMarginBeforeDefault(block), negativeMarginBeforeDefault(block), positiveMarginAfterDefault(block), negativeMarginAfterDefault(block))
            , m_lineBreakToAvoidWidow(-1)
            , m_didBreakAtLineToAvoidWidow(false)
            , m_discardMarginBefore(false)
            , m_discardMarginAfter(false)
        {
        }
        void trace(Visitor*);

        static LayoutUnit positiveMarginBeforeDefault(const RenderBlockFlow* block)
        {
            return std::max<LayoutUnit>(block->marginBefore(), 0);
        }
        static LayoutUnit negativeMarginBeforeDefault(const RenderBlockFlow* block)
        {
            return std::max<LayoutUnit>(-block->marginBefore(), 0);
        }
        static LayoutUnit positiveMarginAfterDefault(const RenderBlockFlow* block)
        {
            return std::max<LayoutUnit>(block->marginAfter(), 0);
        }
        static LayoutUnit negativeMarginAfterDefault(const RenderBlockFlow* block)
        {
            return std::max<LayoutUnit>(-block->marginAfter(), 0);
        }

        MarginValues m_margins;

        int m_lineBreakToAvoidWidow;
        bool m_didBreakAtLineToAvoidWidow : 1;
        bool m_discardMarginBefore : 1;
        bool m_discardMarginAfter : 1;
    };
    LayoutUnit marginOffsetForSelfCollapsingBlock();

protected:
    LayoutUnit maxPositiveMarginBefore() const { return m_rareData ? m_rareData->m_margins.positiveMarginBefore() : RenderBlockFlowRareData::positiveMarginBeforeDefault(this); }
    LayoutUnit maxNegativeMarginBefore() const { return m_rareData ? m_rareData->m_margins.negativeMarginBefore() : RenderBlockFlowRareData::negativeMarginBeforeDefault(this); }
    LayoutUnit maxPositiveMarginAfter() const { return m_rareData ? m_rareData->m_margins.positiveMarginAfter() : RenderBlockFlowRareData::positiveMarginAfterDefault(this); }
    LayoutUnit maxNegativeMarginAfter() const { return m_rareData ? m_rareData->m_margins.negativeMarginAfter() : RenderBlockFlowRareData::negativeMarginAfterDefault(this); }

    void setMaxMarginBeforeValues(LayoutUnit pos, LayoutUnit neg);
    void setMaxMarginAfterValues(LayoutUnit pos, LayoutUnit neg);

    void setMustDiscardMarginBefore(bool = true);
    void setMustDiscardMarginAfter(bool = true);

    bool mustDiscardMarginBefore() const;
    bool mustDiscardMarginAfter() const;

    bool mustDiscardMarginBeforeForChild(const RenderBox*) const;
    bool mustDiscardMarginAfterForChild(const RenderBox*) const;

    bool mustSeparateMarginBeforeForChild(const RenderBox*) const;
    bool mustSeparateMarginAfterForChild(const RenderBox*) const;

    void initMaxMarginValues()
    {
        if (m_rareData) {
            m_rareData->m_margins = MarginValues(RenderBlockFlowRareData::positiveMarginBeforeDefault(this) , RenderBlockFlowRareData::negativeMarginBeforeDefault(this),
                RenderBlockFlowRareData::positiveMarginAfterDefault(this), RenderBlockFlowRareData::negativeMarginAfterDefault(this));

            m_rareData->m_discardMarginBefore = false;
            m_rareData->m_discardMarginAfter = false;
        }
    }

    virtual ETextAlign textAlignmentForLine(bool endsWithSoftBreak) const;
private:
    virtual LayoutUnit collapsedMarginBefore() const OVERRIDE FINAL { return maxPositiveMarginBefore() - maxNegativeMarginBefore(); }
    virtual LayoutUnit collapsedMarginAfter() const OVERRIDE FINAL { return maxPositiveMarginAfter() - maxNegativeMarginAfter(); }

    LayoutUnit collapseMargins(RenderBox* child, MarginInfo&, bool childIsSelfCollapsing);
    LayoutUnit clearFloatsIfNeeded(RenderBox* child, MarginInfo&, LayoutUnit oldTopPosMargin, LayoutUnit oldTopNegMargin, LayoutUnit yPos, bool childIsSelfCollapsing);
    LayoutUnit estimateLogicalTopPosition(RenderBox* child, const MarginInfo&);
    void marginBeforeEstimateForChild(RenderBox*, LayoutUnit&, LayoutUnit&, bool&) const;
    void handleAfterSideOfBlock(RenderBox* lastChild, LayoutUnit top, LayoutUnit bottom, MarginInfo&);
    void setCollapsedBottomMargin(const MarginInfo&);

    // Used to store state between styleWillChange and styleDidChange
    static bool s_canPropagateFloatIntoSibling;

    RenderBlockFlowRareData& ensureRareData();

    LayoutUnit m_paintInvalidationLogicalTop;
    LayoutUnit m_paintInvalidationLogicalBottom;

    virtual bool isSelfCollapsingBlock() const OVERRIDE;

protected:
    OwnPtrWillBeMember<RenderBlockFlowRareData> m_rareData;
    OwnPtr<FloatingObjects> m_floatingObjects;

    friend class BreakingContext; // FIXME: It uses insertFloatingObject and positionNewFloatOnLine, if we move those out from the private scope/add a helper to LineBreaker, we can remove this friend
    friend class MarginInfo;
    friend class LineBreaker;
    friend class LineWidth; // needs to know FloatingObject

// FIXME-BLOCKFLOW: These methods have implementations in
// RenderBlockLineLayout. They should be moved to the proper header once the
// line layout code is separated from RenderBlock and RenderBlockFlow.
// START METHODS DEFINED IN RenderBlockLineLayout
private:
    InlineFlowBox* createLineBoxes(RenderObject*, const LineInfo&, InlineBox* childBox);
    RootInlineBox* constructLine(BidiRunList<BidiRun>&, const LineInfo&);
    void computeInlineDirectionPositionsForLine(RootInlineBox*, const LineInfo&, BidiRun* firstRun, BidiRun* trailingSpaceRun, bool reachedEnd, GlyphOverflowAndFallbackFontsMap&, VerticalPositionCache&, WordMeasurements&);
    BidiRun* computeInlineDirectionPositionsForSegment(RootInlineBox*, const LineInfo&, ETextAlign, float& logicalLeft,
        float& availableLogicalWidth, BidiRun* firstRun, BidiRun* trailingSpaceRun, GlyphOverflowAndFallbackFontsMap& textBoxDataMap, VerticalPositionCache&, WordMeasurements&);
    void computeBlockDirectionPositionsForLine(RootInlineBox*, BidiRun*, GlyphOverflowAndFallbackFontsMap&, VerticalPositionCache&);
    BidiRun* handleTrailingSpaces(BidiRunList<BidiRun>&, BidiContext*);
    void appendFloatingObjectToLastLine(FloatingObject*);
    // Helper function for layoutInlineChildren()
    RootInlineBox* createLineBoxesFromBidiRuns(unsigned bidiLevel, BidiRunList<BidiRun>&, const InlineIterator& end, LineInfo&, VerticalPositionCache&, BidiRun* trailingSpaceRun, WordMeasurements&);
    void layoutRunsAndFloats(LineLayoutState&);
    const InlineIterator& restartLayoutRunsAndFloatsInRange(LayoutUnit oldLogicalHeight, LayoutUnit newLogicalHeight,  FloatingObject* lastFloatFromPreviousLine, InlineBidiResolver&,  const InlineIterator&);
    void layoutRunsAndFloatsInRange(LineLayoutState&, InlineBidiResolver&,
        const InlineIterator& cleanLineStart, const BidiStatus& cleanLineBidiStatus);
    void linkToEndLineIfNeeded(LineLayoutState&);
    static void markDirtyFloatsForPaintInvalidation(Vector<FloatWithRect>& floats);
    void checkFloatsInCleanLine(RootInlineBox*, Vector<FloatWithRect>&, size_t& floatIndex, bool& encounteredNewFloat, bool& dirtiedByFloat);
    RootInlineBox* determineStartPosition(LineLayoutState&, InlineBidiResolver&);
    void determineEndPosition(LineLayoutState&, RootInlineBox* startBox, InlineIterator& cleanLineStart, BidiStatus& cleanLineBidiStatus);
    bool checkPaginationAndFloatsAtEndLine(LineLayoutState&);
    bool matchedEndLine(LineLayoutState&, const InlineBidiResolver&, const InlineIterator& endLineStart, const BidiStatus& endLineStatus);
    void deleteEllipsisLineBoxes();
    void checkLinesForTextOverflow();
    // Positions new floats and also adjust all floats encountered on the line if any of them
    // have to move to the next page/column.
    bool positionNewFloatOnLine(FloatingObject* newFloat, FloatingObject* lastFloatFromPreviousLine, LineInfo&, LineWidth&);


// END METHODS DEFINED IN RenderBlockLineLayout

};

DEFINE_RENDER_OBJECT_TYPE_CASTS(RenderBlockFlow, isRenderBlockFlow());

} // namespace blink

#endif // RenderBlockFlow_h
