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

#ifndef Canvas2DImageBufferSurface_h
#define Canvas2DImageBufferSurface_h

#include "platform/graphics/Canvas2DLayerBridge.h"
#include "platform/graphics/ImageBufferSurface.h"

namespace blink {

// This shim necessary because ImageBufferSurfaces are not allowed to be RefCounted
class Canvas2DImageBufferSurface FINAL : public ImageBufferSurface {
public:
    Canvas2DImageBufferSurface(const IntSize& size, OpacityMode opacityMode = NonOpaque, int msaaSampleCount = 1)
        : ImageBufferSurface(size, opacityMode)
        , m_layerBridge(Canvas2DLayerBridge::create(size, opacityMode, msaaSampleCount))
    {
        clear();
    }

    virtual ~Canvas2DImageBufferSurface()
    {
        if (m_layerBridge)
            m_layerBridge->beginDestruction();
    }

    // ImageBufferSurface implementation
    virtual void finalizeFrame(const FloatRect &dirtyRect) OVERRIDE { m_layerBridge->finalizeFrame(dirtyRect); }
    virtual void willAccessPixels() OVERRIDE { m_layerBridge->willAccessPixels(); }
    virtual SkCanvas* canvas() const OVERRIDE { return m_layerBridge->canvas(); }
    virtual bool isValid() const OVERRIDE { return m_layerBridge && m_layerBridge->checkSurfaceValid(); }
    virtual bool restore() OVERRIDE { return m_layerBridge->restoreSurface(); }
    virtual WebLayer* layer() const OVERRIDE { return m_layerBridge->layer(); }
    virtual Platform3DObject getBackingTexture() const OVERRIDE { return m_layerBridge->getBackingTexture(); }
    virtual bool isAccelerated() const OVERRIDE { return m_layerBridge->isAccelerated(); }
    virtual void setIsHidden(bool hidden) OVERRIDE { m_layerBridge->setIsHidden(hidden); }
    virtual void setImageBuffer(ImageBuffer* imageBuffer) OVERRIDE { m_layerBridge->setImageBuffer(imageBuffer); }

private:
    RefPtr<Canvas2DLayerBridge> m_layerBridge;
};

} // namespace blink

#endif
