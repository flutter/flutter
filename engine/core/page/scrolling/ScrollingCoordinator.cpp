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
#include "core/frame/FrameView.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/html/HTMLElement.h"
#include "core/page/Page.h"
#include "core/rendering/RenderGeometryMap.h"
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
{
}

ScrollingCoordinator::~ScrollingCoordinator()
{
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

        WebScrollbarLayer* scrollbarLayer = getWebScrollbarLayer(scrollableArea, orientation);
        if (!scrollbarLayer) {
            Settings* settings = m_page->mainFrame()->settings();

            OwnPtr<WebScrollbarLayer> webScrollbarLayer;
            if (settings->useSolidColorScrollbars()) {
                ASSERT(RuntimeEnabledFeatures::overlayScrollbarsEnabled());
                webScrollbarLayer = createSolidColorScrollbarLayer(orientation, scrollbar->thumbThickness(), scrollbar->trackPosition(), scrollableArea->shouldPlaceVerticalScrollbarOnLeft());
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

void ScrollingCoordinator::reset()
{
    for (ScrollbarMap::iterator it = m_horizontalScrollbars.begin(); it != m_horizontalScrollbars.end(); ++it)
        GraphicsLayer::unregisterContentsLayer(it->value->layer());
    for (ScrollbarMap::iterator it = m_verticalScrollbars.begin(); it != m_verticalScrollbars.end(); ++it)
        GraphicsLayer::unregisterContentsLayer(it->value->layer());

    m_horizontalScrollbars.clear();
    m_verticalScrollbars.clear();
    m_layersWithTouchRects.clear();
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

void ScrollingCoordinator::willBeDestroyed()
{
    ASSERT(m_page);
    m_page = 0;
    for (ScrollbarMap::iterator it = m_horizontalScrollbars.begin(); it != m_horizontalScrollbars.end(); ++it)
        GraphicsLayer::unregisterContentsLayer(it->value->layer());
    for (ScrollbarMap::iterator it = m_verticalScrollbars.begin(); it != m_verticalScrollbars.end(); ++it)
        GraphicsLayer::unregisterContentsLayer(it->value->layer());
}

bool ScrollingCoordinator::isForMainFrame(ScrollableArea* scrollableArea) const
{
    // FIXME(sky): Remove
    return false;
}

} // namespace blink
