/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2005 Allan Sandfeld Jensen (kde@carewolf.com)
 *           (C) 2005, 2006 Samuel Weinig (sam.weinig@gmail.com)
 * Copyright (C) 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2010 Google Inc. All rights reserved.
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
 *
 */

#include "flutter/sky/engine/core/rendering/RenderBoxModelObject.h"

#include "flutter/sky/engine/core/rendering/RenderBlock.h"
#include "flutter/sky/engine/core/rendering/RenderGeometryMap.h"
#include "flutter/sky/engine/core/rendering/RenderInline.h"
#include "flutter/sky/engine/core/rendering/RenderLayer.h"
#include "flutter/sky/engine/core/rendering/RenderObjectInlines.h"
#include "flutter/sky/engine/core/rendering/RenderView.h"
#include "flutter/sky/engine/core/rendering/style/ShadowList.h"
#include "flutter/sky/engine/platform/LengthFunctions.h"
#include "flutter/sky/engine/platform/geometry/TransformState.h"
#include "flutter/sky/engine/platform/graphics/DrawLooperBuilder.h"
#include "flutter/sky/engine/platform/graphics/GraphicsContextStateSaver.h"
#include "flutter/sky/engine/platform/graphics/Path.h"

namespace blink {

void RenderBoxModelObject::setSelectionState(SelectionState state) {
  if (state == SelectionInside && selectionState() != SelectionNone)
    return;

  if ((state == SelectionStart && selectionState() == SelectionEnd) ||
      (state == SelectionEnd && selectionState() == SelectionStart))
    RenderObject::setSelectionState(SelectionBoth);
  else
    RenderObject::setSelectionState(state);

  // FIXME: We should consider whether it is OK propagating to ancestor
  // RenderInlines. This is a workaround for http://webkit.org/b/32123 The
  // containing block can be null in case of an orphaned tree.
  RenderBlock* containingBlock = this->containingBlock();
  if (containingBlock && !containingBlock->isRenderView())
    containingBlock->setSelectionState(state);
}

RenderBoxModelObject::RenderBoxModelObject() {}

RenderBoxModelObject::~RenderBoxModelObject() {}

bool RenderBoxModelObject::hasAutoHeightOrContainingBlockWithAutoHeight()
    const {
  Length logicalHeightLength = style()->logicalHeight();
  if (logicalHeightLength.isAuto())
    return true;

  // For percentage heights: The percentage is calculated with respect to the
  // height of the generated box's containing block. If the height of the
  // containing block is not specified explicitly (i.e., it depends on content
  // height), and this element is not absolutely positioned, the value computes
  // to 'auto'.
  // FIXME(sky): We might want to make height: 100% be sensible.
  if (!logicalHeightLength.isPercent() || isOutOfFlowPositioned())
    return false;

  RenderBlock* cb = containingBlock();

  // Match RenderBox::availableLogicalHeightUsing by special casing
  // the render view. The available height is taken from the frame.
  if (cb->isRenderView())
    return false;

  if (cb->isOutOfFlowPositioned() && !cb->style()->logicalTop().isAuto() &&
      !cb->style()->logicalBottom().isAuto())
    return false;

  // If the height of the containing block computes to 'auto', then it hasn't
  // been 'specified explicitly'.
  return cb->hasAutoHeightOrContainingBlockWithAutoHeight();
}

LayoutSize RenderBoxModelObject::relativePositionOffset() const {
  LayoutSize offset;

  RenderBlock* containingBlock = this->containingBlock();

  // Objects that shrink to avoid floats normally use available line width when
  // computing containing block width.  However in the case of relative
  // positioning using percentages, we can't do this.  The offset should always
  // be resolved using the available width of the containing block.  Therefore
  // we don't use containingBlockLogicalWidthForContent() here, but instead
  // explicitly call availableWidth on our containing block.
  if (!style()->left().isAuto()) {
    if (!style()->right().isAuto() &&
        !containingBlock->style()->isLeftToRightDirection())
      offset.setWidth(
          -valueForLength(style()->right(), containingBlock->availableWidth()));
    else
      offset.expand(
          valueForLength(style()->left(), containingBlock->availableWidth()),
          0);
  } else if (!style()->right().isAuto()) {
    offset.expand(
        -valueForLength(style()->right(), containingBlock->availableWidth()),
        0);
  }

  // If the containing block of a relatively positioned element does not
  // specify a height, a percentage top or bottom offset should be resolved as
  // auto. An exception to this is if the containing block has the WinIE quirk
  // where <html> and <body> assume the size of the viewport. In this case,
  // calculate the percent offset based on this height.
  // See <https://bugs.webkit.org/show_bug.cgi?id=26396>.
  if (!style()->top().isAuto() &&
      (!containingBlock->hasAutoHeightOrContainingBlockWithAutoHeight() ||
       !style()->top().isPercent()))
    offset.expand(
        0, valueForLength(style()->top(), containingBlock->availableHeight()));

  else if (!style()->bottom().isAuto() &&
           (!containingBlock->hasAutoHeightOrContainingBlockWithAutoHeight() ||
            !style()->bottom().isPercent()))
    offset.expand(0, -valueForLength(style()->bottom(),
                                     containingBlock->availableHeight()));

  return offset;
}

LayoutPoint RenderBoxModelObject::adjustedPositionRelativeToOffsetParent(
    const LayoutPoint& startPoint) const {
  if (!parent())
    return LayoutPoint();

  return startPoint;
}

LayoutUnit RenderBoxModelObject::offsetLeft() const {
  // Note that RenderInline and RenderBox override this to pass a different
  // startPoint to adjustedPositionRelativeToOffsetParent.
  return adjustedPositionRelativeToOffsetParent(LayoutPoint()).x();
}

LayoutUnit RenderBoxModelObject::offsetTop() const {
  // Note that RenderInline and RenderBox override this to pass a different
  // startPoint to adjustedPositionRelativeToOffsetParent.
  return adjustedPositionRelativeToOffsetParent(LayoutPoint()).y();
}

int RenderBoxModelObject::pixelSnappedOffsetWidth() const {
  return snapSizeToPixel(offsetWidth(), offsetLeft());
}

int RenderBoxModelObject::pixelSnappedOffsetHeight() const {
  return snapSizeToPixel(offsetHeight(), offsetTop());
}

LayoutUnit RenderBoxModelObject::computedCSSPadding(
    const Length& padding) const {
  LayoutUnit w = 0;
  if (padding.isPercent())
    w = containingBlockLogicalWidthForContent();
  return minimumValueForLength(padding, w);
}

RoundedRect RenderBoxModelObject::getBackgroundRoundedRect(
    const LayoutRect& borderRect,
    InlineFlowBox* box,
    LayoutUnit inlineBoxWidth,
    LayoutUnit inlineBoxHeight,
    bool includeLogicalLeftEdge,
    bool includeLogicalRightEdge) const {
  RoundedRect border = style()->getRoundedBorderFor(
      borderRect, includeLogicalLeftEdge, includeLogicalRightEdge);
  if (box && (box->nextLineBox() || box->prevLineBox())) {
    RoundedRect segmentBorder = style()->getRoundedBorderFor(
        LayoutRect(0, 0, inlineBoxWidth, inlineBoxHeight),
        includeLogicalLeftEdge, includeLogicalRightEdge);
    border.setRadii(segmentBorder.radii());
  }

  return border;
}

void RenderBoxModelObject::clipRoundedInnerRect(GraphicsContext* context,
                                                const LayoutRect& rect,
                                                const RoundedRect& clipRect) {
  if (clipRect.isRenderable())
    context->clipRoundedRect(clipRect);
  else {
    // We create a rounded rect for each of the corners and clip it, while
    // making sure we clip opposing corners together.
    if (!clipRect.radii().topLeft().isEmpty() ||
        !clipRect.radii().bottomRight().isEmpty()) {
      IntRect topCorner(clipRect.rect().x(), clipRect.rect().y(),
                        rect.maxX() - clipRect.rect().x(),
                        rect.maxY() - clipRect.rect().y());
      RoundedRect::Radii topCornerRadii;
      topCornerRadii.setTopLeft(clipRect.radii().topLeft());
      context->clipRoundedRect(RoundedRect(topCorner, topCornerRadii));

      IntRect bottomCorner(rect.x(), rect.y(),
                           clipRect.rect().maxX() - rect.x(),
                           clipRect.rect().maxY() - rect.y());
      RoundedRect::Radii bottomCornerRadii;
      bottomCornerRadii.setBottomRight(clipRect.radii().bottomRight());
      context->clipRoundedRect(RoundedRect(bottomCorner, bottomCornerRadii));
    }

    if (!clipRect.radii().topRight().isEmpty() ||
        !clipRect.radii().bottomLeft().isEmpty()) {
      IntRect topCorner(rect.x(), clipRect.rect().y(),
                        clipRect.rect().maxX() - rect.x(),
                        rect.maxY() - clipRect.rect().y());
      RoundedRect::Radii topCornerRadii;
      topCornerRadii.setTopRight(clipRect.radii().topRight());
      context->clipRoundedRect(RoundedRect(topCorner, topCornerRadii));

      IntRect bottomCorner(clipRect.rect().x(), rect.y(),
                           rect.maxX() - clipRect.rect().x(),
                           clipRect.rect().maxY() - rect.y());
      RoundedRect::Radii bottomCornerRadii;
      bottomCornerRadii.setBottomLeft(clipRect.radii().bottomLeft());
      context->clipRoundedRect(RoundedRect(bottomCorner, bottomCornerRadii));
    }
  }
}

// FIXME: See crbug.com/382491. The use of getCTM in this context is incorrect
// because the matrix returned does not include scales applied at raster time,
// such as the device zoom.
static LayoutRect shrinkRectByOnePixel(GraphicsContext* context,
                                       const LayoutRect& rect) {
  LayoutRect shrunkRect = rect;
  AffineTransform transform = context->getCTM();
  shrunkRect.inflateX(-static_cast<LayoutUnit>(ceil(1 / transform.xScale())));
  shrunkRect.inflateY(-static_cast<LayoutUnit>(ceil(1 / transform.yScale())));
  return shrunkRect;
}

LayoutRect RenderBoxModelObject::borderInnerRectAdjustedForBleedAvoidance(
    GraphicsContext* context,
    const LayoutRect& rect,
    BackgroundBleedAvoidance bleedAvoidance) const {
  // We shrink the rectangle by one pixel on each side to make it fully overlap
  // the anti-aliased background border
  return (bleedAvoidance == BackgroundBleedBackgroundOverBorder)
             ? shrinkRectByOnePixel(context, rect)
             : rect;
}

RoundedRect
RenderBoxModelObject::backgroundRoundedRectAdjustedForBleedAvoidance(
    GraphicsContext* context,
    const LayoutRect& borderRect,
    BackgroundBleedAvoidance bleedAvoidance,
    InlineFlowBox* box,
    const LayoutSize& boxSize,
    bool includeLogicalLeftEdge,
    bool includeLogicalRightEdge) const {
  if (bleedAvoidance == BackgroundBleedShrinkBackground) {
    // We shrink the rectangle by one pixel on each side because the bleed is
    // one pixel maximum.
    return getBackgroundRoundedRect(
        shrinkRectByOnePixel(context, borderRect), box, boxSize.width(),
        boxSize.height(), includeLogicalLeftEdge, includeLogicalRightEdge);
  }
  if (bleedAvoidance == BackgroundBleedBackgroundOverBorder)
    return style()->getRoundedInnerBorderFor(borderRect, includeLogicalLeftEdge,
                                             includeLogicalRightEdge);

  return getBackgroundRoundedRect(borderRect, box, boxSize.width(),
                                  boxSize.height(), includeLogicalLeftEdge,
                                  includeLogicalRightEdge);
}

static void applyBoxShadowForBackground(GraphicsContext* context,
                                        const RenderObject* renderer) {
  const ShadowList* shadowList = renderer->style()->boxShadow();
  ASSERT(shadowList);
  for (size_t i = shadowList->shadows().size(); i--;) {
    const ShadowData& boxShadow = shadowList->shadows()[i];
    if (boxShadow.style() != Normal)
      continue;
    FloatSize shadowOffset(boxShadow.x(), boxShadow.y());
    context->setShadow(shadowOffset, boxShadow.blur(), boxShadow.color(),
                       DrawLooperBuilder::ShadowRespectsTransforms,
                       DrawLooperBuilder::ShadowIgnoresAlpha);
    return;
  }
}

void RenderBoxModelObject::paintFillLayerExtended(
    const PaintInfo& paintInfo,
    const Color& color,
    const FillLayer& bgLayer,
    const LayoutRect& rect,
    BackgroundBleedAvoidance bleedAvoidance,
    InlineFlowBox* box,
    const LayoutSize& boxSize,
    RenderObject* backgroundObject,
    bool skipBaseColor) {
  GraphicsContext* context = paintInfo.context;
  if (rect.isEmpty())
    return;

  bool includeLeftEdge = box ? box->includeLogicalLeftEdge() : true;
  bool includeRightEdge = box ? box->includeLogicalRightEdge() : true;

  bool hasRoundedBorder =
      style()->hasBorderRadius() && (includeLeftEdge || includeRightEdge);
  bool clippedWithLocalScrolling =
      hasOverflowClip() && bgLayer.attachment() == LocalBackgroundAttachment;
  bool isBorderFill = bgLayer.clip() == BorderFillBox;
  bool isBottomLayer = !bgLayer.next();

  Color bgColor = color;
  StyleImage* bgImage = bgLayer.image();
  bool shouldPaintBackgroundImage = bgImage && bgImage->canRender(*this);

  bool colorVisible = bgColor.alpha();

  // Fast path for drawing simple color backgrounds.
  if (!clippedWithLocalScrolling && !shouldPaintBackgroundImage &&
      isBorderFill && isBottomLayer) {
    if (!colorVisible)
      return;

    bool boxShadowShouldBeAppliedToBackground =
        this->boxShadowShouldBeAppliedToBackground(bleedAvoidance, box);
    GraphicsContextStateSaver shadowStateSaver(
        *context, boxShadowShouldBeAppliedToBackground);
    if (boxShadowShouldBeAppliedToBackground)
      applyBoxShadowForBackground(context, this);

    if (hasRoundedBorder && bleedAvoidance != BackgroundBleedClipBackground) {
      RoundedRect border = backgroundRoundedRectAdjustedForBleedAvoidance(
          context, rect, bleedAvoidance, box, boxSize, includeLeftEdge,
          includeRightEdge);
      if (border.isRenderable())
        context->fillRoundedRect(border, bgColor);
      else {
        context->save();
        clipRoundedInnerRect(context, rect, border);
        context->fillRect(border.rect(), bgColor);
        context->restore();
      }
    } else {
      context->fillRect(pixelSnappedIntRect(rect), bgColor);
    }

    return;
  }

  // BorderFillBox radius clipping is taken care of by
  // BackgroundBleedClipBackground
  bool clipToBorderRadius =
      hasRoundedBorder &&
      !(isBorderFill && bleedAvoidance == BackgroundBleedClipBackground);
  GraphicsContextStateSaver clipToBorderStateSaver(*context,
                                                   clipToBorderRadius);
  if (clipToBorderRadius) {
    RoundedRect border = isBorderFill
                             ? backgroundRoundedRectAdjustedForBleedAvoidance(
                                   context, rect, bleedAvoidance, box, boxSize,
                                   includeLeftEdge, includeRightEdge)
                             : getBackgroundRoundedRect(
                                   rect, box, boxSize.width(), boxSize.height(),
                                   includeLeftEdge, includeRightEdge);

    // Clip to the padding or content boxes as necessary.
    if (bgLayer.clip() == ContentFillBox) {
      border = style()->getRoundedInnerBorderFor(
          border.rect(), paddingTop() + borderTop(),
          paddingBottom() + borderBottom(), paddingLeft() + borderLeft(),
          paddingRight() + borderRight(), includeLeftEdge, includeRightEdge);
    } else if (bgLayer.clip() == PaddingFillBox)
      border = style()->getRoundedInnerBorderFor(border.rect(), includeLeftEdge,
                                                 includeRightEdge);

    clipRoundedInnerRect(context, rect, border);
  }

  int bLeft = includeLeftEdge ? borderLeft() : 0;
  int bRight = includeRightEdge ? borderRight() : 0;
  LayoutUnit pLeft = includeLeftEdge ? paddingLeft() : LayoutUnit();
  LayoutUnit pRight = includeRightEdge ? paddingRight() : LayoutUnit();

  GraphicsContextStateSaver clipWithScrollingStateSaver(
      *context, clippedWithLocalScrolling);
  LayoutRect scrolledPaintRect = rect;
  if (clippedWithLocalScrolling) {
    // Clip to the overflow area.
    RenderBox* thisBox = toRenderBox(this);
    context->clip(thisBox->overflowClipRect(rect.location()));

    // Adjust the paint rect to reflect a scrolled content box with borders at
    // the ends.
    scrolledPaintRect.setWidth(bLeft + thisBox->clientWidth() + bRight);
    scrolledPaintRect.setHeight(borderTop() + thisBox->clientHeight() +
                                borderBottom());
  }

  GraphicsContextStateSaver backgroundClipStateSaver(*context, false);

  switch (bgLayer.clip()) {
    case PaddingFillBox:
    case ContentFillBox: {
      if (clipToBorderRadius)
        break;

      // Clip to the padding or content boxes as necessary.
      bool includePadding = bgLayer.clip() == ContentFillBox;
      LayoutRect clipRect = LayoutRect(
          scrolledPaintRect.x() + bLeft +
              (includePadding ? pLeft : LayoutUnit()),
          scrolledPaintRect.y() + borderTop() +
              (includePadding ? paddingTop() : LayoutUnit()),
          scrolledPaintRect.width() - bLeft - bRight -
              (includePadding ? pLeft + pRight : LayoutUnit()),
          scrolledPaintRect.height() - borderTop() - borderBottom() -
              (includePadding ? paddingTop() + paddingBottom() : LayoutUnit()));
      backgroundClipStateSaver.save();
      context->clip(clipRect);

      break;
    }
    case BorderFillBox:
      break;
    default:
      ASSERT_NOT_REACHED();
      break;
  }

  // Paint the color first underneath all images, culled if background image
  // occludes it.
  // FIXME: In the bgLayer->hasFiniteBounds() case, we could improve the culling
  // test by verifying whether the background image covers the entire layout
  // rect.
  if (isBottomLayer) {
    IntRect backgroundRect(pixelSnappedIntRect(scrolledPaintRect));
    bool boxShadowShouldBeAppliedToBackground =
        this->boxShadowShouldBeAppliedToBackground(bleedAvoidance, box);
    if (boxShadowShouldBeAppliedToBackground || !shouldPaintBackgroundImage ||
        !bgLayer.hasOpaqueImage(this) || !bgLayer.hasRepeatXY()) {
      if (!boxShadowShouldBeAppliedToBackground)
        backgroundRect.intersect(paintInfo.rect);

      GraphicsContextStateSaver shadowStateSaver(
          *context, boxShadowShouldBeAppliedToBackground);
      if (boxShadowShouldBeAppliedToBackground)
        applyBoxShadowForBackground(context, this);

      if (bgColor.alpha())
        context->fillRect(backgroundRect, bgColor,
                          context->compositeOperation());
    }
  }
}

static inline int resolveWidthForRatio(int height,
                                       const FloatSize& intrinsicRatio) {
  return ceilf(height * intrinsicRatio.width() / intrinsicRatio.height());
}

static inline int resolveHeightForRatio(int width,
                                        const FloatSize& intrinsicRatio) {
  return ceilf(width * intrinsicRatio.height() / intrinsicRatio.width());
}

static inline IntSize resolveAgainstIntrinsicWidthOrHeightAndRatio(
    const IntSize& size,
    const FloatSize& intrinsicRatio,
    int useWidth,
    int useHeight) {
  if (intrinsicRatio.isEmpty()) {
    if (useWidth)
      return IntSize(useWidth, size.height());
    return IntSize(size.width(), useHeight);
  }

  if (useWidth)
    return IntSize(useWidth, resolveHeightForRatio(useWidth, intrinsicRatio));
  return IntSize(resolveWidthForRatio(useHeight, intrinsicRatio), useHeight);
}

static inline IntSize resolveAgainstIntrinsicRatio(
    const IntSize& size,
    const FloatSize& intrinsicRatio) {
  // Two possible solutions: (size.width(), solutionHeight) or (solutionWidth,
  // size.height())
  // "... must be assumed to be the largest dimensions..." = easiest answer: the
  // rect with the largest surface area.

  int solutionWidth = resolveWidthForRatio(size.height(), intrinsicRatio);
  int solutionHeight = resolveHeightForRatio(size.width(), intrinsicRatio);
  if (solutionWidth <= size.width()) {
    if (solutionHeight <= size.height()) {
      // If both solutions fit, choose the one covering the larger area.
      int areaOne = solutionWidth * size.height();
      int areaTwo = size.width() * solutionHeight;
      if (areaOne < areaTwo)
        return IntSize(size.width(), solutionHeight);
      return IntSize(solutionWidth, size.height());
    }

    // Only the first solution fits.
    return IntSize(solutionWidth, size.height());
  }

  // Only the second solution fits, assert that.
  ASSERT(solutionHeight <= size.height());
  return IntSize(size.width(), solutionHeight);
}

IntSize RenderBoxModelObject::calculateImageIntrinsicDimensions(
    StyleImage* image,
    const IntSize& positioningAreaSize) const {
  // A generated image without a fixed size, will always return the container
  // size as intrinsic size.
  if (image->isGeneratedImage() && image->usesImageContainerSize())
    return IntSize(positioningAreaSize.width(), positioningAreaSize.height());

  Length intrinsicWidth;
  Length intrinsicHeight;
  FloatSize intrinsicRatio;
  image->computeIntrinsicDimensions(this, intrinsicWidth, intrinsicHeight,
                                    intrinsicRatio);

  ASSERT(!intrinsicWidth.isPercent());
  ASSERT(!intrinsicHeight.isPercent());

  IntSize resolvedSize(intrinsicWidth.value(), intrinsicHeight.value());
  IntSize minimumSize(resolvedSize.width() > 0 ? 1 : 0,
                      resolvedSize.height() > 0 ? 1 : 0);
  resolvedSize.clampToMinimumSize(minimumSize);

  if (!resolvedSize.isEmpty())
    return resolvedSize;

  // If the image has one of either an intrinsic width or an intrinsic height:
  // * and an intrinsic aspect ratio, then the missing dimension is calculated
  // from the given dimension and the ratio.
  // * and no intrinsic aspect ratio, then the missing dimension is assumed to
  // be the size of the rectangle that
  //   establishes the coordinate system for the 'background-position' property.
  if (resolvedSize.width() > 0 || resolvedSize.height() > 0)
    return resolveAgainstIntrinsicWidthOrHeightAndRatio(
        positioningAreaSize, intrinsicRatio, resolvedSize.width(),
        resolvedSize.height());

  // If the image has no intrinsic dimensions and has an intrinsic ratio the
  // dimensions must be assumed to be the largest dimensions at that ratio such
  // that neither dimension exceeds the dimensions of the rectangle that
  // establishes the coordinate system for the 'background-position' property.
  if (!intrinsicRatio.isEmpty())
    return resolveAgainstIntrinsicRatio(positioningAreaSize, intrinsicRatio);

  // If the image has no intrinsic ratio either, then the dimensions must be
  // assumed to be the rectangle that establishes the coordinate system for the
  // 'background-position' property.
  return positioningAreaSize;
}

static inline void applySubPixelHeuristicForTileSize(
    LayoutSize& tileSize,
    const IntSize& positioningAreaSize) {
  tileSize.setWidth(positioningAreaSize.width() - tileSize.width() <= 1
                        ? tileSize.width().ceil()
                        : tileSize.width().floor());
  tileSize.setHeight(positioningAreaSize.height() - tileSize.height() <= 1
                         ? tileSize.height().ceil()
                         : tileSize.height().floor());
}

IntSize RenderBoxModelObject::calculateFillTileSize(
    const FillLayer& fillLayer,
    const IntSize& positioningAreaSize) const {
  StyleImage* image = fillLayer.image();
  EFillSizeType type = fillLayer.size().type;

  IntSize imageIntrinsicSize =
      calculateImageIntrinsicDimensions(image, positioningAreaSize);
  imageIntrinsicSize.scale(1 / image->imageScaleFactor(),
                           1 / image->imageScaleFactor());
  switch (type) {
    case SizeLength: {
      LayoutSize tileSize = positioningAreaSize;

      Length layerWidth = fillLayer.size().size.width();
      Length layerHeight = fillLayer.size().size.height();

      if (layerWidth.isFixed())
        tileSize.setWidth(layerWidth.value());
      else if (layerWidth.isPercent())
        tileSize.setWidth(
            valueForLength(layerWidth, positioningAreaSize.width()));

      if (layerHeight.isFixed())
        tileSize.setHeight(layerHeight.value());
      else if (layerHeight.isPercent())
        tileSize.setHeight(
            valueForLength(layerHeight, positioningAreaSize.height()));

      applySubPixelHeuristicForTileSize(tileSize, positioningAreaSize);

      // If one of the values is auto we have to use the appropriate
      // scale to maintain our aspect ratio.
      if (layerWidth.isAuto() && !layerHeight.isAuto()) {
        if (imageIntrinsicSize.height())
          tileSize.setWidth(imageIntrinsicSize.width() * tileSize.height() /
                            imageIntrinsicSize.height());
      } else if (!layerWidth.isAuto() && layerHeight.isAuto()) {
        if (imageIntrinsicSize.width())
          tileSize.setHeight(imageIntrinsicSize.height() * tileSize.width() /
                             imageIntrinsicSize.width());
      } else if (layerWidth.isAuto() && layerHeight.isAuto()) {
        // If both width and height are auto, use the image's intrinsic size.
        tileSize = imageIntrinsicSize;
      }

      tileSize.clampNegativeToZero();
      return flooredIntSize(tileSize);
    }
    case SizeNone: {
      // If both values are ‘auto’ then the intrinsic width and/or height of the
      // image should be used, if any.
      if (!imageIntrinsicSize.isEmpty())
        return imageIntrinsicSize;

      // If the image has neither an intrinsic width nor an intrinsic height,
      // its size is determined as for ‘contain’.
      type = Contain;
    }
    case Contain:
    case Cover: {
      float horizontalScaleFactor =
          imageIntrinsicSize.width()
              ? static_cast<float>(positioningAreaSize.width()) /
                    imageIntrinsicSize.width()
              : 1;
      float verticalScaleFactor =
          imageIntrinsicSize.height()
              ? static_cast<float>(positioningAreaSize.height()) /
                    imageIntrinsicSize.height()
              : 1;
      float scaleFactor =
          type == Contain
              ? std::min(horizontalScaleFactor, verticalScaleFactor)
              : std::max(horizontalScaleFactor, verticalScaleFactor);
      return IntSize(
          std::max(1l, lround(imageIntrinsicSize.width() * scaleFactor)),
          std::max(1l, lround(imageIntrinsicSize.height() * scaleFactor)));
    }
  }

  ASSERT_NOT_REACHED();
  return IntSize();
}

void RenderBoxModelObject::BackgroundImageGeometry::setNoRepeatX(int xOffset) {
  m_destRect.move(std::max(xOffset, 0), 0);
  m_phase.setX(-std::min(xOffset, 0));
  m_destRect.setWidth(m_tileSize.width() + std::min(xOffset, 0));
}
void RenderBoxModelObject::BackgroundImageGeometry::setNoRepeatY(int yOffset) {
  m_destRect.move(0, std::max(yOffset, 0));
  m_phase.setY(-std::min(yOffset, 0));
  m_destRect.setHeight(m_tileSize.height() + std::min(yOffset, 0));
}

void RenderBoxModelObject::BackgroundImageGeometry::useFixedAttachment(
    const IntPoint& attachmentPoint) {
  IntPoint alignedPoint = attachmentPoint;
  m_phase.move(std::max(alignedPoint.x() - m_destRect.x(), 0),
               std::max(alignedPoint.y() - m_destRect.y(), 0));
}

void RenderBoxModelObject::BackgroundImageGeometry::clip(
    const IntRect& clipRect) {
  m_destRect.intersect(clipRect);
}

IntPoint RenderBoxModelObject::BackgroundImageGeometry::relativePhase() const {
  IntPoint phase = m_phase;
  phase += m_destRect.location() - m_destOrigin;
  return phase;
}

class BorderEdge {
 public:
  BorderEdge(int edgeWidth,
             const Color& edgeColor,
             EBorderStyle edgeStyle,
             bool edgeIsTransparent,
             bool edgeIsPresent = true)
      : width(edgeWidth),
        color(edgeColor),
        style(edgeStyle),
        isTransparent(edgeIsTransparent),
        isPresent(edgeIsPresent) {
    if (style == DOUBLE && edgeWidth < 3)
      style = SOLID;
  }

  BorderEdge()
      : width(0), style(BHIDDEN), isTransparent(false), isPresent(false) {}

  bool hasVisibleColorAndStyle() const {
    return style > BHIDDEN && !isTransparent;
  }
  bool shouldRender() const {
    return isPresent && width && hasVisibleColorAndStyle();
  }
  bool presentButInvisible() const {
    return usedWidth() && !hasVisibleColorAndStyle();
  }
  bool obscuresBackgroundEdge(float scale) const {
    if (!isPresent || isTransparent || (width * scale) < 2 ||
        color.hasAlpha() || style == BHIDDEN)
      return false;

    if (style == DOTTED || style == DASHED)
      return false;

    if (style == DOUBLE)
      return width >= 5 * scale;  // The outer band needs to be >= 2px wide at
                                  // unit scale.

    return true;
  }
  bool obscuresBackground() const {
    if (!isPresent || isTransparent || color.hasAlpha() || style == BHIDDEN)
      return false;

    if (style == DOTTED || style == DASHED || style == DOUBLE)
      return false;

    return true;
  }

  int usedWidth() const { return isPresent ? width : 0; }

  void getDoubleBorderStripeWidths(int& outerWidth, int& innerWidth) const {
    int fullWidth = usedWidth();
    outerWidth = fullWidth / 3;
    innerWidth = fullWidth * 2 / 3;

    // We need certain integer rounding results
    if (fullWidth % 3 == 2)
      outerWidth += 1;

    if (fullWidth % 3 == 1)
      innerWidth += 1;
  }

  int width;
  Color color;
  EBorderStyle style;
  bool isTransparent;
  bool isPresent;
};

static bool allCornersClippedOut(const RoundedRect& border,
                                 const LayoutRect& clipRect) {
  LayoutRect boundingRect = border.rect();
  if (clipRect.contains(boundingRect))
    return false;

  RoundedRect::Radii radii = border.radii();

  LayoutRect topLeftRect(boundingRect.location(), radii.topLeft());
  if (clipRect.intersects(topLeftRect))
    return false;

  LayoutRect topRightRect(boundingRect.location(), radii.topRight());
  topRightRect.setX(boundingRect.maxX() - topRightRect.width());
  if (clipRect.intersects(topRightRect))
    return false;

  LayoutRect bottomLeftRect(boundingRect.location(), radii.bottomLeft());
  bottomLeftRect.setY(boundingRect.maxY() - bottomLeftRect.height());
  if (clipRect.intersects(bottomLeftRect))
    return false;

  LayoutRect bottomRightRect(boundingRect.location(), radii.bottomRight());
  bottomRightRect.setX(boundingRect.maxX() - bottomRightRect.width());
  bottomRightRect.setY(boundingRect.maxY() - bottomRightRect.height());
  if (clipRect.intersects(bottomRightRect))
    return false;

  return true;
}

static bool borderWillArcInnerEdge(const LayoutSize& firstRadius,
                                   const FloatSize& secondRadius) {
  return !firstRadius.isZero() || !secondRadius.isZero();
}

enum BorderEdgeFlag {
  TopBorderEdge = 1 << BSTop,
  RightBorderEdge = 1 << BSRight,
  BottomBorderEdge = 1 << BSBottom,
  LeftBorderEdge = 1 << BSLeft,
  AllBorderEdges =
      TopBorderEdge | BottomBorderEdge | LeftBorderEdge | RightBorderEdge
};

static inline BorderEdgeFlag edgeFlagForSide(BoxSide side) {
  return static_cast<BorderEdgeFlag>(1 << side);
}

static inline bool includesEdge(BorderEdgeFlags flags, BoxSide side) {
  return flags & edgeFlagForSide(side);
}

static inline bool includesAdjacentEdges(BorderEdgeFlags flags) {
  return (flags & (TopBorderEdge | RightBorderEdge)) ==
             (TopBorderEdge | RightBorderEdge) ||
         (flags & (RightBorderEdge | BottomBorderEdge)) ==
             (RightBorderEdge | BottomBorderEdge) ||
         (flags & (BottomBorderEdge | LeftBorderEdge)) ==
             (BottomBorderEdge | LeftBorderEdge) ||
         (flags & (LeftBorderEdge | TopBorderEdge)) ==
             (LeftBorderEdge | TopBorderEdge);
}

inline bool edgesShareColor(const BorderEdge& firstEdge,
                            const BorderEdge& secondEdge) {
  return firstEdge.color == secondEdge.color;
}

inline bool styleRequiresClipPolygon(EBorderStyle style) {
  return style == DOTTED || style == DASHED;  // These are drawn with a stroke,
                                              // so we have to clip to get
                                              // corner miters.
}

static bool borderStyleFillsBorderArea(EBorderStyle style) {
  return !(style == DOTTED || style == DASHED || style == DOUBLE);
}

static bool borderStyleHasInnerDetail(EBorderStyle style) {
  return style == GROOVE || style == RIDGE || style == DOUBLE;
}

static bool borderStyleIsDottedOrDashed(EBorderStyle style) {
  return style == DOTTED || style == DASHED;
}

// OUTSET darkens the bottom and right (and maybe lightens the top and left)
// INSET darkens the top and left (and maybe lightens the bottom and right)
static inline bool borderStyleHasUnmatchedColorsAtCorner(EBorderStyle style,
                                                         BoxSide side,
                                                         BoxSide adjacentSide) {
  // These styles match at the top/left and bottom/right.
  if (style == INSET || style == GROOVE || style == RIDGE || style == OUTSET) {
    const BorderEdgeFlags topRightFlags =
        edgeFlagForSide(BSTop) | edgeFlagForSide(BSRight);
    const BorderEdgeFlags bottomLeftFlags =
        edgeFlagForSide(BSBottom) | edgeFlagForSide(BSLeft);

    BorderEdgeFlags flags =
        edgeFlagForSide(side) | edgeFlagForSide(adjacentSide);
    return flags == topRightFlags || flags == bottomLeftFlags;
  }
  return false;
}

static inline bool colorsMatchAtCorner(BoxSide side,
                                       BoxSide adjacentSide,
                                       const BorderEdge edges[]) {
  if (edges[side].shouldRender() != edges[adjacentSide].shouldRender())
    return false;

  if (!edgesShareColor(edges[side], edges[adjacentSide]))
    return false;

  return !borderStyleHasUnmatchedColorsAtCorner(edges[side].style, side,
                                                adjacentSide);
}

static inline bool colorNeedsAntiAliasAtCorner(BoxSide side,
                                               BoxSide adjacentSide,
                                               const BorderEdge edges[]) {
  if (!edges[side].color.hasAlpha())
    return false;

  if (edges[side].shouldRender() != edges[adjacentSide].shouldRender())
    return false;

  if (!edgesShareColor(edges[side], edges[adjacentSide]))
    return true;

  return borderStyleHasUnmatchedColorsAtCorner(edges[side].style, side,
                                               adjacentSide);
}

// This assumes that we draw in order: top, bottom, left, right.
static inline bool willBeOverdrawn(BoxSide side,
                                   BoxSide adjacentSide,
                                   const BorderEdge edges[]) {
  switch (side) {
    case BSTop:
    case BSBottom:
      if (edges[adjacentSide].presentButInvisible())
        return false;

      if (!edgesShareColor(edges[side], edges[adjacentSide]) &&
          edges[adjacentSide].color.hasAlpha())
        return false;

      if (!borderStyleFillsBorderArea(edges[adjacentSide].style))
        return false;

      return true;

    case BSLeft:
    case BSRight:
      // These draw last, so are never overdrawn.
      return false;
  }
  return false;
}

static inline bool borderStylesRequireMitre(BoxSide side,
                                            BoxSide adjacentSide,
                                            EBorderStyle style,
                                            EBorderStyle adjacentStyle) {
  if (style == DOUBLE || adjacentStyle == DOUBLE || adjacentStyle == GROOVE ||
      adjacentStyle == RIDGE)
    return true;

  if (borderStyleIsDottedOrDashed(style) !=
      borderStyleIsDottedOrDashed(adjacentStyle))
    return true;

  if (style != adjacentStyle)
    return true;

  return borderStyleHasUnmatchedColorsAtCorner(style, side, adjacentSide);
}

static bool joinRequiresMitre(BoxSide side,
                              BoxSide adjacentSide,
                              const BorderEdge edges[],
                              bool allowOverdraw) {
  if ((edges[side].isTransparent && edges[adjacentSide].isTransparent) ||
      !edges[adjacentSide].isPresent)
    return false;

  if (allowOverdraw && willBeOverdrawn(side, adjacentSide, edges))
    return false;

  if (!edgesShareColor(edges[side], edges[adjacentSide]))
    return true;

  if (borderStylesRequireMitre(side, adjacentSide, edges[side].style,
                               edges[adjacentSide].style))
    return true;

  return false;
}

void RenderBoxModelObject::paintOneBorderSide(
    GraphicsContext* graphicsContext,
    const RenderStyle* style,
    const RoundedRect& outerBorder,
    const RoundedRect& innerBorder,
    const IntRect& sideRect,
    BoxSide side,
    BoxSide adjacentSide1,
    BoxSide adjacentSide2,
    const BorderEdge edges[],
    const Path* path,
    BackgroundBleedAvoidance bleedAvoidance,
    bool includeLogicalLeftEdge,
    bool includeLogicalRightEdge,
    bool antialias,
    const Color* overrideColor) {
  const BorderEdge& edgeToRender = edges[side];
  ASSERT(edgeToRender.width);
  const BorderEdge& adjacentEdge1 = edges[adjacentSide1];
  const BorderEdge& adjacentEdge2 = edges[adjacentSide2];

  bool mitreAdjacentSide1 =
      joinRequiresMitre(side, adjacentSide1, edges, !antialias);
  bool mitreAdjacentSide2 =
      joinRequiresMitre(side, adjacentSide2, edges, !antialias);

  bool adjacentSide1StylesMatch =
      colorsMatchAtCorner(side, adjacentSide1, edges);
  bool adjacentSide2StylesMatch =
      colorsMatchAtCorner(side, adjacentSide2, edges);

  const Color& colorToPaint =
      overrideColor ? *overrideColor : edgeToRender.color;

  if (path) {
    GraphicsContextStateSaver stateSaver(*graphicsContext);
    if (innerBorder.isRenderable())
      clipBorderSidePolygon(graphicsContext, outerBorder, innerBorder, side,
                            adjacentSide1StylesMatch, adjacentSide2StylesMatch);
    else
      clipBorderSideForComplexInnerPath(graphicsContext, outerBorder,
                                        innerBorder, side, edges);
    float thickness = std::max(
        std::max(edgeToRender.width, adjacentEdge1.width), adjacentEdge2.width);
    drawBoxSideFromPath(graphicsContext, outerBorder.rect(), *path, edges,
                        edgeToRender.width, thickness, side, style,
                        colorToPaint, edgeToRender.style, bleedAvoidance,
                        includeLogicalLeftEdge, includeLogicalRightEdge);
  } else {
    bool clipForStyle = styleRequiresClipPolygon(edgeToRender.style) &&
                        (mitreAdjacentSide1 || mitreAdjacentSide2);
    bool clipAdjacentSide1 =
        colorNeedsAntiAliasAtCorner(side, adjacentSide1, edges) &&
        mitreAdjacentSide1;
    bool clipAdjacentSide2 =
        colorNeedsAntiAliasAtCorner(side, adjacentSide2, edges) &&
        mitreAdjacentSide2;
    bool shouldClip = clipForStyle || clipAdjacentSide1 || clipAdjacentSide2;

    GraphicsContextStateSaver clipStateSaver(*graphicsContext, shouldClip);
    if (shouldClip) {
      bool aliasAdjacentSide1 =
          clipAdjacentSide1 || (clipForStyle && mitreAdjacentSide1);
      bool aliasAdjacentSide2 =
          clipAdjacentSide2 || (clipForStyle && mitreAdjacentSide2);
      clipBorderSidePolygon(graphicsContext, outerBorder, innerBorder, side,
                            !aliasAdjacentSide1, !aliasAdjacentSide2);
      // Since we clipped, no need to draw with a mitre.
      mitreAdjacentSide1 = false;
      mitreAdjacentSide2 = false;
    }

    drawLineForBoxSide(graphicsContext, sideRect.x(), sideRect.y(),
                       sideRect.maxX(), sideRect.maxY(), side, colorToPaint,
                       edgeToRender.style,
                       mitreAdjacentSide1 ? adjacentEdge1.width : 0,
                       mitreAdjacentSide2 ? adjacentEdge2.width : 0, antialias);
  }
}

static IntRect calculateSideRect(const RoundedRect& outerBorder,
                                 const BorderEdge edges[],
                                 int side) {
  IntRect sideRect = outerBorder.rect();
  int width = edges[side].width;

  if (side == BSTop)
    sideRect.setHeight(width);
  else if (side == BSBottom)
    sideRect.shiftYEdgeTo(sideRect.maxY() - width);
  else if (side == BSLeft)
    sideRect.setWidth(width);
  else
    sideRect.shiftXEdgeTo(sideRect.maxX() - width);

  return sideRect;
}

void RenderBoxModelObject::paintBorderSides(
    GraphicsContext* graphicsContext,
    const RenderStyle* style,
    const RoundedRect& outerBorder,
    const RoundedRect& innerBorder,
    const IntPoint& innerBorderAdjustment,
    const BorderEdge edges[],
    BorderEdgeFlags edgeSet,
    BackgroundBleedAvoidance bleedAvoidance,
    bool includeLogicalLeftEdge,
    bool includeLogicalRightEdge,
    bool antialias,
    const Color* overrideColor) {
  bool renderRadii = outerBorder.isRounded();

  Path roundedPath;
  if (renderRadii)
    roundedPath.addRoundedRect(outerBorder);

  // The inner border adjustment for bleed avoidance mode
  // BackgroundBleedBackgroundOverBorder is only applied to sideRect, which is
  // okay since BackgroundBleedBackgroundOverBorder is only to be used for solid
  // borders and the shape of the border painted by drawBoxSideFromPath only
  // depends on sideRect when painting solid borders.

  if (edges[BSTop].shouldRender() && includesEdge(edgeSet, BSTop)) {
    IntRect sideRect = outerBorder.rect();
    sideRect.setHeight(edges[BSTop].width + innerBorderAdjustment.y());

    bool usePath =
        renderRadii && (borderStyleHasInnerDetail(edges[BSTop].style) ||
                        borderWillArcInnerEdge(innerBorder.radii().topLeft(),
                                               innerBorder.radii().topRight()));
    paintOneBorderSide(graphicsContext, style, outerBorder, innerBorder,
                       sideRect, BSTop, BSLeft, BSRight, edges,
                       usePath ? &roundedPath : 0, bleedAvoidance,
                       includeLogicalLeftEdge, includeLogicalRightEdge,
                       antialias, overrideColor);
  }

  if (edges[BSBottom].shouldRender() && includesEdge(edgeSet, BSBottom)) {
    IntRect sideRect = outerBorder.rect();
    sideRect.shiftYEdgeTo(sideRect.maxY() - edges[BSBottom].width -
                          innerBorderAdjustment.y());

    bool usePath = renderRadii &&
                   (borderStyleHasInnerDetail(edges[BSBottom].style) ||
                    borderWillArcInnerEdge(innerBorder.radii().bottomLeft(),
                                           innerBorder.radii().bottomRight()));
    paintOneBorderSide(graphicsContext, style, outerBorder, innerBorder,
                       sideRect, BSBottom, BSLeft, BSRight, edges,
                       usePath ? &roundedPath : 0, bleedAvoidance,
                       includeLogicalLeftEdge, includeLogicalRightEdge,
                       antialias, overrideColor);
  }

  if (edges[BSLeft].shouldRender() && includesEdge(edgeSet, BSLeft)) {
    IntRect sideRect = outerBorder.rect();
    sideRect.setWidth(edges[BSLeft].width + innerBorderAdjustment.x());

    bool usePath =
        renderRadii && (borderStyleHasInnerDetail(edges[BSLeft].style) ||
                        borderWillArcInnerEdge(innerBorder.radii().bottomLeft(),
                                               innerBorder.radii().topLeft()));
    paintOneBorderSide(graphicsContext, style, outerBorder, innerBorder,
                       sideRect, BSLeft, BSTop, BSBottom, edges,
                       usePath ? &roundedPath : 0, bleedAvoidance,
                       includeLogicalLeftEdge, includeLogicalRightEdge,
                       antialias, overrideColor);
  }

  if (edges[BSRight].shouldRender() && includesEdge(edgeSet, BSRight)) {
    IntRect sideRect = outerBorder.rect();
    sideRect.shiftXEdgeTo(sideRect.maxX() - edges[BSRight].width -
                          innerBorderAdjustment.x());

    bool usePath = renderRadii &&
                   (borderStyleHasInnerDetail(edges[BSRight].style) ||
                    borderWillArcInnerEdge(innerBorder.radii().bottomRight(),
                                           innerBorder.radii().topRight()));
    paintOneBorderSide(graphicsContext, style, outerBorder, innerBorder,
                       sideRect, BSRight, BSTop, BSBottom, edges,
                       usePath ? &roundedPath : 0, bleedAvoidance,
                       includeLogicalLeftEdge, includeLogicalRightEdge,
                       antialias, overrideColor);
  }
}

void RenderBoxModelObject::paintTranslucentBorderSides(
    GraphicsContext* graphicsContext,
    const RenderStyle* style,
    const RoundedRect& outerBorder,
    const RoundedRect& innerBorder,
    const IntPoint& innerBorderAdjustment,
    const BorderEdge edges[],
    BorderEdgeFlags edgesToDraw,
    BackgroundBleedAvoidance bleedAvoidance,
    bool includeLogicalLeftEdge,
    bool includeLogicalRightEdge,
    bool antialias) {
  // willBeOverdrawn assumes that we draw in order: top, bottom, left, right.
  // This is different from BoxSide enum order.
  static const BoxSide paintOrder[] = {BSTop, BSBottom, BSLeft, BSRight};

  while (edgesToDraw) {
    // Find undrawn edges sharing a color.
    Color commonColor;

    BorderEdgeFlags commonColorEdgeSet = 0;
    for (size_t i = 0; i < sizeof(paintOrder) / sizeof(paintOrder[0]); ++i) {
      BoxSide currSide = paintOrder[i];
      if (!includesEdge(edgesToDraw, currSide))
        continue;

      bool includeEdge;
      if (!commonColorEdgeSet) {
        commonColor = edges[currSide].color;
        includeEdge = true;
      } else
        includeEdge = edges[currSide].color == commonColor;

      if (includeEdge)
        commonColorEdgeSet |= edgeFlagForSide(currSide);
    }

    bool useTransparencyLayer =
        includesAdjacentEdges(commonColorEdgeSet) && commonColor.hasAlpha();
    if (useTransparencyLayer) {
      graphicsContext->beginTransparencyLayer(
          static_cast<float>(commonColor.alpha()) / 255);
      commonColor =
          Color(commonColor.red(), commonColor.green(), commonColor.blue());
    }

    paintBorderSides(graphicsContext, style, outerBorder, innerBorder,
                     innerBorderAdjustment, edges, commonColorEdgeSet,
                     bleedAvoidance, includeLogicalLeftEdge,
                     includeLogicalRightEdge, antialias, &commonColor);

    if (useTransparencyLayer)
      graphicsContext->endLayer();

    edgesToDraw &= ~commonColorEdgeSet;
  }
}

void RenderBoxModelObject::paintBorder(const PaintInfo& info,
                                       const LayoutRect& rect,
                                       const RenderStyle* style,
                                       BackgroundBleedAvoidance bleedAvoidance,
                                       bool includeLogicalLeftEdge,
                                       bool includeLogicalRightEdge) {
  GraphicsContext* graphicsContext = info.context;

  BorderEdge edges[4];
  getBorderEdgeInfo(edges, style, includeLogicalLeftEdge,
                    includeLogicalRightEdge);
  RoundedRect outerBorder = style->getRoundedBorderFor(
      rect, includeLogicalLeftEdge, includeLogicalRightEdge);
  RoundedRect innerBorder = style->getRoundedInnerBorderFor(
      borderInnerRectAdjustedForBleedAvoidance(graphicsContext, rect,
                                               bleedAvoidance),
      includeLogicalLeftEdge, includeLogicalRightEdge);

  if (outerBorder.rect().isEmpty())
    return;

  bool haveAlphaColor = false;
  bool haveAllSolidEdges = true;
  bool haveAllDoubleEdges = true;
  int numEdgesVisible = 4;
  bool allEdgesShareColor = true;
  bool allEdgesShareWidth = true;
  int firstVisibleEdge = -1;
  BorderEdgeFlags edgesToDraw = 0;

  for (int i = BSTop; i <= BSLeft; ++i) {
    const BorderEdge& currEdge = edges[i];

    if (edges[i].shouldRender())
      edgesToDraw |= edgeFlagForSide(static_cast<BoxSide>(i));

    if (currEdge.presentButInvisible()) {
      --numEdgesVisible;
      allEdgesShareColor = false;
      allEdgesShareWidth = false;
      continue;
    }

    if (!currEdge.shouldRender()) {
      --numEdgesVisible;
      continue;
    }

    if (firstVisibleEdge == -1) {
      firstVisibleEdge = i;
    } else {
      if (currEdge.color != edges[firstVisibleEdge].color)
        allEdgesShareColor = false;
      if (currEdge.width != edges[firstVisibleEdge].width)
        allEdgesShareWidth = false;
    }

    if (currEdge.color.hasAlpha())
      haveAlphaColor = true;

    if (currEdge.style != SOLID)
      haveAllSolidEdges = false;

    if (currEdge.style != DOUBLE)
      haveAllDoubleEdges = false;
  }

  // If no corner intersects the clip region, we can pretend outerBorder is
  // rectangular to improve performance.
  if (haveAllSolidEdges && outerBorder.isRounded() &&
      allCornersClippedOut(outerBorder, info.rect))
    outerBorder.setRadii(RoundedRect::Radii());

  // isRenderable() check avoids issue described in
  // https://bugs.webkit.org/show_bug.cgi?id=38787
  if ((haveAllSolidEdges || haveAllDoubleEdges) && allEdgesShareColor &&
      innerBorder.isRenderable()) {
    // Fast path for drawing all solid edges and all unrounded double edges

    if (numEdgesVisible == 4 && (outerBorder.isRounded() || haveAlphaColor) &&
        (haveAllSolidEdges ||
         (!outerBorder.isRounded() && !innerBorder.isRounded()))) {
      Path path;

      if (outerBorder.isRounded() && allEdgesShareWidth) {
        // Very fast path for single stroked round rect with circular corners

        graphicsContext->fillBetweenRoundedRects(outerBorder, innerBorder,
                                                 edges[firstVisibleEdge].color);
        return;
      }
      if (outerBorder.isRounded() &&
          bleedAvoidance != BackgroundBleedClipBackground)
        path.addRoundedRect(outerBorder);
      else
        path.addRect(outerBorder.rect());

      if (haveAllDoubleEdges) {
        IntRect innerThirdRect = outerBorder.rect();
        IntRect outerThirdRect = outerBorder.rect();
        for (int side = BSTop; side <= BSLeft; ++side) {
          int outerWidth;
          int innerWidth;
          edges[side].getDoubleBorderStripeWidths(outerWidth, innerWidth);

          if (side == BSTop) {
            innerThirdRect.shiftYEdgeTo(innerThirdRect.y() + innerWidth);
            outerThirdRect.shiftYEdgeTo(outerThirdRect.y() + outerWidth);
          } else if (side == BSBottom) {
            innerThirdRect.setHeight(innerThirdRect.height() - innerWidth);
            outerThirdRect.setHeight(outerThirdRect.height() - outerWidth);
          } else if (side == BSLeft) {
            innerThirdRect.shiftXEdgeTo(innerThirdRect.x() + innerWidth);
            outerThirdRect.shiftXEdgeTo(outerThirdRect.x() + outerWidth);
          } else {
            innerThirdRect.setWidth(innerThirdRect.width() - innerWidth);
            outerThirdRect.setWidth(outerThirdRect.width() - outerWidth);
          }
        }

        RoundedRect outerThird = outerBorder;
        RoundedRect innerThird = innerBorder;
        innerThird.setRect(innerThirdRect);
        outerThird.setRect(outerThirdRect);

        if (outerThird.isRounded() &&
            bleedAvoidance != BackgroundBleedClipBackground)
          path.addRoundedRect(outerThird);
        else
          path.addRect(outerThird.rect());

        if (innerThird.isRounded() &&
            bleedAvoidance != BackgroundBleedClipBackground)
          path.addRoundedRect(innerThird);
        else
          path.addRect(innerThird.rect());
      }

      if (innerBorder.isRounded())
        path.addRoundedRect(innerBorder);
      else
        path.addRect(innerBorder.rect());

      graphicsContext->setFillRule(RULE_EVENODD);
      graphicsContext->setFillColor(edges[firstVisibleEdge].color);
      graphicsContext->fillPath(path);
      return;
    }
    // Avoid creating transparent layers
    if (haveAllSolidEdges && numEdgesVisible != 4 && !outerBorder.isRounded() &&
        haveAlphaColor) {
      Path path;

      for (int i = BSTop; i <= BSLeft; ++i) {
        const BorderEdge& currEdge = edges[i];
        if (currEdge.shouldRender()) {
          IntRect sideRect = calculateSideRect(outerBorder, edges, i);
          path.addRect(sideRect);
        }
      }

      graphicsContext->setFillRule(RULE_NONZERO);
      graphicsContext->setFillColor(edges[firstVisibleEdge].color);
      graphicsContext->fillPath(path);
      return;
    }
  }

  bool clipToOuterBorder = outerBorder.isRounded();
  GraphicsContextStateSaver stateSaver(*graphicsContext, clipToOuterBorder);
  if (clipToOuterBorder) {
    // Clip to the inner and outer radii rects.
    if (bleedAvoidance != BackgroundBleedClipBackground)
      graphicsContext->clipRoundedRect(outerBorder);
    // isRenderable() check avoids issue described in
    // https://bugs.webkit.org/show_bug.cgi?id=38787 The inside will be clipped
    // out later (in clipBorderSideForComplexInnerPath)
    if (innerBorder.isRenderable() && !innerBorder.isEmpty())
      graphicsContext->clipOutRoundedRect(innerBorder);
  }

  // If only one edge visible antialiasing doesn't create seams
  bool antialias =
      shouldAntialiasLines(graphicsContext) || numEdgesVisible == 1;
  RoundedRect unadjustedInnerBorder =
      (bleedAvoidance == BackgroundBleedBackgroundOverBorder)
          ? style->getRoundedInnerBorderFor(rect, includeLogicalLeftEdge,
                                            includeLogicalRightEdge)
          : innerBorder;
  IntPoint innerBorderAdjustment(
      innerBorder.rect().x() - unadjustedInnerBorder.rect().x(),
      innerBorder.rect().y() - unadjustedInnerBorder.rect().y());
  if (haveAlphaColor)
    paintTranslucentBorderSides(
        graphicsContext, style, outerBorder, unadjustedInnerBorder,
        innerBorderAdjustment, edges, edgesToDraw, bleedAvoidance,
        includeLogicalLeftEdge, includeLogicalRightEdge, antialias);
  else
    paintBorderSides(graphicsContext, style, outerBorder, unadjustedInnerBorder,
                     innerBorderAdjustment, edges, edgesToDraw, bleedAvoidance,
                     includeLogicalLeftEdge, includeLogicalRightEdge,
                     antialias);
}

void RenderBoxModelObject::drawBoxSideFromPath(
    GraphicsContext* graphicsContext,
    const LayoutRect& borderRect,
    const Path& borderPath,
    const BorderEdge edges[],
    float thickness,
    float drawThickness,
    BoxSide side,
    const RenderStyle* style,
    Color color,
    EBorderStyle borderStyle,
    BackgroundBleedAvoidance bleedAvoidance,
    bool includeLogicalLeftEdge,
    bool includeLogicalRightEdge) {
  if (thickness <= 0)
    return;

  if (borderStyle == DOUBLE && thickness < 3)
    borderStyle = SOLID;

  switch (borderStyle) {
    case BNONE:
    case BHIDDEN:
      return;
    case DOTTED:
    case DASHED: {
      graphicsContext->setStrokeColor(color);

      // The stroke is doubled here because the provided path is the
      // outside edge of the border so half the stroke is clipped off.
      // The extra multiplier is so that the clipping mask can antialias
      // the edges to prevent jaggies.
      graphicsContext->setStrokeThickness(drawThickness * 2 * 1.1f);
      graphicsContext->setStrokeStyle(borderStyle == DASHED ? DashedStroke
                                                            : DottedStroke);

      // If the number of dashes that fit in the path is odd and non-integral
      // then we will have an awkwardly-sized dash at the end of the path. To
      // try to avoid that here, we simply make the whitespace dashes ever so
      // slightly bigger.
      // FIXME: This could be even better if we tried to manipulate the dash
      // offset and possibly the gapLength to get the corners dash-symmetrical.
      float dashLength = thickness * ((borderStyle == DASHED) ? 3.0f : 1.0f);
      float gapLength = dashLength;
      float numberOfDashes = borderPath.length() / dashLength;
      // Don't try to show dashes if we have less than 2 dashes + 2 gaps.
      // FIXME: should do this test per side.
      if (numberOfDashes >= 4) {
        bool evenNumberOfFullDashes = !((int)numberOfDashes % 2);
        bool integralNumberOfDashes = !(numberOfDashes - (int)numberOfDashes);
        if (!evenNumberOfFullDashes && !integralNumberOfDashes) {
          float numberOfGaps = numberOfDashes / 2;
          gapLength += (dashLength / numberOfGaps);
        }

        DashArray lineDash;
        lineDash.append(dashLength);
        lineDash.append(gapLength);
        graphicsContext->setLineDash(lineDash, dashLength);
      }

      // FIXME: stroking the border path causes issues with tight corners:
      // https://bugs.webkit.org/show_bug.cgi?id=58711
      // Also, to get the best appearance we should stroke a path between the
      // two borders.
      graphicsContext->strokePath(borderPath);
      return;
    }
    case DOUBLE: {
      // Get the inner border rects for both the outer border line and the inner
      // border line
      int outerBorderTopWidth;
      int innerBorderTopWidth;
      edges[BSTop].getDoubleBorderStripeWidths(outerBorderTopWidth,
                                               innerBorderTopWidth);

      int outerBorderRightWidth;
      int innerBorderRightWidth;
      edges[BSRight].getDoubleBorderStripeWidths(outerBorderRightWidth,
                                                 innerBorderRightWidth);

      int outerBorderBottomWidth;
      int innerBorderBottomWidth;
      edges[BSBottom].getDoubleBorderStripeWidths(outerBorderBottomWidth,
                                                  innerBorderBottomWidth);

      int outerBorderLeftWidth;
      int innerBorderLeftWidth;
      edges[BSLeft].getDoubleBorderStripeWidths(outerBorderLeftWidth,
                                                innerBorderLeftWidth);

      // Draw inner border line
      {
        GraphicsContextStateSaver stateSaver(*graphicsContext);
        RoundedRect innerClip = style->getRoundedInnerBorderFor(
            borderRect, innerBorderTopWidth, innerBorderBottomWidth,
            innerBorderLeftWidth, innerBorderRightWidth, includeLogicalLeftEdge,
            includeLogicalRightEdge);

        graphicsContext->clipRoundedRect(innerClip);
        drawBoxSideFromPath(graphicsContext, borderRect, borderPath, edges,
                            thickness, drawThickness, side, style, color, SOLID,
                            bleedAvoidance, includeLogicalLeftEdge,
                            includeLogicalRightEdge);
      }

      // Draw outer border line
      {
        GraphicsContextStateSaver stateSaver(*graphicsContext);
        LayoutRect outerRect = borderRect;
        if (bleedAvoidance == BackgroundBleedClipBackground) {
          outerRect.inflate(1);
          ++outerBorderTopWidth;
          ++outerBorderBottomWidth;
          ++outerBorderLeftWidth;
          ++outerBorderRightWidth;
        }

        RoundedRect outerClip = style->getRoundedInnerBorderFor(
            outerRect, outerBorderTopWidth, outerBorderBottomWidth,
            outerBorderLeftWidth, outerBorderRightWidth, includeLogicalLeftEdge,
            includeLogicalRightEdge);
        graphicsContext->clipOutRoundedRect(outerClip);
        drawBoxSideFromPath(graphicsContext, borderRect, borderPath, edges,
                            thickness, drawThickness, side, style, color, SOLID,
                            bleedAvoidance, includeLogicalLeftEdge,
                            includeLogicalRightEdge);
      }
      return;
    }
    case RIDGE:
    case GROOVE: {
      EBorderStyle s1;
      EBorderStyle s2;
      if (borderStyle == GROOVE) {
        s1 = INSET;
        s2 = OUTSET;
      } else {
        s1 = OUTSET;
        s2 = INSET;
      }

      // Paint full border
      drawBoxSideFromPath(graphicsContext, borderRect, borderPath, edges,
                          thickness, drawThickness, side, style, color, s1,
                          bleedAvoidance, includeLogicalLeftEdge,
                          includeLogicalRightEdge);

      // Paint inner only
      GraphicsContextStateSaver stateSaver(*graphicsContext);
      LayoutUnit topWidth = edges[BSTop].usedWidth() / 2;
      LayoutUnit bottomWidth = edges[BSBottom].usedWidth() / 2;
      LayoutUnit leftWidth = edges[BSLeft].usedWidth() / 2;
      LayoutUnit rightWidth = edges[BSRight].usedWidth() / 2;

      RoundedRect clipRect = style->getRoundedInnerBorderFor(
          borderRect, topWidth, bottomWidth, leftWidth, rightWidth,
          includeLogicalLeftEdge, includeLogicalRightEdge);

      graphicsContext->clipRoundedRect(clipRect);
      drawBoxSideFromPath(graphicsContext, borderRect, borderPath, edges,
                          thickness, drawThickness, side, style, color, s2,
                          bleedAvoidance, includeLogicalLeftEdge,
                          includeLogicalRightEdge);
      return;
    }
    case INSET:
      if (side == BSTop || side == BSLeft)
        color = color.dark();
      break;
    case OUTSET:
      if (side == BSBottom || side == BSRight)
        color = color.dark();
      break;
    default:
      break;
  }

  graphicsContext->setStrokeStyle(NoStroke);
  graphicsContext->setFillColor(color);
  graphicsContext->drawRect(pixelSnappedIntRect(borderRect));
}

void RenderBoxModelObject::clipBorderSidePolygon(
    GraphicsContext* graphicsContext,
    const RoundedRect& outerBorder,
    const RoundedRect& innerBorder,
    BoxSide side,
    bool firstEdgeMatches,
    bool secondEdgeMatches) {
  FloatPoint quad[4];

  const LayoutRect& outerRect = outerBorder.rect();
  const LayoutRect& innerRect = innerBorder.rect();

  FloatPoint centerPoint(
      innerRect.location().x().toFloat() + innerRect.width().toFloat() / 2,
      innerRect.location().y().toFloat() + innerRect.height().toFloat() / 2);

  // For each side, create a quad that encompasses all parts of that side that
  // may draw, including areas inside the innerBorder.
  //
  //         0----------------3
  //       0  \              /  0
  //       |\  1----------- 2  /|
  //       | 1                1 |
  //       | |                | |
  //       | |                | |
  //       | 2                2 |
  //       |/  1------------2  \|
  //       3  /              \  3
  //         0----------------3
  //
  switch (side) {
    case BSTop:
      quad[0] = outerRect.minXMinYCorner();
      quad[1] = innerRect.minXMinYCorner();
      quad[2] = innerRect.maxXMinYCorner();
      quad[3] = outerRect.maxXMinYCorner();

      if (!innerBorder.radii().topLeft().isZero()) {
        findIntersection(
            quad[0], quad[1],
            FloatPoint(quad[1].x() + innerBorder.radii().topLeft().width(),
                       quad[1].y()),
            FloatPoint(quad[1].x(),
                       quad[1].y() + innerBorder.radii().topLeft().height()),
            quad[1]);
      }

      if (!innerBorder.radii().topRight().isZero()) {
        findIntersection(
            quad[3], quad[2],
            FloatPoint(quad[2].x() - innerBorder.radii().topRight().width(),
                       quad[2].y()),
            FloatPoint(quad[2].x(),
                       quad[2].y() + innerBorder.radii().topRight().height()),
            quad[2]);
      }
      break;

    case BSLeft:
      quad[0] = outerRect.minXMinYCorner();
      quad[1] = innerRect.minXMinYCorner();
      quad[2] = innerRect.minXMaxYCorner();
      quad[3] = outerRect.minXMaxYCorner();

      if (!innerBorder.radii().topLeft().isZero()) {
        findIntersection(
            quad[0], quad[1],
            FloatPoint(quad[1].x() + innerBorder.radii().topLeft().width(),
                       quad[1].y()),
            FloatPoint(quad[1].x(),
                       quad[1].y() + innerBorder.radii().topLeft().height()),
            quad[1]);
      }

      if (!innerBorder.radii().bottomLeft().isZero()) {
        findIntersection(
            quad[3], quad[2],
            FloatPoint(quad[2].x() + innerBorder.radii().bottomLeft().width(),
                       quad[2].y()),
            FloatPoint(quad[2].x(),
                       quad[2].y() - innerBorder.radii().bottomLeft().height()),
            quad[2]);
      }
      break;

    case BSBottom:
      quad[0] = outerRect.minXMaxYCorner();
      quad[1] = innerRect.minXMaxYCorner();
      quad[2] = innerRect.maxXMaxYCorner();
      quad[3] = outerRect.maxXMaxYCorner();

      if (!innerBorder.radii().bottomLeft().isZero()) {
        findIntersection(
            quad[0], quad[1],
            FloatPoint(quad[1].x() + innerBorder.radii().bottomLeft().width(),
                       quad[1].y()),
            FloatPoint(quad[1].x(),
                       quad[1].y() - innerBorder.radii().bottomLeft().height()),
            quad[1]);
      }

      if (!innerBorder.radii().bottomRight().isZero()) {
        findIntersection(
            quad[3], quad[2],
            FloatPoint(quad[2].x() - innerBorder.radii().bottomRight().width(),
                       quad[2].y()),
            FloatPoint(
                quad[2].x(),
                quad[2].y() - innerBorder.radii().bottomRight().height()),
            quad[2]);
      }
      break;

    case BSRight:
      quad[0] = outerRect.maxXMinYCorner();
      quad[1] = innerRect.maxXMinYCorner();
      quad[2] = innerRect.maxXMaxYCorner();
      quad[3] = outerRect.maxXMaxYCorner();

      if (!innerBorder.radii().topRight().isZero()) {
        findIntersection(
            quad[0], quad[1],
            FloatPoint(quad[1].x() - innerBorder.radii().topRight().width(),
                       quad[1].y()),
            FloatPoint(quad[1].x(),
                       quad[1].y() + innerBorder.radii().topRight().height()),
            quad[1]);
      }

      if (!innerBorder.radii().bottomRight().isZero()) {
        findIntersection(
            quad[3], quad[2],
            FloatPoint(quad[2].x() - innerBorder.radii().bottomRight().width(),
                       quad[2].y()),
            FloatPoint(
                quad[2].x(),
                quad[2].y() - innerBorder.radii().bottomRight().height()),
            quad[2]);
      }
      break;
  }

  // If the border matches both of its adjacent sides, don't anti-alias the
  // clip, and if neither side matches, anti-alias the clip.
  if (firstEdgeMatches == secondEdgeMatches) {
    graphicsContext->clipConvexPolygon(4, quad, !firstEdgeMatches);
    return;
  }

  // If antialiasing settings for the first edge and second edge is different,
  // they have to be addressed separately. We do this by breaking the quad into
  // two parallelograms, made by moving quad[1] and quad[2].
  float ax = quad[1].x() - quad[0].x();
  float ay = quad[1].y() - quad[0].y();
  float bx = quad[2].x() - quad[1].x();
  float by = quad[2].y() - quad[1].y();
  float cx = quad[3].x() - quad[2].x();
  float cy = quad[3].y() - quad[2].y();

  const static float kEpsilon = 1e-2f;
  float r1, r2;
  if (fabsf(bx) < kEpsilon && fabsf(by) < kEpsilon) {
    // The quad was actually a triangle.
    r1 = r2 = 1.0f;
  } else {
    // Extend parallelogram a bit to hide calculation error
    const static float kExtendFill = 1e-2f;

    r1 = (-ax * by + ay * bx) / (cx * by - cy * bx) + kExtendFill;
    r2 = (-cx * by + cy * bx) / (ax * by - ay * bx) + kExtendFill;
  }

  FloatPoint firstQuad[4];
  firstQuad[0] = quad[0];
  firstQuad[1] = quad[1];
  firstQuad[2] = FloatPoint(quad[3].x() + r2 * ax, quad[3].y() + r2 * ay);
  firstQuad[3] = quad[3];
  graphicsContext->clipConvexPolygon(4, firstQuad, !firstEdgeMatches);

  FloatPoint secondQuad[4];
  secondQuad[0] = quad[0];
  secondQuad[1] = FloatPoint(quad[0].x() - r1 * cx, quad[0].y() - r1 * cy);
  secondQuad[2] = quad[2];
  secondQuad[3] = quad[3];
  graphicsContext->clipConvexPolygon(4, secondQuad, !secondEdgeMatches);
}

static IntRect calculateSideRectIncludingInner(const RoundedRect& outerBorder,
                                               const BorderEdge edges[],
                                               BoxSide side) {
  IntRect sideRect = outerBorder.rect();
  int width;

  switch (side) {
    case BSTop:
      width = sideRect.height() - edges[BSBottom].width;
      sideRect.setHeight(width);
      break;
    case BSBottom:
      width = sideRect.height() - edges[BSTop].width;
      sideRect.shiftYEdgeTo(sideRect.maxY() - width);
      break;
    case BSLeft:
      width = sideRect.width() - edges[BSRight].width;
      sideRect.setWidth(width);
      break;
    case BSRight:
      width = sideRect.width() - edges[BSLeft].width;
      sideRect.shiftXEdgeTo(sideRect.maxX() - width);
      break;
  }

  return sideRect;
}

static RoundedRect calculateAdjustedInnerBorder(const RoundedRect& innerBorder,
                                                BoxSide side) {
  // Expand the inner border as necessary to make it a rounded rect (i.e. radii
  // contained within each edge). This function relies on the fact we only get
  // radii not contained within each edge if one of the radii for an edge is
  // zero, so we can shift the arc towards the zero radius corner.
  RoundedRect::Radii newRadii = innerBorder.radii();
  IntRect newRect = innerBorder.rect();

  float overshoot;
  float maxRadii;

  switch (side) {
    case BSTop:
      overshoot = newRadii.topLeft().width() + newRadii.topRight().width() -
                  newRect.width();
      if (overshoot > 0) {
        ASSERT(!(newRadii.topLeft().width() && newRadii.topRight().width()));
        newRect.setWidth(newRect.width() + overshoot);
        if (!newRadii.topLeft().width())
          newRect.move(-overshoot, 0);
      }
      newRadii.setBottomLeft(IntSize(0, 0));
      newRadii.setBottomRight(IntSize(0, 0));
      maxRadii =
          std::max(newRadii.topLeft().height(), newRadii.topRight().height());
      if (maxRadii > newRect.height())
        newRect.setHeight(maxRadii);
      break;

    case BSBottom:
      overshoot = newRadii.bottomLeft().width() +
                  newRadii.bottomRight().width() - newRect.width();
      if (overshoot > 0) {
        ASSERT(
            !(newRadii.bottomLeft().width() && newRadii.bottomRight().width()));
        newRect.setWidth(newRect.width() + overshoot);
        if (!newRadii.bottomLeft().width())
          newRect.move(-overshoot, 0);
      }
      newRadii.setTopLeft(IntSize(0, 0));
      newRadii.setTopRight(IntSize(0, 0));
      maxRadii = std::max(newRadii.bottomLeft().height(),
                          newRadii.bottomRight().height());
      if (maxRadii > newRect.height()) {
        newRect.move(0, newRect.height() - maxRadii);
        newRect.setHeight(maxRadii);
      }
      break;

    case BSLeft:
      overshoot = newRadii.topLeft().height() + newRadii.bottomLeft().height() -
                  newRect.height();
      if (overshoot > 0) {
        ASSERT(
            !(newRadii.topLeft().height() && newRadii.bottomLeft().height()));
        newRect.setHeight(newRect.height() + overshoot);
        if (!newRadii.topLeft().height())
          newRect.move(0, -overshoot);
      }
      newRadii.setTopRight(IntSize(0, 0));
      newRadii.setBottomRight(IntSize(0, 0));
      maxRadii =
          std::max(newRadii.topLeft().width(), newRadii.bottomLeft().width());
      if (maxRadii > newRect.width())
        newRect.setWidth(maxRadii);
      break;

    case BSRight:
      overshoot = newRadii.topRight().height() +
                  newRadii.bottomRight().height() - newRect.height();
      if (overshoot > 0) {
        ASSERT(
            !(newRadii.topRight().height() && newRadii.bottomRight().height()));
        newRect.setHeight(newRect.height() + overshoot);
        if (!newRadii.topRight().height())
          newRect.move(0, -overshoot);
      }
      newRadii.setTopLeft(IntSize(0, 0));
      newRadii.setBottomLeft(IntSize(0, 0));
      maxRadii =
          std::max(newRadii.topRight().width(), newRadii.bottomRight().width());
      if (maxRadii > newRect.width()) {
        newRect.move(newRect.width() - maxRadii, 0);
        newRect.setWidth(maxRadii);
      }
      break;
  }

  return RoundedRect(newRect, newRadii);
}

void RenderBoxModelObject::clipBorderSideForComplexInnerPath(
    GraphicsContext* graphicsContext,
    const RoundedRect& outerBorder,
    const RoundedRect& innerBorder,
    BoxSide side,
    const class BorderEdge edges[]) {
  graphicsContext->clip(
      calculateSideRectIncludingInner(outerBorder, edges, side));
  RoundedRect adjustedInnerRect =
      calculateAdjustedInnerBorder(innerBorder, side);
  if (!adjustedInnerRect.isEmpty())
    graphicsContext->clipOutRoundedRect(adjustedInnerRect);
}

void RenderBoxModelObject::getBorderEdgeInfo(
    BorderEdge edges[],
    const RenderStyle* style,
    bool includeLogicalLeftEdge,
    bool includeLogicalRightEdge) const {
  edges[BSTop] = BorderEdge(
      style->borderTopWidth(), style->resolveColor(style->borderTopColor()),
      style->borderTopStyle(), style->borderTopIsTransparent(), true);

  edges[BSRight] = BorderEdge(
      style->borderRightWidth(), style->resolveColor(style->borderRightColor()),
      style->borderRightStyle(), style->borderRightIsTransparent(),
      includeLogicalRightEdge);

  edges[BSBottom] = BorderEdge(style->borderBottomWidth(),
                               style->resolveColor(style->borderBottomColor()),
                               style->borderBottomStyle(),
                               style->borderBottomIsTransparent(), true);

  edges[BSLeft] = BorderEdge(
      style->borderLeftWidth(), style->resolveColor(style->borderLeftColor()),
      style->borderLeftStyle(), style->borderLeftIsTransparent(),
      includeLogicalLeftEdge);
}

bool RenderBoxModelObject::borderObscuresBackgroundEdge(
    const FloatSize& contextScale) const {
  BorderEdge edges[4];
  getBorderEdgeInfo(edges, style());

  for (int i = BSTop; i <= BSLeft; ++i) {
    const BorderEdge& currEdge = edges[i];
    // FIXME: for vertical text
    float axisScale = (i == BSTop || i == BSBottom) ? contextScale.height()
                                                    : contextScale.width();
    if (!currEdge.obscuresBackgroundEdge(axisScale))
      return false;
  }

  return true;
}

bool RenderBoxModelObject::borderObscuresBackground() const {
  if (!style()->hasBorder())
    return false;

  BorderEdge edges[4];
  getBorderEdgeInfo(edges, style());

  for (int i = BSTop; i <= BSLeft; ++i) {
    const BorderEdge& currEdge = edges[i];
    if (!currEdge.obscuresBackground())
      return false;
  }

  return true;
}

bool RenderBoxModelObject::boxShadowShouldBeAppliedToBackground(
    BackgroundBleedAvoidance bleedAvoidance,
    InlineFlowBox* inlineFlowBox) const {
  if (bleedAvoidance != BackgroundBleedNone)
    return false;

  const ShadowList* shadowList = style()->boxShadow();
  if (!shadowList)
    return false;

  bool hasOneNormalBoxShadow = false;
  size_t shadowCount = shadowList->shadows().size();
  for (size_t i = 0; i < shadowCount; ++i) {
    const ShadowData& currentShadow = shadowList->shadows()[i];
    if (currentShadow.style() != Normal)
      continue;

    if (hasOneNormalBoxShadow)
      return false;
    hasOneNormalBoxShadow = true;

    if (currentShadow.spread())
      return false;
  }

  if (!hasOneNormalBoxShadow)
    return false;

  Color backgroundColor = style()->resolveColor(style()->backgroundColor());
  if (backgroundColor.hasAlpha())
    return false;

  const FillLayer* lastBackgroundLayer = &style()->backgroundLayers();
  for (const FillLayer* next = lastBackgroundLayer->next(); next;
       next = lastBackgroundLayer->next())
    lastBackgroundLayer = next;

  if (lastBackgroundLayer->clip() != BorderFillBox)
    return false;

  if (lastBackgroundLayer->image() && style()->hasBorderRadius())
    return false;

  if (inlineFlowBox &&
      !inlineFlowBox->boxShadowCanBeAppliedToBackground(*lastBackgroundLayer))
    return false;

  if (hasOverflowClip() &&
      lastBackgroundLayer->attachment() == LocalBackgroundAttachment)
    return false;

  return true;
}

void RenderBoxModelObject::paintBoxShadow(const PaintInfo& info,
                                          const LayoutRect& paintRect,
                                          const RenderStyle* s,
                                          ShadowStyle shadowStyle,
                                          bool includeLogicalLeftEdge,
                                          bool includeLogicalRightEdge) {
  // FIXME: Deal with border-image.  Would be great to use border-image as a
  // mask.
  GraphicsContext* context = info.context;
  if (!s->boxShadow())
    return;

  RoundedRect border =
      (shadowStyle == Inset)
          ? s->getRoundedInnerBorderFor(paintRect, includeLogicalLeftEdge,
                                        includeLogicalRightEdge)
          : s->getRoundedBorderFor(paintRect, includeLogicalLeftEdge,
                                   includeLogicalRightEdge);

  bool hasBorderRadius = s->hasBorderRadius();
  bool hasOpaqueBackground =
      s->resolveColor(s->backgroundColor()).alpha() == 255;

  GraphicsContextStateSaver stateSaver(*context, false);

  const ShadowList* shadowList = s->boxShadow();
  for (size_t i = shadowList->shadows().size(); i--;) {
    const ShadowData& shadow = shadowList->shadows()[i];
    if (shadow.style() != shadowStyle)
      continue;

    FloatSize shadowOffset(shadow.x(), shadow.y());
    float shadowBlur = shadow.blur();
    float shadowSpread = shadow.spread();

    if (shadowOffset.isZero() && !shadowBlur && !shadowSpread)
      continue;

    const Color& shadowColor = shadow.color();

    if (shadow.style() == Normal) {
      FloatRect fillRect = border.rect();
      fillRect.inflate(shadowSpread);
      if (fillRect.isEmpty())
        continue;

      FloatRect shadowRect(border.rect());
      shadowRect.inflate(shadowBlur + shadowSpread);
      shadowRect.move(shadowOffset);

      // Save the state and clip, if not already done.
      // The clip does not depend on any shadow-specific properties.
      if (!stateSaver.saved()) {
        stateSaver.save();
        if (hasBorderRadius) {
          RoundedRect rectToClipOut = border;

          // If the box is opaque, it is unnecessary to clip it out. However,
          // doing so saves time when painting the shadow. On the other hand, it
          // introduces subpixel gaps along the corners. Those are avoided by
          // insetting the clipping path by one pixel.
          if (hasOpaqueBackground)
            rectToClipOut.inflateWithRadii(-1);

          if (!rectToClipOut.isEmpty()) {
            context->clipOutRoundedRect(rectToClipOut);
          }
        } else {
          // This IntRect is correct even with fractional shadows, because it is
          // used for the rectangle of the box itself, which is always
          // pixel-aligned.
          IntRect rectToClipOut = border.rect();

          // If the box is opaque, it is unnecessary to clip it out. However,
          // doing so saves time when painting the shadow. On the other hand, it
          // introduces subpixel gaps along the edges if they are not
          // pixel-aligned. Those are avoided by insetting the clipping path by
          // one pixel.
          if (hasOpaqueBackground) {
            // FIXME: The function to decide on the policy based on the
            // transform should be a named function.
            // FIXME: It's not clear if this check is right. What about integral
            // scale factors?
            AffineTransform transform = context->getCTM();
            if (transform.a() != 1 ||
                (transform.d() != 1 && transform.d() != -1) || transform.b() ||
                transform.c())
              rectToClipOut.inflate(-1);
          }

          if (!rectToClipOut.isEmpty()) {
            context->clipOut(rectToClipOut);
          }
        }
      }

      // Draw only the shadow.
      OwnPtr<DrawLooperBuilder> drawLooperBuilder = DrawLooperBuilder::create();
      drawLooperBuilder->addShadow(shadowOffset, shadowBlur, shadowColor,
                                   DrawLooperBuilder::ShadowRespectsTransforms,
                                   DrawLooperBuilder::ShadowIgnoresAlpha);
      context->setDrawLooper(drawLooperBuilder.release());

      if (hasBorderRadius) {
        RoundedRect influenceRect(pixelSnappedIntRect(LayoutRect(shadowRect)),
                                  border.radii());
        influenceRect.expandRadii(2 * shadowBlur + shadowSpread);
        if (allCornersClippedOut(influenceRect, info.rect))
          context->fillRect(fillRect, Color::black);
        else {
          // TODO: support non-integer shadows - crbug.com/334829
          RoundedRect roundedFillRect = border;
          roundedFillRect.inflate(shadowSpread);

          roundedFillRect.expandRadii(shadowSpread);
          if (!roundedFillRect.isRenderable())
            roundedFillRect.adjustRadii();
          context->fillRoundedRect(roundedFillRect, Color::black);
        }
      } else {
        context->fillRect(fillRect, Color::black);
      }
    } else {
      // The inset shadow case.
      GraphicsContext::Edges clippedEdges = GraphicsContext::NoEdge;
      if (!includeLogicalLeftEdge) {
        clippedEdges |= GraphicsContext::LeftEdge;
      }
      if (!includeLogicalRightEdge) {
        clippedEdges |= GraphicsContext::RightEdge;
      }
      // TODO: support non-integer shadows - crbug.com/334828
      context->drawInnerShadow(border, shadowColor,
                               flooredIntSize(shadowOffset), shadowBlur,
                               shadowSpread, clippedEdges);
    }
  }
}

LayoutUnit RenderBoxModelObject::containingBlockLogicalWidthForContent() const {
  return containingBlock()->availableLogicalWidth();
}

LayoutRect RenderBoxModelObject::localCaretRectForEmptyElement(
    LayoutUnit width,
    LayoutUnit textIndentOffset) {
  ASSERT(!slowFirstChild());

  // FIXME: This does not take into account either :first-line or :first-letter
  // However, as soon as some content is entered, the line boxes will be
  // constructed and this kludge is not called any more. So only the caret size
  // of an empty :first-line'd block is wrong. I think we can live with that.
  RenderStyle* currentStyle = firstLineStyle();

  enum CaretAlignment { alignLeft, alignRight, alignCenter };

  CaretAlignment alignment = alignLeft;

  switch (currentStyle->textAlign()) {
    case LEFT:
      break;
    case CENTER:
      alignment = alignCenter;
      break;
    case RIGHT:
      alignment = alignRight;
      break;
    case JUSTIFY:
    case TASTART:
      if (!currentStyle->isLeftToRightDirection())
        alignment = alignRight;
      break;
    case TAEND:
      if (currentStyle->isLeftToRightDirection())
        alignment = alignRight;
      break;
  }

  LayoutUnit x = borderLeft() + paddingLeft();
  LayoutUnit maxX = width - borderRight() - paddingRight();

  switch (alignment) {
    case alignLeft:
      if (currentStyle->isLeftToRightDirection())
        x += textIndentOffset;
      break;
    case alignCenter:
      x = (x + maxX) / 2;
      if (currentStyle->isLeftToRightDirection())
        x += textIndentOffset / 2;
      else
        x -= textIndentOffset / 2;
      break;
    case alignRight:
      x = maxX - caretWidth;
      if (!currentStyle->isLeftToRightDirection())
        x -= textIndentOffset;
      break;
  }
  x = std::min(x, std::max<LayoutUnit>(maxX - caretWidth, 0));

  LayoutUnit height = style()->fontMetrics().height();
  LayoutUnit verticalSpace =
      lineHeight(true, HorizontalLine, PositionOfInteriorLineBoxes) - height;
  LayoutUnit y = paddingTop() + borderTop() + (verticalSpace / 2);
  return LayoutRect(x, y, caretWidth, height);
}

bool RenderBoxModelObject::shouldAntialiasLines(GraphicsContext* context) {
  // FIXME: We may want to not antialias when scaled by an integral value,
  // and we may want to antialias when translated by a non-integral value.
  // FIXME: See crbug.com/382491. getCTM does not include scale factors applied
  // at raster time, such as device zoom.
  return !context->getCTM().isIdentityOrTranslationOrFlipped();
}

void RenderBoxModelObject::mapAbsoluteToLocalPoint(
    MapCoordinatesFlags mode,
    TransformState& transformState) const {
  RenderObject* o = container();
  if (!o)
    return;

  o->mapAbsoluteToLocalPoint(mode, transformState);

  LayoutSize containerOffset = offsetFromContainer(o, LayoutPoint());

  bool preserve3D = mode & UseTransforms &&
                    (o->style()->preserves3D() || style()->preserves3D());
  if (mode & UseTransforms && shouldUseTransformFromContainer(o)) {
    TransformationMatrix t;
    getTransformFromContainer(o, containerOffset, t);
    transformState.applyTransform(t, preserve3D
                                         ? TransformState::AccumulateTransform
                                         : TransformState::FlattenTransform);
  } else
    transformState.move(containerOffset.width(), containerOffset.height(),
                        preserve3D ? TransformState::AccumulateTransform
                                   : TransformState::FlattenTransform);
}

const RenderObject* RenderBoxModelObject::pushMappingToContainer(
    const RenderBox* ancestorToStopAt,
    RenderGeometryMap& geometryMap) const {
  ASSERT(ancestorToStopAt != this);

  bool ancestorSkipped;
  RenderObject* container = this->container(ancestorToStopAt, &ancestorSkipped);
  if (!container)
    return 0;

  bool isInline = isRenderInline();
  bool hasTransform = !isInline && isBox() && toRenderBox(this)->transform();

  LayoutSize adjustmentForSkippedAncestor;
  if (ancestorSkipped) {
    // There can't be a transform between paintInvalidationContainer and o,
    // because transforms create containers, so it should be safe to just
    // subtract the delta between the ancestor and o.
    adjustmentForSkippedAncestor =
        -ancestorToStopAt->offsetFromAncestorContainer(container);
  }

  bool offsetDependsOnPoint = false;
  LayoutSize containerOffset =
      offsetFromContainer(container, LayoutPoint(), &offsetDependsOnPoint);

  bool preserve3D = container->style()->preserves3D() || style()->preserves3D();
  if (shouldUseTransformFromContainer(container)) {
    TransformationMatrix t;
    getTransformFromContainer(container, containerOffset, t);
    t.translateRight(adjustmentForSkippedAncestor.width().toFloat(),
                     adjustmentForSkippedAncestor.height().toFloat());
    geometryMap.push(this, t, preserve3D, offsetDependsOnPoint, hasTransform);
  } else {
    containerOffset += adjustmentForSkippedAncestor;
    geometryMap.push(this, containerOffset, preserve3D, offsetDependsOnPoint,
                     hasTransform);
  }

  return ancestorSkipped ? ancestorToStopAt : container;
}

void RenderBoxModelObject::collectSelfPaintingLayers(
    Vector<RenderBox*>& layers) {
  for (RenderObject* child = slowFirstChild(); child;
       child = child->nextSibling()) {
    if (child->isBox()) {
      RenderBox* childBox = toRenderBox(child);
      if (childBox->hasSelfPaintingLayer())
        layers.append(childBox);
      else
        childBox->collectSelfPaintingLayers(layers);
    } else if (child->isBoxModelObject()) {
      toRenderBoxModelObject(child)->collectSelfPaintingLayers(layers);
    }
  }
}

void RenderBoxModelObject::moveChildTo(RenderBoxModelObject* toBoxModelObject,
                                       RenderObject* child,
                                       RenderObject* beforeChild,
                                       bool fullRemoveInsert) {
  // We assume that callers have cleared their positioned objects list for child
  // moves (!fullRemoveInsert) so the positioned renderer maps don't become
  // stale. It would be too slow to do the map lookup on each call.
  ASSERT(!fullRemoveInsert || !isRenderBlock() ||
         !toRenderBlock(this)->hasPositionedObjects());

  ASSERT(this == child->parent());
  ASSERT(!beforeChild || toBoxModelObject == beforeChild->parent());
  if (fullRemoveInsert && (toBoxModelObject->isRenderBlock() ||
                           toBoxModelObject->isRenderInline())) {
    // Takes care of adding the new child correctly if toBlock and fromBlock
    // have different kind of children (block vs inline).
    toBoxModelObject->addChild(virtualChildren()->removeChildNode(this, child),
                               beforeChild);
  } else
    toBoxModelObject->virtualChildren()->insertChildNode(
        toBoxModelObject,
        virtualChildren()->removeChildNode(this, child, fullRemoveInsert),
        beforeChild, fullRemoveInsert);
}

void RenderBoxModelObject::moveAllChildrenTo(
    RenderBoxModelObject* toBoxModelObject,
    RenderObject* beforeChild,
    bool fullRemoveInsert) {
  // This condition is rarely hit since this function is usually called on
  // anonymous blocks which can no longer carry positioned objects (see r120761)
  // or when fullRemoveInsert is false.
  if (fullRemoveInsert && isRenderBlock()) {
    RenderBlock* block = toRenderBlock(this);
    block->removePositionedObjects(0);
  }

  ASSERT(!beforeChild || toBoxModelObject == beforeChild->parent());
  for (RenderObject* child = slowFirstChild(); child;) {
    // Save our next sibling as moveChildTo will clear it.
    RenderObject* nextSibling = child->nextSibling();
    moveChildTo(toBoxModelObject, child, beforeChild, fullRemoveInsert);
    child = nextSibling;
  }
}

}  // namespace blink
