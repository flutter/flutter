/*
 * Copyright (C) 2006, 2007, 2008, 2009, 2010, 2011, 2012 Apple Inc. All rights reserved.
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
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

#include "sky/engine/config.h"
#include "sky/engine/core/rendering/RenderLayer.h"

#include "gen/sky/core/CSSPropertyNames.h"
#include "gen/sky/platform/RuntimeEnabledFeatures.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/rendering/FilterEffectRenderer.h"
#include "sky/engine/core/rendering/HitTestRequest.h"
#include "sky/engine/core/rendering/HitTestResult.h"
#include "sky/engine/core/rendering/HitTestingTransformState.h"
#include "sky/engine/core/rendering/RenderGeometryMap.h"
#include "sky/engine/core/rendering/RenderInline.h"
#include "sky/engine/core/rendering/RenderTreeAsText.h"
#include "sky/engine/core/rendering/RenderView.h"
#include "sky/engine/platform/LengthFunctions.h"
#include "sky/engine/platform/Partitions.h"
#include "sky/engine/platform/TraceEvent.h"
#include "sky/engine/platform/geometry/FloatPoint3D.h"
#include "sky/engine/platform/geometry/FloatRect.h"
#include "sky/engine/platform/geometry/TransformState.h"
#include "sky/engine/platform/graphics/GraphicsContextStateSaver.h"
#include "sky/engine/platform/graphics/filters/ReferenceFilter.h"
#include "sky/engine/platform/graphics/filters/SourceGraphic.h"
#include "sky/engine/platform/transforms/ScaleTransformOperation.h"
#include "sky/engine/platform/transforms/TransformationMatrix.h"
#include "sky/engine/platform/transforms/TranslateTransformOperation.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/wtf/StdLibExtras.h"
#include "sky/engine/wtf/text/CString.h"

namespace blink {

RenderLayer::RenderLayer(RenderLayerModelObject* renderer, LayerType type)
    : m_layerType(type)
    , m_hasSelfPaintingLayerDescendant(false)
    , m_hasSelfPaintingLayerDescendantDirty(false)
    , m_isRootLayer(renderer->isRenderView())
    , m_usedTransparency(false)
    , m_3DTransformedDescendantStatusDirty(true)
    , m_has3DTransformedDescendant(false)
    , m_containsDirtyOverlayScrollbars(false)
    , m_hasFilterInfo(false)
    , m_needsAncestorDependentCompositingInputsUpdate(true)
    , m_needsDescendantDependentCompositingInputsUpdate(true)
    , m_childNeedsCompositingInputsUpdate(true)
    , m_hasCompositingDescendant(false)
    , m_lostGroupedMapping(false)
    , m_renderer(renderer)
    , m_parent(0)
    , m_previous(0)
    , m_next(0)
    , m_first(0)
    , m_last(0)
    , m_staticInlinePosition(0)
    , m_staticBlockPosition(0)
    , m_potentialCompositingReasonsFromStyle(CompositingReasonNone)
    , m_compositingReasons(CompositingReasonNone)
    , m_paintInvalidator(*renderer)
    , m_clipper(*renderer)
{
    updateStackingNode();

    m_isSelfPaintingLayer = shouldBeSelfPaintingLayer();

    updateScrollableArea();
}

RenderLayer::~RenderLayer()
{
    removeFilterInfoIfNeeded();
}

String RenderLayer::debugName() const
{
    return renderer()->debugName();
}

bool RenderLayer::paintsWithFilters() const
{
    // FIXME(sky): Remove
    return renderer()->hasFilter();
}

bool RenderLayer::requiresFullLayerImageForFilters() const
{
    if (!paintsWithFilters())
        return false;
    FilterEffectRenderer* filter = filterRenderer();
    return filter ? filter->hasFilterThatMovesPixels() : false;
}

LayoutSize RenderLayer::subpixelAccumulation() const
{
    return m_subpixelAccumulation;
}

void RenderLayer::setSubpixelAccumulation(const LayoutSize& size)
{
    m_subpixelAccumulation = size;
}

void RenderLayer::updateLayerPositionsAfterLayout()
{
    TRACE_EVENT0("blink", "RenderLayer::updateLayerPositionsAfterLayout");

    m_clipper.clearClipRectsIncludingDescendants();
}

void RenderLayer::updateHasSelfPaintingLayerDescendant() const
{
    ASSERT(m_hasSelfPaintingLayerDescendantDirty);

    m_hasSelfPaintingLayerDescendant = false;

    for (RenderLayer* child = firstChild(); child; child = child->nextSibling()) {
        if (child->isSelfPaintingLayer() || child->hasSelfPaintingLayerDescendant()) {
            m_hasSelfPaintingLayerDescendant = true;
            break;
        }
    }

    m_hasSelfPaintingLayerDescendantDirty = false;
}

void RenderLayer::dirtyAncestorChainHasSelfPaintingLayerDescendantStatus()
{
    for (RenderLayer* layer = this; layer; layer = layer->parent()) {
        layer->m_hasSelfPaintingLayerDescendantDirty = true;
        // If we have reached a self-painting layer, we know our parent should have a self-painting descendant
        // in this case, there is no need to dirty our ancestors further.
        if (layer->isSelfPaintingLayer()) {
            ASSERT(!parent() || parent()->m_hasSelfPaintingLayerDescendantDirty || parent()->m_hasSelfPaintingLayerDescendant);
            break;
        }
    }
}

bool RenderLayer::scrollsWithRespectTo(const RenderLayer* other) const
{
    return ancestorScrollingLayer() != other->ancestorScrollingLayer();
}

void RenderLayer::updateTransformationMatrix()
{
    if (m_transform) {
        RenderBox* box = renderBox();
        ASSERT(box);
        m_transform->makeIdentity();
        box->style()->applyTransform(*m_transform, box->pixelSnappedBorderBoxRect().size(), RenderStyle::IncludeTransformOrigin);
        makeMatrixRenderable(*m_transform);
    }
}

void RenderLayer::updateTransform(const RenderStyle* oldStyle, RenderStyle* newStyle)
{
    if (oldStyle && newStyle->transformDataEquivalent(*oldStyle))
        return;

    // hasTransform() on the renderer is also true when there is transform-style: preserve-3d or perspective set,
    // so check style too.
    bool hasTransform = renderer()->hasTransform() && newStyle->hasTransform();
    bool had3DTransform = has3DTransform();

    bool hadTransform = m_transform;
    if (hasTransform != hadTransform) {
        if (hasTransform)
            m_transform = adoptPtr(new TransformationMatrix);
        else
            m_transform.clear();

        // Layers with transforms act as clip rects roots, so clear the cached clip rects here.
        m_clipper.clearClipRectsIncludingDescendants();
    } else if (hasTransform) {
        m_clipper.clearClipRectsIncludingDescendants(AbsoluteClipRects);
    }

    updateTransformationMatrix();

    if (had3DTransform != has3DTransform())
        dirty3DTransformedDescendantStatus();
}

static RenderLayer* enclosingLayerForContainingBlock(RenderLayer* layer)
{
    if (RenderObject* containingBlock = layer->renderer()->containingBlock())
        return containingBlock->enclosingLayer();
    return 0;
}

RenderLayer* RenderLayer::renderingContextRoot()
{
    RenderLayer* renderingContext = 0;

    if (shouldPreserve3D())
        renderingContext = this;

    for (RenderLayer* current = enclosingLayerForContainingBlock(this); current && current->shouldPreserve3D(); current = enclosingLayerForContainingBlock(current))
        renderingContext = current;

    return renderingContext;
}

TransformationMatrix RenderLayer::currentTransform(RenderStyle::ApplyTransformOrigin applyOrigin) const
{
    if (!m_transform)
        return TransformationMatrix();

    // m_transform includes transform-origin, so we need to recompute the transform here.
    if (applyOrigin == RenderStyle::ExcludeTransformOrigin) {
        RenderBox* box = renderBox();
        TransformationMatrix currTransform;
        box->style()->applyTransform(currTransform, box->pixelSnappedBorderBoxRect().size(), RenderStyle::ExcludeTransformOrigin);
        makeMatrixRenderable(currTransform);
        return currTransform;
    }

    return *m_transform;
}

TransformationMatrix RenderLayer::renderableTransform() const
{
    return m_transform ? *m_transform : TransformationMatrix();
}

RenderLayer* RenderLayer::enclosingOverflowClipLayer(IncludeSelfOrNot includeSelf) const
{
    const RenderLayer* layer = (includeSelf == IncludeSelf) ? this : parent();
    while (layer) {
        if (layer->renderer()->hasOverflowClip())
            return const_cast<RenderLayer*>(layer);

        layer = layer->parent();
    }
    return 0;
}

LayoutPoint RenderLayer::positionFromPaintInvalidationContainer(const RenderObject* renderObject, const RenderLayerModelObject* paintInvalidationContainer, const PaintInvalidationState* paintInvalidationState)
{
    // FIXME(sky): Remove
    return renderObject->positionFromPaintInvalidationContainer(paintInvalidationContainer, paintInvalidationState);
}

void RenderLayer::mapRectToPaintInvalidationBacking(const RenderObject* renderObject, const RenderLayerModelObject* paintInvalidationContainer, LayoutRect& rect, const PaintInvalidationState* paintInvalidationState)
{
    // FIXME(sky): Remove
    renderObject->mapRectToPaintInvalidationBacking(paintInvalidationContainer, rect, paintInvalidationState);
}

LayoutRect RenderLayer::computePaintInvalidationRect(const RenderObject* renderObject, const RenderLayer* paintInvalidationContainer, const PaintInvalidationState* paintInvalidationState)
{
    // FIXME(sky): Remove
    return renderObject->computePaintInvalidationRect(paintInvalidationContainer->renderer(), paintInvalidationState);
}

void RenderLayer::dirty3DTransformedDescendantStatus()
{
    RenderLayerStackingNode* stackingNode = m_stackingNode->ancestorStackingContextNode();
    if (!stackingNode)
        return;

    stackingNode->layer()->m_3DTransformedDescendantStatusDirty = true;

    // This propagates up through preserve-3d hierarchies to the enclosing flattening layer.
    // Note that preserves3D() creates stacking context, so we can just run up the stacking containers.
    while (stackingNode && stackingNode->layer()->preserves3D()) {
        stackingNode->layer()->m_3DTransformedDescendantStatusDirty = true;
        stackingNode = stackingNode->ancestorStackingContextNode();
    }
}

// Return true if this layer or any preserve-3d descendants have 3d.
bool RenderLayer::update3DTransformedDescendantStatus()
{
    if (m_3DTransformedDescendantStatusDirty) {
        m_has3DTransformedDescendant = false;

        m_stackingNode->updateZOrderLists();

        // Transformed or preserve-3d descendants can only be in the z-order lists, not
        // in the normal flow list, so we only need to check those.
        RenderLayerStackingNodeIterator iterator(*m_stackingNode.get(), PositiveZOrderChildren | NegativeZOrderChildren);
        while (RenderLayerStackingNode* node = iterator.next())
            m_has3DTransformedDescendant |= node->layer()->update3DTransformedDescendantStatus();

        m_3DTransformedDescendantStatusDirty = false;
    }

    // If we live in a 3d hierarchy, then the layer at the root of that hierarchy needs
    // the m_has3DTransformedDescendant set.
    if (preserves3D())
        return has3DTransform() || m_has3DTransformedDescendant;

    return has3DTransform();
}

IntSize RenderLayer::size() const
{
    if (renderer()->isInline() && renderer()->isRenderInline())
        return toRenderInline(renderer())->linesBoundingBox().size();

    // FIXME: Is snapping the size really needed here?
    if (RenderBox* box = renderBox())
        return pixelSnappedIntSize(box->size(), box->location());

    return IntSize();
}

LayoutPoint RenderLayer::location() const
{
    LayoutPoint localPoint;
    LayoutSize inlineBoundingBoxOffset; // We don't put this into the RenderLayer x/y for inlines, so we need to subtract it out when done.

    if (renderer()->isInline() && renderer()->isRenderInline()) {
        RenderInline* inlineFlow = toRenderInline(renderer());
        IntRect lineBox = inlineFlow->linesBoundingBox();
        inlineBoundingBoxOffset = toSize(lineBox.location());
        localPoint += inlineBoundingBoxOffset;
    } else if (RenderBox* box = renderBox()) {
        localPoint += box->locationOffset();
    }

    if (!renderer()->isOutOfFlowPositioned() && renderer()->parent()) {
        // We must adjust our position by walking up the render tree looking for the
        // nearest enclosing object with a layer.
        RenderObject* curr = renderer()->parent();
        while (curr && !curr->hasLayer()) {
            if (curr->isBox()) {
                // Rows and cells share the same coordinate space (that of the section).
                // Omit them when computing our xpos/ypos.
                localPoint += toRenderBox(curr)->locationOffset();
            }
            curr = curr->parent();
        }
    }

    // Subtract our parent's scroll offset.
    if (renderer()->isOutOfFlowPositioned() && enclosingPositionedAncestor()) {
        RenderLayer* positionedParent = enclosingPositionedAncestor();

        // For positioned layers, we subtract out the enclosing positioned layer's scroll offset.
        if (positionedParent->renderer()->hasOverflowClip()) {
            LayoutSize offset = positionedParent->renderBox()->scrolledContentOffset();
            localPoint -= offset;
        }

        if (positionedParent->renderer()->isRelPositioned() && positionedParent->renderer()->isRenderInline()) {
            LayoutSize offset = toRenderInline(positionedParent->renderer())->offsetForInFlowPositionedInline(*toRenderBox(renderer()));
            localPoint += offset;
        }
    } else if (parent()) {
        if (parent()->renderer()->hasOverflowClip()) {
            IntSize scrollOffset = parent()->renderBox()->scrolledContentOffset();
            localPoint -= scrollOffset;
        }
    }

    localPoint.move(offsetForInFlowPosition());

    // FIXME: We'd really like to just get rid of the concept of a layer rectangle and rely on the renderers.
    localPoint -= inlineBoundingBoxOffset;

    return localPoint;
}

const LayoutSize RenderLayer::offsetForInFlowPosition() const
{
    return renderer()->isRelPositioned() ? toRenderBoxModelObject(renderer())->offsetForInFlowPosition() : LayoutSize();
}

TransformationMatrix RenderLayer::perspectiveTransform() const
{
    if (!renderer()->hasTransform())
        return TransformationMatrix();

    RenderStyle* style = renderer()->style();
    if (!style->hasPerspective())
        return TransformationMatrix();

    // Maybe fetch the perspective from the backing?
    const IntRect borderBox = toRenderBox(renderer())->pixelSnappedBorderBoxRect();
    const float boxWidth = borderBox.width();
    const float boxHeight = borderBox.height();

    float perspectiveOriginX = floatValueForLength(style->perspectiveOriginX(), boxWidth);
    float perspectiveOriginY = floatValueForLength(style->perspectiveOriginY(), boxHeight);

    // A perspective origin of 0,0 makes the vanishing point in the center of the element.
    // We want it to be in the top-left, so subtract half the height and width.
    perspectiveOriginX -= boxWidth / 2.0f;
    perspectiveOriginY -= boxHeight / 2.0f;

    TransformationMatrix t;
    t.translate(perspectiveOriginX, perspectiveOriginY);
    t.applyPerspective(style->perspective());
    t.translate(-perspectiveOriginX, -perspectiveOriginY);

    return t;
}

FloatPoint RenderLayer::perspectiveOrigin() const
{
    if (!renderer()->hasTransform())
        return FloatPoint();

    const LayoutRect borderBox = toRenderBox(renderer())->borderBoxRect();
    RenderStyle* style = renderer()->style();

    return FloatPoint(floatValueForLength(style->perspectiveOriginX(), borderBox.width().toFloat()), floatValueForLength(style->perspectiveOriginY(), borderBox.height().toFloat()));
}

RenderLayer* RenderLayer::enclosingPositionedAncestor() const
{
    RenderLayer* curr = parent();
    while (curr && !curr->isPositionedContainer())
        curr = curr->parent();

    return curr;
}

RenderLayer* RenderLayer::enclosingTransformedAncestor() const
{
    RenderLayer* curr = parent();
    while (curr && !curr->isRootLayer() && !curr->renderer()->hasTransform())
        curr = curr->parent();

    return curr;
}

LayoutPoint RenderLayer::computeOffsetFromTransformedAncestor() const
{
    const AncestorDependentCompositingInputs& properties = ancestorDependentCompositingInputs();

    TransformState transformState(TransformState::ApplyTransformDirection, FloatPoint());
    // FIXME: add a test that checks flipped writing mode and ApplyContainerFlip are correct.
    renderer()->mapLocalToContainer(properties.transformAncestor ? properties.transformAncestor->renderer() : 0, transformState, ApplyContainerFlip);
    transformState.flatten();
    return LayoutPoint(transformState.lastPlanarPoint());
}

const RenderLayer* RenderLayer::compositingContainer() const
{
    if (stackingNode()->isNormalFlowOnly())
        return parent();
    if (RenderLayerStackingNode* ancestorStackingNode = stackingNode()->ancestorStackingContextNode())
        return ancestorStackingNode->layer();
    return 0;
}

RenderLayer* RenderLayer::enclosingFilterLayer(IncludeSelfOrNot includeSelf) const
{
    const RenderLayer* curr = (includeSelf == IncludeSelf) ? this : parent();
    for (; curr; curr = curr->parent()) {
        if (curr->requiresFullLayerImageForFilters())
            return const_cast<RenderLayer*>(curr);
    }

    return 0;
}

void RenderLayer::updateAncestorDependentCompositingInputs(const AncestorDependentCompositingInputs& compositingInputs)
{
    m_ancestorDependentCompositingInputs = compositingInputs;
    m_needsAncestorDependentCompositingInputsUpdate = false;
}

void RenderLayer::updateDescendantDependentCompositingInputs(const DescendantDependentCompositingInputs& compositingInputs)
{
    m_descendantDependentCompositingInputs = compositingInputs;
    m_needsDescendantDependentCompositingInputsUpdate = false;
}

void RenderLayer::setCompositingReasons(CompositingReasons reasons, CompositingReasons mask)
{
    if ((compositingReasons() & mask) == (reasons & mask))
        return;
    m_compositingReasons = (reasons & mask) | (compositingReasons() & ~mask);
}

void RenderLayer::setHasCompositingDescendant(bool hasCompositingDescendant)
{
    // FIXME(sky): Remove
    m_hasCompositingDescendant = hasCompositingDescendant;
}


bool RenderLayer::hasAncestorWithFilterOutsets() const
{
    for (const RenderLayer* curr = this; curr; curr = curr->parent()) {
        RenderLayerModelObject* renderer = curr->renderer();
        if (renderer->style()->hasFilterOutsets())
            return true;
    }
    return false;
}

RenderLayer* RenderLayer::transparentPaintingAncestor()
{
    for (RenderLayer* curr = parent(); curr; curr = curr->parent()) {
        if (curr->isTransparent())
            return curr;
    }
    return 0;
}

enum TransparencyClipBoxBehavior {
    PaintingTransparencyClipBox,
    HitTestingTransparencyClipBox
};

enum TransparencyClipBoxMode {
    DescendantsOfTransparencyClipBox,
    RootOfTransparencyClipBox
};

static LayoutRect transparencyClipBox(const RenderLayer*, const RenderLayer* rootLayer, TransparencyClipBoxBehavior, TransparencyClipBoxMode, const LayoutSize& subPixelAccumulation);

static void expandClipRectForDescendantsAndReflection(LayoutRect& clipRect, const RenderLayer* layer, const RenderLayer* rootLayer,
    TransparencyClipBoxBehavior transparencyBehavior, const LayoutSize& subPixelAccumulation)
{
    // If we have a mask, then the clip is limited to the border box area (and there is
    // no need to examine child layers).
    if (!layer->renderer()->hasMask()) {
        // Note: we don't have to walk z-order lists since transparent elements always establish
        // a stacking container. This means we can just walk the layer tree directly.
        for (RenderLayer* curr = layer->firstChild(); curr; curr = curr->nextSibling())
            clipRect.unite(transparencyClipBox(curr, rootLayer, transparencyBehavior, DescendantsOfTransparencyClipBox, subPixelAccumulation));
    }
}

static LayoutRect transparencyClipBox(const RenderLayer* layer, const RenderLayer* rootLayer, TransparencyClipBoxBehavior transparencyBehavior,
    TransparencyClipBoxMode transparencyMode, const LayoutSize& subPixelAccumulation)
{
    // FIXME: Although this function completely ignores CSS-imposed clipping, we did already intersect with the
    // paintDirtyRect, and that should cut down on the amount we have to paint.  Still it
    // would be better to respect clips.

    if (rootLayer != layer && ((transparencyBehavior == PaintingTransparencyClipBox && layer->paintsWithTransform())
        || (transparencyBehavior == HitTestingTransparencyClipBox && layer->hasTransform()))) {
        // The best we can do here is to use enclosed bounding boxes to establish a "fuzzy" enough clip to encompass
        // the transformed layer and all of its children.
        const RenderLayer* rootLayerForTransform = rootLayer;
        LayoutPoint delta;
        layer->convertToLayerCoords(rootLayerForTransform, delta);

        delta.move(subPixelAccumulation);
        IntPoint pixelSnappedDelta = roundedIntPoint(delta);
        TransformationMatrix transform;
        transform.translate(pixelSnappedDelta.x(), pixelSnappedDelta.y());
        transform = transform * *layer->transform();

        // We don't use fragment boxes when collecting a transformed layer's bounding box, since it always
        // paints unfragmented.
        LayoutRect clipRect = layer->physicalBoundingBox(layer);
        expandClipRectForDescendantsAndReflection(clipRect, layer, layer, transparencyBehavior, subPixelAccumulation);
        layer->renderer()->style()->filterOutsets().expandRect(clipRect);
        LayoutRect result = transform.mapRect(clipRect);
        return result;
    }

    LayoutRect clipRect = layer->physicalBoundingBox(rootLayer);
    expandClipRectForDescendantsAndReflection(clipRect, layer, rootLayer, transparencyBehavior, subPixelAccumulation);
    layer->renderer()->style()->filterOutsets().expandRect(clipRect);
    clipRect.move(subPixelAccumulation);
    return clipRect;
}

LayoutRect RenderLayer::paintingExtent(const RenderLayer* rootLayer, const LayoutRect& paintDirtyRect, const LayoutSize& subPixelAccumulation)
{
    return intersection(transparencyClipBox(this, rootLayer, PaintingTransparencyClipBox, RootOfTransparencyClipBox, subPixelAccumulation), paintDirtyRect);
}

void RenderLayer::beginTransparencyLayers(GraphicsContext* context, const RenderLayer* rootLayer, const LayoutRect& paintDirtyRect, const LayoutSize& subPixelAccumulation)
{
    if (isTransparent() && m_usedTransparency)
        return;

    RenderLayer* ancestor = transparentPaintingAncestor();
    if (ancestor)
        ancestor->beginTransparencyLayers(context, rootLayer, paintDirtyRect, subPixelAccumulation);

    if (isTransparent()) {
        m_usedTransparency = true;
        context->save();
        LayoutRect clipRect = paintingExtent(rootLayer, paintDirtyRect, subPixelAccumulation);
        context->clip(clipRect);

        context->beginTransparencyLayer(renderer()->opacity());

#ifdef REVEAL_TRANSPARENCY_LAYERS
        context->setFillColor(Color(0.0f, 0.0f, 0.5f, 0.2f));
        context->fillRect(clipRect);
#endif
    }
}

void* RenderLayer::operator new(size_t sz)
{
    return partitionAlloc(Partitions::getRenderingPartition(), sz);
}

void RenderLayer::operator delete(void* ptr)
{
    partitionFree(ptr);
}

void RenderLayer::addChild(RenderLayer* child, RenderLayer* beforeChild)
{
    RenderLayer* prevSibling = beforeChild ? beforeChild->previousSibling() : lastChild();
    if (prevSibling) {
        child->setPreviousSibling(prevSibling);
        prevSibling->setNextSibling(child);
        ASSERT(prevSibling != child);
    } else
        setFirstChild(child);

    if (beforeChild) {
        beforeChild->setPreviousSibling(child);
        child->setNextSibling(beforeChild);
        ASSERT(beforeChild != child);
    } else
        setLastChild(child);

    child->m_parent = this;

    if (child->stackingNode()->isNormalFlowOnly())
        m_stackingNode->dirtyNormalFlowList();

    if (!child->stackingNode()->isNormalFlowOnly() || child->firstChild()) {
        // Dirty the z-order list in which we are contained. The ancestorStackingContextNode() can be null in the
        // case where we're building up generated content layers. This is ok, since the lists will start
        // off dirty in that case anyway.
        child->stackingNode()->dirtyStackingContextZOrderLists();
    }

    dirtyAncestorChainHasSelfPaintingLayerDescendantStatus();
}

RenderLayer* RenderLayer::removeChild(RenderLayer* oldChild)
{
    if (oldChild->previousSibling())
        oldChild->previousSibling()->setNextSibling(oldChild->nextSibling());
    if (oldChild->nextSibling())
        oldChild->nextSibling()->setPreviousSibling(oldChild->previousSibling());

    if (m_first == oldChild)
        m_first = oldChild->nextSibling();
    if (m_last == oldChild)
        m_last = oldChild->previousSibling();

    if (oldChild->stackingNode()->isNormalFlowOnly())
        m_stackingNode->dirtyNormalFlowList();
    if (!oldChild->stackingNode()->isNormalFlowOnly() || oldChild->firstChild()) {
        // Dirty the z-order list in which we are contained.  When called via the
        // reattachment process in removeOnlyThisLayer, the layer may already be disconnected
        // from the main layer tree, so we need to null-check the
        // |stackingContext| value.
        oldChild->stackingNode()->dirtyStackingContextZOrderLists();
    }

    oldChild->setPreviousSibling(0);
    oldChild->setNextSibling(0);
    oldChild->m_parent = 0;

    dirtyAncestorChainHasSelfPaintingLayerDescendantStatus();

    return oldChild;
}

void RenderLayer::removeOnlyThisLayer()
{
    if (!m_parent)
        return;

    m_clipper.clearClipRectsIncludingDescendants();

    paintInvalidator().paintInvalidationIncludingNonCompositingDescendants();

    RenderLayer* nextSib = nextSibling();

    // Now walk our kids and reattach them to our parent.
    RenderLayer* current = m_first;
    while (current) {
        RenderLayer* next = current->nextSibling();
        removeChild(current);
        m_parent->addChild(current, nextSib);

        current->renderer()->setShouldDoFullPaintInvalidation(true);
        // FIXME: We should call a specialized version of this function.
        current->updateLayerPositionsAfterLayout();
        current = next;
    }

    // Remove us from the parent.
    m_parent->removeChild(this);
    m_renderer->destroyLayer();
}

void RenderLayer::insertOnlyThisLayer()
{
    if (!m_parent && renderer()->parent()) {
        // We need to connect ourselves when our renderer() has a parent.
        // Find our enclosingLayer and add ourselves.
        RenderLayer* parentLayer = renderer()->parent()->enclosingLayer();
        ASSERT(parentLayer);
        RenderLayer* beforeChild = renderer()->parent()->findNextLayer(parentLayer, renderer());
        parentLayer->addChild(this, beforeChild);
    }

    // Remove all descendant layers from the hierarchy and add them to the new position.
    for (RenderObject* curr = renderer()->slowFirstChild(); curr; curr = curr->nextSibling())
        curr->moveLayers(m_parent, this);

    // Clear out all the clip rects.
    m_clipper.clearClipRectsIncludingDescendants();
}

// Returns the layer reached on the walk up towards the ancestor.
static inline const RenderLayer* accumulateOffsetTowardsAncestor(const RenderLayer* layer, const RenderLayer* ancestorLayer, LayoutPoint& location)
{
    ASSERT(ancestorLayer != layer);

    const RenderLayerModelObject* renderer = layer->renderer();
    EPosition position = renderer->style()->position();

    RenderLayer* parentLayer;
    if (position == AbsolutePosition) {
        // Do what enclosingPositionedAncestor() does, but check for ancestorLayer along the way.
        parentLayer = layer->parent();
        bool foundAncestorFirst = false;
        while (parentLayer) {
            // RenderFlowThread is a positioned container, child of RenderView, positioned at (0,0).
            // This implies that, for out-of-flow positioned elements inside a RenderFlowThread,
            // we are bailing out before reaching root layer.
            if (parentLayer->isPositionedContainer())
                break;

            if (parentLayer == ancestorLayer) {
                foundAncestorFirst = true;
                break;
            }

            parentLayer = parentLayer->parent();
        }

        if (foundAncestorFirst) {
            // Found ancestorLayer before the abs. positioned container, so compute offset of both relative
            // to enclosingPositionedAncestor and subtract.
            RenderLayer* positionedAncestor = parentLayer->enclosingPositionedAncestor();

            LayoutPoint thisCoords;
            layer->convertToLayerCoords(positionedAncestor, thisCoords);

            LayoutPoint ancestorCoords;
            ancestorLayer->convertToLayerCoords(positionedAncestor, ancestorCoords);

            location += (thisCoords - ancestorCoords);
            return ancestorLayer;
        }
    } else
        parentLayer = layer->parent();

    if (!parentLayer)
        return 0;

    location += toSize(layer->location());
    return parentLayer;
}

void RenderLayer::convertToLayerCoords(const RenderLayer* ancestorLayer, LayoutPoint& location) const
{
    if (ancestorLayer == this)
        return;

    const RenderLayer* currLayer = this;
    while (currLayer && currLayer != ancestorLayer)
        currLayer = accumulateOffsetTowardsAncestor(currLayer, ancestorLayer, location);
}

void RenderLayer::convertToLayerCoords(const RenderLayer* ancestorLayer, LayoutRect& rect) const
{
    LayoutPoint delta;
    convertToLayerCoords(ancestorLayer, delta);
    rect.move(-delta.x(), -delta.y());
}

void RenderLayer::didUpdateNeedsCompositedScrolling()
{
    updateSelfPaintingLayer();
}

void RenderLayer::updateStackingNode()
{
    if (requiresStackingNode())
        m_stackingNode = adoptPtr(new RenderLayerStackingNode(this));
    else
        m_stackingNode = nullptr;
}

void RenderLayer::updateScrollableArea()
{
    if (requiresScrollableArea())
        m_scrollableArea = adoptPtr(new RenderLayerScrollableArea(*this));
    else
        m_scrollableArea = nullptr;
}

bool RenderLayer::hasOverflowControls() const
{
    return m_scrollableArea && m_scrollableArea->hasScrollbar();
}

void RenderLayer::paint(GraphicsContext* context, const LayoutRect& damageRect, RenderObject* paintingRoot)
{
    LayerPaintingInfo paintingInfo(this, enclosingIntRect(damageRect), LayoutSize(), paintingRoot);
    paintLayer(context, paintingInfo, PaintContent);
}

void RenderLayer::paintOverlayScrollbars(GraphicsContext* context, const LayoutRect& damageRect, RenderObject* paintingRoot)
{
    if (!m_containsDirtyOverlayScrollbars)
        return;

    LayerPaintingInfo paintingInfo(this, enclosingIntRect(damageRect), LayoutSize(), paintingRoot);
    paintLayer(context, paintingInfo, PaintOverlayScrollbars);

    m_containsDirtyOverlayScrollbars = false;
}

static bool inContainingBlockChain(RenderLayer* startLayer, RenderLayer* endLayer)
{
    if (startLayer == endLayer)
        return true;

    RenderView* view = startLayer->renderer()->view();
    for (RenderBlock* currentBlock = startLayer->renderer()->containingBlock(); currentBlock && currentBlock != view; currentBlock = currentBlock->containingBlock()) {
        if (currentBlock->layer() == endLayer)
            return true;
    }

    return false;
}

void RenderLayer::clipToRect(const LayerPaintingInfo& localPaintingInfo, GraphicsContext* context, const ClipRect& clipRect,
    BorderRadiusClippingRule rule)
{
    if (clipRect.rect() == localPaintingInfo.paintDirtyRect && !clipRect.hasRadius())
        return;
    context->save();
    context->clip(pixelSnappedIntRect(clipRect.rect()));

    if (!clipRect.hasRadius())
        return;

    // If the clip rect has been tainted by a border radius, then we have to walk up our layer chain applying the clips from
    // any layers with overflow. The condition for being able to apply these clips is that the overflow object be in our
    // containing block chain so we check that also.
    for (RenderLayer* layer = rule == IncludeSelfForBorderRadius ? this : parent(); layer; layer = layer->parent()) {
        // Composited scrolling layers handle border-radius clip in the compositor via a mask layer. We do not
        // want to apply a border-radius clip to the layer contents itself, because that would require re-rastering
        // every frame to update the clip. We only want to make sure that the mask layer is properly clipped so
        // that it can in turn clip the scrolled contents in the compositor.
        if (layer->needsCompositedScrolling())
            break;

        if (layer->renderer()->hasOverflowClip() && layer->renderer()->style()->hasBorderRadius() && inContainingBlockChain(this, layer)) {
                LayoutPoint delta;
                layer->convertToLayerCoords(localPaintingInfo.rootLayer, delta);
                context->clipRoundedRect(layer->renderer()->style()->getRoundedInnerBorderFor(LayoutRect(delta, layer->size())));
        }

        if (layer == localPaintingInfo.rootLayer)
            break;
    }
}

void RenderLayer::restoreClip(GraphicsContext* context, const LayoutRect& paintDirtyRect, const ClipRect& clipRect)
{
    if (clipRect.rect() == paintDirtyRect && !clipRect.hasRadius())
        return;
    context->restore();
}

static inline bool shouldSuppressPaintingLayer(RenderLayer* layer)
{
    // Avoid painting descendants of the root layer when stylesheets haven't loaded. This eliminates FOUC.
    // It's ok not to draw, because later on, when all the stylesheets do load, updateStyleSelector on the Document
    // will do a full paintInvalidationForWholeRenderer().
    if (layer->renderer()->document().didLayoutWithPendingStylesheets() && !layer->isRootLayer() && !layer->renderer()->isDocumentElement())
        return true;

    return false;
}

void RenderLayer::paintLayer(GraphicsContext* context, const LayerPaintingInfo& paintingInfo, PaintLayerFlags paintFlags)
{
    // Non self-painting leaf layers don't need to be painted as their renderer() should properly paint itself.
    if (!isSelfPaintingLayer() && !hasSelfPaintingLayerDescendant())
        return;

    if (shouldSuppressPaintingLayer(this))
        return;

    // If this layer is totally invisible then there is nothing to paint.
    if (!renderer()->opacity())
        return;

    if (paintsWithTransform()) {
        TransformationMatrix layerTransform = renderableTransform();
        // If the transform can't be inverted, then don't paint anything.
        if (!layerTransform.isInvertible())
            return;

        // If we have a transparency layer enclosing us and we are the root of a transform, then we need to establish the transparency
        // layer from the parent now, assuming there is a parent
        if (isTransparent()) {
            if (parent())
                parent()->beginTransparencyLayers(context, paintingInfo.rootLayer, paintingInfo.paintDirtyRect, paintingInfo.subPixelAccumulation);
            else
                beginTransparencyLayers(context, paintingInfo.rootLayer, paintingInfo.paintDirtyRect, paintingInfo.subPixelAccumulation);
        }

        // Make sure the parent's clip rects have been calculated.
        ClipRect clipRect = paintingInfo.paintDirtyRect;
        if (parent()) {
            ClipRectsContext clipRectsContext(paintingInfo.rootLayer, PaintingClipRects);
            clipRect = clipper().backgroundClipRect(clipRectsContext);
            clipRect.intersect(paintingInfo.paintDirtyRect);

            // Push the parent coordinate space's clip.
            parent()->clipToRect(paintingInfo, context, clipRect);
        }

        paintLayerByApplyingTransform(context, paintingInfo, paintFlags);

        // Restore the clip.
        if (parent())
            parent()->restoreClip(context, paintingInfo.paintDirtyRect, clipRect);

        return;
    }

    paintLayerContents(context, paintingInfo, paintFlags);
}

void RenderLayer::paintLayerContents(GraphicsContext* context, const LayerPaintingInfo& paintingInfo, PaintLayerFlags paintFlags)
{
    ASSERT(isSelfPaintingLayer() || hasSelfPaintingLayerDescendant());

    float deviceScaleFactor = blink::deviceScaleFactor(renderer()->frame());
    context->setDeviceScaleFactor(deviceScaleFactor);

    GraphicsContext* transparencyLayerContext = context;

    m_stackingNode->updateLayerListsIfNeeded();

    LayoutPoint offsetFromRoot;
    convertToLayerCoords(paintingInfo.rootLayer, offsetFromRoot);

    LayoutRect rootRelativeBounds;
    bool rootRelativeBoundsComputed = false;

    // Apply clip-path to context.
    GraphicsContextStateSaver clipStateSaver(*context, false);
    RenderStyle* style = renderer()->style();

    // Clip-path, like border radius, must not be applied to the contents of a composited-scrolling container.
    // It must, however, still be applied to the mask layer, so that the compositor can properly mask the
    // scrolling contents and scrollbars.
    if (renderer()->hasClipPath() && style && !needsCompositedScrolling()) {
        ASSERT(style->clipPath());
        if (style->clipPath()->type() == ClipPathOperation::SHAPE) {
            ShapeClipPathOperation* clipPath = toShapeClipPathOperation(style->clipPath());
            if (clipPath->isValid()) {
                clipStateSaver.save();

                if (!rootRelativeBoundsComputed) {
                    rootRelativeBounds = physicalBoundingBoxIncludingReflectionAndStackingChildren(paintingInfo.rootLayer, offsetFromRoot);
                    rootRelativeBoundsComputed = true;
                }

                context->clipPath(clipPath->path(rootRelativeBounds), clipPath->windRule());
            }
        }
    }

    LayerPaintingInfo localPaintingInfo(paintingInfo);
    bool deferredFiltersEnabled = renderer()->document().settings()->deferredFiltersEnabled();
    FilterEffectRendererHelper filterPainter(filterRenderer() && paintsWithFilters());

    // FIXME(sky): There's only one fragment. Get rid of the vector.
    LayerFragments layerFragments;
    LayerFragment fragment;
    ClipRectsContext clipRectsContext(localPaintingInfo.rootLayer, PaintingClipRects, localPaintingInfo.subPixelAccumulation);
    clipper().calculateRects(clipRectsContext, localPaintingInfo.paintDirtyRect,
        fragment.layerBounds, fragment.backgroundRect, fragment.foregroundRect, fragment.outlineRect,
        &offsetFromRoot);
    layerFragments.append(fragment);

    bool isPaintingOverlayScrollbars = paintFlags == PaintOverlayScrollbars;
    bool shouldPaintContent = isSelfPaintingLayer() && !isPaintingOverlayScrollbars;
    updatePaintingInfoForFragments(layerFragments, localPaintingInfo, shouldPaintContent, &offsetFromRoot);

    bool haveTransparency = isTransparent();

    if (filterPainter.haveFilterEffect()) {
        ASSERT(this->filterInfo());

        if (!rootRelativeBoundsComputed)
            rootRelativeBounds = physicalBoundingBoxIncludingReflectionAndStackingChildren(paintingInfo.rootLayer, offsetFromRoot);

        if (filterPainter.prepareFilterEffect(this, rootRelativeBounds, paintingInfo.paintDirtyRect)) {

            // Rewire the old context to a memory buffer, so that we can capture the contents of the layer.
            // NOTE: We saved the old context in the "transparencyLayerContext" local variable, to be able to start a transparency layer
            // on the original context and avoid duplicating "beginFilterEffect" after each transparency layer call. Also, note that
            // beginTransparencyLayers will only create a single lazy transparency layer, even though it is called twice in this method.
            // With deferred filters, we don't need a separate context, but we do need to do transparency and clipping before starting
            // filter processing.
            // FIXME: when the legacy path is removed, remove the transparencyLayerContext as well.
            if (deferredFiltersEnabled) {
                if (haveTransparency) {
                    // If we have a filter and transparency, we have to eagerly start a transparency layer here, rather than risk a child layer lazily starts one after filter processing.
                    beginTransparencyLayers(context, localPaintingInfo.rootLayer, paintingInfo.paintDirtyRect, paintingInfo.subPixelAccumulation);
                }
                // We'll handle clipping to the dirty rect before filter rasterization.
                // Filter processing will automatically expand the clip rect and the offscreen to accommodate any filter outsets.
                // FIXME: It is incorrect to just clip to the damageRect here once multiple fragments are involved.
                ClipRect backgroundRect = fragment.backgroundRect;
                clipToRect(localPaintingInfo, context, backgroundRect);
                // Subsequent code should not clip to the dirty rect, since we've already
                // done it above, and doing it later will defeat the outsets.
                localPaintingInfo.clipToDirtyRect = false;
            }
            context = filterPainter.beginFilterEffect(context);

            // Check that we didn't fail to allocate the graphics context for the offscreen buffer.
            if (filterPainter.hasStartedFilterEffect() && !deferredFiltersEnabled) {
                localPaintingInfo.paintDirtyRect = filterPainter.paintInvalidationRect();
                // If the filter needs the full source image, we need to avoid using the clip rectangles.
                // Otherwise, if for example this layer has overflow:hidden, a drop shadow will not compute correctly.
                // Note that we will still apply the clipping on the final rendering of the filter.
                localPaintingInfo.clipToDirtyRect = !filterRenderer()->hasFilterThatMovesPixels();
            }
        }
    }

    if (filterPainter.hasStartedFilterEffect() && haveTransparency && !deferredFiltersEnabled) {
        // If we have a filter and transparency, we have to eagerly start a transparency layer here, rather than risk a child layer lazily starts one with the wrong context.
        beginTransparencyLayers(transparencyLayerContext, localPaintingInfo.rootLayer, paintingInfo.paintDirtyRect, paintingInfo.subPixelAccumulation);
    }

    // If this layer's renderer is a child of the paintingRoot, we render unconditionally, which
    // is done by passing a nil paintingRoot down to our renderer (as if no paintingRoot was ever set).
    // Else, our renderer tree may or may not contain the painting root, so we pass that root along
    // so it will be tested against as we descend through the renderers.
    RenderObject* paintingRootForRenderer = 0;
    if (localPaintingInfo.paintingRoot && !renderer()->isDescendantOf(localPaintingInfo.paintingRoot))
        paintingRootForRenderer = localPaintingInfo.paintingRoot;

    if (shouldPaintContent) {
        paintBackgroundForFragments(layerFragments, context, transparencyLayerContext, paintingInfo.paintDirtyRect, haveTransparency,
            localPaintingInfo, paintingRootForRenderer);
    }

    paintChildren(NegativeZOrderChildren, context, paintingInfo, paintFlags);

    if (shouldPaintContent) {
        paintForegroundForFragments(layerFragments, context, transparencyLayerContext, paintingInfo.paintDirtyRect, haveTransparency,
            localPaintingInfo, paintingRootForRenderer);
    }

    paintOutlineForFragments(layerFragments, context, localPaintingInfo, paintingRootForRenderer);
    paintChildren(NormalFlowChildren | PositiveZOrderChildren, context, paintingInfo, paintFlags);

    if (isPaintingOverlayScrollbars)
        paintOverflowControlsForFragments(layerFragments, context, localPaintingInfo);

    if (filterPainter.hasStartedFilterEffect()) {
        // Apply the correct clipping (ie. overflow: hidden).
        // FIXME: It is incorrect to just clip to the damageRect here once multiple fragments are involved.
        ClipRect backgroundRect = fragment.backgroundRect;
        if (!deferredFiltersEnabled)
            clipToRect(localPaintingInfo, transparencyLayerContext, backgroundRect);

        context = filterPainter.applyFilterEffect();
        restoreClip(transparencyLayerContext, localPaintingInfo.paintDirtyRect, backgroundRect);
    }

    // Make sure that we now use the original transparency context.
    ASSERT(transparencyLayerContext == context);

    if (shouldPaintContent && renderer()->hasMask())
        paintMaskForFragments(layerFragments, context, localPaintingInfo, paintingRootForRenderer);

    // End our transparency layer
    if (haveTransparency && m_usedTransparency) {
        context->endLayer();
        context->restore();
        m_usedTransparency = false;
    }
}

void RenderLayer::paintLayerByApplyingTransform(GraphicsContext* context, const LayerPaintingInfo& paintingInfo, PaintLayerFlags paintFlags, const LayoutPoint& translationOffset)
{
    // This involves subtracting out the position of the layer in our current coordinate space, but preserving
    // the accumulated error for sub-pixel layout.
    LayoutPoint delta;
    convertToLayerCoords(paintingInfo.rootLayer, delta);
    delta.moveBy(translationOffset);
    TransformationMatrix transform(renderableTransform());
    IntPoint roundedDelta = roundedIntPoint(delta);
    transform.translateRight(roundedDelta.x(), roundedDelta.y());
    LayoutSize adjustedSubPixelAccumulation = paintingInfo.subPixelAccumulation + (delta - roundedDelta);

    // Apply the transform.
    GraphicsContextStateSaver stateSaver(*context, false);
    if (!transform.isIdentity()) {
        stateSaver.save();
        context->concatCTM(transform.toAffineTransform());
    }

    // Now do a paint with the root layer shifted to be us.
    LayerPaintingInfo transformedPaintingInfo(this, enclosingIntRect(transform.inverse().mapRect(paintingInfo.paintDirtyRect)),
        adjustedSubPixelAccumulation, paintingInfo.paintingRoot);
    paintLayerContents(context, transformedPaintingInfo, paintFlags);
}

void RenderLayer::paintChildren(unsigned childrenToVisit, GraphicsContext* context, const LayerPaintingInfo& paintingInfo, PaintLayerFlags paintFlags)
{
    if (!hasSelfPaintingLayerDescendant())
        return;

#if ENABLE(ASSERT)
    LayerListMutationDetector mutationChecker(m_stackingNode.get());
#endif

    RenderLayerStackingNodeIterator iterator(*m_stackingNode, childrenToVisit);
    while (RenderLayerStackingNode* child = iterator.next()) {
        child->layer()->paintLayer(context, paintingInfo, paintFlags);
    }
}

void RenderLayer::updatePaintingInfoForFragments(LayerFragments& fragments, const LayerPaintingInfo& localPaintingInfo,
    bool shouldPaintContent, const LayoutPoint* offsetFromRoot)
{
    ASSERT(offsetFromRoot);
    for (size_t i = 0; i < fragments.size(); ++i) {
        LayerFragment& fragment = fragments.at(i);
        LayoutPoint newOffsetFromRoot = *offsetFromRoot;
        fragment.shouldPaintContent = shouldPaintContent && intersectsDamageRect(fragment.layerBounds, fragment.backgroundRect.rect(), localPaintingInfo.rootLayer, &newOffsetFromRoot);
    }
}

void RenderLayer::paintBackgroundForFragments(const LayerFragments& layerFragments, GraphicsContext* context, GraphicsContext* transparencyLayerContext,
    const LayoutRect& transparencyPaintDirtyRect, bool haveTransparency, const LayerPaintingInfo& localPaintingInfo,
    RenderObject* paintingRootForRenderer)
{
    for (size_t i = 0; i < layerFragments.size(); ++i) {
        const LayerFragment& fragment = layerFragments.at(i);
        if (!fragment.shouldPaintContent)
            continue;

        // Begin transparency layers lazily now that we know we have to paint something.
        if (haveTransparency)
            beginTransparencyLayers(transparencyLayerContext, localPaintingInfo.rootLayer, transparencyPaintDirtyRect, localPaintingInfo.subPixelAccumulation);

        if (localPaintingInfo.clipToDirtyRect) {
            // Paint our background first, before painting any child layers.
            // Establish the clip used to paint our background.
            clipToRect(localPaintingInfo, context, fragment.backgroundRect, DoNotIncludeSelfForBorderRadius); // Background painting will handle clipping to self.
        }

        // Paint the background.
        // FIXME: Eventually we will collect the region from the fragment itself instead of just from the paint info.
        PaintInfo paintInfo(context, pixelSnappedIntRect(fragment.backgroundRect.rect()), PaintPhaseBlockBackground, paintingRootForRenderer, 0, localPaintingInfo.rootLayer->renderer());
        renderer()->paint(paintInfo, toPoint(fragment.layerBounds.location() - renderBoxLocation() + localPaintingInfo.subPixelAccumulation));

        if (localPaintingInfo.clipToDirtyRect)
            restoreClip(context, localPaintingInfo.paintDirtyRect, fragment.backgroundRect);
    }
}

void RenderLayer::paintForegroundForFragments(const LayerFragments& layerFragments, GraphicsContext* context, GraphicsContext* transparencyLayerContext,
    const LayoutRect& transparencyPaintDirtyRect, bool haveTransparency, const LayerPaintingInfo& localPaintingInfo,
    RenderObject* paintingRootForRenderer)
{
    // Begin transparency if we have something to paint.
    if (haveTransparency) {
        for (size_t i = 0; i < layerFragments.size(); ++i) {
            const LayerFragment& fragment = layerFragments.at(i);
            if (fragment.shouldPaintContent && !fragment.foregroundRect.isEmpty()) {
                beginTransparencyLayers(transparencyLayerContext, localPaintingInfo.rootLayer, transparencyPaintDirtyRect, localPaintingInfo.subPixelAccumulation);
                break;
            }
        }
    }

    // Optimize clipping for the single fragment case.
    bool shouldClip = localPaintingInfo.clipToDirtyRect && layerFragments.size() == 1 && layerFragments[0].shouldPaintContent && !layerFragments[0].foregroundRect.isEmpty();
    if (shouldClip)
        clipToRect(localPaintingInfo, context, layerFragments[0].foregroundRect);

    // We have to loop through every fragment multiple times, since we have to issue paint invalidations in each specific phase in order for
    // interleaving of the fragments to work properly.
    paintForegroundForFragmentsWithPhase(PaintPhaseChildBlockBackgrounds, layerFragments,
        context, localPaintingInfo, paintingRootForRenderer);
    paintForegroundForFragmentsWithPhase(PaintPhaseForeground, layerFragments, context, localPaintingInfo, paintingRootForRenderer);
    paintForegroundForFragmentsWithPhase(PaintPhaseChildOutlines, layerFragments, context, localPaintingInfo, paintingRootForRenderer);

    if (shouldClip)
        restoreClip(context, localPaintingInfo.paintDirtyRect, layerFragments[0].foregroundRect);
}

void RenderLayer::paintForegroundForFragmentsWithPhase(PaintPhase phase, const LayerFragments& layerFragments, GraphicsContext* context,
    const LayerPaintingInfo& localPaintingInfo, RenderObject* paintingRootForRenderer)
{
    bool shouldClip = localPaintingInfo.clipToDirtyRect && layerFragments.size() > 1;

    for (size_t i = 0; i < layerFragments.size(); ++i) {
        const LayerFragment& fragment = layerFragments.at(i);
        if (!fragment.shouldPaintContent || fragment.foregroundRect.isEmpty())
            continue;

        if (shouldClip)
            clipToRect(localPaintingInfo, context, fragment.foregroundRect);

        PaintInfo paintInfo(context, pixelSnappedIntRect(fragment.foregroundRect.rect()), phase, paintingRootForRenderer, 0, localPaintingInfo.rootLayer->renderer());
        renderer()->paint(paintInfo, toPoint(fragment.layerBounds.location() - renderBoxLocation() + localPaintingInfo.subPixelAccumulation));

        if (shouldClip)
            restoreClip(context, localPaintingInfo.paintDirtyRect, fragment.foregroundRect);
    }
}

void RenderLayer::paintOutlineForFragments(const LayerFragments& layerFragments, GraphicsContext* context, const LayerPaintingInfo& localPaintingInfo,
    RenderObject* paintingRootForRenderer)
{
    for (size_t i = 0; i < layerFragments.size(); ++i) {
        const LayerFragment& fragment = layerFragments.at(i);
        if (fragment.outlineRect.isEmpty())
            continue;

        PaintInfo paintInfo(context, pixelSnappedIntRect(fragment.outlineRect.rect()), PaintPhaseSelfOutline, paintingRootForRenderer, 0, localPaintingInfo.rootLayer->renderer());
        clipToRect(localPaintingInfo, context, fragment.outlineRect, DoNotIncludeSelfForBorderRadius);
        renderer()->paint(paintInfo, toPoint(fragment.layerBounds.location() - renderBoxLocation() + localPaintingInfo.subPixelAccumulation));
        restoreClip(context, localPaintingInfo.paintDirtyRect, fragment.outlineRect);
    }
}

void RenderLayer::paintMaskForFragments(const LayerFragments& layerFragments, GraphicsContext* context, const LayerPaintingInfo& localPaintingInfo,
    RenderObject* paintingRootForRenderer)
{
    for (size_t i = 0; i < layerFragments.size(); ++i) {
        const LayerFragment& fragment = layerFragments.at(i);
        if (!fragment.shouldPaintContent)
            continue;

        if (localPaintingInfo.clipToDirtyRect)
            clipToRect(localPaintingInfo, context, fragment.backgroundRect, DoNotIncludeSelfForBorderRadius); // Mask painting will handle clipping to self.

        // Paint the mask.
        // FIXME: Eventually we will collect the region from the fragment itself instead of just from the paint info.
        PaintInfo paintInfo(context, pixelSnappedIntRect(fragment.backgroundRect.rect()), PaintPhaseMask, paintingRootForRenderer, 0, localPaintingInfo.rootLayer->renderer());
        renderer()->paint(paintInfo, toPoint(fragment.layerBounds.location() - renderBoxLocation() + localPaintingInfo.subPixelAccumulation));

        if (localPaintingInfo.clipToDirtyRect)
            restoreClip(context, localPaintingInfo.paintDirtyRect, fragment.backgroundRect);
    }
}

void RenderLayer::paintOverflowControlsForFragments(const LayerFragments& layerFragments, GraphicsContext* context, const LayerPaintingInfo& localPaintingInfo)
{
    for (size_t i = 0; i < layerFragments.size(); ++i) {
        const LayerFragment& fragment = layerFragments.at(i);
        clipToRect(localPaintingInfo, context, fragment.backgroundRect);
        if (RenderLayerScrollableArea* scrollableArea = this->scrollableArea())
            scrollableArea->paintOverflowControls(context, roundedIntPoint(toPoint(fragment.layerBounds.location() - renderBoxLocation() + localPaintingInfo.subPixelAccumulation)), pixelSnappedIntRect(fragment.backgroundRect.rect()), true);
        restoreClip(context, localPaintingInfo.paintDirtyRect, fragment.backgroundRect);
    }
}

static inline LayoutRect frameVisibleRect(RenderObject* renderer)
{
    FrameView* frameView = renderer->document().view();
    if (!frameView)
        return LayoutRect();

    return frameView->visibleContentRect();
}

bool RenderLayer::hitTest(const HitTestRequest& request, HitTestResult& result)
{
    return hitTest(request, result.hitTestLocation(), result);
}

bool RenderLayer::hitTest(const HitTestRequest& request, const HitTestLocation& hitTestLocation, HitTestResult& result)
{
    ASSERT(isSelfPaintingLayer() || hasSelfPaintingLayerDescendant());

    // RenderView should make sure to update layout before entering hit testing
    ASSERT(!renderer()->frame()->view()->layoutPending());
    ASSERT(!renderer()->document().renderView()->needsLayout());

    LayoutRect hitTestArea = renderer()->view()->documentRect();
    if (!request.ignoreClipping())
        hitTestArea.intersect(frameVisibleRect(renderer()));

    RenderLayer* insideLayer = hitTestLayer(this, 0, request, result, hitTestArea, hitTestLocation, false);
    if (!insideLayer) {
        // We didn't hit any layer. If we are the root layer and the mouse is -- or just was -- down,
        // return ourselves. We do this so mouse events continue getting delivered after a drag has
        // exited the WebView, and so hit testing over a scrollbar hits the content document.
        if (!request.isChildFrameHitTest() && (request.active() || request.release()) && isRootLayer()) {
            renderer()->updateHitTestResult(result, hitTestLocation.point());
            insideLayer = this;
        }
    }

    // Now determine if the result is inside an anchor - if the urlElement isn't already set.
    Node* node = result.innerNode();
    if (node && !result.URLElement())
        result.setURLElement(node->enclosingLinkEventParentOrSelf());

    // Now return whether we were inside this layer (this will always be true for the root
    // layer).
    return insideLayer;
}

Node* RenderLayer::enclosingElement() const
{
    for (RenderObject* r = renderer(); r; r = r->parent()) {
        if (Node* e = r->node())
            return e;
    }
    ASSERT_NOT_REACHED();
    return 0;
}

// Compute the z-offset of the point in the transformState.
// This is effectively projecting a ray normal to the plane of ancestor, finding where that
// ray intersects target, and computing the z delta between those two points.
static double computeZOffset(const HitTestingTransformState& transformState)
{
    // We got an affine transform, so no z-offset
    if (transformState.m_accumulatedTransform.isAffine())
        return 0;

    // Flatten the point into the target plane
    FloatPoint targetPoint = transformState.mappedPoint();

    // Now map the point back through the transform, which computes Z.
    FloatPoint3D backmappedPoint = transformState.m_accumulatedTransform.mapPoint(FloatPoint3D(targetPoint));
    return backmappedPoint.z();
}

PassRefPtr<HitTestingTransformState> RenderLayer::createLocalTransformState(RenderLayer* rootLayer, RenderLayer* containerLayer,
                                        const LayoutRect& hitTestRect, const HitTestLocation& hitTestLocation,
                                        const HitTestingTransformState* containerTransformState,
                                        const LayoutPoint& translationOffset) const
{
    RefPtr<HitTestingTransformState> transformState;
    LayoutPoint offset;
    if (containerTransformState) {
        // If we're already computing transform state, then it's relative to the container (which we know is non-null).
        transformState = HitTestingTransformState::create(*containerTransformState);
        convertToLayerCoords(containerLayer, offset);
    } else {
        // If this is the first time we need to make transform state, then base it off of hitTestLocation,
        // which is relative to rootLayer.
        transformState = HitTestingTransformState::create(hitTestLocation.transformedPoint(), hitTestLocation.transformedRect(), FloatQuad(hitTestRect));
        convertToLayerCoords(rootLayer, offset);
    }
    offset.moveBy(translationOffset);

    RenderObject* containerRenderer = containerLayer ? containerLayer->renderer() : 0;
    if (renderer()->shouldUseTransformFromContainer(containerRenderer)) {
        TransformationMatrix containerTransform;
        renderer()->getTransformFromContainer(containerRenderer, toLayoutSize(offset), containerTransform);
        transformState->applyTransform(containerTransform, HitTestingTransformState::AccumulateTransform);
    } else {
        transformState->translate(offset.x(), offset.y(), HitTestingTransformState::AccumulateTransform);
    }

    return transformState;
}


static bool isHitCandidate(const RenderLayer* hitLayer, bool canDepthSort, double* zOffset, const HitTestingTransformState* transformState)
{
    if (!hitLayer)
        return false;

    // The hit layer is depth-sorting with other layers, so just say that it was hit.
    if (canDepthSort)
        return true;

    // We need to look at z-depth to decide if this layer was hit.
    if (zOffset) {
        ASSERT(transformState);
        // This is actually computing our z, but that's OK because the hitLayer is coplanar with us.
        double childZOffset = computeZOffset(*transformState);
        if (childZOffset > *zOffset) {
            *zOffset = childZOffset;
            return true;
        }
        return false;
    }

    return true;
}

// hitTestLocation and hitTestRect are relative to rootLayer.
// A 'flattening' layer is one preserves3D() == false.
// transformState.m_accumulatedTransform holds the transform from the containing flattening layer.
// transformState.m_lastPlanarPoint is the hitTestLocation in the plane of the containing flattening layer.
// transformState.m_lastPlanarQuad is the hitTestRect as a quad in the plane of the containing flattening layer.
//
// If zOffset is non-null (which indicates that the caller wants z offset information),
//  *zOffset on return is the z offset of the hit point relative to the containing flattening layer.
RenderLayer* RenderLayer::hitTestLayer(RenderLayer* rootLayer, RenderLayer* containerLayer, const HitTestRequest& request, HitTestResult& result,
                                       const LayoutRect& hitTestRect, const HitTestLocation& hitTestLocation, bool appliedTransform,
                                       const HitTestingTransformState* transformState, double* zOffset)
{
    if (!isSelfPaintingLayer() && !hasSelfPaintingLayerDescendant())
        return 0;

    // The natural thing would be to keep HitTestingTransformState on the stack, but it's big, so we heap-allocate.

    // Apply a transform if we have one.
    if (transform() && !appliedTransform) {
        // Make sure the parent's clip rects have been calculated.
        if (parent()) {
            ClipRect clipRect = clipper().backgroundClipRect(ClipRectsContext(rootLayer, RootRelativeClipRects));
            // Go ahead and test the enclosing clip now.
            if (!clipRect.intersects(hitTestLocation))
                return 0;
        }

        return hitTestLayerByApplyingTransform(rootLayer, containerLayer, request, result, hitTestRect, hitTestLocation, transformState, zOffset);
    }

    // Ensure our lists and 3d status are up-to-date.
    m_stackingNode->updateLayerListsIfNeeded();
    update3DTransformedDescendantStatus();

    RefPtr<HitTestingTransformState> localTransformState;
    if (appliedTransform) {
        // We computed the correct state in the caller (above code), so just reference it.
        ASSERT(transformState);
        localTransformState = const_cast<HitTestingTransformState*>(transformState);
    } else if (transformState || m_has3DTransformedDescendant || preserves3D()) {
        // We need transform state for the first time, or to offset the container state, so create it here.
        localTransformState = createLocalTransformState(rootLayer, containerLayer, hitTestRect, hitTestLocation, transformState);
    }

    // Check for hit test on backface if backface-visibility is 'hidden'
    if (localTransformState && renderer()->style()->backfaceVisibility() == BackfaceVisibilityHidden) {
        TransformationMatrix invertedMatrix = localTransformState->m_accumulatedTransform.inverse();
        // If the z-vector of the matrix is negative, the back is facing towards the viewer.
        if (invertedMatrix.m33() < 0)
            return 0;
    }

    RefPtr<HitTestingTransformState> unflattenedTransformState = localTransformState;
    if (localTransformState && !preserves3D()) {
        // Keep a copy of the pre-flattening state, for computing z-offsets for the container
        unflattenedTransformState = HitTestingTransformState::create(*localTransformState);
        // This layer is flattening, so flatten the state passed to descendants.
        localTransformState->flatten();
    }

    // The following are used for keeping track of the z-depth of the hit point of 3d-transformed
    // descendants.
    double localZOffset = -std::numeric_limits<double>::infinity();
    double* zOffsetForDescendantsPtr = 0;
    double* zOffsetForContentsPtr = 0;

    bool depthSortDescendants = false;
    if (preserves3D()) {
        depthSortDescendants = true;
        // Our layers can depth-test with our container, so share the z depth pointer with the container, if it passed one down.
        zOffsetForDescendantsPtr = zOffset ? zOffset : &localZOffset;
        zOffsetForContentsPtr = zOffset ? zOffset : &localZOffset;
    } else if (zOffset) {
        zOffsetForDescendantsPtr = 0;
        // Container needs us to give back a z offset for the hit layer.
        zOffsetForContentsPtr = zOffset;
    }

    // This variable tracks which layer the mouse ends up being inside.
    RenderLayer* candidateLayer = 0;

    // Begin by walking our list of positive layers from highest z-index down to the lowest z-index.
    RenderLayer* hitLayer = hitTestChildren(PositiveZOrderChildren, rootLayer, request, result, hitTestRect, hitTestLocation,
                                        localTransformState.get(), zOffsetForDescendantsPtr, zOffset, unflattenedTransformState.get(), depthSortDescendants);
    if (hitLayer) {
        if (!depthSortDescendants)
            return hitLayer;
        candidateLayer = hitLayer;
    }

    // Now check our overflow objects.
    hitLayer = hitTestChildren(NormalFlowChildren, rootLayer, request, result, hitTestRect, hitTestLocation,
                           localTransformState.get(), zOffsetForDescendantsPtr, zOffset, unflattenedTransformState.get(), depthSortDescendants);
    if (hitLayer) {
        if (!depthSortDescendants)
            return hitLayer;
        candidateLayer = hitLayer;
    }

    LayoutRect layerBounds;
    ClipRect backgroundRect, foregroundRect, outlineRect;
    ClipRectsContext clipRectsContext(rootLayer, RootRelativeClipRects);
    clipper().calculateRects(clipRectsContext, hitTestRect, layerBounds, backgroundRect, foregroundRect, outlineRect);

    // Next we want to see if the mouse pos is inside the child RenderObjects of the layer.
    if (isSelfPaintingLayer() && !foregroundRect.intersects(hitTestLocation)) {
        // Hit test with a temporary HitTestResult, because we only want to commit to 'result' if we know we're frontmost.
        HitTestResult tempResult(result.hitTestLocation());
        if (hitTestContents(request, tempResult, layerBounds, hitTestLocation, HitTestDescendants)
            && isHitCandidate(this, false, zOffsetForContentsPtr, unflattenedTransformState.get())) {
            if (result.isRectBasedTest())
                result.append(tempResult);
            else
                result = tempResult;
            if (!depthSortDescendants)
                return this;
            // Foreground can depth-sort with descendant layers, so keep this as a candidate.
            candidateLayer = this;
        } else if (result.isRectBasedTest()) {
            result.append(tempResult);
        }
    }

    // Now check our negative z-index children.
    hitLayer = hitTestChildren(NegativeZOrderChildren, rootLayer, request, result, hitTestRect, hitTestLocation,
        localTransformState.get(), zOffsetForDescendantsPtr, zOffset, unflattenedTransformState.get(), depthSortDescendants);
    if (hitLayer) {
        if (!depthSortDescendants)
            return hitLayer;
        candidateLayer = hitLayer;
    }

    // If we found a layer, return. Child layers, and foreground always render in front of background.
    if (candidateLayer)
        return candidateLayer;

    if (isSelfPaintingLayer() && !backgroundRect.intersects(hitTestLocation)) {
        HitTestResult tempResult(result.hitTestLocation());
        if (hitTestContents(request, tempResult, layerBounds, hitTestLocation, HitTestSelf)
            && isHitCandidate(this, false, zOffsetForContentsPtr, unflattenedTransformState.get())) {
            if (result.isRectBasedTest())
                result.append(tempResult);
            else
                result = tempResult;
            return this;
        }
        if (result.isRectBasedTest())
            result.append(tempResult);
    }

    return 0;
}

RenderLayer* RenderLayer::hitTestLayerByApplyingTransform(RenderLayer* rootLayer, RenderLayer* containerLayer, const HitTestRequest& request, HitTestResult& result,
    const LayoutRect& hitTestRect, const HitTestLocation& hitTestLocation, const HitTestingTransformState* transformState, double* zOffset,
    const LayoutPoint& translationOffset)
{
    // Create a transform state to accumulate this transform.
    RefPtr<HitTestingTransformState> newTransformState = createLocalTransformState(rootLayer, containerLayer, hitTestRect, hitTestLocation, transformState, translationOffset);

    // If the transform can't be inverted, then don't hit test this layer at all.
    if (!newTransformState->m_accumulatedTransform.isInvertible())
        return 0;

    // Compute the point and the hit test rect in the coords of this layer by using the values
    // from the transformState, which store the point and quad in the coords of the last flattened
    // layer, and the accumulated transform which lets up map through preserve-3d layers.
    //
    // We can't just map hitTestLocation and hitTestRect because they may have been flattened (losing z)
    // by our container.
    FloatPoint localPoint = newTransformState->mappedPoint();
    FloatQuad localPointQuad = newTransformState->mappedQuad();
    LayoutRect localHitTestRect = newTransformState->boundsOfMappedArea();
    HitTestLocation newHitTestLocation;
    if (hitTestLocation.isRectBasedTest())
        newHitTestLocation = HitTestLocation(localPoint, localPointQuad);
    else
        newHitTestLocation = HitTestLocation(localPoint);

    // Now do a hit test with the root layer shifted to be us.
    return hitTestLayer(this, containerLayer, request, result, localHitTestRect, newHitTestLocation, true, newTransformState.get(), zOffset);
}

bool RenderLayer::hitTestContents(const HitTestRequest& request, HitTestResult& result, const LayoutRect& layerBounds, const HitTestLocation& hitTestLocation, HitTestFilter hitTestFilter) const
{
    ASSERT(isSelfPaintingLayer() || hasSelfPaintingLayerDescendant());

    if (!renderer()->hitTest(request, result, hitTestLocation, toLayoutPoint(layerBounds.location() - renderBoxLocation()), hitTestFilter)) {
        // It's wrong to set innerNode, but then claim that you didn't hit anything, unless it is
        // a rect-based test.
        ASSERT(!result.innerNode() || (result.isRectBasedTest() && result.rectBasedTestResult().size()));
        return false;
    }

    // For positioned generated content, we might still not have a
    // node by the time we get to the layer level, since none of
    // the content in the layer has an element. So just walk up
    // the tree.
    if (!result.innerNode() || !result.innerNonSharedNode()) {
        Node* e = enclosingElement();
        if (!result.innerNode())
            result.setInnerNode(e);
        if (!result.innerNonSharedNode())
            result.setInnerNonSharedNode(e);
    }

    return true;
}

RenderLayer* RenderLayer::hitTestChildren(ChildrenIteration childrentoVisit, RenderLayer* rootLayer,
    const HitTestRequest& request, HitTestResult& result,
    const LayoutRect& hitTestRect, const HitTestLocation& hitTestLocation,
    const HitTestingTransformState* transformState,
    double* zOffsetForDescendants, double* zOffset,
    const HitTestingTransformState* unflattenedTransformState,
    bool depthSortDescendants)
{
    if (!hasSelfPaintingLayerDescendant())
        return 0;

    RenderLayer* resultLayer = 0;
    RenderLayerStackingNodeReverseIterator iterator(*m_stackingNode, childrentoVisit);
    while (RenderLayerStackingNode* child = iterator.next()) {
        RenderLayer* childLayer = child->layer();
        RenderLayer* hitLayer = 0;
        HitTestResult tempResult(result.hitTestLocation());
        hitLayer = childLayer->hitTestLayer(rootLayer, this, request, tempResult, hitTestRect, hitTestLocation, false, transformState, zOffsetForDescendants);

        // If it a rect-based test, we can safely append the temporary result since it might had hit
        // nodes but not necesserily had hitLayer set.
        if (result.isRectBasedTest())
            result.append(tempResult);

        if (isHitCandidate(hitLayer, depthSortDescendants, zOffset, unflattenedTransformState)) {
            resultLayer = hitLayer;
            if (!result.isRectBasedTest())
                result = tempResult;
            if (!depthSortDescendants)
                break;
        }
    }

    return resultLayer;
}

void RenderLayer::addBlockSelectionGapsBounds(const LayoutRect& bounds)
{
    m_blockSelectionGapsBounds.unite(enclosingIntRect(bounds));
}

void RenderLayer::clearBlockSelectionGapsBounds()
{
    m_blockSelectionGapsBounds = IntRect();
    for (RenderLayer* child = firstChild(); child; child = child->nextSibling())
        child->clearBlockSelectionGapsBounds();
}

void RenderLayer::invalidatePaintForBlockSelectionGaps()
{
    for (RenderLayer* child = firstChild(); child; child = child->nextSibling())
        child->invalidatePaintForBlockSelectionGaps();

    if (m_blockSelectionGapsBounds.isEmpty())
        return;

    LayoutRect rect = m_blockSelectionGapsBounds;
    if (renderer()->hasOverflowClip()) {
        RenderBox* box = renderBox();
        rect.move(-box->scrolledContentOffset());
        rect.intersect(box->overflowClipRect(LayoutPoint()));
    }
    if (renderer()->hasClip())
        rect.intersect(toRenderBox(renderer())->clipRect(LayoutPoint()));
    if (!rect.isEmpty())
        renderer()->invalidatePaintRectangle(rect);
}

IntRect RenderLayer::blockSelectionGapsBounds() const
{
    if (!renderer()->isRenderBlock())
        return IntRect();

    RenderBlock* renderBlock = toRenderBlock(renderer());
    LayoutRect gapRects = renderBlock->selectionGapRectsForPaintInvalidation(renderBlock);

    return pixelSnappedIntRect(gapRects);
}

bool RenderLayer::intersectsDamageRect(const LayoutRect& layerBounds, const LayoutRect& damageRect, const RenderLayer* rootLayer, const LayoutPoint* offsetFromRoot) const
{
    // Always examine the canvas and the root.
    // FIXME: Could eliminate the isDocumentElement() check if we fix background painting so that the RenderView
    // paints the root's background.
    if (isRootLayer() || renderer()->isDocumentElement())
        return true;

    // If we aren't an inline flow, and our layer bounds do intersect the damage rect, then we
    // can go ahead and return true.
    RenderView* view = renderer()->view();
    ASSERT(view);
    if (view && !renderer()->isRenderInline()) {
        if (layerBounds.intersects(damageRect))
            return true;
    }

    // Otherwise we need to compute the bounding box of this single layer and see if it intersects
    // the damage rect.
    return physicalBoundingBox(rootLayer, offsetFromRoot).intersects(damageRect);
}

LayoutRect RenderLayer::logicalBoundingBox() const
{
    // There are three special cases we need to consider.
    // (1) Inline Flows.  For inline flows we will create a bounding box that fully encompasses all of the lines occupied by the
    // inline.  In other words, if some <span> wraps to three lines, we'll create a bounding box that fully encloses the
    // line boxes of all three lines (including overflow on those lines).
    // (2) Left/Top Overflow.  The width/height of layers already includes right/bottom overflow.  However, in the case of left/top
    // overflow, we have to create a bounding box that will extend to include this overflow.
    // (3) Floats.  When a layer has overhanging floats that it paints, we need to make sure to include these overhanging floats
    // as part of our bounding box.  We do this because we are the responsible layer for both hit testing and painting those
    // floats.
    LayoutRect result;
    if (renderer()->isInline() && renderer()->isRenderInline()) {
        result = toRenderInline(renderer())->linesVisualOverflowBoundingBox();
    } else {
        RenderBox* box = renderBox();
        ASSERT(box);
        result = box->borderBoxRect();
        result.unite(box->visualOverflowRect());
    }

    ASSERT(renderer()->view());
    return result;
}

LayoutRect RenderLayer::physicalBoundingBox(const RenderLayer* ancestorLayer, const LayoutPoint* offsetFromRoot) const
{
    LayoutPoint delta;
    if (offsetFromRoot)
        delta = *offsetFromRoot;
    else
        convertToLayerCoords(ancestorLayer, delta);

    LayoutRect result = logicalBoundingBox();
    result.moveBy(delta);
    return result;
}

static void expandRectForReflectionAndStackingChildren(const RenderLayer* ancestorLayer, RenderLayer::CalculateBoundsOptions options, LayoutRect& result)
{
    ASSERT(ancestorLayer->stackingNode()->isStackingContext() || !ancestorLayer->stackingNode()->hasPositiveZOrderList());

#if ENABLE(ASSERT)
    LayerListMutationDetector mutationChecker(const_cast<RenderLayer*>(ancestorLayer)->stackingNode());
#endif

    RenderLayerStackingNodeIterator iterator(*ancestorLayer->stackingNode(), AllChildren);
    while (RenderLayerStackingNode* node = iterator.next()) {
        result.unite(node->layer()->boundingBoxForCompositing(ancestorLayer, options));
    }
}

LayoutRect RenderLayer::physicalBoundingBoxIncludingReflectionAndStackingChildren(const RenderLayer* ancestorLayer, const LayoutPoint& offsetFromRoot) const
{
    LayoutPoint origin;
    LayoutRect result = physicalBoundingBox(ancestorLayer, &origin);

    const_cast<RenderLayer*>(this)->stackingNode()->updateLayerListsIfNeeded();

    expandRectForReflectionAndStackingChildren(this, DoNotApplyBoundsChickenEggHacks, result);

    result.moveBy(offsetFromRoot);
    return result;
}

LayoutRect RenderLayer::boundingBoxForCompositing(const RenderLayer* ancestorLayer, CalculateBoundsOptions options) const
{
    if (!isSelfPaintingLayer())
        return LayoutRect();

    if (!ancestorLayer)
        ancestorLayer = this;

    // The root layer is always just the size of the document.
    if (isRootLayer())
        return m_renderer->view()->unscaledDocumentRect();

    const bool shouldIncludeTransform = paintsWithTransform() || (options == ApplyBoundsChickenEggHacks && transform());

    LayoutRect localClipRect = clipper().localClipRect();
    if (localClipRect != PaintInfo::infiniteRect()) {
        if (shouldIncludeTransform)
            localClipRect = transform()->mapRect(localClipRect);

        LayoutPoint delta;
        convertToLayerCoords(ancestorLayer, delta);
        localClipRect.moveBy(delta);
        return localClipRect;
    }

    LayoutPoint origin;
    LayoutRect result = physicalBoundingBox(ancestorLayer, &origin);

    const_cast<RenderLayer*>(this)->stackingNode()->updateLayerListsIfNeeded();

    expandRectForReflectionAndStackingChildren(this, options, result);

    // FIXME: We can optimize the size of the composited layers, by not enlarging
    // filtered areas with the outsets if we know that the filter is going to render in hardware.
    // https://bugs.webkit.org/show_bug.cgi?id=81239
    m_renderer->style()->filterOutsets().expandRect(result);

    if (shouldIncludeTransform)
        result = transform()->mapRect(result);

    LayoutPoint delta;
    convertToLayerCoords(ancestorLayer, delta);
    result.moveBy(delta);
    return result;
}

bool RenderLayer::paintsWithTransform() const
{
    // FIXME(sky): Remove
    return transform();
}

bool RenderLayer::backgroundIsKnownToBeOpaqueInRect(const LayoutRect& localRect) const
{
    if (!isSelfPaintingLayer() && !hasSelfPaintingLayerDescendant())
        return false;

    if (isTransparent())
        return false;

    if (paintsWithFilters() && renderer()->style()->filter().hasFilterThatAffectsOpacity())
        return false;

    // FIXME: Handle simple transforms.
    if (paintsWithTransform())
        return false;

    // FIXME: Remove this check.
    // This function should not be called when layer-lists are dirty.
    // It is somehow getting triggered during style update.
    if (m_stackingNode->zOrderListsDirty() || m_stackingNode->normalFlowListDirty())
        return false;

    // FIXME: We currently only check the immediate renderer,
    // which will miss many cases.
    if (renderer()->backgroundIsKnownToBeOpaqueInRect(localRect))
        return true;

    // We can't consult child layers if we clip, since they might cover
    // parts of the rect that are clipped out.
    if (renderer()->hasOverflowClip())
        return false;

    return childBackgroundIsKnownToBeOpaqueInRect(localRect);
}

bool RenderLayer::childBackgroundIsKnownToBeOpaqueInRect(const LayoutRect& localRect) const
{
    RenderLayerStackingNodeReverseIterator revertseIterator(*m_stackingNode, PositiveZOrderChildren | NormalFlowChildren | NegativeZOrderChildren);
    while (RenderLayerStackingNode* child = revertseIterator.next()) {
        const RenderLayer* childLayer = child->layer();
        if (!childLayer->canUseConvertToLayerCoords())
            continue;

        LayoutPoint childOffset;
        LayoutRect childLocalRect(localRect);
        childLayer->convertToLayerCoords(this, childOffset);
        childLocalRect.moveBy(-childOffset);

        if (childLayer->backgroundIsKnownToBeOpaqueInRect(childLocalRect))
            return true;
    }
    return false;
}

bool RenderLayer::shouldBeSelfPaintingLayer() const
{
    return m_layerType == NormalLayer
        || (m_scrollableArea && m_scrollableArea->hasOverlayScrollbars())
        || needsCompositedScrolling();
}

void RenderLayer::updateSelfPaintingLayer()
{
    bool isSelfPaintingLayer = shouldBeSelfPaintingLayer();
    if (this->isSelfPaintingLayer() == isSelfPaintingLayer)
        return;

    m_isSelfPaintingLayer = isSelfPaintingLayer;

    if (parent())
        parent()->dirtyAncestorChainHasSelfPaintingLayerDescendantStatus();
}

bool RenderLayer::hasNonEmptyChildRenderers() const
{
    // Some HTML can cause whitespace text nodes to have renderers, like:
    // <div>
    // <img src=...>
    // </div>
    // so test for 0x0 RenderTexts here
    for (RenderObject* child = renderer()->slowFirstChild(); child; child = child->nextSibling()) {
        if (!child->hasLayer()) {
            if (child->isRenderInline() || !child->isBox())
                return true;

            if (toRenderBox(child)->width() > 0 || toRenderBox(child)->height() > 0)
                return true;
        }
    }
    return false;
}

bool RenderLayer::hasBoxDecorationsOrBackground() const
{
    return renderer()->style()->hasBoxDecorations() || renderer()->style()->hasBackground();
}

bool RenderLayer::hasVisibleBoxDecorations() const
{
    return hasBoxDecorationsOrBackground() || hasOverflowControls();
}

bool RenderLayer::isVisuallyNonEmpty() const
{
    if (hasNonEmptyChildRenderers())
        return true;

    if (renderer()->isReplaced() || renderer()->hasMask())
        return true;

    if (hasVisibleBoxDecorations())
        return true;

    return false;
}

void RenderLayer::updateFilters(const RenderStyle* oldStyle, const RenderStyle* newStyle)
{
    if (!newStyle->hasFilter() && (!oldStyle || !oldStyle->hasFilter()))
        return;

    updateOrRemoveFilterClients();
    updateOrRemoveFilterEffectRenderer();
}

void RenderLayer::styleChanged(StyleDifference diff, const RenderStyle* oldStyle)
{
    m_stackingNode->updateIsNormalFlowOnly();
    m_stackingNode->updateStackingNodesAfterStyleChange(oldStyle);

    if (m_scrollableArea)
        m_scrollableArea->updateAfterStyleChange(oldStyle);

    // Overlay scrollbars can make this layer self-painting so we need
    // to recompute the bit once scrollbars have been updated.
    updateSelfPaintingLayer();

    updateTransform(oldStyle, renderer()->style());
    updateFilters(oldStyle, renderer()->style());
}

bool RenderLayer::scrollsOverflow() const
{
    if (RenderLayerScrollableArea* scrollableArea = this->scrollableArea())
        return scrollableArea->scrollsOverflow();

    return false;
}

FilterOperations RenderLayer::computeFilterOperations(const RenderStyle* style)
{
    return style->filter();
}

void RenderLayer::updateOrRemoveFilterClients()
{
    if (!hasFilter()) {
        removeFilterInfoIfNeeded();
        return;
    }

    if (renderer()->style()->filter().hasReferenceFilter())
        ensureFilterInfo()->updateReferenceFilterClients(renderer()->style()->filter());
    else if (hasFilterInfo())
        filterInfo()->removeReferenceFilterClients();
}

void RenderLayer::updateOrRemoveFilterEffectRenderer()
{
    // FilterEffectRenderer is only used to render the filters in software mode,
    // so we always need to run updateOrRemoveFilterEffectRenderer after the composited
    // mode might have changed for this layer.
    if (!paintsWithFilters()) {
        // Don't delete the whole filter info here, because we might use it
        // for loading CSS shader files.
        if (RenderLayerFilterInfo* filterInfo = this->filterInfo())
            filterInfo->setRenderer(nullptr);

        return;
    }

    RenderLayerFilterInfo* filterInfo = ensureFilterInfo();
    if (!filterInfo->renderer()) {
        RefPtr<FilterEffectRenderer> filterRenderer = FilterEffectRenderer::create();
        filterInfo->setRenderer(filterRenderer.release());

        // We can optimize away code paths in other places if we know that there are no software filters.
        renderer()->document().view()->setHasSoftwareFilters(true);
    }

    // If the filter fails to build, remove it from the layer. It will still attempt to
    // go through regular processing (e.g. compositing), but never apply anything.
    if (!filterInfo->renderer()->build(renderer(), computeFilterOperations(renderer()->style())))
        filterInfo->setRenderer(nullptr);
}

void RenderLayer::filterNeedsPaintInvalidation()
{
}

void RenderLayer::setShouldDoFullPaintInvalidationIncludingNonCompositingDescendants()
{
    renderer()->setShouldDoFullPaintInvalidation(true);

    for (RenderLayer* child = firstChild(); child; child = child->nextSibling()) {
        child->setShouldDoFullPaintInvalidationIncludingNonCompositingDescendants();
    }
}

} // namespace blink

#ifndef NDEBUG
void showLayerTree(const blink::RenderLayer* layer)
{
    if (!layer)
        return;

    if (blink::LocalFrame* frame = layer->renderer()->frame()) {
        WTF::String output = externalRepresentation(frame, blink::RenderAsTextShowAllLayers | blink::RenderAsTextShowLayerNesting | blink::RenderAsTextShowCompositedLayers | blink::RenderAsTextShowAddresses | blink::RenderAsTextShowIDAndClass | blink::RenderAsTextDontUpdateLayout | blink::RenderAsTextShowLayoutState);
        fprintf(stderr, "%s\n", output.utf8().data());
    }
}

void showLayerTree(const blink::RenderObject* renderer)
{
    if (!renderer)
        return;
    showLayerTree(renderer->enclosingLayer());
}
#endif
