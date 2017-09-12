/*
 * Copyright (C) 2006, 2007, 2008, 2009, 2010, 2011, 2012 Apple Inc.
 * All rights reserved.
 *
 * Portions are Copyright (C) 1998 Netscape Communications Corporation.
 *
 * Other contributors:
 *   Robert O'Callahan <roc+@cs.cmu.edu>
 *   David Baron <dbaron@fas.harvard.edu>
 *   Christian Biesinger <cbiesinger@web.de>
 *   Randall Jesup <rjesup@wgate.com>
 *   Roland Mainz <roland.mainz@informatik.med.uni-giessen.de>
 *   Josh Soref <timeless@mac.com>
 *   Boris Zbarsky <bzbarsky@mit.edu>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA
 *
 * Alternatively, the contents of this file may be used under the terms
 * of either the Mozilla Public License Version 1.1, found at
 * http://www.mozilla.org/MPL/ (the "MPL") or the GNU General Public
 * License Version 2.0, found at http://www.fsf.org/copyleft/gpl.html
 * (the "GPL"), in which case the provisions of the MPL or the GPL are
 * applicable instead of those above.  If you wish to allow use of your
 * version of this file only under the terms of one of those two
 * licenses (the MPL or the GPL) and not to allow others to use your
 * version of this file under the LGPL, indicate your decision by
 * deletingthe provisions above and replace them with the notice and
 * other provisions required by the MPL or the GPL, as the case may be.
 * If you do not delete the provisions above, a recipient may use your
 * version of this file under any of the LGPL, the MPL or the GPL.
 */

#include "flutter/sky/engine/core/rendering/RenderLayer.h"

#include "flutter/sky/engine/core/rendering/HitTestRequest.h"
#include "flutter/sky/engine/core/rendering/HitTestResult.h"
#include "flutter/sky/engine/core/rendering/HitTestingTransformState.h"
#include "flutter/sky/engine/core/rendering/RenderGeometryMap.h"
#include "flutter/sky/engine/core/rendering/RenderInline.h"
#include "flutter/sky/engine/core/rendering/RenderTreeAsText.h"
#include "flutter/sky/engine/core/rendering/RenderView.h"
#include "flutter/sky/engine/platform/LengthFunctions.h"
#include "flutter/sky/engine/platform/Partitions.h"
#include "flutter/sky/engine/platform/geometry/FloatPoint3D.h"
#include "flutter/sky/engine/platform/geometry/FloatRect.h"
#include "flutter/sky/engine/platform/geometry/TransformState.h"
#include "flutter/sky/engine/platform/graphics/GraphicsContextStateSaver.h"
#include "flutter/sky/engine/platform/transforms/ScaleTransformOperation.h"
#include "flutter/sky/engine/platform/transforms/TransformationMatrix.h"
#include "flutter/sky/engine/platform/transforms/TranslateTransformOperation.h"
#include "flutter/sky/engine/public/platform/Platform.h"
#include "flutter/sky/engine/wtf/StdLibExtras.h"
#include "flutter/sky/engine/wtf/text/CString.h"

namespace blink {

RenderLayer::RenderLayer(RenderBox* renderer, LayerType type)
    : m_layerType(type),
      m_isRootLayer(renderer->isRenderView()),
      m_3DTransformedDescendantStatusDirty(true),
      m_has3DTransformedDescendant(false),
      m_renderer(renderer),
      m_parent(0),
      m_previous(0),
      m_next(0),
      m_first(0),
      m_last(0),
      m_clipper(*renderer) {
  m_stackingNode = adoptPtr(new RenderLayerStackingNode(this));
  m_isSelfPaintingLayer = shouldBeSelfPaintingLayer();
}

RenderLayer::~RenderLayer() {}

void RenderLayer::updateLayerPositionsAfterLayout() {
  m_clipper.clearClipRectsIncludingDescendants();
}

void RenderLayer::dirty3DTransformedDescendantStatus() {
  RenderLayerStackingNode* stackingNode =
      m_stackingNode->ancestorStackingContextNode();
  if (!stackingNode)
    return;

  stackingNode->layer()->m_3DTransformedDescendantStatusDirty = true;

  // This propagates up through preserve-3d hierarchies to the enclosing
  // flattening layer. Note that preserves3D() creates stacking context, so we
  // can just run up the stacking containers.
  while (stackingNode &&
         stackingNode->layer()->renderer()->style()->preserves3D()) {
    stackingNode->layer()->m_3DTransformedDescendantStatusDirty = true;
    stackingNode = stackingNode->ancestorStackingContextNode();
  }
}

// Return true if this layer or any preserve-3d descendants have 3d.
bool RenderLayer::update3DTransformedDescendantStatus() {
  if (m_3DTransformedDescendantStatusDirty) {
    m_has3DTransformedDescendant = false;

    m_stackingNode->updateZOrderLists();

    // Transformed or preserve-3d descendants can only be in the z-order lists,
    // not in the normal flow list, so we only need to check those.
    RenderLayerStackingNodeIterator iterator(*m_stackingNode.get(),
                                             PositiveZOrderChildren);
    while (RenderLayerStackingNode* node = iterator.next())
      m_has3DTransformedDescendant |=
          node->layer()->update3DTransformedDescendantStatus();

    m_3DTransformedDescendantStatusDirty = false;
  }

  // If we live in a 3d hierarchy, then the layer at the root of that hierarchy
  // needs the m_has3DTransformedDescendant set.
  if (renderer()->style()->preserves3D())
    return renderer()->has3DTransform() || m_has3DTransformedDescendant;

  return renderer()->has3DTransform();
}

IntSize RenderLayer::size() const {
  // FIXME: Is snapping the size really needed here?
  RenderBox* box = renderer();
  return pixelSnappedIntSize(box->size(), box->location());
}

LayoutPoint RenderLayer::location() const {
  LayoutPoint localPoint;
  LayoutSize inlineBoundingBoxOffset;  // We don't put this into the RenderLayer
                                       // x/y for inlines, so we need to
                                       // subtract it out when done.

  if (renderer()->isInline() && renderer()->isRenderInline()) {
    RenderInline* inlineFlow = toRenderInline(renderer());
    IntRect lineBox = inlineFlow->linesBoundingBox();
    inlineBoundingBoxOffset = toSize(lineBox.location());
    localPoint += inlineBoundingBoxOffset;
  } else {
    localPoint += renderer()->locationOffset();
  }

  if (!renderer()->isOutOfFlowPositioned() && renderer()->parent()) {
    // We must adjust our position by walking up the render tree looking for the
    // nearest enclosing object with a layer.
    RenderObject* curr = renderer()->parent();
    while (curr && !curr->hasLayer()) {
      if (curr->isBox()) {
        // Rows and cells share the same coordinate space (that of the section).
        // Omit them when computing our xpos/ypos.
        localPoint += toRenderBox(curr)->locationOffset();
      }
      curr = curr->parent();
    }
  }

  // FIXME: We'd really like to just get rid of the concept of a layer rectangle
  // and rely on the renderers.
  localPoint -= inlineBoundingBoxOffset;

  return localPoint;
}

RenderLayer* RenderLayer::enclosingPositionedAncestor() const {
  RenderLayer* curr = parent();
  while (curr && !curr->isPositionedContainer())
    curr = curr->parent();

  return curr;
}

const RenderLayer* RenderLayer::compositingContainer() const {
  if (stackingNode()->isNormalFlowOnly())
    return parent();
  if (RenderLayerStackingNode* ancestorStackingNode =
          stackingNode()->ancestorStackingContextNode())
    return ancestorStackingNode->layer();
  return 0;
}

void* RenderLayer::operator new(size_t sz) {
  return partitionAlloc(Partitions::getRenderingPartition(), sz);
}

void RenderLayer::operator delete(void* ptr) {
  partitionFree(ptr);
}

void RenderLayer::addChild(RenderLayer* child, RenderLayer* beforeChild) {
  RenderLayer* prevSibling =
      beforeChild ? beforeChild->previousSibling() : lastChild();
  if (prevSibling) {
    child->setPreviousSibling(prevSibling);
    prevSibling->setNextSibling(child);
    ASSERT(prevSibling != child);
  } else
    setFirstChild(child);

  if (beforeChild) {
    beforeChild->setPreviousSibling(child);
    child->setNextSibling(beforeChild);
    ASSERT(beforeChild != child);
  } else
    setLastChild(child);

  child->m_parent = this;

  if (child->stackingNode()->isNormalFlowOnly())
    m_stackingNode->dirtyNormalFlowList();

  if (!child->stackingNode()->isNormalFlowOnly() || child->firstChild()) {
    // Dirty the z-order list in which we are contained. The
    // ancestorStackingContextNode() can be null in the case where we're
    // building up generated content layers. This is ok, since the lists will
    // start off dirty in that case anyway.
    child->stackingNode()->dirtyStackingContextZOrderLists();
  }
}

RenderLayer* RenderLayer::removeChild(RenderLayer* oldChild) {
  if (oldChild->previousSibling())
    oldChild->previousSibling()->setNextSibling(oldChild->nextSibling());
  if (oldChild->nextSibling())
    oldChild->nextSibling()->setPreviousSibling(oldChild->previousSibling());

  if (m_first == oldChild)
    m_first = oldChild->nextSibling();
  if (m_last == oldChild)
    m_last = oldChild->previousSibling();

  if (oldChild->stackingNode()->isNormalFlowOnly())
    m_stackingNode->dirtyNormalFlowList();
  if (!oldChild->stackingNode()->isNormalFlowOnly() || oldChild->firstChild()) {
    // Dirty the z-order list in which we are contained.  When called via the
    // reattachment process in removeOnlyThisLayer, the layer may already be
    // disconnected from the main layer tree, so we need to null-check the
    // |stackingContext| value.
    oldChild->stackingNode()->dirtyStackingContextZOrderLists();
  }

  oldChild->setPreviousSibling(0);
  oldChild->setNextSibling(0);
  oldChild->m_parent = 0;

  return oldChild;
}

void RenderLayer::removeOnlyThisLayer() {
  if (!m_parent)
    return;

  m_clipper.clearClipRectsIncludingDescendants();

  RenderLayer* nextSib = nextSibling();

  // Now walk our kids and reattach them to our parent.
  RenderLayer* current = m_first;
  while (current) {
    RenderLayer* next = current->nextSibling();
    removeChild(current);
    m_parent->addChild(current, nextSib);

    // FIXME: We should call a specialized version of this function.
    current->updateLayerPositionsAfterLayout();
    current = next;
  }

  // Remove us from the parent.
  m_parent->removeChild(this);
  m_renderer->destroyLayer();
}

void RenderLayer::insertOnlyThisLayer() {
  if (!m_parent && renderer()->parent()) {
    // We need to connect ourselves when our renderer() has a parent.
    // Find our enclosingLayer and add ourselves.
    RenderLayer* parentLayer = renderer()->parent()->enclosingLayer();
    ASSERT(parentLayer);
    RenderLayer* beforeChild =
        renderer()->parent()->findNextLayer(parentLayer, renderer());
    parentLayer->addChild(this, beforeChild);
  }

  // Remove all descendant layers from the hierarchy and add them to the new
  // position.
  for (RenderObject* curr = renderer()->slowFirstChild(); curr;
       curr = curr->nextSibling())
    curr->moveLayers(m_parent, this);

  // Clear out all the clip rects.
  m_clipper.clearClipRectsIncludingDescendants();
}

// Returns the layer reached on the walk up towards the ancestor.
static inline const RenderLayer* accumulateOffsetTowardsAncestor(
    const RenderLayer* layer,
    const RenderLayer* ancestorLayer,
    LayoutPoint& location) {
  ASSERT(ancestorLayer != layer);

  const RenderBox* renderer = layer->renderer();
  EPosition position = renderer->style()->position();

  RenderLayer* parentLayer;
  if (position == AbsolutePosition) {
    // Do what enclosingPositionedAncestor() does, but check for ancestorLayer
    // along the way.
    parentLayer = layer->parent();
    bool foundAncestorFirst = false;
    while (parentLayer) {
      // RenderFlowThread is a positioned container, child of RenderView,
      // positioned at (0,0). This implies that, for out-of-flow positioned
      // elements inside a RenderFlowThread, we are bailing out before reaching
      // root layer.
      if (parentLayer->isPositionedContainer())
        break;

      if (parentLayer == ancestorLayer) {
        foundAncestorFirst = true;
        break;
      }

      parentLayer = parentLayer->parent();
    }

    if (foundAncestorFirst) {
      // Found ancestorLayer before the abs. positioned container, so compute
      // offset of both relative to enclosingPositionedAncestor and subtract.
      RenderLayer* positionedAncestor =
          parentLayer->enclosingPositionedAncestor();

      LayoutPoint thisCoords;
      layer->convertToLayerCoords(positionedAncestor, thisCoords);

      LayoutPoint ancestorCoords;
      ancestorLayer->convertToLayerCoords(positionedAncestor, ancestorCoords);

      location += (thisCoords - ancestorCoords);
      return ancestorLayer;
    }
  } else
    parentLayer = layer->parent();

  if (!parentLayer)
    return 0;

  location += toSize(layer->location());
  return parentLayer;
}

void RenderLayer::convertToLayerCoords(const RenderLayer* ancestorLayer,
                                       LayoutPoint& location) const {
  if (ancestorLayer == this)
    return;

  const RenderLayer* currLayer = this;
  while (currLayer && currLayer != ancestorLayer)
    currLayer =
        accumulateOffsetTowardsAncestor(currLayer, ancestorLayer, location);
}

void RenderLayer::convertToLayerCoords(const RenderLayer* ancestorLayer,
                                       LayoutRect& rect) const {
  LayoutPoint delta;
  convertToLayerCoords(ancestorLayer, delta);
  rect.move(-delta.x(), -delta.y());
}

void RenderLayer::clipToRect(const LayerPaintingInfo& localPaintingInfo,
                             GraphicsContext* context,
                             const ClipRect& clipRect,
                             BorderRadiusClippingRule rule) {
  if (clipRect.rect() == localPaintingInfo.paintDirtyRect &&
      !clipRect.hasRadius())
    return;
  context->save();
  context->clip(pixelSnappedIntRect(clipRect.rect()));
}

void RenderLayer::restoreClip(GraphicsContext* context,
                              const LayoutRect& paintDirtyRect,
                              const ClipRect& clipRect) {
  if (clipRect.rect() == paintDirtyRect && !clipRect.hasRadius())
    return;
  context->restore();
}

bool RenderLayer::intersectsDamageRect(
    const LayoutRect& layerBounds,
    const LayoutRect& damageRect,
    const RenderLayer* rootLayer,
    const LayoutPoint* offsetFromRoot) const {
  // Always examine the canvas and the root.
  if (isRootLayer())
    return true;

  // Otherwise we need to compute the bounding box of this single layer and see
  // if it intersects the damage rect.
  return physicalBoundingBox(rootLayer, offsetFromRoot).intersects(damageRect);
}

LayoutRect RenderLayer::logicalBoundingBox() const {
  // There are three special cases we need to consider.
  // (1) Inline Flows.  For inline flows we will create a bounding box that
  // fully encompasses all of the lines occupied by the inline.  In other words,
  // if some <span> wraps to three lines, we'll create a bounding box that fully
  // encloses the line boxes of all three lines (including overflow on those
  // lines). (2) Left/Top Overflow.  The width/height of layers already includes
  // right/bottom overflow.  However, in the case of left/top overflow, we have
  // to create a bounding box that will extend to include this overflow. (3)
  // Floats.  When a layer has overhanging floats that it paints, we need to
  // make sure to include these overhanging floats as part of our bounding box.
  // We do this because we are the responsible layer for both hit testing and
  // painting those floats.
  LayoutRect result;
  if (renderer()->isInline() && renderer()->isRenderInline()) {
    result = toRenderInline(renderer())->linesVisualOverflowBoundingBox();
  } else {
    RenderBox* box = renderer();
    result = box->borderBoxRect();
    result.unite(box->visualOverflowRect());
  }

  return result;
}

LayoutRect RenderLayer::physicalBoundingBox(
    const RenderLayer* ancestorLayer,
    const LayoutPoint* offsetFromRoot) const {
  LayoutPoint delta;
  if (offsetFromRoot)
    delta = *offsetFromRoot;
  else
    convertToLayerCoords(ancestorLayer, delta);

  LayoutRect result = logicalBoundingBox();
  result.moveBy(delta);
  return result;
}

static void expandRectForReflectionAndStackingChildren(
    const RenderLayer* ancestorLayer,
    LayoutRect& result) {
  ASSERT(ancestorLayer->stackingNode()->isStackingContext() ||
         !ancestorLayer->stackingNode()->hasPositiveZOrderList());

#if ENABLE(ASSERT)
  LayerListMutationDetector mutationChecker(
      const_cast<RenderLayer*>(ancestorLayer)->stackingNode());
#endif

  RenderLayerStackingNodeIterator iterator(*ancestorLayer->stackingNode(),
                                           AllChildren);
  while (RenderLayerStackingNode* node = iterator.next()) {
    result.unite(node->layer()->boundingBoxForCompositing(ancestorLayer));
  }
}

LayoutRect
RenderLayer::physicalBoundingBoxIncludingReflectionAndStackingChildren(
    const RenderLayer* ancestorLayer,
    const LayoutPoint& offsetFromRoot) const {
  LayoutPoint origin;
  LayoutRect result = physicalBoundingBox(ancestorLayer, &origin);

  const_cast<RenderLayer*>(this)->stackingNode()->updateLayerListsIfNeeded();

  expandRectForReflectionAndStackingChildren(this, result);

  result.moveBy(offsetFromRoot);
  return result;
}

LayoutRect RenderLayer::boundingBoxForCompositing(
    const RenderLayer* ancestorLayer) const {
  if (!isSelfPaintingLayer())
    return LayoutRect();

  if (!ancestorLayer)
    ancestorLayer = this;

  LayoutRect localClipRect = clipper().localClipRect();
  if (localClipRect != PaintInfo::infiniteRect()) {
    if (renderer()->transform())
      localClipRect = renderer()->transform()->mapRect(localClipRect);

    LayoutPoint delta;
    convertToLayerCoords(ancestorLayer, delta);
    localClipRect.moveBy(delta);
    return localClipRect;
  }

  LayoutPoint origin;
  LayoutRect result = physicalBoundingBox(ancestorLayer, &origin);

  const_cast<RenderLayer*>(this)->stackingNode()->updateLayerListsIfNeeded();

  expandRectForReflectionAndStackingChildren(this, result);

  if (renderer()->transform())
    result = renderer()->transform()->mapRect(result);

  LayoutPoint delta;
  convertToLayerCoords(ancestorLayer, delta);
  result.moveBy(delta);
  return result;
}

bool RenderLayer::shouldBeSelfPaintingLayer() const {
  return m_layerType == NormalLayer;
}

void RenderLayer::styleChanged(StyleDifference diff,
                               const RenderStyle* oldStyle) {
  m_stackingNode->updateIsNormalFlowOnly();
  m_stackingNode->updateStackingNodesAfterStyleChange(oldStyle);

  // Overlay scrollbars can make this layer self-painting so we need
  // to recompute the bit once scrollbars have been updated.
  m_isSelfPaintingLayer = shouldBeSelfPaintingLayer();
}

}  // namespace blink
