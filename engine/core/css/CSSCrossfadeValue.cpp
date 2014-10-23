/*
 * Copyright (C) 2011 Apple Inc.  All rights reserved.
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

#include "config.h"
#include "core/css/CSSCrossfadeValue.h"

#include "core/css/CSSImageValue.h"
#include "core/rendering/RenderObject.h"
#include "core/rendering/style/StyleFetchedImage.h"
#include "platform/graphics/CrossfadeGeneratedImage.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

static bool subimageIsPending(CSSValue* value)
{
    if (value->isImageValue())
        return toCSSImageValue(value)->cachedOrPendingImage()->isPendingImage();

    if (value->isImageGeneratorValue())
        return toCSSImageGeneratorValue(value)->isPending();

    ASSERT_NOT_REACHED();

    return false;
}

static bool subimageKnownToBeOpaque(CSSValue* value, const RenderObject* renderer)
{
    if (value->isImageValue())
        return toCSSImageValue(value)->knownToBeOpaque(renderer);

    if (value->isImageGeneratorValue())
        return toCSSImageGeneratorValue(value)->knownToBeOpaque(renderer);

    ASSERT_NOT_REACHED();

    return false;
}

static ImageResource* cachedImageForCSSValue(CSSValue* value, ResourceFetcher* fetcher)
{
    if (!value)
        return 0;

    if (value->isImageValue()) {
        StyleFetchedImage* styleImageResource = toCSSImageValue(value)->cachedImage(fetcher);
        if (!styleImageResource)
            return 0;

        return styleImageResource->cachedImage();
    }

    if (value->isImageGeneratorValue()) {
        toCSSImageGeneratorValue(value)->loadSubimages(fetcher);
        // FIXME: Handle CSSImageGeneratorValue (and thus cross-fades with gradients and canvas).
        return 0;
    }

    ASSERT_NOT_REACHED();

    return 0;
}

CSSCrossfadeValue::~CSSCrossfadeValue()
{
    if (m_cachedFromImage)
        m_cachedFromImage->removeClient(&m_crossfadeSubimageObserver);
    if (m_cachedToImage)
        m_cachedToImage->removeClient(&m_crossfadeSubimageObserver);
}

String CSSCrossfadeValue::customCSSText() const
{
    StringBuilder result;
    result.appendLiteral("-webkit-cross-fade(");
    result.append(m_fromValue->cssText());
    result.appendLiteral(", ");
    result.append(m_toValue->cssText());
    result.appendLiteral(", ");
    result.append(m_percentageValue->cssText());
    result.append(')');
    return result.toString();
}

IntSize CSSCrossfadeValue::fixedSize(const RenderObject* renderer)
{
    float percentage = m_percentageValue->getFloatValue();
    float inversePercentage = 1 - percentage;

    ResourceFetcher* fetcher = renderer->document().fetcher();
    ImageResource* cachedFromImage = cachedImageForCSSValue(m_fromValue.get(), fetcher);
    ImageResource* cachedToImage = cachedImageForCSSValue(m_toValue.get(), fetcher);

    if (!cachedFromImage || !cachedToImage)
        return IntSize();

    IntSize fromImageSize = cachedFromImage->imageForRenderer(renderer)->size();
    IntSize toImageSize = cachedToImage->imageForRenderer(renderer)->size();

    // Rounding issues can cause transitions between images of equal size to return
    // a different fixed size; avoid performing the interpolation if the images are the same size.
    if (fromImageSize == toImageSize)
        return fromImageSize;

    return IntSize(fromImageSize.width() * inversePercentage + toImageSize.width() * percentage,
        fromImageSize.height() * inversePercentage + toImageSize.height() * percentage);
}

bool CSSCrossfadeValue::isPending() const
{
    return subimageIsPending(m_fromValue.get()) || subimageIsPending(m_toValue.get());
}

bool CSSCrossfadeValue::knownToBeOpaque(const RenderObject* renderer) const
{
    return subimageKnownToBeOpaque(m_fromValue.get(), renderer) && subimageKnownToBeOpaque(m_toValue.get(), renderer);
}

void CSSCrossfadeValue::loadSubimages(ResourceFetcher* fetcher)
{
    ResourcePtr<ImageResource> oldCachedFromImage = m_cachedFromImage;
    ResourcePtr<ImageResource> oldCachedToImage = m_cachedToImage;

    m_cachedFromImage = cachedImageForCSSValue(m_fromValue.get(), fetcher);
    m_cachedToImage = cachedImageForCSSValue(m_toValue.get(), fetcher);

    if (m_cachedFromImage != oldCachedFromImage) {
        if (oldCachedFromImage)
            oldCachedFromImage->removeClient(&m_crossfadeSubimageObserver);
        if (m_cachedFromImage)
            m_cachedFromImage->addClient(&m_crossfadeSubimageObserver);
    }

    if (m_cachedToImage != oldCachedToImage) {
        if (oldCachedToImage)
            oldCachedToImage->removeClient(&m_crossfadeSubimageObserver);
        if (m_cachedToImage)
            m_cachedToImage->addClient(&m_crossfadeSubimageObserver);
    }

    m_crossfadeSubimageObserver.setReady(true);
}

PassRefPtr<Image> CSSCrossfadeValue::image(RenderObject* renderer, const IntSize& size)
{
    if (size.isEmpty())
        return nullptr;

    ResourceFetcher* fetcher = renderer->document().fetcher();
    ImageResource* cachedFromImage = cachedImageForCSSValue(m_fromValue.get(), fetcher);
    ImageResource* cachedToImage = cachedImageForCSSValue(m_toValue.get(), fetcher);

    if (!cachedFromImage || !cachedToImage)
        return Image::nullImage();

    Image* fromImage = cachedFromImage->imageForRenderer(renderer);
    Image* toImage = cachedToImage->imageForRenderer(renderer);

    if (!fromImage || !toImage)
        return Image::nullImage();

    m_generatedImage = CrossfadeGeneratedImage::create(fromImage, toImage, m_percentageValue->getFloatValue(), fixedSize(renderer), size);

    return m_generatedImage.release();
}

void CSSCrossfadeValue::crossfadeChanged(const IntRect&)
{
    RenderObjectSizeCountMap::const_iterator end = clients().end();
    for (RenderObjectSizeCountMap::const_iterator curr = clients().begin(); curr != end; ++curr) {
        RenderObject* client = const_cast<RenderObject*>(curr->key);
        client->imageChanged(static_cast<WrappedImagePtr>(this));
    }
}

void CSSCrossfadeValue::CrossfadeSubimageObserverProxy::imageChanged(ImageResource*, const IntRect* rect)
{
    if (m_ready)
        m_ownerValue->crossfadeChanged(*rect);
}

bool CSSCrossfadeValue::hasFailedOrCanceledSubresources() const
{
    if (m_cachedFromImage && m_cachedFromImage->loadFailedOrCanceled())
        return true;
    if (m_cachedToImage && m_cachedToImage->loadFailedOrCanceled())
        return true;
    return false;
}

bool CSSCrossfadeValue::equals(const CSSCrossfadeValue& other) const
{
    return compareCSSValuePtr(m_fromValue, other.m_fromValue)
        && compareCSSValuePtr(m_toValue, other.m_toValue)
        && compareCSSValuePtr(m_percentageValue, other.m_percentageValue);
}

void CSSCrossfadeValue::traceAfterDispatch(Visitor* visitor)
{
    visitor->trace(m_fromValue);
    visitor->trace(m_toValue);
    visitor->trace(m_percentageValue);
    CSSImageGeneratorValue::traceAfterDispatch(visitor);
}

} // namespace blink
