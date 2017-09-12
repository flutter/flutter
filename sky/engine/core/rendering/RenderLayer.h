/*
 * Copyright (C) 2003, 2009, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Intel Corporation. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_RENDERING_RENDERLAYER_H_
#define SKY_ENGINE_CORE_RENDERING_RENDERLAYER_H_

#include "flutter/sky/engine/core/rendering/LayerPaintingInfo.h"
#include "flutter/sky/engine/core/rendering/RenderBox.h"
#include "flutter/sky/engine/core/rendering/RenderLayerClipper.h"
#include "flutter/sky/engine/core/rendering/RenderLayerStackingNode.h"
#include "flutter/sky/engine/core/rendering/RenderLayerStackingNodeIterator.h"
#include "flutter/sky/engine/public/platform/WebBlendMode.h"
#include "flutter/sky/engine/wtf/OwnPtr.h"

namespace blink {

class RenderStyle;

enum BorderRadiusClippingRule {
  IncludeSelfForBorderRadius,
  DoNotIncludeSelfForBorderRadius
};
enum IncludeSelfOrNot { IncludeSelf, ExcludeSelf };

class RenderLayer {
  WTF_MAKE_NONCOPYABLE(RenderLayer);

 public:
  RenderLayer(RenderBox*, LayerType);
  ~RenderLayer();

  RenderBox* renderer() const { return m_renderer; }
  RenderLayer* parent() const { return m_parent; }
  RenderLayer* previousSibling() const { return m_previous; }
  RenderLayer* nextSibling() const { return m_next; }
  RenderLayer* firstChild() const { return m_first; }
  RenderLayer* lastChild() const { return m_last; }

  void addChild(RenderLayer* newChild, RenderLayer* beforeChild = 0);
  RenderLayer* removeChild(RenderLayer*);

  void removeOnlyThisLayer();
  void insertOnlyThisLayer();

  void styleChanged(StyleDifference, const RenderStyle* oldStyle);
  bool isSelfPaintingLayer() const { return m_isSelfPaintingLayer; }
  void setLayerType(LayerType layerType) { m_layerType = layerType; }

  const RenderLayer* root() const {
    const RenderLayer* curr = this;
    while (curr->parent())
      curr = curr->parent();
    return curr;
  }

  LayoutPoint location() const;
  IntSize size() const;
  LayoutRect rect() const { return LayoutRect(location(), size()); }

  bool isRootLayer() const { return m_isRootLayer; }

  void updateLayerPositionsAfterLayout();

  RenderLayerStackingNode* stackingNode() { return m_stackingNode.get(); }
  const RenderLayerStackingNode* stackingNode() const {
    return m_stackingNode.get();
  }

  // Gets the nearest enclosing positioned ancestor layer (also includes
  // the <html> layer and the root layer).
  RenderLayer* enclosingPositionedAncestor() const;

  const RenderLayer* compositingContainer() const;

  void convertToLayerCoords(const RenderLayer* ancestorLayer,
                            LayoutPoint&) const;
  void convertToLayerCoords(const RenderLayer* ancestorLayer,
                            LayoutRect&) const;

  // Pass offsetFromRoot if known.
  bool intersectsDamageRect(const LayoutRect& layerBounds,
                            const LayoutRect& damageRect,
                            const RenderLayer* rootLayer,
                            const LayoutPoint* offsetFromRoot = 0) const;

  // Bounding box relative to some ancestor layer. Pass offsetFromRoot if known.
  LayoutRect physicalBoundingBox(const RenderLayer* ancestorLayer,
                                 const LayoutPoint* offsetFromRoot = 0) const;
  LayoutRect physicalBoundingBoxIncludingReflectionAndStackingChildren(
      const RenderLayer* ancestorLayer,
      const LayoutPoint& offsetFromRoot) const;
  LayoutRect boundingBoxForCompositing(
      const RenderLayer* ancestorLayer = 0) const;

  bool has3DTransformedDescendant() const {
    return m_has3DTransformedDescendant;
  }
  // Both updates the status, and returns true if descendants of this have 3d.
  bool update3DTransformedDescendantStatus();

  void* operator new(size_t);
  // Only safe to call from RenderBox::destroyLayer()
  void operator delete(void*);

  RenderLayerClipper& clipper() { return m_clipper; }
  const RenderLayerClipper& clipper() const { return m_clipper; }

  inline bool isPositionedContainer() const {
    // FIXME: This is not in sync with containingBlock.
    return isRootLayer() || renderer()->isPositioned() ||
           renderer()->hasTransform();
  }

  void clipToRect(const LayerPaintingInfo&,
                  GraphicsContext*,
                  const ClipRect&,
                  BorderRadiusClippingRule = IncludeSelfForBorderRadius);
  void restoreClip(GraphicsContext*,
                   const LayoutRect& paintDirtyRect,
                   const ClipRect&);

  // Bounding box in the coordinates of this layer.
  LayoutRect logicalBoundingBox() const;

  void setNextSibling(RenderLayer* next) { m_next = next; }
  void setPreviousSibling(RenderLayer* prev) { m_previous = prev; }
  void setFirstChild(RenderLayer* first) { m_first = first; }
  void setLastChild(RenderLayer* last) { m_last = last; }

  bool shouldBeSelfPaintingLayer() const;

  void dirty3DTransformedDescendantStatus();

 private:
  LayerType m_layerType;

  // Self-painting layer is an optimization where we avoid the heavy RenderLayer
  // painting machinery for a RenderLayer allocated only to handle the overflow
  // clip case.
  // FIXME(crbug.com/332791): Self-painting layer should be merged into the
  // overflow-only concept.
  unsigned m_isSelfPaintingLayer : 1;

  const unsigned m_isRootLayer : 1;

  unsigned m_3DTransformedDescendantStatusDirty : 1;
  // Set on a stacking context layer that has 3D descendants anywhere
  // in a preserves3D hierarchy. Hint to do 3D-aware hit testing.
  unsigned m_has3DTransformedDescendant : 1;

  RenderBox* m_renderer;

  RenderLayer* m_parent;
  RenderLayer* m_previous;
  RenderLayer* m_next;
  RenderLayer* m_first;
  RenderLayer* m_last;

  RenderLayerClipper m_clipper;  // FIXME: Lazily allocate?
  OwnPtr<RenderLayerStackingNode> m_stackingNode;
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_RENDERLAYER_H_
