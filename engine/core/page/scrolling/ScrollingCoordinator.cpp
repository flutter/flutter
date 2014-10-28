/*
 * Copyright (C) 2011 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"

#include "core/page/scrolling/ScrollingCoordinator.h"

#include "core/dom/Document.h"
#include "core/dom/Node.h"
#include "core/frame/EventHandlerRegistry.h"
#include "core/frame/FrameView.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/html/HTMLElement.h"
#include "core/page/Page.h"
#include "core/rendering/RenderGeometryMap.h"
#include "core/rendering/RenderPart.h"
#include "core/rendering/RenderView.h"
#include "core/rendering/compositing/CompositedLayerMapping.h"
#include "core/rendering/compositing/RenderLayerCompositor.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "platform/TraceEvent.h"
#include "platform/exported/WebScrollbarImpl.h"
#include "platform/exported/WebScrollbarThemeGeometryNative.h"
#include "platform/geometry/Region.h"
#include "platform/geometry/TransformState.h"
#include "platform/graphics/GraphicsLayer.h"
#if OS(MACOSX)
#include "platform/mac/ScrollAnimatorMac.h"
#endif
#include "platform/scroll/ScrollAnimator.h"
#include "platform/scroll/Scrollbar.h"
#include "public/platform/Platform.h"
#include "public/platform/WebCompositorSupport.h"
#include "public/platform/WebScrollbarLayer.h"
#include "public/platform/WebScrollbarThemeGeometry.h"
#include "public/platform/WebScrollbarThemePainter.h"
#include "wtf/text/StringBuilder.h"

using blink::WebLayer;
using blink::WebLayerPositionConstraint;
using blink::WebRect;
using blink::WebScrollbarLayer;
using blink::WebVector;

namespace {

WebLayer* toWebLayer(blink::GraphicsLayer* layer)
{
    return layer ? layer->platformLayer() : 0;
}

} // namespace

namespace blink {

PassOwnPtr<ScrollingCoordinator> ScrollingCoordinator::create(Page* page)
{
    return adoptPtr(new ScrollingCoordinator(page));
}

ScrollingCoordinator::ScrollingCoordinator(Page* page)
    : m_page(page)
    , m_scrollGestureRegionIsDirty(false)
    , m_touchEventTargetRectsAreDirty(false)
    , m_shouldScrollOnMainThreadDirty(false)
    , m_wasFrameScrollable(false)
    , m_lastMainThreadScrollingReasons(0)
{
}

ScrollingCoordinator::~ScrollingCoordinator()
{
}

void ScrollingCoordinator::setShouldHandleScrollGestureOnMainThreadRegion(const Region& region)
{
    if (WebLayer* scrollLayer = toWebLayer(m_page->mainFrame()->view()->layerForScrolling())) {
        Vector<IntRect> rects = region.rects();
        WebVector<WebRect> webRects(rects.size());
        for (size_t i = 0; i < rects.size(); ++i)
            webRects[i] = rects[i];
        scrollLayer->setNonFastScrollableRegion(webRects);
    }
}

void ScrollingCoordinator::notifyLayoutUpdated()
{
    m_scrollGestureRegionIsDirty = true;
    m_touchEventTargetRectsAreDirty = true;
    m_shouldScrollOnMainThreadDirty = true;
}

void ScrollingCoordinator::updateAfterCompositingChangeIfNeeded()
{
    if (!shouldUpdateAfterCompositingChange())
        return;

    TRACE_EVENT0("input", "ScrollingCoordinator::updateAfterCompositingChangeIfNeeded");

    if (m_scrollGestureRegionIsDirty) {
        // Compute the region of the page where we can't handle scroll gestures and mousewheel events
        // on the impl thread. This currently includes:
        // 1. All scrollable areas, such as subframes, overflow divs and list boxes, whose composited
        // scrolling are not enabled. We need to do this even if the frame view whose layout was updated
        // is not the main frame.
        // 2. Resize control areas, e.g. the small rect at the right bottom of div/textarea/iframe when
        // CSS property "resize" is enabled.
        // 3. Plugin areas.
        Region shouldHandleScrollGestureOnMainThreadRegion = computeShouldHandleScrollGestureOnMainThreadRegion(m_page->mainFrame(), IntPoint());
        setShouldHandleScrollGestureOnMainThreadRegion(shouldHandleScrollGestureOnMainThreadRegion);
        m_scrollGestureRegionIsDirty = false;
    }

    if (m_touchEventTargetRectsAreDirty) {
        updateTouchEventTargetRectsIfNeeded();
        m_touchEventTargetRectsAreDirty = false;
    }

    FrameView* frameView = m_page->mainFrame()->view();
    bool frameIsScrollable = frameView && frameView->isScrollable();
    if (m_shouldScrollOnMainThreadDirty || m_wasFrameScrollable != frameIsScrollable) {
        setShouldUpdateScrollLayerPositionOnMainThread(mainThreadScrollingReasons());
        m_shouldScrollOnMainThreadDirty = false;
    }
    m_wasFrameScrollable = frameIsScrollable;

    // The mainFrame view doesn't get included in the FrameTree below, so we
    // update its size separately.
    if (WebLayer* scrollingWebLayer = frameView ? toWebLayer(frameView->layerForScrolling()) : 0) {
        scrollingWebLayer->setBounds(frameView->size());
    }
}

void ScrollingCoordinator::willDestroyScrollableArea(ScrollableArea* scrollableArea)
{
    removeWebScrollbarLayer(scrollableArea, HorizontalScrollbar);
    removeWebScrollbarLayer(scrollableArea, VerticalScrollbar);
}

void ScrollingCoordinator::removeWebScrollbarLayer(ScrollableArea* scrollableArea, ScrollbarOrientation orientation)
{
    ScrollbarMap& scrollbars = orientation == HorizontalScrollbar ? m_horizontalScrollbars : m_verticalScrollbars;
    if (OwnPtr<WebScrollbarLayer> scrollbarLayer = scrollbars.take(scrollableArea))
        GraphicsLayer::unregisterContentsLayer(scrollbarLayer->layer());
}

static PassOwnPtr<WebScrollbarLayer> createScrollbarLayer(Scrollbar* scrollbar)
{
    blink::WebScrollbarThemePainter painter(scrollbar);
    OwnPtr<blink::WebScrollbarThemeGeometry> geometry(blink::WebScrollbarThemeGeometryNative::create(scrollbar));

    OwnPtr<WebScrollbarLayer> scrollbarLayer = adoptPtr(blink::Platform::current()->compositorSupport()->createScrollbarLayer(new blink::WebScrollbarImpl(scrollbar), painter, geometry.leakPtr()));
    GraphicsLayer::registerContentsLayer(scrollbarLayer->layer());
    return scrollbarLayer.release();
}

PassOwnPtr<WebScrollbarLayer> ScrollingCoordinator::createSolidColorScrollbarLayer(ScrollbarOrientation orientation, int thumbThickness, int trackStart, bool isLeftSideVerticalScrollbar)
{
    blink::WebScrollbar::Orientation webOrientation = (orientation == HorizontalScrollbar) ? blink::WebScrollbar::Horizontal : blink::WebScrollbar::Vertical;
    OwnPtr<WebScrollbarLayer> scrollbarLayer = adoptPtr(blink::Platform::current()->compositorSupport()->createSolidColorScrollbarLayer(webOrientation, thumbThickness, trackStart, isLeftSideVerticalScrollbar));
    GraphicsLayer::registerContentsLayer(scrollbarLayer->layer());
    return scrollbarLayer.release();
}

static void detachScrollbarLayer(GraphicsLayer* scrollbarGraphicsLayer)
{
    ASSERT(scrollbarGraphicsLayer);

    scrollbarGraphicsLayer->setContentsToPlatformLayer(0);
    scrollbarGraphicsLayer->setDrawsContent(true);
}

static void setupScrollbarLayer(GraphicsLayer* scrollbarGraphicsLayer, WebScrollbarLayer* scrollbarLayer, WebLayer* scrollLayer, WebLayer* containerLayer)
{
    ASSERT(scrollbarGraphicsLayer);
    ASSERT(scrollbarLayer);

    if (!scrollLayer) {
        detachScrollbarLayer(scrollbarGraphicsLayer);
        return;
    }
    scrollbarLayer->setScrollLayer(scrollLayer);
    scrollbarLayer->setClipLayer(containerLayer);
    scrollbarGraphicsLayer->setContentsToPlatformLayer(scrollbarLayer->layer());
    scrollbarGraphicsLayer->setDrawsContent(false);
}

WebScrollbarLayer* ScrollingCoordinator::addWebScrollbarLayer(ScrollableArea* scrollableArea, ScrollbarOrientation orientation, PassOwnPtr<blink::WebScrollbarLayer> scrollbarLayer)
{
    ScrollbarMap& scrollbars = orientation == HorizontalScrollbar ? m_horizontalScrollbars : m_verticalScrollbars;
    return scrollbars.add(scrollableArea, scrollbarLayer).storedValue->value.get();
}

WebScrollbarLayer* ScrollingCoordinator::getWebScrollbarLayer(ScrollableArea* scrollableArea, ScrollbarOrientation orientation)
{
    ScrollbarMap& scrollbars = orientation == HorizontalScrollbar ? m_horizontalScrollbars : m_verticalScrollbars;
    return scrollbars.get(scrollableArea);
}

void ScrollingCoordinator::scrollableAreaScrollbarLayerDidChange(ScrollableArea* scrollableArea, ScrollbarOrientation orientation)
{
    GraphicsLayer* scrollbarGraphicsLayer = orientation == HorizontalScrollbar
        ? scrollableArea->layerForHorizontalScrollbar()
        : scrollableArea->layerForVerticalScrollbar();

    if (scrollbarGraphicsLayer) {
        Scrollbar* scrollbar = orientation == HorizontalScrollbar ? scrollableArea->horizontalScrollbar() : scrollableArea->verticalScrollbar();
        if (scrollbar->isCustomScrollbar()) {
            detachScrollbarLayer(scrollbarGraphicsLayer);
            return;
        }

        WebScrollbarLayer* scrollbarLayer = getWebScrollbarLayer(scrollableArea, orientation);
        if (!scrollbarLayer) {
            Settings* settings = m_page->mainFrame()->settings();

            OwnPtr<WebScrollbarLayer> webScrollbarLayer;
            if (settings->useSolidColorScrollbars()) {
                ASSERT(RuntimeEnabledFeatures::overlayScrollbarsEnabled());
                webScrollbarLayer = createSolidColorScrollbarLayer(orientation, scrollbar->theme()->thumbThickness(), scrollbar->theme()->trackPosition(), scrollableArea->shouldPlaceVerticalScrollbarOnLeft());
            } else {
                webScrollbarLayer = createScrollbarLayer(scrollbar);
            }
            scrollbarLayer = addWebScrollbarLayer(scrollableArea, orientation, webScrollbarLayer.release());
        }

        // Root layer non-overlay scrollbars should be marked opaque to disable
        // blending.
        bool isOpaqueScrollbar = !scrollbar->isOverlayScrollbar();
        scrollbarGraphicsLayer->setContentsOpaque(isOpaqueScrollbar);

        WebLayer* scrollLayer = toWebLayer(scrollableArea->layerForScrolling());
        WebLayer* containerLayer = toWebLayer(scrollableArea->layerForContainer());
        setupScrollbarLayer(scrollbarGraphicsLayer, scrollbarLayer, scrollLayer, containerLayer);
    } else
        removeWebScrollbarLayer(scrollableArea, orientation);
}

bool ScrollingCoordinator::scrollableAreaScrollLayerDidChange(ScrollableArea* scrollableArea)
{
    GraphicsLayer* scrollLayer = scrollableArea->layerForScrolling();

    if (scrollLayer)
        scrollLayer->setScrollableArea(scrollableArea);

    WebLayer* webLayer = toWebLayer(scrollableArea->layerForScrolling());
    WebLayer* containerLayer = toWebLayer(scrollableArea->layerForContainer());
    if (webLayer) {
        webLayer->setScrollClipLayer(containerLayer);
        webLayer->setScrollPosition(IntPoint(scrollableArea->scrollPosition() - scrollableArea->minimumScrollPosition()));
        webLayer->setBounds(scrollableArea->contentsSize());
        bool canScrollX = scrollableArea->userInputScrollable(HorizontalScrollbar);
        bool canScrollY = scrollableArea->userInputScrollable(VerticalScrollbar);
        webLayer->setUserScrollable(canScrollX, canScrollY);
    }
    if (WebScrollbarLayer* scrollbarLayer = getWebScrollbarLayer(scrollableArea, HorizontalScrollbar)) {
        GraphicsLayer* horizontalScrollbarLayer = scrollableArea->layerForHorizontalScrollbar();
        if (horizontalScrollbarLayer)
            setupScrollbarLayer(horizontalScrollbarLayer, scrollbarLayer, webLayer, containerLayer);
    }
    if (WebScrollbarLayer* scrollbarLayer = getWebScrollbarLayer(scrollableArea, VerticalScrollbar)) {
        GraphicsLayer* verticalScrollbarLayer = scrollableArea->layerForVerticalScrollbar();
        if (verticalScrollbarLayer)
            setupScrollbarLayer(verticalScrollbarLayer, scrollbarLayer, webLayer, containerLayer);
    }

    return !!webLayer;
}

typedef WTF::HashMap<const GraphicsLayer*, Vector<LayoutRect> > GraphicsLayerHitTestRects;

// In order to do a DFS cross-frame walk of the RenderLayer tree, we need to know which
// RenderLayers have child frames inside of them. This computes a mapping for the
// current frame which we can consult while walking the layers of that frame.
// Whenever we descend into a new frame, a new map will be created.
typedef HashMap<const RenderLayer*, Vector<const LocalFrame*> > LayerFrameMap;
static void makeLayerChildFrameMap(const LocalFrame* currentFrame, LayerFrameMap* map)
{
    map->clear();
}

static void projectRectsToGraphicsLayerSpaceRecursive(
    const RenderLayer* curLayer,
    const LayerHitTestRects& layerRects,
    GraphicsLayerHitTestRects& graphicsRects,
    RenderGeometryMap& geometryMap,
    HashSet<const RenderLayer*>& layersWithRects,
    LayerFrameMap& layerChildFrameMap)
{
    // Project any rects for the current layer
    LayerHitTestRects::const_iterator layerIter = layerRects.find(curLayer);
    if (layerIter != layerRects.end()) {
        // Find the enclosing composited layer when it's in another document (for non-composited iframes).
        const RenderLayer* compositedLayer = layerIter->key->enclosingLayerForPaintInvalidationCrossingFrameBoundaries();
        ASSERT(compositedLayer);

        // Find the appropriate GraphicsLayer for the composited RenderLayer.
        GraphicsLayer* graphicsLayer = compositedLayer->graphicsLayerBackingForScrolling();

        GraphicsLayerHitTestRects::iterator glIter = graphicsRects.find(graphicsLayer);
        Vector<LayoutRect>* glRects;
        if (glIter == graphicsRects.end())
            glRects = &graphicsRects.add(graphicsLayer, Vector<LayoutRect>()).storedValue->value;
        else
            glRects = &glIter->value;

        // Transform each rect to the co-ordinate space of the graphicsLayer.
        for (size_t i = 0; i < layerIter->value.size(); ++i) {
            LayoutRect rect = layerIter->value[i];
            if (compositedLayer != curLayer) {
                FloatQuad compositorQuad = geometryMap.mapToContainer(rect, compositedLayer->renderer());
                rect = LayoutRect(compositorQuad.boundingBox());
                // If the enclosing composited layer itself is scrolled, we have to undo the subtraction
                // of its scroll offset since we want the offset relative to the scrolling content, not
                // the element itself.
                if (compositedLayer->renderer()->hasOverflowClip())
                    rect.move(compositedLayer->renderBox()->scrolledContentOffset());
            }
            RenderLayer::mapRectToPaintBackingCoordinates(compositedLayer->renderer(), rect);
            glRects->append(rect);
        }
    }

    // Walk child layers of interest
    for (const RenderLayer* childLayer = curLayer->firstChild(); childLayer; childLayer = childLayer->nextSibling()) {
        if (layersWithRects.contains(childLayer)) {
            geometryMap.pushMappingsToAncestor(childLayer, curLayer);
            projectRectsToGraphicsLayerSpaceRecursive(childLayer, layerRects, graphicsRects, geometryMap, layersWithRects, layerChildFrameMap);
            geometryMap.popMappingsToAncestor(curLayer);
        }
    }

    // If this layer has any frames of interest as a child of it, walk those (with an updated frame map).
    LayerFrameMap::iterator mapIter = layerChildFrameMap.find(curLayer);
    if (mapIter != layerChildFrameMap.end()) {
        for (size_t i = 0; i < mapIter->value.size(); i++) {
            const LocalFrame* childFrame = mapIter->value[i];
            const RenderLayer* childLayer = childFrame->view()->renderView()->layer();
            if (layersWithRects.contains(childLayer)) {
                LayerFrameMap newLayerChildFrameMap;
                makeLayerChildFrameMap(childFrame, &newLayerChildFrameMap);
                geometryMap.pushMappingsToAncestor(childLayer, curLayer);
                projectRectsToGraphicsLayerSpaceRecursive(childLayer, layerRects, graphicsRects, geometryMap, layersWithRects, newLayerChildFrameMap);
                geometryMap.popMappingsToAncestor(curLayer);
            }
        }
    }
}

static void projectRectsToGraphicsLayerSpace(LocalFrame* mainFrame, const LayerHitTestRects& layerRects, GraphicsLayerHitTestRects& graphicsRects)
{
    TRACE_EVENT0("input", "ScrollingCoordinator::projectRectsToGraphicsLayerSpace");
    bool touchHandlerInChildFrame = false;

    // We have a set of rects per RenderLayer, we need to map them to their bounding boxes in their
    // enclosing composited layer. To do this most efficiently we'll walk the RenderLayer tree using
    // RenderGeometryMap. First record all the branches we should traverse in the tree (including
    // all documents on the page).
    HashSet<const RenderLayer*> layersWithRects;
    for (LayerHitTestRects::const_iterator layerIter = layerRects.begin(); layerIter != layerRects.end(); ++layerIter) {
        const RenderLayer* layer = layerIter->key;
        do {
            if (!layersWithRects.add(layer).isNewEntry)
                break;

            if (layer->parent()) {
                layer = layer->parent();
            }
        } while (layer);
    }

    // Now walk the layer projecting rects while maintaining a RenderGeometryMap
    MapCoordinatesFlags flags = UseTransforms;
    if (touchHandlerInChildFrame)
        flags |= TraverseDocumentBoundaries;
    RenderLayer* rootLayer = mainFrame->contentRenderer()->layer();
    RenderGeometryMap geometryMap(flags);
    geometryMap.pushMappingsToAncestor(rootLayer, 0);
    LayerFrameMap layerChildFrameMap;
    makeLayerChildFrameMap(mainFrame, &layerChildFrameMap);
    projectRectsToGraphicsLayerSpaceRecursive(rootLayer, layerRects, graphicsRects, geometryMap, layersWithRects, layerChildFrameMap);
}

void ScrollingCoordinator::updateTouchEventTargetRectsIfNeeded()
{
    TRACE_EVENT0("input", "ScrollingCoordinator::updateTouchEventTargetRectsIfNeeded");

    if (!RuntimeEnabledFeatures::touchEnabled())
        return;

    LayerHitTestRects touchEventTargetRects;
    computeTouchEventTargetRects(touchEventTargetRects);
    setTouchEventTargetRects(touchEventTargetRects);
}

void ScrollingCoordinator::reset()
{
    for (ScrollbarMap::iterator it = m_horizontalScrollbars.begin(); it != m_horizontalScrollbars.end(); ++it)
        GraphicsLayer::unregisterContentsLayer(it->value->layer());
    for (ScrollbarMap::iterator it = m_verticalScrollbars.begin(); it != m_verticalScrollbars.end(); ++it)
        GraphicsLayer::unregisterContentsLayer(it->value->layer());

    m_horizontalScrollbars.clear();
    m_verticalScrollbars.clear();
    m_layersWithTouchRects.clear();
    m_wasFrameScrollable = false;

    // This is retained for testing.
    m_lastMainThreadScrollingReasons = 0;
    setShouldUpdateScrollLayerPositionOnMainThread(m_lastMainThreadScrollingReasons);
}

// Note that in principle this could be called more often than computeTouchEventTargetRects, for
// example during a non-composited scroll (although that's not yet implemented - crbug.com/261307).
void ScrollingCoordinator::setTouchEventTargetRects(LayerHitTestRects& layerRects)
{
    TRACE_EVENT0("input", "ScrollingCoordinator::setTouchEventTargetRects");

    // Update the list of layers with touch hit rects.
    HashSet<const RenderLayer*> oldLayersWithTouchRects;
    m_layersWithTouchRects.swap(oldLayersWithTouchRects);
    for (LayerHitTestRects::iterator it = layerRects.begin(); it != layerRects.end(); ++it) {
        if (!it->value.isEmpty()) {
            const RenderLayer* compositedLayer = it->key->enclosingLayerForPaintInvalidationCrossingFrameBoundaries();
            ASSERT(compositedLayer);
            m_layersWithTouchRects.add(compositedLayer);
        }
    }

    // Ensure we have an entry for each composited layer that previously had rects (so that old
    // ones will get cleared out). Note that ideally we'd track this on GraphicsLayer instead of
    // RenderLayer, but we have no good hook into the lifetime of a GraphicsLayer.
    for (HashSet<const RenderLayer*>::iterator it = oldLayersWithTouchRects.begin(); it != oldLayersWithTouchRects.end(); ++it) {
        if (!layerRects.contains(*it))
            layerRects.add(*it, Vector<LayoutRect>());
    }

    GraphicsLayerHitTestRects graphicsLayerRects;
    projectRectsToGraphicsLayerSpace(m_page->mainFrame(), layerRects, graphicsLayerRects);

    for (GraphicsLayerHitTestRects::const_iterator iter = graphicsLayerRects.begin(); iter != graphicsLayerRects.end(); ++iter) {
        const GraphicsLayer* graphicsLayer = iter->key;
        WebVector<WebRect> webRects(iter->value.size());
        for (size_t i = 0; i < iter->value.size(); ++i)
            webRects[i] = enclosingIntRect(iter->value[i]);
        graphicsLayer->platformLayer()->setTouchEventHandlerRegion(webRects);
    }
}

void ScrollingCoordinator::touchEventTargetRectsDidChange()
{
    if (!RuntimeEnabledFeatures::touchEnabled())
        return;

    // Wait until after layout to update.
    if (!m_page->mainFrame()->view() || m_page->mainFrame()->view()->needsLayout())
        return;

    // FIXME: scheduleAnimation() is just a method of forcing the compositor to realize that it
    // needs to commit here. We should expose a cleaner API for this.
    RenderView* renderView = m_page->mainFrame()->contentRenderer();
    if (renderView && renderView->compositor() && renderView->compositor()->staleInCompositingMode())
        m_page->mainFrame()->view()->scheduleAnimation();

    m_touchEventTargetRectsAreDirty = true;
}

void ScrollingCoordinator::updateScrollParentForGraphicsLayer(GraphicsLayer* child, RenderLayer* parent)
{
    WebLayer* scrollParentWebLayer = 0;
    if (parent && parent->hasCompositedLayerMapping())
        scrollParentWebLayer = toWebLayer(parent->compositedLayerMapping()->scrollingContentsLayer());

    child->setScrollParent(scrollParentWebLayer);
}

void ScrollingCoordinator::updateClipParentForGraphicsLayer(GraphicsLayer* child, RenderLayer* parent)
{
    WebLayer* clipParentWebLayer = 0;
    if (parent && parent->hasCompositedLayerMapping())
        clipParentWebLayer = toWebLayer(parent->compositedLayerMapping()->parentForSublayers());

    child->setClipParent(clipParentWebLayer);
}

void ScrollingCoordinator::willDestroyRenderLayer(RenderLayer* layer)
{
    m_layersWithTouchRects.remove(layer);
}

void ScrollingCoordinator::updateHaveWheelEventHandlers()
{
    ASSERT(isMainThread());
    ASSERT(m_page);
    if (!m_page->mainFrame()->view())
        return;

    if (WebLayer* scrollLayer = toWebLayer(m_page->mainFrame()->view()->layerForScrolling())) {
        bool haveHandlers = m_page->frameHost().eventHandlerRegistry().hasEventHandlers(EventHandlerRegistry::WheelEvent);
        scrollLayer->setHaveWheelEventHandlers(haveHandlers);
    }
}

void ScrollingCoordinator::updateHaveScrollEventHandlers()
{
    ASSERT(isMainThread());
    ASSERT(m_page);
    if (!m_page->mainFrame()->view())
        return;

    // Currently the compositor only cares whether there are scroll handlers anywhere on the page
    // instead on a per-layer basis. We therefore only update this information for the root
    // scrolling layer.
    if (WebLayer* scrollLayer = toWebLayer(m_page->mainFrame()->view()->layerForScrolling())) {
        bool haveHandlers = m_page->frameHost().eventHandlerRegistry().hasEventHandlers(EventHandlerRegistry::ScrollEvent);
        scrollLayer->setHaveScrollEventHandlers(haveHandlers);
    }
}

void ScrollingCoordinator::setShouldUpdateScrollLayerPositionOnMainThread(MainThreadScrollingReasons reasons)
{
    if (WebLayer* scrollLayer = toWebLayer(m_page->mainFrame()->view()->layerForScrolling())) {
        m_lastMainThreadScrollingReasons = reasons;
        scrollLayer->setShouldScrollOnMainThread(reasons);
    }
}

void ScrollingCoordinator::willBeDestroyed()
{
    ASSERT(m_page);
    m_page = 0;
    for (ScrollbarMap::iterator it = m_horizontalScrollbars.begin(); it != m_horizontalScrollbars.end(); ++it)
        GraphicsLayer::unregisterContentsLayer(it->value->layer());
    for (ScrollbarMap::iterator it = m_verticalScrollbars.begin(); it != m_verticalScrollbars.end(); ++it)
        GraphicsLayer::unregisterContentsLayer(it->value->layer());
}

bool ScrollingCoordinator::coordinatesScrollingForFrameView(FrameView* frameView) const
{
    ASSERT(isMainThread());
    ASSERT(m_page);

    // We currently only handle the main frame.
    if (&frameView->frame() != m_page->mainFrame())
        return false;

    // We currently only support composited mode.
    RenderView* renderView = m_page->mainFrame()->contentRenderer();
    if (!renderView)
        return false;
    return renderView->usesCompositing();
}

Region ScrollingCoordinator::computeShouldHandleScrollGestureOnMainThreadRegion(const LocalFrame* frame, const IntPoint& frameLocation) const
{
    Region shouldHandleScrollGestureOnMainThreadRegion;
    FrameView* frameView = frame->view();
    if (!frameView)
        return shouldHandleScrollGestureOnMainThreadRegion;

    IntPoint offset = frameLocation;
    offset.moveBy(frameView->frameRect().location());

    if (const FrameView::ScrollableAreaSet* scrollableAreas = frameView->scrollableAreas()) {
        for (FrameView::ScrollableAreaSet::const_iterator it = scrollableAreas->begin(), end = scrollableAreas->end(); it != end; ++it) {
            ScrollableArea* scrollableArea = *it;
            // Composited scrollable areas can be scrolled off the main thread.
            if (scrollableArea->usesCompositedScrolling())
                continue;
            IntRect box = scrollableArea->scrollableAreaBoundingBox();
            box.moveBy(offset);
            shouldHandleScrollGestureOnMainThreadRegion.unite(box);
        }
    }

    // We use GestureScrollBegin/Update/End for moving the resizer handle. So we mark these
    // small resizer areas as non-fast-scrollable to allow the scroll gestures to be passed to
    // main thread if they are targeting the resizer area. (Resizing is done in EventHandler.cpp
    // on main thread).
    if (const FrameView::ResizerAreaSet* resizerAreas = frameView->resizerAreas()) {
        for (FrameView::ResizerAreaSet::const_iterator it = resizerAreas->begin(), end = resizerAreas->end(); it != end; ++it) {
            RenderBox* box = *it;
            IntRect bounds = box->absoluteBoundingBoxRect();
            IntRect corner = box->layer()->scrollableArea()->touchResizerCornerRect(bounds);
            corner.moveBy(offset);
            shouldHandleScrollGestureOnMainThreadRegion.unite(corner);
        }
    }

    return shouldHandleScrollGestureOnMainThreadRegion;
}

static void accumulateDocumentTouchEventTargetRects(LayerHitTestRects& rects, const Document* document)
{
    ASSERT(document);
    const EventTargetSet* targets = document->frameHost()->eventHandlerRegistry().eventHandlerTargets(EventHandlerRegistry::TouchEvent);
    if (!targets)
        return;

    // If there's a handler on the window, document, html or body element (fairly common in practice),
    // then we can quickly mark the entire document and skip looking at any other handlers.
    // Note that technically a handler on the body doesn't cover the whole document, but it's
    // reasonable to be conservative and report the whole document anyway.
    for (EventTargetSet::const_iterator iter = targets->begin(); iter != targets->end(); ++iter) {
        EventTarget* target = iter->key;
        Node* node = target->toNode();
        if (target->toDOMWindow() || node == document || node == document->documentElement()) {
            if (RenderView* rendererView = document->renderView()) {
                rendererView->computeLayerHitTestRects(rects);
            }
            return;
        }
    }

    for (EventTargetSet::const_iterator iter = targets->begin(); iter != targets->end(); ++iter) {
        EventTarget* target = iter->key;
        Node* node = target->toNode();
        if (!node || !node->inDocument())
            continue;

        if (node->isDocumentNode() && node != document) {
            accumulateDocumentTouchEventTargetRects(rects, toDocument(node));
        } else if (RenderObject* renderer = node->renderer()) {
            // If the set also contains one of our ancestor nodes then processing
            // this node would be redundant.
            bool hasTouchEventTargetAncestor = false;
            for (Node* ancestor = node->parentNode(); ancestor && !hasTouchEventTargetAncestor; ancestor = ancestor->parentNode()) {
                if (targets->contains(ancestor))
                    hasTouchEventTargetAncestor = true;
            }
            if (!hasTouchEventTargetAncestor) {
                // Walk up the tree to the outermost non-composited scrollable layer.
                RenderLayer* enclosingNonCompositedScrollLayer = 0;
                for (RenderLayer* parent = renderer->enclosingLayer(); parent && parent->compositingState() == NotComposited; parent = parent->parent()) {
                    if (parent->scrollsOverflow())
                        enclosingNonCompositedScrollLayer = parent;
                }

                // Report the whole non-composited scroll layer as a touch hit rect because any
                // rects inside of it may move around relative to their enclosing composited layer
                // without causing the rects to be recomputed. Non-composited scrolling occurs on
                // the main thread, so we're not getting much benefit from compositor touch hit
                // testing in this case anyway.
                if (enclosingNonCompositedScrollLayer)
                    enclosingNonCompositedScrollLayer->computeSelfHitTestRects(rects);

                renderer->computeLayerHitTestRects(rects);
            }
        }
    }
}

void ScrollingCoordinator::computeTouchEventTargetRects(LayerHitTestRects& rects)
{
    TRACE_EVENT0("input", "ScrollingCoordinator::computeTouchEventTargetRects");
    ASSERT(RuntimeEnabledFeatures::touchEnabled());

    Document* document = m_page->mainFrame()->document();
    if (!document || !document->view())
        return;

    accumulateDocumentTouchEventTargetRects(rects, document);
}

void ScrollingCoordinator::frameViewHasSlowRepaintObjectsDidChange(FrameView* frameView)
{
    ASSERT(isMainThread());
    ASSERT(m_page);

    if (!coordinatesScrollingForFrameView(frameView))
        return;

    m_shouldScrollOnMainThreadDirty = true;
}

void ScrollingCoordinator::frameViewFixedObjectsDidChange(FrameView* frameView)
{
    ASSERT(isMainThread());
    ASSERT(m_page);

    if (!coordinatesScrollingForFrameView(frameView))
        return;

    m_shouldScrollOnMainThreadDirty = true;
}

bool ScrollingCoordinator::isForMainFrame(ScrollableArea* scrollableArea) const
{
    // FIXME(sky): Remove
    return false;
}

void ScrollingCoordinator::frameViewRootLayerDidChange(FrameView* frameView)
{
    ASSERT(isMainThread());
    ASSERT(m_page);

    if (!coordinatesScrollingForFrameView(frameView))
        return;

    notifyLayoutUpdated();
    updateHaveWheelEventHandlers();
    updateHaveScrollEventHandlers();
}

#if OS(MACOSX)
void ScrollingCoordinator::handleWheelEventPhase(PlatformWheelEventPhase phase)
{
    ASSERT(isMainThread());

    if (!m_page)
        return;

    FrameView* frameView = m_page->mainFrame()->view();
    if (!frameView)
        return;

    frameView->scrollAnimator()->handleWheelEventPhase(phase);
}
#endif

bool ScrollingCoordinator::hasVisibleSlowRepaintViewportConstrainedObjects(FrameView* frameView) const
{
    // FIXME(sky): Remove
    return false;
}

MainThreadScrollingReasons ScrollingCoordinator::mainThreadScrollingReasons() const
{
    MainThreadScrollingReasons reasons = static_cast<MainThreadScrollingReasons>(0);

    FrameView* frameView = m_page->mainFrame()->view();
    if (!frameView)
        return reasons;

    if (frameView->hasSlowRepaintObjects())
        reasons |= HasSlowRepaintObjects;
    if (frameView->isScrollable() && hasVisibleSlowRepaintViewportConstrainedObjects(frameView))
        reasons |= HasNonLayerViewportConstrainedObjects;

    return reasons;
}

String ScrollingCoordinator::mainThreadScrollingReasonsAsText(MainThreadScrollingReasons reasons)
{
    StringBuilder stringBuilder;

    if (reasons & ScrollingCoordinator::HasSlowRepaintObjects)
        stringBuilder.appendLiteral("Has slow repaint objects, ");
    if (reasons & ScrollingCoordinator::HasViewportConstrainedObjectsWithoutSupportingFixedLayers)
        stringBuilder.appendLiteral("Has viewport constrained objects without supporting fixed layers, ");
    if (reasons & ScrollingCoordinator::HasNonLayerViewportConstrainedObjects)
        stringBuilder.appendLiteral("Has non-layer viewport-constrained objects, ");

    if (stringBuilder.length())
        stringBuilder.resize(stringBuilder.length() - 2);
    return stringBuilder.toString();
}

String ScrollingCoordinator::mainThreadScrollingReasonsAsText() const
{
    ASSERT(m_page->mainFrame()->document()->lifecycle().state() >= DocumentLifecycle::CompositingClean);
    return mainThreadScrollingReasonsAsText(m_lastMainThreadScrollingReasons);
}

bool ScrollingCoordinator::frameViewIsDirty() const
{
    // FIXME(sky): Remove
    return false;
}

} // namespace blink
