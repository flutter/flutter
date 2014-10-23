/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef WebExternalTextureLayer_h
#define WebExternalTextureLayer_h

#include "WebCommon.h"
#include "WebFloatRect.h"
#include "WebLayer.h"

namespace blink {

class WebExternalTextureLayerClient;

// This class represents a layer that renders a texture that is generated
// externally (not managed by the WebLayerTreeView).
// The texture will be used by the WebLayerTreeView during compositing passes.
// When in single-thread mode, this means during WebLayerTreeView::composite().
// When using the threaded compositor, this can mean at an arbitrary time until
// the WebLayerTreeView is destroyed.
class WebExternalTextureLayer {
public:
    virtual ~WebExternalTextureLayer() { }

    virtual WebLayer* layer() = 0;

    // Clears texture from the layer.
    virtual void clearTexture() = 0;

    // Sets whether every pixel in this layer is opaque. Defaults to false.
    virtual void setOpaque(bool) = 0;

    // Sets whether this layer's texture has premultiplied alpha or not. Defaults to true.
    virtual void setPremultipliedAlpha(bool) = 0;

    // Sets whether the texture should be blended with the background color
    // at draw time. Defaults to false.
    virtual void setBlendBackgroundColor(bool) = 0;

    // Sets whether this context should be rate limited by the compositor. Rate limiting works by blocking
    // invalidate() and invalidateRect() calls if the compositor is too many frames behind.
    virtual void setRateLimitContext(bool) = 0;
};

} // namespace blink

#endif // WebExternalTextureLayer_h
