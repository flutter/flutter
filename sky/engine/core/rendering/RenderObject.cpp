/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 *           (C) 2004 Allan Sandfeld Jensen (kde@carewolf.com)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2011 Apple Inc.
 * All rights reserved.
 * Copyright (C) 2009 Google Inc. All rights reserved.
 * Copyright (C) 2009 Torch Mobile Inc. All rights reserved.
 * (http://www.torchmobile.com/)
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

#include "flutter/sky/engine/core/rendering/RenderObject.h"

#include <algorithm>
#include "flutter/sky/engine/core/rendering/HitTestResult.h"
#include "flutter/sky/engine/core/rendering/RenderFlexibleBox.h"
#include "flutter/sky/engine/core/rendering/RenderGeometryMap.h"
#include "flutter/sky/engine/core/rendering/RenderInline.h"
#include "flutter/sky/engine/core/rendering/RenderLayer.h"
#include "flutter/sky/engine/core/rendering/RenderObjectInlines.h"
#include "flutter/sky/engine/core/rendering/RenderParagraph.h"
#include "flutter/sky/engine/core/rendering/RenderText.h"
#include "flutter/sky/engine/core/rendering/RenderTheme.h"
#include "flutter/sky/engine/core/rendering/RenderView.h"
#include "flutter/sky/engine/core/rendering/style/ShadowList.h"
#include "flutter/sky/engine/platform/Partitions.h"
#include "flutter/sky/engine/platform/geometry/TransformState.h"
#include "flutter/sky/engine/platform/graphics/GraphicsContext.h"
#include "flutter/sky/engine/wtf/RefCountedLeakCounter.h"
#include "flutter/sky/engine/wtf/text/StringBuilder.h"
#include "flutter/sky/engine/wtf/text/WTFString.h"
#ifndef NDEBUG
#include <stdio.h>
#endif

namespace blink {

#if ENABLE(ASSERT)

RenderObject::SetLayoutNeededForbiddenScope::SetLayoutNeededForbiddenScope(
    RenderObject& renderObject)
    : m_renderObject(renderObject),
      m_preexistingForbidden(m_renderObject.isSetNeedsLayoutForbidden()) {
  m_renderObject.setNeedsLayoutIsForbidden(true);
}

RenderObject::SetLayoutNeededForbiddenScope::~SetLayoutNeededForbiddenScope() {
  m_renderObject.setNeedsLayoutIsForbidden(m_preexistingForbidden);
}
#endif

struct SameSizeAsRenderObject {
  virtual ~SameSizeAsRenderObject() {}  // Allocate vtable pointer.
  void* pointers[4];
#if ENABLE(ASSERT)
  unsigned m_debugBitfields : 2;
#if ENABLE(OILPAN)
  unsigned m_oilpanBitfields : 1;
#endif
#endif
  unsigned m_bitfields;
};

COMPILE_ASSERT(sizeof(RenderObject) == sizeof(SameSizeAsRenderObject),
               RenderObject_should_stay_small);

bool RenderObject::s_affectsParentBlock = false;

#if !ENABLE(OILPAN)
void* RenderObject::operator new(size_t sz) {
  ASSERT(isMainThread());
  return partitionAlloc(Partitions::getRenderingPartition(), sz);
}

void RenderObject::operator delete(void* ptr) {
  ASSERT(isMainThread());
  partitionFree(ptr);
}
#endif

DEFINE_DEBUG_ONLY_GLOBAL(WTF::RefCountedLeakCounter,
                         renderObjectCounter,
                         ("RenderObject"));
unsigned RenderObject::s_instanceCount = 0;

RenderObject::RenderObject()
    : m_style(nullptr),
      m_parent(nullptr),
      m_previous(nullptr),
      m_next(nullptr)
#if ENABLE(ASSERT)
      ,
      m_setNeedsLayoutForbidden(false)
#if ENABLE(OILPAN)
      ,
      m_didCallDestroy(false)
#endif
#endif
{
#ifndef NDEBUG
  renderObjectCounter.increment();
#endif
  ++s_instanceCount;
}

RenderObject::~RenderObject() {
#if ENABLE(OILPAN)
  ASSERT(m_didCallDestroy);
#endif
#ifndef NDEBUG
  renderObjectCounter.decrement();
#endif
  --s_instanceCount;
}

String RenderObject::debugName() const {
  return renderName();
}

bool RenderObject::isDescendantOf(const RenderObject* obj) const {
  for (const RenderObject* r = this; r; r = r->m_parent) {
    if (r == obj)
      return true;
  }
  return false;
}

void RenderObject::addChild(RenderObject* newChild, RenderObject* beforeChild) {
  RenderObjectChildList* children = virtualChildren();
  ASSERT(children);
  children->insertChildNode(this, newChild, beforeChild);
}

void RenderObject::removeChild(RenderObject* oldChild) {
  RenderObjectChildList* children = virtualChildren();
  ASSERT(children);
  if (!children)
    return;

  children->removeChildNode(this, oldChild);
}

RenderObject* RenderObject::nextInPreOrder() const {
  if (RenderObject* o = slowFirstChild())
    return o;

  return nextInPreOrderAfterChildren();
}

RenderObject* RenderObject::nextInPreOrderAfterChildren() const {
  RenderObject* o = nextSibling();
  if (!o) {
    o = parent();
    while (o && !o->nextSibling())
      o = o->parent();
    if (o)
      o = o->nextSibling();
  }

  return o;
}

RenderObject* RenderObject::nextInPreOrder(
    const RenderObject* stayWithin) const {
  if (RenderObject* o = slowFirstChild())
    return o;

  return nextInPreOrderAfterChildren(stayWithin);
}

RenderObject* RenderObject::nextInPreOrderAfterChildren(
    const RenderObject* stayWithin) const {
  if (this == stayWithin)
    return 0;

  const RenderObject* current = this;
  RenderObject* next = current->nextSibling();
  for (; !next; next = current->nextSibling()) {
    current = current->parent();
    if (!current || current == stayWithin)
      return 0;
  }
  return next;
}

RenderObject* RenderObject::previousInPreOrder() const {
  if (RenderObject* o = previousSibling()) {
    while (RenderObject* lastChild = o->slowLastChild())
      o = lastChild;
    return o;
  }

  return parent();
}

RenderObject* RenderObject::previousInPreOrder(
    const RenderObject* stayWithin) const {
  if (this == stayWithin)
    return 0;

  return previousInPreOrder();
}

RenderObject* RenderObject::childAt(unsigned index) const {
  RenderObject* child = slowFirstChild();
  for (unsigned i = 0; child && i < index; i++)
    child = child->nextSibling();
  return child;
}

RenderObject* RenderObject::lastLeafChild() const {
  RenderObject* r = slowLastChild();
  while (r) {
    RenderObject* n = 0;
    n = r->slowLastChild();
    if (!n)
      break;
    r = n;
  }
  return r;
}

static void addLayers(RenderObject* obj,
                      RenderLayer* parentLayer,
                      RenderObject*& newObject,
                      RenderLayer*& beforeChild) {
  if (obj->hasLayer()) {
    if (!beforeChild && newObject) {
      // We need to figure out the layer that follows newObject. We only do
      // this the first time we find a child layer, and then we update the
      // pointer values for newObject and beforeChild used by everyone else.
      beforeChild = newObject->parent()->findNextLayer(parentLayer, newObject);
      newObject = 0;
    }
    parentLayer->addChild(toRenderBox(obj)->layer(), beforeChild);
    return;
  }

  for (RenderObject* curr = obj->slowFirstChild(); curr;
       curr = curr->nextSibling())
    addLayers(curr, parentLayer, newObject, beforeChild);
}

void RenderObject::addLayers(RenderLayer* parentLayer) {
  if (!parentLayer)
    return;

  RenderObject* object = this;
  RenderLayer* beforeChild = 0;
  blink::addLayers(this, parentLayer, object, beforeChild);
}

void RenderObject::removeLayers(RenderLayer* parentLayer) {
  if (!parentLayer)
    return;

  if (hasLayer()) {
    parentLayer->removeChild(toRenderBox(this)->layer());
    return;
  }

  for (RenderObject* curr = slowFirstChild(); curr; curr = curr->nextSibling())
    curr->removeLayers(parentLayer);
}

void RenderObject::moveLayers(RenderLayer* oldParent, RenderLayer* newParent) {
  if (!newParent)
    return;

  if (hasLayer()) {
    RenderLayer* layer = toRenderBox(this)->layer();
    ASSERT(oldParent == layer->parent());
    if (oldParent)
      oldParent->removeChild(layer);
    newParent->addChild(layer);
    return;
  }

  for (RenderObject* curr = slowFirstChild(); curr; curr = curr->nextSibling())
    curr->moveLayers(oldParent, newParent);
}

RenderLayer* RenderObject::findNextLayer(RenderLayer* parentLayer,
                                         RenderObject* startPoint,
                                         bool checkParent) {
  // Error check the parent layer passed in. If it's null, we can't find
  // anything.
  if (!parentLayer)
    return 0;

  // Step 1: If our layer is a child of the desired parent, then return our
  // layer.
  RenderLayer* ourLayer = hasLayer() ? toRenderBox(this)->layer() : 0;
  if (ourLayer && ourLayer->parent() == parentLayer)
    return ourLayer;

  // Step 2: If we don't have a layer, or our layer is the desired parent, then
  // descend into our siblings trying to find the next layer whose parent is the
  // desired parent.
  if (!ourLayer || ourLayer == parentLayer) {
    for (RenderObject* curr = startPoint ? startPoint->nextSibling()
                                         : slowFirstChild();
         curr; curr = curr->nextSibling()) {
      RenderLayer* nextLayer = curr->findNextLayer(parentLayer, 0, false);
      if (nextLayer)
        return nextLayer;
    }
  }

  // Step 3: If our layer is the desired parent layer, then we're finished. We
  // didn't find anything.
  if (parentLayer == ourLayer)
    return 0;

  // Step 4: If |checkParent| is set, climb up to our parent and check its
  // siblings that follow us to see if we can locate a layer.
  if (checkParent && parent())
    return parent()->findNextLayer(parentLayer, this, true);

  return 0;
}

RenderLayer* RenderObject::enclosingLayer() const {
  for (const RenderObject* current = this; current;
       current = current->parent()) {
    if (current->hasLayer())
      return toRenderBox(current)->layer();
  }
  // FIXME: We should remove the one caller that triggers this case and make
  // this function return a reference.
  ASSERT(!m_parent && !isRenderView());
  return 0;
}

RenderBox* RenderObject::enclosingBox() const {
  RenderObject* curr = const_cast<RenderObject*>(this);
  while (curr) {
    if (curr->isBox())
      return toRenderBox(curr);
    curr = curr->parent();
  }

  ASSERT_NOT_REACHED();
  return 0;
}

RenderBoxModelObject* RenderObject::enclosingBoxModelObject() const {
  RenderObject* curr = const_cast<RenderObject*>(this);
  while (curr) {
    if (curr->isBoxModelObject())
      return toRenderBoxModelObject(curr);
    curr = curr->parent();
  }

  ASSERT_NOT_REACHED();
  return 0;
}

bool RenderObject::skipInvalidationWhenLaidOutChildren() const {
  if (!neededLayoutBecauseOfChildren())
    return false;

  // SVG renderers need to be invalidated when their children are laid out.
  // RenderBlocks with line boxes are responsible to invalidate them so we can't
  // ignore them.
  if (isRenderParagraph() && toRenderParagraph(this)->firstLineBox())
    return false;

  return rendererHasNoBoxEffect();
}

RenderBlock* RenderObject::firstLineBlock() const {
  return 0;
}

static inline bool objectIsRelayoutBoundary(const RenderObject* object) {
  if (!object->hasOverflowClip())
    return false;

  if (object->style()->width().isIntrinsicOrAuto() ||
      object->style()->height().isIntrinsicOrAuto() ||
      object->style()->height().isPercent())
    return false;

  return true;
}

void RenderObject::markContainingBlocksForLayout(bool scheduleRelayout,
                                                 RenderObject* newRoot,
                                                 SubtreeLayoutScope* layouter) {
  ASSERT(!scheduleRelayout || !newRoot);
  ASSERT(!isSetNeedsLayoutForbidden());
  ASSERT(!layouter || this != layouter->root());

  RenderObject* object = container();
  RenderObject* last = this;

  bool simplifiedNormalFlowLayout = needsSimplifiedNormalFlowLayout() &&
                                    !selfNeedsLayout() &&
                                    !normalChildNeedsLayout();

  while (object) {
    if (object->selfNeedsLayout())
      return;

    // Don't mark the outermost object of an unrooted subtree. That object will
    // be marked when the subtree is added to the document.
    RenderObject* container = object->container();
    if (!container && !object->isRenderView())
      return;
    if (!last->isText() && last->style()->hasOutOfFlowPosition()) {
      bool willSkipRelativelyPositionedInlines = !object->isRenderBlock();
      // Skip relatively positioned inlines and anonymous blocks to get to the
      // enclosing RenderBlock.
      while (object && !object->isRenderBlock())
        object = object->container();
      if (!object || object->posChildNeedsLayout())
        return;
      if (willSkipRelativelyPositionedInlines)
        container = object->container();
      object->setPosChildNeedsLayout(true);
      simplifiedNormalFlowLayout = true;
      ASSERT(!object->isSetNeedsLayoutForbidden());
    } else if (simplifiedNormalFlowLayout) {
      if (object->needsSimplifiedNormalFlowLayout())
        return;
      object->setNeedsSimplifiedNormalFlowLayout(true);
      ASSERT(!object->isSetNeedsLayoutForbidden());
    } else {
      if (object->normalChildNeedsLayout())
        return;
      object->setNormalChildNeedsLayout(true);
      ASSERT(!object->isSetNeedsLayoutForbidden());
    }

    if (layouter) {
      layouter->addRendererToLayout(object);
      if (object == layouter->root())
        return;
    }

    if (object == newRoot)
      return;

    last = object;
    if (scheduleRelayout && objectIsRelayoutBoundary(last))
      break;
    object = container;
  }

  if (scheduleRelayout)
    last->scheduleRelayout();
}

#if ENABLE(ASSERT)
void RenderObject::checkBlockPositionedObjectsNeedLayout() {
  ASSERT(!needsLayout());

  if (isRenderBlock())
    toRenderBlock(this)->checkPositionedObjectsNeedLayout();
}
#endif

void RenderObject::setPreferredLogicalWidthsDirty(MarkingBehavior markParents) {
  m_bitfields.setPreferredLogicalWidthsDirty(true);
  if (markParents == MarkContainingBlockChain &&
      (isText() || !style()->hasOutOfFlowPosition()))
    invalidateContainerPreferredLogicalWidths();
}

void RenderObject::clearPreferredLogicalWidthsDirty() {
  m_bitfields.setPreferredLogicalWidthsDirty(false);
}

void RenderObject::invalidateContainerPreferredLogicalWidths() {
  // In order to avoid pathological behavior when inlines are deeply nested, we
  // do include them in the chain that we mark dirty (even though they're kind
  // of irrelevant).
  RenderObject* o = container();
  while (o && !o->preferredLogicalWidthsDirty()) {
    // Don't invalidate the outermost object of an unrooted subtree. That object
    // will be invalidated when the subtree is added to the document.
    RenderObject* container = o->container();
    if (!container && !o->isRenderView())
      break;

    o->m_bitfields.setPreferredLogicalWidthsDirty(true);
    if (o->style()->hasOutOfFlowPosition())
      // A positioned object has no effect on the min/max width of its
      // containing block ever. We can optimize this case and not go up any
      // further.
      break;
    o = container;
  }
}

RenderBlock* RenderObject::containingBlock() const {
  RenderObject* o = parent();
  if (!isText() && m_style->position() == AbsolutePosition) {
    while (o) {
      // For relpositioned inlines, we return the nearest non-anonymous
      // enclosing block. We don't try to return the inline itself.  This allows
      // us to avoid having a positioned objects list in all RenderInlines and
      // lets us return a strongly-typed RenderBlock* result from this method.
      // The container() method can actually be used to obtain the inline
      // directly.
      if (o->style()->position() != StaticPosition &&
          (!o->isInline() || o->isReplaced()))
        break;

      if (o->canContainAbsolutePositionObjects())
        break;

      if (o->style()->hasInFlowPosition() && o->isInline() &&
          !o->isReplaced()) {
        o = o->containingBlock();
        break;
      }

      o = o->parent();
    }

    if (o && !o->isRenderBlock())
      o = o->containingBlock();
  } else {
    while (o && ((o->isInline() && !o->isReplaced()) || !o->isRenderBlock()))
      o = o->parent();
  }

  if (!o || !o->isRenderBlock())
    return 0;  // This can still happen in case of an orphaned tree

  return toRenderBlock(o);
}

void RenderObject::drawLineForBoxSide(GraphicsContext* graphicsContext,
                                      int x1,
                                      int y1,
                                      int x2,
                                      int y2,
                                      BoxSide side,
                                      Color color,
                                      EBorderStyle style,
                                      int adjacentWidth1,
                                      int adjacentWidth2,
                                      bool antialias) {
  int thickness;
  int length;
  if (side == BSTop || side == BSBottom) {
    thickness = y2 - y1;
    length = x2 - x1;
  } else {
    thickness = x2 - x1;
    length = y2 - y1;
  }

  // FIXME: We really would like this check to be an ASSERT as we don't want to
  // draw empty borders. However nothing guarantees that the following recursive
  // calls to drawLineForBoxSide will have non-null dimensions.
  if (!thickness || !length)
    return;

  if (style == DOUBLE && thickness < 3)
    style = SOLID;

  switch (style) {
    case BNONE:
    case BHIDDEN:
      return;
    case DOTTED:
    case DASHED:
      drawDashedOrDottedBoxSide(graphicsContext, x1, y1, x2, y2, side, color,
                                thickness, style, antialias);
      break;
    case DOUBLE:
      drawDoubleBoxSide(graphicsContext, x1, y1, x2, y2, length, side, color,
                        thickness, adjacentWidth1, adjacentWidth2, antialias);
      break;
    case RIDGE:
    case GROOVE:
      drawRidgeOrGrooveBoxSide(graphicsContext, x1, y1, x2, y2, side, color,
                               style, adjacentWidth1, adjacentWidth2,
                               antialias);
      break;
    case INSET:
      // FIXME: Maybe we should lighten the colors on one side like Firefox.
      // https://bugs.webkit.org/show_bug.cgi?id=58608
      if (side == BSTop || side == BSLeft)
        color = color.dark();
      // fall through
    case OUTSET:
      if (style == OUTSET && (side == BSBottom || side == BSRight))
        color = color.dark();
      // fall through
    case SOLID:
      drawSolidBoxSide(graphicsContext, x1, y1, x2, y2, side, color,
                       adjacentWidth1, adjacentWidth2, antialias);
      break;
  }
}

void RenderObject::drawDashedOrDottedBoxSide(GraphicsContext* graphicsContext,
                                             int x1,
                                             int y1,
                                             int x2,
                                             int y2,
                                             BoxSide side,
                                             Color color,
                                             int thickness,
                                             EBorderStyle style,
                                             bool antialias) {
  if (thickness <= 0)
    return;

  bool wasAntialiased = graphicsContext->shouldAntialias();
  StrokeStyle oldStrokeStyle = graphicsContext->strokeStyle();
  graphicsContext->setShouldAntialias(antialias);
  graphicsContext->setStrokeColor(color);
  graphicsContext->setStrokeThickness(thickness);
  graphicsContext->setStrokeStyle(style == DASHED ? DashedStroke
                                                  : DottedStroke);

  switch (side) {
    case BSBottom:
    case BSTop:
      graphicsContext->drawLine(IntPoint(x1, (y1 + y2) / 2),
                                IntPoint(x2, (y1 + y2) / 2));
      break;
    case BSRight:
    case BSLeft:
      graphicsContext->drawLine(IntPoint((x1 + x2) / 2, y1),
                                IntPoint((x1 + x2) / 2, y2));
      break;
  }
  graphicsContext->setShouldAntialias(wasAntialiased);
  graphicsContext->setStrokeStyle(oldStrokeStyle);
}

void RenderObject::drawDoubleBoxSide(GraphicsContext* graphicsContext,
                                     int x1,
                                     int y1,
                                     int x2,
                                     int y2,
                                     int length,
                                     BoxSide side,
                                     Color color,
                                     int thickness,
                                     int adjacentWidth1,
                                     int adjacentWidth2,
                                     bool antialias) {
  int thirdOfThickness = (thickness + 1) / 3;
  ASSERT(thirdOfThickness);

  if (!adjacentWidth1 && !adjacentWidth2) {
    StrokeStyle oldStrokeStyle = graphicsContext->strokeStyle();
    graphicsContext->setStrokeStyle(NoStroke);
    graphicsContext->setFillColor(color);

    bool wasAntialiased = graphicsContext->shouldAntialias();
    graphicsContext->setShouldAntialias(antialias);

    switch (side) {
      case BSTop:
      case BSBottom:
        graphicsContext->drawRect(IntRect(x1, y1, length, thirdOfThickness));
        graphicsContext->drawRect(
            IntRect(x1, y2 - thirdOfThickness, length, thirdOfThickness));
        break;
      case BSLeft:
      case BSRight:
        // FIXME: Why do we offset the border by 1 in this case but not the
        // other one?
        if (length > 1) {
          graphicsContext->drawRect(
              IntRect(x1, y1 + 1, thirdOfThickness, length - 1));
          graphicsContext->drawRect(IntRect(x2 - thirdOfThickness, y1 + 1,
                                            thirdOfThickness, length - 1));
        }
        break;
    }

    graphicsContext->setShouldAntialias(wasAntialiased);
    graphicsContext->setStrokeStyle(oldStrokeStyle);
    return;
  }

  int adjacent1BigThird =
      ((adjacentWidth1 > 0) ? adjacentWidth1 + 1 : adjacentWidth1 - 1) / 3;
  int adjacent2BigThird =
      ((adjacentWidth2 > 0) ? adjacentWidth2 + 1 : adjacentWidth2 - 1) / 3;

  switch (side) {
    case BSTop:
      drawLineForBoxSide(graphicsContext,
                         x1 + std::max((-adjacentWidth1 * 2 + 1) / 3, 0), y1,
                         x2 - std::max((-adjacentWidth2 * 2 + 1) / 3, 0),
                         y1 + thirdOfThickness, side, color, SOLID,
                         adjacent1BigThird, adjacent2BigThird, antialias);
      drawLineForBoxSide(
          graphicsContext, x1 + std::max((adjacentWidth1 * 2 + 1) / 3, 0),
          y2 - thirdOfThickness, x2 - std::max((adjacentWidth2 * 2 + 1) / 3, 0),
          y2, side, color, SOLID, adjacent1BigThird, adjacent2BigThird,
          antialias);
      break;
    case BSLeft:
      drawLineForBoxSide(
          graphicsContext, x1, y1 + std::max((-adjacentWidth1 * 2 + 1) / 3, 0),
          x1 + thirdOfThickness,
          y2 - std::max((-adjacentWidth2 * 2 + 1) / 3, 0), side, color, SOLID,
          adjacent1BigThird, adjacent2BigThird, antialias);
      drawLineForBoxSide(graphicsContext, x2 - thirdOfThickness,
                         y1 + std::max((adjacentWidth1 * 2 + 1) / 3, 0), x2,
                         y2 - std::max((adjacentWidth2 * 2 + 1) / 3, 0), side,
                         color, SOLID, adjacent1BigThird, adjacent2BigThird,
                         antialias);
      break;
    case BSBottom:
      drawLineForBoxSide(
          graphicsContext, x1 + std::max((adjacentWidth1 * 2 + 1) / 3, 0), y1,
          x2 - std::max((adjacentWidth2 * 2 + 1) / 3, 0), y1 + thirdOfThickness,
          side, color, SOLID, adjacent1BigThird, adjacent2BigThird, antialias);
      drawLineForBoxSide(
          graphicsContext, x1 + std::max((-adjacentWidth1 * 2 + 1) / 3, 0),
          y2 - thirdOfThickness,
          x2 - std::max((-adjacentWidth2 * 2 + 1) / 3, 0), y2, side, color,
          SOLID, adjacent1BigThird, adjacent2BigThird, antialias);
      break;
    case BSRight:
      drawLineForBoxSide(
          graphicsContext, x1, y1 + std::max((adjacentWidth1 * 2 + 1) / 3, 0),
          x1 + thirdOfThickness, y2 - std::max((adjacentWidth2 * 2 + 1) / 3, 0),
          side, color, SOLID, adjacent1BigThird, adjacent2BigThird, antialias);
      drawLineForBoxSide(graphicsContext, x2 - thirdOfThickness,
                         y1 + std::max((-adjacentWidth1 * 2 + 1) / 3, 0), x2,
                         y2 - std::max((-adjacentWidth2 * 2 + 1) / 3, 0), side,
                         color, SOLID, adjacent1BigThird, adjacent2BigThird,
                         antialias);
      break;
    default:
      break;
  }
}

void RenderObject::drawRidgeOrGrooveBoxSide(GraphicsContext* graphicsContext,
                                            int x1,
                                            int y1,
                                            int x2,
                                            int y2,
                                            BoxSide side,
                                            Color color,
                                            EBorderStyle style,
                                            int adjacentWidth1,
                                            int adjacentWidth2,
                                            bool antialias) {
  EBorderStyle s1;
  EBorderStyle s2;
  if (style == GROOVE) {
    s1 = INSET;
    s2 = OUTSET;
  } else {
    s1 = OUTSET;
    s2 = INSET;
  }

  int adjacent1BigHalf =
      ((adjacentWidth1 > 0) ? adjacentWidth1 + 1 : adjacentWidth1 - 1) / 2;
  int adjacent2BigHalf =
      ((adjacentWidth2 > 0) ? adjacentWidth2 + 1 : adjacentWidth2 - 1) / 2;

  switch (side) {
    case BSTop:
      drawLineForBoxSide(graphicsContext, x1 + std::max(-adjacentWidth1, 0) / 2,
                         y1, x2 - std::max(-adjacentWidth2, 0) / 2,
                         (y1 + y2 + 1) / 2, side, color, s1, adjacent1BigHalf,
                         adjacent2BigHalf, antialias);
      drawLineForBoxSide(
          graphicsContext, x1 + std::max(adjacentWidth1 + 1, 0) / 2,
          (y1 + y2 + 1) / 2, x2 - std::max(adjacentWidth2 + 1, 0) / 2, y2, side,
          color, s2, adjacentWidth1 / 2, adjacentWidth2 / 2, antialias);
      break;
    case BSLeft:
      drawLineForBoxSide(
          graphicsContext, x1, y1 + std::max(-adjacentWidth1, 0) / 2,
          (x1 + x2 + 1) / 2, y2 - std::max(-adjacentWidth2, 0) / 2, side, color,
          s1, adjacent1BigHalf, adjacent2BigHalf, antialias);
      drawLineForBoxSide(graphicsContext, (x1 + x2 + 1) / 2,
                         y1 + std::max(adjacentWidth1 + 1, 0) / 2, x2,
                         y2 - std::max(adjacentWidth2 + 1, 0) / 2, side, color,
                         s2, adjacentWidth1 / 2, adjacentWidth2 / 2, antialias);
      break;
    case BSBottom:
      drawLineForBoxSide(graphicsContext, x1 + std::max(adjacentWidth1, 0) / 2,
                         y1, x2 - std::max(adjacentWidth2, 0) / 2,
                         (y1 + y2 + 1) / 2, side, color, s2, adjacent1BigHalf,
                         adjacent2BigHalf, antialias);
      drawLineForBoxSide(
          graphicsContext, x1 + std::max(-adjacentWidth1 + 1, 0) / 2,
          (y1 + y2 + 1) / 2, x2 - std::max(-adjacentWidth2 + 1, 0) / 2, y2,
          side, color, s1, adjacentWidth1 / 2, adjacentWidth2 / 2, antialias);
      break;
    case BSRight:
      drawLineForBoxSide(
          graphicsContext, x1, y1 + std::max(adjacentWidth1, 0) / 2,
          (x1 + x2 + 1) / 2, y2 - std::max(adjacentWidth2, 0) / 2, side, color,
          s2, adjacent1BigHalf, adjacent2BigHalf, antialias);
      drawLineForBoxSide(graphicsContext, (x1 + x2 + 1) / 2,
                         y1 + std::max(-adjacentWidth1 + 1, 0) / 2, x2,
                         y2 - std::max(-adjacentWidth2 + 1, 0) / 2, side, color,
                         s1, adjacentWidth1 / 2, adjacentWidth2 / 2, antialias);
      break;
  }
}

void RenderObject::drawSolidBoxSide(GraphicsContext* graphicsContext,
                                    int x1,
                                    int y1,
                                    int x2,
                                    int y2,
                                    BoxSide side,
                                    Color color,
                                    int adjacentWidth1,
                                    int adjacentWidth2,
                                    bool antialias) {
  StrokeStyle oldStrokeStyle = graphicsContext->strokeStyle();
  graphicsContext->setStrokeStyle(NoStroke);
  graphicsContext->setFillColor(color);
  ASSERT(x2 >= x1);
  ASSERT(y2 >= y1);
  if (!adjacentWidth1 && !adjacentWidth2) {
    // Turn off antialiasing to match the behavior of drawConvexPolygon();
    // this matters for rects in transformed contexts.
    bool wasAntialiased = graphicsContext->shouldAntialias();
    graphicsContext->setShouldAntialias(antialias);
    graphicsContext->drawRect(IntRect(x1, y1, x2 - x1, y2 - y1));
    graphicsContext->setShouldAntialias(wasAntialiased);
    graphicsContext->setStrokeStyle(oldStrokeStyle);
    return;
  }
  FloatPoint quad[4];
  switch (side) {
    case BSTop:
      quad[0] = FloatPoint(x1 + std::max(-adjacentWidth1, 0), y1);
      quad[1] = FloatPoint(x1 + std::max(adjacentWidth1, 0), y2);
      quad[2] = FloatPoint(x2 - std::max(adjacentWidth2, 0), y2);
      quad[3] = FloatPoint(x2 - std::max(-adjacentWidth2, 0), y1);
      break;
    case BSBottom:
      quad[0] = FloatPoint(x1 + std::max(adjacentWidth1, 0), y1);
      quad[1] = FloatPoint(x1 + std::max(-adjacentWidth1, 0), y2);
      quad[2] = FloatPoint(x2 - std::max(-adjacentWidth2, 0), y2);
      quad[3] = FloatPoint(x2 - std::max(adjacentWidth2, 0), y1);
      break;
    case BSLeft:
      quad[0] = FloatPoint(x1, y1 + std::max(-adjacentWidth1, 0));
      quad[1] = FloatPoint(x1, y2 - std::max(-adjacentWidth2, 0));
      quad[2] = FloatPoint(x2, y2 - std::max(adjacentWidth2, 0));
      quad[3] = FloatPoint(x2, y1 + std::max(adjacentWidth1, 0));
      break;
    case BSRight:
      quad[0] = FloatPoint(x1, y1 + std::max(adjacentWidth1, 0));
      quad[1] = FloatPoint(x1, y2 - std::max(adjacentWidth2, 0));
      quad[2] = FloatPoint(x2, y2 - std::max(-adjacentWidth2, 0));
      quad[3] = FloatPoint(x2, y1 + std::max(-adjacentWidth1, 0));
      break;
  }

  graphicsContext->drawConvexPolygon(4, quad, antialias);
  graphicsContext->setStrokeStyle(oldStrokeStyle);
}

void RenderObject::addChildFocusRingRects(
    Vector<IntRect>& rects,
    const LayoutPoint& additionalOffset,
    const RenderBox* paintContainer) const {
  for (RenderObject* current = slowFirstChild(); current;
       current = current->nextSibling()) {
    if (current->isText())
      continue;

    if (current->isBox()) {
      RenderBox* box = toRenderBox(current);
      if (box->hasLayer()) {
        Vector<IntRect> layerFocusRingRects;
        box->addFocusRingRects(layerFocusRingRects, LayoutPoint(), box);
        for (size_t i = 0; i < layerFocusRingRects.size(); ++i) {
          FloatQuad quadInBox = box->localToContainerQuad(
              FloatRect(layerFocusRingRects[i]), paintContainer);
          FloatRect rect = quadInBox.boundingBox();
          // Floor the location instead of using pixelSnappedIntRect to match
          // the !hasLayer() path.
          // FIXME: roundedIntSize matches pixelSnappedIntRect in other places
          // of addFocusRingRects because we always floor the offset. This
          // assumption is fragile and should be replaced by better solution.
          rects.append(IntRect(flooredIntPoint(rect.location()),
                               roundedIntSize(rect.size())));
        }
      } else {
        FloatPoint pos(additionalOffset);
        pos.move(box->locationOffset());
        box->addFocusRingRects(rects, flooredIntPoint(pos), paintContainer);
      }
    } else {
      current->addFocusRingRects(rects, additionalOffset, paintContainer);
    }
  }
}

IntRect RenderObject::absoluteBoundingBoxRect() const {
  Vector<FloatQuad> quads;
  absoluteQuads(quads);

  size_t n = quads.size();
  if (!n)
    return IntRect();

  IntRect result = quads[0].enclosingBoundingBox();
  for (size_t i = 1; i < n; ++i)
    result.unite(quads[i].enclosingBoundingBox());
  return result;
}

void RenderObject::addAbsoluteRectForLayer(LayoutRect& result) {
  if (hasLayer())
    result.unite(absoluteBoundingBoxRect());
  for (RenderObject* current = slowFirstChild(); current;
       current = current->nextSibling())
    current->addAbsoluteRectForLayer(result);
}

void RenderObject::paint(PaintInfo&,
                         const LayoutPoint&,
                         Vector<RenderBox*>& layers) {}

void RenderObject::dirtyLinesFromChangedChild(RenderObject*) {}

#ifndef NDEBUG

void RenderObject::showTreeForThis() const {}

void RenderObject::showRenderTreeForThis() const {
  showRenderTree(this, 0);
}

void RenderObject::showLineTreeForThis() const {
  if (containingBlock())
    containingBlock()->showLineTreeAndMark(0, 0, 0, 0, this);
}

void RenderObject::showRenderObject() const {
  showRenderObject(0);
}

void RenderObject::showRenderObject(int printedCharacters) const {
  printedCharacters += fprintf(stderr, "%s %p", renderName(), this);
  fputc('\n', stderr);
}

void RenderObject::showRenderTreeAndMark(const RenderObject* markedObject1,
                                         const char* markedLabel1,
                                         const RenderObject* markedObject2,
                                         const char* markedLabel2,
                                         int depth) const {
  int printedCharacters = 0;
  if (markedObject1 == this && markedLabel1)
    printedCharacters += fprintf(stderr, "%s", markedLabel1);
  if (markedObject2 == this && markedLabel2)
    printedCharacters += fprintf(stderr, "%s", markedLabel2);
  for (; printedCharacters < depth * 2; printedCharacters++)
    fputc(' ', stderr);

  showRenderObject(printedCharacters);

  for (const RenderObject* child = slowFirstChild(); child;
       child = child->nextSibling())
    child->showRenderTreeAndMark(markedObject1, markedLabel1, markedObject2,
                                 markedLabel2, depth + 1);
}

#endif  // NDEBUG

bool RenderObject::isSelectable() const {
  return !(style()->userSelect() == SELECT_NONE &&
           style()->userModify() == READ_ONLY);
}

Color RenderObject::selectionBackgroundColor() const {
  ASSERT_NOT_REACHED();
  // TODO(ianh): if we expose selection painting, we should expose a way to set
  // the background colour
  // TODO(ianh): need to be able to configure whether to consider the selection
  // focused and active or not
  if (!isSelectable())
    return Color::transparent;
  bool isFocusedAndActive = true;
  return isFocusedAndActive
             ? RenderTheme::theme().activeSelectionBackgroundColor()
             : RenderTheme::theme().inactiveSelectionBackgroundColor();
}

Color RenderObject::selectionColor() const {
  ASSERT_NOT_REACHED();
  return style()->color();
}

Color RenderObject::selectionForegroundColor() const {
  return selectionColor();
}

Color RenderObject::selectionEmphasisMarkColor() const {
  return selectionColor();
}

void RenderObject::selectionStartEnd(int& spos, int& epos) const {
  spos = -1;
  epos = -1;
}

StyleDifference RenderObject::adjustStyleDifference(
    StyleDifference diff) const {
  // The answer to layerTypeRequired() for plugins, iframes, and canvas can
  // change without the actual style changing, since it depends on whether we
  // decide to composite these elements. When the layer status of one of these
  // elements changes, we need to force a layout.
  if (!diff.needsFullLayout() && style() && isBox()) {
    bool requiresLayer = toRenderBox(this)->layerTypeRequired() != NoLayer;
    if (hasLayer() != requiresLayer)
      diff.setNeedsFullLayout();
  }

  return diff;
}

inline bool
RenderObject::hasImmediateNonWhitespaceTextChildOrPropertiesDependentOnColor()
    const {
  if (style()->hasBorder() || style()->hasOutline())
    return true;
  for (const RenderObject* r = slowFirstChild(); r; r = r->nextSibling()) {
    if (r->isText() && !toRenderText(r)->isAllCollapsibleWhitespace())
      return true;
    if (r->style()->hasOutline() || r->style()->hasBorder())
      return true;
  }
  return false;
}

void RenderObject::markContainingBlocksForOverflowRecalc() {
  for (RenderBlock* container = containingBlock();
       container && !container->childNeedsOverflowRecalcAfterStyleChange();
       container = container->containingBlock())
    container->setChildNeedsOverflowRecalcAfterStyleChange(true);
}

void RenderObject::setNeedsOverflowRecalcAfterStyleChange() {
  bool neededRecalc = needsOverflowRecalcAfterStyleChange();
  setSelfNeedsOverflowRecalcAfterStyleChange(true);
  if (!neededRecalc)
    markContainingBlocksForOverflowRecalc();
}

void RenderObject::setStyle(PassRefPtr<RenderStyle> style) {
  ASSERT(style);
  StyleDifference diff;
  if (m_style)
    diff = m_style->visualInvalidationDiff(*style);

  diff = adjustStyleDifference(diff);

  styleWillChange(diff, *style);

  RefPtr<RenderStyle> oldStyle = m_style.release();
  setStyleInternal(style);

  updateFillImages(oldStyle ? &oldStyle->backgroundLayers() : 0,
                   m_style->backgroundLayers());

  bool doesNotNeedLayout = !m_parent || isText();

  styleDidChange(diff, oldStyle.get());

  // FIXME: |this| might be destroyed here. This can currently happen for a
  // RenderTextFragment when its first-letter block gets an update in
  // RenderTextFragment::styleDidChange. For RenderTextFragment(s), we will
  // safely bail out with the doesNotNeedLayout flag. We might want to broaden
  // this condition in the future as we move renderer changes out of layout and
  // into style changes.
  // FIXME(sky): Remove this.
  if (doesNotNeedLayout)
    return;

  // Now that the layer (if any) has been updated, we need to adjust the diff
  // again, check whether we should layout now, and decide if we need to
  // invalidate paints.
  StyleDifference updatedDiff = adjustStyleDifference(diff);

  if (!diff.needsFullLayout()) {
    if (updatedDiff.needsFullLayout())
      setNeedsLayoutAndPrefWidthsRecalc();
    else if (updatedDiff.needsPositionedMovementLayout())
      setNeedsPositionedMovementLayout();
  }

  if (diff.transformChanged() && !needsLayout()) {
    if (RenderBlock* container = containingBlock())
      container->setNeedsOverflowRecalcAfterStyleChange();
  }
}

void RenderObject::styleWillChange(StyleDifference diff,
                                   const RenderStyle& newStyle) {
  if (m_style) {
    if (isOutOfFlowPositioned() && (m_style->position() != newStyle.position()))
      // For changes in positioning styles, we need to conceivably remove
      // ourselves from the positioned objects list.
      toRenderBox(this)->removeFloatingOrPositionedChildFromBlockLists();

    s_affectsParentBlock =
        isFloatingOrOutOfFlowPositioned() && !newStyle.hasOutOfFlowPosition() &&
        parent() &&
        (parent()->isRenderParagraph() || parent()->isRenderInline());

    // Clearing these bits is required to avoid leaving stale renderers.
    // FIXME: We shouldn't need that hack if our logic was totally correct.
    if (diff.needsLayout()) {
      clearPositionedState();
    }
  } else {
    s_affectsParentBlock = false;
  }
}

void RenderObject::styleDidChange(StyleDifference diff,
                                  const RenderStyle* oldStyle) {
  if (s_affectsParentBlock) {
    // An object that was floating or positioned became a normal flow object
    // again.  We have to make sure the render tree updates as needed to
    // accommodate the new normal flow object.
    setInline(style()->isDisplayInlineType());
    ASSERT(isInline() == parent()->isRenderParagraph());
  }

  if (!m_parent)
    return;

  if (diff.needsFullLayout()) {
    // If the object already needs layout, then setNeedsLayout won't do
    // any work. But if the containing block has changed, then we may need
    // to mark the new containing blocks for layout. The change that can
    // directly affect the containing block of this object is a change to
    // the position style.
    if (needsLayout() && oldStyle->position() != m_style->position())
      markContainingBlocksForLayout();

    // Ditto.
    if (needsOverflowRecalcAfterStyleChange() &&
        oldStyle->position() != m_style->position())
      markContainingBlocksForOverflowRecalc();

    if (diff.needsFullLayout())
      setNeedsLayoutAndPrefWidthsRecalc();
  } else if (diff.needsPositionedMovementLayout())
    setNeedsPositionedMovementLayout();

  // Don't check for paint invalidation here; we need to wait until the layer
  // has been updated by subclasses before we know if we have to invalidate
  // paints (in setStyle()).
}

void RenderObject::updateFillImages(const FillLayer* oldLayers,
                                    const FillLayer& newLayers) {
  // Optimize the common case
  if (oldLayers && !oldLayers->next() && !newLayers.next() &&
      (oldLayers->image() == newLayers.image()))
    return;

  // Go through the new layers and addClients first, to avoid removing all
  // clients of an image.
  for (const FillLayer* currNew = &newLayers; currNew;
       currNew = currNew->next()) {
    if (currNew->image())
      currNew->image()->addClient(this);
  }

  for (const FillLayer* currOld = oldLayers; currOld;
       currOld = currOld->next()) {
    if (currOld->image())
      currOld->image()->removeClient(this);
  }
}

void RenderObject::updateImage(StyleImage* oldImage, StyleImage* newImage) {
  if (oldImage != newImage) {
    if (oldImage)
      oldImage->removeClient(this);
    if (newImage)
      newImage->addClient(this);
  }
}

FloatPoint RenderObject::localToAbsolute(const FloatPoint& localPoint,
                                         MapCoordinatesFlags mode) const {
  TransformState transformState(TransformState::ApplyTransformDirection,
                                localPoint);
  mapLocalToContainer(0, transformState, mode | ApplyContainerFlip);
  transformState.flatten();

  return transformState.lastPlanarPoint();
}

FloatPoint RenderObject::absoluteToLocal(const FloatPoint& containerPoint,
                                         MapCoordinatesFlags mode) const {
  TransformState transformState(
      TransformState::UnapplyInverseTransformDirection, containerPoint);
  mapAbsoluteToLocalPoint(mode, transformState);
  transformState.flatten();

  return transformState.lastPlanarPoint();
}

FloatQuad RenderObject::absoluteToLocalQuad(const FloatQuad& quad,
                                            MapCoordinatesFlags mode) const {
  TransformState transformState(
      TransformState::UnapplyInverseTransformDirection,
      quad.boundingBox().center(), quad);
  mapAbsoluteToLocalPoint(mode, transformState);
  transformState.flatten();
  return transformState.lastPlanarQuad();
}

void RenderObject::mapLocalToContainer(
    const RenderBox* paintInvalidationContainer,
    TransformState& transformState,
    MapCoordinatesFlags mode) const {
  if (paintInvalidationContainer == this)
    return;

  RenderObject* o = parent();
  if (!o)
    return;

  // FIXME: this should call offsetFromContainer to share code, but I'm not sure
  // it's ever called.
  if (mode & ApplyContainerFlip && o->isBox())
    mode &= ~ApplyContainerFlip;

  o->mapLocalToContainer(paintInvalidationContainer, transformState, mode);
}

const RenderObject* RenderObject::pushMappingToContainer(
    const RenderBox* ancestorToStopAt,
    RenderGeometryMap& geometryMap) const {
  ASSERT_UNUSED(ancestorToStopAt, ancestorToStopAt != this);

  RenderObject* container = parent();
  if (!container)
    return 0;
  // FIXME(sky): Do we need to make this call?
  geometryMap.push(this, LayoutSize(), false);
  return container;
}

void RenderObject::mapAbsoluteToLocalPoint(
    MapCoordinatesFlags mode,
    TransformState& transformState) const {
  RenderObject* o = parent();
  if (o)
    o->mapAbsoluteToLocalPoint(mode, transformState);
}

bool RenderObject::shouldUseTransformFromContainer(
    const RenderObject* containerObject) const {
  // hasTransform() indicates whether the object has transform, transform-style
  // or perspective. We just care about transform, so check the layer's
  // transform directly.
  return (isBox() && toRenderBox(this)->transform()) ||
         (containerObject && containerObject->style()->hasPerspective());
}

void RenderObject::getTransformFromContainer(
    const RenderObject* containerObject,
    const LayoutSize& offsetInContainer,
    TransformationMatrix& transform) const {
  transform.makeIdentity();
  transform.translate(offsetInContainer.width().toFloat(),
                      offsetInContainer.height().toFloat());
  TransformationMatrix* localTransform =
      isBox() ? toRenderBox(this)->transform() : 0;
  if (localTransform)
    transform.multiply(*localTransform);

  if (containerObject && containerObject->hasLayer() &&
      containerObject->style()->hasPerspective()) {
    // Perpsective on the container affects us, so we have to factor it in here.
    ASSERT(containerObject->hasLayer());
    FloatPoint perspectiveOrigin =
        toRenderBox(containerObject)->perspectiveOrigin();

    TransformationMatrix perspectiveMatrix;
    perspectiveMatrix.applyPerspective(containerObject->style()->perspective());

    transform.translateRight3d(-perspectiveOrigin.x(), -perspectiveOrigin.y(),
                               0);
    transform = perspectiveMatrix * transform;
    transform.translateRight3d(perspectiveOrigin.x(), perspectiveOrigin.y(), 0);
  }
}

FloatQuad RenderObject::localToContainerQuad(
    const FloatQuad& localQuad,
    const RenderBox* paintInvalidationContainer,
    MapCoordinatesFlags mode) const {
  // Track the point at the center of the quad's bounding box. As
  // mapLocalToContainer() calls offsetFromContainer(), it will use that point
  // as the reference point to decide which column's transform to apply in
  // multiple-column blocks.
  TransformState transformState(TransformState::ApplyTransformDirection,
                                localQuad.boundingBox().center(), localQuad);
  mapLocalToContainer(paintInvalidationContainer, transformState,
                      mode | ApplyContainerFlip | UseTransforms);
  transformState.flatten();

  return transformState.lastPlanarQuad();
}

FloatPoint RenderObject::localToContainerPoint(
    const FloatPoint& localPoint,
    const RenderBox* paintInvalidationContainer,
    MapCoordinatesFlags mode) const {
  TransformState transformState(TransformState::ApplyTransformDirection,
                                localPoint);
  mapLocalToContainer(paintInvalidationContainer, transformState,
                      mode | ApplyContainerFlip | UseTransforms);
  transformState.flatten();

  return transformState.lastPlanarPoint();
}

LayoutSize RenderObject::offsetFromContainer(const RenderObject* o,
                                             const LayoutPoint& point,
                                             bool* offsetDependsOnPoint) const {
  ASSERT(o == container());
  LayoutSize offset;
  if (offsetDependsOnPoint)
    *offsetDependsOnPoint = false;
  return offset;
}

LayoutSize RenderObject::offsetFromAncestorContainer(
    const RenderObject* container) const {
  LayoutSize offset;
  LayoutPoint referencePoint;
  const RenderObject* currContainer = this;
  do {
    const RenderObject* nextContainer = currContainer->container();
    ASSERT(nextContainer);  // This means we reached the top without finding
                            // container.
    if (!nextContainer)
      break;
    ASSERT(!currContainer->hasTransform());
    LayoutSize currentOffset =
        currContainer->offsetFromContainer(nextContainer, referencePoint);
    offset += currentOffset;
    referencePoint.move(currentOffset);
    currContainer = nextContainer;
  } while (currContainer != container);

  return offset;
}

LayoutRect RenderObject::localCaretRect(InlineBox*,
                                        int,
                                        LayoutUnit* extraWidthToEndOfLine) {
  if (extraWidthToEndOfLine)
    *extraWidthToEndOfLine = 0;

  return LayoutRect();
}

bool RenderObject::isRooted() const {
  const RenderObject* object = this;
  while (object->parent() && !object->hasLayer())
    object = object->parent();
  if (object->hasLayer())
    return toRenderBox(object)->layer()->root()->isRootLayer();
  return false;
}

RespectImageOrientationEnum RenderObject::shouldRespectImageOrientation()
    const {
  return DoNotRespectImageOrientation;
}

bool RenderObject::hasEntirelyFixedBackground() const {
  return m_style->hasEntirelyFixedBackground();
}

RenderObject* RenderObject::container(
    const RenderBox* paintInvalidationContainer,
    bool* paintInvalidationContainerSkipped) const {
  if (paintInvalidationContainerSkipped)
    *paintInvalidationContainerSkipped = false;

  // This method is extremely similar to containingBlock(), but with a few
  // notable exceptions. (1) It can be used on orphaned subtrees, i.e., it can
  // be called safely even when the object is not part of the primary document
  // subtree yet. (2) For normal flow elements, it just returns the parent. (3)
  // For absolute positioned elements, it will return a relative positioned
  // inline. containingBlock() simply skips relpositioned inlines and lets an
  // enclosing block handle the layout of the positioned object.  This does mean
  // that computePositionedLogicalWidth and computePositionedLogicalHeight have
  // to use container().
  RenderObject* o = parent();

  if (isText())
    return o;

  EPosition pos = m_style->position();
  if (pos == AbsolutePosition) {
    // We technically just want our containing block, but
    // we may not have one if we're part of an uninstalled
    // subtree. We'll climb as high as we can though.
    while (o) {
      if (o->style()->position() != StaticPosition)
        break;

      if (o->canContainAbsolutePositionObjects())
        break;

      if (paintInvalidationContainerSkipped && o == paintInvalidationContainer)
        *paintInvalidationContainerSkipped = true;

      o = o->parent();
    }
  }

  return o;
}

bool RenderObject::isSelectionBorder() const {
  SelectionState st = selectionState();
  return st == SelectionStart || st == SelectionEnd || st == SelectionBoth;
}

inline void RenderObject::clearLayoutRootIfNeeded() const {}

void RenderObject::willBeDestroyed() {
  // Destroy any leftover anonymous children.
  RenderObjectChildList* children = virtualChildren();
  if (children)
    children->destroyLeftoverChildren();

  remove();
  setAncestorLineBoxDirty(false);
  clearLayoutRootIfNeeded();
}

void RenderObject::insertedIntoTree() {
  // FIXME: We should ASSERT(isRooted()) here but generated content makes some
  // out-of-order insertion.

  // Keep our layer hierarchy updated. Optimize for the common case where we
  // don't have any children and don't have a layer attached to ourselves.
  RenderLayer* layer = 0;
  if (slowFirstChild() || hasLayer()) {
    layer = parent()->enclosingLayer();
    addLayers(layer);
  }

  if (parent()->isRenderParagraph())
    parent()->dirtyLinesFromChangedChild(this);
}

void RenderObject::willBeRemovedFromTree() {
  // FIXME: We should ASSERT(isRooted()) but we have some out-of-order removals
  // which would need to be fixed first.

  // Keep our layer hierarchy updated.
  if (slowFirstChild() || hasLayer())
    removeLayers(parent()->enclosingLayer());

  if (isOutOfFlowPositioned() && parent()->isRenderParagraph())
    parent()->dirtyLinesFromChangedChild(this);
}

void RenderObject::destroy() {
#if ENABLE(ASSERT) && ENABLE(OILPAN)
  ASSERT(!m_didCallDestroy);
  m_didCallDestroy = true;
#endif
  willBeDestroyed();
  postDestroy();
}

void RenderObject::postDestroy() {
  // It seems ugly that this is not in willBeDestroyed().
  if (m_style) {
    for (const FillLayer* bgLayer = &m_style->backgroundLayers(); bgLayer;
         bgLayer = bgLayer->next()) {
      if (StyleImage* backgroundImage = bgLayer->image())
        backgroundImage->removeClient(this);
    }
  }
  delete this;
}

PositionWithAffinity RenderObject::positionForPoint(const LayoutPoint&) {
  return createPositionWithAffinity(caretMinOffset(), DOWNSTREAM);
}

// FIXME(sky): Change the callers to use nodeAtPoint direclty and remove this
// function. Or, rename nodeAtPoint to hitTest?
bool RenderObject::hitTest(const HitTestRequest& request,
                           HitTestResult& result,
                           const HitTestLocation& locationInContainer,
                           const LayoutPoint& accumulatedOffset) {
  return nodeAtPoint(request, result, locationInContainer, accumulatedOffset);
}

void RenderObject::updateHitTestResult(HitTestResult& result,
                                       const LayoutPoint& point) {}

bool RenderObject::nodeAtPoint(const HitTestRequest&,
                               HitTestResult&,
                               const HitTestLocation& /*locationInContainer*/,
                               const LayoutPoint& /*accumulatedOffset*/) {
  return false;
}

void RenderObject::scheduleRelayout() {}

void RenderObject::forceLayout() {
  setSelfNeedsLayout(true);
  layout();
}

// FIXME: Does this do anything different than forceLayout given that we don't
// walk the containing block chain. If not, we should change all callers to use
// forceLayout.
void RenderObject::forceChildLayout() {
  setNormalChildNeedsLayout(true);
  layout();
}

void RenderObject::getTextDecorations(unsigned decorations,
                                      AppliedTextDecoration& underline,
                                      AppliedTextDecoration& overline,
                                      AppliedTextDecoration& linethrough,
                                      bool quirksMode,
                                      bool firstlineStyle) {
  RenderObject* curr = this;
  RenderStyle* styleToUse = 0;
  unsigned currDecs = TextDecorationNone;
  Color resultColor;
  TextDecorationStyle resultStyle;
  do {
    styleToUse = curr->style(firstlineStyle);
    currDecs = styleToUse->textDecoration();
    currDecs &= decorations;
    resultColor = styleToUse->decorationColor();
    resultStyle = styleToUse->textDecorationStyle();
    // Parameter 'decorations' is cast as an int to enable the bitwise
    // operations below.
    if (currDecs) {
      if (currDecs & TextDecorationUnderline) {
        decorations &= ~TextDecorationUnderline;
        underline.color = resultColor;
        underline.style = resultStyle;
      }
      if (currDecs & TextDecorationOverline) {
        decorations &= ~TextDecorationOverline;
        overline.color = resultColor;
        overline.style = resultStyle;
      }
      if (currDecs & TextDecorationLineThrough) {
        decorations &= ~TextDecorationLineThrough;
        linethrough.color = resultColor;
        linethrough.style = resultStyle;
      }
    }
    curr = curr->parent();
  } while (curr && decorations);

  // If we bailed out, use the element we bailed out at (typically a <font> or
  // <a> element).
  if (decorations && curr) {
    styleToUse = curr->style(firstlineStyle);
    resultColor = styleToUse->decorationColor();
    if (decorations & TextDecorationUnderline) {
      underline.color = resultColor;
      underline.style = resultStyle;
    }
    if (decorations & TextDecorationOverline) {
      overline.color = resultColor;
      overline.style = resultStyle;
    }
    if (decorations & TextDecorationLineThrough) {
      linethrough.color = resultColor;
      linethrough.style = resultStyle;
    }
  }
}

int RenderObject::caretMinOffset() const {
  return 0;
}

int RenderObject::caretMaxOffset() const {
  if (isReplaced())
    return 1;
  return 0;
}

int RenderObject::previousOffset(int current) const {
  return current - 1;
}

int RenderObject::previousOffsetForBackwardDeletion(int current) const {
  return current - 1;
}

int RenderObject::nextOffset(int current) const {
  return current + 1;
}

// touch-action applies to all elements with both width AND height properties.
// According to the CSS Box Model Spec
// (http://dev.w3.org/csswg/css-box/#the-width-and-height-properties) width
// applies to all elements but non-replaced inline elements, table rows, and row
// groups and height applies to all elements but non-replaced inline elements,
// table columns, and column groups.
bool RenderObject::supportsTouchAction() const {
  if (isInline() && !isReplaced())
    return false;
  return true;
}

PositionWithAffinity RenderObject::createPositionWithAffinity(
    int offset,
    EAffinity affinity) {
  return PositionWithAffinity(this, offset, affinity);
}

bool RenderObject::canUpdateSelectionOnRootLineBoxes() {
  if (needsLayout())
    return false;

  RenderBlock* containingBlock = this->containingBlock();
  return containingBlock ? !containingBlock->needsLayout() : false;
}

bool RenderObject::nodeAtFloatPoint(const HitTestRequest&,
                                    HitTestResult&,
                                    const FloatPoint&) {
  ASSERT_NOT_REACHED();
  return false;
}

}  // namespace blink

#ifndef NDEBUG

void showTree(const blink::RenderObject* object) {
  if (object)
    object->showTreeForThis();
}

void showLineTree(const blink::RenderObject* object) {
  if (object)
    object->showLineTreeForThis();
}

void showRenderTree(const blink::RenderObject* object1) {
  showRenderTree(object1, 0);
}

void showRenderTree(const blink::RenderObject* object1,
                    const blink::RenderObject* object2) {
  if (object1) {
    const blink::RenderObject* root = object1;
    while (root->parent())
      root = root->parent();
    root->showRenderTreeAndMark(object1, "*", object2, "-", 0);
  }
}

#endif
