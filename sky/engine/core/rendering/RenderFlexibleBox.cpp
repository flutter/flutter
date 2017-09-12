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

#include "flutter/sky/engine/core/rendering/RenderFlexibleBox.h"

#include <limits>
#include "flutter/sky/engine/core/rendering/RenderLayer.h"
#include "flutter/sky/engine/core/rendering/RenderView.h"
#include "flutter/sky/engine/platform/LengthFunctions.h"
#include "flutter/sky/engine/wtf/MathExtras.h"

namespace blink {

struct RenderFlexibleBox::LineContext {
  LineContext(LayoutUnit crossAxisOffset,
              LayoutUnit crossAxisExtent,
              size_t numberOfChildren,
              LayoutUnit maxAscent)
      : crossAxisOffset(crossAxisOffset),
        crossAxisExtent(crossAxisExtent),
        numberOfChildren(numberOfChildren),
        maxAscent(maxAscent) {}

  LayoutUnit crossAxisOffset;
  LayoutUnit crossAxisExtent;
  size_t numberOfChildren;
  LayoutUnit maxAscent;
};

struct RenderFlexibleBox::Violation {
  Violation(RenderBox* child, LayoutUnit childSize)
      : child(child), childSize(childSize) {}

  RenderBox* child;
  LayoutUnit childSize;
};

RenderFlexibleBox::RenderFlexibleBox()
    : m_orderIterator(this), m_numberOfInFlowChildrenOnFirstLine(-1) {}

RenderFlexibleBox::~RenderFlexibleBox() {}

const char* RenderFlexibleBox::renderName() const {
  return "RenderFlexibleBox";
}

void RenderFlexibleBox::computeIntrinsicLogicalWidths(
    LayoutUnit& minLogicalWidth,
    LayoutUnit& maxLogicalWidth) const {
  // FIXME: We're ignoring flex-basis here and we shouldn't. We can't start
  // honoring it though until the flex shorthand stops setting it to 0. See
  // https://bugs.webkit.org/show_bug.cgi?id=116117 and http://crbug.com/240765.
  for (RenderBox* child = firstChildBox(); child;
       child = child->nextSiblingBox()) {
    if (child->isOutOfFlowPositioned())
      continue;

    LayoutUnit margin = marginIntrinsicLogicalWidthForChild(child);
    LayoutUnit minPreferredLogicalWidth = child->minPreferredLogicalWidth();
    LayoutUnit maxPreferredLogicalWidth = child->maxPreferredLogicalWidth();
    minPreferredLogicalWidth += margin;
    maxPreferredLogicalWidth += margin;
    if (!isColumnFlow()) {
      maxLogicalWidth += maxPreferredLogicalWidth;
      if (isMultiline()) {
        // For multiline, the min preferred width is if you put a break between
        // each item.
        minLogicalWidth = std::max(minLogicalWidth, minPreferredLogicalWidth);
      } else
        minLogicalWidth += minPreferredLogicalWidth;
    } else {
      minLogicalWidth = std::max(minPreferredLogicalWidth, minLogicalWidth);
      maxLogicalWidth = std::max(maxPreferredLogicalWidth, maxLogicalWidth);
    }
  }

  maxLogicalWidth = std::max(minLogicalWidth, maxLogicalWidth);
}

static int synthesizedBaselineFromContentBox(const RenderBox* box,
                                             LineDirectionMode direction) {
  return direction == HorizontalLine
             ? box->borderTop() + box->paddingTop() + box->contentHeight()
             : box->borderRight() + box->paddingRight() + box->contentWidth();
}

int RenderFlexibleBox::baselinePosition(FontBaseline,
                                        bool,
                                        LineDirectionMode direction,
                                        LinePositionMode mode) const {
  ASSERT(mode == PositionOnContainingLine);
  int baseline = firstLineBoxBaseline(FontBaselineOrAuto());
  if (baseline == -1)
    baseline = synthesizedBaselineFromContentBox(this, direction);

  return beforeMarginInLineDirection(direction) + baseline;
}

int RenderFlexibleBox::firstLineBoxBaseline(
    FontBaselineOrAuto baselineType) const {
  if (m_numberOfInFlowChildrenOnFirstLine <= 0)
    return -1;
  RenderBox* baselineChild = 0;
  int childNumber = 0;
  for (RenderBox* child = m_orderIterator.first(); child;
       child = m_orderIterator.next()) {
    if (child->isOutOfFlowPositioned())
      continue;
    if (alignmentForChild(child) == ItemPositionBaseline &&
        !hasAutoMarginsInCrossAxis(child)) {
      baselineChild = child;
      break;
    }
    if (!baselineChild)
      baselineChild = child;

    ++childNumber;
    if (childNumber == m_numberOfInFlowChildrenOnFirstLine)
      break;
  }

  if (!baselineChild)
    return -1;

  if (!isColumnFlow() && hasOrthogonalFlow(baselineChild))
    return crossAxisExtentForChild(baselineChild) + baselineChild->logicalTop();
  if (isColumnFlow() && !hasOrthogonalFlow(baselineChild))
    return mainAxisExtentForChild(baselineChild) + baselineChild->logicalTop();

  int baseline = baselineChild->firstLineBoxBaseline(baselineType);
  if (baseline == -1) {
    // FIXME: We should pass |direction| into firstLineBoxBaseline and stop
    // bailing out if we're a writing mode root. This would also fix some cases
    // where the flexbox is orthogonal to its container.
    LineDirectionMode direction = HorizontalLine;
    return synthesizedBaselineFromContentBox(baselineChild, direction) +
           baselineChild->logicalTop();
  }

  return baseline + baselineChild->logicalTop();
}

int RenderFlexibleBox::inlineBlockBaseline(LineDirectionMode direction) const {
  int baseline = firstLineBoxBaseline(FontBaselineOrAuto());
  if (baseline != -1)
    return baseline;

  int marginAscent = direction == HorizontalLine ? marginTop() : marginRight();
  return synthesizedBaselineFromContentBox(this, direction) + marginAscent;
}

static ItemPosition resolveAlignment(const RenderStyle* parentStyle,
                                     const RenderStyle* childStyle) {
  ItemPosition align = childStyle->alignSelf();
  if (align == ItemPositionAuto)
    align = (parentStyle->alignItems() == ItemPositionAuto)
                ? ItemPositionStretch
                : parentStyle->alignItems();
  return align;
}

void RenderFlexibleBox::removeChild(RenderObject* child) {
  RenderBlock::removeChild(child);
  m_intrinsicSizeAlongMainAxis.remove(child);
}

void RenderFlexibleBox::styleDidChange(StyleDifference diff,
                                       const RenderStyle* oldStyle) {
  RenderBlock::styleDidChange(diff, oldStyle);

  if (oldStyle && oldStyle->alignItems() == ItemPositionStretch &&
      diff.needsFullLayout()) {
    // Flex items that were previously stretching need to be relayed out so we
    // can compute new available cross axis space. This is only necessary for
    // stretching since other alignment values don't change the size of the box.
    for (RenderBox* child = firstChildBox(); child;
         child = child->nextSiblingBox()) {
      ItemPosition previousAlignment =
          resolveAlignment(oldStyle, child->style());
      if (previousAlignment == ItemPositionStretch &&
          previousAlignment != resolveAlignment(style(), child->style()))
        child->setChildNeedsLayout(MarkOnlyThis);
    }
  }
}

void RenderFlexibleBox::layout() {
  ASSERT(needsLayout());

  if (simplifiedLayout())
    return;

  bool relayoutChildren = updateLogicalWidthAndColumnWidth();
  LayoutUnit previousHeight = logicalHeight();
  setLogicalHeight(borderAndPaddingLogicalHeight());

  m_numberOfInFlowChildrenOnFirstLine = -1;

  prepareOrderIteratorAndMargins();

  ChildFrameRects oldChildRects;
  appendChildFrameRects(oldChildRects);

  layoutFlexItems(relayoutChildren);

  if (logicalHeight() != previousHeight)
    relayoutChildren = true;

  layoutPositionedObjects(relayoutChildren);

  // FIXME: css3/flexbox/repaint-rtl-column.html seems to issue paint
  // invalidations for more overflow than it needs to.
  computeOverflow(clientLogicalBottomAfterRepositioning());

  updateLayerTransformAfterLayout();

  clearNeedsLayout();
}

void RenderFlexibleBox::appendChildFrameRects(
    ChildFrameRects& childFrameRects) {
  for (RenderBox* child = m_orderIterator.first(); child;
       child = m_orderIterator.next()) {
    if (!child->isOutOfFlowPositioned())
      childFrameRects.append(child->frameRect());
  }
}

void RenderFlexibleBox::paintChildren(PaintInfo& paintInfo,
                                      const LayoutPoint& paintOffset,
                                      Vector<RenderBox*>& layers) {
  for (RenderBox* child = m_orderIterator.first(); child;
       child = m_orderIterator.next()) {
    if (child->hasSelfPaintingLayer())
      layers.append(child);
    else
      child->paint(paintInfo, paintOffset, layers);
  }
}

void RenderFlexibleBox::repositionLogicalHeightDependentFlexItems(
    Vector<LineContext>& lineContexts) {
  LayoutUnit crossAxisStartEdge =
      lineContexts.isEmpty() ? LayoutUnit() : lineContexts[0].crossAxisOffset;
  alignFlexLines(lineContexts);

  alignChildren(lineContexts);

  if (style()->flexWrap() == FlexWrapReverse)
    flipForWrapReverse(lineContexts, crossAxisStartEdge);

  // direction:rtl + flex-direction:column means the cross-axis direction is
  // flipped.
  flipForRightToLeftColumn();
}

LayoutUnit RenderFlexibleBox::clientLogicalBottomAfterRepositioning() {
  LayoutUnit maxChildLogicalBottom = 0;
  for (RenderBox* child = firstChildBox(); child;
       child = child->nextSiblingBox()) {
    if (child->isOutOfFlowPositioned())
      continue;
    LayoutUnit childLogicalBottom = logicalTopForChild(child) +
                                    logicalHeightForChild(child) +
                                    marginAfterForChild(child);
    maxChildLogicalBottom = std::max(maxChildLogicalBottom, childLogicalBottom);
  }
  return std::max(clientLogicalBottom(),
                  maxChildLogicalBottom + paddingAfter());
}

bool RenderFlexibleBox::hasOrthogonalFlow(RenderBox* child) const {
  // FIXME: If the child is a flexbox, then we need to check isHorizontalFlow.
  return !isHorizontalFlow();
}

bool RenderFlexibleBox::isColumnFlow() const {
  return style()->isColumnFlexDirection();
}

bool RenderFlexibleBox::isHorizontalFlow() const {
  return !isColumnFlow();
}

bool RenderFlexibleBox::isLeftToRightFlow() const {
  if (isColumnFlow())
    return true;
  return style()->isLeftToRightDirection() ^
         (style()->flexDirection() == FlowRowReverse);
}

bool RenderFlexibleBox::isMultiline() const {
  return style()->flexWrap() != FlexNoWrap;
}

Length RenderFlexibleBox::flexBasisForChild(RenderBox* child) const {
  Length flexLength = child->style()->flexBasis();
  if (flexLength.isAuto())
    flexLength =
        isHorizontalFlow() ? child->style()->width() : child->style()->height();
  return flexLength;
}

LayoutUnit RenderFlexibleBox::crossAxisExtentForChild(RenderBox* child) const {
  return isHorizontalFlow() ? child->height() : child->width();
}

static inline LayoutUnit constrainedChildIntrinsicContentLogicalHeight(
    RenderBox* child) {
  LayoutUnit childIntrinsicContentLogicalHeight =
      child->intrinsicContentLogicalHeight();
  return child->constrainLogicalHeightByMinMax(
      childIntrinsicContentLogicalHeight +
          child->borderAndPaddingLogicalHeight(),
      childIntrinsicContentLogicalHeight);
}

LayoutUnit RenderFlexibleBox::childIntrinsicHeight(RenderBox* child) const {
  if (needToStretchChildLogicalHeight(child))
    return constrainedChildIntrinsicContentLogicalHeight(child);
  return child->height();
}

LayoutUnit RenderFlexibleBox::childIntrinsicWidth(RenderBox* child) const {
  // FIXME(sky): Remove
  return child->width();
}

LayoutUnit RenderFlexibleBox::crossAxisIntrinsicExtentForChild(
    RenderBox* child) const {
  return isHorizontalFlow() ? childIntrinsicHeight(child)
                            : childIntrinsicWidth(child);
}

LayoutUnit RenderFlexibleBox::mainAxisExtentForChild(RenderBox* child) const {
  return isHorizontalFlow() ? child->width() : child->height();
}

LayoutUnit RenderFlexibleBox::crossAxisExtent() const {
  return isHorizontalFlow() ? height() : width();
}

LayoutUnit RenderFlexibleBox::mainAxisExtent() const {
  return isHorizontalFlow() ? width() : height();
}

LayoutUnit RenderFlexibleBox::crossAxisContentExtent() const {
  return isHorizontalFlow() ? contentHeight() : contentWidth();
}

LayoutUnit RenderFlexibleBox::mainAxisContentExtent(
    LayoutUnit contentLogicalHeight) {
  if (isColumnFlow()) {
    LogicalExtentComputedValues computedValues;
    LayoutUnit borderPaddingAndScrollbar = borderAndPaddingLogicalHeight();
    LayoutUnit borderBoxLogicalHeight =
        contentLogicalHeight + borderPaddingAndScrollbar;
    computeLogicalHeight(borderBoxLogicalHeight, logicalTop(), computedValues);
    if (computedValues.m_extent == LayoutUnit::max())
      return computedValues.m_extent;
    return std::max(LayoutUnit(0),
                    computedValues.m_extent - borderPaddingAndScrollbar);
  }
  return contentLogicalWidth();
}

LayoutUnit RenderFlexibleBox::computeMainAxisExtentForChild(
    RenderBox* child,
    SizeType sizeType,
    const Length& size) {
  // FIXME: This is wrong for orthogonal flows. It should use the flexbox's
  // writing-mode, not the child's in order to figure out the logical
  // height/width.
  if (isColumnFlow()) {
    // We don't have to check for "auto" here - computeContentLogicalHeight will
    // just return -1 for that case anyway.
    if (size.isIntrinsic())
      child->layoutIfNeeded();
    return child->computeContentLogicalHeight(
        size, child->logicalHeight() - child->borderAndPaddingLogicalHeight());
  }
  return child->computeLogicalWidthUsing(sizeType, size, contentLogicalWidth(),
                                         this) -
         child->borderAndPaddingLogicalWidth();
}

LayoutUnit RenderFlexibleBox::flowAwareBorderStart() const {
  if (isHorizontalFlow())
    return isLeftToRightFlow() ? borderLeft() : borderRight();
  return isLeftToRightFlow() ? borderTop() : borderBottom();
}

LayoutUnit RenderFlexibleBox::flowAwareBorderEnd() const {
  if (isHorizontalFlow())
    return isLeftToRightFlow() ? borderRight() : borderLeft();
  return isLeftToRightFlow() ? borderBottom() : borderTop();
}

LayoutUnit RenderFlexibleBox::flowAwareBorderBefore() const {
  return isHorizontalFlow() ? borderTop() : borderLeft();
}

LayoutUnit RenderFlexibleBox::flowAwareBorderAfter() const {
  return isHorizontalFlow() ? borderBottom() : borderRight();
}

LayoutUnit RenderFlexibleBox::flowAwarePaddingStart() const {
  if (isHorizontalFlow())
    return isLeftToRightFlow() ? paddingLeft() : paddingRight();
  return isLeftToRightFlow() ? paddingTop() : paddingBottom();
}

LayoutUnit RenderFlexibleBox::flowAwarePaddingEnd() const {
  if (isHorizontalFlow())
    return isLeftToRightFlow() ? paddingRight() : paddingLeft();
  return isLeftToRightFlow() ? paddingBottom() : paddingTop();
}

LayoutUnit RenderFlexibleBox::flowAwarePaddingBefore() const {
  return isHorizontalFlow() ? paddingTop() : paddingLeft();
}

LayoutUnit RenderFlexibleBox::flowAwarePaddingAfter() const {
  return isHorizontalFlow() ? paddingBottom() : paddingRight();
}

LayoutUnit RenderFlexibleBox::flowAwareMarginStartForChild(
    RenderBox* child) const {
  if (isHorizontalFlow())
    return isLeftToRightFlow() ? child->marginLeft() : child->marginRight();
  return isLeftToRightFlow() ? child->marginTop() : child->marginBottom();
}

LayoutUnit RenderFlexibleBox::flowAwareMarginEndForChild(
    RenderBox* child) const {
  if (isHorizontalFlow())
    return isLeftToRightFlow() ? child->marginRight() : child->marginLeft();
  return isLeftToRightFlow() ? child->marginBottom() : child->marginTop();
}

LayoutUnit RenderFlexibleBox::flowAwareMarginBeforeForChild(
    RenderBox* child) const {
  return isHorizontalFlow() ? child->marginTop() : child->marginLeft();
}

LayoutUnit RenderFlexibleBox::crossAxisMarginExtentForChild(
    RenderBox* child) const {
  return isHorizontalFlow() ? child->marginHeight() : child->marginWidth();
}

LayoutPoint RenderFlexibleBox::flowAwareLocationForChild(
    RenderBox* child) const {
  return isHorizontalFlow() ? child->location()
                            : child->location().transposedPoint();
}

void RenderFlexibleBox::setFlowAwareLocationForChild(
    RenderBox* child,
    const LayoutPoint& location) {
  if (isHorizontalFlow())
    child->setLocation(location);
  else
    child->setLocation(location.transposedPoint());
}

LayoutUnit RenderFlexibleBox::mainAxisBorderAndPaddingExtentForChild(
    RenderBox* child) const {
  return isHorizontalFlow() ? child->borderAndPaddingWidth()
                            : child->borderAndPaddingHeight();
}

static inline bool preferredMainAxisExtentDependsOnLayout(
    const Length& flexBasis,
    bool hasInfiniteLineLength) {
  return flexBasis.isAuto() || (flexBasis.isPercent() && hasInfiniteLineLength);
}

bool RenderFlexibleBox::childPreferredMainAxisContentExtentRequiresLayout(
    RenderBox* child,
    bool hasInfiniteLineLength) const {
  return preferredMainAxisExtentDependsOnLayout(flexBasisForChild(child),
                                                hasInfiniteLineLength) &&
         hasOrthogonalFlow(child);
}

LayoutUnit RenderFlexibleBox::preferredMainAxisContentExtentForChild(
    RenderBox* child,
    bool hasInfiniteLineLength,
    bool relayoutChildren) {
  child->clearOverrideSize();

  Length flexBasis = flexBasisForChild(child);
  if (preferredMainAxisExtentDependsOnLayout(flexBasis,
                                             hasInfiniteLineLength)) {
    LayoutUnit mainAxisExtent;
    if (hasOrthogonalFlow(child)) {
      if (child->needsLayout() || relayoutChildren) {
        m_intrinsicSizeAlongMainAxis.remove(child);
        child->forceChildLayout();
        m_intrinsicSizeAlongMainAxis.set(child, child->logicalHeight());
      }
      ASSERT(m_intrinsicSizeAlongMainAxis.contains(child));
      mainAxisExtent = m_intrinsicSizeAlongMainAxis.get(child);
    } else {
      mainAxisExtent = child->maxPreferredLogicalWidth();
    }
    ASSERT(mainAxisExtent - mainAxisBorderAndPaddingExtentForChild(child) >= 0);
    return mainAxisExtent - mainAxisBorderAndPaddingExtentForChild(child);
  }
  return std::max(LayoutUnit(0), computeMainAxisExtentForChild(
                                     child, MainOrPreferredSize, flexBasis));
}

void RenderFlexibleBox::layoutFlexItems(bool relayoutChildren) {
  Vector<LineContext> lineContexts;
  OrderedFlexItemList orderedChildren;
  LayoutUnit sumFlexBaseSize;
  double totalFlexGrow;
  double totalWeightedFlexShrink;
  LayoutUnit sumHypotheticalMainSize;

  Vector<LayoutUnit, 16> childSizes;

  m_orderIterator.first();
  LayoutUnit crossAxisOffset =
      flowAwareBorderBefore() + flowAwarePaddingBefore();
  bool hasInfiniteLineLength = false;
  while (computeNextFlexLine(orderedChildren, sumFlexBaseSize, totalFlexGrow,
                             totalWeightedFlexShrink, sumHypotheticalMainSize,
                             hasInfiniteLineLength, relayoutChildren)) {
    LayoutUnit containerMainInnerSize =
        mainAxisContentExtent(sumHypotheticalMainSize);
    LayoutUnit availableFreeSpace = containerMainInnerSize - sumFlexBaseSize;
    FlexSign flexSign = (sumHypotheticalMainSize < containerMainInnerSize)
                            ? PositiveFlexibility
                            : NegativeFlexibility;
    InflexibleFlexItemSize inflexibleItems;
    childSizes.reserveCapacity(orderedChildren.size());
    while (!resolveFlexibleLengths(flexSign, orderedChildren,
                                   availableFreeSpace, totalFlexGrow,
                                   totalWeightedFlexShrink, inflexibleItems,
                                   childSizes, hasInfiniteLineLength)) {
      ASSERT(totalFlexGrow >= 0 && totalWeightedFlexShrink >= 0);
      ASSERT(inflexibleItems.size() > 0);
    }

    layoutAndPlaceChildren(crossAxisOffset, orderedChildren, childSizes,
                           availableFreeSpace, relayoutChildren, lineContexts,
                           hasInfiniteLineLength);
  }
  if (hasLineIfEmpty()) {
    // Even if computeNextFlexLine returns true, the flexbox might not have
    // a line because all our children might be out of flow positioned.
    // Instead of just checking if we have a line, make sure the flexbox
    // has at least a line's worth of height to cover this case.
    LayoutUnit minHeight =
        borderAndPaddingLogicalHeight() +
        lineHeight(true, HorizontalLine, PositionOfInteriorLineBoxes);
    if (height() < minHeight)
      setLogicalHeight(minHeight);
  }

  updateLogicalHeight();
  repositionLogicalHeightDependentFlexItems(lineContexts);
}

LayoutUnit RenderFlexibleBox::autoMarginOffsetInMainAxis(
    const OrderedFlexItemList& children,
    LayoutUnit& availableFreeSpace) {
  if (availableFreeSpace <= 0)
    return 0;

  int numberOfAutoMargins = 0;
  bool isHorizontal = isHorizontalFlow();
  for (size_t i = 0; i < children.size(); ++i) {
    RenderBox* child = children[i];
    if (child->isOutOfFlowPositioned())
      continue;
    if (isHorizontal) {
      if (child->style()->marginLeft().isAuto())
        ++numberOfAutoMargins;
      if (child->style()->marginRight().isAuto())
        ++numberOfAutoMargins;
    } else {
      if (child->style()->marginTop().isAuto())
        ++numberOfAutoMargins;
      if (child->style()->marginBottom().isAuto())
        ++numberOfAutoMargins;
    }
  }
  if (!numberOfAutoMargins)
    return 0;

  LayoutUnit sizeOfAutoMargin = availableFreeSpace / numberOfAutoMargins;
  availableFreeSpace = 0;
  return sizeOfAutoMargin;
}

void RenderFlexibleBox::updateAutoMarginsInMainAxis(
    RenderBox* child,
    LayoutUnit autoMarginOffset) {
  ASSERT(autoMarginOffset >= 0);

  if (isHorizontalFlow()) {
    if (child->style()->marginLeft().isAuto())
      child->setMarginLeft(autoMarginOffset);
    if (child->style()->marginRight().isAuto())
      child->setMarginRight(autoMarginOffset);
  } else {
    if (child->style()->marginTop().isAuto())
      child->setMarginTop(autoMarginOffset);
    if (child->style()->marginBottom().isAuto())
      child->setMarginBottom(autoMarginOffset);
  }
}

bool RenderFlexibleBox::hasAutoMarginsInCrossAxis(RenderBox* child) const {
  if (isHorizontalFlow())
    return child->style()->marginTop().isAuto() ||
           child->style()->marginBottom().isAuto();
  return child->style()->marginLeft().isAuto() ||
         child->style()->marginRight().isAuto();
}

LayoutUnit RenderFlexibleBox::availableAlignmentSpaceForChild(
    LayoutUnit lineCrossAxisExtent,
    RenderBox* child) {
  ASSERT(!child->isOutOfFlowPositioned());
  LayoutUnit childCrossExtent =
      crossAxisMarginExtentForChild(child) + crossAxisExtentForChild(child);
  return lineCrossAxisExtent - childCrossExtent;
}

LayoutUnit RenderFlexibleBox::availableAlignmentSpaceForChildBeforeStretching(
    LayoutUnit lineCrossAxisExtent,
    RenderBox* child) {
  ASSERT(!child->isOutOfFlowPositioned());
  LayoutUnit childCrossExtent = crossAxisMarginExtentForChild(child) +
                                crossAxisIntrinsicExtentForChild(child);
  return lineCrossAxisExtent - childCrossExtent;
}

bool RenderFlexibleBox::updateAutoMarginsInCrossAxis(
    RenderBox* child,
    LayoutUnit availableAlignmentSpace) {
  ASSERT(!child->isOutOfFlowPositioned());
  ASSERT(availableAlignmentSpace >= 0);

  bool isHorizontal = isHorizontalFlow();
  Length topOrLeft =
      isHorizontal ? child->style()->marginTop() : child->style()->marginLeft();
  Length bottomOrRight = isHorizontal ? child->style()->marginBottom()
                                      : child->style()->marginRight();
  if (topOrLeft.isAuto() && bottomOrRight.isAuto()) {
    adjustAlignmentForChild(child, availableAlignmentSpace / 2);
    if (isHorizontal) {
      child->setMarginTop(availableAlignmentSpace / 2);
      child->setMarginBottom(availableAlignmentSpace / 2);
    } else {
      child->setMarginLeft(availableAlignmentSpace / 2);
      child->setMarginRight(availableAlignmentSpace / 2);
    }
    return true;
  }
  bool shouldAdjustTopOrLeft = true;
  if (isColumnFlow() && !child->style()->isLeftToRightDirection()) {
    // For column flows, only make this adjustment if topOrLeft corresponds to
    // the "before" margin, so that flipForRightToLeftColumn will do the right
    // thing.
    shouldAdjustTopOrLeft = false;
  }

  if (topOrLeft.isAuto()) {
    if (shouldAdjustTopOrLeft)
      adjustAlignmentForChild(child, availableAlignmentSpace);

    if (isHorizontal)
      child->setMarginTop(availableAlignmentSpace);
    else
      child->setMarginLeft(availableAlignmentSpace);
    return true;
  }
  if (bottomOrRight.isAuto()) {
    if (!shouldAdjustTopOrLeft)
      adjustAlignmentForChild(child, availableAlignmentSpace);

    if (isHorizontal)
      child->setMarginBottom(availableAlignmentSpace);
    else
      child->setMarginRight(availableAlignmentSpace);
    return true;
  }
  return false;
}

LayoutUnit RenderFlexibleBox::marginBoxAscentForChild(RenderBox* child) {
  LayoutUnit ascent = child->firstLineBoxBaseline(FontBaselineOrAuto());
  if (ascent == -1)
    ascent = crossAxisExtentForChild(child);
  return ascent + flowAwareMarginBeforeForChild(child);
}

LayoutUnit RenderFlexibleBox::computeChildMarginValue(Length margin) {
  // When resolving the margins, we use the content size for resolving percent
  // and calc (for percents in calc expressions) margins. Fortunately, percent
  // margins are always computed with respect to the block's width, even for
  // margin-top and margin-bottom.
  LayoutUnit availableSize = contentLogicalWidth();
  return minimumValueForLength(margin, availableSize);
}

void RenderFlexibleBox::prepareOrderIteratorAndMargins() {
  OrderIteratorPopulator populator(m_orderIterator);

  for (RenderBox* child = firstChildBox(); child;
       child = child->nextSiblingBox()) {
    populator.collectChild(child);

    if (child->isOutOfFlowPositioned())
      continue;

    // Before running the flex algorithm, 'auto' has a margin of 0.
    // Also, if we're not auto sizing, we don't do a layout that computes the
    // start/end margins.
    if (isHorizontalFlow()) {
      child->setMarginLeft(
          computeChildMarginValue(child->style()->marginLeft()));
      child->setMarginRight(
          computeChildMarginValue(child->style()->marginRight()));
    } else {
      child->setMarginTop(computeChildMarginValue(child->style()->marginTop()));
      child->setMarginBottom(
          computeChildMarginValue(child->style()->marginBottom()));
    }
  }
}

LayoutUnit RenderFlexibleBox::adjustChildSizeForMinAndMax(
    RenderBox* child,
    LayoutUnit childSize) {
  Length max = isHorizontalFlow() ? child->style()->maxWidth()
                                  : child->style()->maxHeight();
  if (max.isSpecifiedOrIntrinsic()) {
    LayoutUnit maxExtent = computeMainAxisExtentForChild(child, MaxSize, max);
    if (maxExtent != -1 && childSize > maxExtent)
      childSize = maxExtent;
  }

  Length min = isHorizontalFlow() ? child->style()->minWidth()
                                  : child->style()->minHeight();
  LayoutUnit minExtent = 0;
  if (min.isSpecifiedOrIntrinsic())
    minExtent = computeMainAxisExtentForChild(child, MinSize, min);
  return std::max(childSize, minExtent);
}

bool RenderFlexibleBox::computeNextFlexLine(
    OrderedFlexItemList& orderedChildren,
    LayoutUnit& sumFlexBaseSize,
    double& totalFlexGrow,
    double& totalWeightedFlexShrink,
    LayoutUnit& sumHypotheticalMainSize,
    bool& hasInfiniteLineLength,
    bool relayoutChildren) {
  orderedChildren.clear();
  sumFlexBaseSize = 0;
  totalFlexGrow = totalWeightedFlexShrink = 0;
  sumHypotheticalMainSize = 0;

  if (!m_orderIterator.currentChild())
    return false;

  LayoutUnit lineBreakLength = mainAxisContentExtent(LayoutUnit::max());
  hasInfiniteLineLength = lineBreakLength == LayoutUnit::max();

  bool lineHasInFlowItem = false;

  for (RenderBox* child = m_orderIterator.currentChild(); child;
       child = m_orderIterator.next()) {
    if (child->isOutOfFlowPositioned()) {
      orderedChildren.append(child);
      continue;
    }

    LayoutUnit childMainAxisExtent = preferredMainAxisContentExtentForChild(
        child, hasInfiniteLineLength, relayoutChildren);
    LayoutUnit childMainAxisMarginBorderPadding =
        mainAxisBorderAndPaddingExtentForChild(child) +
        (isHorizontalFlow() ? child->marginWidth() : child->marginHeight());
    LayoutUnit childFlexBaseSize =
        childMainAxisExtent + childMainAxisMarginBorderPadding;

    LayoutUnit childMinMaxAppliedMainAxisExtent =
        adjustChildSizeForMinAndMax(child, childMainAxisExtent);
    LayoutUnit childHypotheticalMainSize =
        childMinMaxAppliedMainAxisExtent + childMainAxisMarginBorderPadding;

    if (isMultiline() &&
        sumHypotheticalMainSize + childHypotheticalMainSize > lineBreakLength &&
        lineHasInFlowItem)
      break;
    orderedChildren.append(child);
    lineHasInFlowItem = true;
    sumFlexBaseSize += childFlexBaseSize;
    totalFlexGrow += child->style()->flexGrow();
    totalWeightedFlexShrink +=
        child->style()->flexShrink() * childMainAxisExtent;
    sumHypotheticalMainSize += childHypotheticalMainSize;
  }
  return true;
}

void RenderFlexibleBox::freezeViolations(
    const Vector<Violation>& violations,
    LayoutUnit& availableFreeSpace,
    double& totalFlexGrow,
    double& totalWeightedFlexShrink,
    InflexibleFlexItemSize& inflexibleItems,
    bool hasInfiniteLineLength) {
  for (size_t i = 0; i < violations.size(); ++i) {
    RenderBox* child = violations[i].child;
    LayoutUnit childSize = violations[i].childSize;
    LayoutUnit preferredChildSize =
        preferredMainAxisContentExtentForChild(child, hasInfiniteLineLength);
    availableFreeSpace -= childSize - preferredChildSize;
    totalFlexGrow -= child->style()->flexGrow();
    totalWeightedFlexShrink -=
        child->style()->flexShrink() * preferredChildSize;
    inflexibleItems.set(child, childSize);
  }
}

// Returns true if we successfully ran the algorithm and sized the flex items.
bool RenderFlexibleBox::resolveFlexibleLengths(
    FlexSign flexSign,
    const OrderedFlexItemList& children,
    LayoutUnit& availableFreeSpace,
    double& totalFlexGrow,
    double& totalWeightedFlexShrink,
    InflexibleFlexItemSize& inflexibleItems,
    Vector<LayoutUnit, 16>& childSizes,
    bool hasInfiniteLineLength) {
  childSizes.resize(0);
  LayoutUnit totalViolation = 0;
  LayoutUnit usedFreeSpace = 0;
  Vector<Violation> minViolations;
  Vector<Violation> maxViolations;
  for (size_t i = 0; i < children.size(); ++i) {
    RenderBox* child = children[i];
    if (child->isOutOfFlowPositioned()) {
      childSizes.append(0);
      continue;
    }

    if (inflexibleItems.contains(child))
      childSizes.append(inflexibleItems.get(child));
    else {
      LayoutUnit preferredChildSize =
          preferredMainAxisContentExtentForChild(child, hasInfiniteLineLength);
      LayoutUnit childSize = preferredChildSize;
      double extraSpace = 0;
      if (availableFreeSpace > 0 && totalFlexGrow > 0 &&
          flexSign == PositiveFlexibility && std::isfinite(totalFlexGrow))
        extraSpace =
            availableFreeSpace * child->style()->flexGrow() / totalFlexGrow;
      else if (availableFreeSpace < 0 && totalWeightedFlexShrink > 0 &&
               flexSign == NegativeFlexibility &&
               std::isfinite(totalWeightedFlexShrink))
        extraSpace = availableFreeSpace * child->style()->flexShrink() *
                     preferredChildSize / totalWeightedFlexShrink;
      if (std::isfinite(extraSpace))
        childSize += LayoutUnit::fromFloatRound(extraSpace);

      LayoutUnit adjustedChildSize =
          adjustChildSizeForMinAndMax(child, childSize);
      childSizes.append(adjustedChildSize);
      usedFreeSpace += adjustedChildSize - preferredChildSize;

      LayoutUnit violation = adjustedChildSize - childSize;
      if (violation > 0)
        minViolations.append(Violation(child, adjustedChildSize));
      else if (violation < 0)
        maxViolations.append(Violation(child, adjustedChildSize));
      totalViolation += violation;
    }
  }

  if (totalViolation)
    freezeViolations(totalViolation < 0 ? maxViolations : minViolations,
                     availableFreeSpace, totalFlexGrow, totalWeightedFlexShrink,
                     inflexibleItems, hasInfiniteLineLength);
  else
    availableFreeSpace -= usedFreeSpace;

  return !totalViolation;
}

static LayoutUnit initialJustifyContentOffset(LayoutUnit availableFreeSpace,
                                              EJustifyContent justifyContent,
                                              unsigned numberOfChildren) {
  if (justifyContent == JustifyFlexEnd)
    return availableFreeSpace;
  if (justifyContent == JustifyCenter)
    return availableFreeSpace / 2;
  if (justifyContent == JustifySpaceAround) {
    if (availableFreeSpace > 0 && numberOfChildren)
      return availableFreeSpace / (2 * numberOfChildren);
    else
      return availableFreeSpace / 2;
  }
  return 0;
}

static LayoutUnit justifyContentSpaceBetweenChildren(
    LayoutUnit availableFreeSpace,
    EJustifyContent justifyContent,
    unsigned numberOfChildren) {
  if (availableFreeSpace > 0 && numberOfChildren > 1) {
    if (justifyContent == JustifySpaceBetween)
      return availableFreeSpace / (numberOfChildren - 1);
    if (justifyContent == JustifySpaceAround)
      return availableFreeSpace / numberOfChildren;
  }
  return 0;
}

void RenderFlexibleBox::setLogicalOverrideSize(RenderBox* child,
                                               LayoutUnit childPreferredSize) {
  if (hasOrthogonalFlow(child))
    child->setOverrideLogicalContentHeight(
        childPreferredSize - child->borderAndPaddingLogicalHeight());
  else
    child->setOverrideLogicalContentWidth(
        childPreferredSize - child->borderAndPaddingLogicalWidth());
}

ItemPosition RenderFlexibleBox::alignmentForChild(RenderBox* child) const {
  ItemPosition align = resolveAlignment(style(), child->style());

  if (align == ItemPositionBaseline && hasOrthogonalFlow(child))
    align = ItemPositionFlexStart;

  if (style()->flexWrap() == FlexWrapReverse) {
    if (align == ItemPositionFlexStart)
      align = ItemPositionFlexEnd;
    else if (align == ItemPositionFlexEnd)
      align = ItemPositionFlexStart;
  }

  return align;
}

size_t RenderFlexibleBox::numberOfInFlowPositionedChildren(
    const OrderedFlexItemList& children) const {
  size_t count = 0;
  for (size_t i = 0; i < children.size(); ++i) {
    RenderBox* child = children[i];
    if (!child->isOutOfFlowPositioned())
      ++count;
  }
  return count;
}

void RenderFlexibleBox::resetAutoMarginsAndLogicalTopInCrossAxis(
    RenderBox* child) {
  if (hasAutoMarginsInCrossAxis(child)) {
    child->updateLogicalHeight();
    if (isHorizontalFlow()) {
      if (child->style()->marginTop().isAuto())
        child->setMarginTop(0);
      if (child->style()->marginBottom().isAuto())
        child->setMarginBottom(0);
    } else {
      if (child->style()->marginLeft().isAuto())
        child->setMarginLeft(0);
      if (child->style()->marginRight().isAuto())
        child->setMarginRight(0);
    }
  }
}

bool RenderFlexibleBox::needToStretchChildLogicalHeight(
    RenderBox* child) const {
  if (alignmentForChild(child) != ItemPositionStretch)
    return false;

  return isHorizontalFlow() && child->style()->height().isAuto();
}

void RenderFlexibleBox::layoutAndPlaceChildren(
    LayoutUnit& crossAxisOffset,
    const OrderedFlexItemList& children,
    const Vector<LayoutUnit, 16>& childSizes,
    LayoutUnit availableFreeSpace,
    bool relayoutChildren,
    Vector<LineContext>& lineContexts,
    bool hasInfiniteLineLength) {
  ASSERT(childSizes.size() == children.size());

  size_t numberOfChildrenForJustifyContent =
      numberOfInFlowPositionedChildren(children);
  LayoutUnit autoMarginOffset =
      autoMarginOffsetInMainAxis(children, availableFreeSpace);
  LayoutUnit mainAxisOffset = flowAwareBorderStart() + flowAwarePaddingStart();
  mainAxisOffset +=
      initialJustifyContentOffset(availableFreeSpace, style()->justifyContent(),
                                  numberOfChildrenForJustifyContent);

  LayoutUnit totalMainExtent = mainAxisExtent();
  LayoutUnit maxAscent = 0, maxDescent = 0;  // Used when align-items: baseline.
  LayoutUnit maxChildCrossAxisExtent = 0;
  size_t seenInFlowPositionedChildren = 0;
  bool shouldFlipMainAxis = !isColumnFlow() && !isLeftToRightFlow();
  for (size_t i = 0; i < children.size(); ++i) {
    RenderBox* child = children[i];

    if (child->isOutOfFlowPositioned()) {
      child->containingBlock()->insertPositionedObject(child);
      continue;
    }

    LayoutUnit childPreferredSize =
        childSizes[i] + mainAxisBorderAndPaddingExtentForChild(child);
    setLogicalOverrideSize(child, childPreferredSize);
    if (childPreferredSize != mainAxisExtentForChild(child)) {
      child->setChildNeedsLayout(MarkOnlyThis);
    } else {
      // To avoid double applying margin changes in
      // updateAutoMarginsInCrossAxis, we reset the margins here.
      resetAutoMarginsAndLogicalTopInCrossAxis(child);
    }
    // We may have already forced relayout for orthogonal flowing children in
    // preferredMainAxisContentExtentForChild.
    bool forceChildRelayout =
        relayoutChildren && !childPreferredMainAxisContentExtentRequiresLayout(
                                child, hasInfiniteLineLength);
    updateBlockChildDirtyBitsBeforeLayout(forceChildRelayout, child);
    child->layoutIfNeeded();

    updateAutoMarginsInMainAxis(child, autoMarginOffset);

    LayoutUnit childCrossAxisMarginBoxExtent;
    if (alignmentForChild(child) == ItemPositionBaseline &&
        !hasAutoMarginsInCrossAxis(child)) {
      LayoutUnit ascent = marginBoxAscentForChild(child);
      LayoutUnit descent = (crossAxisMarginExtentForChild(child) +
                            crossAxisExtentForChild(child)) -
                           ascent;

      maxAscent = std::max(maxAscent, ascent);
      maxDescent = std::max(maxDescent, descent);

      childCrossAxisMarginBoxExtent = maxAscent + maxDescent;
    } else {
      childCrossAxisMarginBoxExtent = crossAxisIntrinsicExtentForChild(child) +
                                      crossAxisMarginExtentForChild(child);
    }
    if (!isColumnFlow())
      setLogicalHeight(
          std::max(logicalHeight(), crossAxisOffset + flowAwareBorderAfter() +
                                        flowAwarePaddingAfter() +
                                        childCrossAxisMarginBoxExtent));
    maxChildCrossAxisExtent =
        std::max(maxChildCrossAxisExtent, childCrossAxisMarginBoxExtent);

    mainAxisOffset += flowAwareMarginStartForChild(child);

    LayoutUnit childMainExtent = mainAxisExtentForChild(child);
    // In an RTL column situation, this will apply the margin-right/margin-end
    // on the left. This will be fixed later in flipForRightToLeftColumn.
    LayoutPoint childLocation(
        shouldFlipMainAxis ? totalMainExtent - mainAxisOffset - childMainExtent
                           : mainAxisOffset,
        crossAxisOffset + flowAwareMarginBeforeForChild(child));

    // FIXME: Supporting layout deltas.
    setFlowAwareLocationForChild(child, childLocation);
    mainAxisOffset += childMainExtent + flowAwareMarginEndForChild(child);

    ++seenInFlowPositionedChildren;
    if (seenInFlowPositionedChildren < numberOfChildrenForJustifyContent)
      mainAxisOffset += justifyContentSpaceBetweenChildren(
          availableFreeSpace, style()->justifyContent(),
          numberOfChildrenForJustifyContent);
  }

  if (isColumnFlow())
    setLogicalHeight(mainAxisOffset + flowAwareBorderEnd() +
                     flowAwarePaddingEnd());

  if (style()->flexDirection() == FlowColumnReverse) {
    // We have to do an extra pass for column-reverse to reposition the flex
    // items since the start depends on the height of the flexbox, which we only
    // know after we've positioned all the flex items.
    updateLogicalHeight();
    layoutColumnReverse(children, crossAxisOffset, availableFreeSpace);
  }

  if (m_numberOfInFlowChildrenOnFirstLine == -1)
    m_numberOfInFlowChildrenOnFirstLine = seenInFlowPositionedChildren;
  lineContexts.append(LineContext(crossAxisOffset, maxChildCrossAxisExtent,
                                  children.size(), maxAscent));
  crossAxisOffset += maxChildCrossAxisExtent;
}

void RenderFlexibleBox::layoutColumnReverse(const OrderedFlexItemList& children,
                                            LayoutUnit crossAxisOffset,
                                            LayoutUnit availableFreeSpace) {
  // This is similar to the logic in layoutAndPlaceChildren, except we place the
  // children starting from the end of the flexbox. We also don't need to layout
  // anything since we're just moving the children to a new position.
  size_t numberOfChildrenForJustifyContent =
      numberOfInFlowPositionedChildren(children);
  LayoutUnit mainAxisOffset =
      logicalHeight() - flowAwareBorderEnd() - flowAwarePaddingEnd();
  mainAxisOffset -=
      initialJustifyContentOffset(availableFreeSpace, style()->justifyContent(),
                                  numberOfChildrenForJustifyContent);

  size_t seenInFlowPositionedChildren = 0;
  for (size_t i = 0; i < children.size(); ++i) {
    RenderBox* child = children[i];

    if (child->isOutOfFlowPositioned())
      continue;

    mainAxisOffset -=
        mainAxisExtentForChild(child) + flowAwareMarginEndForChild(child);

    setFlowAwareLocationForChild(
        child,
        LayoutPoint(mainAxisOffset,
                    crossAxisOffset + flowAwareMarginBeforeForChild(child)));

    mainAxisOffset -= flowAwareMarginStartForChild(child);

    ++seenInFlowPositionedChildren;
    if (seenInFlowPositionedChildren < numberOfChildrenForJustifyContent)
      mainAxisOffset -= justifyContentSpaceBetweenChildren(
          availableFreeSpace, style()->justifyContent(),
          numberOfChildrenForJustifyContent);
  }
}

static LayoutUnit initialAlignContentOffset(LayoutUnit availableFreeSpace,
                                            EAlignContent alignContent,
                                            unsigned numberOfLines) {
  if (numberOfLines <= 1)
    return 0;
  if (alignContent == AlignContentFlexEnd)
    return availableFreeSpace;
  if (alignContent == AlignContentCenter)
    return availableFreeSpace / 2;
  if (alignContent == AlignContentSpaceAround) {
    if (availableFreeSpace > 0 && numberOfLines)
      return availableFreeSpace / (2 * numberOfLines);
    if (availableFreeSpace < 0)
      return availableFreeSpace / 2;
  }
  return 0;
}

static LayoutUnit alignContentSpaceBetweenChildren(
    LayoutUnit availableFreeSpace,
    EAlignContent alignContent,
    unsigned numberOfLines) {
  if (availableFreeSpace > 0 && numberOfLines > 1) {
    if (alignContent == AlignContentSpaceBetween)
      return availableFreeSpace / (numberOfLines - 1);
    if (alignContent == AlignContentSpaceAround ||
        alignContent == AlignContentStretch)
      return availableFreeSpace / numberOfLines;
  }
  return 0;
}

void RenderFlexibleBox::alignFlexLines(Vector<LineContext>& lineContexts) {
  // If we have a single line flexbox or a multiline line flexbox with only one
  // flex line, the line height is all the available space. For flex-direction:
  // row, this means we need to use the height, so we do this after calling
  // updateLogicalHeight.
  if (lineContexts.size() == 1) {
    lineContexts[0].crossAxisExtent = crossAxisContentExtent();
    return;
  }

  if (style()->alignContent() == AlignContentFlexStart)
    return;

  LayoutUnit availableCrossAxisSpace = crossAxisContentExtent();
  for (size_t i = 0; i < lineContexts.size(); ++i)
    availableCrossAxisSpace -= lineContexts[i].crossAxisExtent;

  RenderBox* child = m_orderIterator.first();
  LayoutUnit lineOffset = initialAlignContentOffset(
      availableCrossAxisSpace, style()->alignContent(), lineContexts.size());
  for (unsigned lineNumber = 0; lineNumber < lineContexts.size();
       ++lineNumber) {
    lineContexts[lineNumber].crossAxisOffset += lineOffset;
    for (size_t childNumber = 0;
         childNumber < lineContexts[lineNumber].numberOfChildren;
         ++childNumber, child = m_orderIterator.next())
      adjustAlignmentForChild(child, lineOffset);

    if (style()->alignContent() == AlignContentStretch &&
        availableCrossAxisSpace > 0)
      lineContexts[lineNumber].crossAxisExtent +=
          availableCrossAxisSpace / static_cast<unsigned>(lineContexts.size());

    lineOffset += alignContentSpaceBetweenChildren(
        availableCrossAxisSpace, style()->alignContent(), lineContexts.size());
  }
}

void RenderFlexibleBox::adjustAlignmentForChild(RenderBox* child,
                                                LayoutUnit delta) {
  if (child->isOutOfFlowPositioned()) {
    return;
  }

  setFlowAwareLocationForChild(
      child, flowAwareLocationForChild(child) + LayoutSize(0, delta));
}

void RenderFlexibleBox::alignChildren(const Vector<LineContext>& lineContexts) {
  // Keep track of the space between the baseline edge and the after edge of the
  // box for each line.
  Vector<LayoutUnit> minMarginAfterBaselines;

  RenderBox* child = m_orderIterator.first();
  for (size_t lineNumber = 0; lineNumber < lineContexts.size(); ++lineNumber) {
    LayoutUnit minMarginAfterBaseline = LayoutUnit::max();
    LayoutUnit lineCrossAxisExtent = lineContexts[lineNumber].crossAxisExtent;
    LayoutUnit maxAscent = lineContexts[lineNumber].maxAscent;

    for (size_t childNumber = 0;
         childNumber < lineContexts[lineNumber].numberOfChildren;
         ++childNumber, child = m_orderIterator.next()) {
      ASSERT(child);
      if (child->isOutOfFlowPositioned()) {
        if (style()->flexWrap() == FlexWrapReverse)
          adjustAlignmentForChild(child, lineCrossAxisExtent);
        continue;
      }

      if (updateAutoMarginsInCrossAxis(
              child, std::max(LayoutUnit(0), availableAlignmentSpaceForChild(
                                                 lineCrossAxisExtent, child))))
        continue;

      switch (alignmentForChild(child)) {
        case ItemPositionAuto:
          ASSERT_NOT_REACHED();
          break;
        case ItemPositionStretch: {
          applyStretchAlignmentToChild(child, lineCrossAxisExtent);
          // Since wrap-reverse flips cross start and cross end, strech children
          // should be aligned with the cross end.
          if (style()->flexWrap() == FlexWrapReverse)
            adjustAlignmentForChild(child, availableAlignmentSpaceForChild(
                                               lineCrossAxisExtent, child));
          break;
        }
        case ItemPositionFlexStart:
          break;
        case ItemPositionFlexEnd:
          adjustAlignmentForChild(child, availableAlignmentSpaceForChild(
                                             lineCrossAxisExtent, child));
          break;
        case ItemPositionCenter:
          adjustAlignmentForChild(
              child,
              availableAlignmentSpaceForChild(lineCrossAxisExtent, child) / 2);
          break;
        case ItemPositionBaseline: {
          // FIXME: If we get here in columns, we want the use the descent,
          // except we currently can't get the ascent/descent of orthogonal
          // children. https://bugs.webkit.org/show_bug.cgi?id=98076
          LayoutUnit ascent = marginBoxAscentForChild(child);
          LayoutUnit startOffset = maxAscent - ascent;
          adjustAlignmentForChild(child, startOffset);

          if (style()->flexWrap() == FlexWrapReverse)
            minMarginAfterBaseline = std::min(
                minMarginAfterBaseline,
                availableAlignmentSpaceForChild(lineCrossAxisExtent, child) -
                    startOffset);
          break;
        }
        case ItemPositionLastBaseline:
        case ItemPositionSelfStart:
        case ItemPositionSelfEnd:
        case ItemPositionStart:
        case ItemPositionEnd:
        case ItemPositionLeft:
        case ItemPositionRight:
          // FIXME: File a bug about implementing that. The extended grammar
          // is not enabled by default so we shouldn't hit this codepath.
          ASSERT_NOT_REACHED();
          break;
      }
    }
    minMarginAfterBaselines.append(minMarginAfterBaseline);
  }

  if (style()->flexWrap() != FlexWrapReverse)
    return;

  // wrap-reverse flips the cross axis start and end. For baseline alignment,
  // this means we need to align the after edge of baseline elements with the
  // after edge of the flex line.
  child = m_orderIterator.first();
  for (size_t lineNumber = 0; lineNumber < lineContexts.size(); ++lineNumber) {
    LayoutUnit minMarginAfterBaseline = minMarginAfterBaselines[lineNumber];
    for (size_t childNumber = 0;
         childNumber < lineContexts[lineNumber].numberOfChildren;
         ++childNumber, child = m_orderIterator.next()) {
      ASSERT(child);
      if (alignmentForChild(child) == ItemPositionBaseline &&
          !hasAutoMarginsInCrossAxis(child) && minMarginAfterBaseline)
        adjustAlignmentForChild(child, minMarginAfterBaseline);
    }
  }
}

void RenderFlexibleBox::applyStretchAlignmentToChild(
    RenderBox* child,
    LayoutUnit lineCrossAxisExtent) {
  if (!isColumnFlow() && child->style()->logicalHeight().isAuto()) {
    // FIXME: If the child has orthogonal flow, then it already has an override
    // height set, so use it.
    if (!hasOrthogonalFlow(child)) {
      LayoutUnit heightBeforeStretching =
          needToStretchChildLogicalHeight(child)
              ? constrainedChildIntrinsicContentLogicalHeight(child)
              : child->logicalHeight();
      LayoutUnit stretchedLogicalHeight =
          heightBeforeStretching +
          availableAlignmentSpaceForChildBeforeStretching(lineCrossAxisExtent,
                                                          child);
      ASSERT(!child->needsLayout());
      LayoutUnit desiredLogicalHeight = child->constrainLogicalHeightByMinMax(
          stretchedLogicalHeight,
          heightBeforeStretching - child->borderAndPaddingLogicalHeight());

      // FIXME: Can avoid laying out here in some cases. See
      // https://webkit.org/b/87905.
      if (desiredLogicalHeight != child->logicalHeight()) {
        child->setOverrideLogicalContentHeight(
            desiredLogicalHeight - child->borderAndPaddingLogicalHeight());
        child->setLogicalHeight(0);
        child->forceChildLayout();
      }
    }
  } else if (isColumnFlow() && child->style()->logicalWidth().isAuto()) {
    // FIXME: If the child doesn't have orthogonal flow, then it already has an
    // override width set, so use it.
    if (hasOrthogonalFlow(child)) {
      LayoutUnit childWidth = std::max<LayoutUnit>(
          0, lineCrossAxisExtent - crossAxisMarginExtentForChild(child));
      childWidth =
          child->constrainLogicalWidthByMinMax(childWidth, childWidth, this);

      if (childWidth != child->logicalWidth()) {
        child->setOverrideLogicalContentWidth(
            childWidth - child->borderAndPaddingLogicalWidth());
        child->forceChildLayout();
      }
    }
  }
}

void RenderFlexibleBox::flipForRightToLeftColumn() {
  if (style()->isLeftToRightDirection() || !isColumnFlow())
    return;

  LayoutUnit crossExtent = crossAxisExtent();
  for (RenderBox* child = m_orderIterator.first(); child;
       child = m_orderIterator.next()) {
    if (child->isOutOfFlowPositioned())
      continue;
    LayoutPoint location = flowAwareLocationForChild(child);
    // For vertical flows, setFlowAwareLocationForChild will transpose x and y,
    // so using the y axis for a column cross axis extent is correct.
    location.setY(crossExtent - crossAxisExtentForChild(child) - location.y());
    setFlowAwareLocationForChild(child, location);
  }
}

void RenderFlexibleBox::flipForWrapReverse(
    const Vector<LineContext>& lineContexts,
    LayoutUnit crossAxisStartEdge) {
  LayoutUnit contentExtent = crossAxisContentExtent();
  RenderBox* child = m_orderIterator.first();
  for (size_t lineNumber = 0; lineNumber < lineContexts.size(); ++lineNumber) {
    for (size_t childNumber = 0;
         childNumber < lineContexts[lineNumber].numberOfChildren;
         ++childNumber, child = m_orderIterator.next()) {
      ASSERT(child);
      LayoutUnit lineCrossAxisExtent = lineContexts[lineNumber].crossAxisExtent;
      LayoutUnit originalOffset =
          lineContexts[lineNumber].crossAxisOffset - crossAxisStartEdge;
      LayoutUnit newOffset =
          contentExtent - originalOffset - lineCrossAxisExtent;
      adjustAlignmentForChild(child, newOffset - originalOffset);
    }
  }
}

}  // namespace blink
