/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/frame/PinchViewport.h"

#include "core/frame/FrameHost.h"
#include "core/frame/FrameView.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/page/Chrome.h"
#include "core/page/ChromeClient.h"
#include "core/page/Page.h"
#include "core/page/scrolling/ScrollingCoordinator.h"
#include "core/rendering/RenderView.h"
#include "core/rendering/compositing/RenderLayerCompositor.h"
#include "platform/TraceEvent.h"
#include "platform/geometry/FloatSize.h"
#include "platform/graphics/GraphicsLayer.h"
#include "platform/graphics/GraphicsLayerFactory.h"
#include "platform/scroll/Scrollbar.h"
#include "public/platform/Platform.h"
#include "public/platform/WebCompositorSupport.h"
#include "public/platform/WebLayer.h"
#include "public/platform/WebLayerTreeView.h"
#include "public/platform/WebScrollbar.h"
#include "public/platform/WebScrollbarLayer.h"

using blink::WebLayer;
using blink::WebLayerTreeView;
using blink::WebScrollbar;
using blink::WebScrollbarLayer;
using blink::FrameHost;
using blink::GraphicsLayer;
using blink::GraphicsLayerFactory;

namespace blink {

PinchViewport::PinchViewport(FrameHost& owner)
    : m_frameHost(owner)
    , m_scale(1)
{
    reset();
}

PinchViewport::~PinchViewport() { }

void PinchViewport::setSize(const IntSize& size)
{
    if (m_size == size)
        return;

    TRACE_EVENT2("blink", "PinchViewport::setSize", "width", size.width(), "height", size.height());
    m_size = size;

    // Make sure we clamp the offset to within the new bounds.
    setLocation(m_offset);

    if (m_innerViewportContainerLayer) {
        m_innerViewportContainerLayer->setSize(m_size);

        // Need to re-compute sizes for the overlay scrollbars.
        setupScrollbar(WebScrollbar::Horizontal);
        setupScrollbar(WebScrollbar::Vertical);
    }
}

void PinchViewport::reset()
{
    setLocation(FloatPoint());
    setScale(1);
}

void PinchViewport::mainFrameDidChangeSize()
{
    TRACE_EVENT0("blink", "PinchViewport::mainFrameDidChangeSize");

    // In unit tests we may not have initialized the layer tree.
    if (m_innerViewportScrollLayer)
        m_innerViewportScrollLayer->setSize(contentsSize());

    // Make sure the viewport's offset is clamped within the newly sized main frame.
    setLocation(m_offset);
}

FloatRect PinchViewport::visibleRect() const
{
    FloatSize scaledSize(m_size);
    scaledSize.scale(1 / m_scale);
    return FloatRect(m_offset, scaledSize);
}

FloatRect PinchViewport::visibleRectInDocument() const
{
    if (!mainFrame() || !mainFrame()->view())
        return FloatRect();

    FloatRect viewRect = mainFrame()->view()->visibleContentRect();
    FloatRect pinchRect = visibleRect();
    pinchRect.moveBy(viewRect.location());
    return pinchRect;
}

void PinchViewport::scrollIntoView(const FloatRect& rect)
{
    // FIXME(sky): Delete this whole file.
}

void PinchViewport::setLocation(const FloatPoint& newLocation)
{
    FloatPoint clampedOffset(clampOffsetToBoundaries(newLocation));

    if (clampedOffset == m_offset)
        return;

    m_offset = clampedOffset;

    ScrollingCoordinator* coordinator = m_frameHost.page().scrollingCoordinator();
    ASSERT(coordinator);
    coordinator->scrollableAreaScrollLayerDidChange(this);
}

void PinchViewport::move(const FloatPoint& delta)
{
    setLocation(m_offset + delta);
}

void PinchViewport::setScale(float scale)
{
    if (scale == m_scale)
        return;

    m_scale = scale;

    // Old-style pinch sets scale here but we shouldn't call into the
    // clamping code below.
    if (!m_innerViewportScrollLayer)
        return;

    // Ensure we clamp so we remain within the bounds.
    setLocation(visibleRect().location());

    // TODO: We should probably be calling scaleDidChange type functions here.
    // see Page::setPageScaleFactor.
}

// Modifies the top of the graphics layer tree to add layers needed to support
// the inner/outer viewport fixed-position model for pinch zoom. When finished,
// the tree will look like this (with * denoting added layers):
//
// *rootTransformLayer
//  +- *innerViewportContainerLayer (fixed pos container)
//      +- *pageScaleLayer
//  |       +- *innerViewportScrollLayer
//  |           +-- overflowControlsHostLayer (root layer)
//  |               +-- outerViewportContainerLayer (fixed pos container) [frame container layer in RenderLayerCompositor]
//  |               |   +-- outerViewportScrollLayer [frame scroll layer in RenderLayerCompositor]
//  |               |       +-- content layers ...
//  |               +-- horizontal ScrollbarLayer (non-overlay)
//  |               +-- verticalScrollbarLayer (non-overlay)
//  |               +-- scroll corner (non-overlay)
//  +- *horizontalScrollbarLayer (overlay)
//  +- *verticalScrollbarLayer (overlay)
//
void PinchViewport::attachToLayerTree(GraphicsLayer* currentLayerTreeRoot, GraphicsLayerFactory* graphicsLayerFactory)
{
    TRACE_EVENT1("blink", "PinchViewport::attachToLayerTree", "currentLayerTreeRoot", (bool)currentLayerTreeRoot);
    if (!currentLayerTreeRoot) {
        m_innerViewportScrollLayer->removeAllChildren();
        return;
    }

    if (currentLayerTreeRoot->parent() && currentLayerTreeRoot->parent() == m_innerViewportScrollLayer)
        return;

    if (!m_innerViewportScrollLayer) {
        ASSERT(!m_overlayScrollbarHorizontal
            && !m_overlayScrollbarVertical
            && !m_pageScaleLayer
            && !m_innerViewportContainerLayer);

        // FIXME: The root transform layer should only be created on demand.
        m_rootTransformLayer = GraphicsLayer::create(graphicsLayerFactory, this);
        m_innerViewportContainerLayer = GraphicsLayer::create(graphicsLayerFactory, this);
        m_pageScaleLayer = GraphicsLayer::create(graphicsLayerFactory, this);
        m_innerViewportScrollLayer = GraphicsLayer::create(graphicsLayerFactory, this);
        m_overlayScrollbarHorizontal = GraphicsLayer::create(graphicsLayerFactory, this);
        m_overlayScrollbarVertical = GraphicsLayer::create(graphicsLayerFactory, this);

        blink::ScrollingCoordinator* coordinator = m_frameHost.page().scrollingCoordinator();
        ASSERT(coordinator);
        coordinator->setLayerIsContainerForFixedPositionLayers(m_innerViewportScrollLayer.get(), true);

        // Set masks to bounds so the compositor doesn't clobber a manually
        // set inner viewport container layer size.
        m_innerViewportContainerLayer->setMasksToBounds(m_frameHost.settings().mainFrameClipsContent());
        m_innerViewportContainerLayer->setSize(m_size);

        m_innerViewportScrollLayer->platformLayer()->setScrollClipLayer(
            m_innerViewportContainerLayer->platformLayer());
        m_innerViewportScrollLayer->platformLayer()->setUserScrollable(true, true);

        m_rootTransformLayer->addChild(m_innerViewportContainerLayer.get());
        m_innerViewportContainerLayer->addChild(m_pageScaleLayer.get());
        m_pageScaleLayer->addChild(m_innerViewportScrollLayer.get());
        m_innerViewportContainerLayer->addChild(m_overlayScrollbarHorizontal.get());
        m_innerViewportContainerLayer->addChild(m_overlayScrollbarVertical.get());

        // Ensure this class is set as the scroll layer's ScrollableArea.
        coordinator->scrollableAreaScrollLayerDidChange(this);

        // Setup the inner viewport overlay scrollbars.
        setupScrollbar(WebScrollbar::Horizontal);
        setupScrollbar(WebScrollbar::Vertical);
    }

    m_innerViewportScrollLayer->removeAllChildren();
    m_innerViewportScrollLayer->addChild(currentLayerTreeRoot);

    // We only need to disable the existing (outer viewport) scrollbars
    // if the existing ones are already overlay.
    // FIXME: If we knew in advance before the overflowControlsHostLayer goes
    // away, we would re-enable the drawing of these scrollbars.
    // FIXME: This doesn't seem to work (at least on Android). Commenting out for now until
    // I figure out how to access RenderLayerCompositor from here.
    // if (GraphicsLayer* scrollbar = m_frameHost->compositor()->layerForHorizontalScrollbar())
    //    scrollbar->setDrawsContent(!page->mainFrame()->view()->hasOverlayScrollbars());
    // if (GraphicsLayer* scrollbar = m_frameHost->compositor()->layerForVerticalScrollbar())
    //    scrollbar->setDrawsContent(!page->mainFrame()->view()->hasOverlayScrollbars());
}

void PinchViewport::setupScrollbar(WebScrollbar::Orientation orientation)
{
    bool isHorizontal = orientation == WebScrollbar::Horizontal;
    GraphicsLayer* scrollbarGraphicsLayer = isHorizontal ?
        m_overlayScrollbarHorizontal.get() : m_overlayScrollbarVertical.get();
    OwnPtr<WebScrollbarLayer>& webScrollbarLayer = isHorizontal ?
        m_webOverlayScrollbarHorizontal : m_webOverlayScrollbarVertical;

    const int overlayScrollbarThickness = m_frameHost.settings().pinchOverlayScrollbarThickness();

    if (!webScrollbarLayer) {
        ScrollingCoordinator* coordinator = m_frameHost.page().scrollingCoordinator();
        ASSERT(coordinator);
        ScrollbarOrientation webcoreOrientation = isHorizontal ? HorizontalScrollbar : VerticalScrollbar;
        webScrollbarLayer = coordinator->createSolidColorScrollbarLayer(webcoreOrientation, overlayScrollbarThickness, 0, false);

        webScrollbarLayer->setClipLayer(m_innerViewportContainerLayer->platformLayer());
        scrollbarGraphicsLayer->setContentsToPlatformLayer(webScrollbarLayer->layer());
        scrollbarGraphicsLayer->setDrawsContent(false);
    }

    int xPosition = isHorizontal ? 0 : m_innerViewportContainerLayer->size().width() - overlayScrollbarThickness;
    int yPosition = isHorizontal ? m_innerViewportContainerLayer->size().height() - overlayScrollbarThickness : 0;
    int width = isHorizontal ? m_innerViewportContainerLayer->size().width() - overlayScrollbarThickness : overlayScrollbarThickness;
    int height = isHorizontal ? overlayScrollbarThickness : m_innerViewportContainerLayer->size().height() - overlayScrollbarThickness;

    // Use the GraphicsLayer to position the scrollbars.
    scrollbarGraphicsLayer->setPosition(IntPoint(xPosition, yPosition));
    scrollbarGraphicsLayer->setSize(IntSize(width, height));
    scrollbarGraphicsLayer->setContentsRect(IntRect(0, 0, width, height));
}

void PinchViewport::registerLayersWithTreeView(WebLayerTreeView* layerTreeView) const
{
    TRACE_EVENT0("blink", "PinchViewport::registerLayersWithTreeView");
    ASSERT(layerTreeView);
    ASSERT(m_frameHost.page().mainFrame());
    ASSERT(m_frameHost.page().mainFrame()->contentRenderer());

    RenderLayerCompositor* compositor = m_frameHost.page().mainFrame()->contentRenderer()->compositor();
    // Get the outer viewport scroll layer.
    WebLayer* scrollLayer = compositor->scrollLayer()->platformLayer();

    m_webOverlayScrollbarHorizontal->setScrollLayer(scrollLayer);
    m_webOverlayScrollbarVertical->setScrollLayer(scrollLayer);

    ASSERT(compositor);
    layerTreeView->registerViewportLayers(
        m_pageScaleLayer->platformLayer(),
        m_innerViewportScrollLayer->platformLayer(),
        scrollLayer);
}

void PinchViewport::clearLayersForTreeView(WebLayerTreeView* layerTreeView) const
{
    ASSERT(layerTreeView);

    layerTreeView->clearViewportLayers();
}

int PinchViewport::scrollSize(ScrollbarOrientation orientation) const
{
    IntSize scrollDimensions = maximumScrollPosition() - minimumScrollPosition();
    return (orientation == HorizontalScrollbar) ? scrollDimensions.width() : scrollDimensions.height();
}

IntPoint PinchViewport::minimumScrollPosition() const
{
    return IntPoint();
}

IntPoint PinchViewport::maximumScrollPosition() const
{
    return flooredIntPoint(FloatSize(contentsSize()) - visibleRect().size());
}

IntRect PinchViewport::scrollableAreaBoundingBox() const
{
    // This method should return the bounding box in the parent view's coordinate
    // space; however, PinchViewport technically isn't a child of any Frames.
    // Nonetheless, the PinchViewport always occupies the entire main frame so just
    // return that.
    LocalFrame* frame = mainFrame();

    if (!frame || !frame->view())
        return IntRect();

    return frame->view()->frameRect();
}

IntSize PinchViewport::contentsSize() const
{
    LocalFrame* frame = mainFrame();

    if (!frame || !frame->view())
        return IntSize();

    ASSERT(frame->view()->visibleContentScaleFactor() == 1);
    return frame->view()->visibleContentRect(IncludeScrollbars).size();
}

void PinchViewport::invalidateScrollbarRect(Scrollbar*, const IntRect&)
{
    // Do nothing. Pinch scrollbars live on the compositor thread and will
    // be updated when the viewport is synced to the CC.
}

void PinchViewport::setScrollOffset(const IntPoint& offset)
{
    setLocation(offset);
}

GraphicsLayer* PinchViewport::layerForContainer() const
{
    return m_innerViewportContainerLayer.get();
}

GraphicsLayer* PinchViewport::layerForScrolling() const
{
    return m_innerViewportScrollLayer.get();
}

GraphicsLayer* PinchViewport::layerForHorizontalScrollbar() const
{
    return m_overlayScrollbarHorizontal.get();
}

GraphicsLayer* PinchViewport::layerForVerticalScrollbar() const
{
    return m_overlayScrollbarVertical.get();
}

void PinchViewport::notifyAnimationStarted(const GraphicsLayer*, double monotonicTime)
{
}

void PinchViewport::paintContents(const GraphicsLayer*, GraphicsContext&, GraphicsLayerPaintingPhase, const IntRect& inClip)
{
}

LocalFrame* PinchViewport::mainFrame() const
{
    return m_frameHost.page().mainFrame();
}

FloatPoint PinchViewport::clampOffsetToBoundaries(const FloatPoint& offset)
{
    FloatPoint clampedOffset(offset);
    clampedOffset = clampedOffset.shrunkTo(FloatPoint(maximumScrollPosition()));
    clampedOffset = clampedOffset.expandedTo(FloatPoint(minimumScrollPosition()));
    return clampedOffset;
}

String PinchViewport::debugName(const GraphicsLayer* graphicsLayer)
{
    String name;
    if (graphicsLayer == m_innerViewportContainerLayer.get()) {
        name = "Inner Viewport Container Layer";
    } else if (graphicsLayer == m_pageScaleLayer.get()) {
        name =  "Page Scale Layer";
    } else if (graphicsLayer == m_innerViewportScrollLayer.get()) {
        name =  "Inner Viewport Scroll Layer";
    } else if (graphicsLayer == m_overlayScrollbarHorizontal.get()) {
        name =  "Overlay Scrollbar Horizontal Layer";
    } else if (graphicsLayer == m_overlayScrollbarVertical.get()) {
        name =  "Overlay Scrollbar Vertical Layer";
    } else {
        ASSERT_NOT_REACHED();
    }

    return name;
}

} // namespace blink
