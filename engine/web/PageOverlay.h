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

#ifndef PageOverlay_h
#define PageOverlay_h

#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"

namespace blink {

class GraphicsContext;
class GraphicsLayer;
class GraphicsLayerClient;
class OverlayGraphicsLayerClientImpl;
class WebPageOverlay;
class WebViewImpl;
struct WebRect;

class PageOverlay {
public:
    static PassOwnPtr<PageOverlay> create(WebViewImpl*, WebPageOverlay*);

    ~PageOverlay() { }

    WebPageOverlay* overlay() const { return m_overlay; }
    void setOverlay(WebPageOverlay* overlay) { m_overlay = overlay; }

    int zOrder() const { return m_zOrder; }
    void setZOrder(int zOrder) { m_zOrder = zOrder; }

    void clear();
    void update();
    void paintWebFrame(GraphicsContext&);

    GraphicsLayer* graphicsLayer() const { return m_layer.get(); }

private:
    PageOverlay(WebViewImpl*, WebPageOverlay*);
    void invalidateWebFrame();

    WebViewImpl* m_viewImpl;
    WebPageOverlay* m_overlay;
    OwnPtr<GraphicsLayerClient> m_layerClient;
    OwnPtr<GraphicsLayer> m_layer;
    int m_zOrder;
};

} // namespace blink

#endif // PageOverlay_h
