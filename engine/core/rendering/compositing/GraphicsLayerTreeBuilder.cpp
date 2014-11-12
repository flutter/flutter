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
#include "core/rendering/compositing/GraphicsLayerTreeBuilder.h"

#include "core/rendering/RenderLayer.h"
#include "core/rendering/RenderView.h"
#include "core/rendering/compositing/CompositedLayerMapping.h"
#include "core/rendering/compositing/RenderLayerCompositor.h"

namespace blink {

GraphicsLayerTreeBuilder::GraphicsLayerTreeBuilder()
{
}

GraphicsLayerTreeBuilder::~GraphicsLayerTreeBuilder()
{
}

void GraphicsLayerTreeBuilder::rebuild(RenderLayer& layer, AncestorInfo info)
{
    // Make the layer compositing if necessary, and set up clipping and content layers.
    // Note that we can only do work here that is independent of whether the descendant layers
    // have been processed. computeCompositingRequirements() will already have done the paint invalidation if necessary.

    layer.stackingNode()->updateLayerListsIfNeeded();

    const bool hasCompositedLayerMapping = layer.hasCompositedLayerMapping();
    CompositedLayerMapping* currentCompositedLayerMapping = layer.compositedLayerMapping();

    // If this layer has a compositedLayerMapping, then that is where we place subsequent children GraphicsLayers.
    // Otherwise children continue to append to the child list of the enclosing layer.
    GraphicsLayerVector layerChildren;
    AncestorInfo infoForChildren(info);
    if (hasCompositedLayerMapping) {
        infoForChildren.childLayersOfEnclosingCompositedLayer = &layerChildren;
        infoForChildren.enclosingCompositedLayer = &layer;
    }

#if ENABLE(ASSERT)
    LayerListMutationDetector mutationChecker(layer.stackingNode());
#endif

    if (layer.stackingNode()->isStackingContext()) {
        RenderLayerStackingNodeIterator iterator(*layer.stackingNode(), NegativeZOrderChildren);
        while (RenderLayerStackingNode* curNode = iterator.next())
            rebuild(*curNode->layer(), infoForChildren);

        // If a negative z-order child is compositing, we get a foreground layer which needs to get parented.
        if (hasCompositedLayerMapping && currentCompositedLayerMapping->foregroundLayer())
            infoForChildren.childLayersOfEnclosingCompositedLayer->append(currentCompositedLayerMapping->foregroundLayer());
    }

    RenderLayerStackingNodeIterator iterator(*layer.stackingNode(), NormalFlowChildren | PositiveZOrderChildren);
    while (RenderLayerStackingNode* curNode = iterator.next())
        rebuild(*curNode->layer(), infoForChildren);

    if (hasCompositedLayerMapping) {
        currentCompositedLayerMapping->parentForSublayers()->setChildren(layerChildren);

        info.childLayersOfEnclosingCompositedLayer->append(currentCompositedLayerMapping->childForSuperlayers());
    }

    if (layer.scrollParent()
        && layer.scrollParent()->hasCompositedLayerMapping()
        && layer.scrollParent()->compositedLayerMapping()->needsToReparentOverflowControls()
        && layer.scrollParent()->scrollableArea()->topmostScrollChild() == &layer)
        info.childLayersOfEnclosingCompositedLayer->append(layer.scrollParent()->compositedLayerMapping()->detachLayerForOverflowControls(*info.enclosingCompositedLayer));
}

}
