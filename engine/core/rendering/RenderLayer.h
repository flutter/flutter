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

#ifndef RenderLayer_h
#define RenderLayer_h

#include "sky/engine/core/rendering/LayerFragment.h"
#include "sky/engine/core/rendering/LayerPaintingInfo.h"
#include "sky/engine/core/rendering/RenderBox.h"
#include "sky/engine/core/rendering/RenderLayerClipper.h"
#include "sky/engine/core/rendering/RenderLayerFilterInfo.h"
#include "sky/engine/core/rendering/RenderLayerRepainter.h"
#include "sky/engine/core/rendering/RenderLayerScrollableArea.h"
#include "sky/engine/core/rendering/RenderLayerStackingNode.h"
#include "sky/engine/core/rendering/RenderLayerStackingNodeIterator.h"
#include "sky/engine/platform/graphics/CompositingReasons.h"
#include "sky/engine/public/platform/WebBlendMode.h"
#include "sky/engine/wtf/OwnPtr.h"

namespace blink {

class FilterEffectRenderer;
class FilterOperations;
class HitTestRequest;
class HitTestResult;
class HitTestingTransformState;
class CompositedLayerMapping;
class RenderLayerCompositor;
class RenderStyle;
class TransformationMatrix;

enum BorderRadiusClippingRule { IncludeSelfForBorderRadius, DoNotIncludeSelfForBorderRadius };
enum IncludeSelfOrNot { IncludeSelf, ExcludeSelf };

enum CompositingQueryMode {
    CompositingQueriesAreAllowed,
    CompositingQueriesAreOnlyAllowedInCertainDocumentLifecyclePhases
};

// FIXME: remove this once the compositing query ASSERTS are no longer hit.
class DisableCompositingQueryAsserts {
    WTF_MAKE_NONCOPYABLE(DisableCompositingQueryAsserts);
public:
    DisableCompositingQueryAsserts();
private:
    TemporaryChange<CompositingQueryMode> m_disabler;
};

class RenderLayer {
    WTF_MAKE_NONCOPYABLE(RenderLayer);
public:
    RenderLayer(RenderLayerModelObject*, LayerType);
    ~RenderLayer();

    String debugName() const;

    RenderLayerModelObject* renderer() const { return m_renderer; }
    RenderBox* renderBox() const { return m_renderer && m_renderer->isBox() ? toRenderBox(m_renderer) : 0; }
    RenderLayer* parent() const { return m_parent; }
    RenderLayer* previousSibling() const { return m_previous; }
    RenderLayer* nextSibling() const { return m_next; }
    RenderLayer* firstChild() const { return m_first; }
    RenderLayer* lastChild() const { return m_last; }

    const RenderLayer* compositingContainer() const;

    void addChild(RenderLayer* newChild, RenderLayer* beforeChild = 0);
    RenderLayer* removeChild(RenderLayer*);

    void removeOnlyThisLayer();
    void insertOnlyThisLayer();

    void styleChanged(StyleDifference, const RenderStyle* oldStyle);

    // FIXME: Many people call this function while it has out-of-date information.
    bool isSelfPaintingLayer() const { return m_isSelfPaintingLayer; }

    void setLayerType(LayerType layerType) { m_layerType = layerType; }

    bool isTransparent() const { return renderer()->isTransparent() || renderer()->hasMask(); }
    RenderLayer* transparentPaintingAncestor();
    void beginTransparencyLayers(GraphicsContext*, const RenderLayer* rootLayer, const LayoutRect& paintDirtyRect, const LayoutSize& subPixelAccumulation, PaintBehavior);

    const RenderLayer* root() const
    {
        const RenderLayer* curr = this;
        while (curr->parent())
            curr = curr->parent();
        return curr;
    }

    LayoutPoint location() const;
    IntSize size() const;

    LayoutRect rect() const { return LayoutRect(location(), size()); }

    bool isRootLayer() const { return m_isRootLayer; }

    RenderLayerCompositor* compositor() const;

    // Notification from the renderer that its content changed (e.g. current frame of image changed).
    // Allows updates of layer content without invalidating paint.
    void contentChanged(ContentChangeType);

    void updateLayerPositionsAfterLayout();

    void updateTransformationMatrix();
    RenderLayer* renderingContextRoot();

    // Our current relative position offset.
    const LayoutSize offsetForInFlowPosition() const;

    void blockSelectionGapsBoundsChanged();
    void addBlockSelectionGapsBounds(const LayoutRect&);
    void clearBlockSelectionGapsBounds();
    void invalidatePaintForBlockSelectionGaps();
    IntRect blockSelectionGapsBounds() const;

    RenderLayerStackingNode* stackingNode() { return m_stackingNode.get(); }
    const RenderLayerStackingNode* stackingNode() const { return m_stackingNode.get(); }

    bool hasBoxDecorationsOrBackground() const;
    bool hasVisibleBoxDecorations() const;
    // Returns true if this layer has visible content (ignoring any child layers).
    bool isVisuallyNonEmpty() const;
    // True if this layer container renderers that paint.
    bool hasNonEmptyChildRenderers() const;

    bool usedTransparency() const { return m_usedTransparency; }

    // Gets the nearest enclosing positioned ancestor layer (also includes
    // the <html> layer and the root layer).
    RenderLayer* enclosingPositionedAncestor() const;

    RenderLayer* enclosingOverflowClipLayer(IncludeSelfOrNot = IncludeSelf) const;

    bool isPaintInvalidationContainer() const;

    // Do *not* call this method unless you know what you are dooing. You probably want to call enclosingCompositingLayerForPaintInvalidation() instead.
    // If includeSelf is true, may return this.
    RenderLayer* enclosingLayerWithCompositedLayerMapping(IncludeSelfOrNot) const;

    // Returns the enclosing layer root into which this layer paints, inclusive of this one. Note that the enclosing layer may or may not have its own
    // GraphicsLayer backing, but is nevertheless the root for a call to the RenderLayer::paint*() methods.
    RenderLayer* enclosingLayerForPaintInvalidation() const;

    RenderLayer* enclosingLayerForPaintInvalidationCrossingFrameBoundaries() const;

    RenderLayer* enclosingFilterLayer(IncludeSelfOrNot = IncludeSelf) const;
    bool hasAncestorWithFilterOutsets() const;

    bool canUseConvertToLayerCoords() const
    {
        return !renderer()->hasTransform();
    }

    void convertToLayerCoords(const RenderLayer* ancestorLayer, LayoutPoint&) const;
    void convertToLayerCoords(const RenderLayer* ancestorLayer, LayoutRect&) const;

    // The two main functions that use the layer system.  The paint method
    // paints the layers that intersect the damage rect from back to
    // front.  The hitTest method looks for mouse events by walking
    // layers that intersect the point from front to back.
    // paint() assumes that the caller will clip to the bounds of damageRect if necessary.
    void paint(GraphicsContext*, const LayoutRect& damageRect, PaintBehavior = PaintBehaviorNormal, RenderObject* paintingRoot = 0, PaintLayerFlags = 0);
    bool hitTest(const HitTestRequest&, HitTestResult&);
    bool hitTest(const HitTestRequest&, const HitTestLocation&, HitTestResult&);
    void paintOverlayScrollbars(GraphicsContext*, const LayoutRect& damageRect, PaintBehavior, RenderObject* paintingRoot = 0);

    // Pass offsetFromRoot if known.
    bool intersectsDamageRect(const LayoutRect& layerBounds, const LayoutRect& damageRect, const RenderLayer* rootLayer, const LayoutPoint* offsetFromRoot = 0) const;

    // Bounding box relative to some ancestor layer. Pass offsetFromRoot if known.
    LayoutRect physicalBoundingBox(const RenderLayer* ancestorLayer, const LayoutPoint* offsetFromRoot = 0) const;
    LayoutRect physicalBoundingBoxIncludingReflectionAndStackingChildren(const RenderLayer* ancestorLayer, const LayoutPoint& offsetFromRoot) const;

    // FIXME: This function is inconsistent as to whether the returned rect has been flipped for writing mode.
    LayoutRect boundingBoxForCompositingOverlapTest() const { return overlapBoundsIncludeChildren() ? boundingBoxForCompositing() : logicalBoundingBox(); }

    // If true, this layer's children are included in its bounds for overlap testing.
    // We can't rely on the children's positions if this layer has a filter that could have moved the children's pixels around.
    bool overlapBoundsIncludeChildren() const { return hasFilter() && renderer()->style()->filter().hasFilterThatMovesPixels(); }

    enum CalculateBoundsOptions {
        ApplyBoundsChickenEggHacks,
        DoNotApplyBoundsChickenEggHacks,
    };
    LayoutRect boundingBoxForCompositing(const RenderLayer* ancestorLayer = 0, CalculateBoundsOptions = DoNotApplyBoundsChickenEggHacks) const;

    LayoutUnit staticInlinePosition() const { return m_staticInlinePosition; }
    LayoutUnit staticBlockPosition() const { return m_staticBlockPosition; }

    void setStaticInlinePosition(LayoutUnit position) { m_staticInlinePosition = position; }
    void setStaticBlockPosition(LayoutUnit position) { m_staticBlockPosition = position; }

    LayoutSize subpixelAccumulation() const;
    void setSubpixelAccumulation(const LayoutSize&);

    bool hasTransform() const { return renderer()->hasTransform(); }
    // Note that this transform has the transform-origin baked in.
    TransformationMatrix* transform() const { return m_transform.get(); }
    // currentTransform computes a transform which takes accelerated animations into account. The
    // resulting transform has transform-origin baked in. If the layer does not have a transform,
    // returns the identity matrix.
    TransformationMatrix currentTransform(RenderStyle::ApplyTransformOrigin = RenderStyle::IncludeTransformOrigin) const;
    TransformationMatrix renderableTransform(PaintBehavior) const;

    // Get the perspective transform, which is applied to transformed sublayers.
    // Returns true if the layer has a -webkit-perspective.
    // Note that this transform has the perspective-origin baked in.
    TransformationMatrix perspectiveTransform() const;
    FloatPoint perspectiveOrigin() const;
    bool preserves3D() const { return renderer()->style()->transformStyle3D() == TransformStyle3DPreserve3D; }
    bool has3DTransform() const { return m_transform && !m_transform->isAffine(); }

    // FIXME: reflections should force transform-style to be flat in the style: https://bugs.webkit.org/show_bug.cgi?id=106959
    bool shouldPreserve3D() const { return renderer()->style()->transformStyle3D() == TransformStyle3DPreserve3D; }

    void filterNeedsPaintInvalidation();
    bool hasFilter() const { return renderer()->hasFilter(); }

    void* operator new(size_t);
    // Only safe to call from RenderLayerModelObject::destroyLayer()
    void operator delete(void*);

    CompositingState compositingState() const;

    // This returns true if our document is in a phase of its lifestyle during which
    // compositing state may legally be read.
    bool isAllowedToQueryCompositingState() const;

    // Don't null check this.
    CompositedLayerMapping* compositedLayerMapping() const;
    // FIXME: This should return a reference.
    CompositedLayerMapping* ensureCompositedLayerMapping();
    GraphicsLayer* graphicsLayerBacking() const;
    // NOTE: If you are using hasCompositedLayerMapping to determine the state of compositing for this layer,
    // (and not just to do bookkeeping related to the mapping like, say, allocating or deallocating a mapping),
    // then you may have incorrect logic. Use compositingState() instead.
    // FIXME: This is identical to null checking compositedLayerMapping(), why not just call that?
    bool hasCompositedLayerMapping() const { return m_compositedLayerMapping.get(); }
    void clearCompositedLayerMapping(bool layerBeingDestroyed = false);
    CompositedLayerMapping* groupedMapping() const { return m_groupedMapping; }
    void setGroupedMapping(CompositedLayerMapping* groupedMapping, bool layerBeingDestroyed = false);

    bool hasCompositedMask() const;
    bool hasCompositedClippingMask() const;
    bool needsCompositedScrolling() const { return m_scrollableArea && m_scrollableArea->needsCompositedScrolling(); }

    bool clipsCompositingDescendantsWithBorderRadius() const;

    // Computes the position of the given render object in the space of |paintInvalidationContainer|.
    // FIXME: invert the logic to have paint invalidation containers take care of painting objects into them, rather than the reverse.
    // This will allow us to clean up this static method messiness.
    static LayoutPoint positionFromPaintInvalidationContainer(const RenderObject*, const RenderLayerModelObject* paintInvalidationContainer, const PaintInvalidationState* = 0);

    static void mapRectToPaintBackingCoordinates(const RenderLayerModelObject* paintInvalidationContainer, LayoutRect&);

    // Adjusts the given rect (in the coordinate space of the RenderObject) to the coordinate space of |paintInvalidationContainer|'s GraphicsLayer backing.
    static void mapRectToPaintInvalidationBacking(const RenderObject*, const RenderLayerModelObject* paintInvalidationContainer, LayoutRect&, const PaintInvalidationState* = 0);

    // Computes the bounding paint invalidation rect for |renderObject|, in the coordinate space of |paintInvalidationContainer|'s GraphicsLayer backing.
    static LayoutRect computePaintInvalidationRect(const RenderObject*, const RenderLayer* paintInvalidationContainer, const PaintInvalidationState* = 0);

    bool paintsWithTransparency(PaintBehavior paintBehavior) const
    {
        return isTransparent() && ((paintBehavior & PaintBehaviorFlattenCompositingLayers) || compositingState() != PaintsIntoOwnBacking);
    }

    bool paintsWithTransform(PaintBehavior) const;

    // Returns true if background phase is painted opaque in the given rect.
    // The query rect is given in local coordinates.
    bool backgroundIsKnownToBeOpaqueInRect(const LayoutRect&) const;

    bool containsDirtyOverlayScrollbars() const { return m_containsDirtyOverlayScrollbars; }
    void setContainsDirtyOverlayScrollbars(bool dirtyScrollbars) { m_containsDirtyOverlayScrollbars = dirtyScrollbars; }

    FilterOperations computeFilterOperations(const RenderStyle*);
    bool paintsWithFilters() const;
    bool requiresFullLayerImageForFilters() const;
    FilterEffectRenderer* filterRenderer() const
    {
        RenderLayerFilterInfo* filterInfo = this->filterInfo();
        return filterInfo ? filterInfo->renderer() : 0;
    }

    RenderLayerFilterInfo* filterInfo() const { return hasFilterInfo() ? RenderLayerFilterInfo::filterInfoForRenderLayer(this) : 0; }
    RenderLayerFilterInfo* ensureFilterInfo() { return RenderLayerFilterInfo::createFilterInfoForRenderLayerIfNeeded(this); }
    void removeFilterInfoIfNeeded()
    {
        if (hasFilterInfo())
            RenderLayerFilterInfo::removeFilterInfoForRenderLayer(this);
    }

    bool hasFilterInfo() const { return m_hasFilterInfo; }
    void setHasFilterInfo(bool hasFilterInfo) { m_hasFilterInfo = hasFilterInfo; }

    void updateFilters(const RenderStyle* oldStyle, const RenderStyle* newStyle);

    Node* enclosingElement() const;

    bool scrollsWithViewport() const;
    bool scrollsWithRespectTo(const RenderLayer*) const;

    // FIXME: This should probably return a ScrollableArea but a lot of internal methods are mistakenly exposed.
    RenderLayerScrollableArea* scrollableArea() const { return m_scrollableArea.get(); }
    RenderLayerRepainter& paintInvalidator() { return m_paintInvalidator; }
    RenderLayerClipper& clipper() { return m_clipper; }
    const RenderLayerClipper& clipper() const { return m_clipper; }

    inline bool isPositionedContainer() const
    {
        // FIXME: This is not in sync with containingBlock.
        RenderLayerModelObject* layerRenderer = renderer();
        return isRootLayer() || layerRenderer->isPositioned() || hasTransform();
    }

    // paintLayer() assumes that the caller will clip to the bounds of the painting dirty if necessary.
    void paintLayer(GraphicsContext*, const LayerPaintingInfo&, PaintLayerFlags);

    bool scrollsOverflow() const;

    CompositingReasons potentialCompositingReasonsFromStyle() const { return m_potentialCompositingReasonsFromStyle; }
    void setPotentialCompositingReasonsFromStyle(CompositingReasons reasons) { ASSERT(reasons == (reasons & CompositingReasonComboAllStyleDeterminedReasons)); m_potentialCompositingReasonsFromStyle = reasons; }

    bool hasStyleDeterminedDirectCompositingReasons() const { return m_potentialCompositingReasonsFromStyle & CompositingReasonComboAllDirectStyleDeterminedReasons; }

    class AncestorDependentCompositingInputs {
    public:
        AncestorDependentCompositingInputs()
            : opacityAncestor(0)
            , transformAncestor(0)
            , filterAncestor(0)
            , clippingContainer(0)
            , ancestorScrollingLayer(0)
            , scrollParent(0)
            , clipParent(0)
            , isUnclippedDescendant(false)
            , hasAncestorWithClipPath(false)
        { }

        IntRect clippedAbsoluteBoundingBox;
        const RenderLayer* opacityAncestor;
        const RenderLayer* transformAncestor;
        const RenderLayer* filterAncestor;
        const RenderObject* clippingContainer;
        const RenderLayer* ancestorScrollingLayer;

        // A scroll parent is a compositor concept. It's only needed in blink
        // because we need to use it as a promotion trigger. A layer has a
        // scroll parent if neither its compositor scrolling ancestor, nor any
        // other layer scrolled by this ancestor, is a stacking ancestor of this
        // layer. Layers with scroll parents must be scrolled with the main
        // scrolling layer by the compositor.
        const RenderLayer* scrollParent;

        // A clip parent is another compositor concept that has leaked into
        // blink so that it may be used as a promotion trigger. Layers with clip
        // parents escape the clip of a stacking tree ancestor. The compositor
        // needs to know about clip parents in order to circumvent its normal
        // clipping logic.
        const RenderLayer* clipParent;

        // The "is unclipped descendant" concept is now only being used for one
        // purpose: when traversing the RenderLayers in stacking order, we check
        // if we scroll wrt to these unclipped descendants. We do this to
        // proactively promote in the same way that we do for animated layers.
        // Since we have no idea where scrolled content will scroll to, we just
        // assume that it can overlap the unclipped thing at some point, so we
        // promote. But this is unfortunate. We should be able to inflate the
        // bounds of scrolling content for overlap the same way we're doing for
        // animation and only promote what's necessary. Once we're doing that,
        // we won't need to use the "unclipped" concept for promotion any
        // longer.
        unsigned isUnclippedDescendant : 1;
        unsigned hasAncestorWithClipPath : 1;
    };

    class DescendantDependentCompositingInputs {
    public:
        DescendantDependentCompositingInputs()
            : hasDescendantWithClipPath(false)

        { }

        unsigned hasDescendantWithClipPath : 1;
    };

    void setNeedsCompositingInputsUpdate();
    bool childNeedsCompositingInputsUpdate() const { return m_childNeedsCompositingInputsUpdate; }
    bool needsCompositingInputsUpdate() const
    {
        // While we're updating the compositing inputs, these values may differ.
        // We should never be asking for this value when that is the case.
        ASSERT(m_needsDescendantDependentCompositingInputsUpdate == m_needsAncestorDependentCompositingInputsUpdate);
        return m_needsDescendantDependentCompositingInputsUpdate;
    }

    void updateAncestorDependentCompositingInputs(const AncestorDependentCompositingInputs&);
    void updateDescendantDependentCompositingInputs(const DescendantDependentCompositingInputs&);
    void didUpdateCompositingInputs();

    const AncestorDependentCompositingInputs& ancestorDependentCompositingInputs() const { ASSERT(!m_needsAncestorDependentCompositingInputsUpdate); return m_ancestorDependentCompositingInputs; }
    const DescendantDependentCompositingInputs& descendantDependentCompositingInputs() const { ASSERT(!m_needsDescendantDependentCompositingInputsUpdate); return m_descendantDependentCompositingInputs; }

    IntRect clippedAbsoluteBoundingBox() const { return ancestorDependentCompositingInputs().clippedAbsoluteBoundingBox; }
    const RenderLayer* opacityAncestor() const { return ancestorDependentCompositingInputs().opacityAncestor; }
    const RenderLayer* transformAncestor() const { return ancestorDependentCompositingInputs().transformAncestor; }
    const RenderLayer* filterAncestor() const { return ancestorDependentCompositingInputs().filterAncestor; }
    const RenderObject* clippingContainer() const { return ancestorDependentCompositingInputs().clippingContainer; }
    const RenderLayer* ancestorScrollingLayer() const { return ancestorDependentCompositingInputs().ancestorScrollingLayer; }
    RenderLayer* scrollParent() const { return const_cast<RenderLayer*>(ancestorDependentCompositingInputs().scrollParent); }
    RenderLayer* clipParent() const { return const_cast<RenderLayer*>(ancestorDependentCompositingInputs().clipParent); }
    bool isUnclippedDescendant() const { return ancestorDependentCompositingInputs().isUnclippedDescendant; }
    bool hasAncestorWithClipPath() const { return ancestorDependentCompositingInputs().hasAncestorWithClipPath; }
    bool hasDescendantWithClipPath() const { return descendantDependentCompositingInputs().hasDescendantWithClipPath; }

    bool lostGroupedMapping() const { ASSERT(isAllowedToQueryCompositingState()); return m_lostGroupedMapping; }
    void setLostGroupedMapping(bool b) { m_lostGroupedMapping = b; }

    CompositingReasons compositingReasons() const { ASSERT(isAllowedToQueryCompositingState()); return m_compositingReasons; }
    void setCompositingReasons(CompositingReasons, CompositingReasons mask = CompositingReasonAll);

    bool hasCompositingDescendant() const { ASSERT(isAllowedToQueryCompositingState()); return m_hasCompositingDescendant; }
    void setHasCompositingDescendant(bool);

    void updateOrRemoveFilterEffectRenderer();

    void updateSelfPaintingLayer();

    // paintLayerContents() assumes that the caller will clip to the bounds of the painting dirty rect if necessary.
    void paintLayerContents(GraphicsContext*, const LayerPaintingInfo&, PaintLayerFlags);

    RenderLayer* enclosingTransformedAncestor() const;
    LayoutPoint computeOffsetFromTransformedAncestor() const;

    void didUpdateNeedsCompositedScrolling();

    void setShouldDoFullPaintInvalidationIncludingNonCompositingDescendants();

private:
    // Bounding box in the coordinates of this layer.
    LayoutRect logicalBoundingBox() const;

    bool hasOverflowControls() const;

    void setAncestorChainHasSelfPaintingLayerDescendant();
    void dirtyAncestorChainHasSelfPaintingLayerDescendantStatus();

    void clipToRect(const LayerPaintingInfo&, GraphicsContext*, const ClipRect&, PaintLayerFlags, BorderRadiusClippingRule = IncludeSelfForBorderRadius);
    void restoreClip(GraphicsContext*, const LayoutRect& paintDirtyRect, const ClipRect&);

    void setNextSibling(RenderLayer* next) { m_next = next; }
    void setPreviousSibling(RenderLayer* prev) { m_previous = prev; }
    void setFirstChild(RenderLayer* first) { m_first = first; }
    void setLastChild(RenderLayer* last) { m_last = last; }

    void updateHasSelfPaintingLayerDescendant() const;

    bool hasSelfPaintingLayerDescendant() const
    {
        if (m_hasSelfPaintingLayerDescendantDirty)
            updateHasSelfPaintingLayerDescendant();
        ASSERT(!m_hasSelfPaintingLayerDescendantDirty);
        return m_hasSelfPaintingLayerDescendant;
    }

    LayoutPoint renderBoxLocation() const { return renderer()->isBox() ? toRenderBox(renderer())->location() : LayoutPoint(); }

    void paintLayerContentsAndReflection(GraphicsContext*, const LayerPaintingInfo&, PaintLayerFlags);
    void paintLayerByApplyingTransform(GraphicsContext*, const LayerPaintingInfo&, PaintLayerFlags, const LayoutPoint& translationOffset = LayoutPoint());

    // Returns whether this layer should be painted during sofware painting (i.e., not via calls from CompositedLayerMapping to draw into composited
    // layers).
    bool shouldPaintLayerInSoftwareMode(const LayerPaintingInfo&, PaintLayerFlags paintFlags);

    void paintChildren(unsigned childrenToVisit, GraphicsContext*, const LayerPaintingInfo&, PaintLayerFlags);

    void collectFragments(LayerFragments&, const RenderLayer* rootLayer, const LayoutRect& dirtyRect,
        ClipRectsCacheSlot, ShouldRespectOverflowClip = RespectOverflowClip, const LayoutPoint* offsetFromRoot = 0,
        const LayoutSize& subPixelAccumulation = LayoutSize(), const LayoutRect* layerBoundingBox = 0);
    void updatePaintingInfoForFragments(LayerFragments&, const LayerPaintingInfo&, PaintLayerFlags, bool shouldPaintContent, const LayoutPoint* offsetFromRoot);
    void paintBackgroundForFragments(const LayerFragments&, GraphicsContext*, GraphicsContext* transparencyLayerContext,
        const LayoutRect& transparencyPaintDirtyRect, bool haveTransparency, const LayerPaintingInfo&, PaintBehavior, RenderObject* paintingRootForRenderer, PaintLayerFlags);
    void paintForegroundForFragments(const LayerFragments&, GraphicsContext*, GraphicsContext* transparencyLayerContext,
        const LayoutRect& transparencyPaintDirtyRect, bool haveTransparency, const LayerPaintingInfo&, PaintBehavior, RenderObject* paintingRootForRenderer,
        bool selectionOnly, PaintLayerFlags);
    void paintForegroundForFragmentsWithPhase(PaintPhase, const LayerFragments&, GraphicsContext*, const LayerPaintingInfo&, PaintBehavior, RenderObject* paintingRootForRenderer, PaintLayerFlags);
    void paintOutlineForFragments(const LayerFragments&, GraphicsContext*, const LayerPaintingInfo&, PaintBehavior, RenderObject* paintingRootForRenderer, PaintLayerFlags);
    void paintOverflowControlsForFragments(const LayerFragments&, GraphicsContext*, const LayerPaintingInfo&, PaintLayerFlags);
    void paintMaskForFragments(const LayerFragments&, GraphicsContext*, const LayerPaintingInfo&, RenderObject* paintingRootForRenderer, PaintLayerFlags);
    void paintChildClippingMaskForFragments(const LayerFragments&, GraphicsContext*, const LayerPaintingInfo&, RenderObject* paintingRootForRenderer, PaintLayerFlags);

    RenderLayer* hitTestLayer(RenderLayer* rootLayer, RenderLayer* containerLayer, const HitTestRequest& request, HitTestResult& result,
                              const LayoutRect& hitTestRect, const HitTestLocation&, bool appliedTransform,
                              const HitTestingTransformState* transformState = 0, double* zOffset = 0);
    RenderLayer* hitTestLayerByApplyingTransform(RenderLayer* rootLayer, RenderLayer* containerLayer, const HitTestRequest&, HitTestResult&,
        const LayoutRect& hitTestRect, const HitTestLocation&, const HitTestingTransformState* = 0, double* zOffset = 0,
        const LayoutPoint& translationOffset = LayoutPoint());
    RenderLayer* hitTestChildren(ChildrenIteration, RenderLayer* rootLayer, const HitTestRequest&, HitTestResult&,
                             const LayoutRect& hitTestRect, const HitTestLocation&,
                             const HitTestingTransformState* transformState, double* zOffsetForDescendants, double* zOffset,
                             const HitTestingTransformState* unflattenedTransformState, bool depthSortDescendants);

    PassRefPtr<HitTestingTransformState> createLocalTransformState(RenderLayer* rootLayer, RenderLayer* containerLayer,
                            const LayoutRect& hitTestRect, const HitTestLocation&,
                            const HitTestingTransformState* containerTransformState,
                            const LayoutPoint& translationOffset = LayoutPoint()) const;

    bool hitTestContents(const HitTestRequest&, HitTestResult&, const LayoutRect& layerBounds, const HitTestLocation&, HitTestFilter) const;
    bool hitTestContentsForFragments(const LayerFragments&, const HitTestRequest&, HitTestResult&, const HitTestLocation&, HitTestFilter, bool& insideClipRect) const;

    bool childBackgroundIsKnownToBeOpaqueInRect(const LayoutRect&) const;

    bool shouldBeSelfPaintingLayer() const;

    // FIXME: We should only create the stacking node if needed.
    bool requiresStackingNode() const { return true; }
    void updateStackingNode();

    // FIXME: We could lazily allocate our ScrollableArea based on style properties ('overflow', ...)
    // but for now, we are always allocating it for RenderBox as it's safer.
    bool requiresScrollableArea() const { return renderBox(); }
    void updateScrollableArea();

    bool attemptDirectCompositingUpdate(StyleDifference, const RenderStyle* oldStyle);
    void updateTransform(const RenderStyle* oldStyle, RenderStyle* newStyle);

    void dirty3DTransformedDescendantStatus();
    // Both updates the status, and returns true if descendants of this have 3d.
    bool update3DTransformedDescendantStatus();

    void updateOrRemoveFilterClients();

    LayoutRect paintingExtent(const RenderLayer* rootLayer, const LayoutRect& paintDirtyRect, const LayoutSize& subPixelAccumulation, PaintBehavior);

    LayerType m_layerType;

    // Self-painting layer is an optimization where we avoid the heavy RenderLayer painting
    // machinery for a RenderLayer allocated only to handle the overflow clip case.
    // FIXME(crbug.com/332791): Self-painting layer should be merged into the overflow-only concept.
    unsigned m_isSelfPaintingLayer : 1;

    // If have no self-painting descendants, we don't have to walk our children during painting. This can lead to
    // significant savings, especially if the tree has lots of non-self-painting layers grouped together (e.g. table cells).
    mutable unsigned m_hasSelfPaintingLayerDescendant : 1;
    mutable unsigned m_hasSelfPaintingLayerDescendantDirty : 1;

    const unsigned m_isRootLayer : 1;

    unsigned m_usedTransparency : 1; // Tracks whether we need to close a transparent layer, i.e., whether
                                 // we ended up painting this layer or any descendants (and therefore need to
                                 // blend).

    unsigned m_3DTransformedDescendantStatusDirty : 1;
    // Set on a stacking context layer that has 3D descendants anywhere
    // in a preserves3D hierarchy. Hint to do 3D-aware hit testing.
    unsigned m_has3DTransformedDescendant : 1;

    unsigned m_containsDirtyOverlayScrollbars : 1;

    unsigned m_hasFilterInfo : 1;
    unsigned m_needsAncestorDependentCompositingInputsUpdate : 1;
    unsigned m_needsDescendantDependentCompositingInputsUpdate : 1;
    unsigned m_childNeedsCompositingInputsUpdate : 1;

    // Used only while determining what layers should be composited. Applies to the tree of z-order lists.
    unsigned m_hasCompositingDescendant : 1;

    // True if this render layer just lost its grouped mapping due to the CompositedLayerMapping being destroyed,
    // and we don't yet know to what graphics layer this RenderLayer will be assigned.
    unsigned m_lostGroupedMapping : 1;

    RenderLayerModelObject* m_renderer;

    RenderLayer* m_parent;
    RenderLayer* m_previous;
    RenderLayer* m_next;
    RenderLayer* m_first;
    RenderLayer* m_last;

    // Cached normal flow values for absolute positioned elements with static left/top values.
    LayoutUnit m_staticInlinePosition;
    LayoutUnit m_staticBlockPosition;

    OwnPtr<TransformationMatrix> m_transform;

    // These compositing reasons are updated whenever style changes, not while updating compositing layers.
    // They should not be used to infer the compositing state of this layer.
    CompositingReasons m_potentialCompositingReasonsFromStyle;

    // Once computed, indicates all that a layer needs to become composited using the CompositingReasons enum bitfield.
    CompositingReasons m_compositingReasons;

    DescendantDependentCompositingInputs m_descendantDependentCompositingInputs;
    AncestorDependentCompositingInputs m_ancestorDependentCompositingInputs;

    IntRect m_blockSelectionGapsBounds;

    OwnPtr<CompositedLayerMapping> m_compositedLayerMapping;
    OwnPtr<RenderLayerScrollableArea> m_scrollableArea;

    CompositedLayerMapping* m_groupedMapping;

    RenderLayerRepainter m_paintInvalidator;
    RenderLayerClipper m_clipper; // FIXME: Lazily allocate?
    OwnPtr<RenderLayerStackingNode> m_stackingNode;

    LayoutSize m_subpixelAccumulation; // The accumulated subpixel offset of a composited layer's composited bounds compared to absolute coordinates.
};

} // namespace blink

#ifndef NDEBUG
// Outside the WebCore namespace for ease of invocation from gdb.
void showLayerTree(const blink::RenderLayer*);
void showLayerTree(const blink::RenderObject*);
#endif

#endif // RenderLayer_h
