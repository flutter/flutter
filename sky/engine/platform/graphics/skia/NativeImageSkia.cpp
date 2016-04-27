/*
 * Copyright (c) 2008, Google Inc. All rights reserved.
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

#include "sky/engine/platform/graphics/skia/NativeImageSkia.h"

#include "skia/ext/image_operations.h"
#include "sky/engine/platform/TraceEvent.h"
#include "sky/engine/platform/geometry/FloatPoint.h"
#include "sky/engine/platform/geometry/FloatRect.h"
#include "sky/engine/platform/geometry/FloatSize.h"
#include "sky/engine/platform/graphics/DeferredImageDecoder.h"
#include "sky/engine/platform/graphics/GraphicsContext.h"
#include "sky/engine/platform/graphics/Image.h"
#include "sky/engine/platform/graphics/skia/SkiaUtils.h"
#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkPaint.h"
#include "third_party/skia/include/core/SkScalar.h"
#include "third_party/skia/include/core/SkShader.h"

#include <math.h>

namespace blink {

// This function is used to scale an image and extract a scaled fragment.
//
// ALGORITHM
//
// Because the scaled image size has to be integers, we approximate the real
// scale with the following formula (only X direction is shown):
//
// scaledImageWidth = round(scaleX * imageRect.width())
// approximateScaleX = scaledImageWidth / imageRect.width()
//
// With this method we maintain a constant scale factor among fragments in
// the scaled image. This allows fragments to stitch together to form the
// full scaled image. The downside is there will be a small difference
// between |scaleX| and |approximateScaleX|.
//
// A scaled image fragment is identified by:
//
// - Scaled image size
// - Scaled image fragment rectangle (IntRect)
//
// Scaled image size has been determined and the next step is to compute the
// rectangle for the scaled image fragment which needs to be an IntRect.
//
// scaledSrcRect = srcRect * (approximateScaleX, approximateScaleY)
// enclosingScaledSrcRect = enclosingIntRect(scaledSrcRect)
//
// Finally we extract the scaled image fragment using
// (scaledImageSize, enclosingScaledSrcRect).
//
SkBitmap NativeImageSkia::extractScaledImageFragment(const SkRect& srcRect, float scaleX, float scaleY, SkRect* scaledSrcRect) const
{
    SkISize imageSize = SkISize::Make(bitmap().width(), bitmap().height());
    SkISize scaledImageSize = SkISize::Make(clampToInteger(roundf(imageSize.width() * scaleX)),
        clampToInteger(roundf(imageSize.height() * scaleY)));

    SkRect imageRect = SkRect::MakeWH(imageSize.width(), imageSize.height());
    SkRect scaledImageRect = SkRect::MakeWH(scaledImageSize.width(), scaledImageSize.height());

    SkMatrix scaleTransform;
    scaleTransform.setRectToRect(imageRect, scaledImageRect, SkMatrix::kFill_ScaleToFit);
    scaleTransform.mapRect(scaledSrcRect, srcRect);

    bool ok = scaledSrcRect->intersect(scaledImageRect);
    ASSERT_UNUSED(ok, ok);
    SkIRect enclosingScaledSrcRect = enclosingIntRect(*scaledSrcRect);

    // |enclosingScaledSrcRect| can be larger than |scaledImageSize| because
    // of float inaccuracy so clip to get inside.
    ok = enclosingScaledSrcRect.intersect(SkIRect::MakeSize(scaledImageSize));
    ASSERT_UNUSED(ok, ok);

    // scaledSrcRect is relative to the pixel snapped fragment we're extracting.
    scaledSrcRect->offset(-enclosingScaledSrcRect.x(), -enclosingScaledSrcRect.y());

    return resizedBitmap(scaledImageSize, enclosingScaledSrcRect);
}

NativeImageSkia::NativeImageSkia()
    : m_resizeRequests(0)
{
}

NativeImageSkia::NativeImageSkia(const SkBitmap& other)
    : m_bitmap(other)
    , m_resizeRequests(0)
{
}

NativeImageSkia::~NativeImageSkia()
{
}

bool NativeImageSkia::hasResizedBitmap(const SkISize& scaledImageSize, const SkIRect& scaledImageSubset) const
{
    bool imageScaleEqual = m_cachedImageInfo.scaledImageSize == scaledImageSize;
    bool scaledImageSubsetAvailable = m_cachedImageInfo.scaledImageSubset.contains(scaledImageSubset);
    return imageScaleEqual && scaledImageSubsetAvailable && !m_resizedImage.empty();
}

SkBitmap NativeImageSkia::resizedBitmap(const SkISize& scaledImageSize, const SkIRect& scaledImageSubset) const
{
    ASSERT(!DeferredImageDecoder::isLazyDecoded(bitmap()));

    if (!hasResizedBitmap(scaledImageSize, scaledImageSubset)) {
        bool shouldCache = isDataComplete()
            && shouldCacheResampling(scaledImageSize, scaledImageSubset);

        SkBitmap resizedImage = skia::ImageOperations::Resize(bitmap(), skia::ImageOperations::RESIZE_LANCZOS3, scaledImageSize.width(), scaledImageSize.height(), scaledImageSubset);
        resizedImage.setImmutable();

        if (!shouldCache)
            return resizedImage;

        m_resizedImage = resizedImage;
    }

    SkBitmap resizedSubset;
    SkIRect resizedSubsetRect = m_cachedImageInfo.rectInSubset(scaledImageSubset);
    m_resizedImage.extractSubset(&resizedSubset, resizedSubsetRect);
    return resizedSubset;
}

void NativeImageSkia::draw(
    GraphicsContext* context,
    const SkRect& srcRect,
    const SkRect& destRect,
    CompositeOperator compositeOp,
    WebBlendMode blendMode) const
{
    TRACE_EVENT0("skia", "NativeImageSkia::draw");

    bool isLazyDecoded = DeferredImageDecoder::isLazyDecoded(bitmap());

    SkPaint paint;
    context->preparePaintForDrawRectToRect(&paint, srcRect, destRect, compositeOp, blendMode, isLazyDecoded, isDataComplete());
    // We want to filter it if we decided to do interpolation above, or if
    // there is something interesting going on with the matrix (like a rotation).
    // Note: for serialization, we will want to subset the bitmap first so we
    // don't send extra pixels.
    context->drawBitmapRect(bitmap(), &srcRect, destRect, &paint);
    context->didDrawRect(destRect, paint, &bitmap());
}

static SkBitmap createBitmapWithSpace(const SkBitmap& bitmap, int spaceWidth, int spaceHeight)
{
    SkImageInfo info = bitmap.info();
    SkImageInfo newInfo = SkImageInfo::Make(
        info.width() + spaceWidth, info.height() + spaceHeight,
        info.colorType(), kPremul_SkAlphaType, info.profileType());

    SkBitmap result;
    result.allocPixels(newInfo);
    result.eraseColor(SK_ColorTRANSPARENT);
    bitmap.copyPixelsTo(reinterpret_cast<uint8_t*>(result.getPixels()), result.rowBytes() * result.height(), result.rowBytes());

    return result;
}

void NativeImageSkia::drawPattern(
    GraphicsContext* context,
    const FloatRect& floatSrcRect,
    const FloatSize& scale,
    const FloatPoint& phase,
    CompositeOperator compositeOp,
    const FloatRect& destRect,
    WebBlendMode blendMode,
    const IntSize& repeatSpacing) const
{
    FloatRect normSrcRect = floatSrcRect;
    normSrcRect.intersect(FloatRect(0, 0, bitmap().width(), bitmap().height()));
    if (destRect.isEmpty() || normSrcRect.isEmpty())
        return; // nothing to draw

    SkMatrix totalMatrix = context->getTotalMatrix();
    AffineTransform ctm = context->getCTM();
    SkScalar ctmScaleX = ctm.xScale();
    SkScalar ctmScaleY = ctm.yScale();
    totalMatrix.preScale(scale.width(), scale.height());

    // Figure out what size the bitmap will be in the destination. The
    // destination rect is the bounds of the pattern, we need to use the
    // matrix to see how big it will be.
    SkRect destRectTarget;
    totalMatrix.mapRect(&destRectTarget, normSrcRect);

    float destBitmapWidth = SkScalarToFloat(destRectTarget.width());
    float destBitmapHeight = SkScalarToFloat(destRectTarget.height());

    bool isLazyDecoded = DeferredImageDecoder::isLazyDecoded(bitmap());

    // Compute the resampling mode.
    InterpolationQuality resampling;
    if (context->isAccelerated())
        resampling = InterpolationLow;
    else if (isLazyDecoded)
        resampling = InterpolationHigh;
    else
        resampling = computeInterpolationQuality(totalMatrix, normSrcRect.width(), normSrcRect.height(), destBitmapWidth, destBitmapHeight, isDataComplete());
    resampling = limitInterpolationQuality(context, resampling);

    SkMatrix localMatrix;
    // We also need to translate it such that the origin of the pattern is the
    // origin of the destination rect, which is what WebKit expects. Skia uses
    // the coordinate system origin as the base for the pattern. If WebKit wants
    // a shifted image, it will shift it from there using the localMatrix.
    const float adjustedX = phase.x() + normSrcRect.x() * scale.width();
    const float adjustedY = phase.y() + normSrcRect.y() * scale.height();
    localMatrix.setTranslate(SkFloatToScalar(adjustedX), SkFloatToScalar(adjustedY));

    sk_sp<SkShader> shader;
    SkFilterQuality filterLevel = static_cast<SkFilterQuality>(resampling);

    // Bicubic filter is only applied to defer-decoded images, see
    // NativeImageSkia::draw for details.
    if (resampling == InterpolationHigh && !isLazyDecoded) {
        // Do nice resampling.
        filterLevel = kNone_SkFilterQuality;
        float scaleX = destBitmapWidth / normSrcRect.width();
        float scaleY = destBitmapHeight / normSrcRect.height();
        SkRect scaledSrcRect;

        // Since we are resizing the bitmap, we need to remove the scale
        // applied to the pixels in the bitmap shader. This means we need
        // CTM * localMatrix to have identity scale. Since we
        // can't modify CTM (or the rectangle will be drawn in the wrong
        // place), we must set localMatrix's scale to the inverse of
        // CTM scale.
        localMatrix.preScale(ctmScaleX ? 1 / ctmScaleX : 1, ctmScaleY ? 1 / ctmScaleY : 1);

        // The image fragment generated here is not exactly what is
        // requested. The scale factor used is approximated and image
        // fragment is slightly larger to align to integer
        // boundaries.
        SkBitmap resampled = extractScaledImageFragment(normSrcRect, scaleX, scaleY, &scaledSrcRect);
        if (repeatSpacing.isZero()) {
            shader = SkShader::MakeBitmapShader(resampled, SkShader::kRepeat_TileMode, SkShader::kRepeat_TileMode, &localMatrix);
        } else {
            shader = SkShader::MakeBitmapShader(
                createBitmapWithSpace(resampled, repeatSpacing.width() * ctmScaleX, repeatSpacing.height() * ctmScaleY),
                SkShader::kRepeat_TileMode, SkShader::kRepeat_TileMode, &localMatrix);
        }
    } else {
        // Because no resizing occurred, the shader transform should be
        // set to the pattern's transform, which just includes scale.
        localMatrix.preScale(scale.width(), scale.height());

        // No need to resample before drawing.
        SkBitmap srcSubset;
        bitmap().extractSubset(&srcSubset, enclosingIntRect(normSrcRect));
        if (repeatSpacing.isZero()) {
            shader = SkShader::MakeBitmapShader(srcSubset, SkShader::kRepeat_TileMode, SkShader::kRepeat_TileMode, &localMatrix);
        } else {
            shader = SkShader::MakeBitmapShader(
                createBitmapWithSpace(srcSubset, repeatSpacing.width() * ctmScaleX, repeatSpacing.height() * ctmScaleY),
                SkShader::kRepeat_TileMode, SkShader::kRepeat_TileMode, &localMatrix);
        }
    }

    SkPaint paint;
    paint.setShader(shader);
    paint.setXfermodeMode(WebCoreCompositeToSkiaComposite(compositeOp, blendMode));
    paint.setColorFilter(sk_ref_sp(context->colorFilter()));
    paint.setFilterQuality(filterLevel);
    context->drawRect(destRect, paint);
}

bool NativeImageSkia::shouldCacheResampling(const SkISize& scaledImageSize, const SkIRect& scaledImageSubset) const
{
    // Check whether the requested dimensions match previous request.
    bool matchesPreviousRequest = m_cachedImageInfo.isEqual(scaledImageSize, scaledImageSubset);
    if (matchesPreviousRequest)
        ++m_resizeRequests;
    else {
        m_cachedImageInfo.set(scaledImageSize, scaledImageSubset);
        m_resizeRequests = 0;
        // Reset m_resizedImage now, because we don't distinguish
        // between the last requested resize info and m_resizedImage's
        // resize info.
        m_resizedImage.reset();
    }

    // We can not cache incomplete frames. This might be a good optimization in
    // the future, were we know how much of the frame has been decoded, so when
    // we incrementally draw more of the image, we only have to resample the
    // parts that are changed.
    if (!isDataComplete())
        return false;

    // If the destination bitmap is excessively large, we'll never allow caching.
    static const unsigned long long kLargeBitmapSize = 4096ULL * 4096ULL;
    unsigned long long fullSize = static_cast<unsigned long long>(scaledImageSize.width()) * static_cast<unsigned long long>(scaledImageSize.height());
    unsigned long long fragmentSize = static_cast<unsigned long long>(scaledImageSubset.width()) * static_cast<unsigned long long>(scaledImageSubset.height());

    if (fragmentSize > kLargeBitmapSize)
        return false;

    // If the destination bitmap is small, we'll always allow caching, since
    // there is not very much penalty for computing it and it may come in handy.
    static const unsigned kSmallBitmapSize = 4096;
    if (fragmentSize <= kSmallBitmapSize)
        return true;

    // If "too many" requests have been made for this bitmap, we assume that
    // many more will be made as well, and we'll go ahead and cache it.
    static const int kManyRequestThreshold = 4;
    if (m_resizeRequests >= kManyRequestThreshold)
        return true;

    // If more than 1/4 of the resized image is requested, it's worth caching.
    return fragmentSize > fullSize / 4;
}

NativeImageSkia::ImageResourceInfo::ImageResourceInfo()
{
    scaledImageSize.setEmpty();
    scaledImageSubset.setEmpty();
}

bool NativeImageSkia::ImageResourceInfo::isEqual(const SkISize& otherScaledImageSize, const SkIRect& otherScaledImageSubset) const
{
    return scaledImageSize == otherScaledImageSize && scaledImageSubset == otherScaledImageSubset;
}

void NativeImageSkia::ImageResourceInfo::set(const SkISize& otherScaledImageSize, const SkIRect& otherScaledImageSubset)
{
    scaledImageSize = otherScaledImageSize;
    scaledImageSubset = otherScaledImageSubset;
}

SkIRect NativeImageSkia::ImageResourceInfo::rectInSubset(const SkIRect& otherScaledImageSubset)
{
    if (!scaledImageSubset.contains(otherScaledImageSubset))
        return SkIRect::MakeEmpty();
    SkIRect subsetRect = otherScaledImageSubset;
    subsetRect.offset(-scaledImageSubset.x(), -scaledImageSubset.y());
    return subsetRect;
}

} // namespace blink
