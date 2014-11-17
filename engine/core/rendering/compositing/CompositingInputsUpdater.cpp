// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/rendering/compositing/CompositingInputsUpdater.h"

#include "core/rendering/RenderBlock.h"
#include "core/rendering/RenderLayer.h"
#include "core/rendering/compositing/CompositedLayerMapping.h"
#include "core/rendering/compositing/RenderLayerCompositor.h"
#include "platform/TraceEvent.h"

namespace blink {

CompositingInputsUpdater::CompositingInputsUpdater(RenderLayer* rootRenderLayer)
    : m_geometryMap(UseTransforms)
    , m_rootRenderLayer(rootRenderLayer)
{
}

CompositingInputsUpdater::~CompositingInputsUpdater()
{
}

void CompositingInputsUpdater::update()
{
    TRACE_EVENT0("blink", "CompositingInputsUpdater::update");
    updateRecursive(m_rootRenderLayer, DoNotForceUpdate, AncestorInfo());
}

static const RenderLayer* findParentLayerOnClippingContainerChain(const RenderLayer* layer)
{
    RenderObject* current = layer->renderer();
    while (current) {
        current = current->containingBlock();

        if (current->hasLayer())
            return static_cast<const RenderLayerModelObject*>(current)->layer();
        // Having clip or overflow clip forces the RenderObject to become a layer.
        ASSERT(!current->hasClipOrOverflowClip());
    }
    ASSERT_NOT_REACHED();
    return 0;
}

static const RenderLayer* findParentLayerOnContainingBlockChain(const RenderObject* object)
{
    for (const RenderObject* current = object; current; current = current->containingBlock()) {
        if (current->hasLayer())
            return static_cast<const RenderLayerModelObject*>(current)->layer();
    }
    ASSERT_NOT_REACHED();
    return 0;
}

static bool hasClippedStackingAncestor(const RenderLayer* layer, const RenderLayer* clippingLayer)
{
    if (layer == clippingLayer)
        return false;
    const RenderObject* clippingRenderer = clippingLayer->renderer();
    for (const RenderLayer* current = layer->compositingContainer(); current && current != clippingLayer; current = current->compositingContainer()) {
        if (current->renderer()->hasClipOrOverflowClip() && !clippingRenderer->isDescendantOf(current->renderer()))
            return true;

        if (const RenderObject* container = current->clippingContainer()) {
            if (clippingRenderer != container && !clippingRenderer->isDescendantOf(container))
                return true;
        }
    }
    return false;
}

void CompositingInputsUpdater::updateRecursive(RenderLayer* layer, UpdateType updateType, AncestorInfo info)
{
    if (!layer->childNeedsCompositingInputsUpdate() && updateType != ForceUpdate)
        return;

    m_geometryMap.pushMappingsToAncestor(layer, layer->parent());

    if (layer->hasCompositedLayerMapping())
        info.enclosingCompositedLayer = layer;

    if (layer->needsCompositingInputsUpdate()) {
        if (info.enclosingCompositedLayer)
            info.enclosingCompositedLayer->compositedLayerMapping()->setNeedsGraphicsLayerUpdate(GraphicsLayerUpdateSubtree);
        updateType = ForceUpdate;
    }

    if (updateType == ForceUpdate) {
        RenderLayer::AncestorDependentCompositingInputs properties;

        if (!layer->isRootLayer()) {
            properties.clippedAbsoluteBoundingBox = enclosingIntRect(m_geometryMap.absoluteRect(layer->boundingBoxForCompositingOverlapTest()));
            // FIXME: Setting the absBounds to 1x1 instead of 0x0 makes very little sense,
            // but removing this code will make JSGameBench sad.
            // See https://codereview.chromium.org/13912020/
            if (properties.clippedAbsoluteBoundingBox.isEmpty())
                properties.clippedAbsoluteBoundingBox.setSize(IntSize(1, 1));

            IntRect clipRect = pixelSnappedIntRect(layer->clipper().backgroundClipRect(ClipRectsContext(m_rootRenderLayer, AbsoluteClipRects)).rect());
            properties.clippedAbsoluteBoundingBox.intersect(clipRect);

            const RenderLayer* parent = layer->parent();
            properties.opacityAncestor = parent->isTransparent() ? parent : parent->opacityAncestor();
            properties.transformAncestor = parent->hasTransform() ? parent : parent->transformAncestor();
            properties.filterAncestor = parent->hasFilter() ? parent : parent->filterAncestor();

            if (info.hasAncestorWithClipOrOverflowClip) {
                const RenderLayer* parentLayerOnClippingContainerChain = findParentLayerOnClippingContainerChain(layer);
                const bool parentHasClipOrOverflowClip = parentLayerOnClippingContainerChain->renderer()->hasClipOrOverflowClip();
                properties.clippingContainer = parentHasClipOrOverflowClip ? parentLayerOnClippingContainerChain->renderer() : parentLayerOnClippingContainerChain->clippingContainer();
            }

            if (info.lastScrollingAncestor) {
                const RenderObject* containingBlock = layer->renderer()->containingBlock();
                const RenderLayer* parentLayerOnContainingBlockChain = findParentLayerOnContainingBlockChain(containingBlock);

                properties.ancestorScrollingLayer = parentLayerOnContainingBlockChain->ancestorScrollingLayer();
                if (parentLayerOnContainingBlockChain->scrollsOverflow())
                    properties.ancestorScrollingLayer = parentLayerOnContainingBlockChain;

                if (layer->renderer()->isOutOfFlowPositioned()) {
                    const RenderObject* lastScroller = info.lastScrollingAncestor->renderer();
                    const RenderLayer* clippingLayer = properties.clippingContainer ? properties.clippingContainer->enclosingLayer() : layer->compositor()->rootRenderLayer();
                    properties.isUnclippedDescendant = lastScroller != containingBlock && lastScroller->isDescendantOf(containingBlock);
                    if (hasClippedStackingAncestor(layer, clippingLayer))
                        properties.clipParent = clippingLayer;
                }

                if (!layer->stackingNode()->isNormalFlowOnly()
                    && properties.ancestorScrollingLayer
                    && !info.ancestorStackingContext->renderer()->isDescendantOf(properties.ancestorScrollingLayer->renderer()))
                    properties.scrollParent = properties.ancestorScrollingLayer;
            }
        }

        properties.hasAncestorWithClipPath = info.hasAncestorWithClipPath;
        layer->updateAncestorDependentCompositingInputs(properties);
    }

    if (layer->stackingNode()->isStackingContext())
        info.ancestorStackingContext = layer;

    if (layer->scrollsOverflow())
        info.lastScrollingAncestor = layer;

    if (layer->renderer()->hasClipOrOverflowClip())
        info.hasAncestorWithClipOrOverflowClip = true;

    if (layer->renderer()->hasClipPath())
        info.hasAncestorWithClipPath = true;

    RenderLayer::DescendantDependentCompositingInputs descendantProperties;
    for (RenderLayer* child = layer->firstChild(); child; child = child->nextSibling()) {
        updateRecursive(child, updateType, info);

        descendantProperties.hasDescendantWithClipPath |= child->hasDescendantWithClipPath() || child->renderer()->hasClipPath();
    }

    layer->updateDescendantDependentCompositingInputs(descendantProperties);
    layer->didUpdateCompositingInputs();

    m_geometryMap.popMappingsToAncestor(layer->parent());
}

#if ENABLE(ASSERT)

void CompositingInputsUpdater::assertNeedsCompositingInputsUpdateBitsCleared(RenderLayer* layer)
{
    ASSERT(!layer->childNeedsCompositingInputsUpdate());
    ASSERT(!layer->needsCompositingInputsUpdate());

    for (RenderLayer* child = layer->firstChild(); child; child = child->nextSibling())
        assertNeedsCompositingInputsUpdateBitsCleared(child);
}

#endif

} // namespace blink
