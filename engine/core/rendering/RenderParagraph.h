// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_RENDERING_RENDERPARAGRAPH_H_
#define SKY_ENGINE_CORE_RENDERING_RENDERPARAGRAPH_H_

#include "sky/engine/core/dom/ContainerNode.h"
#include "sky/engine/core/rendering/RenderBlockFlow.h"

namespace blink {

class ContainerNode;

class RenderParagraph final : public RenderBlockFlow {
public:
    explicit RenderParagraph(ContainerNode*);
    virtual ~RenderParagraph();

    static RenderParagraph* createAnonymous(Document&);

    bool isRenderParagraph() const override { return true; }

    virtual RootInlineBox* lineAtIndex(int) const;
    virtual int lineCount(const RootInlineBox* = 0, bool* = 0) const;

    GapRects inlineSelectionGaps(RenderBlock* rootBlock, const LayoutPoint& rootBlockPhysicalPosition, const LayoutSize& offsetFromRootBlock,
        LayoutUnit& lastLogicalTop, LayoutUnit& lastLogicalLeft, LayoutUnit& lastLogicalRight, const PaintInfo*);

protected:
    void layoutChildren(bool relayoutChildren, SubtreeLayoutScope&, LayoutUnit beforeEdge, LayoutUnit afterEdge) final;

    void addOverflowFromChildren() final;

    void simplifiedNormalFlowLayout() final;

    void paintChildren(PaintInfo&, const LayoutPoint&, Vector<RenderBox*>& layers) final;

    bool hitTestContents(const HitTestRequest&, HitTestResult&, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset) final;

    virtual ETextAlign textAlignmentForLine(bool endsWithSoftBreak) const;

    void computeIntrinsicLogicalWidths(LayoutUnit& minLogicalWidth, LayoutUnit& maxLogicalWidth) const final;

    int firstLineBoxBaseline() const final;
    int lastLineBoxBaseline(LineDirectionMode) const final;

private:
    virtual const char* renderName() const override;

    void markLinesDirtyInBlockRange(LayoutUnit logicalTop, LayoutUnit logicalBottom, RootInlineBox* highest = 0);

    InlineFlowBox* createLineBoxes(RenderObject*, const LineInfo&, InlineBox* childBox);
    RootInlineBox* constructLine(BidiRunList<BidiRun>&, const LineInfo&);
    void computeInlineDirectionPositionsForLine(RootInlineBox*, const LineInfo&, BidiRun* firstRun, BidiRun* trailingSpaceRun, bool reachedEnd, GlyphOverflowAndFallbackFontsMap&, VerticalPositionCache&, WordMeasurements&);
    BidiRun* computeInlineDirectionPositionsForSegment(RootInlineBox*, const LineInfo&, ETextAlign, float& logicalLeft,
        float& availableLogicalWidth, BidiRun* firstRun, BidiRun* trailingSpaceRun, GlyphOverflowAndFallbackFontsMap& textBoxDataMap, VerticalPositionCache&, WordMeasurements&);
    void computeBlockDirectionPositionsForLine(RootInlineBox*, BidiRun*, GlyphOverflowAndFallbackFontsMap&, VerticalPositionCache&);
    // Helper function for layoutChildren()
    RootInlineBox* createLineBoxesFromBidiRuns(unsigned bidiLevel, BidiRunList<BidiRun>&, const InlineIterator& end, LineInfo&, VerticalPositionCache&, BidiRun* trailingSpaceRun, WordMeasurements&);
    void layoutRunsAndFloats(LineLayoutState&);
    void layoutRunsAndFloatsInRange(LineLayoutState&, InlineBidiResolver&,
        const InlineIterator& cleanLineStart, const BidiStatus& cleanLineBidiStatus);
    void linkToEndLineIfNeeded(LineLayoutState&);
    void checkFloatsInCleanLine(RootInlineBox*, Vector<FloatWithRect>&, size_t& floatIndex, bool& encounteredNewFloat, bool& dirtiedByFloat);
    RootInlineBox* determineStartPosition(LineLayoutState&, InlineBidiResolver&);
    void determineEndPosition(LineLayoutState&, RootInlineBox* startBox, InlineIterator& cleanLineStart, BidiStatus& cleanLineBidiStatus);
    bool checkPaginationAndFloatsAtEndLine(LineLayoutState&);
    bool matchedEndLine(LineLayoutState&, const InlineBidiResolver&, const InlineIterator& endLineStart, const BidiStatus& endLineStatus);
    void deleteEllipsisLineBoxes();
    void checkLinesForTextOverflow();
};

DEFINE_RENDER_OBJECT_TYPE_CASTS(RenderParagraph, isRenderParagraph());

} // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_RENDERPARAGRAPH_H_
