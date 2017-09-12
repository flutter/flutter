/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2007 David Smith (catfish.man@gmail.com)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc.
 * All rights reserved.
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#include "flutter/sky/engine/core/rendering/RenderBlock.h"

#include "flutter/sky/engine/core/rendering/HitTestLocation.h"
#include "flutter/sky/engine/core/rendering/HitTestResult.h"
#include "flutter/sky/engine/core/rendering/InlineIterator.h"
#include "flutter/sky/engine/core/rendering/InlineTextBox.h"
#include "flutter/sky/engine/core/rendering/PaintInfo.h"
#include "flutter/sky/engine/core/rendering/RenderFlexibleBox.h"
#include "flutter/sky/engine/core/rendering/RenderInline.h"
#include "flutter/sky/engine/core/rendering/RenderLayer.h"
#include "flutter/sky/engine/core/rendering/RenderObjectInlines.h"
#include "flutter/sky/engine/core/rendering/RenderParagraph.h"
#include "flutter/sky/engine/core/rendering/RenderView.h"
#include "flutter/sky/engine/core/rendering/style/RenderStyle.h"
#include "flutter/sky/engine/platform/geometry/FloatQuad.h"
#include "flutter/sky/engine/platform/geometry/TransformState.h"
#include "flutter/sky/engine/platform/graphics/GraphicsContextStateSaver.h"
#include "flutter/sky/engine/wtf/StdLibExtras.h"
#include "flutter/sky/engine/wtf/TemporaryChange.h"

using namespace WTF;
using namespace Unicode;

namespace blink {

struct SameSizeAsRenderBlock : public RenderBox {
  RenderObjectChildList children;
  RenderLineBoxList lineBoxes;
  int pageLogicalOffset;
  uint32_t bitfields;
};

COMPILE_ASSERT(sizeof(RenderBlock) == sizeof(SameSizeAsRenderBlock),
               RenderBlock_should_stay_small);

static TrackedDescendantsMap* gPositionedDescendantsMap = 0;
static TrackedDescendantsMap* gPercentHeightDescendantsMap = 0;

static TrackedContainerMap* gPositionedContainerMap = 0;
static TrackedContainerMap* gPercentHeightContainerMap = 0;

RenderBlock::RenderBlock()
    : m_hasMarginBeforeQuirk(false),
      m_hasMarginAfterQuirk(false),
      m_beingDestroyed(false),
      m_hasBorderOrPaddingLogicalWidthChanged(false) {}

static void removeBlockFromDescendantAndContainerMaps(
    RenderBlock* block,
    TrackedDescendantsMap*& descendantMap,
    TrackedContainerMap*& containerMap) {
  if (OwnPtr<TrackedRendererListHashSet> descendantSet =
          descendantMap->take(block)) {
    TrackedRendererListHashSet::iterator end = descendantSet->end();
    for (TrackedRendererListHashSet::iterator descendant =
             descendantSet->begin();
         descendant != end; ++descendant) {
      TrackedContainerMap::iterator it = containerMap->find(*descendant);
      ASSERT(it != containerMap->end());
      if (it == containerMap->end())
        continue;
      HashSet<RenderBlock*>* containerSet = it->value.get();
      ASSERT(containerSet->contains(block));
      containerSet->remove(block);
      if (containerSet->isEmpty())
        containerMap->remove(it);
    }
  }
}

void RenderBlock::removeFromGlobalMaps() {
  if (gPercentHeightDescendantsMap)
    removeBlockFromDescendantAndContainerMaps(
        this, gPercentHeightDescendantsMap, gPercentHeightContainerMap);
  if (gPositionedDescendantsMap)
    removeBlockFromDescendantAndContainerMaps(this, gPositionedDescendantsMap,
                                              gPositionedContainerMap);
}

RenderBlock::~RenderBlock() {
#if !ENABLE(OILPAN)
  removeFromGlobalMaps();
#endif
}

void RenderBlock::destroy() {
  RenderBox::destroy();
#if ENABLE(OILPAN)
  removeFromGlobalMaps();
#endif
}

void RenderBlock::willBeDestroyed() {
  // Mark as being destroyed to avoid trouble with merges in removeChild().
  m_beingDestroyed = true;

  // Make sure to destroy anonymous children first while they are still
  // connected to the rest of the tree, so that they will properly dirty line
  // boxes that they are removed from. Effects that do :before/:after only on
  // hover could crash otherwise.
  children()->destroyLeftoverChildren();

  if (!documentBeingDestroyed()) {
    if (!firstLineBox() && parent())
      parent()->dirtyLinesFromChangedChild(this);
  }

  m_lineBoxes.deleteLineBoxes();

  RenderBox::willBeDestroyed();
}

void RenderBlock::styleWillChange(StyleDifference diff,
                                  const RenderStyle& newStyle) {
  RenderStyle* oldStyle = style();

  setReplaced(newStyle.isDisplayInlineType());

  if (oldStyle && parent()) {
    bool oldStyleIsContainer = oldStyle->position() != StaticPosition ||
                               oldStyle->hasTransformRelatedProperty();
    bool newStyleIsContainer = newStyle.position() != StaticPosition ||
                               newStyle.hasTransformRelatedProperty();

    if (oldStyleIsContainer && !newStyleIsContainer) {
      // Clear our positioned objects list. Our absolutely positioned
      // descendants will be inserted into our containing block's positioned
      // objects list during layout.
      removePositionedObjects(0, NewContainingBlock);
    } else if (!oldStyleIsContainer && newStyleIsContainer) {
      // Remove our absolutely positioned descendants from their current
      // containing block. They will be inserted into our positioned objects
      // list during layout.
      RenderObject* cb = parent();
      while (cb &&
             (cb->style()->position() == StaticPosition ||
              (cb->isInline() && !cb->isReplaced())) &&
             !cb->isRenderView()) {
        cb = cb->parent();
      }

      if (cb->isRenderBlock())
        toRenderBlock(cb)->removePositionedObjects(this, NewContainingBlock);
    }
  }

  RenderBox::styleWillChange(diff, newStyle);
}

static bool borderOrPaddingLogicalWidthChanged(const RenderStyle* oldStyle,
                                               const RenderStyle* newStyle) {
  return oldStyle->borderLeftWidth() != newStyle->borderLeftWidth() ||
         oldStyle->borderRightWidth() != newStyle->borderRightWidth() ||
         oldStyle->paddingLeft() != newStyle->paddingLeft() ||
         oldStyle->paddingRight() != newStyle->paddingRight();
}

void RenderBlock::styleDidChange(StyleDifference diff,
                                 const RenderStyle* oldStyle) {
  RenderBox::styleDidChange(diff, oldStyle);

  // It's possible for our border/padding to change, but for the overall logical
  // width of the block to end up being the same. We keep track of this change
  // so in layoutBlock, we can know to set relayoutChildren=true.
  m_hasBorderOrPaddingLogicalWidthChanged =
      oldStyle && diff.needsFullLayout() && needsLayout() &&
      borderOrPaddingLogicalWidthChanged(oldStyle, style());
}

void RenderBlock::addChild(RenderObject* newChild, RenderObject* beforeChild) {
  ASSERT(isRenderParagraph() || !newChild->isInline());
  RenderBox::addChild(newChild, beforeChild);
}

void RenderBlock::deleteLineBoxTree() {
  ASSERT(!m_lineBoxes.firstLineBox());
}

void RenderBlock::removeChild(RenderObject* oldChild) {
  RenderBox::removeChild(oldChild);

  // No need to waste time deleting the line box tree if we're getting
  // destroyed.
  if (documentBeingDestroyed())
    return;

  // If this was our last child be sure to clear out our line boxes.
  if (!firstChild() && isRenderParagraph())
    deleteLineBoxTree();
}

bool RenderBlock::widthAvailableToChildrenHasChanged() {
  bool widthAvailableToChildrenHasChanged =
      m_hasBorderOrPaddingLogicalWidthChanged;
  m_hasBorderOrPaddingLogicalWidthChanged = false;

  // If we use border-box sizing, have percentage padding, and our parent has
  // changed width then the width available to our children has changed even
  // though our own width has remained the same.
  widthAvailableToChildrenHasChanged |=
      style()->boxSizing() == BORDER_BOX && needsPreferredWidthsRecalculation();

  return widthAvailableToChildrenHasChanged;
}

bool RenderBlock::updateLogicalWidthAndColumnWidth() {
  LayoutUnit oldWidth = logicalWidth();
  updateLogicalWidth();
  return oldWidth != logicalWidth() || widthAvailableToChildrenHasChanged();
}

void RenderBlock::addOverflowFromChildren() {
  for (RenderBox* child = firstChildBox(); child;
       child = child->nextSiblingBox()) {
    if (!child->isFloatingOrOutOfFlowPositioned())
      addOverflowFromChild(child);
  }
}

void RenderBlock::computeOverflow(LayoutUnit oldClientAfterEdge, bool) {
  m_overflow.clear();

  // Add overflow from children.
  addOverflowFromChildren();

  // Add in the overflow from positioned objects.
  addOverflowFromPositionedObjects();

  if (hasOverflowClip()) {
    // When we have overflow clip, propagate the original spillout since it will
    // include collapsed bottom margins and bottom padding.  Set the axis we
    // don't care about to be 1, since we want this overflow to always be
    // considered reachable.
    LayoutRect clientRect(paddingBoxRect());
    LayoutRect rectToApply;
    rectToApply = LayoutRect(
        clientRect.x(), clientRect.y(), 1,
        std::max<LayoutUnit>(0, oldClientAfterEdge - clientRect.y()));
    addLayoutOverflow(rectToApply);
    if (hasRenderOverflow())
      m_overflow->setLayoutClientAfterEdge(oldClientAfterEdge);
  }

  addVisualEffectOverflow();
}

void RenderBlock::addOverflowFromPositionedObjects() {
  TrackedRendererListHashSet* positionedDescendants = positionedObjects();
  if (!positionedDescendants)
    return;

  RenderBox* positionedObject;
  TrackedRendererListHashSet::iterator end = positionedDescendants->end();
  for (TrackedRendererListHashSet::iterator it = positionedDescendants->begin();
       it != end; ++it) {
    positionedObject = *it;
    addOverflowFromChild(positionedObject, LayoutSize(positionedObject->x(),
                                                      positionedObject->y()));
  }
}

void RenderBlock::updateBlockChildDirtyBitsBeforeLayout(bool relayoutChildren,
                                                        RenderBox* child) {
  // FIXME: Technically percentage height objects only need a relayout if their
  // percentage isn't going to be turned into an auto value. Add a method to
  // determine this, so that we can avoid the relayout.
  if (relayoutChildren ||
      (child->hasRelativeLogicalHeight() && !isRenderView()))
    child->setChildNeedsLayout(MarkOnlyThis);

  // If relayoutChildren is set and the child has percentage padding or an
  // embedded content box, we also need to invalidate the childs pref widths.
  if (relayoutChildren && child->needsPreferredWidthsRecalculation())
    child->setPreferredLogicalWidthsDirty(MarkOnlyThis);
}

void RenderBlock::simplifiedNormalFlowLayout() {
  for (RenderBox* box = firstChildBox(); box; box = box->nextSiblingBox()) {
    if (!box->isOutOfFlowPositioned())
      box->layoutIfNeeded();
  }
}

bool RenderBlock::simplifiedLayout() {
  // Check if we need to do a full layout.
  if (normalChildNeedsLayout() || selfNeedsLayout())
    return false;

  // Check that we actually need to do a simplified layout.
  if (!posChildNeedsLayout() &&
      !(needsSimplifiedNormalFlowLayout() || needsPositionedMovementLayout()))
    return false;

  if (needsPositionedMovementLayout() &&
      !tryLayoutDoingPositionedMovementOnly())
    return false;

  // Lay out positioned descendants or objects that just need to recompute
  // overflow.
  if (needsSimplifiedNormalFlowLayout())
    simplifiedNormalFlowLayout();

  if (posChildNeedsLayout() || needsPositionedMovementLayout())
    layoutPositionedObjects(false, needsPositionedMovementLayout()
                                       ? ForcedLayoutAfterContainingBlockMoved
                                       : DefaultLayout);

  // Recompute our overflow information.
  // FIXME: We could do better here by computing a temporary overflow object
  // from layoutPositionedObjects and only updating our overflow if we either
  // used to have overflow or if the new temporary object has overflow. For now
  // just always recompute overflow. This is no worse performance-wise than the
  // old code that called rightmostPosition and lowestPosition on every relayout
  // so it's not a regression. computeOverflow expects the bottom edge before we
  // clamp our height. Since this information isn't available during
  // simplifiedLayout, we cache the value in m_overflow.
  LayoutUnit oldClientAfterEdge = hasRenderOverflow()
                                      ? m_overflow->layoutClientAfterEdge()
                                      : clientLogicalBottom();
  computeOverflow(oldClientAfterEdge, true);

  updateLayerTransformAfterLayout();

  clearNeedsLayout();
  return true;
}

LayoutUnit RenderBlock::marginIntrinsicLogicalWidthForChild(
    RenderBox* child) const {
  // A margin has three types: fixed, percentage, and auto (variable).
  // Auto and percentage margins become 0 when computing min/max width.
  // Fixed margins can be added in as is.
  Length marginLeft = child->style()->marginStartUsing(style());
  Length marginRight = child->style()->marginEndUsing(style());
  LayoutUnit margin = 0;
  if (marginLeft.isFixed())
    margin += marginLeft.value();
  if (marginRight.isFixed())
    margin += marginRight.value();
  return margin;
}

void RenderBlock::layoutPositionedObjects(bool relayoutChildren,
                                          PositionedLayoutBehavior info) {
  TrackedRendererListHashSet* positionedDescendants = positionedObjects();
  if (!positionedDescendants)
    return;

  RenderBox* r;
  TrackedRendererListHashSet::iterator end = positionedDescendants->end();
  for (TrackedRendererListHashSet::iterator it = positionedDescendants->begin();
       it != end; ++it) {
    r = *it;

    // If relayoutChildren is set and the child has percentage padding or an
    // embedded content box, we also need to invalidate the childs pref widths.
    if (relayoutChildren && r->needsPreferredWidthsRecalculation())
      r->setPreferredLogicalWidthsDirty(MarkOnlyThis);

    if (info == ForcedLayoutAfterContainingBlockMoved)
      r->setNeedsPositionedMovementLayout();

    r->layoutIfNeeded();
  }
}

void RenderBlock::markPositionedObjectsForLayout() {
  if (TrackedRendererListHashSet* positionedDescendants = positionedObjects()) {
    TrackedRendererListHashSet::iterator end = positionedDescendants->end();
    for (TrackedRendererListHashSet::iterator it =
             positionedDescendants->begin();
         it != end; ++it)
      (*it)->setChildNeedsLayout();
  }
}

void RenderBlock::paint(PaintInfo& paintInfo,
                        const LayoutPoint& paintOffset,
                        Vector<RenderBox*>& layers) {
  LayoutPoint adjustedPaintOffset = paintOffset + location();

  LayoutRect overflowBox = visualOverflowRect();
  overflowBox.moveBy(adjustedPaintOffset);
  if (!overflowBox.intersects(paintInfo.rect))
    return;

  // There are some cases where not all clipped visual overflow is accounted
  // for.
  // FIXME: reduce the number of such cases.
  ContentsClipBehavior contentsClipBehavior = ForceContentsClip;
  if (hasOverflowClip() && !shouldPaintSelectionGaps())
    contentsClipBehavior = SkipContentsClipIfPossible;

  bool pushedClip =
      pushContentsClip(paintInfo, adjustedPaintOffset, contentsClipBehavior);
  paintObject(paintInfo, adjustedPaintOffset, layers);
  if (pushedClip)
    popContentsClip(paintInfo, adjustedPaintOffset);
}

void RenderBlock::paintChildren(PaintInfo& paintInfo,
                                const LayoutPoint& paintOffset,
                                Vector<RenderBox*>& layers) {
  for (RenderBox* child = firstChildBox(); child;
       child = child->nextSiblingBox()) {
    if (child->hasSelfPaintingLayer())
      layers.append(child);
    else
      child->paint(paintInfo, paintOffset, layers);
  }
}

void RenderBlock::paintObject(PaintInfo& paintInfo,
                              const LayoutPoint& paintOffset,
                              Vector<RenderBox*>& layers) {
  if (hasBoxDecorationBackground())
    paintBoxDecorationBackground(paintInfo, paintOffset);

  paintChildren(paintInfo, paintOffset, layers);
  paintSelection(
      paintInfo,
      paintOffset);  // Fill in gaps in selection on lines and between blocks.
}

bool RenderBlock::shouldPaintSelectionGaps() const {
  return selectionState() != SelectionNone && isSelectionRoot();
}

bool RenderBlock::isSelectionRoot() const {
  return false;
}

void RenderBlock::paintSelection(PaintInfo& paintInfo,
                                 const LayoutPoint& paintOffset) {
  if (shouldPaintSelectionGaps()) {
    LayoutUnit lastTop = 0;
    LayoutUnit lastLeft = logicalLeftSelectionOffset(this, lastTop);
    LayoutUnit lastRight = logicalRightSelectionOffset(this, lastTop);
    GraphicsContextStateSaver stateSaver(*paintInfo.context);

    // TODO(ojan): In sky, we don't use the return value, but we
    // need this in order to actually paint selection gaps.
    // We should rename it appropriately.
    selectionGaps(this, paintOffset, LayoutSize(), lastTop, lastLeft, lastRight,
                  &paintInfo);
  }
}

static void clipOutPositionedObjects(
    const PaintInfo* paintInfo,
    const LayoutPoint& offset,
    TrackedRendererListHashSet* positionedObjects) {
  if (!positionedObjects)
    return;

  TrackedRendererListHashSet::const_iterator end = positionedObjects->end();
  for (TrackedRendererListHashSet::const_iterator it =
           positionedObjects->begin();
       it != end; ++it) {
    RenderBox* r = *it;
    paintInfo->context->clipOut(IntRect(
        offset.x() + r->x(), offset.y() + r->y(), r->width(), r->height()));
  }
}

LayoutUnit RenderBlock::blockDirectionOffset(
    const LayoutSize& offsetFromBlock) const {
  // FIXME(sky): Remove
  return offsetFromBlock.height();
}

LayoutUnit RenderBlock::inlineDirectionOffset(
    const LayoutSize& offsetFromBlock) const {
  // FIXME(sky): Remove
  return offsetFromBlock.width();
}

LayoutRect RenderBlock::logicalRectToPhysicalRect(
    const LayoutPoint& rootBlockPhysicalPosition,
    const LayoutRect& logicalRect) {
  LayoutRect result = logicalRect;
  result.moveBy(rootBlockPhysicalPosition);
  return result;
}

GapRects RenderBlock::selectionGaps(
    RenderBlock* rootBlock,
    const LayoutPoint& rootBlockPhysicalPosition,
    const LayoutSize& offsetFromRootBlock,
    LayoutUnit& lastLogicalTop,
    LayoutUnit& lastLogicalLeft,
    LayoutUnit& lastLogicalRight,
    const PaintInfo* paintInfo) {
  // IMPORTANT: Callers of this method that intend for painting to happen need
  // to do a save/restore. Clip out floating and positioned objects when
  // painting selection gaps.
  if (paintInfo) {
    // Note that we don't clip out overflow for positioned objects.  We just
    // stick to the border box.
    LayoutRect blockRect(offsetFromRootBlock.width(),
                         offsetFromRootBlock.height(), width(), height());
    blockRect.moveBy(rootBlockPhysicalPosition);
    clipOutPositionedObjects(paintInfo, blockRect.location(),
                             positionedObjects());
  }

  // FIXME: overflow: auto/scroll regions need more math here, since painting in
  // the border box is different from painting in the padding box (one is
  // scrolled, the other is fixed).
  GapRects result;
  if (!isRenderParagraph())  // FIXME: Make multi-column selection gap filling
                             // work someday.
    return result;

  if (hasTransform()) {
    // FIXME: We should learn how to gap fill multiple columns and transforms
    // eventually.
    lastLogicalTop =
        rootBlock->blockDirectionOffset(offsetFromRootBlock) + logicalHeight();
    lastLogicalLeft = logicalLeftSelectionOffset(rootBlock, logicalHeight());
    lastLogicalRight = logicalRightSelectionOffset(rootBlock, logicalHeight());
    return result;
  }

  if (isRenderParagraph())
    result = toRenderParagraph(this)->inlineSelectionGaps(
        rootBlock, rootBlockPhysicalPosition, offsetFromRootBlock,
        lastLogicalTop, lastLogicalLeft, lastLogicalRight, paintInfo);
  else
    result = blockSelectionGaps(rootBlock, rootBlockPhysicalPosition,
                                offsetFromRootBlock, lastLogicalTop,
                                lastLogicalLeft, lastLogicalRight, paintInfo);

  // Go ahead and fill the vertical gap all the way to the bottom of our block
  // if the selection extends past our block.
  if (rootBlock == this &&
      (selectionState() != SelectionBoth && selectionState() != SelectionEnd))
    result.uniteCenter(blockSelectionGap(rootBlock, rootBlockPhysicalPosition,
                                         offsetFromRootBlock, lastLogicalTop,
                                         lastLogicalLeft, lastLogicalRight,
                                         logicalHeight(), paintInfo));
  return result;
}

GapRects RenderBlock::blockSelectionGaps(
    RenderBlock* rootBlock,
    const LayoutPoint& rootBlockPhysicalPosition,
    const LayoutSize& offsetFromRootBlock,
    LayoutUnit& lastLogicalTop,
    LayoutUnit& lastLogicalLeft,
    LayoutUnit& lastLogicalRight,
    const PaintInfo* paintInfo) {
  GapRects result;

  // Go ahead and jump right to the first block child that contains some
  // selected objects.
  RenderBox* curr;
  for (curr = firstChildBox(); curr && curr->selectionState() == SelectionNone;
       curr = curr->nextSiblingBox()) {
  }

  for (bool sawSelectionEnd = false; curr && !sawSelectionEnd;
       curr = curr->nextSiblingBox()) {
    SelectionState childState = curr->selectionState();
    if (childState == SelectionBoth || childState == SelectionEnd)
      sawSelectionEnd = true;

    if (curr->isFloatingOrOutOfFlowPositioned())
      continue;  // We must be a normal flow object in order to even be
                 // considered.

    bool paintsOwnSelection = curr->shouldPaintSelectionGaps();
    bool fillBlockGaps = paintsOwnSelection || (curr->canBeSelectionLeaf() &&
                                                childState != SelectionNone);
    if (fillBlockGaps) {
      // We need to fill the vertical gap above this object.
      if (childState == SelectionEnd || childState == SelectionInside)
        // Fill the gap above the object.
        result.uniteCenter(blockSelectionGap(
            rootBlock, rootBlockPhysicalPosition, offsetFromRootBlock,
            lastLogicalTop, lastLogicalLeft, lastLogicalRight,
            curr->logicalTop(), paintInfo));

      // Only fill side gaps for objects that paint their own selection if we
      // know for sure the selection is going to extend all the way *past* our
      // object.  We know this if the selection did not end inside our object.
      if (paintsOwnSelection &&
          (childState == SelectionStart || sawSelectionEnd))
        childState = SelectionNone;

      // Fill side gaps on this object based off its state.
      bool leftGap, rightGap;
      getSelectionGapInfo(childState, leftGap, rightGap);

      if (leftGap)
        result.uniteLeft(logicalLeftSelectionGap(
            rootBlock, rootBlockPhysicalPosition, offsetFromRootBlock, this,
            curr->logicalLeft(), curr->logicalTop(), curr->logicalHeight(),
            paintInfo));
      if (rightGap)
        result.uniteRight(logicalRightSelectionGap(
            rootBlock, rootBlockPhysicalPosition, offsetFromRootBlock, this,
            curr->logicalRight(), curr->logicalTop(), curr->logicalHeight(),
            paintInfo));

      // Update lastLogicalTop to be just underneath the object.
      // lastLogicalLeft and lastLogicalRight extend as far as they can without
      // bumping into floating or positioned objects.  Ideally they will go
      // right up to the border of the root selection block.
      lastLogicalTop = rootBlock->blockDirectionOffset(offsetFromRootBlock) +
                       curr->logicalBottom();
      lastLogicalLeft =
          logicalLeftSelectionOffset(rootBlock, curr->logicalBottom());
      lastLogicalRight =
          logicalRightSelectionOffset(rootBlock, curr->logicalBottom());
    } else if (childState != SelectionNone)
      // We must be a block that has some selected object inside it.  Go ahead
      // and recur.
      result.unite(toRenderBlock(curr)->selectionGaps(
          rootBlock, rootBlockPhysicalPosition,
          LayoutSize(offsetFromRootBlock.width() + curr->x(),
                     offsetFromRootBlock.height() + curr->y()),
          lastLogicalTop, lastLogicalLeft, lastLogicalRight, paintInfo));
  }
  return result;
}

IntRect alignSelectionRectToDevicePixels(LayoutRect& rect) {
  LayoutUnit roundedX = rect.x().round();
  return IntRect(roundedX, rect.y().round(), (rect.maxX() - roundedX).round(),
                 snapSizeToPixel(rect.height(), rect.y()));
}

LayoutRect RenderBlock::blockSelectionGap(
    RenderBlock* rootBlock,
    const LayoutPoint& rootBlockPhysicalPosition,
    const LayoutSize& offsetFromRootBlock,
    LayoutUnit lastLogicalTop,
    LayoutUnit lastLogicalLeft,
    LayoutUnit lastLogicalRight,
    LayoutUnit logicalBottom,
    const PaintInfo* paintInfo) {
  LayoutUnit logicalTop = lastLogicalTop;
  LayoutUnit logicalHeight =
      rootBlock->blockDirectionOffset(offsetFromRootBlock) + logicalBottom -
      logicalTop;
  if (logicalHeight <= 0)
    return LayoutRect();

  // Get the selection offsets for the bottom of the gap
  LayoutUnit logicalLeft = std::max(
      lastLogicalLeft, logicalLeftSelectionOffset(rootBlock, logicalBottom));
  LayoutUnit logicalRight = std::min(
      lastLogicalRight, logicalRightSelectionOffset(rootBlock, logicalBottom));
  LayoutUnit logicalWidth = logicalRight - logicalLeft;
  if (logicalWidth <= 0)
    return LayoutRect();

  LayoutRect gapRect = rootBlock->logicalRectToPhysicalRect(
      rootBlockPhysicalPosition,
      LayoutRect(logicalLeft, logicalTop, logicalWidth, logicalHeight));
  if (paintInfo)
    paintInfo->context->fillRect(alignSelectionRectToDevicePixels(gapRect),
                                 selectionBackgroundColor());
  return gapRect;
}

LayoutRect RenderBlock::logicalLeftSelectionGap(
    RenderBlock* rootBlock,
    const LayoutPoint& rootBlockPhysicalPosition,
    const LayoutSize& offsetFromRootBlock,
    RenderObject* selObj,
    LayoutUnit logicalLeft,
    LayoutUnit logicalTop,
    LayoutUnit logicalHeight,
    const PaintInfo* paintInfo) {
  LayoutUnit rootBlockLogicalTop =
      rootBlock->blockDirectionOffset(offsetFromRootBlock) + logicalTop;
  LayoutUnit rootBlockLogicalLeft = std::max(
      logicalLeftSelectionOffset(rootBlock, logicalTop),
      logicalLeftSelectionOffset(rootBlock, logicalTop + logicalHeight));
  LayoutUnit rootBlockLogicalRight = std::min(
      rootBlock->inlineDirectionOffset(offsetFromRootBlock) + logicalLeft,
      std::min(
          logicalRightSelectionOffset(rootBlock, logicalTop),
          logicalRightSelectionOffset(rootBlock, logicalTop + logicalHeight)));
  LayoutUnit rootBlockLogicalWidth =
      rootBlockLogicalRight - rootBlockLogicalLeft;
  if (rootBlockLogicalWidth <= 0)
    return LayoutRect();

  LayoutRect gapRect = rootBlock->logicalRectToPhysicalRect(
      rootBlockPhysicalPosition,
      LayoutRect(rootBlockLogicalLeft, rootBlockLogicalTop,
                 rootBlockLogicalWidth, logicalHeight));
  if (paintInfo)
    paintInfo->context->fillRect(alignSelectionRectToDevicePixels(gapRect),
                                 selObj->selectionBackgroundColor());
  return gapRect;
}

LayoutRect RenderBlock::logicalRightSelectionGap(
    RenderBlock* rootBlock,
    const LayoutPoint& rootBlockPhysicalPosition,
    const LayoutSize& offsetFromRootBlock,
    RenderObject* selObj,
    LayoutUnit logicalRight,
    LayoutUnit logicalTop,
    LayoutUnit logicalHeight,
    const PaintInfo* paintInfo) {
  LayoutUnit rootBlockLogicalTop =
      rootBlock->blockDirectionOffset(offsetFromRootBlock) + logicalTop;
  LayoutUnit rootBlockLogicalLeft = std::max(
      rootBlock->inlineDirectionOffset(offsetFromRootBlock) + logicalRight,
      max(logicalLeftSelectionOffset(rootBlock, logicalTop),
          logicalLeftSelectionOffset(rootBlock, logicalTop + logicalHeight)));
  LayoutUnit rootBlockLogicalRight = std::min(
      logicalRightSelectionOffset(rootBlock, logicalTop),
      logicalRightSelectionOffset(rootBlock, logicalTop + logicalHeight));
  LayoutUnit rootBlockLogicalWidth =
      rootBlockLogicalRight - rootBlockLogicalLeft;
  if (rootBlockLogicalWidth <= 0)
    return LayoutRect();

  LayoutRect gapRect = rootBlock->logicalRectToPhysicalRect(
      rootBlockPhysicalPosition,
      LayoutRect(rootBlockLogicalLeft, rootBlockLogicalTop,
                 rootBlockLogicalWidth, logicalHeight));
  if (paintInfo)
    paintInfo->context->fillRect(alignSelectionRectToDevicePixels(gapRect),
                                 selObj->selectionBackgroundColor());
  return gapRect;
}

void RenderBlock::getSelectionGapInfo(SelectionState state,
                                      bool& leftGap,
                                      bool& rightGap) {
  bool ltr = style()->isLeftToRightDirection();
  leftGap = (state == RenderObject::SelectionInside) ||
            (state == RenderObject::SelectionEnd && ltr) ||
            (state == RenderObject::SelectionStart && !ltr);
  rightGap = (state == RenderObject::SelectionInside) ||
             (state == RenderObject::SelectionStart && ltr) ||
             (state == RenderObject::SelectionEnd && !ltr);
}

LayoutUnit RenderBlock::logicalLeftSelectionOffset(RenderBlock* rootBlock,
                                                   LayoutUnit position) {
  // The border can potentially be further extended by our containingBlock().
  if (rootBlock != this)
    return containingBlock()->logicalLeftSelectionOffset(
        rootBlock, position + logicalTop());
  return logicalLeftOffsetForContent();
}

LayoutUnit RenderBlock::logicalRightSelectionOffset(RenderBlock* rootBlock,
                                                    LayoutUnit position) {
  // The border can potentially be further extended by our containingBlock().
  if (rootBlock != this)
    return containingBlock()->logicalRightSelectionOffset(
        rootBlock, position + logicalTop());
  return logicalRightOffsetForContent();
}

RenderBlock* RenderBlock::blockBeforeWithinSelectionRoot(
    LayoutSize& offset) const {
  if (isSelectionRoot())
    return 0;

  const RenderObject* object = this;
  RenderObject* sibling;
  do {
    sibling = object->previousSibling();
    while (sibling && (!sibling->isRenderBlock() ||
                       toRenderBlock(sibling)->isSelectionRoot()))
      sibling = sibling->previousSibling();

    offset -= LayoutSize(toRenderBlock(object)->logicalLeft(),
                         toRenderBlock(object)->logicalTop());
    object = object->parent();
  } while (!sibling && object && object->isRenderBlock() &&
           !toRenderBlock(object)->isSelectionRoot());

  if (!sibling)
    return 0;

  RenderBlock* beforeBlock = toRenderBlock(sibling);

  offset += LayoutSize(beforeBlock->logicalLeft(), beforeBlock->logicalTop());

  RenderObject* child = beforeBlock->lastChild();
  while (child && child->isRenderBlock()) {
    beforeBlock = toRenderBlock(child);
    offset += LayoutSize(beforeBlock->logicalLeft(), beforeBlock->logicalTop());
    child = beforeBlock->lastChild();
  }
  return beforeBlock;
}

void RenderBlock::setSelectionState(SelectionState state) {
  RenderBox::setSelectionState(state);

  if (inlineBoxWrapper() && canUpdateSelectionOnRootLineBoxes())
    inlineBoxWrapper()->root().setHasSelectedChildren(state != SelectionNone);
}

void RenderBlock::insertIntoTrackedRendererMaps(
    RenderBox* descendant,
    TrackedDescendantsMap*& descendantsMap,
    TrackedContainerMap*& containerMap) {
  if (!descendantsMap) {
    descendantsMap = new TrackedDescendantsMap;
    containerMap = new TrackedContainerMap;
  }

  TrackedRendererListHashSet* descendantSet = descendantsMap->get(this);
  if (!descendantSet) {
    descendantSet = new TrackedRendererListHashSet;
    descendantsMap->set(this, adoptPtr(descendantSet));
  }
  bool added = descendantSet->add(descendant).isNewEntry;
  if (!added) {
    ASSERT(containerMap->get(descendant));
    ASSERT(containerMap->get(descendant)->contains(this));
    return;
  }

  HashSet<RenderBlock*>* containerSet = containerMap->get(descendant);
  if (!containerSet) {
    containerSet = new HashSet<RenderBlock*>;
    containerMap->set(descendant, adoptPtr(containerSet));
  }
  ASSERT(!containerSet->contains(this));
  containerSet->add(this);
}

void RenderBlock::removeFromTrackedRendererMaps(
    RenderBox* descendant,
    TrackedDescendantsMap*& descendantsMap,
    TrackedContainerMap*& containerMap) {
  if (!descendantsMap)
    return;

  OwnPtr<HashSet<RenderBlock*>> containerSet = containerMap->take(descendant);
  if (!containerSet)
    return;

  HashSet<RenderBlock*>::iterator end = containerSet->end();
  for (HashSet<RenderBlock*>::iterator it = containerSet->begin(); it != end;
       ++it) {
    RenderBlock* container = *it;

    // FIXME: Disabling this assert temporarily until we fix the layout
    // bugs associated with positioned objects not properly cleared from
    // their ancestor chain before being moved. See webkit bug 93766.
    // ASSERT(descendant->isDescendantOf(container));

    TrackedDescendantsMap::iterator descendantsMapIterator =
        descendantsMap->find(container);
    ASSERT(descendantsMapIterator != descendantsMap->end());
    if (descendantsMapIterator == descendantsMap->end())
      continue;
    TrackedRendererListHashSet* descendantSet =
        descendantsMapIterator->value.get();
    ASSERT(descendantSet->contains(descendant));
    descendantSet->remove(descendant);
    if (descendantSet->isEmpty())
      descendantsMap->remove(descendantsMapIterator);
  }
}

TrackedRendererListHashSet* RenderBlock::positionedObjects() const {
  if (gPositionedDescendantsMap)
    return gPositionedDescendantsMap->get(this);
  return 0;
}

void RenderBlock::insertPositionedObject(RenderBox* o) {
  insertIntoTrackedRendererMaps(o, gPositionedDescendantsMap,
                                gPositionedContainerMap);
}

void RenderBlock::removePositionedObject(RenderBox* o) {
  removeFromTrackedRendererMaps(o, gPositionedDescendantsMap,
                                gPositionedContainerMap);
}

void RenderBlock::removePositionedObjects(
    RenderBlock* o,
    ContainingBlockState containingBlockState) {
  TrackedRendererListHashSet* positionedDescendants = positionedObjects();
  if (!positionedDescendants)
    return;

  RenderBox* r;

  TrackedRendererListHashSet::iterator end = positionedDescendants->end();

  Vector<RenderBox*, 16> deadObjects;

  for (TrackedRendererListHashSet::iterator it = positionedDescendants->begin();
       it != end; ++it) {
    r = *it;
    if (!o || r->isDescendantOf(o)) {
      if (containingBlockState == NewContainingBlock)
        r->setChildNeedsLayout(MarkOnlyThis);

      // It is parent blocks job to add positioned child to positioned objects
      // list of its containing block Parent layout needs to be invalidated to
      // ensure this happens.
      RenderObject* p = r->parent();
      while (p && !p->isRenderBlock())
        p = p->parent();
      if (p)
        p->setChildNeedsLayout();

      deadObjects.append(r);
    }
  }

  for (unsigned i = 0; i < deadObjects.size(); i++)
    removePositionedObject(deadObjects.at(i));
}

void RenderBlock::addPercentHeightDescendant(RenderBox* descendant) {
  insertIntoTrackedRendererMaps(descendant, gPercentHeightDescendantsMap,
                                gPercentHeightContainerMap);
}

void RenderBlock::removePercentHeightDescendant(RenderBox* descendant) {
  removeFromTrackedRendererMaps(descendant, gPercentHeightDescendantsMap,
                                gPercentHeightContainerMap);
}

TrackedRendererListHashSet* RenderBlock::percentHeightDescendants() const {
  return gPercentHeightDescendantsMap ? gPercentHeightDescendantsMap->get(this)
                                      : 0;
}

bool RenderBlock::hasPercentHeightContainerMap() {
  return gPercentHeightContainerMap;
}

bool RenderBlock::hasPercentHeightDescendant(RenderBox* descendant) {
  // We don't null check gPercentHeightContainerMap since the caller
  // already ensures this and we need to call this function on every
  // descendant in clearPercentHeightDescendantsFrom().
  ASSERT(gPercentHeightContainerMap);
  return gPercentHeightContainerMap->contains(descendant);
}

void RenderBlock::dirtyForLayoutFromPercentageHeightDescendants(
    SubtreeLayoutScope& layoutScope) {
  if (!gPercentHeightDescendantsMap)
    return;

  TrackedRendererListHashSet* descendants =
      gPercentHeightDescendantsMap->get(this);
  if (!descendants)
    return;

  TrackedRendererListHashSet::iterator end = descendants->end();
  for (TrackedRendererListHashSet::iterator it = descendants->begin();
       it != end; ++it) {
    RenderBox* box = *it;
    while (box != this) {
      if (box->normalChildNeedsLayout())
        break;
      layoutScope.setChildNeedsLayout(box);
      box = box->containingBlock();
      ASSERT(box);
      if (!box)
        break;
    }
  }
}

void RenderBlock::removePercentHeightDescendantIfNeeded(RenderBox* descendant) {
  // We query the map directly, rather than looking at style's
  // logicalHeight()/logicalMinHeight()/logicalMaxHeight() since those
  // can change with writing mode/directional changes.
  if (!hasPercentHeightContainerMap())
    return;

  if (!hasPercentHeightDescendant(descendant))
    return;

  removePercentHeightDescendant(descendant);
}

void RenderBlock::clearPercentHeightDescendantsFrom(RenderBox* parent) {
  ASSERT(gPercentHeightContainerMap);
  for (RenderObject* curr = parent->slowFirstChild(); curr;
       curr = curr->nextInPreOrder(parent)) {
    if (!curr->isBox())
      continue;

    RenderBox* box = toRenderBox(curr);
    if (!hasPercentHeightDescendant(box))
      continue;

    removePercentHeightDescendant(box);
  }
}

LayoutUnit RenderBlock::textIndentOffset() const {
  LayoutUnit cw = 0;
  if (style()->textIndent().isPercent())
    cw = containingBlock()->availableLogicalWidth();
  return minimumValueForLength(style()->textIndent(), cw);
}

bool RenderBlock::nodeAtPoint(const HitTestRequest& request,
                              HitTestResult& result,
                              const HitTestLocation& locationInContainer,
                              const LayoutPoint& accumulatedOffset) {
  LayoutPoint adjustedLocation(accumulatedOffset + location());
  LayoutSize localOffset = toLayoutSize(adjustedLocation);

  if (!isRenderView()) {
    // Check if we need to do anything at all.
    // If we have clipping, then we can't have any spillout.
    LayoutRect overflowBox =
        hasOverflowClip() ? borderBoxRect() : visualOverflowRect();
    overflowBox.moveBy(adjustedLocation);
    if (!locationInContainer.intersects(overflowBox))
      return false;
  }

  if (style()->clipPath()) {
    switch (style()->clipPath()->type()) {
      case ClipPathOperation::SHAPE:
        break;
      case ClipPathOperation::REFERENCE:
        break;
    }
  }

  // If we have clipping, then we can't have any spillout.
  bool useOverflowClip = hasOverflowClip() && !hasSelfPaintingLayer();
  bool checkChildren = !useOverflowClip;
  if (!checkChildren) {
    LayoutRect clipRect = overflowClipRect(adjustedLocation);
    if (style()->hasBorderRadius())
      checkChildren = locationInContainer.intersects(
          style()->getRoundedBorderFor(clipRect));
    else
      checkChildren = locationInContainer.intersects(clipRect);
  }
  if (checkChildren) {
    if (hitTestContents(request, result, locationInContainer,
                        toLayoutPoint(localOffset))) {
      updateHitTestResult(result, locationInContainer.point() - localOffset);
      return true;
    }
  }

  // Check if the point is outside radii.
  if (style()->hasBorderRadius()) {
    LayoutRect borderRect = borderBoxRect();
    borderRect.moveBy(adjustedLocation);
    RoundedRect border = style()->getRoundedBorderFor(borderRect);
    if (!locationInContainer.intersects(border))
      return false;
  }

  // Now hit test our background
  LayoutRect boundsRect(adjustedLocation, size());
  if (visibleToHitTestRequest(request) &&
      locationInContainer.intersects(boundsRect)) {
    updateHitTestResult(result, locationInContainer.point() - localOffset);
    return true;
  }

  return false;
}

bool RenderBlock::hitTestContents(const HitTestRequest& request,
                                  HitTestResult& result,
                                  const HitTestLocation& locationInContainer,
                                  const LayoutPoint& accumulatedOffset) {
  for (RenderBox* child = lastChildBox(); child;
       child = child->previousSiblingBox()) {
    if (!child->hasSelfPaintingLayer() &&
        child->nodeAtPoint(request, result, locationInContainer,
                           accumulatedOffset))
      return true;
  }

  return false;
}

static PositionWithAffinity positionForPointInChild(
    RenderBox* child,
    const LayoutPoint& pointInParentCoordinates) {
  LayoutPoint childLocation = child->location();

  // FIXME: This is wrong if the child's writing-mode is different from the
  // parent's.
  LayoutPoint pointInChildCoordinates(
      toLayoutPoint(pointInParentCoordinates - childLocation));
  return child->positionForPoint(pointInChildCoordinates);
}

PositionWithAffinity RenderBlock::positionForPointWithInlineChildren(
    const LayoutPoint& pointInLogicalContents) {
  ASSERT(isRenderParagraph());

  if (!firstRootBox())
    return createPositionWithAffinity(0, DOWNSTREAM);

  // look for the closest line box in the root box which is at the passed-in y
  // coordinate
  InlineBox* closestBox = 0;
  RootInlineBox* firstRootBoxWithChildren = 0;
  RootInlineBox* lastRootBoxWithChildren = 0;
  for (RootInlineBox* root = firstRootBox(); root; root = root->nextRootBox()) {
    if (!root->firstLeafChild())
      continue;
    if (!firstRootBoxWithChildren)
      firstRootBoxWithChildren = root;

    lastRootBoxWithChildren = root;

    // check if this root line box is located at this y coordinate
    if (pointInLogicalContents.y() < root->selectionBottom()) {
      closestBox = root->closestLeafChildForLogicalLeftPosition(
          pointInLogicalContents.x());
      if (closestBox)
        break;
    }
  }

  if (!closestBox && lastRootBoxWithChildren) {
    // y coordinate is below last root line box, pretend we hit it
    closestBox =
        lastRootBoxWithChildren->closestLeafChildForLogicalLeftPosition(
            pointInLogicalContents.x());
  }

  if (closestBox) {
    // pass the box a top position that is inside it
    LayoutPoint point(pointInLogicalContents.x(),
                      closestBox->root().blockDirectionPointInLine());
    if (closestBox->renderer().isReplaced())
      return positionForPointInChild(&toRenderBox(closestBox->renderer()),
                                     point);
    return closestBox->renderer().positionForPoint(point);
  }

  // Can't reach this. We have a root line box, but it has no kids.
  // FIXME: This should ASSERT_NOT_REACHED(), but clicking on placeholder text
  // seems to hit this code path.
  return createPositionWithAffinity(0, DOWNSTREAM);
}

static inline bool isChildHitTestCandidate(RenderBox* box) {
  return box->height() && !box->isFloatingOrOutOfFlowPositioned();
}

PositionWithAffinity RenderBlock::positionForPoint(const LayoutPoint& point) {
  if (isReplaced()) {
    // FIXME: This seems wrong when the object's writing-mode doesn't match the
    // line's writing-mode.
    LayoutUnit pointLogicalLeft = point.x();
    LayoutUnit pointLogicalTop = point.y();

    if (pointLogicalLeft < 0)
      return createPositionWithAffinity(caretMinOffset(), DOWNSTREAM);
    if (pointLogicalLeft >= logicalWidth())
      return createPositionWithAffinity(caretMaxOffset(), DOWNSTREAM);
    if (pointLogicalTop < 0)
      return createPositionWithAffinity(caretMinOffset(), DOWNSTREAM);
    if (pointLogicalTop >= logicalHeight())
      return createPositionWithAffinity(caretMaxOffset(), DOWNSTREAM);
  }

  LayoutPoint pointInContents = point;
  LayoutPoint pointInLogicalContents(pointInContents);

  if (isRenderParagraph())
    return positionForPointWithInlineChildren(pointInLogicalContents);

  RenderBox* lastCandidateBox = lastChildBox();
  while (lastCandidateBox && !isChildHitTestCandidate(lastCandidateBox))
    lastCandidateBox = lastCandidateBox->previousSiblingBox();

  if (lastCandidateBox) {
    if (pointInLogicalContents.y() > logicalTopForChild(lastCandidateBox) ||
        (pointInLogicalContents.y() == logicalTopForChild(lastCandidateBox)))
      return positionForPointInChild(lastCandidateBox, pointInContents);

    for (RenderBox* childBox = firstChildBox(); childBox;
         childBox = childBox->nextSiblingBox()) {
      if (!isChildHitTestCandidate(childBox))
        continue;
      LayoutUnit childLogicalBottom =
          logicalTopForChild(childBox) + logicalHeightForChild(childBox);
      // We hit child if our click is above the bottom of its padding box (like
      // IE6/7 and FF3).
      if (isChildHitTestCandidate(childBox) &&
          (pointInLogicalContents.y() < childLogicalBottom))
        return positionForPointInChild(childBox, pointInContents);
    }
  }

  // We only get here if there are no hit test candidate children below the
  // click.
  return RenderBox::positionForPoint(point);
}

LayoutUnit RenderBlock::availableLogicalWidth() const {
  return RenderBox::availableLogicalWidth();
}

void RenderBlock::computePreferredLogicalWidths() {
  ASSERT(preferredLogicalWidthsDirty());

  m_minPreferredLogicalWidth = 0;
  m_maxPreferredLogicalWidth = 0;

  // FIXME: The isFixed() calls here should probably be checking for isSpecified
  // since you should be able to use percentage, calc or viewport relative
  // values for width.
  RenderStyle* styleToUse = style();
  if (styleToUse->logicalWidth().isFixed() &&
      styleToUse->logicalWidth().value() >= 0)
    m_minPreferredLogicalWidth = m_maxPreferredLogicalWidth =
        adjustContentBoxLogicalWidthForBoxSizing(
            styleToUse->logicalWidth().value());
  else
    computeIntrinsicLogicalWidths(m_minPreferredLogicalWidth,
                                  m_maxPreferredLogicalWidth);

  if (styleToUse->logicalMinWidth().isFixed() &&
      styleToUse->logicalMinWidth().value() > 0) {
    m_maxPreferredLogicalWidth = std::max(
        m_maxPreferredLogicalWidth, adjustContentBoxLogicalWidthForBoxSizing(
                                        styleToUse->logicalMinWidth().value()));
    m_minPreferredLogicalWidth = std::max(
        m_minPreferredLogicalWidth, adjustContentBoxLogicalWidthForBoxSizing(
                                        styleToUse->logicalMinWidth().value()));
  }

  if (styleToUse->logicalMaxWidth().isFixed()) {
    m_maxPreferredLogicalWidth = std::min(
        m_maxPreferredLogicalWidth, adjustContentBoxLogicalWidthForBoxSizing(
                                        styleToUse->logicalMaxWidth().value()));
    m_minPreferredLogicalWidth = std::min(
        m_minPreferredLogicalWidth, adjustContentBoxLogicalWidthForBoxSizing(
                                        styleToUse->logicalMaxWidth().value()));
  }

  LayoutUnit borderAndPadding = borderAndPaddingLogicalWidth();
  m_minPreferredLogicalWidth += borderAndPadding;
  m_maxPreferredLogicalWidth += borderAndPadding;

  clearPreferredLogicalWidthsDirty();
}

void RenderBlock::computeIntrinsicLogicalWidths(
    LayoutUnit& minLogicalWidth,
    LayoutUnit& maxLogicalWidth) const {
  RenderStyle* styleToUse = style();
  bool nowrap = styleToUse->whiteSpace() == NOWRAP;

  RenderObject* child = firstChild();
  while (child) {
    // Positioned children don't affect the min/max width
    if (child->isOutOfFlowPositioned()) {
      child = child->nextSibling();
      continue;
    }

    RefPtr<RenderStyle> childStyle = child->style();

    // A margin basically has three types: fixed, percentage, and auto
    // (variable). Auto and percentage margins simply become 0 when computing
    // min/max width. Fixed margins can be added in as is.
    Length startMarginLength = childStyle->marginStartUsing(styleToUse);
    Length endMarginLength = childStyle->marginEndUsing(styleToUse);
    LayoutUnit margin = 0;
    LayoutUnit marginStart = 0;
    LayoutUnit marginEnd = 0;
    if (startMarginLength.isFixed())
      marginStart += startMarginLength.value();
    if (endMarginLength.isFixed())
      marginEnd += endMarginLength.value();
    margin = marginStart + marginEnd;

    LayoutUnit childMinPreferredLogicalWidth =
        child->minPreferredLogicalWidth();
    LayoutUnit childMaxPreferredLogicalWidth =
        child->maxPreferredLogicalWidth();

    LayoutUnit w = childMinPreferredLogicalWidth + margin;
    minLogicalWidth = std::max(w, minLogicalWidth);

    // IE ignores tables for calculation of nowrap. Makes some sense.
    if (nowrap)
      maxLogicalWidth = std::max(w, maxLogicalWidth);

    w = childMaxPreferredLogicalWidth + margin;

    maxLogicalWidth = std::max(w, maxLogicalWidth);

    child = child->nextSibling();
  }

  // Always make sure these values are non-negative.
  minLogicalWidth = std::max<LayoutUnit>(0, minLogicalWidth);
  maxLogicalWidth = std::max<LayoutUnit>(minLogicalWidth, maxLogicalWidth);
}

bool RenderBlock::hasLineIfEmpty() const {
  return false;
}

LayoutUnit RenderBlock::lineHeight(bool firstLine,
                                   LineDirectionMode direction,
                                   LinePositionMode linePositionMode) const {
  // Inline blocks are replaced elements. Otherwise, just pass off to
  // the base class.  If we're being queried as though we're the root line
  // box, then the fact that we're an inline-block is irrelevant, and we behave
  // just like a block.
  if (isReplaced() && linePositionMode == PositionOnContainingLine)
    return RenderBox::lineHeight(firstLine, direction, linePositionMode);
  return style()->computedLineHeight();
}

int RenderBlock::beforeMarginInLineDirection(
    LineDirectionMode direction) const {
  return direction == HorizontalLine ? marginTop() : marginRight();
}

int RenderBlock::baselinePosition(FontBaseline baselineType,
                                  bool firstLine,
                                  LineDirectionMode direction,
                                  LinePositionMode linePositionMode) const {
  // Inline blocks are replaced elements. Otherwise, just pass off to
  // the base class.  If we're being queried as though we're the root line
  // box, then the fact that we're an inline-block is irrelevant, and we behave
  // just like a block.
  if (isInline() && linePositionMode == PositionOnContainingLine) {
    // CSS2.1 states that the baseline of an inline block is the baseline of the
    // last line box in the normal flow.  We make an exception for marquees,
    // since their baselines are meaningless (the content inside them moves).
    // This matches WinIE as well, which just bottom-aligns them. We also give
    // up on finding a baseline if we have a vertical scrollbar, or if we are
    // scrolled vertically (e.g., an overflow:hidden block that has had
    // scrollTop moved).
    int baselinePos = inlineBlockBaseline(direction);
    if (baselinePos != -1)
      return beforeMarginInLineDirection(direction) + baselinePos;

    return RenderBox::baselinePosition(baselineType, firstLine, direction,
                                       linePositionMode);
  }

  // If we're not replaced, we'll only get called with
  // PositionOfInteriorLineBoxes. Note that inline-block counts as replaced
  // here.
  ASSERT(linePositionMode == PositionOfInteriorLineBoxes);

  const FontMetrics& fontMetrics = style(firstLine)->fontMetrics();
  return fontMetrics.ascent(baselineType) +
         (lineHeight(firstLine, direction, linePositionMode) -
          fontMetrics.height()) /
             2;
}

LayoutUnit RenderBlock::minLineHeightForReplacedRenderer(
    bool isFirstLine,
    LayoutUnit replacedHeight) const {
  if (!(style(isFirstLine)->lineBoxContain() & LineBoxContainBlock))
    return 0;

  return std::max<LayoutUnit>(
      replacedHeight,
      lineHeight(isFirstLine, HorizontalLine, PositionOfInteriorLineBoxes));
}

int RenderBlock::firstLineBoxBaseline(FontBaselineOrAuto baselineType) const {
  for (RenderBox* curr = firstChildBox(); curr; curr = curr->nextSiblingBox()) {
    if (!curr->isFloatingOrOutOfFlowPositioned()) {
      int result = curr->firstLineBoxBaseline(baselineType);
      if (result != -1)
        return curr->logicalTop() +
               result;  // Translate to our coordinate space.
    }
  }

  return -1;
}

int RenderBlock::inlineBlockBaseline(LineDirectionMode direction) const {
  if (!style()->isOverflowVisible()) {
    // We are not calling RenderBox::baselinePosition here because the caller
    // should add the margin-top/margin-right, not us.
    return direction == HorizontalLine ? height() + m_marginBox.bottom()
                                       : width() + m_marginBox.left();
  }

  return lastLineBoxBaseline(direction);
}

int RenderBlock::lastLineBoxBaseline(LineDirectionMode lineDirection) const {
  bool haveNormalFlowChild = false;
  for (RenderBox* curr = lastChildBox(); curr;
       curr = curr->previousSiblingBox()) {
    if (!curr->isFloatingOrOutOfFlowPositioned()) {
      haveNormalFlowChild = true;
      int result = curr->inlineBlockBaseline(lineDirection);
      if (result != -1)
        return curr->logicalTop() +
               result;  // Translate to our coordinate space.
    }
  }
  if (!haveNormalFlowChild && hasLineIfEmpty()) {
    const FontMetrics& fontMetrics = firstLineStyle()->fontMetrics();
    return fontMetrics.ascent() +
           (lineHeight(true, lineDirection, PositionOfInteriorLineBoxes) -
            fontMetrics.height()) /
               2 +
           (lineDirection == HorizontalLine ? borderTop() + paddingTop()
                                            : borderRight() + paddingRight());
  }

  return -1;
}

RenderBlock* RenderBlock::firstLineBlock() const {
  RenderBlock* firstLineBlock = const_cast<RenderBlock*>(this);
  bool hasPseudo = false;
  while (true) {
    // FIXME(sky): Remove all this.
    hasPseudo = false;
    if (hasPseudo)
      break;
    RenderObject* parentBlock = firstLineBlock->parent();
    if (firstLineBlock->isReplaced() || !parentBlock ||
        !parentBlock->isRenderParagraph())
      break;
    ASSERT_WITH_SECURITY_IMPLICATION(parentBlock->isRenderBlock());
    if (toRenderParagraph(parentBlock)->firstChild() != firstLineBlock)
      break;
    firstLineBlock = toRenderBlock(parentBlock);
  }

  if (!hasPseudo)
    return 0;

  return firstLineBlock;
}

// Helper methods for obtaining the last line, computing line counts and heights
// for line counts (crawling into blocks).
static bool shouldCheckLines(RenderObject* obj) {
  return !obj->isFloatingOrOutOfFlowPositioned() && obj->isRenderBlock() &&
         obj->style()->height().isAuto();
}

RootInlineBox* RenderBlock::lineAtIndex(int i) const {
  ASSERT(i >= 0);

  for (RenderObject* child = firstChild(); child;
       child = child->nextSibling()) {
    if (!shouldCheckLines(child))
      continue;
    if (RootInlineBox* box = toRenderBlock(child)->lineAtIndex(i))
      return box;
  }

  return 0;
}

int RenderBlock::lineCount(const RootInlineBox* stopRootInlineBox,
                           bool* found) const {
  int count = 0;
  for (RenderObject* obj = firstChild(); obj; obj = obj->nextSibling()) {
    if (shouldCheckLines(obj)) {
      bool recursiveFound = false;
      count +=
          toRenderBlock(obj)->lineCount(stopRootInlineBox, &recursiveFound);
      if (recursiveFound) {
        if (found)
          *found = true;
        break;
      }
    }
  }

  return count;
}

void RenderBlock::clearTruncation() {
  for (RenderObject* obj = firstChild(); obj; obj = obj->nextSibling()) {
    if (shouldCheckLines(obj))
      toRenderBlock(obj)->clearTruncation();
  }
}

void RenderBlock::absoluteQuads(Vector<FloatQuad>& quads) const {
  quads.append(RenderBox::localToAbsoluteQuad(
      FloatRect(0, 0, width().toFloat(), height().toFloat()), 0 /* mode */));
}

void RenderBlock::updateHitTestResult(HitTestResult& result,
                                      const LayoutPoint& point) {}

LayoutRect RenderBlock::localCaretRect(InlineBox* inlineBox,
                                       int caretOffset,
                                       LayoutUnit* extraWidthToEndOfLine) {
  // Do the normal calculation in most cases.
  if (firstChild())
    return RenderBox::localCaretRect(inlineBox, caretOffset,
                                     extraWidthToEndOfLine);

  LayoutRect caretRect =
      localCaretRectForEmptyElement(width(), textIndentOffset());

  if (extraWidthToEndOfLine)
    *extraWidthToEndOfLine = width() - caretRect.maxX();

  return caretRect;
}

void RenderBlock::addFocusRingRects(Vector<IntRect>& rects,
                                    const LayoutPoint& additionalOffset,
                                    const RenderBox* paintContainer) const {
  if (width() && height())
    rects.append(pixelSnappedIntRect(additionalOffset, size()));

  if (!hasOverflowClip()) {
    for (RootInlineBox* curr = firstRootBox(); curr;
         curr = curr->nextRootBox()) {
      LayoutUnit top = std::max<LayoutUnit>(curr->lineTop(), curr->top());
      LayoutUnit bottom = std::min<LayoutUnit>(curr->lineBottom(),
                                               curr->top() + curr->height());
      LayoutRect rect(additionalOffset.x() + curr->x(),
                      additionalOffset.y() + top, curr->width(), bottom - top);
      if (!rect.isEmpty())
        rects.append(pixelSnappedIntRect(rect));
    }

    addChildFocusRingRects(rects, additionalOffset, paintContainer);
  }
}

LayoutUnit RenderBlock::marginBeforeForChild(const RenderBox* child) const {
  // FIXME(sky): Remove
  return child->marginBefore();
}

LayoutUnit RenderBlock::marginAfterForChild(const RenderBox* child) const {
  // FIXME(sky): Remove
  return child->marginAfter();
}

bool RenderBlock::hasMarginBeforeQuirk(const RenderBox* child) const {
  return child->isRenderBlock() ? toRenderBlock(child)->hasMarginBeforeQuirk()
                                : child->style()->hasMarginBeforeQuirk();
}

bool RenderBlock::hasMarginAfterQuirk(const RenderBox* child) const {
  return child->isRenderBlock() ? toRenderBlock(child)->hasMarginAfterQuirk()
                                : child->style()->hasMarginAfterQuirk();
}

const char* RenderBlock::renderName() const {
  if (isInlineBlock())
    return "RenderBlock (inline-block)";
  if (isOutOfFlowPositioned())
    return "RenderBlock (positioned)";
  return "RenderBlock";
}

static bool recalcNormalFlowChildOverflowIfNeeded(RenderObject* renderer) {
  if (renderer->isOutOfFlowPositioned() ||
      !renderer->needsOverflowRecalcAfterStyleChange())
    return false;

  ASSERT(renderer->isRenderBlock());
  return toRenderBlock(renderer)->recalcOverflowAfterStyleChange();
}

bool RenderBlock::recalcChildOverflowAfterStyleChange() {
  ASSERT(childNeedsOverflowRecalcAfterStyleChange());
  setChildNeedsOverflowRecalcAfterStyleChange(false);

  bool childrenOverflowChanged = false;

  if (isRenderParagraph()) {
    ListHashSet<RootInlineBox*> lineBoxes;
    for (InlineWalker walker(this); !walker.atEnd(); walker.advance()) {
      RenderObject* renderer = walker.current();
      if (recalcNormalFlowChildOverflowIfNeeded(renderer)) {
        childrenOverflowChanged = true;
        if (InlineBox* inlineBoxWrapper =
                toRenderBlock(renderer)->inlineBoxWrapper())
          lineBoxes.add(&inlineBoxWrapper->root());
      }
    }

    // FIXME: Glyph overflow will get lost in this case, but not really a big
    // deal.
    GlyphOverflowAndFallbackFontsMap textBoxDataMap;
    for (ListHashSet<RootInlineBox*>::const_iterator it = lineBoxes.begin();
         it != lineBoxes.end(); ++it) {
      RootInlineBox* box = *it;
      box->computeOverflow(box->lineTop(), box->lineBottom(), textBoxDataMap);
    }
  } else {
    for (RenderBox* box = firstChildBox(); box; box = box->nextSiblingBox()) {
      if (recalcNormalFlowChildOverflowIfNeeded(box))
        childrenOverflowChanged = true;
    }
  }

  TrackedRendererListHashSet* positionedDescendants = positionedObjects();
  if (!positionedDescendants)
    return childrenOverflowChanged;

  TrackedRendererListHashSet::iterator end = positionedDescendants->end();
  for (TrackedRendererListHashSet::iterator it = positionedDescendants->begin();
       it != end; ++it) {
    RenderBox* box = *it;

    if (!box->needsOverflowRecalcAfterStyleChange())
      continue;
    RenderBlock* block = toRenderBlock(box);
    if (!block->recalcOverflowAfterStyleChange())
      continue;

    childrenOverflowChanged = true;
  }
  return childrenOverflowChanged;
}

bool RenderBlock::recalcOverflowAfterStyleChange() {
  ASSERT(needsOverflowRecalcAfterStyleChange());

  bool childrenOverflowChanged = false;
  if (childNeedsOverflowRecalcAfterStyleChange())
    childrenOverflowChanged = recalcChildOverflowAfterStyleChange();

  if (!selfNeedsOverflowRecalcAfterStyleChange() && !childrenOverflowChanged)
    return false;

  setSelfNeedsOverflowRecalcAfterStyleChange(false);
  // If the current block needs layout, overflow will be recalculated during
  // layout time anyway. We can safely exit here.
  if (needsLayout())
    return false;

  LayoutUnit oldClientAfterEdge = hasRenderOverflow()
                                      ? m_overflow->layoutClientAfterEdge()
                                      : clientLogicalBottom();
  computeOverflow(oldClientAfterEdge, true);

  return !hasOverflowClip();
}

#if ENABLE(ASSERT)
void RenderBlock::checkPositionedObjectsNeedLayout() {
  if (!gPositionedDescendantsMap)
    return;

  if (TrackedRendererListHashSet* positionedDescendantSet =
          positionedObjects()) {
    TrackedRendererListHashSet::const_iterator end =
        positionedDescendantSet->end();
    for (TrackedRendererListHashSet::const_iterator it =
             positionedDescendantSet->begin();
         it != end; ++it) {
      RenderBox* currBox = *it;
      ASSERT(!currBox->needsLayout());
    }
  }
}

#endif

#ifndef NDEBUG

void RenderBlock::showLineTreeAndMark(const InlineBox* markedBox1,
                                      const char* markedLabel1,
                                      const InlineBox* markedBox2,
                                      const char* markedLabel2,
                                      const RenderObject* obj) const {
  showRenderObject();
  for (const RootInlineBox* root = firstRootBox(); root;
       root = root->nextRootBox())
    root->showLineTreeAndMark(markedBox1, markedLabel1, markedBox2,
                              markedLabel2, obj, 1);
}

#endif

}  // namespace blink
