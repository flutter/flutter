/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2006, 2007, 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2010, 2012 Google Inc. All rights reserved.
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

#ifndef RenderLayerModelObject_h
#define RenderLayerModelObject_h

#include "core/rendering/RenderObject.h"

namespace blink {

class RenderLayer;
class CompositedLayerMapping;
class ScrollableArea;

enum LayerType {
    NoLayer,
    NormalLayer,
    // A forced or overflow clip layer is required for bookkeeping purposes,
    // but does not force a layer to be self painting.
    OverflowClipLayer,
    ForcedLayer
};

class RenderLayerModelObject : public RenderObject {
public:
    explicit RenderLayerModelObject(ContainerNode*);
    virtual ~RenderLayerModelObject();

    // This is the only way layers should ever be destroyed.
    void destroyLayer();

    bool hasSelfPaintingLayer() const;
    RenderLayer* layer() const { return m_layer.get(); }
    ScrollableArea* scrollableArea() const;

    virtual void styleWillChange(StyleDifference, const RenderStyle& newStyle) OVERRIDE;
    virtual void styleDidChange(StyleDifference, const RenderStyle* oldStyle) OVERRIDE;
    virtual void updateFromStyle() { }

    virtual LayerType layerTypeRequired() const = 0;

    // Returns true if the background is painted opaque in the given rect.
    // The query rect is given in local coordinate system.
    virtual bool backgroundIsKnownToBeOpaqueInRect(const LayoutRect&) const { return false; }

    // This is null for anonymous renderers.
    ContainerNode* node() const { return toContainerNode(RenderObject::node()); }

    virtual void invalidateTreeIfNeeded(const PaintInvalidationState&) OVERRIDE;
protected:
    void createLayer(LayerType);

    virtual void willBeDestroyed() OVERRIDE;

    virtual void addLayerHitTestRects(LayerHitTestRects&, const RenderLayer*, const LayoutPoint&, const LayoutRect&) const OVERRIDE;

    virtual InvalidationReason invalidatePaintIfNeeded(const PaintInvalidationState&, const RenderLayerModelObject& newPaintInvalidationContainer);
private:
    virtual bool isLayerModelObject() const OVERRIDE FINAL { return true; }

    OwnPtr<RenderLayer> m_layer;

    // Used to store state between styleWillChange and styleDidChange
    static bool s_wasFloating;
};

DEFINE_RENDER_OBJECT_TYPE_CASTS(RenderLayerModelObject, isLayerModelObject());

} // namespace blink

#endif // RenderLayerModelObject_h
