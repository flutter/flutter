/*
 * Copyright (C) 2009, 2010 Apple Inc. All rights reserved.
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

#include "sky/engine/config.h"

#include "sky/engine/core/rendering/compositing/RenderLayerCompositor.h"

#include "gen/sky/platform/RuntimeEnabledFeatures.h"
#include "sky/engine/core/animation/DocumentAnimations.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/core/inspector/InspectorNodeIds.h"
#include "sky/engine/core/page/Chrome.h"
#include "sky/engine/core/page/ChromeClient.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/rendering/RenderLayerStackingNode.h"
#include "sky/engine/core/rendering/RenderLayerStackingNodeIterator.h"
#include "sky/engine/core/rendering/RenderView.h"
#include "sky/engine/core/rendering/compositing/CompositedLayerMapping.h"
#include "sky/engine/core/rendering/compositing/CompositingInputsUpdater.h"
#include "sky/engine/core/rendering/compositing/CompositingLayerAssigner.h"
#include "sky/engine/core/rendering/compositing/CompositingRequirementsUpdater.h"
#include "sky/engine/core/rendering/compositing/GraphicsLayerTreeBuilder.h"
#include "sky/engine/core/rendering/compositing/GraphicsLayerUpdater.h"
#include "sky/engine/platform/ScriptForbiddenScope.h"
#include "sky/engine/platform/TraceEvent.h"
#include "sky/engine/platform/graphics/GraphicsLayer.h"
#include "sky/engine/public/platform/Platform.h"

namespace blink {

RenderLayerCompositor::RenderLayerCompositor(RenderView& renderView)
    : m_renderView(renderView)
    , m_compositingReasonFinder(renderView)
    , m_pendingUpdateType(CompositingUpdateNone)
    , m_compositing(false)
    , m_rootShouldAlwaysCompositeDirty(true)
    , m_needsUpdateFixedBackground(false)
    , m_isTrackingPaintInvalidations(false)
    , m_rootLayerAttachment(RootLayerUnattached)
{
    updateAcceleratedCompositingSettings();
}

RenderLayerCompositor::~RenderLayerCompositor()
{
    ASSERT(m_rootLayerAttachment == RootLayerUnattached);
}

bool RenderLayerCompositor::inCompositingMode() const
{
    // FIXME: This should assert that lificycle is >= CompositingClean since
    // the last step of updateIfNeeded can set this bit to false.
    ASSERT(!m_rootShouldAlwaysCompositeDirty);
    return m_compositing;
}

bool RenderLayerCompositor::staleInCompositingMode() const
{
    return m_compositing;
}

void RenderLayerCompositor::setCompositingModeEnabled(bool enable)
{
    if (enable == m_compositing)
        return;

    m_compositing = enable;

    if (m_compositing)
        ensureRootLayer();
    else
        destroyRootLayer();
}

void RenderLayerCompositor::enableCompositingModeIfNeeded()
{
    if (!m_rootShouldAlwaysCompositeDirty)
        return;

    m_rootShouldAlwaysCompositeDirty = false;
    if (m_compositing)
        return;

    if (rootShouldAlwaysComposite()) {
        // FIXME: Is this needed? It was added in https://bugs.webkit.org/show_bug.cgi?id=26651.
        // No tests fail if it's deleted.
        setNeedsCompositingUpdate(CompositingUpdateRebuildTree);
        setCompositingModeEnabled(true);
    }
}

bool RenderLayerCompositor::rootShouldAlwaysComposite() const
{
    return false;
}

void RenderLayerCompositor::updateAcceleratedCompositingSettings()
{
    m_compositingReasonFinder.updateTriggers();
    m_rootShouldAlwaysCompositeDirty = true;
}

bool RenderLayerCompositor::hasAcceleratedCompositing() const
{
    return false;
}

bool RenderLayerCompositor::layerSquashingEnabled() const
{
    if (!RuntimeEnabledFeatures::layerSquashingEnabled())
        return false;
    return true;
}

bool RenderLayerCompositor::preferCompositingToLCDTextEnabled() const
{
    return m_compositingReasonFinder.hasOverflowScrollTrigger();
}

void RenderLayerCompositor::updateIfNeededRecursive()
{
    TRACE_EVENT0("blink", "RenderLayerCompositor::updateIfNeededRecursive");

    ASSERT(!m_renderView.needsLayout());

    ScriptForbiddenScope forbidScript;

    // FIXME: enableCompositingModeIfNeeded can trigger a CompositingUpdateRebuildTree,
    // which asserts that it's not InCompositingUpdate.
    enableCompositingModeIfNeeded();

    lifecycle().advanceTo(DocumentLifecycle::InCompositingUpdate);
    updateIfNeeded();
    lifecycle().advanceTo(DocumentLifecycle::CompositingClean);

    DocumentAnimations::startPendingAnimations(m_renderView.document());

#if ENABLE(ASSERT)
    ASSERT(lifecycle().state() == DocumentLifecycle::CompositingClean);
    assertNoUnresolvedDirtyBits();
#endif
}

void RenderLayerCompositor::setNeedsCompositingUpdate(CompositingUpdateType updateType)
{
    ASSERT(updateType != CompositingUpdateNone);
    m_pendingUpdateType = std::max(m_pendingUpdateType, updateType);
    page()->animator().scheduleVisualUpdate();
    lifecycle().ensureStateAtMost(DocumentLifecycle::LayoutClean);
}

void RenderLayerCompositor::didLayout()
{
    // FIXME: Technically we only need to do this when the FrameView's
    // isScrollable method would return a different value.
    m_rootShouldAlwaysCompositeDirty = true;
    enableCompositingModeIfNeeded();

    // FIXME: Rather than marking the entire RenderView as dirty, we should
    // track which RenderLayers moved during layout and only dirty those
    // specific RenderLayers.
    rootRenderLayer()->setNeedsCompositingInputsUpdate();
}

#if ENABLE(ASSERT)

void RenderLayerCompositor::assertNoUnresolvedDirtyBits()
{
    ASSERT(m_pendingUpdateType == CompositingUpdateNone);
    ASSERT(!m_rootShouldAlwaysCompositeDirty);
}

#endif

void RenderLayerCompositor::updateWithoutAcceleratedCompositing(CompositingUpdateType updateType)
{
    ASSERT(!hasAcceleratedCompositing());

    if (updateType >= CompositingUpdateAfterCompositingInputChange)
        CompositingInputsUpdater(rootRenderLayer()).update();

#if ENABLE(ASSERT)
    CompositingInputsUpdater::assertNeedsCompositingInputsUpdateBitsCleared(rootRenderLayer());
#endif
}

void RenderLayerCompositor::updateIfNeeded()
{
    m_pendingUpdateType = CompositingUpdateNone;
}

bool RenderLayerCompositor::allocateOrClearCompositedLayerMapping(RenderLayer* layer, const CompositingStateTransitionType compositedLayerUpdate)
{
    bool compositedLayerMappingChanged = false;

    // FIXME: It would be nice to directly use the layer's compositing reason,
    // but allocateOrClearCompositedLayerMapping also gets called without having updated compositing
    // requirements fully.
    switch (compositedLayerUpdate) {
    case AllocateOwnCompositedLayerMapping:
        ASSERT(!layer->hasCompositedLayerMapping());
        setCompositingModeEnabled(true);

        // If we need to issue paint invalidations, do so before allocating the compositedLayerMapping and clearing out the groupedMapping.
        paintInvalidationOnCompositingChange(layer);

        // If this layer was previously squashed, we need to remove its reference to a groupedMapping right away, so
        // that computing paint invalidation rects will know the layer's correct compositingState.
        // FIXME: do we need to also remove the layer from it's location in the squashing list of its groupedMapping?
        // Need to create a test where a squashed layer pops into compositing. And also to cover all other
        // sorts of compositingState transitions.
        layer->setLostGroupedMapping(false);
        layer->setGroupedMapping(0);

        layer->ensureCompositedLayerMapping();
        compositedLayerMappingChanged = true;
        break;
    case RemoveOwnCompositedLayerMapping:
    // PutInSquashingLayer means you might have to remove the composited layer mapping first.
    case PutInSquashingLayer:
        if (layer->hasCompositedLayerMapping()) {
            layer->clearCompositedLayerMapping();
            compositedLayerMappingChanged = true;
        }

        break;
    case RemoveFromSquashingLayer:
    case NoCompositingStateChange:
        // Do nothing.
        break;
    }

    if (layer->hasCompositedLayerMapping() && layer->compositedLayerMapping()->updateRequiresOwnBackingStoreForIntrinsicReasons())
        compositedLayerMappingChanged = true;

    if (compositedLayerMappingChanged)
        layer->clipper().clearClipRectsIncludingDescendants(PaintingClipRects);

    return compositedLayerMappingChanged;
}

void RenderLayerCompositor::paintInvalidationOnCompositingChange(RenderLayer* layer)
{
    // If the renderer is not attached yet, no need to issue paint invalidations.
    if (layer->renderer() != &m_renderView && !layer->renderer()->parent())
        return;

    // For querying RenderLayer::compositingState()
    // Eager invalidation here is correct, since we are invalidating with respect to the previous frame's
    // compositing state when changing the compositing backing of the layer.
    DisableCompositingQueryAsserts disabler;

    layer->paintInvalidator().paintInvalidationIncludingNonCompositingDescendants();
}

void RenderLayerCompositor::frameViewDidChangeLocation(const IntPoint& contentsOffset)
{
    if (m_overflowControlsHostLayer)
        m_overflowControlsHostLayer->setPosition(contentsOffset);
}

void RenderLayerCompositor::frameViewDidChangeSize()
{
    if (m_containerLayer) {
        FrameView* frameView = m_renderView.frameView();
        m_containerLayer->setSize(frameView->unscaledVisibleContentSize());
    }
}

void RenderLayerCompositor::rootFixedBackgroundsChanged()
{
    if (!supportsFixedRootBackgroundCompositing())
        return;

    // To avoid having to make the fixed root background layer fixed positioned to
    // stay put, we position it in the layer tree as follows:
    //
    // + Overflow controls host
    //   + LocalFrame clip
    //     + (Fixed root background) <-- Here.
    //     + LocalFrame scroll
    //       + Root content layer
    //   + Scrollbars
    //
    // That is, it needs to be the first child of the frame clip, the sibling of
    // the frame scroll layer. The compositor does not own the background layer, it
    // just positions it (like the foreground layer).
    if (GraphicsLayer* backgroundLayer = fixedRootBackgroundLayer())
        m_containerLayer->addChildBelow(backgroundLayer, m_scrollLayer.get());
}

String RenderLayerCompositor::layerTreeAsText(LayerTreeFlags flags)
{
    ASSERT(lifecycle().state() >= DocumentLifecycle::PaintInvalidationClean);

    if (!m_rootContentLayer)
        return String();

    // We skip dumping the scroll and clip layers to keep layerTreeAsText output
    // similar between platforms (unless we explicitly request dumping from the
    // root.
    GraphicsLayer* rootLayer = m_rootContentLayer.get();
    if (flags & LayerTreeIncludesRootLayer)
        rootLayer = rootGraphicsLayer();

    String layerTreeText = rootLayer->layerTreeAsText(flags);

    // The true root layer is not included in the dump, so if we want to report
    // its paint invalidation rects, they must be included here.
    if (flags & LayerTreeIncludesPaintInvalidationRects)
        return m_renderView.frameView()->trackedPaintInvalidationRectsAsText() + layerTreeText;

    return layerTreeText;
}

static void fullyInvalidatePaintRecursive(RenderLayer* layer)
{
    if (layer->compositingState() == PaintsIntoOwnBacking) {
        layer->compositedLayerMapping()->setContentsNeedDisplay();
        layer->compositedLayerMapping()->setSquashingContentsNeedDisplay();
    }

    for (RenderLayer* child = layer->firstChild(); child; child = child->nextSibling())
        fullyInvalidatePaintRecursive(child);
}

void RenderLayerCompositor::fullyInvalidatePaint()
{
    // We're walking all compositing layers and invalidating them, so there's
    // no need to have up-to-date compositing state.
    DisableCompositingQueryAsserts disabler;
    fullyInvalidatePaintRecursive(rootRenderLayer());
}

RenderLayer* RenderLayerCompositor::rootRenderLayer() const
{
    return m_renderView.layer();
}

GraphicsLayer* RenderLayerCompositor::rootGraphicsLayer() const
{
    if (m_overflowControlsHostLayer)
        return m_overflowControlsHostLayer.get();
    return m_rootContentLayer.get();
}

GraphicsLayer* RenderLayerCompositor::scrollLayer() const
{
    return m_scrollLayer.get();
}

GraphicsLayer* RenderLayerCompositor::containerLayer() const
{
    return m_containerLayer.get();
}

GraphicsLayer* RenderLayerCompositor::ensureRootTransformLayer()
{
    ASSERT(rootGraphicsLayer());

    if (!m_rootTransformLayer.get()) {
        m_rootTransformLayer = GraphicsLayer::create(graphicsLayerFactory(), this);
        m_overflowControlsHostLayer->addChild(m_rootTransformLayer.get());
        m_rootTransformLayer->addChild(m_containerLayer.get());
    }

    return m_rootTransformLayer.get();
}

void RenderLayerCompositor::setIsInWindow(bool isInWindow)
{
    if (!staleInCompositingMode())
        return;

    if (isInWindow) {
        if (m_rootLayerAttachment != RootLayerUnattached)
            return;

        RootLayerAttachment attachment = RootLayerAttachedViaChromeClient;
        attachRootLayer(attachment);
    } else {
        if (m_rootLayerAttachment == RootLayerUnattached)
            return;

        detachRootLayer();
    }
}

void RenderLayerCompositor::updateRootLayerPosition()
{
    if (m_rootContentLayer) {
        const IntRect& documentRect = m_renderView.documentRect();
        m_rootContentLayer->setSize(documentRect.size());
        m_rootContentLayer->setPosition(documentRect.location());
    }
    if (m_containerLayer) {
        FrameView* frameView = m_renderView.frameView();
        m_containerLayer->setSize(frameView->unscaledVisibleContentSize());
    }
}

void RenderLayerCompositor::updatePotentialCompositingReasonsFromStyle(RenderLayer* layer)
{
    layer->setPotentialCompositingReasonsFromStyle(m_compositingReasonFinder.potentialCompositingReasonsFromStyle(layer->renderer()));
}

void RenderLayerCompositor::updateDirectCompositingReasons(RenderLayer* layer)
{
    layer->setCompositingReasons(m_compositingReasonFinder.directReasons(layer), CompositingReasonComboAllDirectReasons);
}

void RenderLayerCompositor::setOverlayLayer(GraphicsLayer* layer)
{
    ASSERT(rootGraphicsLayer());

    if (layer->parent() != m_overflowControlsHostLayer.get())
        m_overflowControlsHostLayer->addChild(layer);
}

bool RenderLayerCompositor::canBeComposited(const RenderLayer* layer) const
{
    // FIXME: We disable accelerated compositing for elements in a RenderFlowThread as it doesn't work properly.
    // See http://webkit.org/b/84900 to re-enable it.
    return layer->isSelfPaintingLayer();
}

// Return true if the given layer is a stacking context and has compositing child
// layers that it needs to clip. In this case we insert a clipping GraphicsLayer
// into the hierarchy between this layer and its children in the z-order hierarchy.
bool RenderLayerCompositor::clipsCompositingDescendants(const RenderLayer* layer) const
{
    return layer->hasCompositingDescendant() && layer->renderer()->hasClipOrOverflowClip();
}

// If an element has negative z-index children, those children render in front of the
// layer background, so we need an extra 'contents' layer for the foreground of the layer
// object.
bool RenderLayerCompositor::needsContentsCompositingLayer(const RenderLayer* layer) const
{
    return layer->stackingNode()->hasNegativeZOrderList();
}

void RenderLayerCompositor::paintContents(const GraphicsLayer* graphicsLayer, GraphicsContext& context, GraphicsLayerPaintingPhase, const IntRect& clip)
{
    // FIXME(sky): Remove.
}

bool RenderLayerCompositor::supportsFixedRootBackgroundCompositing() const
{
    if (Settings* settings = m_renderView.document().settings())
        return settings->preferCompositingToLCDTextEnabled();
    return false;
}

bool RenderLayerCompositor::needsFixedRootBackgroundLayer(const RenderLayer* layer) const
{
    if (layer != m_renderView.layer())
        return false;

    return supportsFixedRootBackgroundCompositing() && m_renderView.rootBackgroundIsEntirelyFixed();
}

GraphicsLayer* RenderLayerCompositor::fixedRootBackgroundLayer() const
{
    // Get the fixed root background from the RenderView layer's compositedLayerMapping.
    RenderLayer* viewLayer = m_renderView.layer();
    if (!viewLayer)
        return 0;

    if (viewLayer->compositingState() == PaintsIntoOwnBacking && viewLayer->compositedLayerMapping()->backgroundLayerPaintsFixedRootBackground())
        return viewLayer->compositedLayerMapping()->backgroundLayer();

    return 0;
}

static void resetTrackedPaintInvalidationRectsRecursive(GraphicsLayer* graphicsLayer)
{
    if (!graphicsLayer)
        return;

    graphicsLayer->resetTrackedPaintInvalidations();

    for (size_t i = 0; i < graphicsLayer->children().size(); ++i)
        resetTrackedPaintInvalidationRectsRecursive(graphicsLayer->children()[i]);

    if (GraphicsLayer* maskLayer = graphicsLayer->maskLayer())
        resetTrackedPaintInvalidationRectsRecursive(maskLayer);

    if (GraphicsLayer* clippingMaskLayer = graphicsLayer->contentsClippingMaskLayer())
        resetTrackedPaintInvalidationRectsRecursive(clippingMaskLayer);
}

void RenderLayerCompositor::resetTrackedPaintInvalidationRects()
{
    if (GraphicsLayer* rootLayer = rootGraphicsLayer())
        resetTrackedPaintInvalidationRectsRecursive(rootLayer);
}

void RenderLayerCompositor::setTracksPaintInvalidations(bool tracksPaintInvalidations)
{
    ASSERT(lifecycle().state() == DocumentLifecycle::PaintInvalidationClean);
    m_isTrackingPaintInvalidations = tracksPaintInvalidations;
}

bool RenderLayerCompositor::isTrackingPaintInvalidations() const
{
    return m_isTrackingPaintInvalidations;
}

void RenderLayerCompositor::ensureRootLayer()
{
    RootLayerAttachment expectedAttachment = RootLayerAttachedViaChromeClient;
    if (expectedAttachment == m_rootLayerAttachment)
         return;

    if (!m_rootContentLayer) {
        m_rootContentLayer = GraphicsLayer::create(graphicsLayerFactory(), this);
        IntRect overflowRect = m_renderView.pixelSnappedLayoutOverflowRect();
        m_rootContentLayer->setSize(FloatSize(overflowRect.maxX(), overflowRect.maxY()));
        m_rootContentLayer->setPosition(FloatPoint());
        m_rootContentLayer->setOwnerNodeId(InspectorNodeIds::idForNode(m_renderView.node()));

        // Need to clip to prevent transformed content showing outside this frame
        m_rootContentLayer->setMasksToBounds(true);
    }

    if (!m_overflowControlsHostLayer) {
        ASSERT(!m_scrollLayer);
        ASSERT(!m_containerLayer);

        // Create a layer to host the clipping layer and the overflow controls layers.
        m_overflowControlsHostLayer = GraphicsLayer::create(graphicsLayerFactory(), this);

        // Create a clipping layer if this is an iframe or settings require to clip.
        m_containerLayer = GraphicsLayer::create(graphicsLayerFactory(), this);
        bool containerMasksToBounds = false;
        if (Settings* settings = m_renderView.document().settings()) {
            if (settings->mainFrameClipsContent())
                containerMasksToBounds = true;
        }
        m_containerLayer->setMasksToBounds(containerMasksToBounds);

        m_scrollLayer = GraphicsLayer::create(graphicsLayerFactory(), this);

        // Hook them up
        m_overflowControlsHostLayer->addChild(m_containerLayer.get());
        m_containerLayer->addChild(m_scrollLayer.get());
        m_scrollLayer->addChild(m_rootContentLayer.get());

        frameViewDidChangeSize();
    }

    // Check to see if we have to change the attachment
    if (m_rootLayerAttachment != RootLayerUnattached)
        detachRootLayer();

    attachRootLayer(expectedAttachment);
}

void RenderLayerCompositor::destroyRootLayer()
{
    if (!m_rootContentLayer)
        return;

    detachRootLayer();

    if (m_overflowControlsHostLayer) {
        m_overflowControlsHostLayer = nullptr;
        m_containerLayer = nullptr;
        m_scrollLayer = nullptr;
    }
    ASSERT(!m_scrollLayer);
    m_rootContentLayer = nullptr;
    m_rootTransformLayer = nullptr;
}

void RenderLayerCompositor::attachRootLayer(RootLayerAttachment attachment)
{
    if (!m_rootContentLayer)
        return;

    switch (attachment) {
        case RootLayerUnattached:
            ASSERT_NOT_REACHED();
            break;
        case RootLayerAttachedViaChromeClient: {
            LocalFrame& frame = m_renderView.frameView()->frame();
            Page* page = frame.page();
            if (!page)
                return;
            page->chrome().client().attachRootGraphicsLayer(rootGraphicsLayer());
            break;
        }
        case RootLayerAttachedViaEnclosingFrame: {
            ASSERT_NOT_REACHED();
        }
    }

    m_rootLayerAttachment = attachment;
}

void RenderLayerCompositor::detachRootLayer()
{
    if (!m_rootContentLayer || m_rootLayerAttachment == RootLayerUnattached)
        return;

    switch (m_rootLayerAttachment) {
    case RootLayerAttachedViaEnclosingFrame: {
        ASSERT_NOT_REACHED();
    }
    case RootLayerAttachedViaChromeClient: {
        LocalFrame& frame = m_renderView.frameView()->frame();
        Page* page = frame.page();
        if (!page)
            return;
        page->chrome().client().attachRootGraphicsLayer(0);
    }
    break;
    case RootLayerUnattached:
        break;
    }

    m_rootLayerAttachment = RootLayerUnattached;
}

void RenderLayerCompositor::updateRootLayerAttachment()
{
    ensureRootLayer();
}

GraphicsLayerFactory* RenderLayerCompositor::graphicsLayerFactory() const
{
    if (Page* page = this->page())
        return page->chrome().client().graphicsLayerFactory();
    return 0;
}

Page* RenderLayerCompositor::page() const
{
    return m_renderView.frameView()->frame().page();
}

DocumentLifecycle& RenderLayerCompositor::lifecycle() const
{
    return m_renderView.document().lifecycle();
}

String RenderLayerCompositor::debugName(const GraphicsLayer* graphicsLayer)
{
    String name;
    if (graphicsLayer == m_rootContentLayer.get()) {
        name = "Content Root Layer";
    } else if (graphicsLayer == m_rootTransformLayer.get()) {
        name = "Root Transform Layer";
    } else if (graphicsLayer == m_overflowControlsHostLayer.get()) {
        name = "Overflow Controls Host Layer";
    } else if (graphicsLayer == m_containerLayer.get()) {
        name = "LocalFrame Clipping Layer";
    } else if (graphicsLayer == m_scrollLayer.get()) {
        name = "LocalFrame Scrolling Layer";
    } else {
        ASSERT_NOT_REACHED();
    }

    return name;
}

} // namespace blink
