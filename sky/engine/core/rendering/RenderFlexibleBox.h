/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_RENDERING_RENDERFLEXIBLEBOX_H_
#define SKY_ENGINE_CORE_RENDERING_RENDERFLEXIBLEBOX_H_

#include "flutter/sky/engine/core/rendering/OrderIterator.h"
#include "flutter/sky/engine/core/rendering/RenderBlock.h"

namespace blink {

class RenderFlexibleBox : public RenderBlock {
 public:
  RenderFlexibleBox();
  virtual ~RenderFlexibleBox();

  virtual const char* renderName() const override;

  virtual bool isFlexibleBox() const override final { return true; }
  void layout();

  virtual int baselinePosition(
      FontBaseline,
      bool firstLine,
      LineDirectionMode,
      LinePositionMode = PositionOnContainingLine) const override;
  virtual int firstLineBoxBaseline(
      FontBaselineOrAuto baselineType) const override;
  virtual int inlineBlockBaseline(LineDirectionMode) const override;

  virtual void paintChildren(PaintInfo&,
                             const LayoutPoint&,
                             Vector<RenderBox*>& layers) override final;

  bool isHorizontalFlow() const;

 protected:
  virtual void computeIntrinsicLogicalWidths(
      LayoutUnit& minLogicalWidth,
      LayoutUnit& maxLogicalWidth) const override;

  virtual void styleDidChange(StyleDifference,
                              const RenderStyle* oldStyle) override;
  virtual void removeChild(RenderObject*) override;

 private:
  enum FlexSign {
    PositiveFlexibility,
    NegativeFlexibility,
  };

  enum PositionedLayoutMode {
    FlipForRowReverse,
    NoFlipForRowReverse,
  };

  typedef HashMap<const RenderBox*, LayoutUnit> InflexibleFlexItemSize;
  typedef Vector<RenderBox*> OrderedFlexItemList;

  struct LineContext;
  struct Violation;

  // Use an inline capacity of 8, since flexbox containers usually have less
  // than 8 children.
  typedef Vector<LayoutRect, 8> ChildFrameRects;

  bool hasOrthogonalFlow(RenderBox* child) const;
  bool isColumnFlow() const;
  bool isLeftToRightFlow() const;
  bool isMultiline() const;
  Length flexBasisForChild(RenderBox* child) const;
  LayoutUnit crossAxisExtentForChild(RenderBox* child) const;
  LayoutUnit crossAxisIntrinsicExtentForChild(RenderBox* child) const;
  LayoutUnit childIntrinsicHeight(RenderBox* child) const;
  LayoutUnit childIntrinsicWidth(RenderBox* child) const;
  LayoutUnit mainAxisExtentForChild(RenderBox* child) const;
  LayoutUnit crossAxisExtent() const;
  LayoutUnit mainAxisExtent() const;
  LayoutUnit crossAxisContentExtent() const;
  LayoutUnit mainAxisContentExtent(LayoutUnit contentLogicalHeight);
  LayoutUnit computeMainAxisExtentForChild(RenderBox* child,
                                           SizeType,
                                           const Length& size);
  LayoutUnit flowAwareBorderStart() const;
  LayoutUnit flowAwareBorderEnd() const;
  LayoutUnit flowAwareBorderBefore() const;
  LayoutUnit flowAwareBorderAfter() const;
  LayoutUnit flowAwarePaddingStart() const;
  LayoutUnit flowAwarePaddingEnd() const;
  LayoutUnit flowAwarePaddingBefore() const;
  LayoutUnit flowAwarePaddingAfter() const;
  LayoutUnit flowAwareMarginStartForChild(RenderBox* child) const;
  LayoutUnit flowAwareMarginEndForChild(RenderBox* child) const;
  LayoutUnit flowAwareMarginBeforeForChild(RenderBox* child) const;
  LayoutUnit crossAxisMarginExtentForChild(RenderBox* child) const;
  LayoutPoint flowAwareLocationForChild(RenderBox* child) const;
  // FIXME: Supporting layout deltas.
  void setFlowAwareLocationForChild(RenderBox* child, const LayoutPoint&);
  void adjustAlignmentForChild(RenderBox* child, LayoutUnit);
  ItemPosition alignmentForChild(RenderBox* child) const;
  LayoutUnit mainAxisBorderAndPaddingExtentForChild(RenderBox* child) const;
  LayoutUnit preferredMainAxisContentExtentForChild(
      RenderBox* child,
      bool hasInfiniteLineLength,
      bool relayoutChildren = false);
  bool childPreferredMainAxisContentExtentRequiresLayout(
      RenderBox* child,
      bool hasInfiniteLineLength) const;
  bool needToStretchChildLogicalHeight(RenderBox* child) const;

  void layoutFlexItems(bool relayoutChildren);
  LayoutUnit autoMarginOffsetInMainAxis(const OrderedFlexItemList&,
                                        LayoutUnit& availableFreeSpace);
  void updateAutoMarginsInMainAxis(RenderBox* child,
                                   LayoutUnit autoMarginOffset);
  bool hasAutoMarginsInCrossAxis(RenderBox* child) const;
  bool updateAutoMarginsInCrossAxis(RenderBox* child,
                                    LayoutUnit availableAlignmentSpace);
  void repositionLogicalHeightDependentFlexItems(Vector<LineContext>&);
  LayoutUnit clientLogicalBottomAfterRepositioning();
  void appendChildFrameRects(ChildFrameRects&);

  LayoutUnit availableAlignmentSpaceForChild(LayoutUnit lineCrossAxisExtent,
                                             RenderBox*);
  LayoutUnit availableAlignmentSpaceForChildBeforeStretching(
      LayoutUnit lineCrossAxisExtent,
      RenderBox*);
  LayoutUnit marginBoxAscentForChild(RenderBox*);

  LayoutUnit computeChildMarginValue(Length margin);
  void prepareOrderIteratorAndMargins();
  LayoutUnit adjustChildSizeForMinAndMax(RenderBox*, LayoutUnit childSize);
  // The hypothetical main size of an item is the flex base size clamped
  // according to its min and max main size properties
  bool computeNextFlexLine(OrderedFlexItemList& orderedChildren,
                           LayoutUnit& sumFlexBaseSize,
                           double& totalFlexGrow,
                           double& totalWeightedFlexShrink,
                           LayoutUnit& sumHypotheticalMainSize,
                           bool& hasInfiniteLineLength,
                           bool relayoutChildren);

  bool resolveFlexibleLengths(FlexSign,
                              const OrderedFlexItemList&,
                              LayoutUnit& availableFreeSpace,
                              double& totalFlexGrow,
                              double& totalWeightedFlexShrink,
                              InflexibleFlexItemSize&,
                              Vector<LayoutUnit, 16>& childSizes,
                              bool hasInfiniteLineLength);
  void freezeViolations(const Vector<Violation>&,
                        LayoutUnit& availableFreeSpace,
                        double& totalFlexGrow,
                        double& totalWeightedFlexShrink,
                        InflexibleFlexItemSize&,
                        bool hasInfiniteLineLength);

  void resetAutoMarginsAndLogicalTopInCrossAxis(RenderBox*);
  void setLogicalOverrideSize(RenderBox* child, LayoutUnit childPreferredSize);
  size_t numberOfInFlowPositionedChildren(const OrderedFlexItemList&) const;
  void layoutAndPlaceChildren(LayoutUnit& crossAxisOffset,
                              const OrderedFlexItemList&,
                              const Vector<LayoutUnit, 16>& childSizes,
                              LayoutUnit availableFreeSpace,
                              bool relayoutChildren,
                              Vector<LineContext>&,
                              bool hasInfiniteLineLength);
  void layoutColumnReverse(const OrderedFlexItemList&,
                           LayoutUnit crossAxisOffset,
                           LayoutUnit availableFreeSpace);
  void alignFlexLines(Vector<LineContext>&);
  void alignChildren(const Vector<LineContext>&);
  void applyStretchAlignmentToChild(RenderBox*, LayoutUnit lineCrossAxisExtent);
  void flipForRightToLeftColumn();
  void flipForWrapReverse(const Vector<LineContext>&,
                          LayoutUnit crossAxisStartEdge);

  // This is used to cache the preferred size for orthogonal flow children so we
  // don't have to relayout to get it
  HashMap<const RenderObject*, LayoutUnit> m_intrinsicSizeAlongMainAxis;

  mutable OrderIterator m_orderIterator;
  int m_numberOfInFlowChildrenOnFirstLine;
};

DEFINE_RENDER_OBJECT_TYPE_CASTS(RenderFlexibleBox, isFlexibleBox());

}  // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_RENDERFLEXIBLEBOX_H_
