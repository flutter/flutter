// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_RENDERING_RENDERPARAGRAPH_H_
#define SKY_ENGINE_CORE_RENDERING_RENDERPARAGRAPH_H_

#include "flutter/sky/engine/core/rendering/RenderBlock.h"
#include "flutter/sky/engine/core/rendering/line/TrailingObjects.h"

namespace blink {

struct BidiRun;
// class InlineBidiResolver;
class InlineIterator;

class RenderParagraph final : public RenderBlock {
 public:
  explicit RenderParagraph();
  virtual ~RenderParagraph();

  bool isRenderParagraph() const final { return true; }

  void layout() final;

  LayoutUnit logicalRightOffsetForLine(bool shouldIndentText) const {
    LayoutUnit right = logicalRightOffsetForContent();
    if (shouldIndentText && !style()->isLeftToRightDirection())
      right -= textIndentOffset();
    return right;
  }
  LayoutUnit logicalLeftOffsetForLine(bool shouldIndentText) const {
    LayoutUnit left = logicalLeftOffsetForContent();
    if (shouldIndentText && style()->isLeftToRightDirection())
      left += textIndentOffset();
    return left;
  }

  LayoutUnit logicalLeftSelectionOffset(RenderBlock* rootBlock,
                                        LayoutUnit position) final;
  LayoutUnit logicalRightSelectionOffset(RenderBlock* rootBlock,
                                         LayoutUnit position) final;

  virtual RootInlineBox* lineAtIndex(int) const;
  virtual int lineCount(const RootInlineBox* = 0, bool* = 0) const;

  void deleteLineBoxTree() final;

  GapRects inlineSelectionGaps(RenderBlock* rootBlock,
                               const LayoutPoint& rootBlockPhysicalPosition,
                               const LayoutSize& offsetFromRootBlock,
                               LayoutUnit& lastLogicalTop,
                               LayoutUnit& lastLogicalLeft,
                               LayoutUnit& lastLogicalRight,
                               const PaintInfo*);

  static bool shouldSkipCreatingRunsForObject(RenderObject* obj) {
    return obj->isOutOfFlowPositioned() &&
           !obj->style()->isOriginalDisplayInlineType() &&
           !obj->container()->isRenderInline();
  }

  bool didExceedMaxLines() const { return m_didExceedMaxLines; }

  // TODO(ojan): Remove the need for these.
  using RenderBlock::firstLineBox;
  using RenderBlock::lastRootBox;
  using RenderBlock::lineBoxes;

 protected:
  void addOverflowFromChildren() final;

  void simplifiedNormalFlowLayout() final;

  void paintChildren(PaintInfo&,
                     const LayoutPoint&,
                     Vector<RenderBox*>& layers) final;

  bool hitTestContents(const HitTestRequest&,
                       HitTestResult&,
                       const HitTestLocation& locationInContainer,
                       const LayoutPoint& accumulatedOffset) final;

  virtual ETextAlign textAlignmentForLine(bool endsWithSoftBreak) const;

  void computeIntrinsicLogicalWidths(LayoutUnit& minLogicalWidth,
                                     LayoutUnit& maxLogicalWidth) const final;

  int firstLineBoxBaseline(FontBaselineOrAuto baselineType) const final;
  int lastLineBoxBaseline(LineDirectionMode) const final;

 private:
  virtual const char* renderName() const override;

  void layoutChildren(bool relayoutChildren,
                      SubtreeLayoutScope&,
                      LayoutUnit beforeEdge,
                      LayoutUnit afterEdge);

  void markLinesDirtyInBlockRange(LayoutUnit logicalTop,
                                  LayoutUnit logicalBottom,
                                  RootInlineBox* highest = 0);

  void updateLogicalWidthForAlignment(const ETextAlign&,
                                      const RootInlineBox*,
                                      BidiRun* trailingSpaceRun,
                                      float& logicalLeft,
                                      float& totalLogicalWidth,
                                      float& availableLogicalWidth,
                                      unsigned expansionOpportunityCount);

  RootInlineBox* createAndAppendRootInlineBox();
  RootInlineBox* createRootInlineBox();
  InlineFlowBox* createLineBoxes(RenderObject*,
                                 const LineInfo&,
                                 InlineBox* childBox);
  InlineBox* createInlineBoxForRenderer(RenderObject*,
                                        bool isRootLineBox,
                                        bool isOnlyRun = false);
  RootInlineBox* constructLine(BidiRunList<BidiRun>&, const LineInfo&);
  void computeInlineDirectionPositionsForLine(RootInlineBox*,
                                              const LineInfo&,
                                              BidiRun* firstRun,
                                              BidiRun* trailingSpaceRun,
                                              bool reachedEnd,
                                              GlyphOverflowAndFallbackFontsMap&,
                                              VerticalPositionCache&,
                                              WordMeasurements&);
  BidiRun* computeInlineDirectionPositionsForSegment(
      RootInlineBox*,
      const LineInfo&,
      ETextAlign,
      float& logicalLeft,
      float& availableLogicalWidth,
      BidiRun* firstRun,
      BidiRun* trailingSpaceRun,
      GlyphOverflowAndFallbackFontsMap& textBoxDataMap,
      VerticalPositionCache&,
      WordMeasurements&);
  void computeBlockDirectionPositionsForLine(RootInlineBox*,
                                             BidiRun*,
                                             GlyphOverflowAndFallbackFontsMap&,
                                             VerticalPositionCache&);
  // Helper function for layoutChildren()
  RootInlineBox* createLineBoxesFromBidiRuns(unsigned bidiLevel,
                                             BidiRunList<BidiRun>&,
                                             const InlineIterator& end,
                                             LineInfo&,
                                             VerticalPositionCache&,
                                             BidiRun* trailingSpaceRun,
                                             WordMeasurements&);
  void layoutRunsAndFloats(LineLayoutState&);
  void layoutRunsAndFloatsInRange(LineLayoutState&,
                                  InlineBidiResolver&,
                                  const InlineIterator& cleanLineStart,
                                  const BidiStatus& cleanLineBidiStatus);
  void linkToEndLineIfNeeded(LineLayoutState&);
  RootInlineBox* determineStartPosition(LineLayoutState&, InlineBidiResolver&);
  void determineEndPosition(LineLayoutState&,
                            RootInlineBox* startBox,
                            InlineIterator& cleanLineStart,
                            BidiStatus& cleanLineBidiStatus);
  bool checkPaginationAndFloatsAtEndLine(LineLayoutState&);
  bool matchedEndLine(LineLayoutState&,
                      const InlineBidiResolver&,
                      const InlineIterator& endLineStart,
                      const BidiStatus& endLineStatus);

  bool m_didExceedMaxLines;
};

DEFINE_RENDER_OBJECT_TYPE_CASTS(RenderParagraph, isRenderParagraph());

}  // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_RENDERPARAGRAPH_H_
