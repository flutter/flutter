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

#ifndef CompositedLayerMapping_h
#define CompositedLayerMapping_h

#include "core/rendering/RenderLayer.h"
#include "core/rendering/compositing/GraphicsLayerUpdater.h"
#include "platform/geometry/FloatPoint.h"
#include "platform/geometry/FloatPoint3D.h"
#include "platform/graphics/GraphicsLayer.h"
#include "platform/graphics/GraphicsLayerClient.h"

namespace blink {

class RenderLayerCompositor;

// A GraphicsLayerPaintInfo contains all the info needed to paint a partial subtree of RenderLayers into a GraphicsLayer.
struct GraphicsLayerPaintInfo {
    RenderLayer* renderLayer;

    LayoutRect compositedBounds;

    // The clip rect to apply, in the local coordinate space of the squashed layer, when painting it.
    IntRect localClipRectForSquashedLayer;

    // Offset describing where this squashed RenderLayer paints into the shared GraphicsLayer backing.
    IntSize offsetFromRenderer;
    bool offsetFromRendererSet;

    GraphicsLayerPaintInfo() : renderLayer(0), offsetFromRendererSet(false) { }
};

enum GraphicsLayerUpdateScope {
    GraphicsLayerUpdateNone,
    GraphicsLayerUpdateLocal,
    GraphicsLayerUpdateSubtree,
};

// CompositedLayerMapping keeps track of how RenderLayers of the render tree correspond to
// GraphicsLayers of the composited layer tree. Each instance of CompositedLayerMapping
// manages a small cluster of GraphicsLayers and the references to which RenderLayers
// and paint phases contribute to each GraphicsLayer.
//
// Currently (Oct. 2013) there is one CompositedLayerMapping for each RenderLayer,
// but this is likely to evolve soon.
class CompositedLayerMapping final : public GraphicsLayerClient {
    WTF_MAKE_NONCOPYABLE(CompositedLayerMapping); WTF_MAKE_FAST_ALLOCATED;
public:
    explicit CompositedLayerMapping(RenderLayer&);
    virtual ~CompositedLayerMapping();

    RenderLayer& owningLayer() const { return m_owningLayer; }

    bool updateGraphicsLayerConfiguration();
    void updateGraphicsLayerGeometry(const RenderLayer* compositingContainer, const RenderLayer* compositingStackingContext, Vector<RenderLayer*>& layersNeedingPaintInvalidation);

    // Update whether layer needs blending.
    void updateContentsOpaque();

    GraphicsLayer* mainGraphicsLayer() const { return m_graphicsLayer.get(); }

    // Layer to clip children
    bool hasClippingLayer() const { return m_childContainmentLayer; }
    GraphicsLayer* clippingLayer() const { return m_childContainmentLayer.get(); }

    // Layer to get clipped by ancestor
    bool hasAncestorClippingLayer() const { return m_ancestorClippingLayer; }
    GraphicsLayer* ancestorClippingLayer() const { return m_ancestorClippingLayer.get(); }

    bool hasContentsLayer() const { return m_foregroundLayer; }
    GraphicsLayer* foregroundLayer() const { return m_foregroundLayer.get(); }

    GraphicsLayer* backgroundLayer() const { return m_backgroundLayer.get(); }
    bool backgroundLayerPaintsFixedRootBackground() const { return m_backgroundLayerPaintsFixedRootBackground; }

    bool hasMaskLayer() const { return m_maskLayer; }
    GraphicsLayer* maskLayer() const { return m_maskLayer.get(); }

    bool hasChildClippingMaskLayer() const { return m_childClippingMaskLayer; }
    GraphicsLayer* childClippingMaskLayer() const { return m_childClippingMaskLayer.get(); }

    GraphicsLayer* parentForSublayers() const;
    GraphicsLayer* childForSuperlayers() const;

    GraphicsLayer* childTransformLayer() const { return m_childTransformLayer.get(); }

    GraphicsLayer* squashingContainmentLayer() const { return m_squashingContainmentLayer.get(); }
    GraphicsLayer* squashingLayer() const { return m_squashingLayer.get(); }
    // Contains the bottommost layer in the hierarchy that can contain the children transform.
    GraphicsLayer* layerForChildrenTransform() const;

    // Returns true for a composited layer that has no backing store of its own, so
    // paints into some ancestor layer.
    bool paintsIntoCompositedAncestor() const { return !(m_requiresOwnBackingStoreForAncestorReasons || m_requiresOwnBackingStoreForIntrinsicReasons); }

    // Updates whether a backing store is needed based on the layer's compositing ancestor's
    // properties; returns true if the need for a backing store for ancestor reasons changed.
    bool updateRequiresOwnBackingStoreForAncestorReasons(const RenderLayer* compositingAncestor);

    // Updates whether a backing store is needed for intrinsic reasons (that is, based on the
    // layer's own properties or compositing reasons); returns true if the intrinsic need for
    // a backing store changed.
    bool updateRequiresOwnBackingStoreForIntrinsicReasons();

    void setSquashingContentsNeedDisplay();
    void setContentsNeedDisplay();
    // r is in the coordinate space of the layer's render object
    void setContentsNeedDisplayInRect(const LayoutRect&);

    // Notification from the renderer that its content changed.
    void contentChanged(ContentChangeType);

    LayoutRect compositedBounds() const { return m_compositedBounds; }
    IntRect pixelSnappedCompositedBounds() const;

    // Returns true if the assignment actually changed the assigned squashing layer.
    bool updateSquashingLayerAssignment(RenderLayer* squashedLayer, const RenderLayer& owningLayer, size_t nextSquashedLayerIndex);
    void removeRenderLayerFromSquashingGraphicsLayer(const RenderLayer*);

    void finishAccumulatingSquashingLayers(size_t nextSquashedLayerIndex);
    void updateRenderingContext();
    void updateShouldFlattenTransform();

    // GraphicsLayerClient interface
    virtual void notifyAnimationStarted(const GraphicsLayer*, double monotonicTime) override;
    virtual void paintContents(const GraphicsLayer*, GraphicsContext&, GraphicsLayerPaintingPhase, const IntRect& clip) override;
    virtual bool isTrackingPaintInvalidations() const override;

#if ENABLE(ASSERT)
    virtual void verifyNotPainting() override;
#endif

    LayoutRect contentsBox() const;

    // Returns true if the overflow controls cannot be positioned within this
    // CLM's internal hierarchy without incorrectly stacking under some
    // scrolling content. If this returns true, these controls must be
    // repositioned in the graphics layer tree to ensure that they stack above
    // scrolling content.
    bool needsToReparentOverflowControls() const;

    // Removes the overflow controls host layer from its parent and positions it
    // so that it can be inserted as a sibling to this CLM without changing
    // position.
    GraphicsLayer* detachLayerForOverflowControls(const RenderLayer& enclosingLayer);

    void updateFilters(const RenderStyle*);

    void setBlendMode(WebBlendMode);

    bool needsGraphicsLayerUpdate() { return m_pendingUpdateScope > GraphicsLayerUpdateNone; }
    void setNeedsGraphicsLayerUpdate(GraphicsLayerUpdateScope scope) { m_pendingUpdateScope = std::max(static_cast<GraphicsLayerUpdateScope>(m_pendingUpdateScope), scope); }
    void clearNeedsGraphicsLayerUpdate() { m_pendingUpdateScope = GraphicsLayerUpdateNone; }

    GraphicsLayerUpdater::UpdateType updateTypeForChildren(GraphicsLayerUpdater::UpdateType) const;

#if ENABLE(ASSERT)
    void assertNeedsToUpdateGraphicsLayerBitsCleared() {  ASSERT(m_pendingUpdateScope == GraphicsLayerUpdateNone); }
#endif

    virtual String debugName(const GraphicsLayer*) override;

    LayoutSize contentOffsetInCompositingLayer() const;

    LayoutPoint squashingOffsetFromTransformedAncestor()
    {
        return m_squashingLayerOffsetFromTransformedAncestor;
    }

    // If there is a squashed layer painting into this CLM that is an ancestor of the given RenderObject, return it. Otherwise return 0.
    const GraphicsLayerPaintInfo* containingSquashedLayer(const RenderObject*);

private:
    static const GraphicsLayerPaintInfo* containingSquashedLayer(const RenderObject*,  const Vector<GraphicsLayerPaintInfo>& layers);

    // Helper methods to updateGraphicsLayerGeometry:
    void computeGraphicsLayerParentLocation(const RenderLayer* compositingContainer, const IntRect& ancestorCompositingBounds, IntPoint& graphicsLayerParentLocation);
    void updateSquashingLayerGeometry(const LayoutPoint& offsetFromCompositedAncestor, const IntPoint& graphicsLayerParentLocation, const RenderLayer& referenceLayer, Vector<GraphicsLayerPaintInfo>& layers, GraphicsLayer*, LayoutPoint* offsetFromTransformedAncestor, Vector<RenderLayer*>& layersNeedingPaintInvalidation);
    void updateMainGraphicsLayerGeometry(const IntRect& relativeCompositingBounds, const IntRect& localCompositingBounds, const IntPoint& graphicsLayerParentLocation);
    void updateAncestorClippingLayerGeometry(const RenderLayer* compositingContainer, const IntPoint& snappedOffsetFromCompositedAncestor, IntPoint& graphicsLayerParentLocation);
    void updateOverflowControlsHostLayerGeometry(const RenderLayer* compositingStackingContext);
    void updateChildContainmentLayerGeometry(const IntRect& clippingBox, const IntRect& localCompositingBounds);
    void updateChildTransformLayerGeometry();
    void updateMaskLayerGeometry();
    void updateTransformGeometry(const IntPoint& snappedOffsetFromCompositedAncestor, const IntRect& relativeCompositingBounds);
    void updateForegroundLayerGeometry(const FloatSize& relativeCompositingBoundsSize, const IntRect& clippingBox);
    void updateBackgroundLayerGeometry(const FloatSize& relativeCompositingBoundsSize);
    void updateChildClippingMaskLayerGeometry();

    void createPrimaryGraphicsLayer();
    void destroyGraphicsLayers();

    PassOwnPtr<GraphicsLayer> createGraphicsLayer(CompositingReasons);

    RenderLayerModelObject* renderer() const { return m_owningLayer.renderer(); }
    RenderLayerCompositor* compositor() const { return m_owningLayer.compositor(); }

    void updateInternalHierarchy();
    void updatePaintingPhases();
    bool updateClippingLayers(bool needsAncestorClip, bool needsDescendantClip);
    bool updateChildTransformLayer(bool needsChildTransformLayer);
    bool updateForegroundLayer(bool needsForegroundLayer);
    bool updateBackgroundLayer(bool needsBackgroundLayer);
    bool updateMaskLayer(bool needsMaskLayer);
    bool updateClippingMaskLayers(bool needsChildClippingMaskLayer);
    void updateClipParent();
    bool updateSquashingLayers(bool needsSquashingLayers);
    void updateDrawsContent();
    void updateChildrenTransform();
    void updateCompositedBounds();

    // Also sets subpixelAccumulation on the layer.
    void computeBoundsOfOwningLayer(const RenderLayer* compositedAncestor, IntRect& localCompositingBounds, IntRect& compositingBoundsRelativeToCompositedAncestor, LayoutPoint& offsetFromCompositedAncestor, IntPoint& snappedOffsetFromCompositedAncestor);

    void setBackgroundLayerPaintsFixedRootBackground(bool);

    GraphicsLayerPaintingPhase paintingPhaseForPrimaryLayer() const;

    // Result is transform origin in pixels.
    FloatPoint3D computeTransformOrigin(const IntRect& borderBox) const;

    void updateOpacity(const RenderStyle*);
    void updateTransform(const RenderStyle*);
    void updateLayerBlendMode(const RenderStyle*);
    void updateIsRootForIsolatedGroup();
    // Return the opacity value that this layer should use for compositing.
    float compositingOpacity(float rendererOpacity) const;

    bool paintsChildren() const;

    // Returns true if this layer has content that needs to be rendered by painting into the backing store.
    bool containsPaintedContent() const;
    // Returns true if the RenderLayer just contains an image that we can composite directly.
    bool isDirectlyCompositedImage() const;
    void updateImageContents();

    Color rendererBackgroundColor() const;
    void updateBackgroundColor();
    void updateContentsRect();
    void updateContentsOffsetInCompositingLayer(const IntPoint& snappedOffsetFromCompositedAncestor, const IntPoint& graphicsLayerParentLocation);
    void updateCompositingReasons();

    void doPaintTask(const GraphicsLayerPaintInfo&, const PaintLayerFlags&, GraphicsContext*, const IntRect& clip);

    // Computes the background clip rect for the given squashed layer, up to any containing layer that is squashed into the
    // same squashing layer and contains this squashed layer's clipping ancestor.
    // The clip rect is returned in the coordinate space of the given squashed layer.
    // If there is no such containing layer, returns the infinite rect.
    // FIXME: unify this code with the code that sets up m_ancestorClippingLayer. They are doing very similar things.
    static IntRect localClipRectForSquashedLayer(const RenderLayer& referenceLayer, const GraphicsLayerPaintInfo&,  const Vector<GraphicsLayerPaintInfo>& layers);

    // Return true if |m_owningLayer|'s compositing ancestor is not a descendant (inclusive) of the
    // clipping container for |m_owningLayer|.
    bool owningLayerClippedByLayerNotAboveCompositedAncestor();

    RenderLayer& m_owningLayer;

    // The hierarchy of layers that is maintained by the CompositedLayerMapping looks like this:
    //
    //  + m_ancestorClippingLayer [OPTIONAL]
    //     + m_graphicsLayer
    //        + m_childContainmentLayer [OPTIONAL] <-OR-> m_childTransformLayer
    //        |
    //        + m_overflowControlsClippingLayer [OPTIONAL] // *The overflow controls may need to be repositioned in the
    //          + m_overflowControlsHostLayer              //  graphics layer tree by the RLC to ensure that they stack
    //
    // We need an ancestor clipping layer if our clipping ancestor is not our ancestor in the
    // clipping tree. Here's what that might look like.
    //
    // Let A = the clipping ancestor,
    //     B = the clip descendant, and
    //     SC = the stacking context that is the ancestor of A and B in the stacking tree.
    //
    // SC
    //  + A = m_graphicsLayer
    //  |  + m_childContainmentLayer
    //  |     + ...
    //  ...
    //  |
    //  + B = m_ancestorClippingLayer [+]
    //     + m_graphicsLayer
    //        + ...
    //
    // In this case B is clipped by another layer that doesn't happen to be its ancestor: A.
    // So we create an ancestor clipping layer for B, [+], which ensures that B is clipped
    // as if it had been A's descendant.
    OwnPtr<GraphicsLayer> m_ancestorClippingLayer; // Only used if we are clipped by an ancestor which is not a stacking context.
    OwnPtr<GraphicsLayer> m_graphicsLayer;
    OwnPtr<GraphicsLayer> m_childContainmentLayer; // Only used if we have clipping on a stacking context with compositing children.
    OwnPtr<GraphicsLayer> m_childTransformLayer; // Only used if we have perspective and no m_childContainmentLayer.

    // This layer is also added to the hierarchy by the RLB, but in a different way than
    // the layers above. It's added to m_graphicsLayer as its mask layer (naturally) if
    // we have a mask, and isn't part of the typical hierarchy (it has no children).
    OwnPtr<GraphicsLayer> m_maskLayer; // Only used if we have a mask.
    OwnPtr<GraphicsLayer> m_childClippingMaskLayer; // Only used if we have to clip child layers or accelerated contents with border radius or clip-path.

    // There are two other (optional) layers whose painting is managed by the CompositedLayerMapping,
    // but whose position in the hierarchy is maintained by the RenderLayerCompositor. These
    // are the foreground and background layers. The foreground layer exists if we have composited
    // descendants with negative z-order. We need the extra layer in this case because the layer
    // needs to draw both below (for the background, say) and above (for the normal flow content, say)
    // the negative z-order descendants and this is impossible with a single layer. The RLC handles
    // inserting m_foregroundLayer in the correct position in our descendant list for us (right after
    // the neg z-order dsecendants).
    //
    // The background layer is only created if this is the root layer and our background is entirely
    // fixed. In this case we want to put the background in a separate composited layer so that when
    // we scroll, we don't have to re-raster the background into position. This layer is also inserted
    // into the tree by the RLC as it gets a special home. This layer becomes a descendant of the
    // frame clipping layer. That is:
    //   ...
    //     + frame clipping layer
    //       + m_backgroundLayer
    //       + frame scrolling layer
    //         + root content layer
    //
    // With the hierarchy set up like this, the root content layer is able to scroll without affecting
    // the background layer (or paint invalidation).
    OwnPtr<GraphicsLayer> m_foregroundLayer; // Only used in cases where we need to draw the foreground separately.
    OwnPtr<GraphicsLayer> m_backgroundLayer; // Only used in cases where we need to draw the background separately.

    // This layer exists to simplify the reparenting of overflow control that is occasionally required
    // to ensure that scrollbars appear above scrolling content.
    OwnPtr<GraphicsLayer> m_overflowControlsHostLayer;

    // The reparented overflow controls sometimes need to be clipped by a non-ancestor. In just the same
    // way we need an ancestor clipping layer to clip this CLM's internal hierarchy, we add another layer
    // to clip the overflow controls. It would be possible to make m_overflowControlsHostLayer be
    // responsible for applying this clip, but that could require repositioning all of the overflow
    // controls since the this clip may apply an offset. By using a separate layer, the overflow controls
    // can remain ignorant of the layers above them and still work correctly.
    OwnPtr<GraphicsLayer> m_overflowControlsClippingLayer;

    // A squashing CLM has two possible squashing-related structures.
    //
    // If m_ancestorClippingLayer is present:
    //
    // m_ancestorClippingLayer
    //   + m_graphicsLayer
    //   + m_squashingLayer
    //
    // If not:
    //
    // m_squashingContainmentLayer
    //   + m_graphicsLayer
    //   + m_squashingLayer
    //
    // Stacking children of a squashed layer receive graphics layers that are parented to the compositd ancestor of the
    // squashed layer (i.e. nearest enclosing composited layer that is not squashed).
    OwnPtr<GraphicsLayer> m_squashingContainmentLayer; // Only used if any squashed layers exist and m_squashingContainmentLayer is not present, to contain the squashed layers as siblings to the rest of the GraphicsLayer tree chunk.
    OwnPtr<GraphicsLayer> m_squashingLayer; // Only used if any squashed layers exist, this is the backing that squashed layers paint into.
    Vector<GraphicsLayerPaintInfo> m_squashedLayers;
    LayoutPoint m_squashingLayerOffsetFromTransformedAncestor;

    LayoutRect m_compositedBounds;

    LayoutSize m_contentOffsetInCompositingLayer;
    unsigned m_contentOffsetInCompositingLayerDirty : 1;

    unsigned m_pendingUpdateScope : 2;
    unsigned m_requiresOwnBackingStoreForIntrinsicReasons : 1;
    unsigned m_requiresOwnBackingStoreForAncestorReasons : 1;
    unsigned m_backgroundLayerPaintsFixedRootBackground : 1;
};

} // namespace blink

#endif // CompositedLayerMapping_h
