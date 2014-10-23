/*
 * Copyright (C) 2009, 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2014 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/rendering/compositing/GraphicsLayerUpdater.h"

#include "core/html/HTMLMediaElement.h"
#include "core/rendering/RenderLayer.h"
#include "core/rendering/RenderPart.h"
#include "core/rendering/compositing/CompositedLayerMapping.h"
#include "core/rendering/compositing/RenderLayerCompositor.h"
#include "platform/TraceEvent.h"

namespace blink {

class GraphicsLayerUpdater::UpdateContext {
public:
    UpdateContext()
        : m_compositingStackingContext(0)
        , m_compositingAncestor(0)
    {
    }

    UpdateContext(const UpdateContext& other, const RenderLayer& layer)
        : m_compositingStackingContext(other.m_compositingStackingContext)
        , m_compositingAncestor(other.compositingContainer(layer))
    {
        CompositingState compositingState = layer.compositingState();
        if (compositingState != NotComposited && compositingState != PaintsIntoGroupedBacking) {
            m_compositingAncestor = &layer;
            if (layer.stackingNode()->isStackingContext())
                m_compositingStackingContext = &layer;
        }
    }

    const RenderLayer* compositingContainer(const RenderLayer& layer) const
    {
        return layer.stackingNode()->isNormalFlowOnly() ? m_compositingAncestor : m_compositingStackingContext;
    }

    const RenderLayer* compositingStackingContext() const
    {
        return m_compositingStackingContext;
    }

private:
    const RenderLayer* m_compositingStackingContext;
    const RenderLayer* m_compositingAncestor;
};

GraphicsLayerUpdater::GraphicsLayerUpdater()
    : m_needsRebuildTree(false)
{
}

GraphicsLayerUpdater::~GraphicsLayerUpdater()
{
}

void GraphicsLayerUpdater::update(RenderLayer& layer, Vector<RenderLayer*>& layersNeedingPaintInvalidation)
{
    TRACE_EVENT0("blink", "GraphicsLayerUpdater::update");
    updateRecursive(layer, DoNotForceUpdate, UpdateContext(), layersNeedingPaintInvalidation);
    layer.compositor()->updateRootLayerPosition();
}

void GraphicsLayerUpdater::updateRecursive(RenderLayer& layer, UpdateType updateType, const UpdateContext& context, Vector<RenderLayer*>& layersNeedingPaintInvalidation)
{
    if (layer.hasCompositedLayerMapping()) {
        CompositedLayerMapping* mapping = layer.compositedLayerMapping();

        if (updateType == ForceUpdate || mapping->needsGraphicsLayerUpdate()) {
            const RenderLayer* compositingContainer = context.compositingContainer(layer);
            ASSERT(compositingContainer == layer.enclosingLayerWithCompositedLayerMapping(ExcludeSelf));

            if (mapping->updateRequiresOwnBackingStoreForAncestorReasons(compositingContainer)) {
                layersNeedingPaintInvalidation.append(&layer);
                updateType = ForceUpdate;
            }

            if (mapping->updateGraphicsLayerConfiguration())
                m_needsRebuildTree = true;

            mapping->updateGraphicsLayerGeometry(compositingContainer, context.compositingStackingContext(), layersNeedingPaintInvalidation);

            if (mapping->hasUnpositionedOverflowControlsLayers())
                layer.scrollableArea()->positionOverflowControls(IntSize());

            updateType = mapping->updateTypeForChildren(updateType);
            mapping->clearNeedsGraphicsLayerUpdate();
        }
    }

    UpdateContext childContext(context, layer);
    for (RenderLayer* child = layer.firstChild(); child; child = child->nextSibling())
        updateRecursive(*child, updateType, childContext, layersNeedingPaintInvalidation);
}

#if ENABLE(ASSERT)

void GraphicsLayerUpdater::assertNeedsToUpdateGraphicsLayerBitsCleared(RenderLayer& layer)
{
    if (layer.hasCompositedLayerMapping())
        layer.compositedLayerMapping()->assertNeedsToUpdateGraphicsLayerBitsCleared();

    for (RenderLayer* child = layer.firstChild(); child; child = child->nextSibling())
        assertNeedsToUpdateGraphicsLayerBitsCleared(*child);
}

#endif

} // namespace blink
