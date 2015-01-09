/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2005 Allan Sandfeld Jensen (kde@carewolf.com)
 *           (C) 2005, 2006 Samuel Weinig (sam.weinig@gmail.com)
 * Copyright (C) 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
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

#include "sky/engine/config.h"
#include "sky/engine/core/rendering/RenderLayerModelObject.h"

#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/rendering/RenderLayer.h"
#include "sky/engine/core/rendering/RenderView.h"

namespace blink {

RenderLayerModelObject::RenderLayerModelObject(ContainerNode* node)
    : RenderObject(node)
{
}

RenderLayerModelObject::~RenderLayerModelObject()
{
    // Our layer should have been destroyed and cleared by now
    ASSERT(!hasLayer());
    ASSERT(!m_layer);
}

void RenderLayerModelObject::destroyLayer()
{
    setHasLayer(false);
    m_layer = nullptr;
}

void RenderLayerModelObject::createLayer(LayerType type)
{
    ASSERT(!m_layer);
    m_layer = adoptPtr(new RenderLayer(this, type));
    setHasLayer(true);
    m_layer->insertOnlyThisLayer();
}

bool RenderLayerModelObject::hasSelfPaintingLayer() const
{
    return m_layer && m_layer->isSelfPaintingLayer();
}

ScrollableArea* RenderLayerModelObject::scrollableArea() const
{
    return m_layer ? m_layer->scrollableArea() : 0;
}

void RenderLayerModelObject::willBeDestroyed()
{
    RenderObject::willBeDestroyed();
    destroyLayer();
}

void RenderLayerModelObject::styleWillChange(StyleDifference diff, const RenderStyle& newStyle)
{
    if (RenderStyle* oldStyle = style()) {
        if (parent() && diff.needsPaintInvalidationLayer()) {
            if (oldStyle->hasAutoClip() != newStyle.hasAutoClip()
                || oldStyle->clip() != newStyle.clip())
                layer()->clipper().clearClipRectsIncludingDescendants();
        }
    }

    RenderObject::styleWillChange(diff, newStyle);
}

void RenderLayerModelObject::styleDidChange(StyleDifference diff, const RenderStyle* oldStyle)
{
    bool hadTransform = hasTransform();

    RenderObject::styleDidChange(diff, oldStyle);
    updateFromStyle();

    LayerType type = layerTypeRequired();
    if (type != NoLayer) {
        if (!layer()) {
            createLayer(type);
            if (parent() && !needsLayout()) {
                // FIXME: This invalidation is overly broad. We should update to
                // do the correct invalidation at RenderStyle::diff time. crbug.com/349061
                layer()->renderer()->setShouldDoFullPaintInvalidation(true);
                // FIXME: We should call a specialized version of this function.
                layer()->updateLayerPositionsAfterLayout();
            }
        }
    } else if (layer() && layer()->parent()) {
        setHasTransform(false); // Either a transform wasn't specified or the object doesn't support transforms, so just null out the bit.
        layer()->removeOnlyThisLayer(); // calls destroyLayer() which clears m_layer
        if (hadTransform)
            setNeedsLayoutAndPrefWidthsRecalcAndFullPaintInvalidation();
    }

    if (layer()) {
        // FIXME: Ideally we shouldn't need this setter but we can't easily infer an overflow-only layer
        // from the style.
        layer()->setLayerType(type);
        layer()->styleChanged(diff, oldStyle);
    }
}

void RenderLayerModelObject::invalidateTreeIfNeeded(const PaintInvalidationState& paintInvalidationState)
{
    // FIXME: SVG should probably also go through this unified paint invalidation system.
    ASSERT(!needsLayout());

    if (!shouldCheckForPaintInvalidation(paintInvalidationState))
        return;

    const RenderLayerModelObject& newPaintInvalidationContainer = *adjustCompositedContainerForSpecialAncestors(&paintInvalidationState.paintInvalidationContainer());
    ASSERT(&newPaintInvalidationContainer == containerForPaintInvalidation());

    PaintInvalidationState childTreeWalkState(paintInvalidationState, *this, newPaintInvalidationContainer);
    RenderObject::invalidateTreeIfNeeded(childTreeWalkState);
}

} // namespace blink

