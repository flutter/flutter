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

#ifndef SKY_ENGINE_CORE_RENDERING_RENDERBLOCKFLOW_H_
#define SKY_ENGINE_CORE_RENDERING_RENDERBLOCKFLOW_H_

#include "sky/engine/core/rendering/RenderBlock.h"
#include "sky/engine/core/rendering/line/TrailingObjects.h"
#include "sky/engine/core/rendering/style/RenderStyleConstants.h"

namespace blink {

class LineBreaker;
class LineWidth;
class FloatingObject;

class RenderBlockFlow : public RenderBlock {
public:
    explicit RenderBlockFlow(ContainerNode*);
    virtual ~RenderBlockFlow();

    static RenderBlockFlow* createAnonymous(Document*);

    virtual bool isRenderBlockFlow() const override final { return true; }

    virtual void layoutBlock(bool relayoutChildren) override;

    virtual void deleteLineBoxTree() override final;

    LayoutUnit availableLogicalWidthForLine(bool shouldIndentText) const
    {
        return max<LayoutUnit>(0, logicalRightOffsetForLine(shouldIndentText) - logicalLeftOffsetForLine(shouldIndentText));
    }
    LayoutUnit logicalRightOffsetForLine(bool shouldIndentText) const
    {
        return logicalRightOffsetForLine(logicalRightOffsetForContent(), shouldIndentText);
    }
    LayoutUnit logicalLeftOffsetForLine(bool shouldIndentText) const
    {
        return logicalLeftOffsetForLine(logicalLeftOffsetForContent(), shouldIndentText);
    }
    LayoutUnit startOffsetForLine(bool shouldIndentText) const
    {
        return style()->isLeftToRightDirection() ? logicalLeftOffsetForLine(shouldIndentText)
            : logicalWidth() - logicalRightOffsetForLine(shouldIndentText);
    }
    LayoutUnit endOffsetForLine(bool shouldIndentText) const
    {
        return !style()->isLeftToRightDirection() ? logicalLeftOffsetForLine(shouldIndentText)
            : logicalWidth() - logicalRightOffsetForLine(shouldIndentText);
    }

    // FIXME-BLOCKFLOW: Move this into RenderBlockFlow once there are no calls
    // in RenderBlock. http://crbug.com/393945, http://crbug.com/302024
    using RenderBlock::lineBoxes;
    using RenderBlock::firstLineBox;
    using RenderBlock::lastLineBox;
    using RenderBlock::firstRootBox;
    using RenderBlock::lastRootBox;

    virtual LayoutUnit logicalLeftSelectionOffset(RenderBlock* rootBlock, LayoutUnit position) override;
    virtual LayoutUnit logicalRightSelectionOffset(RenderBlock* rootBlock, LayoutUnit position) override;

    RootInlineBox* createAndAppendRootInlineBox();

    virtual void addChild(RenderObject* newChild, RenderObject* beforeChild = 0) override;

    bool generatesLineBoxesForInlineChild(RenderObject*);

    LayoutUnit startAlignedOffsetForLine(bool shouldIndentText);

    void setStaticInlinePositionForChild(RenderBox*, LayoutUnit inlinePosition);
    void updateStaticInlinePositionForChild(RenderBox*);

    static bool shouldSkipCreatingRunsForObject(RenderObject* obj)
    {
        return obj->isOutOfFlowPositioned() && !obj->style()->isOriginalDisplayInlineType() && !obj->container()->isRenderInline();
    }

    void addOverflowFromInlineChildren();

    // FIXME: This should be const to avoid a const_cast, but can modify child dirty bits
    void computeInlinePreferredLogicalWidths(LayoutUnit& minLogicalWidth, LayoutUnit& maxLogicalWidth);

    GapRects inlineSelectionGaps(RenderBlock* rootBlock, const LayoutPoint& rootBlockPhysicalPosition, const LayoutSize& offsetFromRootBlock,
        LayoutUnit& lastLogicalTop, LayoutUnit& lastLogicalLeft, LayoutUnit& lastLogicalRight, const PaintInfo*);

protected:
    void layoutInlineChildren(bool relayoutChildren, LayoutUnit& paintInvalidationLogicalTop, LayoutUnit& paintInvalidationLogicalBottom, LayoutUnit afterEdge);

    virtual bool updateLogicalWidthAndColumnWidth() override;

    void determineLogicalLeftPositionForChild(RenderBox* child);

private:
    LayoutUnit logicalRightOffsetForLine(LayoutUnit fixedOffset, bool applyTextIndent) const
    {
        LayoutUnit right = fixedOffset;
        if (applyTextIndent && !style()->isLeftToRightDirection())
            right -= textIndentOffset();
        return right;
    }
    LayoutUnit logicalLeftOffsetForLine(LayoutUnit fixedOffset, bool applyTextIndent) const
    {
        LayoutUnit left = fixedOffset;
        if (applyTextIndent && style()->isLeftToRightDirection())
            left += textIndentOffset();
        return left;
    }

    void layoutBlockFlow(bool relayoutChildren, SubtreeLayoutScope&);
    void layoutBlockChildren(bool relayoutChildren, SubtreeLayoutScope&, LayoutUnit beforeEdge, LayoutUnit afterEdge);

    void layoutBlockChild(RenderBox* child);
    void adjustPositionedBlock(RenderBox* child);

    virtual void invalidatePaintForOverflow() override final;

    RootInlineBox* createRootInlineBox();

    void updateLogicalWidthForAlignment(const ETextAlign&, const RootInlineBox*, BidiRun* trailingSpaceRun, float& logicalLeft, float& totalLogicalWidth, float& availableLogicalWidth, unsigned expansionOpportunityCount);

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

protected:
    virtual ETextAlign textAlignmentForLine(bool endsWithSoftBreak) const;
private:
    LayoutUnit m_paintInvalidationLogicalTop;
    LayoutUnit m_paintInvalidationLogicalBottom;

protected:
    friend class BreakingContext; // FIXME: It uses insertFloatingObject and positionNewFloatOnLine, if we move those out from the private scope/add a helper to LineBreaker, we can remove this friend
    friend class LineBreaker;

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


// END METHODS DEFINED IN RenderBlockLineLayout

};

DEFINE_RENDER_OBJECT_TYPE_CASTS(RenderBlockFlow, isRenderBlockFlow());

} // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_RENDERBLOCKFLOW_H_
