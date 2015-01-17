/*
 * Copyright (c) 2008, Google Inc. All rights reserved.
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
 * Copyright (C) 2010 Torch Mobile (Beijing) Co. Ltd. All rights reserved.
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

#include "sky/engine/config.h"
#include "sky/engine/platform/graphics/ImageBuffer.h"

#include "platform/image-encoders/skia/JPEGImageEncoder.h"
#include "platform/image-encoders/skia/PNGImageEncoder.h"
#include "sky/engine/platform/MIMETypeRegistry.h"
#include "sky/engine/platform/geometry/IntRect.h"
#include "sky/engine/platform/graphics/BitmapImage.h"
#include "sky/engine/platform/graphics/GraphicsContext.h"
#include "sky/engine/platform/graphics/GraphicsTypes3D.h"
#include "sky/engine/platform/graphics/ImageBufferClient.h"
#include "sky/engine/platform/graphics/UnacceleratedImageBufferSurface.h"
#include "sky/engine/platform/graphics/gpu/DrawingBuffer.h"
#include "sky/engine/platform/graphics/gpu/Extensions3DUtil.h"
#include "sky/engine/platform/graphics/skia/NativeImageSkia.h"
#include "sky/engine/platform/graphics/skia/SkiaUtils.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/public/platform/WebExternalTextureMailbox.h"
#include "sky/engine/public/platform/WebGraphicsContext3D.h"
#include "sky/engine/public/platform/WebGraphicsContext3DProvider.h"
#include "sky/engine/wtf/MathExtras.h"
#include "sky/engine/wtf/Vector.h"
#include "sky/engine/wtf/text/Base64.h"
#include "sky/engine/wtf/text/WTFString.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/effects/SkTableColorFilter.h"
#include "third_party/skia/include/gpu/GrContext.h"

namespace blink {

PassOwnPtr<ImageBuffer> ImageBuffer::create(PassOwnPtr<ImageBufferSurface> surface)
{
    if (!surface->isValid())
        return nullptr;
    return adoptPtr(new ImageBuffer(surface));
}

PassOwnPtr<ImageBuffer> ImageBuffer::create(const IntSize& size, OpacityMode opacityMode)
{
    OwnPtr<ImageBufferSurface> surface = adoptPtr(new UnacceleratedImageBufferSurface(size, opacityMode));
    if (!surface->isValid())
        return nullptr;
    return adoptPtr(new ImageBuffer(surface.release()));
}

ImageBuffer::ImageBuffer(PassOwnPtr<ImageBufferSurface> surface)
    : m_surface(surface)
    , m_client(0)
{
    if (m_surface->canvas()) {
        m_context = adoptPtr(new GraphicsContext(m_surface->canvas()));
        m_context->setCertainlyOpaque(m_surface->opacityMode() == Opaque);
        m_context->setAccelerated(m_surface->isAccelerated());
    }
    m_surface->setImageBuffer(this);
}

ImageBuffer::~ImageBuffer()
{
}

GraphicsContext* ImageBuffer::context() const
{
    if (!isSurfaceValid())
        return 0;
    ASSERT(m_context.get());
    return m_context.get();
}

const SkBitmap& ImageBuffer::bitmap() const
{
    return m_surface->bitmap();
}

bool ImageBuffer::isSurfaceValid() const
{
    return m_surface->isValid();
}

bool ImageBuffer::isDirty()
{
    return m_client ? m_client->isDirty() : false;
}

void ImageBuffer::didFinalizeFrame()
{
    if (m_client)
        m_client->didFinalizeFrame();
}

void ImageBuffer::finalizeFrame()
{
    m_surface->finalizeFrame();
    didFinalizeFrame();
}

bool ImageBuffer::restoreSurface() const
{
    return m_surface->isValid() || m_surface->restore();
}

void ImageBuffer::notifySurfaceInvalid()
{
    if (m_client)
        m_client->notifySurfaceInvalid();
}

static SkBitmap deepSkBitmapCopy(const SkBitmap& bitmap)
{
    SkBitmap tmp;
    if (!bitmap.deepCopyTo(&tmp))
        bitmap.copyTo(&tmp, bitmap.colorType());

    return tmp;
}

PassRefPtr<Image> ImageBuffer::copyImage(BackingStoreCopy copyBehavior, ScaleBehavior) const
{
    if (!isSurfaceValid())
        return BitmapImage::create(NativeImageSkia::create());

    const SkBitmap& bitmap = m_surface->bitmap();
    return BitmapImage::create(NativeImageSkia::create(copyBehavior == CopyBackingStore ? deepSkBitmapCopy(bitmap) : bitmap));
}

BackingStoreCopy ImageBuffer::fastCopyImageMode()
{
    return DontCopyBackingStore;
}

WebLayer* ImageBuffer::platformLayer() const
{
    return m_surface->layer();
}

bool ImageBuffer::copyToPlatformTexture(WebGraphicsContext3D* context, Platform3DObject texture, GLenum internalFormat, GLenum destType, GLint level, bool premultiplyAlpha, bool flipY)
{
    if (!m_surface->isAccelerated() || !platformLayer() || !isSurfaceValid())
        return false;

    if (!Extensions3DUtil::canUseCopyTextureCHROMIUM(internalFormat, destType, level))
        return false;

    OwnPtr<WebGraphicsContext3DProvider> provider = adoptPtr(Platform::current()->createSharedOffscreenGraphicsContext3DProvider());
    if (!provider)
        return false;
    WebGraphicsContext3D* sharedContext = provider->context3d();
    if (!sharedContext)
        return false;

    OwnPtr<WebExternalTextureMailbox> mailbox = adoptPtr(new WebExternalTextureMailbox);

    // Contexts may be in a different share group. We must transfer the texture through a mailbox first
    sharedContext->genMailboxCHROMIUM(mailbox->name);
    sharedContext->produceTextureDirectCHROMIUM(getBackingTexture(), GL_TEXTURE_2D, mailbox->name);
    sharedContext->flush();

    mailbox->syncPoint = sharedContext->insertSyncPoint();

    context->waitSyncPoint(mailbox->syncPoint);
    Platform3DObject sourceTexture = context->createAndConsumeTextureCHROMIUM(GL_TEXTURE_2D, mailbox->name);

    // The canvas is stored in a premultiplied format, so unpremultiply if necessary.
    context->pixelStorei(GC3D_UNPACK_UNPREMULTIPLY_ALPHA_CHROMIUM, !premultiplyAlpha);

    // The canvas is stored in an inverted position, so the flip semantics are reversed.
    context->pixelStorei(GC3D_UNPACK_FLIP_Y_CHROMIUM, !flipY);
    context->copyTextureCHROMIUM(GL_TEXTURE_2D, sourceTexture, texture, level, internalFormat, destType);

    context->pixelStorei(GC3D_UNPACK_FLIP_Y_CHROMIUM, false);
    context->pixelStorei(GC3D_UNPACK_UNPREMULTIPLY_ALPHA_CHROMIUM, false);

    context->deleteTexture(sourceTexture);

    context->flush();
    sharedContext->waitSyncPoint(context->insertSyncPoint());

    // Undo grContext texture binding changes introduced in this function
    provider->grContext()->resetContext(kTextureBinding_GrGLBackendState);

    return true;
}

static bool drawNeedsCopy(GraphicsContext* src, GraphicsContext* dst)
{
    ASSERT(dst);
    return (src == dst);
}

Platform3DObject ImageBuffer::getBackingTexture()
{
    return m_surface->getBackingTexture();
}

bool ImageBuffer::copyRenderingResultsFromDrawingBuffer(DrawingBuffer* drawingBuffer, bool fromFrontBuffer)
{
    if (!drawingBuffer)
        return false;
    OwnPtr<WebGraphicsContext3DProvider> provider = adoptPtr(Platform::current()->createSharedOffscreenGraphicsContext3DProvider());
    if (!provider)
        return false;
    WebGraphicsContext3D* context3D = provider->context3d();
    Platform3DObject tex = m_surface->getBackingTexture();
    if (!context3D || !tex)
        return false;

    m_surface->invalidateCachedBitmap();
    return drawingBuffer->copyToPlatformTexture(context3D, tex, GL_RGBA,
        GL_UNSIGNED_BYTE, 0, true, false, fromFrontBuffer);
}

void ImageBuffer::draw(GraphicsContext* context, const FloatRect& destRect, const FloatRect* srcPtr, CompositeOperator op, WebBlendMode blendMode)
{
    if (!isSurfaceValid())
        return;

    FloatRect srcRect = srcPtr ? *srcPtr : FloatRect(FloatPoint(), size());
    RefPtr<SkPicture> picture = m_surface->getPicture();
    if (picture) {
        context->drawPicture(picture.release(), destRect, srcRect, op, blendMode);
        return;
    }

    SkBitmap bitmap = m_surface->bitmap();
    // For ImageBufferSurface that enables cachedBitmap, Use the cached Bitmap for CPU side usage
    // if it is available, otherwise generate and use it.
    if (!context->isAccelerated() && m_surface->isAccelerated() && m_surface->cachedBitmapEnabled() && isSurfaceValid()) {
        m_surface->updateCachedBitmapIfNeeded();
        bitmap = m_surface->cachedBitmap();
    }

    RefPtr<Image> image = BitmapImage::create(NativeImageSkia::create(drawNeedsCopy(m_context.get(), context) ? deepSkBitmapCopy(bitmap) : bitmap));

    context->drawImage(image.get(), destRect, srcRect, op, blendMode, DoNotRespectImageOrientation);
}

void ImageBuffer::flush()
{
    if (m_surface->canvas()) {
        m_surface->canvas()->flush();
    }
}

void ImageBuffer::drawPattern(GraphicsContext* context, const FloatRect& srcRect, const FloatSize& scale,
    const FloatPoint& phase, CompositeOperator op, const FloatRect& destRect, WebBlendMode blendMode, const IntSize& repeatSpacing)
{
    if (!isSurfaceValid())
        return;

    const SkBitmap& bitmap = m_surface->bitmap();
    RefPtr<Image> image = BitmapImage::create(NativeImageSkia::create(drawNeedsCopy(m_context.get(), context) ? deepSkBitmapCopy(bitmap) : bitmap));
    image->drawPattern(context, srcRect, scale, phase, op, destRect, blendMode, repeatSpacing);
}

void ImageBuffer::transformColorSpace(ColorSpace srcColorSpace, ColorSpace dstColorSpace)
{
    const uint8_t* lookUpTable = ColorSpaceUtilities::getConversionLUT(dstColorSpace, srcColorSpace);
    if (!lookUpTable)
        return;

    // FIXME: Disable color space conversions on accelerated canvases (for now).
    if (context()->isAccelerated() || !isSurfaceValid())
        return;

    const SkBitmap& bitmap = m_surface->bitmap();
    if (bitmap.isNull())
        return;

    ASSERT(bitmap.colorType() == kN32_SkColorType);
    IntSize size = m_surface->size();
    SkAutoLockPixels bitmapLock(bitmap);
    for (int y = 0; y < size.height(); ++y) {
        uint32_t* srcRow = bitmap.getAddr32(0, y);
        for (int x = 0; x < size.width(); ++x) {
            SkColor color = SkPMColorToColor(srcRow[x]);
            srcRow[x] = SkPreMultiplyARGB(
                SkColorGetA(color),
                lookUpTable[SkColorGetR(color)],
                lookUpTable[SkColorGetG(color)],
                lookUpTable[SkColorGetB(color)]);
        }
    }
}

PassRefPtr<SkColorFilter> ImageBuffer::createColorSpaceFilter(ColorSpace srcColorSpace,
    ColorSpace dstColorSpace)
{
    const uint8_t* lut = ColorSpaceUtilities::getConversionLUT(dstColorSpace, srcColorSpace);
    if (!lut)
        return nullptr;

    return adoptRef(SkTableColorFilter::CreateARGB(0, lut, lut, lut));
}

PassRefPtr<Uint8ClampedArray> ImageBuffer::getImageData(Multiply multiplied, const IntRect& rect) const
{
    if (!isSurfaceValid())
        return Uint8ClampedArray::create(rect.width() * rect.height() * 4);

    float area = 4.0f * rect.width() * rect.height();
    if (area > static_cast<float>(std::numeric_limits<int>::max()))
        return nullptr;

    RefPtr<Uint8ClampedArray> result = Uint8ClampedArray::createUninitialized(rect.width() * rect.height() * 4);

    if (rect.x() < 0
        || rect.y() < 0
        || rect.maxX() > m_surface->size().width()
        || rect.maxY() > m_surface->size().height())
        result->zeroFill();

    SkAlphaType alphaType = (multiplied == Premultiplied) ? kPremul_SkAlphaType : kUnpremul_SkAlphaType;
    SkImageInfo info = SkImageInfo::Make(rect.width(), rect.height(), kRGBA_8888_SkColorType, alphaType);

    m_surface->willAccessPixels();
    context()->readPixels(info, result->data(), 4 * rect.width(), rect.x(), rect.y());
    return result.release();
}

void ImageBuffer::putByteArray(Multiply multiplied, Uint8ClampedArray* source, const IntSize& sourceSize, const IntRect& sourceRect, const IntPoint& destPoint)
{
    if (!isSurfaceValid())
        return;

    ASSERT(sourceRect.width() > 0);
    ASSERT(sourceRect.height() > 0);

    int originX = sourceRect.x();
    int destX = destPoint.x() + sourceRect.x();
    ASSERT(destX >= 0);
    ASSERT(destX < m_surface->size().width());
    ASSERT(originX >= 0);
    ASSERT(originX < sourceRect.maxX());

    int originY = sourceRect.y();
    int destY = destPoint.y() + sourceRect.y();
    ASSERT(destY >= 0);
    ASSERT(destY < m_surface->size().height());
    ASSERT(originY >= 0);
    ASSERT(originY < sourceRect.maxY());

    const size_t srcBytesPerRow = 4 * sourceSize.width();
    const void* srcAddr = source->data() + originY * srcBytesPerRow + originX * 4;
    SkAlphaType alphaType = (multiplied == Premultiplied) ? kPremul_SkAlphaType : kUnpremul_SkAlphaType;
    SkImageInfo info = SkImageInfo::Make(sourceRect.width(), sourceRect.height(), kRGBA_8888_SkColorType, alphaType);

    m_surface->willAccessPixels();

    context()->writePixels(info, srcAddr, srcBytesPerRow, destX, destY);
}

template <typename T>
static bool encodeImage(T& source, const String& mimeType, const double* quality, Vector<char>* output)
{
    Vector<unsigned char>* encodedImage = reinterpret_cast<Vector<unsigned char>*>(output);

    if (mimeType == "image/jpeg") {
        int compressionQuality = JPEGImageEncoder::DefaultCompressionQuality;
        if (quality && *quality >= 0.0 && *quality <= 1.0)
            compressionQuality = static_cast<int>(*quality * 100 + 0.5);
        if (!JPEGImageEncoder::encode(source, compressionQuality, encodedImage))
            return false;
    } else {
        if (!PNGImageEncoder::encode(source, encodedImage))
            return false;
        ASSERT(mimeType == "image/png");
    }

    return true;
}

String ImageBuffer::toDataURL(const String& mimeType, const double* quality) const
{
    ASSERT(MIMETypeRegistry::isSupportedImageMIMETypeForEncoding(mimeType));

    Vector<char> encodedImage;
    if (!isSurfaceValid() || !encodeImage(m_surface->bitmap(), mimeType, quality, &encodedImage))
        return "data:,";
    Vector<char> base64Data;
    base64Encode(encodedImage, base64Data);

    return "data:" + mimeType + ";base64," + base64Data;
}

String ImageDataToDataURL(const ImageDataBuffer& imageData, const String& mimeType, const double* quality)
{
    ASSERT(MIMETypeRegistry::isSupportedImageMIMETypeForEncoding(mimeType));

    Vector<char> encodedImage;
    if (!encodeImage(imageData, mimeType, quality, &encodedImage))
        return "data:,";

    Vector<char> base64Data;
    base64Encode(encodedImage, base64Data);

    return "data:" + mimeType + ";base64," + base64Data;
}

} // namespace blink
