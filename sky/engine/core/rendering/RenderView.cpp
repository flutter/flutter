/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009 Apple Inc.
 * All rights reserved.
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

#include "flutter/sky/engine/core/rendering/RenderView.h"

#include "flutter/sky/engine/core/rendering/HitTestResult.h"
#include "flutter/sky/engine/core/rendering/RenderGeometryMap.h"
#include "flutter/sky/engine/core/rendering/RenderLayer.h"
#include "flutter/sky/engine/platform/geometry/FloatQuad.h"
#include "flutter/sky/engine/platform/geometry/TransformState.h"
#include "flutter/sky/engine/platform/graphics/GraphicsContext.h"

namespace blink {

RenderView::RenderView()
    : m_selectionStart(nullptr),
      m_selectionEnd(nullptr),
      m_selectionStartPos(-1),
      m_selectionEndPos(-1),
      m_renderCounterCount(0),
      m_hitTestCount(0) {
  // init RenderObject attributes
  setInline(false);

  m_minPreferredLogicalWidth = 0;
  m_maxPreferredLogicalWidth = 0;

  setPreferredLogicalWidthsDirty(MarkOnlyThis);

  setPositionState(AbsolutePosition);  // to 0,0 :)
}

RenderView::~RenderView() {}

bool RenderView::hitTest(const HitTestRequest& request, HitTestResult& result) {
  return hitTest(request, result.hitTestLocation(), result);
}

bool RenderView::hitTest(const HitTestRequest& request,
                         const HitTestLocation& location,
                         HitTestResult& result) {
  m_hitTestCount++;

  // TODO(ojan): Does any of this intersection stuff make sense for Sky?
  LayoutRect hitTestArea;
  hitTestArea.setSize(m_frameViewSize);

  bool insideLayer =
      hitTestLayer(layer(), 0, request, result, hitTestArea, location);
  if (!insideLayer) {
    // TODO(ojan): Is this code needed for Sky?

    // We didn't hit any layer. If we are the root layer and the mouse is -- or
    // just was -- down, return ourselves. We do this so mouse events continue
    // getting delivered after a drag has exited the WebView, and so hit testing
    // over a scrollbar hits the content document.
    if (request.active() || request.release()) {
      updateHitTestResult(result, location.point());
      insideLayer = true;
    }
  }
  return insideLayer;
}

void RenderView::computeLogicalHeight(
    LayoutUnit logicalHeight,
    LayoutUnit,
    LogicalExtentComputedValues& computedValues) const {
  computedValues.m_extent = logicalHeight;
}

void RenderView::updateLogicalWidth() {
  setLogicalWidth(viewLogicalWidth());
}

bool RenderView::isChildAllowed(RenderObject* child, RenderStyle*) const {
  return child->isBox();
}

void RenderView::layout() {
  SubtreeLayoutScope layoutScope(*this);

  bool relayoutChildren = width() != viewWidth() || height() != viewHeight();
  if (relayoutChildren) {
    layoutScope.setChildNeedsLayout(this);
    for (RenderObject* child = firstChild(); child;
         child = child->nextSibling()) {
      if ((child->isBox() && toRenderBox(child)->hasRelativeLogicalHeight()) ||
          child->style()->logicalHeight().isPercent() ||
          child->style()->logicalMinHeight().isPercent() ||
          child->style()->logicalMaxHeight().isPercent())
        layoutScope.setChildNeedsLayout(child);
    }
  }

  if (!needsLayout())
    return;

  RenderFlexibleBox::layout();
  clearNeedsLayout();
}

void RenderView::mapLocalToContainer(
    const RenderBox* paintInvalidationContainer,
    TransformState& transformState,
    MapCoordinatesFlags mode) const {
  if (!paintInvalidationContainer && mode & UseTransforms &&
      shouldUseTransformFromContainer(0)) {
    TransformationMatrix t;
    getTransformFromContainer(0, LayoutSize(), t);
    transformState.applyTransform(t);
  }
}

const RenderObject* RenderView::pushMappingToContainer(
    const RenderBox* ancestorToStopAt,
    RenderGeometryMap& geometryMap) const {
  LayoutSize offset;
  RenderObject* container = 0;

  // If a container was specified, and was not 0 or the RenderView, then we
  // should have found it by now unless we're traversing to a parent document.
  ASSERT_ARG(ancestorToStopAt,
             !ancestorToStopAt || ancestorToStopAt == this || container);

  if ((!ancestorToStopAt || container) &&
      shouldUseTransformFromContainer(container)) {
    TransformationMatrix t;
    getTransformFromContainer(container, LayoutSize(), t);
    geometryMap.push(this, t, false, false, true);
  } else {
    geometryMap.push(this, offset, false, false, false);
  }

  return container;
}

void RenderView::mapAbsoluteToLocalPoint(MapCoordinatesFlags mode,
                                         TransformState& transformState) const {
  if (mode & UseTransforms && shouldUseTransformFromContainer(0)) {
    TransformationMatrix t;
    getTransformFromContainer(0, LayoutSize(), t);
    transformState.applyTransform(t);
  }
}

void RenderView::paint(PaintInfo& paintInfo,
                       const LayoutPoint& paintOffset,
                       Vector<RenderBox*>& layers) {
  // If we ever require layout but receive a paint anyway, something has gone
  // horribly wrong.
  ASSERT(!needsLayout());
  // RenderViews should never be called to paint with an offset not on device
  // pixels.
  ASSERT(LayoutPoint(IntPoint(paintOffset.x(), paintOffset.y())) ==
         paintOffset);

  paintObject(paintInfo, paintOffset, layers);
}

void RenderView::paintBoxDecorationBackground(PaintInfo& paintInfo,
                                              const LayoutPoint& paintOffset) {}

void RenderView::absoluteQuads(Vector<FloatQuad>& quads) const {
  quads.append(FloatRect(FloatPoint(), layer()->size()));
}

static RenderObject* rendererAfterPosition(RenderObject* object,
                                           unsigned offset) {
  if (!object)
    return 0;

  RenderObject* child = object->childAt(offset);
  return child ? child : object->nextInPreOrderAfterChildren();
}

// When exploring the RenderTree looking for the nodes involved in the
// Selection, sometimes it's required to change the traversing direction because
// the "start" position is below the "end" one.
static inline RenderObject* getNextOrPrevRenderObjectBasedOnDirection(
    const RenderObject* o,
    const RenderObject* stop,
    bool& continueExploring,
    bool& exploringBackwards) {
  RenderObject* next;
  if (exploringBackwards) {
    next = o->previousInPreOrder();
    continueExploring = next && !(next)->isRenderView();
  } else {
    next = o->nextInPreOrder();
    continueExploring = next && next != stop;
    exploringBackwards = !next && (next != stop);
    if (exploringBackwards) {
      next = stop->previousInPreOrder();
      continueExploring = next && !next->isRenderView();
    }
  }

  return next;
}

void RenderView::setSelection(RenderObject* start,
                              int startPos,
                              RenderObject* end,
                              int endPos) {
  // This code makes no assumptions as to if the rendering tree is up to date or
  // not and will not try to update it. Currently clearSelection calls this
  // (intentionally) without updating the rendering tree as it doesn't care.
  // Other callers may want to force recalc style before calling this.

  // Make sure both our start and end objects are defined.
  // Check www.msnbc.com and try clicking around to find the case where this
  // happened.
  if ((start && !end) || (end && !start))
    return;

  // Just return if the selection hasn't changed.
  if (m_selectionStart == start && m_selectionStartPos == startPos &&
      m_selectionEnd == end && m_selectionEndPos == endPos)
    return;

  RenderObject* os = m_selectionStart;
  RenderObject* stop = rendererAfterPosition(m_selectionEnd, m_selectionEndPos);
  bool exploringBackwards = false;
  bool continueExploring = os && (os != stop);
  while (continueExploring) {
    if ((os->canBeSelectionLeaf() || os == m_selectionStart ||
         os == m_selectionEnd) &&
        os->selectionState() != SelectionNone) {
      os->setSelectionStateIfNeeded(SelectionNone);
    }

    os = getNextOrPrevRenderObjectBasedOnDirection(os, stop, continueExploring,
                                                   exploringBackwards);
  }

  // set selection start and end
  m_selectionStart = start;
  m_selectionStartPos = startPos;
  m_selectionEnd = end;
  m_selectionEndPos = endPos;

  // Update the selection status of all objects between m_selectionStart and
  // m_selectionEnd
  if (start && start == end) {
    start->setSelectionStateIfNeeded(SelectionBoth);
  } else {
    if (start)
      start->setSelectionStateIfNeeded(SelectionStart);
    if (end)
      end->setSelectionStateIfNeeded(SelectionEnd);
  }

  RenderObject* o = start;
  stop = rendererAfterPosition(end, endPos);

  while (o && o != stop) {
    if (o != start && o != end && o->canBeSelectionLeaf())
      o->setSelectionStateIfNeeded(SelectionInside);
    o = o->nextInPreOrder();
  }
}

void RenderView::getSelection(RenderObject*& startRenderer,
                              int& startOffset,
                              RenderObject*& endRenderer,
                              int& endOffset) const {
  startRenderer = m_selectionStart;
  startOffset = m_selectionStartPos;
  endRenderer = m_selectionEnd;
  endOffset = m_selectionEndPos;
}

void RenderView::clearSelection() {
  setSelection(0, -1, 0, -1);
}

void RenderView::selectionStartEnd(int& startPos, int& endPos) const {
  startPos = m_selectionStartPos;
  endPos = m_selectionEndPos;
}

IntRect RenderView::unscaledDocumentRect() const {
  return pixelSnappedIntRect(layoutOverflowRect());
}

LayoutRect RenderView::backgroundRect(RenderBox* backgroundRenderer) const {
  return unscaledDocumentRect();
}

IntRect RenderView::documentRect() const {
  FloatRect overflowRect(unscaledDocumentRect());
  if (hasTransform())
    overflowRect = transform()->mapRect(overflowRect);
  return IntRect(overflowRect);
}

int RenderView::viewHeight() const {
  return m_frameViewSize.height();
}

int RenderView::viewWidth() const {
  return m_frameViewSize.width();
}

int RenderView::viewLogicalHeight() const {
  return viewHeight();
}

LayoutUnit RenderView::viewLogicalHeightForPercentages() const {
  return viewLogicalHeight();
}

// FIXME(sky): remove
double RenderView::layoutViewportWidth() const {
  return viewWidth();
}

// FIXME(sky): remove
double RenderView::layoutViewportHeight() const {
  return viewHeight();
}

}  // namespace blink
