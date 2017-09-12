/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2005 Allan Sandfeld Jensen (kde@carewolf.com)
 *           (C) 2005, 2006 Samuel Weinig (sam.weinig@gmail.com)
 * Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010 Apple Inc.
 * All rights reserved.
 * Copyright (C) 2013 Adobe Systems Incorporated. All rights reserved.
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

#include "flutter/sky/engine/core/rendering/RenderBox.h"

#include <math.h>
#include <algorithm>
#include "flutter/sky/engine/core/rendering/HitTestResult.h"
#include "flutter/sky/engine/core/rendering/HitTestingTransformState.h"
#include "flutter/sky/engine/core/rendering/PaintInfo.h"
#include "flutter/sky/engine/core/rendering/RenderFlexibleBox.h"
#include "flutter/sky/engine/core/rendering/RenderGeometryMap.h"
#include "flutter/sky/engine/core/rendering/RenderInline.h"
#include "flutter/sky/engine/core/rendering/RenderLayer.h"
#include "flutter/sky/engine/core/rendering/RenderView.h"
#include "flutter/sky/engine/platform/LengthFunctions.h"
#include "flutter/sky/engine/platform/geometry/FloatQuad.h"
#include "flutter/sky/engine/platform/geometry/TransformState.h"
#include "flutter/sky/engine/platform/graphics/GraphicsContextStateSaver.h"

namespace blink {

RenderBox::RenderBox()
    : m_intrinsicContentLogicalHeight(-1),
      m_minPreferredLogicalWidth(-1),
      m_maxPreferredLogicalWidth(-1) {
  setIsBox();
}

void RenderBox::willBeDestroyed() {
  clearOverrideSize();
  RenderBlock::removePercentHeightDescendantIfNeeded(this);
  RenderBoxModelObject::willBeDestroyed();
  destroyLayer();
}

void RenderBox::destroyLayer() {
  setHasLayer(false);
  m_layer = nullptr;
}

void RenderBox::createLayer(LayerType type) {
  ASSERT(!m_layer);
  m_layer = adoptPtr(new RenderLayer(this, type));
  setHasLayer(true);
  m_layer->insertOnlyThisLayer();
}

bool RenderBox::hasSelfPaintingLayer() const {
  return m_layer && m_layer->isSelfPaintingLayer();
}

void RenderBox::removeFloatingOrPositionedChildFromBlockLists() {
  ASSERT(isFloatingOrOutOfFlowPositioned());

  if (documentBeingDestroyed())
    return;

  if (isOutOfFlowPositioned())
    RenderBlock::removePositionedObject(this);
}

void RenderBox::styleWillChange(StyleDifference diff,
                                const RenderStyle& newStyle) {
  RenderStyle* oldStyle = style();
  if (oldStyle && parent()) {
    // When a layout hint happens and an object's position style changes, we
    // have to do a layout to dirty the render tree using the old position value
    // now.
    if (diff.needsFullLayout() && oldStyle->position() != newStyle.position()) {
      markContainingBlocksForLayout();
      if (newStyle.hasOutOfFlowPosition())
        parent()->setChildNeedsLayout();
    }

    if (oldStyle->hasAutoClip() != newStyle.hasAutoClip() ||
        oldStyle->clip() != newStyle.clip())
      layer()->clipper().clearClipRectsIncludingDescendants();
  }

  RenderBoxModelObject::styleWillChange(diff, newStyle);
}

void RenderBox::styleDidChange(StyleDifference diff,
                               const RenderStyle* oldStyle) {
  bool hadTransform = hasTransform();

  RenderObject::styleDidChange(diff, oldStyle);
  updateFromStyle();

  LayerType type = layerTypeRequired();
  if (type != NoLayer) {
    if (!layer()) {
      createLayer(type);
      if (parent() && !needsLayout()) {
        // FIXME: We should call a specialized version of this function.
        layer()->updateLayerPositionsAfterLayout();
      }
    }
  } else if (layer() && layer()->parent()) {
    setHasTransform(false);  // Either a transform wasn't specified or the
                             // object doesn't support transforms, so just null
                             // out the bit.
    layer()
        ->removeOnlyThisLayer();  // calls destroyLayer() which clears m_layer
    if (hadTransform)
      setNeedsLayoutAndPrefWidthsRecalc();
  }

  if (layer()) {
    // FIXME: Ideally we shouldn't need this setter but we can't easily infer an
    // overflow-only layer from the style.
    layer()->setLayerType(type);
    layer()->styleChanged(diff, oldStyle);
  }

  updateTransform(oldStyle);

  if (needsLayout() && oldStyle)
    RenderBlock::removePercentHeightDescendantIfNeeded(this);
}

void RenderBox::updateTransformationMatrix() {
  if (m_transform) {
    m_transform->makeIdentity();
    style()->applyTransform(*m_transform, pixelSnappedBorderBoxRect().size(),
                            RenderStyle::IncludeTransformOrigin);
    // FIXME(sky): We shouldn't need to do this once Skia has 4x4 matrix
    // support. Until then, 3d transforms don't work right.
    m_transform->makeAffine();
  }
}

void RenderBox::updateTransform(const RenderStyle* oldStyle) {
  if (oldStyle && style()->transformDataEquivalent(*oldStyle))
    return;

  // hasTransform() on the renderer is also true when there is transform-style:
  // preserve-3d or perspective set, so check style too.
  bool localHasTransform = hasTransform() && style()->hasTransform();
  bool had3DTransform = has3DTransform();

  bool hadTransform = m_transform;
  if (localHasTransform != hadTransform) {
    if (localHasTransform)
      m_transform = adoptPtr(new TransformationMatrix);
    else
      m_transform.clear();

    // Layers with transforms act as clip rects roots, so clear the cached clip
    // rects here.
    if (layer())
      layer()->clipper().clearClipRectsIncludingDescendants();
  }

  updateTransformationMatrix();

  if (layer() && had3DTransform != has3DTransform())
    layer()->dirty3DTransformedDescendantStatus();
}

// TODO(ojan): Inline this into styleDidChange,
void RenderBox::updateFromStyle() {
  RenderStyle* styleToUse = style();

  setHasBoxDecorationBackground(hasBackground() || styleToUse->hasBorder() ||
                                styleToUse->boxShadow());
  setInline(styleToUse->isDisplayInlineType());
  setPositionState(styleToUse->position());

  if (isRenderView()) {
    // TODO(ojan): Merge this into the same call above.
    setHasBoxDecorationBackground(true);
  } else if (isRenderBlock()) {
    // TODO(esprehn): Why do we not want to set this on the RenderView?
    setHasOverflowClip(!styleToUse->isOverflowVisible());
  }

  setHasTransform(styleToUse->hasTransformRelatedProperty());
}

void RenderBox::layout() {
  ASSERT(needsLayout());

  RenderObject* child = slowFirstChild();
  if (!child) {
    clearNeedsLayout();
    return;
  }

  while (child) {
    child->layoutIfNeeded();
    ASSERT(!child->needsLayout());
    child = child->nextSibling();
  }
  clearNeedsLayout();
}

// More IE extensions.  clientWidth and clientHeight represent the interior of
// an object excluding border and scrollbar.
LayoutUnit RenderBox::clientWidth() const {
  return width() - borderLeft() - borderRight();
}

LayoutUnit RenderBox::clientHeight() const {
  return height() - borderTop() - borderBottom();
}

int RenderBox::pixelSnappedClientWidth() const {
  return snapSizeToPixel(clientWidth(), x() + clientLeft());
}

int RenderBox::pixelSnappedClientHeight() const {
  return snapSizeToPixel(clientHeight(), y() + clientTop());
}

int RenderBox::pixelSnappedOffsetWidth() const {
  return snapSizeToPixel(offsetWidth(), x() + clientLeft());
}

int RenderBox::pixelSnappedOffsetHeight() const {
  return snapSizeToPixel(offsetHeight(), y() + clientTop());
}

void RenderBox::absoluteQuads(Vector<FloatQuad>& quads) const {
  quads.append(localToAbsoluteQuad(
      FloatRect(0, 0, width().toFloat(), height().toFloat()), 0 /* mode */));
}

void RenderBox::updateLayerTransformAfterLayout() {
  // Transform-origin depends on box size, so we need to update the transform
  // after layout.
  updateTransformationMatrix();
}

LayoutUnit RenderBox::constrainLogicalWidthByMinMax(LayoutUnit logicalWidth,
                                                    LayoutUnit availableWidth,
                                                    RenderBlock* cb) const {
  RenderStyle* styleToUse = style();
  if (!styleToUse->logicalMaxWidth().isMaxSizeNone())
    logicalWidth = std::min(
        logicalWidth,
        computeLogicalWidthUsing(MaxSize, styleToUse->logicalMaxWidth(),
                                 availableWidth, cb));
  return std::max(logicalWidth, computeLogicalWidthUsing(
                                    MinSize, styleToUse->logicalMinWidth(),
                                    availableWidth, cb));
}

LayoutUnit RenderBox::constrainLogicalHeightByMinMax(
    LayoutUnit logicalHeight,
    LayoutUnit intrinsicContentHeight) const {
  RenderStyle* styleToUse = style();
  if (!styleToUse->logicalMaxHeight().isMaxSizeNone()) {
    LayoutUnit maxH = computeLogicalHeightUsing(styleToUse->logicalMaxHeight(),
                                                intrinsicContentHeight);
    if (maxH != -1)
      logicalHeight = std::min(logicalHeight, maxH);
  }
  return std::max(logicalHeight,
                  computeLogicalHeightUsing(styleToUse->logicalMinHeight(),
                                            intrinsicContentHeight));
}

LayoutUnit RenderBox::constrainContentBoxLogicalHeightByMinMax(
    LayoutUnit logicalHeight,
    LayoutUnit intrinsicContentHeight) const {
  RenderStyle* styleToUse = style();
  if (!styleToUse->logicalMaxHeight().isMaxSizeNone()) {
    LayoutUnit maxH = computeContentLogicalHeight(
        styleToUse->logicalMaxHeight(), intrinsicContentHeight);
    if (maxH != -1)
      logicalHeight = std::min(logicalHeight, maxH);
  }
  return std::max(logicalHeight,
                  computeContentLogicalHeight(styleToUse->logicalMinHeight(),
                                              intrinsicContentHeight));
}

IntRect RenderBox::absoluteContentBox() const {
  // This is wrong with transforms and flipped writing modes.
  IntRect rect = pixelSnappedIntRect(contentBoxRect());
  FloatPoint absPos = localToAbsolute();
  rect.move(absPos.x(), absPos.y());
  return rect;
}

FloatQuad RenderBox::absoluteContentQuad() const {
  LayoutRect rect = contentBoxRect();
  return localToAbsoluteQuad(FloatRect(rect));
}

FloatPoint RenderBox::perspectiveOrigin() const {
  if (!hasTransform())
    return FloatPoint();

  const LayoutRect borderBox = borderBoxRect();
  return FloatPoint(floatValueForLength(style()->perspectiveOriginX(),
                                        borderBox.width().toFloat()),
                    floatValueForLength(style()->perspectiveOriginY(),
                                        borderBox.height().toFloat()));
}

void RenderBox::addFocusRingRects(Vector<IntRect>& rects,
                                  const LayoutPoint& additionalOffset,
                                  const RenderBox*) const {
  if (!size().isEmpty())
    rects.append(pixelSnappedIntRect(additionalOffset, size()));
}

bool RenderBox::needsPreferredWidthsRecalculation() const {
  return style()->paddingStart().isPercent() ||
         style()->paddingEnd().isPercent();
}

void RenderBox::computeIntrinsicLogicalWidths(
    LayoutUnit& minLogicalWidth,
    LayoutUnit& maxLogicalWidth) const {
  minLogicalWidth = minPreferredLogicalWidth() - borderAndPaddingLogicalWidth();
  maxLogicalWidth = maxPreferredLogicalWidth() - borderAndPaddingLogicalWidth();
}

LayoutUnit RenderBox::minPreferredLogicalWidth() const {
  if (preferredLogicalWidthsDirty()) {
#if ENABLE(ASSERT)
    SetLayoutNeededForbiddenScope layoutForbiddenScope(
        const_cast<RenderBox&>(*this));
#endif
    const_cast<RenderBox*>(this)->computePreferredLogicalWidths();
  }

  return m_minPreferredLogicalWidth;
}

LayoutUnit RenderBox::maxPreferredLogicalWidth() const {
  if (preferredLogicalWidthsDirty()) {
#if ENABLE(ASSERT)
    SetLayoutNeededForbiddenScope layoutForbiddenScope(
        const_cast<RenderBox&>(*this));
#endif
    const_cast<RenderBox*>(this)->computePreferredLogicalWidths();
  }

  return m_maxPreferredLogicalWidth;
}

void RenderBox::setMinPreferredLogicalWidth(LayoutUnit width) {
  m_minPreferredLogicalWidth = width;
}

void RenderBox::setMaxPreferredLogicalWidth(LayoutUnit width) {
  m_maxPreferredLogicalWidth = width;
}

bool RenderBox::hasOverrideHeight() const {
  return m_rareData && m_rareData->m_overrideLogicalContentHeight != -1;
}

bool RenderBox::hasOverrideWidth() const {
  return m_rareData && m_rareData->m_overrideLogicalContentWidth != -1;
}

void RenderBox::setOverrideLogicalContentHeight(LayoutUnit height) {
  ASSERT(height >= 0);
  ensureRareData().m_overrideLogicalContentHeight = height;
}

void RenderBox::setOverrideLogicalContentWidth(LayoutUnit width) {
  ASSERT(width >= 0);
  ensureRareData().m_overrideLogicalContentWidth = width;
}

void RenderBox::clearOverrideLogicalContentHeight() {
  if (m_rareData)
    m_rareData->m_overrideLogicalContentHeight = -1;
}

void RenderBox::clearOverrideLogicalContentWidth() {
  if (m_rareData)
    m_rareData->m_overrideLogicalContentWidth = -1;
}

void RenderBox::clearOverrideSize() {
  clearOverrideLogicalContentHeight();
  clearOverrideLogicalContentWidth();
}

LayoutUnit RenderBox::overrideLogicalContentWidth() const {
  ASSERT(hasOverrideWidth());
  return m_rareData->m_overrideLogicalContentWidth;
}

LayoutUnit RenderBox::overrideLogicalContentHeight() const {
  ASSERT(hasOverrideHeight());
  return m_rareData->m_overrideLogicalContentHeight;
}

LayoutUnit RenderBox::adjustBorderBoxLogicalWidthForBoxSizing(
    LayoutUnit width) const {
  LayoutUnit bordersPlusPadding = borderAndPaddingLogicalWidth();
  if (style()->boxSizing() == CONTENT_BOX)
    return width + bordersPlusPadding;
  return std::max(width, bordersPlusPadding);
}

LayoutUnit RenderBox::adjustBorderBoxLogicalHeightForBoxSizing(
    LayoutUnit height) const {
  LayoutUnit bordersPlusPadding = borderAndPaddingLogicalHeight();
  if (style()->boxSizing() == CONTENT_BOX)
    return height + bordersPlusPadding;
  return std::max(height, bordersPlusPadding);
}

LayoutUnit RenderBox::adjustContentBoxLogicalWidthForBoxSizing(
    LayoutUnit width) const {
  if (style()->boxSizing() == BORDER_BOX)
    width -= borderAndPaddingLogicalWidth();
  return std::max<LayoutUnit>(0, width);
}

LayoutUnit RenderBox::adjustContentBoxLogicalHeightForBoxSizing(
    LayoutUnit height) const {
  if (style()->boxSizing() == BORDER_BOX)
    height -= borderAndPaddingLogicalHeight();
  return std::max<LayoutUnit>(0, height);
}

bool RenderBox::nodeAtPoint(const HitTestRequest& request,
                            HitTestResult& result,
                            const HitTestLocation& locationInContainer,
                            const LayoutPoint& accumulatedOffset) {
  LayoutPoint adjustedLocation = accumulatedOffset + location();

  // Check kids first.
  for (RenderObject* child = slowLastChild(); child;
       child = child->previousSibling()) {
    if ((!child->hasLayer() ||
         !toRenderBox(child)->layer()->isSelfPaintingLayer()) &&
        child->nodeAtPoint(request, result, locationInContainer,
                           adjustedLocation)) {
      updateHitTestResult(
          result, locationInContainer.point() - toLayoutSize(adjustedLocation));
      return true;
    }
  }

  // Check our bounds next.
  LayoutRect boundsRect = borderBoxRect();
  boundsRect.moveBy(adjustedLocation);
  if (visibleToHitTestRequest(request) &&
      locationInContainer.intersects(boundsRect)) {
    updateHitTestResult(
        result, locationInContainer.point() - toLayoutSize(adjustedLocation));
    return true;
  }

  return false;
}

PassRefPtr<HitTestingTransformState> RenderBox::createLocalTransformState(
    RenderLayer* rootLayer,
    RenderLayer* containerLayer,
    const LayoutRect& hitTestRect,
    const HitTestLocation& hitTestLocation,
    const HitTestingTransformState* containerTransformState) const {
  RefPtr<HitTestingTransformState> transformState;
  LayoutPoint offset;
  if (containerTransformState) {
    // If we're already computing transform state, then it's relative to the
    // container (which we know is non-null).
    transformState = HitTestingTransformState::create(*containerTransformState);
    layer()->convertToLayerCoords(containerLayer, offset);
  } else {
    // If this is the first time we need to make transform state, then base it
    // off of hitTestLocation, which is relative to rootLayer.
    transformState = HitTestingTransformState::create(
        hitTestLocation.transformedPoint(), hitTestLocation.transformedRect(),
        FloatQuad(hitTestRect));
    layer()->convertToLayerCoords(rootLayer, offset);
  }

  RenderObject* containerRenderer =
      containerLayer ? containerLayer->renderer() : 0;
  if (shouldUseTransformFromContainer(containerRenderer)) {
    TransformationMatrix containerTransform;
    getTransformFromContainer(containerRenderer, toLayoutSize(offset),
                              containerTransform);
    transformState->applyTransform(
        containerTransform, HitTestingTransformState::AccumulateTransform);
  } else {
    transformState->translate(offset.x(), offset.y(),
                              HitTestingTransformState::AccumulateTransform);
  }

  return transformState;
}

// Compute the z-offset of the point in the transformState.
// This is effectively projecting a ray normal to the plane of ancestor, finding
// where that ray intersects target, and computing the z delta between those two
// points.
static double computeZOffset(const HitTestingTransformState& transformState) {
  // We got an affine transform, so no z-offset
  if (transformState.m_accumulatedTransform.isAffine())
    return 0;

  // Flatten the point into the target plane
  FloatPoint targetPoint = transformState.mappedPoint();

  // Now map the point back through the transform, which computes Z.
  FloatPoint3D backmappedPoint =
      transformState.m_accumulatedTransform.mapPoint(FloatPoint3D(targetPoint));
  return backmappedPoint.z();
}

static bool isHitCandidate(bool canDepthSort,
                           double* zOffset,
                           const HitTestingTransformState* transformState) {
  // The hit layer is depth-sorting with other layers, so just say that it was
  // hit.
  if (canDepthSort)
    return true;

  // We need to look at z-depth to decide if this layer was hit.
  if (zOffset) {
    ASSERT(transformState);
    // This is actually computing our z, but that's OK because the hitLayer is
    // coplanar with us.
    double childZOffset = computeZOffset(*transformState);
    if (childZOffset > *zOffset) {
      *zOffset = childZOffset;
      return true;
    }
    return false;
  }

  return true;
}

static inline bool forwardCompareZIndex(RenderBox* first, RenderBox* second) {
  return first->style()->zIndex() < second->style()->zIndex();
}

// hitTestLocation and hitTestRect are relative to rootLayer.
// A 'flattening' layer is one preserves3D() == false.
// transformState.m_accumulatedTransform holds the transform from the containing
// flattening layer. transformState.m_lastPlanarPoint is the hitTestLocation in
// the plane of the containing flattening layer. transformState.m_lastPlanarQuad
// is the hitTestRect as a quad in the plane of the containing flattening layer.
//
// If zOffset is non-null (which indicates that the caller wants z offset
// information),
//  *zOffset on return is the z offset of the hit point relative to the
//  containing flattening layer.
bool RenderBox::hitTestLayer(RenderLayer* rootLayer,
                             RenderLayer* containerLayer,
                             const HitTestRequest& request,
                             HitTestResult& result,
                             const LayoutRect& hitTestRect,
                             const HitTestLocation& hitTestLocation,
                             const HitTestingTransformState* transformState,
                             double* zOffset) {
  ASSERT(layer()->isSelfPaintingLayer());

  // The natural thing would be to keep HitTestingTransformState on the stack,
  // but it's big, so we heap-allocate.
  RefPtr<HitTestingTransformState> localTransformState;

  LayoutRect localHitTestRect = hitTestRect;
  HitTestLocation localHitTestLocation = hitTestLocation;

  // We need transform state for the first time, or to offset the container
  // state, or to accumulate the new transform.
  if (transform() || transformState || layer()->has3DTransformedDescendant() ||
      style()->preserves3D())
    localTransformState =
        createLocalTransformState(rootLayer, containerLayer, localHitTestRect,
                                  localHitTestLocation, transformState);

  // Apply a transform if we have one.
  if (transform()) {
    // The RenderView cannot have transforms.
    ASSERT(parent());
    // Make sure the parent's clip rects have been calculated.
    ClipRect clipRect = layer()->clipper().backgroundClipRect(
        ClipRectsContext(rootLayer, RootRelativeClipRects));
    // Go ahead and test the enclosing clip now.
    if (!clipRect.intersects(localHitTestLocation))
      return 0;

    // If the transform can't be inverted, then don't hit test this layer at
    // all.
    if (!localTransformState->m_accumulatedTransform.isInvertible())
      return 0;

    // Compute the point and the hit test rect in the coords of this layer by
    // using the values from the transformState, which store the point and quad
    // in the coords of the last flattened layer, and the accumulated transform
    // which lets up map through preserve-3d layers.
    //
    // We can't just map hitTestLocation and hitTestRect because they may have
    // been flattened (losing z) by our container.
    FloatPoint localPoint = localTransformState->mappedPoint();
    FloatQuad localPointQuad = localTransformState->mappedQuad();
    localHitTestRect = localTransformState->boundsOfMappedArea();
    if (localHitTestLocation.isRectBasedTest())
      localHitTestLocation = HitTestLocation(localPoint, localPointQuad);
    else
      localHitTestLocation = HitTestLocation(localPoint);

    // Now do a hit test with the root layer shifted to be us.
    rootLayer = layer();
  }

  // Ensure our lists and 3d status are up-to-date.
  layer()->stackingNode()->updateLayerListsIfNeeded();
  layer()->update3DTransformedDescendantStatus();

  RefPtr<HitTestingTransformState> unflattenedTransformState =
      localTransformState;
  if (localTransformState && !style()->preserves3D()) {
    // Keep a copy of the pre-flattening state, for computing z-offsets for the
    // container
    unflattenedTransformState =
        HitTestingTransformState::create(*localTransformState);
    // This layer is flattening, so flatten the state passed to descendants.
    localTransformState->flatten();
  }

  // The following are used for keeping track of the z-depth of the hit point of
  // 3d-transformed descendants.
  double localZOffset = -std::numeric_limits<double>::infinity();
  double* zOffsetForDescendantsPtr = 0;
  double* zOffsetForContentsPtr = 0;

  bool depthSortDescendants = false;
  if (style()->preserves3D()) {
    depthSortDescendants = true;
    // Our layers can depth-test with our container, so share the z depth
    // pointer with the container, if it passed one down.
    zOffsetForDescendantsPtr = zOffset ? zOffset : &localZOffset;
    zOffsetForContentsPtr = zOffset ? zOffset : &localZOffset;
  } else if (zOffset) {
    zOffsetForDescendantsPtr = 0;
    // Container needs us to give back a z offset for the hit layer.
    zOffsetForContentsPtr = zOffset;
  }

  Vector<RenderBox*> layers;
  collectSelfPaintingLayers(layers);
  // Hit testing needs to walk in the backwards direction from paint.
  // Forward compare and then reverse instead of just reverse comparing
  // so that elements with the same z-index are walked in reverse tree order.
  std::stable_sort(layers.begin(), layers.end(), forwardCompareZIndex);
  layers.reverse();

  bool hitLayer = false;
  for (auto& currentLayer : layers) {
    HitTestResult tempResult(result.hitTestLocation());
    bool localHitLayer = currentLayer->hitTestLayer(
        rootLayer, layer(), request, tempResult, localHitTestRect,
        localHitTestLocation, localTransformState.get(),
        zOffsetForDescendantsPtr);

    // If it a rect-based test, we can safely append the temporary result since
    // it might had hit nodes but not necesserily had hitLayer set.
    if (result.isRectBasedTest())
      result.append(tempResult);

    if (localHitLayer && isHitCandidate(depthSortDescendants, zOffset,
                                        unflattenedTransformState.get())) {
      hitLayer = localHitLayer;
      if (!result.isRectBasedTest())
        result = tempResult;
      if (!depthSortDescendants)
        return true;
    }
  }

  LayoutRect layerBounds;
  ClipRect contentRect;
  ClipRectsContext clipRectsContext(rootLayer, RootRelativeClipRects);
  layer()->clipper().calculateRects(clipRectsContext, localHitTestRect,
                                    layerBounds, contentRect);

  // Next we want to see if the mouse pos is inside the child RenderObjects of
  // the layer.
  if (contentRect.intersects(localHitTestLocation)) {
    // Hit test with a temporary HitTestResult, because we only want to commit
    // to 'result' if we know we're frontmost.
    HitTestResult tempResult(result.hitTestLocation());
    if (hitTestNonLayerDescendants(request, tempResult, layerBounds,
                                   localHitTestLocation) &&
        isHitCandidate(false, zOffsetForContentsPtr,
                       unflattenedTransformState.get())) {
      if (result.isRectBasedTest())
        result.append(tempResult);
      else
        result = tempResult;
      if (!depthSortDescendants)
        return true;
      // Foreground can depth-sort with descendant layers, so keep this as a
      // candidate.
      hitLayer = true;
    } else if (result.isRectBasedTest()) {
      result.append(tempResult);
    }
  }

  return hitLayer;
}

bool RenderBox::hitTestNonLayerDescendants(
    const HitTestRequest& request,
    HitTestResult& result,
    const LayoutRect& layerBounds,
    const HitTestLocation& hitTestLocation) {
  return hitTest(request, result, hitTestLocation,
                 toLayoutPoint(layerBounds.location() - location()));
}

// --------------------- painting stuff -------------------------------

void RenderBox::paintLayer(GraphicsContext* context,
                           const LayerPaintingInfo& paintingInfo) {
  // If this layer is totally invisible then there is nothing to paint.
  // TODO(ojan): Return false from isSelfPainting and then ASSERT(!opacity())
  // here.
  if (!opacity())
    return;

  if (!transform()) {
    paintLayerContents(context, paintingInfo);
    return;
  }

  // The RenderView can't be transformed in Sky.
  ASSERT(layer()->parent());

  // If the transform can't be inverted, then don't paint anything.
  if (!transform()->isInvertible())
    return;

  // Make sure the parent's clip rects have been calculated.
  ClipRectsContext clipRectsContext(paintingInfo.rootLayer, PaintingClipRects);
  ClipRect clipRect = layer()->clipper().backgroundClipRect(clipRectsContext);
  clipRect.intersect(paintingInfo.paintDirtyRect);

  // Push the parent coordinate space's clip.
  layer()->parent()->clipToRect(paintingInfo, context, clipRect);

  // This involves subtracting out the position of the layer in our current
  // coordinate space, but preserving the accumulated error for sub-pixel
  // layout.
  LayoutPoint delta;
  layer()->convertToLayerCoords(paintingInfo.rootLayer, delta);
  TransformationMatrix localTransform(*transform());
  IntPoint roundedDelta = roundedIntPoint(delta);
  localTransform.translateRight(roundedDelta.x(), roundedDelta.y());
  LayoutSize adjustedSubPixelAccumulation =
      paintingInfo.subPixelAccumulation + (delta - roundedDelta);

  // Apply the transform.
  GraphicsContextStateSaver stateSaver(*context, false);
  if (!localTransform.isIdentity()) {
    stateSaver.save();
    context->concatCTM(localTransform.toAffineTransform());
  }

  // Now do a paint with the root layer shifted to be us.
  LayerPaintingInfo transformedPaintingInfo(
      layer(),
      enclosingIntRect(
          localTransform.inverse().mapRect(paintingInfo.paintDirtyRect)),
      adjustedSubPixelAccumulation);
  paintLayerContents(context, transformedPaintingInfo);

  // Restore the clip.
  layer()->parent()->restoreClip(context, paintingInfo.paintDirtyRect,
                                 clipRect);
}

static LayoutRect transparencyClipBox(const RenderLayer*,
                                      const RenderLayer* rootLayer,
                                      const LayoutSize& subPixelAccumulation);

static void expandClipRectForDescendantsAndReflection(
    LayoutRect& clipRect,
    const RenderLayer* layer,
    const RenderLayer* rootLayer,
    const LayoutSize& subPixelAccumulation) {
  // Note: we don't have to walk z-order lists since transparent elements always
  // establish a stacking container. This means we can just walk the layer tree
  // directly.
  for (RenderLayer* curr = layer->firstChild(); curr;
       curr = curr->nextSibling())
    clipRect.unite(transparencyClipBox(curr, rootLayer, subPixelAccumulation));
}

static LayoutRect transparencyClipBox(const RenderLayer* layer,
                                      const RenderLayer* rootLayer,
                                      const LayoutSize& subPixelAccumulation) {
  // FIXME: Although this function completely ignores CSS-imposed clipping, we
  // did already intersect with the paintDirtyRect, and that should cut down on
  // the amount we have to paint.  Still it would be better to respect clips.

  if (rootLayer != layer && layer->renderer()->transform()) {
    // The best we can do here is to use enclosed bounding boxes to establish a
    // "fuzzy" enough clip to encompass the transformed layer and all of its
    // children.
    const RenderLayer* rootLayerForTransform = rootLayer;
    LayoutPoint delta;
    layer->convertToLayerCoords(rootLayerForTransform, delta);

    delta.move(subPixelAccumulation);
    IntPoint pixelSnappedDelta = roundedIntPoint(delta);
    TransformationMatrix transform;
    transform.translate(pixelSnappedDelta.x(), pixelSnappedDelta.y());
    transform = transform * *layer->renderer()->transform();

    // We don't use fragment boxes when collecting a transformed layer's
    // bounding box, since it always paints unfragmented.y
    LayoutRect clipRect = layer->physicalBoundingBox(layer);
    expandClipRectForDescendantsAndReflection(clipRect, layer, layer,
                                              subPixelAccumulation);
    LayoutRect result = transform.mapRect(clipRect);
    return result;
  }

  LayoutRect clipRect = layer->physicalBoundingBox(rootLayer);
  expandClipRectForDescendantsAndReflection(clipRect, layer, rootLayer,
                                            subPixelAccumulation);
  clipRect.move(subPixelAccumulation);
  return clipRect;
}

void RenderBox::paintLayerContents(GraphicsContext* context,
                                   const LayerPaintingInfo& paintingInfo) {
  float deviceScaleFactor = 1.0f;
  context->setDeviceScaleFactor(deviceScaleFactor);

  LayoutPoint offsetFromRoot;
  layer()->convertToLayerCoords(paintingInfo.rootLayer, offsetFromRoot);

  LayerPaintingInfo localPaintingInfo(paintingInfo);

  LayoutRect layerBounds;
  ClipRect contentRect;
  ClipRectsContext clipRectsContext(localPaintingInfo.rootLayer,
                                    PaintingClipRects,
                                    localPaintingInfo.subPixelAccumulation);
  layer()->clipper().calculateRects(clipRectsContext,
                                    localPaintingInfo.paintDirtyRect,
                                    layerBounds, contentRect, &offsetFromRoot);

  if (!layer()->intersectsDamageRect(layerBounds, contentRect.rect(),
                                     localPaintingInfo.rootLayer,
                                     &offsetFromRoot))
    return;

  LayoutRect rootRelativeBounds;

  // Apply clip-path to context.
  GraphicsContextStateSaver clipStateSaver(*context, false);

  // Clip-path, like border radius, must not be applied to the contents of a
  // composited-scrolling container. It must, however, still be applied to the
  // mask layer, so that the compositor can properly mask the scrolling contents
  // and scrollbars.
  if (hasClipPath()) {
    ASSERT(style()->clipPath());
    if (style()->clipPath()->type() == ClipPathOperation::SHAPE) {
      // Removed.
    }
  }

  if (isTransparent()) {
    context->save();
    LayoutRect clipRect = intersection(
        paintingInfo.paintDirtyRect,
        transparencyClipBox(layer(), localPaintingInfo.rootLayer,
                            localPaintingInfo.subPixelAccumulation));
    context->clip(clipRect);
    context->beginTransparencyLayer(opacity());
  }

  layer()->clipToRect(localPaintingInfo, context, contentRect);

  LayoutPoint layerLocation = toPoint(layerBounds.location() - location() +
                                      localPaintingInfo.subPixelAccumulation);

  Vector<RenderBox*> layers;
  PaintInfo paintInfo(context, pixelSnappedIntRect(contentRect.rect()),
                      localPaintingInfo.rootLayer->renderer());
  paint(paintInfo, layerLocation, layers);

  std::stable_sort(layers.begin(), layers.end(), forwardCompareZIndex);
  for (auto& box : layers) {
    box->paintLayer(context, paintingInfo);
  }

  layer()->restoreClip(context, localPaintingInfo.paintDirtyRect, contentRect);

  if (isTransparent()) {
    context->endLayer();
    context->restore();
  }
}

void RenderBox::paint(PaintInfo& paintInfo,
                      const LayoutPoint& paintOffset,
                      Vector<RenderBox*>& layers) {
  LayoutPoint adjustedPaintOffset = paintOffset + location();
  for (RenderObject* child = slowFirstChild(); child;
       child = child->nextSibling())
    child->paint(paintInfo, adjustedPaintOffset, layers);
}

BackgroundBleedAvoidance RenderBox::determineBackgroundBleedAvoidance(
    GraphicsContext* context,
    const BoxDecorationData& boxDecorationData) const {
  if (!boxDecorationData.hasBackground || !boxDecorationData.hasBorder ||
      !style()->hasBorderRadius())
    return BackgroundBleedNone;

  // FIXME: See crbug.com/382491. getCTM does not accurately reflect the scale
  // at the time content is rasterized, and should not be relied on to make
  // decisions about bleeding.
  AffineTransform ctm = context->getCTM();
  FloatSize contextScaling(static_cast<float>(ctm.xScale()),
                           static_cast<float>(ctm.yScale()));

  // Because RoundedRect uses IntRect internally the inset applied by the
  // BackgroundBleedShrinkBackground strategy cannot be less than one integer
  // layout coordinate, even with subpixel layout enabled. To take that into
  // account, we clamp the contextScaling to 1.0 for the following test so
  // that borderObscuresBackgroundEdge can only return true if the border
  // widths are greater than 2 in both layout coordinates and screen
  // coordinates.
  // This precaution will become obsolete if RoundedRect is ever promoted to
  // a sub-pixel representation.
  if (contextScaling.width() > 1)
    contextScaling.setWidth(1);
  if (contextScaling.height() > 1)
    contextScaling.setHeight(1);

  if (borderObscuresBackgroundEdge(contextScaling))
    return BackgroundBleedShrinkBackground;
  if (borderObscuresBackground() && backgroundHasOpaqueTopLayer())
    return BackgroundBleedBackgroundOverBorder;

  return BackgroundBleedClipBackground;
}

void RenderBox::paintBoxDecorationBackground(PaintInfo& paintInfo,
                                             const LayoutPoint& paintOffset) {
  LayoutRect paintRect = borderBoxRect();
  paintRect.moveBy(paintOffset);
  paintBoxDecorationBackgroundWithRect(paintInfo, paintOffset, paintRect);
}

void RenderBox::paintBoxDecorationBackgroundWithRect(
    PaintInfo& paintInfo,
    const LayoutPoint& paintOffset,
    const LayoutRect& paintRect) {
  RenderStyle* style = this->style();
  BoxDecorationData boxDecorationData(*style);
  BackgroundBleedAvoidance bleedAvoidance =
      determineBackgroundBleedAvoidance(paintInfo.context, boxDecorationData);

  // FIXME: Should eventually give the theme control over whether the box shadow
  // should paint, since controls could have custom shadows of their own.
  if (!boxShadowShouldBeAppliedToBackground(bleedAvoidance))
    paintBoxShadow(paintInfo, paintRect, style, Normal);

  GraphicsContextStateSaver stateSaver(*paintInfo.context, false);
  if (bleedAvoidance == BackgroundBleedClipBackground) {
    stateSaver.save();
    RoundedRect border = style->getRoundedBorderFor(paintRect);
    paintInfo.context->clipRoundedRect(border);
  }

  if (bleedAvoidance == BackgroundBleedBackgroundOverBorder)
    paintBorder(paintInfo, paintRect, style, bleedAvoidance);

  paintBackground(paintInfo, paintRect, boxDecorationData.backgroundColor,
                  bleedAvoidance);
  paintBoxShadow(paintInfo, paintRect, style, Inset);

  // The theme will tell us whether or not we should also paint the CSS border.
  if (boxDecorationData.hasBorder &&
      bleedAvoidance != BackgroundBleedBackgroundOverBorder)
    paintBorder(paintInfo, paintRect, style, bleedAvoidance);
}

void RenderBox::paintBackground(const PaintInfo& paintInfo,
                                const LayoutRect& paintRect,
                                const Color& backgroundColor,
                                BackgroundBleedAvoidance bleedAvoidance) {
  paintFillLayers(paintInfo, backgroundColor, style()->backgroundLayers(),
                  paintRect, bleedAvoidance);
}

bool RenderBox::backgroundHasOpaqueTopLayer() const {
  const FillLayer& fillLayer = style()->backgroundLayers();
  if (fillLayer.clip() != BorderFillBox)
    return false;

  if (fillLayer.hasOpaqueImage(this) && fillLayer.hasRepeatXY() &&
      fillLayer.image()->canRender(*this))
    return true;

  // If there is only one layer and no image, check whether the background color
  // is opaque
  if (!fillLayer.next() && !fillLayer.hasImage()) {
    Color bgColor = style()->resolveColor(style()->backgroundColor());
    if (bgColor.alpha() == 255)
      return true;
  }

  return false;
}

void RenderBox::paintFillLayers(const PaintInfo& paintInfo,
                                const Color& c,
                                const FillLayer& fillLayer,
                                const LayoutRect& rect,
                                BackgroundBleedAvoidance bleedAvoidance,
                                RenderObject* backgroundObject) {
  Vector<const FillLayer*, 8> layers;
  const FillLayer* curLayer = &fillLayer;
  bool shouldDrawBackgroundInSeparateBuffer = false;
  while (curLayer) {
    layers.append(curLayer);
    // Stop traversal when an opaque layer is encountered.
    // FIXME : It would be possible for the following occlusion culling test to
    // be more aggressive on layers with no repeat by testing whether the image
    // covers the layout rect. Testing that here would imply duplicating a lot
    // of calculations that are currently done in
    // RenderBoxModelObject::paintFillLayerExtended. A more efficient solution
    // might be to move the layer recursion into paintFillLayerExtended, or to
    // compute the layer geometry here and pass it down.

    if (!shouldDrawBackgroundInSeparateBuffer &&
        curLayer->blendMode() != WebBlendModeNormal)
      shouldDrawBackgroundInSeparateBuffer = true;

    // The clipOccludesNextLayers condition must be evaluated first to avoid
    // short-circuiting.
    if (curLayer->clipOccludesNextLayers(curLayer == &fillLayer) &&
        curLayer->hasOpaqueImage(this) && curLayer->image()->canRender(*this) &&
        curLayer->hasRepeatXY() &&
        curLayer->blendMode() == WebBlendModeNormal &&
        !boxShadowShouldBeAppliedToBackground(bleedAvoidance))
      break;
    curLayer = curLayer->next();
  }

  GraphicsContext* context = paintInfo.context;
  if (!context)
    shouldDrawBackgroundInSeparateBuffer = false;

  // FIXME(sky): Propagate this constant.
  bool skipBaseColor = false;
  if (shouldDrawBackgroundInSeparateBuffer)
    context->beginTransparencyLayer(1);

  Vector<const FillLayer*>::const_reverse_iterator topLayer = layers.rend();
  for (Vector<const FillLayer*>::const_reverse_iterator it = layers.rbegin();
       it != topLayer; ++it)
    paintFillLayer(paintInfo, c, **it, rect, bleedAvoidance, backgroundObject,
                   skipBaseColor);

  if (shouldDrawBackgroundInSeparateBuffer)
    context->endLayer();
}

void RenderBox::paintFillLayer(const PaintInfo& paintInfo,
                               const Color& c,
                               const FillLayer& fillLayer,
                               const LayoutRect& rect,
                               BackgroundBleedAvoidance bleedAvoidance,
                               RenderObject* backgroundObject,
                               bool skipBaseColor) {
  paintFillLayerExtended(paintInfo, c, fillLayer, rect, bleedAvoidance, 0,
                         LayoutSize(), backgroundObject, skipBaseColor);
}

bool RenderBox::pushContentsClip(PaintInfo& paintInfo,
                                 const LayoutPoint& accumulatedOffset,
                                 ContentsClipBehavior contentsClipBehavior) {
  bool isOverflowClip = hasOverflowClip() && !layer()->isSelfPaintingLayer();
  if (!isOverflowClip)
    return false;

  LayoutRect clipRect = overflowClipRect(accumulatedOffset);
  RoundedRect clipRoundedRect(0, 0, 0, 0);
  bool hasBorderRadius = style()->hasBorderRadius();
  if (hasBorderRadius)
    clipRoundedRect = style()->getRoundedInnerBorderFor(
        LayoutRect(accumulatedOffset, size()));

  if (contentsClipBehavior == SkipContentsClipIfPossible) {
    LayoutRect contentsVisualOverflow = contentsVisualOverflowRect();
    if (contentsVisualOverflow.isEmpty())
      return false;

    LayoutRect conservativeClipRect = clipRect;
    if (hasBorderRadius)
      conservativeClipRect.intersect(clipRoundedRect.radiusCenterRect());
    conservativeClipRect.moveBy(-accumulatedOffset);
    if (conservativeClipRect.contains(contentsVisualOverflow))
      return false;
  }

  paintInfo.context->save();
  if (hasBorderRadius)
    paintInfo.context->clipRoundedRect(clipRoundedRect);
  paintInfo.context->clip(pixelSnappedIntRect(clipRect));
  return true;
}

void RenderBox::popContentsClip(PaintInfo& paintInfo,
                                const LayoutPoint& accumulatedOffset) {
  ASSERT(hasOverflowClip() && !layer()->isSelfPaintingLayer());
  paintInfo.context->restore();
}

LayoutRect RenderBox::overflowClipRect(const LayoutPoint& location) {
  LayoutRect clipRect = borderBoxRect();
  clipRect.setLocation(location + clipRect.location() +
                       LayoutSize(borderLeft(), borderTop()));
  clipRect.setSize(clipRect.size() - LayoutSize(borderLeft() + borderRight(),
                                                borderTop() + borderBottom()));
  return clipRect;
}

LayoutRect RenderBox::clipRect(const LayoutPoint& location) {
  LayoutRect borderBoxRect = this->borderBoxRect();
  LayoutRect clipRect =
      LayoutRect(borderBoxRect.location() + location, borderBoxRect.size());

  if (!style()->clipLeft().isAuto()) {
    LayoutUnit c = valueForLength(style()->clipLeft(), borderBoxRect.width());
    clipRect.move(c, 0);
    clipRect.contract(c, 0);
  }

  if (!style()->clipRight().isAuto())
    clipRect.contract(width() - valueForLength(style()->clipRight(), width()),
                      0);

  if (!style()->clipTop().isAuto()) {
    LayoutUnit c = valueForLength(style()->clipTop(), borderBoxRect.height());
    clipRect.move(0, c);
    clipRect.contract(0, c);
  }

  if (!style()->clipBottom().isAuto())
    clipRect.contract(
        0, height() - valueForLength(style()->clipBottom(), height()));

  return clipRect;
}

LayoutUnit RenderBox::containingBlockLogicalHeightForContent(
    AvailableLogicalHeightType heightType) const {
  return containingBlock()->availableLogicalHeight(heightType);
}

void RenderBox::mapLocalToContainer(const RenderBox* paintInvalidationContainer,
                                    TransformState& transformState,
                                    MapCoordinatesFlags mode) const {
  if (paintInvalidationContainer == this)
    return;

  bool containerSkipped;
  RenderObject* o = container(paintInvalidationContainer, &containerSkipped);
  if (!o)
    return;

  LayoutSize containerOffset =
      offsetFromContainer(o, roundedLayoutPoint(transformState.mappedPoint()));

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

  if (containerSkipped) {
    // There can't be a transform between paintInvalidationContainer and o,
    // because transforms create containers, so it should be safe to just
    // subtract the delta between the paintInvalidationContainer and o.
    LayoutSize containerOffset =
        paintInvalidationContainer->offsetFromAncestorContainer(o);
    transformState.move(-containerOffset.width(), -containerOffset.height(),
                        preserve3D ? TransformState::AccumulateTransform
                                   : TransformState::FlattenTransform);
    return;
  }

  mode &= ~ApplyContainerFlip;

  o->mapLocalToContainer(paintInvalidationContainer, transformState, mode);
}

LayoutSize RenderBox::offsetFromContainer(const RenderObject* o,
                                          const LayoutPoint& point,
                                          bool* offsetDependsOnPoint) const {
  ASSERT(o == container());
  if (!isInline() || isReplaced())
    return locationOffset();
  return LayoutSize();
}

InlineBox* RenderBox::createInlineBox() {
  return new InlineBox(*this);
}

void RenderBox::dirtyLineBoxes(bool fullLayout) {
  if (inlineBoxWrapper()) {
    if (fullLayout) {
      inlineBoxWrapper()->destroy();
      ASSERT(m_rareData);
      m_rareData->m_inlineBoxWrapper = 0;
    } else {
      inlineBoxWrapper()->dirtyLineBoxes();
    }
  }
}

void RenderBox::positionLineBox(InlineBox* box) {
  if (isOutOfFlowPositioned()) {
    box->remove(DontMarkLineBoxes);
    box->destroy();
  } else if (isReplaced()) {
    setLocation(roundedLayoutPoint(box->topLeft()));
    setInlineBoxWrapper(box);
  }
}

void RenderBox::deleteLineBoxWrapper() {
  if (inlineBoxWrapper()) {
    if (!documentBeingDestroyed())
      inlineBoxWrapper()->remove();
    inlineBoxWrapper()->destroy();
    ASSERT(m_rareData);
    m_rareData->m_inlineBoxWrapper = 0;
  }
}

void RenderBox::updateLogicalWidth() {
  LogicalExtentComputedValues computedValues;
  computeLogicalWidth(computedValues);

  setLogicalWidth(computedValues.m_extent);
  setLogicalLeft(computedValues.m_position);
  setMarginStart(computedValues.m_margins.m_start);
  setMarginEnd(computedValues.m_margins.m_end);
}

void RenderBox::computeLogicalWidth(
    LogicalExtentComputedValues& computedValues) const {
  computedValues.m_extent = logicalWidth();
  computedValues.m_position = logicalLeft();
  computedValues.m_margins.m_start = marginStart();
  computedValues.m_margins.m_end = marginEnd();

  if (isOutOfFlowPositioned()) {
    // FIXME: This calculation is not patched for block-flow yet.
    // https://bugs.webkit.org/show_bug.cgi?id=46500
    computePositionedLogicalWidth(computedValues);
    return;
  }

  if (hasOverrideWidth()) {
    computedValues.m_extent =
        overrideLogicalContentWidth() + borderAndPaddingLogicalWidth();
    return;
  }

  bool treatAsReplaced = shouldComputeSizeAsReplaced();

  RenderStyle* styleToUse = style();
  Length logicalWidthLength = treatAsReplaced
                                  ? Length(computeReplacedLogicalWidth(), Fixed)
                                  : styleToUse->logicalWidth();

  RenderBlock* cb = containingBlock();
  LayoutUnit containerLogicalWidth =
      std::max<LayoutUnit>(0, containingBlockLogicalWidthForContent());

  if (isInline() && !isInlineBlock()) {
    // just calculate margins
    computedValues.m_margins.m_start =
        minimumValueForLength(styleToUse->marginStart(), containerLogicalWidth);
    computedValues.m_margins.m_end =
        minimumValueForLength(styleToUse->marginEnd(), containerLogicalWidth);
    if (treatAsReplaced)
      computedValues.m_extent =
          std::max<LayoutUnit>(floatValueForLength(logicalWidthLength, 0) +
                                   borderAndPaddingLogicalWidth(),
                               minPreferredLogicalWidth());
    return;
  }

  // Width calculations
  if (treatAsReplaced)
    computedValues.m_extent =
        logicalWidthLength.value() + borderAndPaddingLogicalWidth();
  else {
    LayoutUnit preferredWidth = computeLogicalWidthUsing(
        MainOrPreferredSize, styleToUse->logicalWidth(), containerLogicalWidth,
        cb);
    computedValues.m_extent = constrainLogicalWidthByMinMax(
        preferredWidth, containerLogicalWidth, cb);
  }

  // Margin calculations.
  computeMarginsForDirection(
      InlineDirection, cb, containerLogicalWidth, computedValues.m_extent,
      computedValues.m_margins.m_start, computedValues.m_margins.m_end,
      style()->marginStart(), style()->marginEnd());

  if (containerLogicalWidth &&
      containerLogicalWidth !=
          (computedValues.m_extent + computedValues.m_margins.m_start +
           computedValues.m_margins.m_end) &&
      !isInline() && !cb->isFlexibleBox()) {
    LayoutUnit newMargin = containerLogicalWidth - computedValues.m_extent -
                           cb->marginStartForChild(this);
    bool hasInvertedDirection = cb->style()->isLeftToRightDirection() !=
                                style()->isLeftToRightDirection();
    if (hasInvertedDirection)
      computedValues.m_margins.m_start = newMargin;
    else
      computedValues.m_margins.m_end = newMargin;
  }
}

LayoutUnit RenderBox::fillAvailableMeasure(
    LayoutUnit availableLogicalWidth) const {
  LayoutUnit marginStart =
      minimumValueForLength(style()->marginStart(), availableLogicalWidth);
  LayoutUnit marginEnd =
      minimumValueForLength(style()->marginEnd(), availableLogicalWidth);
  return availableLogicalWidth - marginStart - marginEnd;
}

LayoutUnit RenderBox::computeIntrinsicLogicalWidthUsing(
    const Length& logicalWidthLength,
    LayoutUnit availableLogicalWidth,
    LayoutUnit borderAndPadding) const {
  if (logicalWidthLength.type() == FillAvailable)
    return fillAvailableMeasure(availableLogicalWidth);

  LayoutUnit minLogicalWidth = 0;
  LayoutUnit maxLogicalWidth = 0;
  computeIntrinsicLogicalWidths(minLogicalWidth, maxLogicalWidth);

  if (logicalWidthLength.type() == MinContent)
    return minLogicalWidth + borderAndPadding;

  if (logicalWidthLength.type() == MaxContent)
    return maxLogicalWidth + borderAndPadding;

  if (logicalWidthLength.type() == FitContent) {
    minLogicalWidth += borderAndPadding;
    maxLogicalWidth += borderAndPadding;
    return std::max(
        minLogicalWidth,
        std::min(maxLogicalWidth, fillAvailableMeasure(availableLogicalWidth)));
  }

  ASSERT_NOT_REACHED();
  return 0;
}

LayoutUnit RenderBox::computeLogicalWidthUsing(SizeType widthType,
                                               const Length& logicalWidth,
                                               LayoutUnit availableLogicalWidth,
                                               const RenderBlock* cb) const {
  if (!logicalWidth.isIntrinsicOrAuto()) {
    // FIXME: If the containing block flow is perpendicular to our direction we
    // need to use the available logical height instead.
    return adjustBorderBoxLogicalWidthForBoxSizing(
        valueForLength(logicalWidth, availableLogicalWidth));
  }

  if (logicalWidth.isIntrinsic())
    return computeIntrinsicLogicalWidthUsing(
        logicalWidth, availableLogicalWidth, borderAndPaddingLogicalWidth());

  LayoutUnit logicalWidthResult = fillAvailableMeasure(availableLogicalWidth);

  if (widthType == MainOrPreferredSize &&
      sizesLogicalWidthToFitContent(logicalWidth))
    return std::max(minPreferredLogicalWidth(),
                    std::min(maxPreferredLogicalWidth(), logicalWidthResult));
  return logicalWidthResult;
}

static bool columnFlexItemHasStretchAlignment(const RenderObject* flexitem) {
  RenderObject* parent = flexitem->parent();
  // auto margins mean we don't stretch. Note that this function will only be
  // used for widths, so we don't have to check marginBefore/marginAfter.
  ASSERT(parent->style()->isColumnFlexDirection());
  if (flexitem->style()->marginStart().isAuto() ||
      flexitem->style()->marginEnd().isAuto())
    return false;
  return flexitem->style()->alignSelf() == ItemPositionStretch ||
         (flexitem->style()->alignSelf() == ItemPositionAuto &&
          parent->style()->alignItems() == ItemPositionStretch);
}

bool RenderBox::sizesLogicalWidthToFitContent(
    const Length& logicalWidth) const {
  if (isInlineBlock())
    return true;

  if (logicalWidth.type() == Intrinsic)
    return true;

  // Flexible box items should shrink wrap, so we lay them out at their
  // intrinsic widths. In the case of columns that have a stretch alignment, we
  // go ahead and layout at the stretched size to avoid an extra layout when
  // applying alignment.
  if (parent()->isFlexibleBox()) {
    // For multiline columns, we need to apply align-content first, so we can't
    // stretch now.
    if (!parent()->style()->isColumnFlexDirection() ||
        parent()->style()->flexWrap() != FlexNoWrap)
      return true;
    if (!columnFlexItemHasStretchAlignment(this))
      return true;
  }

  return false;
}

void RenderBox::computeMarginsForDirection(MarginDirection flowDirection,
                                           const RenderBlock* containingBlock,
                                           LayoutUnit containerWidth,
                                           LayoutUnit childWidth,
                                           LayoutUnit& marginStart,
                                           LayoutUnit& marginEnd,
                                           Length marginStartLength,
                                           Length marginEndLength) const {
  if (flowDirection == BlockDirection || isInline()) {
    // Margins are calculated with respect to the logical width of
    // the containing block (8.3)
    // Inline blocks/tables and floats don't have their margins increased.
    marginStart = minimumValueForLength(marginStartLength, containerWidth);
    marginEnd = minimumValueForLength(marginEndLength, containerWidth);
    return;
  }

  if (containingBlock->isFlexibleBox()) {
    // We need to let flexbox handle the margin adjustment - otherwise, flexbox
    // will think we're wider than we actually are and calculate line sizes
    // wrong. See also http://dev.w3.org/csswg/css-flexbox/#auto-margins
    if (marginStartLength.isAuto())
      marginStartLength.setValue(0);
    if (marginEndLength.isAuto())
      marginEndLength.setValue(0);
  }

  LayoutUnit marginStartWidth =
      minimumValueForLength(marginStartLength, containerWidth);
  LayoutUnit marginEndWidth =
      minimumValueForLength(marginEndLength, containerWidth);

  // CSS 2.1 (10.3.3): "If 'width' is not 'auto' and 'border-left-width' +
  // 'padding-left' + 'width' + 'padding-right' + 'border-right-width' (plus any
  // of 'margin-left' or 'margin-right' that are not 'auto') is larger than the
  // width of the containing block, then any 'auto' values for 'margin-left' or
  // 'margin-right' are, for the following rules, treated as zero.
  LayoutUnit marginBoxWidth =
      childWidth + (!style()->width().isAuto()
                        ? marginStartWidth + marginEndWidth
                        : LayoutUnit());

  // CSS 2.1: "If both 'margin-left' and 'margin-right' are 'auto', their used
  // values are equal. This horizontally centers the element with respect to the
  // edges of the containing block."
  if (marginStartLength.isAuto() && marginEndLength.isAuto() &&
      marginBoxWidth < containerWidth) {
    // Other browsers center the margin box for align=center elements so we
    // match them here.
    LayoutUnit centeredMarginBoxStart = std::max<LayoutUnit>(
        0,
        (containerWidth - childWidth - marginStartWidth - marginEndWidth) / 2);
    marginStart = centeredMarginBoxStart + marginStartWidth;
    marginEnd = containerWidth - childWidth - marginStart + marginEndWidth;
    return;
  }

  // CSS 2.1: "If there is exactly one value specified as 'auto', its used value
  // follows from the equality."
  if (marginEndLength.isAuto() && marginBoxWidth < containerWidth) {
    marginStart = marginStartWidth;
    marginEnd = containerWidth - childWidth - marginStart;
    return;
  }

  if (marginStartLength.isAuto() && marginBoxWidth < containerWidth) {
    marginEnd = marginEndWidth;
    marginStart = containerWidth - childWidth - marginEnd;
    return;
  }

  // Either no auto margins, or our margin box width is >= the container width,
  // auto margins will just turn into 0.
  marginStart = marginStartWidth;
  marginEnd = marginEndWidth;
}

void RenderBox::updateLogicalHeight() {
  m_intrinsicContentLogicalHeight = contentLogicalHeight();

  LogicalExtentComputedValues computedValues;
  computeLogicalHeight(logicalHeight(), logicalTop(), computedValues);

  setLogicalHeight(computedValues.m_extent);
  setLogicalTop(computedValues.m_position);
  setMarginBefore(computedValues.m_margins.m_before);
  setMarginAfter(computedValues.m_margins.m_after);
}

void RenderBox::computeLogicalHeight(
    LayoutUnit logicalHeight,
    LayoutUnit logicalTop,
    LogicalExtentComputedValues& computedValues) const {
  computedValues.m_extent = logicalHeight;
  computedValues.m_position = logicalTop;

  // Cell height is managed by the table and inline non-replaced elements do not
  // support a height property.
  if (isInline() && !isReplaced())
    return;

  Length h;
  if (isOutOfFlowPositioned())
    computePositionedLogicalHeight(computedValues);
  else {
    RenderBlock* cb = containingBlock();

    // If we are perpendicular to our containing block then we need to resolve
    // our block-start and block-end margins so that if they are 'auto' we are
    // centred or aligned within the inline flow containing block: this is done
    // by computing the margins as though they are inline. Note that as this is
    // the 'sizing phase' we are using our own writing mode rather than the
    // containing block's. We use the containing block's writing mode when
    // figuring out the block-direction margins for positioning in
    // |computeAndSetBlockDirectionMargins| (i.e. margin collapsing etc.). See
    // http://www.w3.org/TR/2014/CR-css-writing-modes-3-20140320/#orthogonal-flows
    // FIXME(sky): Remove MarginDirection enum.
    MarginDirection flowDirection = BlockDirection;

    bool treatAsReplaced = shouldComputeSizeAsReplaced();
    bool checkMinMaxHeight = false;

    // The parent box is flexing us, so it has increased or decreased our
    // height.  We have to grab our cached flexible height.
    // FIXME: Account for block-flow in flexible boxes.
    // https://bugs.webkit.org/show_bug.cgi?id=46418
    if (hasOverrideHeight() && parent()->isFlexibleBox())
      h = Length(overrideLogicalContentHeight(), Fixed);
    else if (treatAsReplaced)
      h = Length(computeReplacedLogicalHeight(), Fixed);
    else {
      h = style()->logicalHeight();
      checkMinMaxHeight = true;
    }

    LayoutUnit heightResult;
    if (checkMinMaxHeight) {
      heightResult = computeLogicalHeightUsing(
          style()->logicalHeight(),
          computedValues.m_extent - borderAndPaddingLogicalHeight());
      if (heightResult == -1)
        heightResult = computedValues.m_extent;
      heightResult = constrainLogicalHeightByMinMax(
          heightResult,
          computedValues.m_extent - borderAndPaddingLogicalHeight());
    } else {
      // The only times we don't check min/max height are when a fixed length
      // has been given as an override.  Just use that.  The value has already
      // been adjusted for box-sizing.
      ASSERT(h.isFixed());
      heightResult = h.value() + borderAndPaddingLogicalHeight();
    }

    computedValues.m_extent = heightResult;
    computeMarginsForDirection(
        flowDirection, cb, containingBlockLogicalWidthForContent(),
        computedValues.m_extent, computedValues.m_margins.m_before,
        computedValues.m_margins.m_after, style()->marginBefore(),
        style()->marginAfter());
  }
}

LayoutUnit RenderBox::computeLogicalHeightUsing(
    const Length& height,
    LayoutUnit intrinsicContentHeight) const {
  LayoutUnit logicalHeight =
      computeContentLogicalHeightUsing(height, intrinsicContentHeight);
  if (logicalHeight != -1)
    logicalHeight = adjustBorderBoxLogicalHeightForBoxSizing(logicalHeight);
  return logicalHeight;
}

LayoutUnit RenderBox::computeContentLogicalHeight(
    const Length& height,
    LayoutUnit intrinsicContentHeight) const {
  LayoutUnit heightIncludingScrollbar =
      computeContentLogicalHeightUsing(height, intrinsicContentHeight);
  if (heightIncludingScrollbar == -1)
    return -1;
  return std::max<LayoutUnit>(
      0, adjustContentBoxLogicalHeightForBoxSizing(heightIncludingScrollbar));
}

LayoutUnit RenderBox::computeIntrinsicLogicalContentHeightUsing(
    const Length& logicalHeightLength,
    LayoutUnit intrinsicContentHeight,
    LayoutUnit borderAndPadding) const {
  // FIXME(cbiesinger): The css-sizing spec is considering changing what
  // min-content/max-content should resolve to. If that happens, this code will
  // have to change.
  if (logicalHeightLength.isMinContent() ||
      logicalHeightLength.isMaxContent() ||
      logicalHeightLength.isFitContent()) {
    if (isReplaced())
      return intrinsicSize().height();
    if (m_intrinsicContentLogicalHeight != -1)
      return m_intrinsicContentLogicalHeight;
    return intrinsicContentHeight;
  }
  if (logicalHeightLength.isFillAvailable())
    return containingBlock()->availableLogicalHeight(
               ExcludeMarginBorderPadding) -
           borderAndPadding;
  ASSERT_NOT_REACHED();
  return 0;
}

LayoutUnit RenderBox::computeContentLogicalHeightUsing(
    const Length& height,
    LayoutUnit intrinsicContentHeight) const {
  // FIXME(cbiesinger): The css-sizing spec is considering changing what
  // min-content/max-content should resolve to. If that happens, this code will
  // have to change.
  if (height.isIntrinsic()) {
    if (intrinsicContentHeight == -1)
      return -1;  // Intrinsic height isn't available.
    return computeIntrinsicLogicalContentHeightUsing(
        height, intrinsicContentHeight, borderAndPaddingLogicalHeight());
  }
  if (height.isFixed())
    return height.value();
  return -1;
}

// FIXME(sky): Remove
bool RenderBox::skipContainingBlockForPercentHeightCalculation(
    const RenderBox* containingBlock) const {
  return false;
}

LayoutUnit RenderBox::computeReplacedLogicalWidth(
    ShouldComputePreferred shouldComputePreferred) const {
  return computeReplacedLogicalWidthRespectingMinMaxWidth(
      computeReplacedLogicalWidthUsing(style()->logicalWidth()),
      shouldComputePreferred);
}

LayoutUnit RenderBox::computeReplacedLogicalWidthRespectingMinMaxWidth(
    LayoutUnit logicalWidth,
    ShouldComputePreferred shouldComputePreferred) const {
  LayoutUnit minLogicalWidth =
      (shouldComputePreferred == ComputePreferred &&
       style()->logicalMinWidth().isPercent()) ||
              style()->logicalMinWidth().isMaxSizeNone()
          ? logicalWidth
          : computeReplacedLogicalWidthUsing(style()->logicalMinWidth());
  LayoutUnit maxLogicalWidth =
      (shouldComputePreferred == ComputePreferred &&
       style()->logicalMaxWidth().isPercent()) ||
              style()->logicalMaxWidth().isMaxSizeNone()
          ? logicalWidth
          : computeReplacedLogicalWidthUsing(style()->logicalMaxWidth());
  return std::max(minLogicalWidth, std::min(logicalWidth, maxLogicalWidth));
}

LayoutUnit RenderBox::computeReplacedLogicalWidthUsing(
    const Length& logicalWidth) const {
  switch (logicalWidth.type()) {
    case Fixed:
      return adjustContentBoxLogicalWidthForBoxSizing(logicalWidth.value());
    case MinContent:
    case MaxContent: {
      // MinContent/MaxContent don't need the availableLogicalWidth argument.
      LayoutUnit availableLogicalWidth = 0;
      return computeIntrinsicLogicalWidthUsing(logicalWidth,
                                               availableLogicalWidth,
                                               borderAndPaddingLogicalWidth()) -
             borderAndPaddingLogicalWidth();
    }
    case FitContent:
    case FillAvailable:
    case Percent:
    case Calculated: {
      // FIXME: containingBlockLogicalWidthForContent() is wrong if the replaced
      // element's block-flow is perpendicular to the containing block's
      // block-flow. https://bugs.webkit.org/show_bug.cgi?id=46496
      const LayoutUnit cw = isOutOfFlowPositioned()
                                ? containingBlockLogicalWidthForPositioned(
                                      toRenderBoxModelObject(container()))
                                : containingBlockLogicalWidthForContent();
      Length containerLogicalWidth = containingBlock()->style()->logicalWidth();
      // FIXME: Handle cases when containing block width is calculated or
      // viewport percent. https://bugs.webkit.org/show_bug.cgi?id=91071
      if (logicalWidth.isIntrinsic())
        return computeIntrinsicLogicalWidthUsing(
                   logicalWidth, cw, borderAndPaddingLogicalWidth()) -
               borderAndPaddingLogicalWidth();
      if (cw > 0 || (!cw && (containerLogicalWidth.isFixed() ||
                             containerLogicalWidth.isPercent())))
        return adjustContentBoxLogicalWidthForBoxSizing(
            minimumValueForLength(logicalWidth, cw));
      return 0;
    }
    case Intrinsic:
    case MinIntrinsic:
    case Auto:
    case MaxSizeNone:
      return intrinsicLogicalWidth();
    case DeviceWidth:
    case DeviceHeight:
      break;
  }

  ASSERT_NOT_REACHED();
  return 0;
}

LayoutUnit RenderBox::computeReplacedLogicalHeight() const {
  return computeReplacedLogicalHeightRespectingMinMaxHeight(
      computeReplacedLogicalHeightUsing(style()->logicalHeight()));
}

bool RenderBox::logicalHeightComputesAsNone(SizeType sizeType) const {
  ASSERT(sizeType == MinSize || sizeType == MaxSize);
  Length logicalHeight = sizeType == MinSize ? style()->logicalMinHeight()
                                             : style()->logicalMaxHeight();
  Length initialLogicalHeight = sizeType == MinSize
                                    ? RenderStyle::initialMinSize()
                                    : RenderStyle::initialMaxSize();

  if (logicalHeight == initialLogicalHeight)
    return true;

  if (!logicalHeight.isPercent() || isOutOfFlowPositioned())
    return false;

  return containingBlock()->hasAutoHeightOrContainingBlockWithAutoHeight();
}

LayoutUnit RenderBox::computeReplacedLogicalHeightRespectingMinMaxHeight(
    LayoutUnit logicalHeight) const {
  // If the height of the containing block is not specified explicitly (i.e., it
  // depends on content height), and this element is not absolutely positioned,
  // the percentage value is treated as '0' (for 'min-height') or 'none' (for
  // 'max-height').
  LayoutUnit minLogicalHeight;
  if (!logicalHeightComputesAsNone(MinSize))
    minLogicalHeight =
        computeReplacedLogicalHeightUsing(style()->logicalMinHeight());
  LayoutUnit maxLogicalHeight = logicalHeight;
  if (!logicalHeightComputesAsNone(MaxSize))
    maxLogicalHeight =
        computeReplacedLogicalHeightUsing(style()->logicalMaxHeight());
  return std::max(minLogicalHeight, std::min(logicalHeight, maxLogicalHeight));
}

LayoutUnit RenderBox::computeReplacedLogicalHeightUsing(
    const Length& logicalHeight) const {
  switch (logicalHeight.type()) {
    case Fixed:
      return adjustContentBoxLogicalHeightForBoxSizing(logicalHeight.value());
    case Percent:
    case Calculated: {
      RenderObject* cb =
          isOutOfFlowPositioned() ? container() : containingBlock();
      if (cb->isRenderBlock())
        toRenderBlock(cb)->addPercentHeightDescendant(
            const_cast<RenderBox*>(this));

      // FIXME: This calculation is not patched for block-flow yet.
      // https://bugs.webkit.org/show_bug.cgi?id=46500
      if (cb->isOutOfFlowPositioned() && cb->style()->height().isAuto() &&
          !(cb->style()->top().isAuto() || cb->style()->bottom().isAuto())) {
        ASSERT_WITH_SECURITY_IMPLICATION(cb->isRenderBlock());
        RenderBlock* block = toRenderBlock(cb);
        LogicalExtentComputedValues computedValues;
        block->computeLogicalHeight(block->logicalHeight(), 0, computedValues);
        LayoutUnit newContentHeight =
            computedValues.m_extent - block->borderAndPaddingLogicalHeight();
        LayoutUnit newHeight =
            block->adjustContentBoxLogicalHeightForBoxSizing(newContentHeight);
        return adjustContentBoxLogicalHeightForBoxSizing(
            valueForLength(logicalHeight, newHeight));
      }

      // FIXME: availableLogicalHeight() is wrong if the replaced element's
      // block-flow is perpendicular to the containing block's block-flow.
      // https://bugs.webkit.org/show_bug.cgi?id=46496
      LayoutUnit availableHeight;
      if (isOutOfFlowPositioned())
        availableHeight = containingBlockLogicalHeightForPositioned(
            toRenderBoxModelObject(cb));
      else {
        availableHeight =
            containingBlockLogicalHeightForContent(IncludeMarginBorderPadding);
        // It is necessary to use the border-box to match WinIE's broken
        // box model.  This is essential for sizing inside
        // table cells using percentage heights.
        // FIXME: This needs to be made block-flow-aware.  If the cell and image
        // are perpendicular block-flows, this isn't right.
        // https://bugs.webkit.org/show_bug.cgi?id=46997
        while (cb && !cb->isRenderView() &&
               (cb->style()->logicalHeight().isAuto() ||
                cb->style()->logicalHeight().isPercent())) {
          toRenderBlock(cb)->addPercentHeightDescendant(
              const_cast<RenderBox*>(this));
          cb = cb->containingBlock();
        }
      }
      return adjustContentBoxLogicalHeightForBoxSizing(
          valueForLength(logicalHeight, availableHeight));
    }
    case MinContent:
    case MaxContent:
    case FitContent:
    case FillAvailable:
      return adjustContentBoxLogicalHeightForBoxSizing(
          computeIntrinsicLogicalContentHeightUsing(logicalHeight,
                                                    intrinsicLogicalHeight(),
                                                    borderAndPaddingHeight()));
    default:
      return intrinsicLogicalHeight();
  }
}

LayoutUnit RenderBox::availableLogicalHeight(
    AvailableLogicalHeightType heightType) const {
  // http://www.w3.org/TR/CSS2/visudet.html#propdef-height - We are interested
  // in the content height.
  return constrainContentBoxLogicalHeightByMinMax(
      availableLogicalHeightUsing(style()->logicalHeight(), heightType), -1);
}

LayoutUnit RenderBox::availableLogicalHeightUsing(
    const Length& h,
    AvailableLogicalHeightType heightType) const {
  if (isRenderView()) {
    ASSERT_NOT_REACHED();
    return LayoutUnit();
  }

  if (h.isPercent() && isOutOfFlowPositioned()) {
    // FIXME: This is wrong if the containingBlock has a perpendicular writing
    // mode.
    LayoutUnit availableHeight =
        containingBlockLogicalHeightForPositioned(containingBlock());
    return adjustContentBoxLogicalHeightForBoxSizing(
        valueForLength(h, availableHeight));
  }

  LayoutUnit heightIncludingScrollbar = computeContentLogicalHeightUsing(h, -1);
  if (heightIncludingScrollbar != -1)
    return std::max<LayoutUnit>(
        0, adjustContentBoxLogicalHeightForBoxSizing(heightIncludingScrollbar));

  // FIXME: Check logicalTop/logicalBottom here to correctly handle vertical
  // writing-mode. https://bugs.webkit.org/show_bug.cgi?id=46500
  if (isRenderBlock() && isOutOfFlowPositioned() &&
      style()->height().isAuto() &&
      !(style()->top().isAuto() || style()->bottom().isAuto())) {
    RenderBlock* block = const_cast<RenderBlock*>(toRenderBlock(this));
    LogicalExtentComputedValues computedValues;
    block->computeLogicalHeight(block->logicalHeight(), 0, computedValues);
    LayoutUnit newContentHeight =
        computedValues.m_extent - block->borderAndPaddingLogicalHeight();
    return adjustContentBoxLogicalHeightForBoxSizing(newContentHeight);
  }

  // FIXME: This is wrong if the containingBlock has a perpendicular writing
  // mode.
  LayoutUnit availableHeight =
      containingBlockLogicalHeightForContent(heightType);
  if (heightType == ExcludeMarginBorderPadding) {
    // FIXME: Margin collapsing hasn't happened yet, so this incorrectly removes
    // collapsed margins.
    availableHeight -=
        marginBefore() + marginAfter() + borderAndPaddingLogicalHeight();
  }
  return availableHeight;
}

void RenderBox::computeAndSetBlockDirectionMargins(
    const RenderBlock* containingBlock) {
  LayoutUnit marginBefore;
  LayoutUnit marginAfter;
  computeMarginsForDirection(
      BlockDirection, containingBlock, containingBlockLogicalWidthForContent(),
      logicalHeight(), marginBefore, marginAfter,
      style()->marginBeforeUsing(containingBlock->style()),
      style()->marginAfterUsing(containingBlock->style()));
  // Note that in this 'positioning phase' of the layout we are using the
  // containing block's writing mode rather than our own when calculating
  // margins. See
  // http://www.w3.org/TR/2014/CR-css-writing-modes-3-20140320/#orthogonal-flows
  containingBlock->setMarginBeforeForChild(this, marginBefore);
  containingBlock->setMarginAfterForChild(this, marginAfter);
}

LayoutUnit RenderBox::containingBlockLogicalWidthForPositioned(
    const RenderBoxModelObject* containingBlock) const {
  ASSERT(containingBlock->isBox());
  return toRenderBox(containingBlock)->clientLogicalWidth();
}

LayoutUnit RenderBox::containingBlockLogicalHeightForPositioned(
    const RenderBoxModelObject* containingBlock) const {
  ASSERT(containingBlock->isBox());
  const RenderBlock* cb = containingBlock->isRenderBlock()
                              ? toRenderBlock(containingBlock)
                              : containingBlock->containingBlock();
  return cb->clientLogicalHeight();
}

static void computePositionedStaticDistance(Length& leftOrTop,
                                            Length& rightOrBottom) {
  if (!leftOrTop.isAuto() || !rightOrBottom.isAuto())
    return;
  leftOrTop.setValue(Fixed, 0);
}

void RenderBox::computePositionedLogicalWidth(
    LogicalExtentComputedValues& computedValues) const {
  if (isReplaced()) {
    computePositionedLogicalWidthReplaced(computedValues);
    return;
  }

  // QUESTIONS
  // FIXME 1: Should we still deal with these the cases of 'left' or 'right'
  // having the type 'static' in determining whether to calculate the static
  // distance? NOTE: 'static' is not a legal value for 'left' or 'right' as of
  // CSS 2.1.

  // FIXME 2: Can perhaps optimize out cases when max-width/min-width are
  // greater than or less than the computed width().  Be careful of box-sizing
  // and percentage issues.

  // The following is based off of the W3C Working Draft from April 11, 2006 of
  // CSS 2.1: Section 10.3.7 "Absolutely positioned, non-replaced elements"
  // <http://www.w3.org/TR/CSS21/visudet.html#abs-non-replaced-width>
  // (block-style-comments in this function and in
  // computePositionedLogicalWidthUsing() correspond to text from the spec)

  // We don't use containingBlock(), since we may be positioned by an enclosing
  // relative positioned inline.
  const RenderBoxModelObject* containerBlock =
      toRenderBoxModelObject(container());

  const LayoutUnit containerLogicalWidth =
      containingBlockLogicalWidthForPositioned(containerBlock);

  // Use the container block's direction except when calculating the static
  // distance This conforms with the reference results for
  // abspos-replaced-width-margin-000.htm of the CSS 2.1 test suite
  TextDirection containerDirection = containerBlock->style()->direction();

  const LayoutUnit bordersPlusPadding = borderAndPaddingLogicalWidth();
  const Length marginLogicalLeft = style()->marginLeft();
  const Length marginLogicalRight = style()->marginRight();

  Length logicalLeftLength = style()->logicalLeft();
  Length logicalRightLength = style()->logicalRight();

  /*---------------------------------------------------------------------------*\
   * For the purposes of this section and the next, the term "static position"
   * (of an element) refers, roughly, to the position an element would have had
   * in the normal flow. More precisely:
   *
   * * The static position for 'left' is the distance from the left edge of the
   *   containing block to the left margin edge of a hypothetical box that would
   *   have been the first box of the element if its 'position' property had
   *   been 'static' and 'float' had been 'none'. The value is negative if the
   *   hypothetical box is to the left of the containing block.
   * * The static position for 'right' is the distance from the right edge of
  the
   *   containing block to the right margin edge of the same hypothetical box as
   *   above. The value is positive if the hypothetical box is to the left of
  the
   *   containing block's edge.
   *
   * But rather than actually calculating the dimensions of that hypothetical
  box,
   * user agents are free to make a guess at its probable position.
   *
   * For the purposes of calculating the static position, the containing block
  of
   * fixed positioned elements is the initial containing block instead of the
   * viewport, and all scrollable boxes should be assumed to be scrolled to
  their
   * origin.
  \*---------------------------------------------------------------------------*/

  // see FIXME 1
  // Calculate the static distance if needed.
  computePositionedStaticDistance(logicalLeftLength, logicalRightLength);

  // Calculate constraint equation values for 'width' case.
  computePositionedLogicalWidthUsing(style()->logicalWidth(), containerBlock,
                                     containerDirection, containerLogicalWidth,
                                     bordersPlusPadding, logicalLeftLength,
                                     logicalRightLength, marginLogicalLeft,
                                     marginLogicalRight, computedValues);

  // Calculate constraint equation values for 'max-width' case.
  if (!style()->logicalMaxWidth().isMaxSizeNone()) {
    LogicalExtentComputedValues maxValues;

    computePositionedLogicalWidthUsing(
        style()->logicalMaxWidth(), containerBlock, containerDirection,
        containerLogicalWidth, bordersPlusPadding, logicalLeftLength,
        logicalRightLength, marginLogicalLeft, marginLogicalRight, maxValues);

    if (computedValues.m_extent > maxValues.m_extent) {
      computedValues.m_extent = maxValues.m_extent;
      computedValues.m_position = maxValues.m_position;
      computedValues.m_margins.m_start = maxValues.m_margins.m_start;
      computedValues.m_margins.m_end = maxValues.m_margins.m_end;
    }
  }

  // Calculate constraint equation values for 'min-width' case.
  if (!style()->logicalMinWidth().isZero() ||
      style()->logicalMinWidth().isIntrinsic()) {
    LogicalExtentComputedValues minValues;

    computePositionedLogicalWidthUsing(
        style()->logicalMinWidth(), containerBlock, containerDirection,
        containerLogicalWidth, bordersPlusPadding, logicalLeftLength,
        logicalRightLength, marginLogicalLeft, marginLogicalRight, minValues);

    if (computedValues.m_extent < minValues.m_extent) {
      computedValues.m_extent = minValues.m_extent;
      computedValues.m_position = minValues.m_position;
      computedValues.m_margins.m_start = minValues.m_margins.m_start;
      computedValues.m_margins.m_end = minValues.m_margins.m_end;
    }
  }

  computedValues.m_extent += bordersPlusPadding;
}

static void computeLogicalLeftPositionedOffset(
    LayoutUnit& logicalLeftPos,
    const RenderBox* child,
    LayoutUnit logicalWidthValue,
    const RenderBoxModelObject* containerBlock,
    LayoutUnit containerLogicalWidth) {
  // FIXME(sky): Remove
  logicalLeftPos += containerBlock->borderLeft();
}

void RenderBox::shrinkToFitWidth(
    const LayoutUnit availableSpace,
    const LayoutUnit logicalLeftValue,
    const LayoutUnit bordersPlusPadding,
    LogicalExtentComputedValues& computedValues) const {
  // FIXME: would it be better to have shrink-to-fit in one step?
  LayoutUnit preferredWidth = maxPreferredLogicalWidth() - bordersPlusPadding;
  LayoutUnit preferredMinWidth =
      minPreferredLogicalWidth() - bordersPlusPadding;
  LayoutUnit availableWidth = availableSpace - logicalLeftValue;
  computedValues.m_extent =
      std::min(std::max(preferredMinWidth, availableWidth), preferredWidth);
}

void RenderBox::computePositionedLogicalWidthUsing(
    Length logicalWidth,
    const RenderBoxModelObject* containerBlock,
    TextDirection containerDirection,
    LayoutUnit containerLogicalWidth,
    LayoutUnit bordersPlusPadding,
    const Length& logicalLeft,
    const Length& logicalRight,
    const Length& marginLogicalLeft,
    const Length& marginLogicalRight,
    LogicalExtentComputedValues& computedValues) const {
  if (logicalWidth.isIntrinsic())
    logicalWidth =
        Length(computeIntrinsicLogicalWidthUsing(
                   logicalWidth, containerLogicalWidth, bordersPlusPadding) -
                   bordersPlusPadding,
               Fixed);

  // 'left' and 'right' cannot both be 'auto' because one would of been
  // converted to the static position already
  ASSERT(!(logicalLeft.isAuto() && logicalRight.isAuto()));

  LayoutUnit logicalLeftValue = 0;

  const LayoutUnit containerRelativeLogicalWidth =
      containingBlockLogicalWidthForPositioned(containerBlock);

  bool logicalWidthIsAuto = logicalWidth.isIntrinsicOrAuto();
  bool logicalLeftIsAuto = logicalLeft.isAuto();
  bool logicalRightIsAuto = logicalRight.isAuto();
  LayoutUnit& marginLogicalLeftValue = style()->isLeftToRightDirection()
                                           ? computedValues.m_margins.m_start
                                           : computedValues.m_margins.m_end;
  LayoutUnit& marginLogicalRightValue = style()->isLeftToRightDirection()
                                            ? computedValues.m_margins.m_end
                                            : computedValues.m_margins.m_start;
  if (!logicalLeftIsAuto && !logicalWidthIsAuto && !logicalRightIsAuto) {
    /*-----------------------------------------------------------------------*\
     * If none of the three is 'auto': If both 'margin-left' and 'margin-
     * right' are 'auto', solve the equation under the extra constraint that
     * the two margins get equal values, unless this would make them negative,
     * in which case when direction of the containing block is 'ltr' ('rtl'),
     * set 'margin-left' ('margin-right') to zero and solve for 'margin-right'
     * ('margin-left'). If one of 'margin-left' or 'margin-right' is 'auto',
     * solve the equation for that value. If the values are over-constrained,
     * ignore the value for 'left' (in case the 'direction' property of the
     * containing block is 'rtl') or 'right' (in case 'direction' is 'ltr')
     * and solve for that value.
    \*-----------------------------------------------------------------------*/
    // NOTE:  It is not necessary to solve for 'right' in the over constrained
    // case because the value is not used for any further calculations.

    logicalLeftValue = valueForLength(logicalLeft, containerLogicalWidth);
    computedValues.m_extent = adjustContentBoxLogicalWidthForBoxSizing(
        valueForLength(logicalWidth, containerLogicalWidth));

    const LayoutUnit availableSpace =
        containerLogicalWidth -
        (logicalLeftValue + computedValues.m_extent +
         valueForLength(logicalRight, containerLogicalWidth) +
         bordersPlusPadding);

    // Margins are now the only unknown
    if (marginLogicalLeft.isAuto() && marginLogicalRight.isAuto()) {
      // Both margins auto, solve for equality
      if (availableSpace >= 0) {
        marginLogicalLeftValue = availableSpace / 2;  // split the difference
        marginLogicalRightValue =
            availableSpace -
            marginLogicalLeftValue;  // account for odd valued differences
      } else {
        // Use the containing block's direction rather than the parent block's
        // per CSS 2.1 reference test abspos-non-replaced-width-margin-000.
        if (containerDirection == LTR) {
          marginLogicalLeftValue = 0;
          marginLogicalRightValue = availableSpace;  // will be negative
        } else {
          marginLogicalLeftValue = availableSpace;  // will be negative
          marginLogicalRightValue = 0;
        }
      }
    } else if (marginLogicalLeft.isAuto()) {
      // Solve for left margin
      marginLogicalRightValue =
          valueForLength(marginLogicalRight, containerRelativeLogicalWidth);
      marginLogicalLeftValue = availableSpace - marginLogicalRightValue;
    } else if (marginLogicalRight.isAuto()) {
      // Solve for right margin
      marginLogicalLeftValue =
          valueForLength(marginLogicalLeft, containerRelativeLogicalWidth);
      marginLogicalRightValue = availableSpace - marginLogicalLeftValue;
    } else {
      // Over-constrained, solve for left if direction is RTL
      marginLogicalLeftValue =
          valueForLength(marginLogicalLeft, containerRelativeLogicalWidth);
      marginLogicalRightValue =
          valueForLength(marginLogicalRight, containerRelativeLogicalWidth);

      // Use the containing block's direction rather than the parent block's
      // per CSS 2.1 reference test abspos-non-replaced-width-margin-000.
      if (containerDirection == RTL)
        logicalLeftValue = (availableSpace + logicalLeftValue) -
                           marginLogicalLeftValue - marginLogicalRightValue;
    }
  } else {
    /*--------------------------------------------------------------------*\
     * Otherwise, set 'auto' values for 'margin-left' and 'margin-right'
     * to 0, and pick the one of the following six rules that applies.
     *
     * 1. 'left' and 'width' are 'auto' and 'right' is not 'auto', then the
     *    width is shrink-to-fit. Then solve for 'left'
     *
     *              OMIT RULE 2 AS IT SHOULD NEVER BE HIT
     * ------------------------------------------------------------------
     * 2. 'left' and 'right' are 'auto' and 'width' is not 'auto', then if
     *    the 'direction' property of the containing block is 'ltr' set
     *    'left' to the static position, otherwise set 'right' to the
     *    static position. Then solve for 'left' (if 'direction is 'rtl')
     *    or 'right' (if 'direction' is 'ltr').
     * ------------------------------------------------------------------
     *
     * 3. 'width' and 'right' are 'auto' and 'left' is not 'auto', then the
     *    width is shrink-to-fit . Then solve for 'right'
     * 4. 'left' is 'auto', 'width' and 'right' are not 'auto', then solve
     *    for 'left'
     * 5. 'width' is 'auto', 'left' and 'right' are not 'auto', then solve
     *    for 'width'
     * 6. 'right' is 'auto', 'left' and 'width' are not 'auto', then solve
     *    for 'right'
     *
     * Calculation of the shrink-to-fit width is similar to calculating the
     * width of a table cell using the automatic table layout algorithm.
     * Roughly: calculate the preferred width by formatting the content
     * without breaking lines other than where explicit line breaks occur,
     * and also calculate the preferred minimum width, e.g., by trying all
     * possible line breaks. CSS 2.1 does not define the exact algorithm.
     * Thirdly, calculate the available width: this is found by solving
     * for 'width' after setting 'left' (in case 1) or 'right' (in case 3)
     * to 0.
     *
     * Then the shrink-to-fit width is:
     * min(max(preferred minimum width, available width), preferred width).
    \*--------------------------------------------------------------------*/
    // NOTE: For rules 3 and 6 it is not necessary to solve for 'right'
    // because the value is not used for any further calculations.

    // Calculate margins, 'auto' margins are ignored.
    marginLogicalLeftValue =
        minimumValueForLength(marginLogicalLeft, containerRelativeLogicalWidth);
    marginLogicalRightValue = minimumValueForLength(
        marginLogicalRight, containerRelativeLogicalWidth);

    const LayoutUnit availableSpace =
        containerLogicalWidth -
        (marginLogicalLeftValue + marginLogicalRightValue + bordersPlusPadding);

    // FIXME: Is there a faster way to find the correct case?
    // Use rule/case that applies.
    if (logicalLeftIsAuto && logicalWidthIsAuto && !logicalRightIsAuto) {
      // RULE 1: (use shrink-to-fit for width, and solve of left)
      LayoutUnit logicalRightValue =
          valueForLength(logicalRight, containerLogicalWidth);

      // FIXME: would it be better to have shrink-to-fit in one step?
      LayoutUnit preferredWidth =
          maxPreferredLogicalWidth() - bordersPlusPadding;
      LayoutUnit preferredMinWidth =
          minPreferredLogicalWidth() - bordersPlusPadding;
      LayoutUnit availableWidth = availableSpace - logicalRightValue;
      computedValues.m_extent =
          std::min(std::max(preferredMinWidth, availableWidth), preferredWidth);
      logicalLeftValue =
          availableSpace - (computedValues.m_extent + logicalRightValue);
    } else if (!logicalLeftIsAuto && logicalWidthIsAuto && logicalRightIsAuto) {
      // RULE 3: (use shrink-to-fit for width, and no need solve of right)
      logicalLeftValue = valueForLength(logicalLeft, containerLogicalWidth);

      shrinkToFitWidth(availableSpace, logicalLeftValue, bordersPlusPadding,
                       computedValues);
    } else if (logicalLeftIsAuto && !logicalWidthIsAuto &&
               !logicalRightIsAuto) {
      // RULE 4: (solve for left)
      computedValues.m_extent = adjustContentBoxLogicalWidthForBoxSizing(
          valueForLength(logicalWidth, containerLogicalWidth));
      logicalLeftValue = availableSpace -
                         (computedValues.m_extent +
                          valueForLength(logicalRight, containerLogicalWidth));
    } else if (!logicalLeftIsAuto && logicalWidthIsAuto &&
               !logicalRightIsAuto) {
      // RULE 5: (solve for width)
      logicalLeftValue = valueForLength(logicalLeft, containerLogicalWidth);
      computedValues.m_extent =
          availableSpace -
          (logicalLeftValue +
           valueForLength(logicalRight, containerLogicalWidth));
    } else if (!logicalLeftIsAuto && !logicalWidthIsAuto &&
               logicalRightIsAuto) {
      // RULE 6: (no need solve for right)
      logicalLeftValue = valueForLength(logicalLeft, containerLogicalWidth);
      computedValues.m_extent = adjustContentBoxLogicalWidthForBoxSizing(
          valueForLength(logicalWidth, containerLogicalWidth));
    }
  }

  // Use computed values to calculate the horizontal position.

  // FIXME: This hack is needed to calculate the  logical left position for a
  // 'rtl' relatively positioned, inline because right now, it is using the
  // logical left position of the first line box when really it should use the
  // last line box.  When this is fixed elsewhere, this block should be removed.
  if (containerBlock->isRenderInline() &&
      !containerBlock->style()->isLeftToRightDirection()) {
    const RenderInline* flow = toRenderInline(containerBlock);
    InlineFlowBox* firstLine = flow->firstLineBox();
    InlineFlowBox* lastLine = flow->lastLineBox();
    if (firstLine && lastLine && firstLine != lastLine) {
      computedValues.m_position =
          logicalLeftValue + marginLogicalLeftValue +
          lastLine->borderLogicalLeft() +
          (lastLine->logicalLeft() - firstLine->logicalLeft());
      return;
    }
  }

  computedValues.m_position = logicalLeftValue + marginLogicalLeftValue;
  computeLogicalLeftPositionedOffset(computedValues.m_position, this,
                                     computedValues.m_extent, containerBlock,
                                     containerLogicalWidth);
}

void RenderBox::computePositionedLogicalHeight(
    LogicalExtentComputedValues& computedValues) const {
  if (isReplaced()) {
    computePositionedLogicalHeightReplaced(computedValues);
    return;
  }

  // The following is based off of the W3C Working Draft from April 11, 2006 of
  // CSS 2.1: Section 10.6.4 "Absolutely positioned, non-replaced elements"
  // <http://www.w3.org/TR/2005/WD-CSS21-20050613/visudet.html#abs-non-replaced-height>
  // (block-style-comments in this function and in
  // computePositionedLogicalHeightUsing() correspond to text from the spec)

  // We don't use containingBlock(), since we may be positioned by an enclosing
  // relpositioned inline.
  const RenderBoxModelObject* containerBlock =
      toRenderBoxModelObject(container());

  const LayoutUnit containerLogicalHeight =
      containingBlockLogicalHeightForPositioned(containerBlock);

  RenderStyle* styleToUse = style();
  const LayoutUnit bordersPlusPadding = borderAndPaddingLogicalHeight();
  const Length marginBefore = styleToUse->marginBefore();
  const Length marginAfter = styleToUse->marginAfter();
  Length logicalTopLength = styleToUse->logicalTop();
  Length logicalBottomLength = styleToUse->logicalBottom();

  /*---------------------------------------------------------------------------*\
   * For the purposes of this section and the next, the term "static position"
   * (of an element) refers, roughly, to the position an element would have had
   * in the normal flow. More precisely, the static position for 'top' is the
   * distance from the top edge of the containing block to the top margin edge
   * of a hypothetical box that would have been the first box of the element if
   * its 'position' property had been 'static' and 'float' had been 'none'. The
   * value is negative if the hypothetical box is above the containing block.
   *
   * But rather than actually calculating the dimensions of that hypothetical
   * box, user agents are free to make a guess at its probable position.
   *
   * For the purposes of calculating the static position, the containing block
   * of fixed positioned elements is the initial containing block instead of
   * the viewport.
  \*---------------------------------------------------------------------------*/

  // see FIXME 1
  // Calculate the static distance if needed.
  computePositionedStaticDistance(logicalTopLength, logicalBottomLength);

  // Calculate constraint equation values for 'height' case.
  LayoutUnit logicalHeight = computedValues.m_extent;
  computePositionedLogicalHeightUsing(
      styleToUse->logicalHeight(), containerBlock, containerLogicalHeight,
      bordersPlusPadding, logicalHeight, logicalTopLength, logicalBottomLength,
      marginBefore, marginAfter, computedValues);

  // Avoid doing any work in the common case (where the values of min-height and
  // max-height are their defaults). see FIXME 2

  // Calculate constraint equation values for 'max-height' case.
  if (!styleToUse->logicalMaxHeight().isMaxSizeNone()) {
    LogicalExtentComputedValues maxValues;

    computePositionedLogicalHeightUsing(
        styleToUse->logicalMaxHeight(), containerBlock, containerLogicalHeight,
        bordersPlusPadding, logicalHeight, logicalTopLength,
        logicalBottomLength, marginBefore, marginAfter, maxValues);

    if (computedValues.m_extent > maxValues.m_extent) {
      computedValues.m_extent = maxValues.m_extent;
      computedValues.m_position = maxValues.m_position;
      computedValues.m_margins.m_before = maxValues.m_margins.m_before;
      computedValues.m_margins.m_after = maxValues.m_margins.m_after;
    }
  }

  // Calculate constraint equation values for 'min-height' case.
  if (!styleToUse->logicalMinHeight().isZero() ||
      styleToUse->logicalMinHeight().isIntrinsic()) {
    LogicalExtentComputedValues minValues;

    computePositionedLogicalHeightUsing(
        styleToUse->logicalMinHeight(), containerBlock, containerLogicalHeight,
        bordersPlusPadding, logicalHeight, logicalTopLength,
        logicalBottomLength, marginBefore, marginAfter, minValues);

    if (computedValues.m_extent < minValues.m_extent) {
      computedValues.m_extent = minValues.m_extent;
      computedValues.m_position = minValues.m_position;
      computedValues.m_margins.m_before = minValues.m_margins.m_before;
      computedValues.m_margins.m_after = minValues.m_margins.m_after;
    }
  }

  // Set final height value.
  computedValues.m_extent += bordersPlusPadding;
}

static void computeLogicalTopPositionedOffset(
    LayoutUnit& logicalTopPos,
    const RenderBox* child,
    LayoutUnit logicalHeightValue,
    const RenderBoxModelObject* containerBlock,
    LayoutUnit containerLogicalHeight) {
  // FIXME(sky): Remove
  logicalTopPos += containerBlock->borderTop();
}

void RenderBox::computePositionedLogicalHeightUsing(
    Length logicalHeightLength,
    const RenderBoxModelObject* containerBlock,
    LayoutUnit containerLogicalHeight,
    LayoutUnit bordersPlusPadding,
    LayoutUnit logicalHeight,
    const Length& logicalTop,
    const Length& logicalBottom,
    const Length& marginBefore,
    const Length& marginAfter,
    LogicalExtentComputedValues& computedValues) const {
  // 'top' and 'bottom' cannot both be 'auto' because 'top would of been
  // converted to the static position in computePositionedLogicalHeight()
  ASSERT(!(logicalTop.isAuto() && logicalBottom.isAuto()));

  LayoutUnit logicalHeightValue;
  LayoutUnit contentLogicalHeight = logicalHeight - bordersPlusPadding;

  const LayoutUnit containerRelativeLogicalWidth =
      containingBlockLogicalWidthForPositioned(containerBlock);

  LayoutUnit logicalTopValue = 0;

  bool logicalHeightIsAuto = logicalHeightLength.isAuto();
  bool logicalTopIsAuto = logicalTop.isAuto();
  bool logicalBottomIsAuto = logicalBottom.isAuto();

  LayoutUnit resolvedLogicalHeight;
  if (logicalHeightLength.isIntrinsic())
    resolvedLogicalHeight = computeIntrinsicLogicalContentHeightUsing(
        logicalHeightLength, contentLogicalHeight, bordersPlusPadding);
  else
    resolvedLogicalHeight = adjustContentBoxLogicalHeightForBoxSizing(
        valueForLength(logicalHeightLength, containerLogicalHeight));

  if (!logicalTopIsAuto && !logicalHeightIsAuto && !logicalBottomIsAuto) {
    /*-----------------------------------------------------------------------*\
     * If none of the three are 'auto': If both 'margin-top' and 'margin-
     * bottom' are 'auto', solve the equation under the extra constraint that
     * the two margins get equal values. If one of 'margin-top' or 'margin-
     * bottom' is 'auto', solve the equation for that value. If the values
     * are over-constrained, ignore the value for 'bottom' and solve for that
     * value.
    \*-----------------------------------------------------------------------*/
    // NOTE:  It is not necessary to solve for 'bottom' in the over constrained
    // case because the value is not used for any further calculations.

    logicalHeightValue = resolvedLogicalHeight;
    logicalTopValue = valueForLength(logicalTop, containerLogicalHeight);

    const LayoutUnit availableSpace =
        containerLogicalHeight -
        (logicalTopValue + logicalHeightValue +
         valueForLength(logicalBottom, containerLogicalHeight) +
         bordersPlusPadding);

    // Margins are now the only unknown
    if (marginBefore.isAuto() && marginAfter.isAuto()) {
      // Both margins auto, solve for equality
      // NOTE: This may result in negative values.
      computedValues.m_margins.m_before =
          availableSpace / 2;  // split the difference
      computedValues.m_margins.m_after =
          availableSpace - computedValues.m_margins
                               .m_before;  // account for odd valued differences
    } else if (marginBefore.isAuto()) {
      // Solve for top margin
      computedValues.m_margins.m_after =
          valueForLength(marginAfter, containerRelativeLogicalWidth);
      computedValues.m_margins.m_before =
          availableSpace - computedValues.m_margins.m_after;
    } else if (marginAfter.isAuto()) {
      // Solve for bottom margin
      computedValues.m_margins.m_before =
          valueForLength(marginBefore, containerRelativeLogicalWidth);
      computedValues.m_margins.m_after =
          availableSpace - computedValues.m_margins.m_before;
    } else {
      // Over-constrained, (no need solve for bottom)
      computedValues.m_margins.m_before =
          valueForLength(marginBefore, containerRelativeLogicalWidth);
      computedValues.m_margins.m_after =
          valueForLength(marginAfter, containerRelativeLogicalWidth);
    }
  } else {
    /*--------------------------------------------------------------------*\
     * Otherwise, set 'auto' values for 'margin-top' and 'margin-bottom'
     * to 0, and pick the one of the following six rules that applies.
     *
     * 1. 'top' and 'height' are 'auto' and 'bottom' is not 'auto', then
     *    the height is based on the content, and solve for 'top'.
     *
     *              OMIT RULE 2 AS IT SHOULD NEVER BE HIT
     * ------------------------------------------------------------------
     * 2. 'top' and 'bottom' are 'auto' and 'height' is not 'auto', then
     *    set 'top' to the static position, and solve for 'bottom'.
     * ------------------------------------------------------------------
     *
     * 3. 'height' and 'bottom' are 'auto' and 'top' is not 'auto', then
     *    the height is based on the content, and solve for 'bottom'.
     * 4. 'top' is 'auto', 'height' and 'bottom' are not 'auto', and
     *    solve for 'top'.
     * 5. 'height' is 'auto', 'top' and 'bottom' are not 'auto', and
     *    solve for 'height'.
     * 6. 'bottom' is 'auto', 'top' and 'height' are not 'auto', and
     *    solve for 'bottom'.
    \*--------------------------------------------------------------------*/
    // NOTE: For rules 3 and 6 it is not necessary to solve for 'bottom'
    // because the value is not used for any further calculations.

    // Calculate margins, 'auto' margins are ignored.
    computedValues.m_margins.m_before =
        minimumValueForLength(marginBefore, containerRelativeLogicalWidth);
    computedValues.m_margins.m_after =
        minimumValueForLength(marginAfter, containerRelativeLogicalWidth);

    const LayoutUnit availableSpace =
        containerLogicalHeight -
        (computedValues.m_margins.m_before + computedValues.m_margins.m_after +
         bordersPlusPadding);

    // Use rule/case that applies.
    if (logicalTopIsAuto && logicalHeightIsAuto && !logicalBottomIsAuto) {
      // RULE 1: (height is content based, solve of top)
      logicalHeightValue = contentLogicalHeight;
      logicalTopValue = availableSpace -
                        (logicalHeightValue +
                         valueForLength(logicalBottom, containerLogicalHeight));
    } else if (!logicalTopIsAuto && logicalHeightIsAuto &&
               logicalBottomIsAuto) {
      // RULE 3: (height is content based, no need solve of bottom)
      logicalTopValue = valueForLength(logicalTop, containerLogicalHeight);
      logicalHeightValue = contentLogicalHeight;
    } else if (logicalTopIsAuto && !logicalHeightIsAuto &&
               !logicalBottomIsAuto) {
      // RULE 4: (solve of top)
      logicalHeightValue = resolvedLogicalHeight;
      logicalTopValue = availableSpace -
                        (logicalHeightValue +
                         valueForLength(logicalBottom, containerLogicalHeight));
    } else if (!logicalTopIsAuto && logicalHeightIsAuto &&
               !logicalBottomIsAuto) {
      // RULE 5: (solve of height)
      logicalTopValue = valueForLength(logicalTop, containerLogicalHeight);
      logicalHeightValue = std::max<LayoutUnit>(
          0, availableSpace -
                 (logicalTopValue +
                  valueForLength(logicalBottom, containerLogicalHeight)));
    } else if (!logicalTopIsAuto && !logicalHeightIsAuto &&
               logicalBottomIsAuto) {
      // RULE 6: (no need solve of bottom)
      logicalHeightValue = resolvedLogicalHeight;
      logicalTopValue = valueForLength(logicalTop, containerLogicalHeight);
    }
  }
  computedValues.m_extent = logicalHeightValue;

  // Use computed values to calculate the vertical position.
  computedValues.m_position =
      logicalTopValue + computedValues.m_margins.m_before;
  computeLogicalTopPositionedOffset(computedValues.m_position, this,
                                    logicalHeightValue, containerBlock,
                                    containerLogicalHeight);
}

void RenderBox::computePositionedLogicalWidthReplaced(
    LogicalExtentComputedValues& computedValues) const {
  // The following is based off of the W3C Working Draft from April 11, 2006 of
  // CSS 2.1: Section 10.3.8 "Absolutely positioned, replaced elements"
  // <http://www.w3.org/TR/2005/WD-CSS21-20050613/visudet.html#abs-replaced-width>
  // (block-style-comments in this function correspond to text from the spec and
  // the numbers correspond to numbers in spec)

  // We don't use containingBlock(), since we may be positioned by an enclosing
  // relative positioned inline.
  const RenderBoxModelObject* containerBlock =
      toRenderBoxModelObject(container());

  const LayoutUnit containerLogicalWidth =
      containingBlockLogicalWidthForPositioned(containerBlock);
  const LayoutUnit containerRelativeLogicalWidth =
      containingBlockLogicalWidthForPositioned(containerBlock);

  // To match WinIE, in quirks mode use the parent's 'direction' property
  // instead of the the container block's.
  TextDirection containerDirection = containerBlock->style()->direction();

  // Variables to solve.
  Length logicalLeft = style()->logicalLeft();
  Length logicalRight = style()->logicalRight();
  Length marginLogicalLeft = style()->marginLeft();
  Length marginLogicalRight = style()->marginRight();
  LayoutUnit& marginLogicalLeftAlias = style()->isLeftToRightDirection()
                                           ? computedValues.m_margins.m_start
                                           : computedValues.m_margins.m_end;
  LayoutUnit& marginLogicalRightAlias = style()->isLeftToRightDirection()
                                            ? computedValues.m_margins.m_end
                                            : computedValues.m_margins.m_start;

  /*-----------------------------------------------------------------------*\
   * 1. The used value of 'width' is determined as for inline replaced
   *    elements.
  \*-----------------------------------------------------------------------*/
  // NOTE: This value of width is final in that the min/max width calculations
  // are dealt with in computeReplacedWidth().  This means that the steps to
  // produce correct max/min in the non-replaced version, are not necessary.
  computedValues.m_extent =
      computeReplacedLogicalWidth() + borderAndPaddingLogicalWidth();

  const LayoutUnit availableSpace =
      containerLogicalWidth - computedValues.m_extent;

  /*-----------------------------------------------------------------------*\
   * 2. If both 'left' and 'right' have the value 'auto', then if 'direction'
   *    of the containing block is 'ltr', set 'left' to the static position;
   *    else if 'direction' is 'rtl', set 'right' to the static position.
  \*-----------------------------------------------------------------------*/
  // see FIXME 1
  computePositionedStaticDistance(logicalLeft, logicalRight);

  /*-----------------------------------------------------------------------*\
   * 3. If 'left' or 'right' are 'auto', replace any 'auto' on 'margin-left'
   *    or 'margin-right' with '0'.
  \*-----------------------------------------------------------------------*/
  if (logicalLeft.isAuto() || logicalRight.isAuto()) {
    if (marginLogicalLeft.isAuto())
      marginLogicalLeft.setValue(Fixed, 0);
    if (marginLogicalRight.isAuto())
      marginLogicalRight.setValue(Fixed, 0);
  }

  /*-----------------------------------------------------------------------*\
   * 4. If at this point both 'margin-left' and 'margin-right' are still
   *    'auto', solve the equation under the extra constraint that the two
   *    margins must get equal values, unless this would make them negative,
   *    in which case when the direction of the containing block is 'ltr'
   *    ('rtl'), set 'margin-left' ('margin-right') to zero and solve for
   *    'margin-right' ('margin-left').
  \*-----------------------------------------------------------------------*/
  LayoutUnit logicalLeftValue = 0;
  LayoutUnit logicalRightValue = 0;

  if (marginLogicalLeft.isAuto() && marginLogicalRight.isAuto()) {
    // 'left' and 'right' cannot be 'auto' due to step 3
    ASSERT(!(logicalLeft.isAuto() && logicalRight.isAuto()));

    logicalLeftValue = valueForLength(logicalLeft, containerLogicalWidth);
    logicalRightValue = valueForLength(logicalRight, containerLogicalWidth);

    LayoutUnit difference =
        availableSpace - (logicalLeftValue + logicalRightValue);
    if (difference > 0) {
      marginLogicalLeftAlias = difference / 2;  // split the difference
      marginLogicalRightAlias =
          difference -
          marginLogicalLeftAlias;  // account for odd valued differences
    } else {
      // Use the containing block's direction rather than the parent block's
      // per CSS 2.1 reference test abspos-replaced-width-margin-000.
      if (containerDirection == LTR) {
        marginLogicalLeftAlias = 0;
        marginLogicalRightAlias = difference;  // will be negative
      } else {
        marginLogicalLeftAlias = difference;  // will be negative
        marginLogicalRightAlias = 0;
      }
    }

    /*-----------------------------------------------------------------------*\
     * 5. If at this point there is an 'auto' left, solve the equation for
     *    that value.
    \*-----------------------------------------------------------------------*/
  } else if (logicalLeft.isAuto()) {
    marginLogicalLeftAlias =
        valueForLength(marginLogicalLeft, containerRelativeLogicalWidth);
    marginLogicalRightAlias =
        valueForLength(marginLogicalRight, containerRelativeLogicalWidth);
    logicalRightValue = valueForLength(logicalRight, containerLogicalWidth);

    // Solve for 'left'
    logicalLeftValue =
        availableSpace -
        (logicalRightValue + marginLogicalLeftAlias + marginLogicalRightAlias);
  } else if (logicalRight.isAuto()) {
    marginLogicalLeftAlias =
        valueForLength(marginLogicalLeft, containerRelativeLogicalWidth);
    marginLogicalRightAlias =
        valueForLength(marginLogicalRight, containerRelativeLogicalWidth);
    logicalLeftValue = valueForLength(logicalLeft, containerLogicalWidth);

    // Solve for 'right'
    logicalRightValue =
        availableSpace -
        (logicalLeftValue + marginLogicalLeftAlias + marginLogicalRightAlias);
  } else if (marginLogicalLeft.isAuto()) {
    marginLogicalRightAlias =
        valueForLength(marginLogicalRight, containerRelativeLogicalWidth);
    logicalLeftValue = valueForLength(logicalLeft, containerLogicalWidth);
    logicalRightValue = valueForLength(logicalRight, containerLogicalWidth);

    // Solve for 'margin-left'
    marginLogicalLeftAlias =
        availableSpace -
        (logicalLeftValue + logicalRightValue + marginLogicalRightAlias);
  } else if (marginLogicalRight.isAuto()) {
    marginLogicalLeftAlias =
        valueForLength(marginLogicalLeft, containerRelativeLogicalWidth);
    logicalLeftValue = valueForLength(logicalLeft, containerLogicalWidth);
    logicalRightValue = valueForLength(logicalRight, containerLogicalWidth);

    // Solve for 'margin-right'
    marginLogicalRightAlias =
        availableSpace -
        (logicalLeftValue + logicalRightValue + marginLogicalLeftAlias);
  } else {
    // Nothing is 'auto', just calculate the values.
    marginLogicalLeftAlias =
        valueForLength(marginLogicalLeft, containerRelativeLogicalWidth);
    marginLogicalRightAlias =
        valueForLength(marginLogicalRight, containerRelativeLogicalWidth);
    logicalRightValue = valueForLength(logicalRight, containerLogicalWidth);
    logicalLeftValue = valueForLength(logicalLeft, containerLogicalWidth);
    // If the containing block is right-to-left, then push the left position as
    // far to the right as possible
    if (containerDirection == RTL) {
      int totalLogicalWidth = computedValues.m_extent + logicalLeftValue +
                              logicalRightValue + marginLogicalLeftAlias +
                              marginLogicalRightAlias;
      logicalLeftValue =
          containerLogicalWidth - (totalLogicalWidth - logicalLeftValue);
    }
  }

  /*-----------------------------------------------------------------------*\
   * 6. If at this point the values are over-constrained, ignore the value
   *    for either 'left' (in case the 'direction' property of the
   *    containing block is 'rtl') or 'right' (in case 'direction' is
   *    'ltr') and solve for that value.
  \*-----------------------------------------------------------------------*/
  // NOTE: Constraints imposed by the width of the containing block and its
  // content have already been accounted for above.

  // FIXME: Deal with differing writing modes here.  Our offset needs to be in
  // the containing block's coordinate space, so that can make the result here
  // rather complicated to compute.

  // Use computed values to calculate the horizontal position.

  // FIXME: This hack is needed to calculate the logical left position for a
  // 'rtl' relatively positioned, inline containing block because right now, it
  // is using the logical left position of the first line box when really it
  // should use the last line box.  When this is fixed elsewhere, this block
  // should be removed.
  if (containerBlock->isRenderInline() &&
      !containerBlock->style()->isLeftToRightDirection()) {
    const RenderInline* flow = toRenderInline(containerBlock);
    InlineFlowBox* firstLine = flow->firstLineBox();
    InlineFlowBox* lastLine = flow->lastLineBox();
    if (firstLine && lastLine && firstLine != lastLine) {
      computedValues.m_position =
          logicalLeftValue + marginLogicalLeftAlias +
          lastLine->borderLogicalLeft() +
          (lastLine->logicalLeft() - firstLine->logicalLeft());
      return;
    }
  }

  LayoutUnit logicalLeftPos = logicalLeftValue + marginLogicalLeftAlias;
  computeLogicalLeftPositionedOffset(logicalLeftPos, this,
                                     computedValues.m_extent, containerBlock,
                                     containerLogicalWidth);
  computedValues.m_position = logicalLeftPos;
}

void RenderBox::computePositionedLogicalHeightReplaced(
    LogicalExtentComputedValues& computedValues) const {
  // The following is based off of the W3C Working Draft from April 11, 2006 of
  // CSS 2.1: Section 10.6.5 "Absolutely positioned, replaced elements"
  // <http://www.w3.org/TR/2005/WD-CSS21-20050613/visudet.html#abs-replaced-height>
  // (block-style-comments in this function correspond to text from the spec and
  // the numbers correspond to numbers in spec)

  // We don't use containingBlock(), since we may be positioned by an enclosing
  // relpositioned inline.
  const RenderBoxModelObject* containerBlock =
      toRenderBoxModelObject(container());

  const LayoutUnit containerLogicalHeight =
      containingBlockLogicalHeightForPositioned(containerBlock);
  const LayoutUnit containerRelativeLogicalWidth =
      containingBlockLogicalWidthForPositioned(containerBlock);

  // Variables to solve.
  Length marginBefore = style()->marginBefore();
  Length marginAfter = style()->marginAfter();
  LayoutUnit& marginBeforeAlias = computedValues.m_margins.m_before;
  LayoutUnit& marginAfterAlias = computedValues.m_margins.m_after;

  Length logicalTop = style()->logicalTop();
  Length logicalBottom = style()->logicalBottom();

  /*-----------------------------------------------------------------------*\
   * 1. The used value of 'height' is determined as for inline replaced
   *    elements.
  \*-----------------------------------------------------------------------*/
  // NOTE: This value of height is final in that the min/max height calculations
  // are dealt with in computeReplacedHeight().  This means that the steps to
  // produce correct max/min in the non-replaced version, are not necessary.
  computedValues.m_extent =
      computeReplacedLogicalHeight() + borderAndPaddingLogicalHeight();
  const LayoutUnit availableSpace =
      containerLogicalHeight - computedValues.m_extent;

  /*-----------------------------------------------------------------------*\
   * 2. If both 'top' and 'bottom' have the value 'auto', replace 'top'
   *    with the element's static position.
  \*-----------------------------------------------------------------------*/
  // see FIXME 1
  computePositionedStaticDistance(logicalTop, logicalBottom);

  /*-----------------------------------------------------------------------*\
   * 3. If 'bottom' is 'auto', replace any 'auto' on 'margin-top' or
   *    'margin-bottom' with '0'.
  \*-----------------------------------------------------------------------*/
  // FIXME: The spec. says that this step should only be taken when bottom is
  // auto, but if only top is auto, this makes step 4 impossible.
  if (logicalTop.isAuto() || logicalBottom.isAuto()) {
    if (marginBefore.isAuto())
      marginBefore.setValue(Fixed, 0);
    if (marginAfter.isAuto())
      marginAfter.setValue(Fixed, 0);
  }

  /*-----------------------------------------------------------------------*\
   * 4. If at this point both 'margin-top' and 'margin-bottom' are still
   *    'auto', solve the equation under the extra constraint that the two
   *    margins must get equal values.
  \*-----------------------------------------------------------------------*/
  LayoutUnit logicalTopValue = 0;
  LayoutUnit logicalBottomValue = 0;

  if (marginBefore.isAuto() && marginAfter.isAuto()) {
    // 'top' and 'bottom' cannot be 'auto' due to step 2 and 3 combined.
    ASSERT(!(logicalTop.isAuto() || logicalBottom.isAuto()));

    logicalTopValue = valueForLength(logicalTop, containerLogicalHeight);
    logicalBottomValue = valueForLength(logicalBottom, containerLogicalHeight);

    LayoutUnit difference =
        availableSpace - (logicalTopValue + logicalBottomValue);
    // NOTE: This may result in negative values.
    marginBeforeAlias = difference / 2;  // split the difference
    marginAfterAlias =
        difference - marginBeforeAlias;  // account for odd valued differences

    /*-----------------------------------------------------------------------*\
     * 5. If at this point there is only one 'auto' left, solve the equation
     *    for that value.
    \*-----------------------------------------------------------------------*/
  } else if (logicalTop.isAuto()) {
    marginBeforeAlias =
        valueForLength(marginBefore, containerRelativeLogicalWidth);
    marginAfterAlias =
        valueForLength(marginAfter, containerRelativeLogicalWidth);
    logicalBottomValue = valueForLength(logicalBottom, containerLogicalHeight);

    // Solve for 'top'
    logicalTopValue = availableSpace - (logicalBottomValue + marginBeforeAlias +
                                        marginAfterAlias);
  } else if (logicalBottom.isAuto()) {
    marginBeforeAlias =
        valueForLength(marginBefore, containerRelativeLogicalWidth);
    marginAfterAlias =
        valueForLength(marginAfter, containerRelativeLogicalWidth);
    logicalTopValue = valueForLength(logicalTop, containerLogicalHeight);

    // Solve for 'bottom'
    // NOTE: It is not necessary to solve for 'bottom' because we don't ever
    // use the value.
  } else if (marginBefore.isAuto()) {
    marginAfterAlias =
        valueForLength(marginAfter, containerRelativeLogicalWidth);
    logicalTopValue = valueForLength(logicalTop, containerLogicalHeight);
    logicalBottomValue = valueForLength(logicalBottom, containerLogicalHeight);

    // Solve for 'margin-top'
    marginBeforeAlias = availableSpace - (logicalTopValue + logicalBottomValue +
                                          marginAfterAlias);
  } else if (marginAfter.isAuto()) {
    marginBeforeAlias =
        valueForLength(marginBefore, containerRelativeLogicalWidth);
    logicalTopValue = valueForLength(logicalTop, containerLogicalHeight);
    logicalBottomValue = valueForLength(logicalBottom, containerLogicalHeight);

    // Solve for 'margin-bottom'
    marginAfterAlias = availableSpace - (logicalTopValue + logicalBottomValue +
                                         marginBeforeAlias);
  } else {
    // Nothing is 'auto', just calculate the values.
    marginBeforeAlias =
        valueForLength(marginBefore, containerRelativeLogicalWidth);
    marginAfterAlias =
        valueForLength(marginAfter, containerRelativeLogicalWidth);
    logicalTopValue = valueForLength(logicalTop, containerLogicalHeight);
    // NOTE: It is not necessary to solve for 'bottom' because we don't ever
    // use the value.
  }

  /*-----------------------------------------------------------------------*\
   * 6. If at this point the values are over-constrained, ignore the value
   *    for 'bottom' and solve for that value.
  \*-----------------------------------------------------------------------*/
  // NOTE: It is not necessary to do this step because we don't end up using
  // the value of 'bottom' regardless of whether the values are over-constrained
  // or not.

  // Use computed values to calculate the vertical position.
  LayoutUnit logicalTopPos = logicalTopValue + marginBeforeAlias;
  computeLogicalTopPositionedOffset(logicalTopPos, this,
                                    computedValues.m_extent, containerBlock,
                                    containerLogicalHeight);
  computedValues.m_position = logicalTopPos;
}

LayoutRect RenderBox::localCaretRect(InlineBox* box,
                                     int caretOffset,
                                     LayoutUnit* extraWidthToEndOfLine) {
  // VisiblePositions at offsets inside containers either a) refer to the
  // positions before/after those containers (tables and select elements) or b)
  // refer to the position inside an empty block. They never refer to children.
  // FIXME: Paint the carets inside empty blocks differently than the carets
  // before/after elements.

  LayoutRect rect(location(), LayoutSize(caretWidth, height()));
  bool ltr =
      box ? box->isLeftToRightDirection() : style()->isLeftToRightDirection();

  if ((!caretOffset) ^ ltr)
    rect.move(LayoutSize(width() - caretWidth, 0));

  if (box) {
    RootInlineBox& rootBox = box->root();
    LayoutUnit top = rootBox.lineTop();
    rect.setY(top);
    rect.setHeight(rootBox.lineBottom() - top);
  }

  // If height of box is smaller than font height, use the latter one,
  // otherwise the caret might become invisible.
  //
  // Also, if the box is not a replaced element, always use the font height.
  // This prevents the "big caret" bug described in:
  // <rdar://problem/3777804> Deleting all content in a document can result in
  // giant tall-as-window insertion point
  //
  // FIXME: ignoring :first-line, missing good reason to take care of
  LayoutUnit fontHeight = style()->fontMetrics().height();
  if (fontHeight > rect.height() || !isReplaced())
    rect.setHeight(fontHeight);

  if (extraWidthToEndOfLine)
    *extraWidthToEndOfLine = x() + width() - rect.maxX();

  // Move to local coords
  rect.moveBy(-location());

  return rect;
}

PositionWithAffinity RenderBox::positionForPoint(const LayoutPoint& point) {
  // no children...return this render object's element, if there is one, and
  // offset 0
  RenderObject* firstChild = slowFirstChild();
  if (!firstChild)
    return createPositionWithAffinity(caretMinOffset(), DOWNSTREAM);

  // Pass off to the closest child.
  LayoutUnit minDist = LayoutUnit::max();
  RenderBox* closestRenderer = 0;
  LayoutPoint adjustedPoint = point;

  for (RenderObject* renderObject = firstChild; renderObject;
       renderObject = renderObject->nextSibling()) {
    if (!renderObject->slowFirstChild() && !renderObject->isInline() &&
        !renderObject->isRenderParagraph())
      continue;

    if (!renderObject->isBox())
      continue;

    RenderBox* renderer = toRenderBox(renderObject);

    LayoutUnit top =
        renderer->borderTop() + renderer->paddingTop() + renderer->y();
    LayoutUnit bottom = top + renderer->contentHeight();
    LayoutUnit left =
        renderer->borderLeft() + renderer->paddingLeft() + renderer->x();
    LayoutUnit right = left + renderer->contentWidth();

    if (point.x() <= right && point.x() >= left && point.y() <= top &&
        point.y() >= bottom)
      return renderer->positionForPoint(point - renderer->locationOffset());

    // Find the distance from (x, y) to the box.  Split the space around the box
    // into 8 pieces and use a different compare depending on which piece (x, y)
    // is in.
    LayoutPoint cmp;
    if (point.x() > right) {
      if (point.y() < top)
        cmp = LayoutPoint(right, top);
      else if (point.y() > bottom)
        cmp = LayoutPoint(right, bottom);
      else
        cmp = LayoutPoint(right, point.y());
    } else if (point.x() < left) {
      if (point.y() < top)
        cmp = LayoutPoint(left, top);
      else if (point.y() > bottom)
        cmp = LayoutPoint(left, bottom);
      else
        cmp = LayoutPoint(left, point.y());
    } else {
      if (point.y() < top)
        cmp = LayoutPoint(point.x(), top);
      else
        cmp = LayoutPoint(point.x(), bottom);
    }

    LayoutSize difference = cmp - point;

    LayoutUnit dist = difference.width() * difference.width() +
                      difference.height() * difference.height();
    if (dist < minDist) {
      closestRenderer = renderer;
      minDist = dist;
    }
  }

  if (closestRenderer)
    return closestRenderer->positionForPoint(adjustedPoint -
                                             closestRenderer->locationOffset());
  return createPositionWithAffinity(caretMinOffset(), DOWNSTREAM);
}

void RenderBox::addVisualEffectOverflow() {
  if (!style()->hasVisualOverflowingEffect())
    return;

  // Add in the final overflow with shadows, outsets and outline combined.
  LayoutRect visualEffectOverflow = borderBoxRect();
  visualEffectOverflow.expand(computeVisualEffectOverflowExtent());
  addVisualOverflow(visualEffectOverflow);
}

LayoutBoxExtent RenderBox::computeVisualEffectOverflowExtent() const {
  ASSERT(style()->hasVisualOverflowingEffect());

  LayoutUnit top;
  LayoutUnit right;
  LayoutUnit bottom;
  LayoutUnit left;

  if (style()->boxShadow()) {
    style()->getBoxShadowExtent(top, right, bottom, left);

    // Box shadow extent's top and left are negative when extend to left and top
    // direction, respectively. Negate to make them positive.
    top = -top;
    left = -left;
  }

  if (style()->hasOutline()) {
    if (style()->outlineStyleIsAuto()) {
      // The result focus ring rects are in coordinates of this object's border
      // box.
      Vector<IntRect> focusRingRects;
      addFocusRingRects(focusRingRects, LayoutPoint(), this);
      IntRect rect = unionRect(focusRingRects);

      int outlineSize = GraphicsContext::focusRingOutsetExtent(
          style()->outlineOffset(), style()->outlineWidth());
      top = std::max<LayoutUnit>(top, -rect.y() + outlineSize);
      right = std::max<LayoutUnit>(right, rect.maxX() - width() + outlineSize);
      bottom =
          std::max<LayoutUnit>(bottom, rect.maxY() - height() + outlineSize);
      left = std::max<LayoutUnit>(left, -rect.x() + outlineSize);
    } else {
      LayoutUnit outlineSize = style()->outlineSize();
      top = std::max(top, outlineSize);
      right = std::max(right, outlineSize);
      bottom = std::max(bottom, outlineSize);
      left = std::max(left, outlineSize);
    }
  }

  return LayoutBoxExtent(top, right, bottom, left);
}

void RenderBox::addOverflowFromChild(RenderBox* child,
                                     const LayoutSize& delta) {
  // Only propagate layout overflow from the child if the child isn't clipping
  // its overflow.  If it is, then its overflow is internal to it, and we don't
  // care about it.  layoutOverflowRectForPropagation takes care of this and
  // just propagates the border box rect instead.
  LayoutRect childLayoutOverflowRect =
      child->layoutOverflowRectForPropagation();
  childLayoutOverflowRect.move(delta);
  addLayoutOverflow(childLayoutOverflowRect);

  // Add in visual overflow from the child.  Even if the child clips its
  // overflow, it may still have visual overflow of its own set from box shadows
  // or reflections.  It is unnecessary to propagate this overflow if we are
  // clipping our own overflow.
  if (child->hasSelfPaintingLayer())
    return;
  LayoutRect childVisualOverflowRect = child->visualOverflowRect();
  childVisualOverflowRect.move(delta);
  addContentsVisualOverflow(childVisualOverflowRect);
}

void RenderBox::addLayoutOverflow(const LayoutRect& rect) {
  LayoutRect clientBox = paddingBoxRect();
  if (clientBox.contains(rect) || rect.isEmpty())
    return;

  // For overflow clip objects, we don't want to propagate overflow into
  // unreachable areas.
  LayoutRect overflowRect(rect);
  if (hasOverflowClip() || isRenderView()) {
    // Overflow is in the block's coordinate space and thus is flipped for
    // horizontal-bt and vertical-rl writing modes.  At this stage that is
    // actually a simplification, since we can treat horizontal-tb/bt as the
    // same and vertical-lr/rl as the same.
    bool hasTopOverflow = false;
    bool hasLeftOverflow = !style()->isLeftToRightDirection();
    if (isFlexibleBox() && style()->isReverseFlexDirection()) {
      RenderFlexibleBox* flexibleBox = toRenderFlexibleBox(this);
      if (flexibleBox->isHorizontalFlow())
        hasLeftOverflow = true;
      else
        hasTopOverflow = true;
    }

    if (!hasTopOverflow)
      overflowRect.shiftYEdgeTo(std::max(overflowRect.y(), clientBox.y()));
    else
      overflowRect.shiftMaxYEdgeTo(
          std::min(overflowRect.maxY(), clientBox.maxY()));
    if (!hasLeftOverflow)
      overflowRect.shiftXEdgeTo(std::max(overflowRect.x(), clientBox.x()));
    else
      overflowRect.shiftMaxXEdgeTo(
          std::min(overflowRect.maxX(), clientBox.maxX()));

    // Now re-test with the adjusted rectangle and see if it has become
    // unreachable or fully contained.
    if (clientBox.contains(overflowRect) || overflowRect.isEmpty())
      return;
  }

  if (!m_overflow)
    m_overflow = adoptPtr(new RenderOverflow(clientBox, borderBoxRect()));

  m_overflow->addLayoutOverflow(overflowRect);
}

void RenderBox::addVisualOverflow(const LayoutRect& rect) {
  LayoutRect borderBox = borderBoxRect();
  if (borderBox.contains(rect) || rect.isEmpty())
    return;

  if (!m_overflow)
    m_overflow = adoptPtr(new RenderOverflow(paddingBoxRect(), borderBox));

  m_overflow->addVisualOverflow(rect);
}

void RenderBox::addContentsVisualOverflow(const LayoutRect& rect) {
  if (!hasOverflowClip()) {
    addVisualOverflow(rect);
    return;
  }

  if (!m_overflow)
    m_overflow =
        adoptPtr(new RenderOverflow(paddingBoxRect(), borderBoxRect()));
  m_overflow->addContentsVisualOverflow(rect);
}

void RenderBox::clearLayoutOverflow() {
  if (!m_overflow)
    return;

  if (!hasVisualOverflow() && contentsVisualOverflowRect().isEmpty()) {
    clearAllOverflows();
    return;
  }

  m_overflow->setLayoutOverflow(paddingBoxRect());
}

LayoutUnit RenderBox::lineHeight(bool /*firstLine*/,
                                 LineDirectionMode direction,
                                 LinePositionMode /*linePositionMode*/) const {
  if (isReplaced())
    return direction == HorizontalLine
               ? m_marginBox.top() + height() + m_marginBox.bottom()
               : m_marginBox.right() + width() + m_marginBox.left();
  return 0;
}

int RenderBox::baselinePosition(FontBaseline baselineType,
                                bool /*firstLine*/,
                                LineDirectionMode direction,
                                LinePositionMode linePositionMode) const {
  ASSERT(linePositionMode == PositionOnContainingLine);
  if (isReplaced()) {
    int result = direction == HorizontalLine
                     ? m_marginBox.top() + height() + m_marginBox.bottom()
                     : m_marginBox.right() + width() + m_marginBox.left();
    if (baselineType == AlphabeticBaseline)
      return result;
    return result - result / 2;
  }
  return 0;
}

RenderLayer* RenderBox::enclosingFloatPaintingLayer() const {
  const RenderObject* curr = this;
  while (curr) {
    RenderLayer* layer =
        curr->hasLayer() && curr->isBox() ? toRenderBox(curr)->layer() : 0;
    if (layer && layer->isSelfPaintingLayer())
      return layer;
    curr = curr->parent();
  }
  return 0;
}

LayoutRect RenderBox::layoutOverflowRectForPropagation() const {
  // Only propagate interior layout overflow if we don't clip it.
  LayoutRect rect = borderBoxRect();
  rect.expand(LayoutSize(LayoutUnit(), marginAfter()));

  if (!hasOverflowClip())
    rect.unite(layoutOverflowRect());

  if (transform())
    rect = transform()->mapRect(rect);

  return rect;
}

LayoutUnit RenderBox::offsetLeft() const {
  return adjustedPositionRelativeToOffsetParent(location()).x();
}

LayoutUnit RenderBox::offsetTop() const {
  return adjustedPositionRelativeToOffsetParent(location()).y();
}

bool RenderBox::hasRelativeLogicalHeight() const {
  return style()->logicalHeight().isPercent() ||
         style()->logicalMinHeight().isPercent() ||
         style()->logicalMaxHeight().isPercent();
}

RenderBox::BoxDecorationData::BoxDecorationData(const RenderStyle& style) {
  backgroundColor = style.resolveColor(style.backgroundColor());
  hasBackground = backgroundColor.alpha() || style.hasBackgroundImage();
  ASSERT(hasBackground == style.hasBackground());
  hasBorder = style.hasBorder();
}

}  // namespace blink
