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

#include "flutter/sky/engine/core/rendering/RenderLayerClipper.h"

#include "flutter/sky/engine/core/rendering/RenderLayer.h"
#include "flutter/sky/engine/core/rendering/RenderView.h"

namespace blink {

RenderLayerClipper::RenderLayerClipper(RenderBox& renderer)
    : m_renderer(renderer) {}

ClipRects* RenderLayerClipper::clipRectsIfCached(
    const ClipRectsContext& context) const {
  ASSERT(context.usesCache());
  if (!m_cache)
    return 0;
  ClipRectsCache::Entry& entry = m_cache->get(context.cacheSlot);
  // FIXME: We used to ASSERT that we always got a consistent root layer.
  // We should add a test that has an inconsistent root. See
  // http://crbug.com/366118 for an example.
  if (context.rootLayer != entry.root)
    return 0;

#ifdef CHECK_CACHED_CLIP_RECTS
  // This code is useful to check cached clip rects, but is too expensive to
  // leave enabled in debug builds by default.
  ClipRectsContext tempContext(context);
  tempContext.cacheSlot = UncachedClipRects;
  ClipRects clipRects;
  calculateClipRects(tempContext, clipRects);
  ASSERT(clipRects == *entry.clipRects);
#endif

  return entry.clipRects.get();
}

ClipRects* RenderLayerClipper::storeClipRectsInCache(
    const ClipRectsContext& context,
    ClipRects* parentClipRects,
    const ClipRects& clipRects) const {
  ClipRectsCache::Entry& entry = cache().get(context.cacheSlot);
  entry.root = context.rootLayer;

  if (parentClipRects) {
    // If our clip rects match the clip rects of our parent, we share storage.
    if (clipRects == *parentClipRects) {
      entry.clipRects = parentClipRects;
      return parentClipRects;
    }
  }

  entry.clipRects = ClipRects::create(clipRects);
  return entry.clipRects.get();
}

ClipRects* RenderLayerClipper::getClipRects(
    const ClipRectsContext& context) const {
  if (ClipRects* result = clipRectsIfCached(context))
    return result;

  // Note that it's important that we call getClipRects on our parent
  // before we call calculateClipRects so that calculateClipRects will hit
  // the cache.
  ClipRects* parentClipRects = 0;
  if (context.rootLayer != m_renderer.layer() && m_renderer.layer()->parent())
    parentClipRects =
        m_renderer.layer()->parent()->clipper().getClipRects(context);

  ClipRects clipRects;
  calculateClipRects(context, clipRects);
  return storeClipRectsInCache(context, parentClipRects, clipRects);
}

void RenderLayerClipper::clearClipRectsIncludingDescendants() {
  m_cache = nullptr;

  for (RenderLayer* layer = m_renderer.layer()->firstChild(); layer;
       layer = layer->nextSibling())
    layer->clipper().clearClipRectsIncludingDescendants();
}

void RenderLayerClipper::clearClipRectsIncludingDescendants(
    ClipRectsCacheSlot cacheSlot) {
  if (m_cache)
    m_cache->clear(cacheSlot);

  for (RenderLayer* layer = m_renderer.layer()->firstChild(); layer;
       layer = layer->nextSibling())
    layer->clipper().clearClipRectsIncludingDescendants(cacheSlot);
}

LayoutRect RenderLayerClipper::localClipRect() const {
  // FIXME: border-radius not accounted for.
  RenderLayer* clippingRootLayer = clippingRootForPainting();
  LayoutRect layerBounds;
  ClipRect backgroundRect;
  ClipRectsContext context(clippingRootLayer, PaintingClipRects);
  calculateRects(context, PaintInfo::infiniteRect(), layerBounds,
                 backgroundRect);

  LayoutRect clipRect = backgroundRect.rect();
  if (clipRect == PaintInfo::infiniteRect())
    return clipRect;

  LayoutPoint clippingRootOffset;
  m_renderer.layer()->convertToLayerCoords(clippingRootLayer,
                                           clippingRootOffset);
  clipRect.moveBy(-clippingRootOffset);

  return clipRect;
}

void RenderLayerClipper::calculateRects(
    const ClipRectsContext& context,
    const LayoutRect& paintDirtyRect,
    LayoutRect& layerBounds,
    ClipRect& backgroundRect,
    const LayoutPoint* offsetFromRoot) const {
  bool isClippingRoot = m_renderer.layer() == context.rootLayer;

  if (!isClippingRoot && m_renderer.layer()->parent()) {
    backgroundRect = backgroundClipRect(context);
    backgroundRect.move(roundedIntSize(context.subPixelAccumulation));
    backgroundRect.intersect(paintDirtyRect);
  } else {
    backgroundRect = paintDirtyRect;
  }

  LayoutPoint offset;
  if (offsetFromRoot)
    offset = *offsetFromRoot;
  else
    m_renderer.layer()->convertToLayerCoords(context.rootLayer, offset);
  layerBounds = LayoutRect(offset, m_renderer.layer()->size());

  // Update the clip rects that will be passed to child layers.
  if (m_renderer.hasOverflowClip()) {
    // If we establish an overflow clip at all, then go ahead and make sure our
    // background rect is intersected with our layer's bounds including our
    // visual overflow, since any visual overflow like box-shadow or
    // border-outset is not clipped by overflow:auto/hidden.
    if (m_renderer.hasVisualOverflow()) {
      // FIXME: Perhaps we should be propagating the borderbox as the clip rect
      // for children, even though
      //        we may need to inflate our clip specifically for shadows or
      //        outsets.
      // FIXME: Does not do the right thing with CSS regions yet, since we don't
      // yet factor in the individual region boxes as overflow.
      LayoutRect layerBoundsWithVisualOverflow =
          m_renderer.visualOverflowRect();
      layerBoundsWithVisualOverflow.moveBy(offset);
      backgroundRect.intersect(layerBoundsWithVisualOverflow);
    } else {
      LayoutRect bounds = m_renderer.borderBoxRect();
      bounds.moveBy(offset);
      backgroundRect.intersect(bounds);
    }
  }

  // CSS clip (different than clipping due to overflow) can clip to any box,
  // even if it falls outside of the border box.
  if (m_renderer.hasClip()) {
    // Clip applies to *us* as well, so go ahead and update the damageRect.
    LayoutRect newPosClip = m_renderer.clipRect(offset);
    backgroundRect.intersect(newPosClip);
  }
}

void RenderLayerClipper::calculateClipRects(const ClipRectsContext& context,
                                            ClipRects& clipRects) const {
  if (!m_renderer.layer()->parent()) {
    // The root layer's clip rect is always infinite.
    clipRects.reset(PaintInfo::infiniteRect());
    return;
  }

  bool isClippingRoot = m_renderer.layer() == context.rootLayer;

  // For transformed layers, the root layer was shifted to be us, so there is no
  // need to examine the parent. We want to cache clip rects with us as the
  // root.
  RenderLayer* parentLayer = !isClippingRoot ? m_renderer.layer()->parent() : 0;

  // Ensure that our parent's clip has been calculated so that we can examine
  // the values.
  if (parentLayer) {
    // FIXME: Why don't we just call getClipRects here?
    if (context.usesCache() &&
        parentLayer->clipper().cachedClipRects(context)) {
      clipRects = *parentLayer->clipper().cachedClipRects(context);
    } else {
      parentLayer->clipper().calculateClipRects(context, clipRects);
    }
  } else {
    clipRects.reset(PaintInfo::infiniteRect());
  }

  if (m_renderer.style()->position() == AbsolutePosition) {
    clipRects.setOverflowClipRect(clipRects.posClipRect());
  }

  // This offset cannot use convertToLayerCoords, because sometimes our
  // rootLayer may be across some transformed layer boundary, for example, in
  // the RenderLayerCompositor overlapMap, where clipRects are needed in view
  // space.
  LayoutPoint offset = roundedLayoutPoint(m_renderer.localToContainerPoint(
      FloatPoint(), context.rootLayer->renderer()));
  if (m_renderer.hasOverflowClip()) {
    ClipRect newOverflowClip = m_renderer.overflowClipRect(offset);
    newOverflowClip.setHasRadius(m_renderer.style()->hasBorderRadius());
    clipRects.setOverflowClipRect(
        intersection(newOverflowClip, clipRects.overflowClipRect()));
    if (m_renderer.isPositioned())
      clipRects.setPosClipRect(
          intersection(newOverflowClip, clipRects.posClipRect()));
  }

  if (m_renderer.hasClip()) {
    LayoutRect newClip = m_renderer.clipRect(offset);
    clipRects.setPosClipRect(intersection(newClip, clipRects.posClipRect()));
    clipRects.setOverflowClipRect(
        intersection(newClip, clipRects.overflowClipRect()));
  }
}

ClipRect RenderLayerClipper::backgroundClipRect(
    const ClipRectsContext& context) const {
  ASSERT(m_renderer.layer()->parent());

  ClipRects parentClipRects;
  if (m_renderer.layer() == context.rootLayer)
    parentClipRects.reset(PaintInfo::infiniteRect());
  else
    m_renderer.layer()->parent()->clipper().getOrCalculateClipRects(
        context, parentClipRects);

  if (m_renderer.style()->position() == AbsolutePosition)
    return parentClipRects.posClipRect();
  return parentClipRects.overflowClipRect();
}

void RenderLayerClipper::getOrCalculateClipRects(
    const ClipRectsContext& context,
    ClipRects& clipRects) const {
  if (context.usesCache())
    clipRects = *getClipRects(context);
  else
    calculateClipRects(context, clipRects);
}

RenderLayer* RenderLayerClipper::clippingRootForPainting() const {
  const RenderLayer* current = m_renderer.layer();
  while (current) {
    if (current->isRootLayer())
      return const_cast<RenderLayer*>(current);

    current = current->compositingContainer();
    ASSERT(current);
    if (current->renderer()->transform())
      return const_cast<RenderLayer*>(current);
  }

  ASSERT_NOT_REACHED();
  return 0;
}

}  // namespace blink
