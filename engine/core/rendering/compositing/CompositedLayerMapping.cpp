/*
 * Copyright (C) 2009, 2010, 2011 Apple Inc. All rights reserved.
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

#include "core/rendering/compositing/CompositedLayerMapping.h"

#include "core/fetch/ImageResource.h"
#include "core/frame/FrameView.h"
#include "core/html/HTMLCanvasElement.h"
#include "core/html/canvas/CanvasRenderingContext.h"
#include "core/inspector/InspectorNodeIds.h"
#include "core/inspector/InspectorTraceEvents.h"
#include "core/page/Chrome.h"
#include "core/page/ChromeClient.h"
#include "core/page/Page.h"
#include "core/rendering/FilterEffectRenderer.h"
#include "core/rendering/RenderImage.h"
#include "core/rendering/RenderLayerStackingNodeIterator.h"
#include "core/rendering/RenderView.h"
#include "core/rendering/compositing/RenderLayerCompositor.h"
#include "core/rendering/style/KeyframeList.h"
#include "platform/LengthFunctions.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "platform/fonts/FontCache.h"
#include "platform/geometry/TransformState.h"
#include "platform/graphics/GraphicsContext.h"
#include "wtf/CurrentTime.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

static IntRect clipBox(RenderBox* renderer);

static IntRect contentsRect(const RenderObject* renderer)
{
    if (!renderer->isBox())
        return IntRect();

    return pixelSnappedIntRect(toRenderBox(renderer)->contentBoxRect());
}

static IntRect backgroundRect(const RenderObject* renderer)
{
    if (!renderer->isBox())
        return IntRect();

    LayoutRect rect;
    const RenderBox* box = toRenderBox(renderer);
    EFillBox clip = box->style()->backgroundClip();
    switch (clip) {
    case BorderFillBox:
        rect = box->borderBoxRect();
        break;
    case PaddingFillBox:
        rect = box->paddingBoxRect();
        break;
    case ContentFillBox:
        rect = box->contentBoxRect();
        break;
    case TextFillBox:
        break;
    }

    return pixelSnappedIntRect(rect);
}

static inline bool isAcceleratedCanvas(const RenderObject* renderer)
{
    if (renderer->isCanvas()) {
        HTMLCanvasElement* canvas = toHTMLCanvasElement(renderer->node());
        if (CanvasRenderingContext* context = canvas->renderingContext())
            return context->isAccelerated();
    }
    return false;
}

static bool hasBoxDecorationsOrBackgroundImage(const RenderStyle* style)
{
    return style->hasBoxDecorations() || style->hasBackgroundImage();
}

static bool contentLayerSupportsDirectBackgroundComposition(const RenderObject* renderer)
{
    // No support for decorations - border, border-radius or outline.
    // Only simple background - solid color or transparent.
    if (hasBoxDecorationsOrBackgroundImage(renderer->style()))
        return false;

    // If there is no background, there is nothing to support.
    if (!renderer->style()->hasBackground())
        return true;

    // Simple background that is contained within the contents rect.
    return contentsRect(renderer).contains(backgroundRect(renderer));
}

static inline bool isAcceleratedContents(RenderObject* renderer)
{
    return isAcceleratedCanvas(renderer);
}

CompositedLayerMapping::CompositedLayerMapping(RenderLayer& layer)
    : m_owningLayer(layer)
    , m_contentOffsetInCompositingLayerDirty(false)
    , m_pendingUpdateScope(GraphicsLayerUpdateNone)
    , m_requiresOwnBackingStoreForIntrinsicReasons(false)
    , m_requiresOwnBackingStoreForAncestorReasons(false)
    , m_backgroundLayerPaintsFixedRootBackground(false)
{
    createPrimaryGraphicsLayer();
}

CompositedLayerMapping::~CompositedLayerMapping()
{
    // Hits in compositing/squashing/squash-onto-nephew.html.
    DisableCompositingQueryAsserts disabler;

    // Do not leave the destroyed pointer dangling on any RenderLayers that painted to this mapping's squashing layer.
    for (size_t i = 0; i < m_squashedLayers.size(); ++i) {
        RenderLayer* oldSquashedLayer = m_squashedLayers[i].renderLayer;
        if (oldSquashedLayer->groupedMapping() == this) {
            oldSquashedLayer->setGroupedMapping(0, true);
            oldSquashedLayer->setLostGroupedMapping(true);
        }
    }

    updateClippingLayers(false, false);
    updateChildTransformLayer(false);
    updateForegroundLayer(false);
    updateBackgroundLayer(false);
    updateMaskLayer(false);
    updateClippingMaskLayers(false);
    updateSquashingLayers(false);
    destroyGraphicsLayers();
}

PassOwnPtr<GraphicsLayer> CompositedLayerMapping::createGraphicsLayer(CompositingReasons reasons)
{
    GraphicsLayerFactory* graphicsLayerFactory = 0;
    if (Page* page = renderer()->frame()->page())
        graphicsLayerFactory = page->chrome().client().graphicsLayerFactory();

    OwnPtr<GraphicsLayer> graphicsLayer = GraphicsLayer::create(graphicsLayerFactory, this);

    graphicsLayer->setCompositingReasons(reasons);
    if (Node* owningNode = m_owningLayer.renderer()->node())
        graphicsLayer->setOwnerNodeId(InspectorNodeIds::idForNode(owningNode));

    return graphicsLayer.release();
}

void CompositedLayerMapping::createPrimaryGraphicsLayer()
{
    m_graphicsLayer = createGraphicsLayer(m_owningLayer.compositingReasons());

    updateOpacity(renderer()->style());
    updateTransform(renderer()->style());
    updateFilters(renderer()->style());
}

void CompositedLayerMapping::destroyGraphicsLayers()
{
    if (m_graphicsLayer)
        m_graphicsLayer->removeFromParent();

    m_ancestorClippingLayer = nullptr;
    m_graphicsLayer = nullptr;
    m_foregroundLayer = nullptr;
    m_backgroundLayer = nullptr;
    m_childContainmentLayer = nullptr;
    m_childTransformLayer = nullptr;
    m_maskLayer = nullptr;
    m_childClippingMaskLayer = nullptr;
}

void CompositedLayerMapping::updateOpacity(const RenderStyle* style)
{
    m_graphicsLayer->setOpacity(compositingOpacity(style->opacity()));
}

void CompositedLayerMapping::updateTransform(const RenderStyle* style)
{
    // FIXME: This could use m_owningLayer.transform(), but that currently has transform-origin
    // baked into it, and we don't want that.
    TransformationMatrix t;
    if (m_owningLayer.hasTransform()) {
        style->applyTransform(t, toRenderBox(renderer())->pixelSnappedBorderBoxRect().size(), RenderStyle::ExcludeTransformOrigin);
        makeMatrixRenderable(t, compositor()->hasAcceleratedCompositing());
    }

    m_graphicsLayer->setTransform(t);
}

void CompositedLayerMapping::updateFilters(const RenderStyle* style)
{
    m_graphicsLayer->setFilters(owningLayer().computeFilterOperations(style));
}

void CompositedLayerMapping::updateContentsOpaque()
{
    // For non-root layers, background is always painted by the primary graphics layer.
    ASSERT(!m_backgroundLayer);
    if (m_backgroundLayer) {
        m_graphicsLayer->setContentsOpaque(false);
        m_backgroundLayer->setContentsOpaque(m_owningLayer.backgroundIsKnownToBeOpaqueInRect(compositedBounds()));
    } else {
        m_graphicsLayer->setContentsOpaque(m_owningLayer.backgroundIsKnownToBeOpaqueInRect(compositedBounds()));
    }
}

void CompositedLayerMapping::updateCompositedBounds()
{
    ASSERT(m_owningLayer.compositor()->lifecycle().state() == DocumentLifecycle::InCompositingUpdate);
    // FIXME: if this is really needed for performance, it would be better to store it on RenderLayer.
    m_compositedBounds = m_owningLayer.boundingBoxForCompositing();
    m_contentOffsetInCompositingLayerDirty = true;
}

void CompositedLayerMapping::updateCompositingReasons()
{
    // All other layers owned by this mapping will have the same compositing reason
    // for their lifetime, so they are initialized only when created.
    m_graphicsLayer->setCompositingReasons(m_owningLayer.compositingReasons());
}

bool CompositedLayerMapping::owningLayerClippedByLayerNotAboveCompositedAncestor()
{
    if (!m_owningLayer.parent())
        return false;

    const RenderLayer* compositingAncestor = m_owningLayer.enclosingLayerWithCompositedLayerMapping(ExcludeSelf);
    if (!compositingAncestor)
        return false;

    const RenderObject* clippingContainer = m_owningLayer.clippingContainer();
    if (!clippingContainer)
        return false;

    if (compositingAncestor->renderer()->isDescendantOf(clippingContainer))
        return false;

    // We ignore overflow clip here; we want composited overflow content to
    // behave as if it lives in an unclipped universe so it can prepaint, etc.
    // This means that we need to check if we are actually clipped before
    // setting up m_ancestorClippingLayer otherwise
    // updateAncestorClippingLayerGeometry will fail as the clip rect will be
    // infinite.
    // FIXME: this should use cached clip rects, but this sometimes give
    // inaccurate results (and trips the ASSERTS in RenderLayerClipper).
    ClipRectsContext clipRectsContext(compositingAncestor, UncachedClipRects);
    clipRectsContext.setIgnoreOverflowClip();
    IntRect parentClipRect = pixelSnappedIntRect(m_owningLayer.clipper().backgroundClipRect(clipRectsContext).rect());
    return parentClipRect != PaintInfo::infiniteRect();
}

bool CompositedLayerMapping::updateGraphicsLayerConfiguration()
{
    ASSERT(m_owningLayer.compositor()->lifecycle().state() == DocumentLifecycle::InCompositingUpdate);

    // Note carefully: here we assume that the compositing state of all descendants have been updated already,
    // so it is legitimate to compute and cache the composited bounds for this layer.
    updateCompositedBounds();

    RenderLayerCompositor* compositor = this->compositor();
    RenderObject* renderer = this->renderer();

    bool layerConfigChanged = false;
    setBackgroundLayerPaintsFixedRootBackground(compositor->needsFixedRootBackgroundLayer(&m_owningLayer));

    // The background layer is currently only used for fixed root backgrounds.
    if (updateBackgroundLayer(m_backgroundLayerPaintsFixedRootBackground))
        layerConfigChanged = true;

    if (updateForegroundLayer(compositor->needsContentsCompositingLayer(&m_owningLayer)))
        layerConfigChanged = true;

    bool needsDescendantsClippingLayer = compositor->clipsCompositingDescendants(&m_owningLayer);

    // Our scrolling layer will clip.
    if (m_owningLayer.needsCompositedScrolling())
        needsDescendantsClippingLayer = false;

    RenderLayer* scrollParent = compositor->preferCompositingToLCDTextEnabled() ? m_owningLayer.scrollParent() : 0;

    // This is required because compositing layers are parented
    // according to the z-order hierarchy, yet clipping goes down the renderer hierarchy.
    // Thus, a RenderLayer can be clipped by a RenderLayer that is an ancestor in the renderer hierarchy,
    // but a sibling in the z-order hierarchy. Further, that sibling need not be composited at all.
    // In such scenarios, an ancestor clipping layer is necessary to apply the composited clip for this layer.
    bool needsAncestorClip = owningLayerClippedByLayerNotAboveCompositedAncestor();

    if (scrollParent) {
        // If our containing block is our ancestor scrolling layer, then we'll already be clipped
        // to it via our scroll parent and we don't need an ancestor clipping layer.
        if (m_owningLayer.renderer()->containingBlock()->enclosingLayer() == m_owningLayer.ancestorScrollingLayer())
            needsAncestorClip = false;
    }

    if (updateClippingLayers(needsAncestorClip, needsDescendantsClippingLayer))
        layerConfigChanged = true;

    bool hasPerspective = false;
    if (RenderStyle* style = renderer->style())
        hasPerspective = style->hasPerspective();
    bool needsChildTransformLayer = hasPerspective && (layerForChildrenTransform() == m_childTransformLayer.get()) && renderer->isBox();
    if (updateChildTransformLayer(needsChildTransformLayer))
        layerConfigChanged = true;

    updateClipParent();

    if (updateSquashingLayers(!m_squashedLayers.isEmpty()))
        layerConfigChanged = true;

    if (layerConfigChanged)
        updateInternalHierarchy();

    // A mask layer is not part of the hierarchy proper, it's an auxiliary layer
    // that's plugged into another GraphicsLayer that is part of the hierarchy.
    // It has no parent or child GraphicsLayer. For that reason, we process it
    // here, after the hierarchy has been updated.
    bool maskLayerChanged = false;
    if (updateMaskLayer(renderer->hasMask())) {
        maskLayerChanged = true;
        m_graphicsLayer->setMaskLayer(m_maskLayer.get());
    }

    bool hasChildClippingLayer = compositor->clipsCompositingDescendants(&m_owningLayer) && (hasClippingLayer());
    // If we have a border radius or clip path on a scrolling layer, we need a clipping mask to properly
    // clip the scrolled contents, even if there are no composited descendants.
    bool hasClipPath = renderer->style()->clipPath();
    bool needsChildClippingMask = (hasClipPath || renderer->style()->hasBorderRadius()) && (hasChildClippingLayer || isAcceleratedContents(renderer));
    if (updateClippingMaskLayers(needsChildClippingMask)) {
        // Clip path clips the entire subtree, including scrollbars. It must be attached directly onto
        // the main m_graphicsLayer.
        if (hasClipPath)
            m_graphicsLayer->setMaskLayer(m_childClippingMaskLayer.get());
        else if (hasClippingLayer())
            clippingLayer()->setMaskLayer(m_childClippingMaskLayer.get());
        else if (isAcceleratedContents(renderer))
            m_graphicsLayer->setContentsClippingMaskLayer(m_childClippingMaskLayer.get());
    }

    updateBackgroundColor();

    if (renderer->isImage()) {
        if (isDirectlyCompositedImage()) {
            updateImageContents();
        } else if (m_graphicsLayer->hasContentsLayer()) {
            m_graphicsLayer->setContentsToImage(0);
        }
    }

    if (isAcceleratedCanvas(renderer)) {
        HTMLCanvasElement* canvas = toHTMLCanvasElement(renderer->node());
        if (CanvasRenderingContext* context = canvas->renderingContext())
            m_graphicsLayer->setContentsToPlatformLayer(context->platformLayer());
        layerConfigChanged = true;
    }

    // Changes to either the internal hierarchy or the mask layer have an impact
    // on painting phases, so we need to update when either are updated.
    if (layerConfigChanged || maskLayerChanged)
        updatePaintingPhases();

    return layerConfigChanged;
}

static IntRect clipBox(RenderBox* renderer)
{
    LayoutRect result = PaintInfo::infiniteRect();
    if (renderer->hasOverflowClip())
        result = renderer->overflowClipRect(LayoutPoint());

    if (renderer->hasClip())
        result.intersect(renderer->clipRect(LayoutPoint()));

    return pixelSnappedIntRect(result);
}

static LayoutPoint computeOffsetFromCompositedAncestor(const RenderLayer* layer, const RenderLayer* compositedAncestor)
{
    LayoutPoint offset;
    layer->convertToLayerCoords(compositedAncestor, offset);
    if (compositedAncestor)
        offset.move(compositedAncestor->compositedLayerMapping()->owningLayer().subpixelAccumulation());
    return offset;
}

void CompositedLayerMapping::computeBoundsOfOwningLayer(const RenderLayer* compositedAncestor, IntRect& localBounds, IntRect& compositingBoundsRelativeToCompositedAncestor, LayoutPoint& offsetFromCompositedAncestor,
    IntPoint& snappedOffsetFromCompositedAncestor)
{
    LayoutRect localRawCompositingBounds = compositedBounds();
    offsetFromCompositedAncestor = computeOffsetFromCompositedAncestor(&m_owningLayer, compositedAncestor);
    snappedOffsetFromCompositedAncestor = IntPoint(offsetFromCompositedAncestor.x().round(), offsetFromCompositedAncestor.y().round());

    LayoutSize subpixelAccumulation = offsetFromCompositedAncestor - snappedOffsetFromCompositedAncestor;
    m_owningLayer.setSubpixelAccumulation(subpixelAccumulation);

    // Move the bounds by the subpixel accumulation so that it pixel-snaps relative to absolute pixels instead of local coordinates.
    localRawCompositingBounds.move(subpixelAccumulation);
    localBounds = pixelSnappedIntRect(localRawCompositingBounds);

    compositingBoundsRelativeToCompositedAncestor = localBounds;
    compositingBoundsRelativeToCompositedAncestor.moveBy(snappedOffsetFromCompositedAncestor);
}

void CompositedLayerMapping::updateSquashingLayerGeometry(const LayoutPoint& offsetFromCompositedAncestor, const IntPoint& graphicsLayerParentLocation, const RenderLayer& referenceLayer,
    Vector<GraphicsLayerPaintInfo>& layers, GraphicsLayer* squashingLayer, LayoutPoint* offsetFromTransformedAncestor, Vector<RenderLayer*>& layersNeedingPaintInvalidation)
{
    if (!squashingLayer)
        return;
    ASSERT(compositor()->layerSquashingEnabled());

    LayoutPoint offsetFromReferenceLayerToParentGraphicsLayer(offsetFromCompositedAncestor);
    offsetFromReferenceLayerToParentGraphicsLayer.moveBy(-graphicsLayerParentLocation);

    // FIXME: Cache these offsets.
    LayoutPoint referenceOffsetFromTransformedAncestor = referenceLayer.computeOffsetFromTransformedAncestor();

    LayoutRect totalSquashBounds;
    for (size_t i = 0; i < layers.size(); ++i) {
        LayoutRect squashedBounds = layers[i].renderLayer->boundingBoxForCompositing();

        // Store the local bounds of the RenderLayer subtree before applying the offset.
        layers[i].compositedBounds = squashedBounds;

        LayoutPoint offsetFromTransformedAncestorForSquashedLayer = layers[i].renderLayer->computeOffsetFromTransformedAncestor();
        LayoutSize offsetFromSquashingLayer = offsetFromTransformedAncestorForSquashedLayer - referenceOffsetFromTransformedAncestor;

        squashedBounds.move(offsetFromSquashingLayer);
        totalSquashBounds.unite(squashedBounds);
    }

    // The totalSquashBounds is positioned with respect to referenceLayer of this CompositedLayerMapping.
    // But the squashingLayer needs to be positioned with respect to the ancestor CompositedLayerMapping.
    // The conversion between referenceLayer and the ancestor CLM is already computed as
    // offsetFromReferenceLayerToParentGraphicsLayer.
    totalSquashBounds.moveBy(offsetFromReferenceLayerToParentGraphicsLayer);
    IntRect squashLayerBounds = enclosingIntRect(totalSquashBounds);
    IntPoint squashLayerOrigin = squashLayerBounds.location();
    LayoutSize squashLayerOriginInOwningLayerSpace = squashLayerOrigin - offsetFromReferenceLayerToParentGraphicsLayer;

    // Now that the squashing bounds are known, we can convert the RenderLayer painting offsets
    // from CLM owning layer space to the squashing layer space.
    //
    // The painting offset we want to compute for each squashed RenderLayer is essentially the position of
    // the squashed RenderLayer described w.r.t. referenceLayer's origin. For this purpose we already cached
    // offsetFromSquashingCLM before, which describes where the squashed RenderLayer is located w.r.t.
    // referenceLayer. So we just need to convert that point from referenceLayer space to referenceLayer
    // space. This is simply done by subtracing squashLayerOriginInOwningLayerSpace, but then the offset
    // overall needs to be negated because that's the direction that the painting code expects the
    // offset to be.
    for (size_t i = 0; i < layers.size(); ++i) {
        LayoutPoint offsetFromTransformedAncestorForSquashedLayer = layers[i].renderLayer->computeOffsetFromTransformedAncestor();
        LayoutSize offsetFromSquashLayerOrigin = (offsetFromTransformedAncestorForSquashedLayer - referenceOffsetFromTransformedAncestor) - squashLayerOriginInOwningLayerSpace;

        // It is ok to issue paint invalidation here, because all of the geometry needed to correctly invalidate paint is computed by this point.
        IntSize newOffsetFromRenderer = -IntSize(offsetFromSquashLayerOrigin.width().round(), offsetFromSquashLayerOrigin.height().round());
        LayoutSize subpixelAccumulation = offsetFromSquashLayerOrigin + newOffsetFromRenderer;
        if (layers[i].offsetFromRendererSet && layers[i].offsetFromRenderer != newOffsetFromRenderer) {
            layers[i].renderLayer->paintInvalidator().paintInvalidationIncludingNonCompositingDescendants();
            layersNeedingPaintInvalidation.append(layers[i].renderLayer);
        }
        layers[i].offsetFromRenderer = newOffsetFromRenderer;
        layers[i].offsetFromRendererSet = true;

        layers[i].renderLayer->setSubpixelAccumulation(subpixelAccumulation);
    }

    squashingLayer->setPosition(squashLayerBounds.location());
    squashingLayer->setSize(squashLayerBounds.size());

    *offsetFromTransformedAncestor = referenceOffsetFromTransformedAncestor;
    offsetFromTransformedAncestor->move(squashLayerOriginInOwningLayerSpace);

    for (size_t i = 0; i < layers.size(); ++i)
        layers[i].localClipRectForSquashedLayer = localClipRectForSquashedLayer(referenceLayer, layers[i], layers);
}

void CompositedLayerMapping::updateGraphicsLayerGeometry(const RenderLayer* compositingContainer, const RenderLayer* compositingStackingContext, Vector<RenderLayer*>& layersNeedingPaintInvalidation)
{
    ASSERT(m_owningLayer.compositor()->lifecycle().state() == DocumentLifecycle::InCompositingUpdate);

    // Set transform property, if it is not animating. We have to do this here because the transform
    // is affected by the layer dimensions.
    if (!renderer()->style()->isRunningTransformAnimationOnCompositor())
        updateTransform(renderer()->style());

    // Set opacity, if it is not animating.
    if (!renderer()->style()->isRunningOpacityAnimationOnCompositor())
        updateOpacity(renderer()->style());

    if (!renderer()->style()->isRunningFilterAnimationOnCompositor())
        updateFilters(renderer()->style());

    // We compute everything relative to the enclosing compositing layer.
    IntRect ancestorCompositingBounds;
    if (compositingContainer) {
        ASSERT(compositingContainer->hasCompositedLayerMapping());
        ancestorCompositingBounds = compositingContainer->compositedLayerMapping()->pixelSnappedCompositedBounds();
    }

    IntRect localCompositingBounds;
    IntRect relativeCompositingBounds;
    LayoutPoint offsetFromCompositedAncestor;
    IntPoint snappedOffsetFromCompositedAncestor;
    computeBoundsOfOwningLayer(compositingContainer, localCompositingBounds, relativeCompositingBounds, offsetFromCompositedAncestor, snappedOffsetFromCompositedAncestor);

    IntPoint graphicsLayerParentLocation;
    computeGraphicsLayerParentLocation(compositingContainer, ancestorCompositingBounds, graphicsLayerParentLocation);

    // Might update graphicsLayerParentLocation.
    updateAncestorClippingLayerGeometry(compositingContainer, snappedOffsetFromCompositedAncestor, graphicsLayerParentLocation);
    updateOverflowControlsHostLayerGeometry(compositingStackingContext);

    FloatSize contentsSize = relativeCompositingBounds.size();

    updateMainGraphicsLayerGeometry(relativeCompositingBounds, localCompositingBounds, graphicsLayerParentLocation);
    updateContentsOffsetInCompositingLayer(snappedOffsetFromCompositedAncestor, graphicsLayerParentLocation);
    updateSquashingLayerGeometry(offsetFromCompositedAncestor, graphicsLayerParentLocation, m_owningLayer, m_squashedLayers, m_squashingLayer.get(), &m_squashingLayerOffsetFromTransformedAncestor, layersNeedingPaintInvalidation);

    // If we have a layer that clips children, position it.
    IntRect clippingBox;
    if (m_childContainmentLayer)
        clippingBox = clipBox(toRenderBox(renderer()));

    updateChildContainmentLayerGeometry(clippingBox, localCompositingBounds);
    updateChildTransformLayerGeometry();

    updateMaskLayerGeometry();
    updateTransformGeometry(snappedOffsetFromCompositedAncestor, relativeCompositingBounds);
    updateForegroundLayerGeometry(contentsSize, clippingBox);
    updateBackgroundLayerGeometry(contentsSize);
    updateChildClippingMaskLayerGeometry();

    if (m_owningLayer.scrollableArea() && m_owningLayer.scrollableArea()->scrollsOverflow())
        m_owningLayer.scrollableArea()->positionOverflowControls(IntSize());

    updateContentsRect();
    updateBackgroundColor();
    updateDrawsContent();
    updateContentsOpaque();
    updateRenderingContext();
    updateShouldFlattenTransform();
    updateChildrenTransform();

    updateCompositingReasons();
}

void CompositedLayerMapping::updateMainGraphicsLayerGeometry(const IntRect& relativeCompositingBounds, const IntRect& localCompositingBounds, const IntPoint& graphicsLayerParentLocation)
{
    m_graphicsLayer->setPosition(FloatPoint(relativeCompositingBounds.location() - graphicsLayerParentLocation));
    m_graphicsLayer->setOffsetFromRenderer(toIntSize(localCompositingBounds.location()));

    FloatSize oldSize = m_graphicsLayer->size();
    const IntSize& contentsSize = relativeCompositingBounds.size();
    if (oldSize != contentsSize)
        m_graphicsLayer->setSize(contentsSize);

    m_graphicsLayer->setContentsVisible(true);
    m_graphicsLayer->setBackfaceVisibility(renderer()->style()->backfaceVisibility() == BackfaceVisibilityVisible);
}

void CompositedLayerMapping::computeGraphicsLayerParentLocation(const RenderLayer* compositingContainer, const IntRect& ancestorCompositingBounds, IntPoint& graphicsLayerParentLocation)
{
    if (compositingContainer && compositingContainer->compositedLayerMapping()->hasClippingLayer()) {
        // If the compositing ancestor has a layer to clip children, we parent in that, and therefore
        // position relative to it.
        IntRect clippingBox = clipBox(toRenderBox(compositingContainer->renderer()));
        graphicsLayerParentLocation = clippingBox.location() + roundedIntSize(compositingContainer->subpixelAccumulation());
    } else if (compositingContainer && compositingContainer->compositedLayerMapping()->childTransformLayer()) {
        // Similarly, if the compositing ancestor has a child transform layer, we parent in that, and therefore
        // position relative to it. It's already taken into account the contents offset, so we do not need to here.
        graphicsLayerParentLocation = roundedIntPoint(compositingContainer->subpixelAccumulation());
    } else if (compositingContainer) {
        graphicsLayerParentLocation = ancestorCompositingBounds.location();
    } else {
        graphicsLayerParentLocation = renderer()->view()->documentRect().location();
    }

    if (compositingContainer && compositingContainer->needsCompositedScrolling()) {
        RenderBox* renderBox = toRenderBox(compositingContainer->renderer());
        IntSize scrollOffset = renderBox->scrolledContentOffset();
        IntPoint scrollOrigin(renderBox->borderLeft(), renderBox->borderTop());
        graphicsLayerParentLocation = scrollOrigin - scrollOffset;
    }
}

void CompositedLayerMapping::updateAncestorClippingLayerGeometry(const RenderLayer* compositingContainer, const IntPoint& snappedOffsetFromCompositedAncestor, IntPoint& graphicsLayerParentLocation)
{
    if (!compositingContainer || !m_ancestorClippingLayer)
        return;

    ClipRectsContext clipRectsContext(compositingContainer, PaintingClipRectsIgnoringOverflowClip);
    IntRect parentClipRect = pixelSnappedIntRect(m_owningLayer.clipper().backgroundClipRect(clipRectsContext).rect());
    ASSERT(parentClipRect != PaintInfo::infiniteRect());
    m_ancestorClippingLayer->setPosition(FloatPoint(parentClipRect.location() - graphicsLayerParentLocation));
    m_ancestorClippingLayer->setSize(parentClipRect.size());

    // backgroundRect is relative to compositingContainer, so subtract snappedOffsetFromCompositedAncestor.X/snappedOffsetFromCompositedAncestor.Y to get back to local coords.
    m_ancestorClippingLayer->setOffsetFromRenderer(parentClipRect.location() - snappedOffsetFromCompositedAncestor);

    // The primary layer is then parented in, and positioned relative to this clipping layer.
    graphicsLayerParentLocation = parentClipRect.location();
}

void CompositedLayerMapping::updateOverflowControlsHostLayerGeometry(const RenderLayer* compositingStackingContext)
{
    if (!m_overflowControlsHostLayer)
        return;

    if (needsToReparentOverflowControls()) {
        if (m_overflowControlsClippingLayer) {
            m_overflowControlsClippingLayer->setPosition(m_ancestorClippingLayer->position());
            m_overflowControlsClippingLayer->setSize(m_ancestorClippingLayer->size());
            m_overflowControlsClippingLayer->setOffsetFromRenderer(m_ancestorClippingLayer->offsetFromRenderer());
            m_overflowControlsClippingLayer->setMasksToBounds(true);

            m_overflowControlsHostLayer->setPosition(IntPoint(-m_overflowControlsClippingLayer->offsetFromRenderer()));
        } else {
            // The controls are in the same 2D space as the compositing container, so we can map them into the space of the container.
            TransformState transformState(TransformState::ApplyTransformDirection, FloatPoint());
            m_owningLayer.renderer()->mapLocalToContainer(compositingStackingContext->renderer(), transformState, ApplyContainerFlip);
            transformState.flatten();
            LayoutPoint offsetFromStackingContainer = LayoutPoint(transformState.lastPlanarPoint());
            m_overflowControlsHostLayer->setPosition(FloatPoint(offsetFromStackingContainer));
        }
    } else {
        m_overflowControlsHostLayer->setPosition(FloatPoint());
    }
}

void CompositedLayerMapping::updateChildContainmentLayerGeometry(const IntRect& clippingBox, const IntRect& localCompositingBounds)
{
    if (!m_childContainmentLayer)
        return;

    m_childContainmentLayer->setPosition(FloatPoint(clippingBox.location() - localCompositingBounds.location() + roundedIntSize(m_owningLayer.subpixelAccumulation())));
    m_childContainmentLayer->setSize(clippingBox.size());
    m_childContainmentLayer->setOffsetFromRenderer(toIntSize(clippingBox.location()));
    if (m_childClippingMaskLayer && !renderer()->style()->clipPath()) {
        m_childClippingMaskLayer->setPosition(m_childContainmentLayer->position());
        m_childClippingMaskLayer->setSize(m_childContainmentLayer->size());
        m_childClippingMaskLayer->setOffsetFromRenderer(m_childContainmentLayer->offsetFromRenderer());
    }
}

void CompositedLayerMapping::updateChildTransformLayerGeometry()
{
    if (!m_childTransformLayer)
        return;
    const IntRect borderBox = toRenderBox(m_owningLayer.renderer())->pixelSnappedBorderBoxRect();
    m_childTransformLayer->setSize(borderBox.size());
    m_childTransformLayer->setPosition(FloatPoint(contentOffsetInCompositingLayer()));
}

void CompositedLayerMapping::updateMaskLayerGeometry()
{
    if (!m_maskLayer)
        return;

    if (m_maskLayer->size() != m_graphicsLayer->size()) {
        m_maskLayer->setSize(m_graphicsLayer->size());
        m_maskLayer->setNeedsDisplay();
    }
    m_maskLayer->setPosition(FloatPoint());
    m_maskLayer->setOffsetFromRenderer(m_graphicsLayer->offsetFromRenderer());
}

void CompositedLayerMapping::updateTransformGeometry(const IntPoint& snappedOffsetFromCompositedAncestor, const IntRect& relativeCompositingBounds)
{
    if (m_owningLayer.hasTransform()) {
        const LayoutRect borderBox = toRenderBox(renderer())->borderBoxRect();

        // Get layout bounds in the coords of compositingContainer to match relativeCompositingBounds.
        IntRect layerBounds = pixelSnappedIntRect(toLayoutPoint(m_owningLayer.subpixelAccumulation()), borderBox.size());
        layerBounds.moveBy(snappedOffsetFromCompositedAncestor);

        // Update properties that depend on layer dimensions
        FloatPoint3D transformOrigin = computeTransformOrigin(IntRect(IntPoint(), layerBounds.size()));

        // |transformOrigin| is in the local space of this layer. layerBounds - relativeCompositingBounds converts to the space of the
        // compositing bounds relative to the composited ancestor. This does not apply to the z direction, since the page is 2D.
        FloatPoint3D compositedTransformOrigin(
            layerBounds.x() - relativeCompositingBounds.x() + transformOrigin.x(),
            layerBounds.y() - relativeCompositingBounds.y() + transformOrigin.y(),
            transformOrigin.z());
        m_graphicsLayer->setTransformOrigin(compositedTransformOrigin);
    } else {
        FloatPoint3D compositedTransformOrigin(
            relativeCompositingBounds.width() * 0.5f,
            relativeCompositingBounds.height() * 0.5f,
            0.f);
        m_graphicsLayer->setTransformOrigin(compositedTransformOrigin);
    }
}

void CompositedLayerMapping::updateChildClippingMaskLayerGeometry()
{
    if (!m_childClippingMaskLayer || !renderer()->style()->clipPath())
        return;
    RenderBox* renderBox = toRenderBox(renderer());
    IntRect clientBox = enclosingIntRect(renderBox->clientBoxRect());

    m_childClippingMaskLayer->setPosition(m_graphicsLayer->position());
    m_childClippingMaskLayer->setSize(m_graphicsLayer->size());
    m_childClippingMaskLayer->setOffsetFromRenderer(toIntSize(clientBox.location()));

    // NOTE: also some stuff happening in updateChildContainmentLayerGeometry().
}

void CompositedLayerMapping::updateForegroundLayerGeometry(const FloatSize& relativeCompositingBoundsSize, const IntRect& clippingBox)
{
    if (!m_foregroundLayer)
        return;

    FloatSize foregroundSize = relativeCompositingBoundsSize;
    IntSize foregroundOffset = m_graphicsLayer->offsetFromRenderer();
    m_foregroundLayer->setPosition(FloatPoint());

    if (hasClippingLayer()) {
        // If we have a clipping layer (which clips descendants), then the foreground layer is a child of it,
        // so that it gets correctly sorted with children. In that case, position relative to the clipping layer.
        foregroundSize = FloatSize(clippingBox.size());
        foregroundOffset = toIntSize(clippingBox.location());
    } else if (m_childTransformLayer) {
        // Things are different if we have a child transform layer rather
        // than a clipping layer. In this case, we want to actually change
        // the position of the layer (to compensate for our ancestor
        // compositing layer's position) rather than leave the position the
        // same and use offset-from-renderer + size to describe a clipped
        // "window" onto the clipped layer.

        m_foregroundLayer->setPosition(-m_childTransformLayer->position());
    }

    if (foregroundSize != m_foregroundLayer->size()) {
        m_foregroundLayer->setSize(foregroundSize);
        m_foregroundLayer->setNeedsDisplay();
    }
    m_foregroundLayer->setOffsetFromRenderer(foregroundOffset);
}

void CompositedLayerMapping::updateBackgroundLayerGeometry(const FloatSize& relativeCompositingBoundsSize)
{
    if (!m_backgroundLayer)
        return;

    FloatSize backgroundSize = relativeCompositingBoundsSize;
    if (backgroundLayerPaintsFixedRootBackground()) {
        FrameView* frameView = toRenderView(renderer())->frameView();
        backgroundSize = frameView->visibleContentRect().size();
    }
    m_backgroundLayer->setPosition(FloatPoint());
    if (backgroundSize != m_backgroundLayer->size()) {
        m_backgroundLayer->setSize(backgroundSize);
        m_backgroundLayer->setNeedsDisplay();
    }
    m_backgroundLayer->setOffsetFromRenderer(m_graphicsLayer->offsetFromRenderer());
}

void CompositedLayerMapping::updateInternalHierarchy()
{
    // m_foregroundLayer has to be inserted in the correct order with child layers,
    // so it's not inserted here.
    if (m_ancestorClippingLayer)
        m_ancestorClippingLayer->removeAllChildren();

    m_graphicsLayer->removeFromParent();

    if (m_ancestorClippingLayer)
        m_ancestorClippingLayer->addChild(m_graphicsLayer.get());

    if (m_childContainmentLayer)
        m_graphicsLayer->addChild(m_childContainmentLayer.get());
    else if (m_childTransformLayer)
        m_graphicsLayer->addChild(m_childTransformLayer.get());

    // The clip for child layers does not include space for overflow controls, so they exist as
    // siblings of the clipping layer if we have one. Normal children of this layer are set as
    // children of the clipping layer.
    if (m_overflowControlsClippingLayer) {
        ASSERT(m_overflowControlsHostLayer);
        m_graphicsLayer->addChild(m_overflowControlsClippingLayer.get());
        m_overflowControlsClippingLayer->addChild(m_overflowControlsHostLayer.get());
    } else if (m_overflowControlsHostLayer) {
        m_graphicsLayer->addChild(m_overflowControlsHostLayer.get());
    }

    // The squashing containment layer, if it exists, becomes a no-op parent.
    if (m_squashingLayer) {
        ASSERT(compositor()->layerSquashingEnabled());
        ASSERT((m_ancestorClippingLayer && !m_squashingContainmentLayer) || (!m_ancestorClippingLayer && m_squashingContainmentLayer));

        if (m_squashingContainmentLayer) {
            m_squashingContainmentLayer->removeAllChildren();
            m_squashingContainmentLayer->addChild(m_graphicsLayer.get());
            m_squashingContainmentLayer->addChild(m_squashingLayer.get());
        } else {
            // The ancestor clipping layer is already set up and has m_graphicsLayer under it.
            m_ancestorClippingLayer->addChild(m_squashingLayer.get());
        }
    }
}

void CompositedLayerMapping::updatePaintingPhases()
{
    m_graphicsLayer->setPaintingPhase(paintingPhaseForPrimaryLayer());
}

void CompositedLayerMapping::updateContentsRect()
{
    m_graphicsLayer->setContentsRect(pixelSnappedIntRect(contentsBox()));
}

void CompositedLayerMapping::updateContentsOffsetInCompositingLayer(const IntPoint& snappedOffsetFromCompositedAncestor, const IntPoint& graphicsLayerParentLocation)
{
    // m_graphicsLayer is positioned relative to our compositing ancestor
    // RenderLayer, but it's not positioned at the origin of m_owningLayer, it's
    // offset by m_contentBounds.location(). This is what
    // contentOffsetInCompositingLayer is meant to capture, roughly speaking
    // (ignoring rounding and subpixel accumulation).
    //
    // Our ancestor graphics layers in this CLM (m_graphicsLayer and potentially
    // m_ancestorClippingLayer) have pixel snapped, so if we don't adjust this
    // offset, we'll see accumulated rounding errors due to that snapping.
    //
    // In order to ensure that we account for this rounding, we compute
    // contentsOffsetInCompositingLayer in a somewhat roundabout way.
    //
    // our position = (desired position) - (inherited graphics layer offset).
    //
    // Precisely,
    // Offset = snappedOffsetFromCompositedAncestor - offsetDueToAncestorGraphicsLayers (See code below)
    //      = snappedOffsetFromCompositedAncestor - (m_graphicsLayer->position() + graphicsLayerParentLocation)
    //      = snappedOffsetFromCompositedAncestor - (relativeCompositingBounds.location() - graphicsLayerParentLocation + graphicsLayerParentLocation) (See updateMainGraphicsLayerGeometry)
    //      = snappedOffsetFromCompositedAncestor - relativeCompositingBounds.location()
    //      = snappedOffsetFromCompositedAncestor - (pixelSnappedIntRect(contentBounds.location()) + snappedOffsetFromCompositedAncestor) (See computeBoundsOfOwningLayer)
    //      = -pixelSnappedIntRect(contentBounds.location())
    //
    // As you can see, we've ended up at the same spot (-contentBounds.location()),
    // but by subtracting off our ancestor graphics layers positions, we can be
    // sure we've accounted correctly for any pixel snapping due to ancestor
    // graphics layers.
    //
    // And drawing of composited children takes into account the subpixel
    // accumulation of this CLM already (through its own
    // graphicsLayerParentLocation it appears).
    FloatPoint offsetDueToAncestorGraphicsLayers = m_graphicsLayer->position() + graphicsLayerParentLocation;
    m_contentOffsetInCompositingLayer = LayoutSize(snappedOffsetFromCompositedAncestor - offsetDueToAncestorGraphicsLayers);
    m_contentOffsetInCompositingLayerDirty = false;
}

void CompositedLayerMapping::updateDrawsContent()
{
    bool hasPaintedContent = containsPaintedContent();
    if (hasPaintedContent && isAcceleratedCanvas(renderer())) {
        CanvasRenderingContext* context = toHTMLCanvasElement(renderer()->node())->renderingContext();
        // Content layer may be null if context is lost.
        if (WebLayer* contentLayer = context->platformLayer()) {
            Color bgColor(Color::transparent);
            if (contentLayerSupportsDirectBackgroundComposition(renderer())) {
                bgColor = rendererBackgroundColor();
            }
            contentLayer->setBackgroundColor(bgColor.rgb());
        }
    }

    // FIXME: we could refine this to only allocate backings for one of these layers if possible.
    m_graphicsLayer->setDrawsContent(hasPaintedContent);
    if (m_foregroundLayer)
        m_foregroundLayer->setDrawsContent(hasPaintedContent);

    if (m_backgroundLayer)
        m_backgroundLayer->setDrawsContent(hasPaintedContent);
}

void CompositedLayerMapping::updateChildrenTransform()
{
    if (GraphicsLayer* childTransformLayer = layerForChildrenTransform()) {
        childTransformLayer->setTransform(owningLayer().perspectiveTransform());
        childTransformLayer->setTransformOrigin(FloatPoint3D(childTransformLayer->size().width() * 0.5f, childTransformLayer->size().height() * 0.5f, 0.f));
    }

    updateShouldFlattenTransform();
}

// Return true if the layers changed.
bool CompositedLayerMapping::updateClippingLayers(bool needsAncestorClip, bool needsDescendantClip)
{
    bool layersChanged = false;

    if (needsAncestorClip) {
        if (!m_ancestorClippingLayer) {
            m_ancestorClippingLayer = createGraphicsLayer(CompositingReasonLayerForAncestorClip);
            m_ancestorClippingLayer->setMasksToBounds(true);
            layersChanged = true;
        }
    } else if (m_ancestorClippingLayer) {
        m_ancestorClippingLayer->removeFromParent();
        m_ancestorClippingLayer = nullptr;
        layersChanged = true;
    }

    if (needsDescendantClip) {
        // FIXME(sky): remove
    } else if (hasClippingLayer()) {
        m_childContainmentLayer->removeFromParent();
        m_childContainmentLayer = nullptr;
        layersChanged = true;
    }

    return layersChanged;
}

bool CompositedLayerMapping::updateChildTransformLayer(bool needsChildTransformLayer)
{
    bool layersChanged = false;

    if (needsChildTransformLayer) {
        if (!m_childTransformLayer) {
            m_childTransformLayer = createGraphicsLayer(CompositingReasonLayerForPerspective);
            m_childTransformLayer->setDrawsContent(false);
            layersChanged = true;
        }
    } else if (m_childTransformLayer) {
        m_childTransformLayer->removeFromParent();
        m_childTransformLayer = nullptr;
        layersChanged = true;
    }

    return layersChanged;
}

void CompositedLayerMapping::setBackgroundLayerPaintsFixedRootBackground(bool backgroundLayerPaintsFixedRootBackground)
{
    m_backgroundLayerPaintsFixedRootBackground = backgroundLayerPaintsFixedRootBackground;
}

enum ApplyToGraphicsLayersModeFlags {
    ApplyToCoreLayers = (1 << 0),
    ApplyToSquashingLayer = (1 << 1),
    ApplyToBackgroundLayer = (1 << 3),
    ApplyToMaskLayers = (1 << 4),
    ApplyToContentLayers = (1 << 5),
    ApplyToAllGraphicsLayers = (ApplyToSquashingLayer | ApplyToBackgroundLayer | ApplyToMaskLayers | ApplyToCoreLayers | ApplyToContentLayers)
};
typedef unsigned ApplyToGraphicsLayersMode;

template <typename Func>
static void ApplyToGraphicsLayers(const CompositedLayerMapping* mapping, const Func& f, ApplyToGraphicsLayersMode mode)
{
    ASSERT(mode);

    if ((mode & ApplyToCoreLayers) && mapping->squashingContainmentLayer())
        f(mapping->squashingContainmentLayer());
    if ((mode & ApplyToCoreLayers) && mapping->childTransformLayer())
        f(mapping->childTransformLayer());
    if ((mode & ApplyToCoreLayers) && mapping->ancestorClippingLayer())
        f(mapping->ancestorClippingLayer());
    if (((mode & ApplyToCoreLayers) || (mode & ApplyToContentLayers)) && mapping->mainGraphicsLayer())
        f(mapping->mainGraphicsLayer());
    if ((mode & ApplyToCoreLayers) && mapping->clippingLayer())
        f(mapping->clippingLayer());
    if (((mode & ApplyToCoreLayers) || (mode & ApplyToContentLayers)) && mapping->foregroundLayer())
        f(mapping->foregroundLayer());

    if ((mode & ApplyToSquashingLayer) && mapping->squashingLayer())
        f(mapping->squashingLayer());

    if (((mode & ApplyToMaskLayers) || (mode & ApplyToContentLayers)) && mapping->maskLayer())
        f(mapping->maskLayer());
    if (((mode & ApplyToMaskLayers) || (mode & ApplyToContentLayers)) && mapping->childClippingMaskLayer())
        f(mapping->childClippingMaskLayer());

    if (((mode & ApplyToBackgroundLayer) || (mode & ApplyToContentLayers)) && mapping->backgroundLayer())
        f(mapping->backgroundLayer());
}

struct UpdateRenderingContextFunctor {
    void operator() (GraphicsLayer* layer) const { layer->setRenderingContext(renderingContext); }
    int renderingContext;
};

void CompositedLayerMapping::updateRenderingContext()
{
    // All layers but the squashing layer (which contains 'alien' content) should be included in this
    // rendering context.
    int id = 0;

    // NB, it is illegal at this point to query an ancestor's compositing state. Some compositing
    // reasons depend on the compositing state of ancestors. So if we want a rendering context id
    // for the context root, we cannot ask for the id of its associated WebLayer now; it may not have
    // one yet. We could do a second past after doing the compositing updates to get these ids,
    // but this would actually be harmful. We do not want to attach any semantic meaning to
    // the context id other than the fact that they group a number of layers together for the
    // sake of 3d sorting. So instead we will ask the compositor to vend us an arbitrary, but
    // consistent id.
    if (RenderLayer* root = m_owningLayer.renderingContextRoot()) {
        if (Node* node = root->renderer()->node())
            id = static_cast<int>(WTF::PtrHash<Node*>::hash(node));
    }

    UpdateRenderingContextFunctor functor = { id };
    ApplyToGraphicsLayersMode mode = ApplyToAllGraphicsLayers & ~ApplyToSquashingLayer;
    ApplyToGraphicsLayers<UpdateRenderingContextFunctor>(this, functor, mode);
}

struct UpdateShouldFlattenTransformFunctor {
    void operator() (GraphicsLayer* layer) const { layer->setShouldFlattenTransform(shouldFlatten); }
    bool shouldFlatten;
};

void CompositedLayerMapping::updateShouldFlattenTransform()
{
    // All CLM-managed layers that could affect a descendant layer should update their
    // should-flatten-transform value (the other layers' transforms don't matter here).
    UpdateShouldFlattenTransformFunctor functor = { !m_owningLayer.shouldPreserve3D() };
    ApplyToGraphicsLayersMode mode = ApplyToCoreLayers;
    ApplyToGraphicsLayers(this, functor, mode);

    // Note, if we apply perspective, we have to set should flatten differently
    // so that the transform propagates to child layers correctly.
    if (GraphicsLayer* childTransformLayer = layerForChildrenTransform()) {
        bool hasPerspective = false;
        if (RenderStyle* style = m_owningLayer.renderer()->style())
            hasPerspective = style->hasPerspective();
        if (hasPerspective)
            childTransformLayer->setShouldFlattenTransform(false);
    }
}

bool CompositedLayerMapping::updateForegroundLayer(bool needsForegroundLayer)
{
    bool layerChanged = false;
    if (needsForegroundLayer) {
        if (!m_foregroundLayer) {
            m_foregroundLayer = createGraphicsLayer(CompositingReasonLayerForForeground);
            m_foregroundLayer->setDrawsContent(true);
            m_foregroundLayer->setPaintingPhase(GraphicsLayerPaintForeground);
            layerChanged = true;
        }
    } else if (m_foregroundLayer) {
        m_foregroundLayer->removeFromParent();
        m_foregroundLayer = nullptr;
        layerChanged = true;
    }

    return layerChanged;
}

bool CompositedLayerMapping::updateBackgroundLayer(bool needsBackgroundLayer)
{
    bool layerChanged = false;
    if (needsBackgroundLayer) {
        if (!m_backgroundLayer) {
            m_backgroundLayer = createGraphicsLayer(CompositingReasonLayerForBackground);
            m_backgroundLayer->setDrawsContent(true);
            m_backgroundLayer->setTransformOrigin(FloatPoint3D());
            m_backgroundLayer->setPaintingPhase(GraphicsLayerPaintBackground);
#if !OS(ANDROID)
            m_backgroundLayer->contentLayer()->setDrawCheckerboardForMissingTiles(true);
            m_graphicsLayer->contentLayer()->setDrawCheckerboardForMissingTiles(false);
#endif
            layerChanged = true;
        }
    } else {
        if (m_backgroundLayer) {
            m_backgroundLayer->removeFromParent();
            m_backgroundLayer = nullptr;
#if !OS(ANDROID)
            m_graphicsLayer->contentLayer()->setDrawCheckerboardForMissingTiles(true);
#endif
            layerChanged = true;
        }
    }

    if (layerChanged && !m_owningLayer.renderer()->documentBeingDestroyed())
        compositor()->rootFixedBackgroundsChanged();

    return layerChanged;
}

bool CompositedLayerMapping::updateMaskLayer(bool needsMaskLayer)
{
    bool layerChanged = false;
    if (needsMaskLayer) {
        if (!m_maskLayer) {
            m_maskLayer = createGraphicsLayer(CompositingReasonLayerForMask);
            m_maskLayer->setDrawsContent(true);
            m_maskLayer->setPaintingPhase(GraphicsLayerPaintMask);
            layerChanged = true;
        }
    } else if (m_maskLayer) {
        m_maskLayer = nullptr;
        layerChanged = true;
    }

    return layerChanged;
}

bool CompositedLayerMapping::updateClippingMaskLayers(bool needsChildClippingMaskLayer)
{
    bool layerChanged = false;
    if (needsChildClippingMaskLayer) {
        if (!m_childClippingMaskLayer) {
            m_childClippingMaskLayer = createGraphicsLayer(CompositingReasonLayerForClippingMask);
            m_childClippingMaskLayer->setDrawsContent(true);
            m_childClippingMaskLayer->setPaintingPhase(GraphicsLayerPaintChildClippingMask);
            layerChanged = true;
        }
    } else if (m_childClippingMaskLayer) {
        m_childClippingMaskLayer = nullptr;
        layerChanged = true;
    }
    return layerChanged;
}

void CompositedLayerMapping::updateClipParent()
{
    if (owningLayerClippedByLayerNotAboveCompositedAncestor())
        return;

    RenderLayer* clipParent = m_owningLayer.clipParent();
    if (clipParent)
        clipParent = clipParent->enclosingLayerWithCompositedLayerMapping(IncludeSelf);
}

bool CompositedLayerMapping::updateSquashingLayers(bool needsSquashingLayers)
{
    bool layersChanged = false;

    if (needsSquashingLayers) {
        ASSERT(compositor()->layerSquashingEnabled());

        if (!m_squashingLayer) {
            m_squashingLayer = createGraphicsLayer(CompositingReasonLayerForSquashingContents);
            m_squashingLayer->setDrawsContent(true);
            layersChanged = true;
        }

        if (m_ancestorClippingLayer) {
            if (m_squashingContainmentLayer) {
                m_squashingContainmentLayer->removeFromParent();
                m_squashingContainmentLayer = nullptr;
                layersChanged = true;
            }
        } else {
            if (!m_squashingContainmentLayer) {
                m_squashingContainmentLayer = createGraphicsLayer(CompositingReasonLayerForSquashingContainer);
                layersChanged = true;
            }
        }

        ASSERT((m_ancestorClippingLayer && !m_squashingContainmentLayer) || (!m_ancestorClippingLayer && m_squashingContainmentLayer));
        ASSERT(m_squashingLayer);
    } else {
        if (m_squashingLayer) {
            m_squashingLayer->removeFromParent();
            m_squashingLayer = nullptr;
            layersChanged = true;
        }
        if (m_squashingContainmentLayer) {
            m_squashingContainmentLayer->removeFromParent();
            m_squashingContainmentLayer = nullptr;
            layersChanged = true;
        }
        ASSERT(!m_squashingLayer && !m_squashingContainmentLayer);
    }

    return layersChanged;
}

GraphicsLayerPaintingPhase CompositedLayerMapping::paintingPhaseForPrimaryLayer() const
{
    unsigned phase = 0;
    if (!m_backgroundLayer)
        phase |= GraphicsLayerPaintBackground;
    if (!m_foregroundLayer)
        phase |= GraphicsLayerPaintForeground;
    if (!m_maskLayer)
        phase |= GraphicsLayerPaintMask;

    return static_cast<GraphicsLayerPaintingPhase>(phase);
}

float CompositedLayerMapping::compositingOpacity(float rendererOpacity) const
{
    float finalOpacity = rendererOpacity;

    for (RenderLayer* curr = m_owningLayer.parent(); curr; curr = curr->parent()) {
        // We only care about parents that are stacking contexts.
        // Recall that opacity creates stacking context.
        if (!curr->stackingNode()->isStackingContext())
            continue;

        // If we found a composited layer, regardless of whether it actually
        // paints into it, we want to compute opacity relative to it. So we can
        // break here.
        //
        // FIXME: with grouped backings, a composited descendant will have to
        // continue past the grouped (squashed) layers that its parents may
        // contribute to. This whole confusion can be avoided by specifying
        // explicitly the composited ancestor where we would stop accumulating
        // opacity.
        if (curr->compositingState() == PaintsIntoOwnBacking || curr->compositingState() == HasOwnBackingButPaintsIntoAncestor)
            break;

        finalOpacity *= curr->renderer()->opacity();
    }

    return finalOpacity;
}

Color CompositedLayerMapping::rendererBackgroundColor() const
{
    return renderer()->resolveColor(CSSPropertyBackgroundColor);
}

void CompositedLayerMapping::updateBackgroundColor()
{
    m_graphicsLayer->setBackgroundColor(rendererBackgroundColor());
}

bool CompositedLayerMapping::paintsChildren() const
{
    if (m_owningLayer.hasNonEmptyChildRenderers())
        return true;

    // FIXME: We shouldn't be called with a stale z-order lists. See bug 85512.
    m_owningLayer.stackingNode()->updateLayerListsIfNeeded();

#if ENABLE(ASSERT)
    LayerListMutationDetector mutationChecker(m_owningLayer.stackingNode());
#endif

    RenderLayerStackingNodeIterator it(*m_owningLayer.stackingNode(), AllChildren);
    while (RenderLayerStackingNode* stackingNode = it.next()) {
        if (stackingNode->layer()->hasCompositedLayerMapping())
            continue;
        return true;
    }

    return false;
}

bool CompositedLayerMapping::containsPaintedContent() const
{
    if (paintsIntoCompositedAncestor())
        return false;

    if (renderer()->isImage() && isDirectlyCompositedImage())
        return false;

    RenderObject* renderObject = renderer();

    if (m_owningLayer.hasVisibleBoxDecorations())
        return true;

    if (renderObject->hasMask()) // masks require special treatment
        return true;

    if (renderObject->isReplaced())
        return true;

    if (renderObject->node() && renderObject->node()->isDocumentNode()) {
        // Look to see if the root object has a non-simple background
        RenderObject* rootObject = renderObject->document().documentElement() ? renderObject->document().documentElement()->renderer() : 0;
        // Reject anything that has a border, a border-radius or outline,
        // or is not a simple background (no background, or solid color).
        if (rootObject && hasBoxDecorationsOrBackgroundImage(rootObject->style()))
            return true;
    }

    // FIXME: it's O(n^2). A better solution is needed.
    return paintsChildren();
}

// An image can be directly compositing if it's the sole content of the layer, and has no box decorations
// that require painting. Direct compositing saves backing store.
bool CompositedLayerMapping::isDirectlyCompositedImage() const
{
    ASSERT(renderer()->isImage());

    RenderObject* renderObject = renderer();
    if (m_owningLayer.hasBoxDecorationsOrBackground() || renderObject->hasClip() || renderObject->hasClipPath())
        return false;

    RenderImage* imageRenderer = toRenderImage(renderObject);
    if (ImageResource* cachedImage = imageRenderer->cachedImage()) {
        if (!cachedImage->hasImage())
            return false;

        Image* image = cachedImage->imageForRenderer(imageRenderer);
        return image->isBitmapImage();
    }

    return false;
}

void CompositedLayerMapping::contentChanged(ContentChangeType changeType)
{
    if ((changeType == ImageChanged) && renderer()->isImage() && isDirectlyCompositedImage()) {
        updateImageContents();
        return;
    }

    if (changeType == CanvasChanged && isAcceleratedCanvas(renderer())) {
        m_graphicsLayer->setContentsNeedsDisplay();
        return;
    }
}

void CompositedLayerMapping::updateImageContents()
{
    ASSERT(renderer()->isImage());
    RenderImage* imageRenderer = toRenderImage(renderer());

    ImageResource* cachedImage = imageRenderer->cachedImage();
    if (!cachedImage)
        return;

    Image* image = cachedImage->imageForRenderer(imageRenderer);
    if (!image)
        return;

    // We have to wait until the image is fully loaded before setting it on the layer.
    if (!cachedImage->isLoaded())
        return;

    // This is a no-op if the layer doesn't have an inner layer for the image.
    m_graphicsLayer->setContentsToImage(image);

    // Prevent double-drawing: https://bugs.webkit.org/show_bug.cgi?id=58632
    updateDrawsContent();

    // Image animation is "lazy", in that it automatically stops unless someone is drawing
    // the image. So we have to kick the animation each time; this has the downside that the
    // image will keep animating, even if its layer is not visible.
    image->startAnimation();
}

FloatPoint3D CompositedLayerMapping::computeTransformOrigin(const IntRect& borderBox) const
{
    RenderStyle* style = renderer()->style();

    FloatPoint3D origin;
    origin.setX(floatValueForLength(style->transformOriginX(), borderBox.width()));
    origin.setY(floatValueForLength(style->transformOriginY(), borderBox.height()));
    origin.setZ(style->transformOriginZ());

    return origin;
}

// Return the offset from the top-left of this compositing layer at which the
// renderer's contents are painted.
LayoutSize CompositedLayerMapping::contentOffsetInCompositingLayer() const
{
    ASSERT(!m_contentOffsetInCompositingLayerDirty);
    return m_contentOffsetInCompositingLayer;
}

LayoutRect CompositedLayerMapping::contentsBox() const
{
    LayoutRect contentsBox = contentsRect(renderer());
    contentsBox.move(contentOffsetInCompositingLayer());
    return contentsBox;
}

bool CompositedLayerMapping::needsToReparentOverflowControls() const
{
    return m_owningLayer.scrollableArea()
        && m_owningLayer.scrollableArea()->hasOverlayScrollbars()
        && m_owningLayer.scrollableArea()->topmostScrollChild();
}

GraphicsLayer* CompositedLayerMapping::detachLayerForOverflowControls(const RenderLayer& enclosingLayer)
{
    GraphicsLayer* host = m_overflowControlsClippingLayer.get();
    if (!host)
        host = m_overflowControlsHostLayer.get();
    host->removeFromParent();
    return host;
}

GraphicsLayer* CompositedLayerMapping::parentForSublayers() const
{
    if (m_childContainmentLayer)
        return m_childContainmentLayer.get();

    if (m_childTransformLayer)
        return m_childTransformLayer.get();

    return m_graphicsLayer.get();
}

GraphicsLayer* CompositedLayerMapping::childForSuperlayers() const
{
    if (m_squashingContainmentLayer)
        return m_squashingContainmentLayer.get();

    if (m_ancestorClippingLayer)
        return m_ancestorClippingLayer.get();

    return m_graphicsLayer.get();
}

GraphicsLayer* CompositedLayerMapping::layerForChildrenTransform() const
{
    if (GraphicsLayer* clipLayer = clippingLayer())
        return clipLayer;
    return m_childTransformLayer.get();
}

bool CompositedLayerMapping::updateRequiresOwnBackingStoreForAncestorReasons(const RenderLayer* compositingAncestorLayer)
{
    unsigned previousRequiresOwnBackingStoreForAncestorReasons = m_requiresOwnBackingStoreForAncestorReasons;
    bool previousPaintsIntoCompositedAncestor = paintsIntoCompositedAncestor();
    bool canPaintIntoAncestor = compositingAncestorLayer
        && (compositingAncestorLayer->compositedLayerMapping()->mainGraphicsLayer()->drawsContent()
            || compositingAncestorLayer->compositedLayerMapping()->paintsIntoCompositedAncestor());

    m_requiresOwnBackingStoreForAncestorReasons = !canPaintIntoAncestor;
    if (paintsIntoCompositedAncestor() != previousPaintsIntoCompositedAncestor) {
        // Back out the change temporarily while invalidating with respect to the old container.
        m_requiresOwnBackingStoreForAncestorReasons = !m_requiresOwnBackingStoreForAncestorReasons;
        compositor()->paintInvalidationOnCompositingChange(&m_owningLayer);
        m_requiresOwnBackingStoreForAncestorReasons = !m_requiresOwnBackingStoreForAncestorReasons;
    }

    return m_requiresOwnBackingStoreForAncestorReasons != previousRequiresOwnBackingStoreForAncestorReasons;
}

bool CompositedLayerMapping::updateRequiresOwnBackingStoreForIntrinsicReasons()
{
    unsigned previousRequiresOwnBackingStoreForIntrinsicReasons = m_requiresOwnBackingStoreForIntrinsicReasons;
    bool previousPaintsIntoCompositedAncestor = paintsIntoCompositedAncestor();
    RenderObject* renderer = m_owningLayer.renderer();
    m_requiresOwnBackingStoreForIntrinsicReasons = m_owningLayer.isRootLayer()
        || (m_owningLayer.compositingReasons() & CompositingReasonComboReasonsThatRequireOwnBacking)
        || m_owningLayer.transform()
        || m_owningLayer.clipsCompositingDescendantsWithBorderRadius() // FIXME: Revisit this if the paintsIntoCompositedAncestor state is removed.
        || renderer->isTransparent()
        || renderer->hasMask();

    if (paintsIntoCompositedAncestor() != previousPaintsIntoCompositedAncestor) {
        // Back out the change temporarily while invalidating with respect to the old container.
        m_requiresOwnBackingStoreForIntrinsicReasons = !m_requiresOwnBackingStoreForIntrinsicReasons;
        compositor()->paintInvalidationOnCompositingChange(&m_owningLayer);
        m_requiresOwnBackingStoreForIntrinsicReasons = !m_requiresOwnBackingStoreForIntrinsicReasons;
    }

    return m_requiresOwnBackingStoreForIntrinsicReasons != previousRequiresOwnBackingStoreForIntrinsicReasons;
}

void CompositedLayerMapping::setBlendMode(WebBlendMode blendMode)
{
    if (m_ancestorClippingLayer) {
        m_ancestorClippingLayer->setBlendMode(blendMode);
        m_graphicsLayer->setBlendMode(WebBlendModeNormal);
    } else {
        m_graphicsLayer->setBlendMode(blendMode);
    }
}

GraphicsLayerUpdater::UpdateType CompositedLayerMapping::updateTypeForChildren(GraphicsLayerUpdater::UpdateType updateType) const
{
    if (m_pendingUpdateScope >= GraphicsLayerUpdateSubtree)
        return GraphicsLayerUpdater::ForceUpdate;
    return updateType;
}

struct SetContentsNeedsDisplayFunctor {
    void operator() (GraphicsLayer* layer) const
    {
        if (layer->drawsContent())
            layer->setNeedsDisplay();
    }
};

void CompositedLayerMapping::setSquashingContentsNeedDisplay()
{
    ApplyToGraphicsLayers(this, SetContentsNeedsDisplayFunctor(), ApplyToSquashingLayer);
}

void CompositedLayerMapping::setContentsNeedDisplay()
{
    // FIXME: need to split out paint invalidations for the background.
    ASSERT(!paintsIntoCompositedAncestor());
    ApplyToGraphicsLayers(this, SetContentsNeedsDisplayFunctor(), ApplyToContentLayers);
}

struct SetContentsNeedsDisplayInRectFunctor {
    void operator() (GraphicsLayer* layer) const
    {
        if (layer->drawsContent()) {
            IntRect layerDirtyRect = r;
            layerDirtyRect.move(-layer->offsetFromRenderer());
            layer->setNeedsDisplayInRect(layerDirtyRect);
        }
    }

    IntRect r;
};

// r is in the coordinate space of the layer's render object
void CompositedLayerMapping::setContentsNeedDisplayInRect(const LayoutRect& r)
{
    // FIXME: need to split out paint invalidations for the background.
    ASSERT(!paintsIntoCompositedAncestor());

    SetContentsNeedsDisplayInRectFunctor functor = {
        pixelSnappedIntRect(r.location() + m_owningLayer.subpixelAccumulation(), r.size())
    };
    ApplyToGraphicsLayers(this, functor, ApplyToContentLayers);
}

const GraphicsLayerPaintInfo* CompositedLayerMapping::containingSquashedLayer(const RenderObject* renderObject, const Vector<GraphicsLayerPaintInfo>& layers)
{
    for (size_t i = 0; i < layers.size(); ++i) {
        if (renderObject->isDescendantOf(layers[i].renderLayer->renderer()))
            return &layers[i];
    }
    return 0;
}

const GraphicsLayerPaintInfo* CompositedLayerMapping::containingSquashedLayer(const RenderObject* renderObject)
{
    return CompositedLayerMapping::containingSquashedLayer(renderObject, m_squashedLayers);
}

IntRect CompositedLayerMapping::localClipRectForSquashedLayer(const RenderLayer& referenceLayer, const GraphicsLayerPaintInfo& paintInfo, const Vector<GraphicsLayerPaintInfo>& layers)
{
    const RenderObject* clippingContainer = paintInfo.renderLayer->clippingContainer();
    if (clippingContainer == referenceLayer.clippingContainer())
        return PaintInfo::infiniteRect();

    ASSERT(clippingContainer);

    const GraphicsLayerPaintInfo* ancestorPaintInfo = containingSquashedLayer(clippingContainer, layers);
    // Must be there, otherwise CompositingLayerAssigner::canSquashIntoCurrentSquashingOwner would have disallowed squashing.
    ASSERT(ancestorPaintInfo);

    // FIXME: this is a potential performance issue. We shoudl consider caching these clip rects or otherwise optimizing.
    ClipRectsContext clipRectsContext(ancestorPaintInfo->renderLayer, UncachedClipRects);
    IntRect parentClipRect = pixelSnappedIntRect(paintInfo.renderLayer->clipper().backgroundClipRect(clipRectsContext).rect());
    ASSERT(parentClipRect != PaintInfo::infiniteRect());

    // Convert from ancestor to local coordinates.
    IntSize ancestorToLocalOffset = paintInfo.offsetFromRenderer - ancestorPaintInfo->offsetFromRenderer;
    parentClipRect.move(ancestorToLocalOffset);
    return parentClipRect;
}

void CompositedLayerMapping::doPaintTask(const GraphicsLayerPaintInfo& paintInfo, const PaintLayerFlags& paintLayerFlags, GraphicsContext* context,
    const IntRect& clip) // In the coords of rootLayer.
{
    RELEASE_ASSERT(paintInfo.renderLayer->compositingState() == PaintsIntoGroupedBacking || !paintsIntoCompositedAncestor());

    FontCachePurgePreventer fontCachePurgePreventer;

    // Note carefully: in theory it is appropriate to invoke context->save() here
    // and restore the context after painting. For efficiency, we are assuming that
    // it is equivalent to manually undo this offset translation, which means we are
    // assuming that the context's space was not affected by the RenderLayer
    // painting code.

    IntSize offset = paintInfo.offsetFromRenderer;
    context->translate(-offset.width(), -offset.height());

    // The dirtyRect is in the coords of the painting root.
    IntRect dirtyRect(clip);
    dirtyRect.move(offset);

    if (!(paintLayerFlags & PaintLayerPaintingOverflowContents)) {
        LayoutRect bounds = paintInfo.compositedBounds;
        bounds.move(paintInfo.renderLayer->subpixelAccumulation());
        dirtyRect.intersect(pixelSnappedIntRect(bounds));
    } else {
        dirtyRect.move(roundedIntSize(paintInfo.renderLayer->subpixelAccumulation()));
    }

#if ENABLE(ASSERT)
    paintInfo.renderLayer->renderer()->assertSubtreeIsLaidOut();
#endif

    if (paintInfo.renderLayer->compositingState() != PaintsIntoGroupedBacking) {
        // FIXME: GraphicsLayers need a way to split for RenderRegions.
        LayerPaintingInfo paintingInfo(paintInfo.renderLayer, dirtyRect, PaintBehaviorNormal, paintInfo.renderLayer->subpixelAccumulation());
        paintInfo.renderLayer->paintLayerContents(context, paintingInfo, paintLayerFlags);

        if (paintInfo.renderLayer->containsDirtyOverlayScrollbars())
            paintInfo.renderLayer->paintLayerContents(context, paintingInfo, paintLayerFlags | PaintLayerPaintingOverlayScrollbars);
    } else {
        ASSERT(compositor()->layerSquashingEnabled());
        LayerPaintingInfo paintingInfo(paintInfo.renderLayer, dirtyRect, PaintBehaviorNormal, paintInfo.renderLayer->subpixelAccumulation());

        // RenderLayer::paintLayer assumes that the caller clips to the passed rect. Squashed layers need to do this clipping in software,
        // since there is no graphics layer to clip them precisely. Furthermore, in some cases we squash layers that need clipping in software
        // from clipping ancestors (see CompositedLayerMapping::localClipRectForSquashedLayer()).
        context->save();
        dirtyRect.intersect(paintInfo.localClipRectForSquashedLayer);
        context->clip(dirtyRect);
        paintInfo.renderLayer->paintLayer(context, paintingInfo, paintLayerFlags);
        context->restore();
    }

    ASSERT(!paintInfo.renderLayer->usedTransparency());

    // Manually restore the context to its original state by applying the opposite translation.
    context->translate(offset.width(), offset.height());
}

// Up-call from compositing layer drawing callback.
void CompositedLayerMapping::paintContents(const GraphicsLayer* graphicsLayer, GraphicsContext& context, GraphicsLayerPaintingPhase graphicsLayerPaintingPhase, const IntRect& clip)
{
    // https://code.google.com/p/chromium/issues/detail?id=343772
    DisableCompositingQueryAsserts disabler;
#if ENABLE(ASSERT)
    // FIXME: once the state machine is ready, this can be removed and we can refer to that instead.
    if (Page* page = renderer()->frame()->page())
        page->setIsPainting(true);
#endif
    TRACE_EVENT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "Paint", "data", InspectorPaintEvent::data(m_owningLayer.renderer(), clip, graphicsLayer));
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline.stack"), "CallStack", TRACE_EVENT_SCOPE_PROCESS, "stack", InspectorCallStackEvent::currentCallStack());

    PaintLayerFlags paintLayerFlags = 0;
    if (graphicsLayerPaintingPhase & GraphicsLayerPaintBackground)
        paintLayerFlags |= PaintLayerPaintingCompositingBackgroundPhase;
    if (graphicsLayerPaintingPhase & GraphicsLayerPaintForeground)
        paintLayerFlags |= PaintLayerPaintingCompositingForegroundPhase;
    if (graphicsLayerPaintingPhase & GraphicsLayerPaintMask)
        paintLayerFlags |= PaintLayerPaintingCompositingMaskPhase;
    if (graphicsLayerPaintingPhase & GraphicsLayerPaintChildClippingMask)
        paintLayerFlags |= PaintLayerPaintingChildClippingMaskPhase;
    if (graphicsLayerPaintingPhase & GraphicsLayerPaintOverflowContents)
        paintLayerFlags |= PaintLayerPaintingOverflowContents;

    if (graphicsLayer == m_backgroundLayer)
        paintLayerFlags |= (PaintLayerPaintingRootBackgroundOnly | PaintLayerPaintingCompositingForegroundPhase); // Need PaintLayerPaintingCompositingForegroundPhase to walk child layers.
    else if (compositor()->fixedRootBackgroundLayer())
        paintLayerFlags |= PaintLayerPaintingSkipRootBackground;

    if (graphicsLayer == m_graphicsLayer.get()
        || graphicsLayer == m_foregroundLayer.get()
        || graphicsLayer == m_backgroundLayer.get()
        || graphicsLayer == m_maskLayer.get()
        || graphicsLayer == m_childClippingMaskLayer.get()) {

        GraphicsLayerPaintInfo paintInfo;
        paintInfo.renderLayer = &m_owningLayer;
        paintInfo.compositedBounds = compositedBounds();
        paintInfo.offsetFromRenderer = graphicsLayer->offsetFromRenderer();

        // We have to use the same root as for hit testing, because both methods can compute and cache clipRects.
        doPaintTask(paintInfo, paintLayerFlags, &context, clip);
    } else if (graphicsLayer == m_squashingLayer.get()) {
        ASSERT(compositor()->layerSquashingEnabled());
        for (size_t i = 0; i < m_squashedLayers.size(); ++i)
            doPaintTask(m_squashedLayers[i], paintLayerFlags, &context, clip);
    }
#if ENABLE(ASSERT)
    if (Page* page = renderer()->frame()->page())
        page->setIsPainting(false);
#endif
}

bool CompositedLayerMapping::isTrackingPaintInvalidations() const
{
    GraphicsLayerClient* client = compositor();
    return client ? client->isTrackingPaintInvalidations() : false;
}

#if ENABLE(ASSERT)
void CompositedLayerMapping::verifyNotPainting()
{
    ASSERT(!renderer()->frame()->page() || !renderer()->frame()->page()->isPainting());
}
#endif

void CompositedLayerMapping::notifyAnimationStarted(const GraphicsLayer*, double monotonicTime)
{
    renderer()->node()->document().compositorPendingAnimations().notifyCompositorAnimationStarted(monotonicTime);
}

IntRect CompositedLayerMapping::pixelSnappedCompositedBounds() const
{
    LayoutRect bounds = m_compositedBounds;
    bounds.move(m_owningLayer.subpixelAccumulation());
    return pixelSnappedIntRect(bounds);
}

bool CompositedLayerMapping::updateSquashingLayerAssignment(RenderLayer* squashedLayer, const RenderLayer& owningLayer, size_t nextSquashedLayerIndex)
{
    ASSERT(compositor()->layerSquashingEnabled());

    GraphicsLayerPaintInfo paintInfo;
    paintInfo.renderLayer = squashedLayer;
    // NOTE: composited bounds are updated elsewhere
    // NOTE: offsetFromRenderer is updated elsewhere

    // Change tracking on squashing layers: at the first sign of something changed, just invalidate the layer.
    // FIXME: Perhaps we can find a tighter more clever mechanism later.
    bool updatedAssignment = false;
    if (nextSquashedLayerIndex < m_squashedLayers.size()) {
        if (paintInfo.renderLayer != m_squashedLayers[nextSquashedLayerIndex].renderLayer) {
            compositor()->paintInvalidationOnCompositingChange(squashedLayer);
            updatedAssignment = true;
            m_squashedLayers[nextSquashedLayerIndex] = paintInfo;
        }
    } else {
        compositor()->paintInvalidationOnCompositingChange(squashedLayer);
        m_squashedLayers.append(paintInfo);
        updatedAssignment = true;
    }
    squashedLayer->setGroupedMapping(this);
    return updatedAssignment;
}

void CompositedLayerMapping::removeRenderLayerFromSquashingGraphicsLayer(const RenderLayer* layer)
{
    size_t layerIndex = kNotFound;

    for (size_t i = 0; i < m_squashedLayers.size(); ++i) {
        if (m_squashedLayers[i].renderLayer == layer) {
            layerIndex = i;
            break;
        }
    }

    if (layerIndex == kNotFound)
        return;

    m_squashedLayers.remove(layerIndex);
}

void CompositedLayerMapping::finishAccumulatingSquashingLayers(size_t nextSquashedLayerIndex)
{
    ASSERT(compositor()->layerSquashingEnabled());

    // Any additional squashed RenderLayers in the array no longer exist, and removing invalidates the squashingLayer contents.
    if (nextSquashedLayerIndex < m_squashedLayers.size())
        m_squashedLayers.remove(nextSquashedLayerIndex, m_squashedLayers.size() - nextSquashedLayerIndex);
}

String CompositedLayerMapping::debugName(const GraphicsLayer* graphicsLayer)
{
    String name;
    if (graphicsLayer == m_graphicsLayer.get()) {
        name = m_owningLayer.debugName();
    } else if (graphicsLayer == m_squashingContainmentLayer.get()) {
        name = "Squashing Containment Layer";
    } else if (graphicsLayer == m_squashingLayer.get()) {
        name = "Squashing Layer";
    } else if (graphicsLayer == m_ancestorClippingLayer.get()) {
        name = "Ancestor Clipping Layer";
    } else if (graphicsLayer == m_foregroundLayer.get()) {
        name = m_owningLayer.debugName() + " (foreground) Layer";
    } else if (graphicsLayer == m_backgroundLayer.get()) {
        name = m_owningLayer.debugName() + " (background) Layer";
    } else if (graphicsLayer == m_childContainmentLayer.get()) {
        name = "Child Containment Layer";
    } else if (graphicsLayer == m_childTransformLayer.get()) {
        name = "Child Transform Layer";
    } else if (graphicsLayer == m_maskLayer.get()) {
        name = "Mask Layer";
    } else if (graphicsLayer == m_childClippingMaskLayer.get()) {
        name = "Child Clipping Mask Layer";
    } else if (graphicsLayer == m_overflowControlsHostLayer.get()) {
        name = "Overflow Controls Host Layer";
    } else if (graphicsLayer == m_overflowControlsClippingLayer.get()) {
        name = "Overflow Controls ClipLayer Layer";
    } else {
        ASSERT_NOT_REACHED();
    }

    return name;
}

} // namespace blink
