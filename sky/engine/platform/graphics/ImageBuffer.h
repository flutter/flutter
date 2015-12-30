/*
 * Copyright (C) 2006 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2007, 2008, 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2010 Torch Mobile (Beijing) Co. Ltd. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
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

#ifndef SKY_ENGINE_PLATFORM_GRAPHICS_IMAGEBUFFER_H_
#define SKY_ENGINE_PLATFORM_GRAPHICS_IMAGEBUFFER_H_

#include "sky/engine/platform/PlatformExport.h"
#include "sky/engine/platform/geometry/FloatRect.h"
#include "sky/engine/platform/geometry/IntSize.h"
#include "sky/engine/platform/graphics/ColorSpace.h"
#include "sky/engine/platform/graphics/GraphicsTypes.h"
#include "sky/engine/platform/graphics/ImageBufferSurface.h"
#include "sky/engine/platform/transforms/AffineTransform.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/Uint8ClampedArray.h"

namespace blink {

class GraphicsContext;
class Image;
class ImageBufferClient;
class IntPoint;
class IntRect;
class WebGraphicsContext3D;

enum Multiply {
    Premultiplied,
    Unmultiplied
};

enum BackingStoreCopy {
    CopyBackingStore, // Guarantee subsequent draws don't affect the copy.
    DontCopyBackingStore // Subsequent draws may affect the copy.
};

enum ScaleBehavior {
    Scaled,
    Unscaled
};

class PLATFORM_EXPORT ImageBuffer {
    WTF_MAKE_NONCOPYABLE(ImageBuffer); WTF_MAKE_FAST_ALLOCATED;
public:
    static PassOwnPtr<ImageBuffer> create(const IntSize&, OpacityMode = NonOpaque);
    static PassOwnPtr<ImageBuffer> create(PassOwnPtr<ImageBufferSurface>);

    ~ImageBuffer();

    void setClient(ImageBufferClient* client) { m_client = client; }

    const IntSize& size() const { return m_surface->size(); }
    bool isAccelerated() const { return m_surface->isAccelerated(); }
    bool isSurfaceValid() const;
    bool restoreSurface() const;

    void setIsHidden(bool hidden) { m_surface->setIsHidden(hidden); }

    GraphicsContext* context() const;

    // Called at the end of a task that rendered a whole frame
    void finalizeFrame();
    void didFinalizeFrame();

    bool isDirty();

    const SkBitmap& bitmap() const;

    PassRefPtr<Image> copyImage(BackingStoreCopy = CopyBackingStore, ScaleBehavior = Scaled) const;
    // Give hints on the faster copyImage Mode, return DontCopyBackingStore if it supports the DontCopyBackingStore behavior
    // or return CopyBackingStore if it doesn't.
    static BackingStoreCopy fastCopyImageMode();

    PassRefPtr<Uint8ClampedArray> getImageData(Multiply, const IntRect&) const;

    void putByteArray(Multiply, Uint8ClampedArray*, const IntSize& sourceSize, const IntRect& sourceRect, const IntPoint& destPoint);

    AffineTransform baseTransform() const { return AffineTransform(); }
    void transformColorSpace(ColorSpace srcColorSpace, ColorSpace dstColorSpace);
    WebLayer* platformLayer() const;

    void flush();

    void notifySurfaceInvalid();

private:
    ImageBuffer(PassOwnPtr<ImageBufferSurface>);

    void draw(GraphicsContext*, const FloatRect&, const FloatRect* = 0, CompositeOperator = CompositeSourceOver, WebBlendMode = WebBlendModeNormal);
    void drawPattern(GraphicsContext*, const FloatRect&, const FloatSize&, const FloatPoint&, CompositeOperator, const FloatRect&, WebBlendMode, const IntSize& repeatSpacing = IntSize());
    static PassRefPtr<SkColorFilter> createColorSpaceFilter(ColorSpace srcColorSpace, ColorSpace dstColorSpace);

    friend class GraphicsContext;
    friend class GeneratedImage;
    friend class CrossfadeGeneratedImage;
    friend class GradientGeneratedImage;
    friend class SkiaImageFilterBuilder;

    OwnPtr<ImageBufferSurface> m_surface;
    OwnPtr<GraphicsContext> m_context;
    ImageBufferClient* m_client;
};

struct ImageDataBuffer {
    ImageDataBuffer(const IntSize& size, PassRefPtr<Uint8ClampedArray> data) : m_size(size), m_data(data) { }
    IntSize size() const { return m_size; }
    unsigned char* data() const { return m_data->data(); }

    IntSize m_size;
    RefPtr<Uint8ClampedArray> m_data;
};

} // namespace blink

#endif  // SKY_ENGINE_PLATFORM_GRAPHICS_IMAGEBUFFER_H_
