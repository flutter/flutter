// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/frame/ImageBitmap.h"

#include "core/html/HTMLCanvasElement.h"
#include "core/html/HTMLVideoElement.h"
#include "core/html/ImageData.h"
#include "core/html/canvas/CanvasRenderingContext.h"
#include "platform/graphics/BitmapImage.h"
#include "platform/graphics/GraphicsContext.h"
#include "platform/graphics/ImageBuffer.h"
#include "wtf/RefPtr.h"

namespace blink {

static inline IntRect normalizeRect(const IntRect& rect)
{
    return IntRect(std::min(rect.x(), rect.maxX()),
        std::min(rect.y(), rect.maxY()),
        std::max(rect.width(), -rect.width()),
        std::max(rect.height(), -rect.height()));
}

static inline PassRefPtr<Image> cropImage(Image* image, const IntRect& cropRect)
{
    IntRect intersectRect = intersection(IntRect(IntPoint(), image->size()), cropRect);
    if (!intersectRect.width() || !intersectRect.height())
        return nullptr;

    SkBitmap cropped;
    image->nativeImageForCurrentFrame()->bitmap().extractSubset(&cropped, intersectRect);
    return BitmapImage::create(NativeImageSkia::create(cropped));
}

ImageBitmap::ImageBitmap(HTMLImageElement* image, const IntRect& cropRect)
    : m_imageElement(image)
    , m_bitmap(nullptr)
    , m_cropRect(cropRect)
{
    IntRect srcRect = intersection(cropRect, IntRect(0, 0, image->width(), image->height()));
    m_bitmapRect = IntRect(IntPoint(std::max(0, -cropRect.x()), std::max(0, -cropRect.y())), srcRect.size());
    m_bitmapOffset = srcRect.location();

    if (!srcRect.width() || !srcRect.height())
        m_imageElement = nullptr;
    else
        m_imageElement->addClient(this);

    ScriptWrappable::init(this);
}

ImageBitmap::ImageBitmap(HTMLVideoElement* video, const IntRect& cropRect)
    : m_imageElement(nullptr)
    , m_cropRect(cropRect)
    , m_bitmapOffset(IntPoint())
{
    IntSize playerSize;

    if (video->webMediaPlayer())
        playerSize = video->webMediaPlayer()->naturalSize();

    IntRect videoRect = IntRect(IntPoint(), playerSize);
    IntRect srcRect = intersection(cropRect, videoRect);
    IntRect dstRect(IntPoint(), srcRect.size());

    OwnPtr<ImageBuffer> buf = ImageBuffer::create(videoRect.size());
    if (!buf)
        return;
    GraphicsContext* c = buf->context();
    c->clip(dstRect);
    c->translate(-srcRect.x(), -srcRect.y());
    video->paintCurrentFrameInContext(c, videoRect);
    m_bitmap = buf->copyImage(DontCopyBackingStore);
    m_bitmapRect = IntRect(IntPoint(std::max(0, -cropRect.x()), std::max(0, -cropRect.y())), srcRect.size());

    ScriptWrappable::init(this);
}

ImageBitmap::ImageBitmap(HTMLCanvasElement* canvas, const IntRect& cropRect)
    : m_imageElement(nullptr)
    , m_cropRect(cropRect)
    , m_bitmapOffset(IntPoint())
{
    CanvasRenderingContext* sourceContext = canvas->renderingContext();
    if (sourceContext && sourceContext->is3d())
        sourceContext->paintRenderingResultsToCanvas();

    IntRect srcRect = intersection(cropRect, IntRect(IntPoint(), canvas->size()));
    m_bitmapRect = IntRect(IntPoint(std::max(0, -cropRect.x()), std::max(0, -cropRect.y())), srcRect.size());
    m_bitmap = cropImage(canvas->buffer()->copyImage(CopyBackingStore).get(), cropRect);

    ScriptWrappable::init(this);
}

ImageBitmap::ImageBitmap(ImageData* data, const IntRect& cropRect)
    : m_imageElement(nullptr)
    , m_cropRect(cropRect)
    , m_bitmapOffset(IntPoint())
{
    IntRect srcRect = intersection(cropRect, IntRect(IntPoint(), data->size()));

    OwnPtr<ImageBuffer> buf = ImageBuffer::create(data->size());
    if (!buf)
        return;
    if (srcRect.width() > 0 && srcRect.height() > 0)
        buf->putByteArray(Premultiplied, data->data(), data->size(), srcRect, IntPoint(std::min(0, -cropRect.x()), std::min(0, -cropRect.y())));

    m_bitmap = buf->copyImage(DontCopyBackingStore);
    m_bitmapRect = IntRect(IntPoint(std::max(0, -cropRect.x()), std::max(0, -cropRect.y())),  srcRect.size());

    ScriptWrappable::init(this);
}

ImageBitmap::ImageBitmap(ImageBitmap* bitmap, const IntRect& cropRect)
    : m_imageElement(bitmap->imageElement())
    , m_bitmap(nullptr)
    , m_cropRect(cropRect)
    , m_bitmapOffset(IntPoint())
{
    IntRect oldBitmapRect = bitmap->bitmapRect();
    IntRect srcRect = intersection(cropRect, oldBitmapRect);
    m_bitmapRect = IntRect(IntPoint(std::max(0, oldBitmapRect.x() - cropRect.x()), std::max(0, oldBitmapRect.y() - cropRect.y())), srcRect.size());

    if (m_imageElement) {
        m_imageElement->addClient(this);
        m_bitmapOffset = srcRect.location();
    } else if (bitmap->bitmapImage()) {
        IntRect adjustedCropRect(IntPoint(cropRect.x() -oldBitmapRect.x(), cropRect.y() - oldBitmapRect.y()), cropRect.size());
        m_bitmap = cropImage(bitmap->bitmapImage().get(), adjustedCropRect);
    }

    ScriptWrappable::init(this);
}

ImageBitmap::ImageBitmap(Image* image, const IntRect& cropRect)
    : m_imageElement(nullptr)
    , m_cropRect(cropRect)
{
    IntRect srcRect = intersection(cropRect, IntRect(IntPoint(), image->size()));
    m_bitmap = cropImage(image, cropRect);
    m_bitmapRect = IntRect(IntPoint(std::max(0, -cropRect.x()), std::max(0, -cropRect.y())),  srcRect.size());

    ScriptWrappable::init(this);
}

ImageBitmap::~ImageBitmap()
{
#if !ENABLE(OILPAN)
    if (m_imageElement)
        m_imageElement->removeClient(this);
#endif
}

PassRefPtrWillBeRawPtr<ImageBitmap> ImageBitmap::create(HTMLImageElement* image, const IntRect& cropRect)
{
    IntRect normalizedCropRect = normalizeRect(cropRect);
    return adoptRefWillBeNoop(new ImageBitmap(image, normalizedCropRect));
}

PassRefPtrWillBeRawPtr<ImageBitmap> ImageBitmap::create(HTMLVideoElement* video, const IntRect& cropRect)
{
    IntRect normalizedCropRect = normalizeRect(cropRect);
    return adoptRefWillBeNoop(new ImageBitmap(video, normalizedCropRect));
}

PassRefPtrWillBeRawPtr<ImageBitmap> ImageBitmap::create(HTMLCanvasElement* canvas, const IntRect& cropRect)
{
    IntRect normalizedCropRect = normalizeRect(cropRect);
    return adoptRefWillBeNoop(new ImageBitmap(canvas, normalizedCropRect));
}

PassRefPtrWillBeRawPtr<ImageBitmap> ImageBitmap::create(ImageData* data, const IntRect& cropRect)
{
    IntRect normalizedCropRect = normalizeRect(cropRect);
    return adoptRefWillBeNoop(new ImageBitmap(data, normalizedCropRect));
}

PassRefPtrWillBeRawPtr<ImageBitmap> ImageBitmap::create(ImageBitmap* bitmap, const IntRect& cropRect)
{
    IntRect normalizedCropRect = normalizeRect(cropRect);
    return adoptRefWillBeNoop(new ImageBitmap(bitmap, normalizedCropRect));
}

PassRefPtrWillBeRawPtr<ImageBitmap> ImageBitmap::create(Image* image, const IntRect& cropRect)
{
    IntRect normalizedCropRect = normalizeRect(cropRect);
    return adoptRefWillBeNoop(new ImageBitmap(image, normalizedCropRect));
}

void ImageBitmap::notifyImageSourceChanged()
{
    m_bitmap = cropImage(m_imageElement->cachedImage()->image(), m_cropRect);
    m_bitmapOffset = IntPoint();
    m_imageElement = nullptr;
}

PassRefPtr<Image> ImageBitmap::bitmapImage() const
{
    ASSERT((m_imageElement || m_bitmap || !m_bitmapRect.width() || !m_bitmapRect.height()) && (!m_imageElement || !m_bitmap));
    if (m_imageElement)
        return m_imageElement->cachedImage()->image();
    return m_bitmap;
}

PassRefPtr<Image> ImageBitmap::getSourceImageForCanvas(SourceImageMode, SourceImageStatus* status) const
{
    *status = NormalSourceImageStatus;
    return bitmapImage();
}

void ImageBitmap::adjustDrawRects(FloatRect* srcRect, FloatRect* dstRect) const
{
    FloatRect intersectRect = intersection(m_bitmapRect, *srcRect);
    FloatRect newSrcRect = intersectRect;
    newSrcRect.move(m_bitmapOffset - m_bitmapRect.location());
    FloatRect newDstRect(FloatPoint(intersectRect.location() - srcRect->location()), m_bitmapRect.size());
    newDstRect.scale(dstRect->width() / srcRect->width() * intersectRect.width() / m_bitmapRect.width(),
        dstRect->height() / srcRect->height() * intersectRect.height() / m_bitmapRect.height());
    newDstRect.moveBy(dstRect->location());
    *srcRect = newSrcRect;
    *dstRect = newDstRect;
}

FloatSize ImageBitmap::sourceSize() const
{
    return FloatSize(width(), height());
}

void ImageBitmap::trace(Visitor* visitor)
{
    visitor->trace(m_imageElement);
    ImageLoaderClient::trace(visitor);
}

}
