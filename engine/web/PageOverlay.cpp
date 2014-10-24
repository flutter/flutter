/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * 1. Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY GOOGLE INC. AND ITS CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL GOOGLE INC.
 * OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "web/PageOverlay.h"

#include "core/frame/Settings.h"
#include "core/page/Page.h"
#include "platform/graphics/GraphicsContext.h"
#include "platform/graphics/GraphicsLayer.h"
#include "platform/graphics/GraphicsLayerClient.h"
#include "public/platform/WebLayer.h"
#include "public/web/WebPageOverlay.h"
#include "public/web/WebViewClient.h"
#include "web/WebViewImpl.h"

namespace blink {

namespace {

WebCanvas* ToWebCanvas(GraphicsContext* gc)
{
    return gc->canvas();
}

} // namespace

PassOwnPtr<PageOverlay> PageOverlay::create(WebViewImpl* viewImpl, WebPageOverlay* overlay)
{
    return adoptPtr(new PageOverlay(viewImpl, overlay));
}

PageOverlay::PageOverlay(WebViewImpl* viewImpl, WebPageOverlay* overlay)
    : m_viewImpl(viewImpl)
    , m_overlay(overlay)
    , m_zOrder(0)
{
}

class OverlayGraphicsLayerClientImpl : public GraphicsLayerClient {
public:
    static PassOwnPtr<OverlayGraphicsLayerClientImpl> create(WebPageOverlay* overlay)
    {
        return adoptPtr(new OverlayGraphicsLayerClientImpl(overlay));
    }

    virtual ~OverlayGraphicsLayerClientImpl() { }

    virtual void notifyAnimationStarted(const GraphicsLayer*, double monotonicTime) override { }

    virtual void paintContents(const GraphicsLayer*, GraphicsContext& gc, GraphicsLayerPaintingPhase, const IntRect& inClip)
    {
        gc.save();
        m_overlay->paintPageOverlay(ToWebCanvas(&gc));
        gc.restore();
    }

    virtual String debugName(const GraphicsLayer* graphicsLayer) override
    {
        return String("WebViewImpl Page Overlay Content Layer");
    }

private:
    explicit OverlayGraphicsLayerClientImpl(WebPageOverlay* overlay)
        : m_overlay(overlay)
    {
    }

    WebPageOverlay* m_overlay;
};

void PageOverlay::clear()
{
    invalidateWebFrame();

    if (m_layer) {
        m_layer->removeFromParent();
        m_layer = nullptr;
        m_layerClient = nullptr;
    }
}

void PageOverlay::update()
{
    invalidateWebFrame();

    if (!m_layer) {
        m_layerClient = OverlayGraphicsLayerClientImpl::create(m_overlay);
        m_layer = GraphicsLayer::create(m_viewImpl->graphicsLayerFactory(), m_layerClient.get());
        m_layer->setDrawsContent(true);

        // This is required for contents of overlay to stay in sync with the page while scrolling.
        WebLayer* platformLayer = m_layer->platformLayer();
        platformLayer->setShouldScrollOnMainThread(true);
    }

    FloatSize size(m_viewImpl->size());
    if (size != m_layer->size()) {
        // Triggers re-adding to root layer to ensure that we are on top of
        // scrollbars.
        m_layer->removeFromParent();
        m_layer->setSize(size);
    }

    m_viewImpl->setOverlayLayer(m_layer.get());
    m_layer->setNeedsDisplay();
}

void PageOverlay::paintWebFrame(GraphicsContext& gc)
{
    if (!m_viewImpl->isAcceleratedCompositingActive()) {
        gc.save();
        m_overlay->paintPageOverlay(ToWebCanvas(&gc));
        gc.restore();
    }
}

void PageOverlay::invalidateWebFrame()
{
    // WebPageOverlay does the actual painting of the overlay.
    // Here we just make sure to invalidate.
    if (!m_viewImpl->isAcceleratedCompositingActive()) {
        // FIXME: able to invalidate a smaller rect.
        // FIXME: Is it important to just invalidate a smaller rect given that
        // this is not on a critical codepath? In order to do so, we'd
        // have to take scrolling into account.
        const WebSize& size = m_viewImpl->size();
        WebRect damagedRect(0, 0, size.width, size.height);
        if (m_viewImpl->client())
            m_viewImpl->client()->didInvalidateRect(damagedRect);
    }
}

} // namespace blink
