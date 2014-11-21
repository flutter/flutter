/*
 * Copyright (c) 2013, Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_PLATFORM_GRAPHICS_GPU_WEBGLIMAGEBUFFERSURFACE_H_
#define SKY_ENGINE_PLATFORM_GRAPHICS_GPU_WEBGLIMAGEBUFFERSURFACE_H_

#include "sky/engine/platform/graphics/ImageBufferSurface.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "third_party/skia/include/core/SkBitmap.h"

namespace blink {

class WebGraphicsContext3DProvider;

// This is a GPU backed surface that has no canvas or render target.
class PLATFORM_EXPORT WebGLImageBufferSurface : public ImageBufferSurface {
    WTF_MAKE_NONCOPYABLE(WebGLImageBufferSurface); WTF_MAKE_FAST_ALLOCATED;
public:
    WebGLImageBufferSurface(const IntSize&, OpacityMode = NonOpaque);
    virtual ~WebGLImageBufferSurface();

    virtual SkCanvas* canvas() const override { return 0; }
    virtual const SkBitmap& bitmap() override { return m_bitmap; }
    virtual bool isValid() const override { return m_bitmap.pixelRef(); }
    virtual bool isAccelerated() const override { return true; }
    virtual Platform3DObject getBackingTexture() const override;
    virtual bool cachedBitmapEnabled() const override { return true; }
    virtual const SkBitmap& cachedBitmap() const override { return m_cachedBitmap; }
    virtual void invalidateCachedBitmap() override;
    virtual void updateCachedBitmapIfNeeded() override;

private:
    SkBitmap m_bitmap;
    // This raw-pixel based SkBitmap works as a cache at CPU side to avoid heavy cost
    // on readback from GPU side to CPU side in some cases.
    SkBitmap m_cachedBitmap;
    OwnPtr<WebGraphicsContext3DProvider> m_contextProvider;
};

} // namespace blink

#endif  // SKY_ENGINE_PLATFORM_GRAPHICS_GPU_WEBGLIMAGEBUFFERSURFACE_H_
