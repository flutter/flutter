/*
 * Copyright (C) 2006 Rob Buis <buis@kde.org>
 *           (C) 2008 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2008 Apple Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#include "config.h"
#include "core/css/CSSCursorImageValue.h"

#include "core/css/CSSImageSetValue.h"
#include "core/fetch/ImageResource.h"
#include "core/fetch/ResourceFetcher.h"
#include "core/rendering/style/StyleFetchedImage.h"
#include "core/rendering/style/StyleFetchedImageSet.h"
#include "core/rendering/style/StyleImage.h"
#include "core/rendering/style/StylePendingImage.h"
#include "wtf/MathExtras.h"
#include "wtf/text/StringBuilder.h"
#include "wtf/text/WTFString.h"

namespace blink {

CSSCursorImageValue::CSSCursorImageValue(PassRefPtrWillBeRawPtr<CSSValue> imageValue, bool hasHotSpot, const IntPoint& hotSpot)
    : CSSValue(CursorImageClass)
    , m_imageValue(imageValue)
    , m_hasHotSpot(hasHotSpot)
    , m_hotSpot(hotSpot)
    , m_accessedImage(false)
{
}

CSSCursorImageValue::~CSSCursorImageValue()
{
    // The below teardown is all handled by weak pointer processing in oilpan.
#if !ENABLE(OILPAN)
    if (!isSVGCursor())
        return;
#endif
}

String CSSCursorImageValue::customCSSText() const
{
    StringBuilder result;
    result.append(m_imageValue->cssText());
    if (m_hasHotSpot) {
        result.append(' ');
        result.appendNumber(m_hotSpot.x());
        result.append(' ');
        result.appendNumber(m_hotSpot.y());
    }
    return result.toString();
}

StyleImage* CSSCursorImageValue::cachedImage(ResourceFetcher* loader, float deviceScaleFactor)
{
    if (m_imageValue->isImageSetValue())
        return toCSSImageSetValue(m_imageValue.get())->cachedImageSet(loader, deviceScaleFactor);

    if (!m_accessedImage) {
        m_accessedImage = true;

        if (m_imageValue->isImageValue())
            m_image = toCSSImageValue(m_imageValue.get())->cachedImage(loader);
    }

    if (m_image && m_image->isImageResource())
        return toStyleFetchedImage(m_image);
    return 0;
}

StyleImage* CSSCursorImageValue::cachedOrPendingImage(float deviceScaleFactor)
{
    // Need to delegate completely so that changes in device scale factor can be handled appropriately.
    if (m_imageValue->isImageSetValue())
        return toCSSImageSetValue(m_imageValue.get())->cachedOrPendingImageSet(deviceScaleFactor);

    if (!m_image)
        m_image = StylePendingImage::create(this);

    return m_image.get();
}

bool CSSCursorImageValue::isSVGCursor() const
{
    if (m_imageValue->isImageValue()) {
        RefPtrWillBeRawPtr<CSSImageValue> imageValue = toCSSImageValue(m_imageValue.get());
        KURL kurl(ParsedURLString, imageValue->url());
        return kurl.hasFragmentIdentifier();
    }
    return false;
}

String CSSCursorImageValue::cachedImageURL()
{
    if (!m_image || !m_image->isImageResource())
        return String();
    return toStyleFetchedImage(m_image)->cachedImage()->url().string();
}

void CSSCursorImageValue::clearImageResource()
{
    m_image = nullptr;
    m_accessedImage = false;
}

bool CSSCursorImageValue::equals(const CSSCursorImageValue& other) const
{
    return m_hasHotSpot ? other.m_hasHotSpot && m_hotSpot == other.m_hotSpot : !other.m_hasHotSpot
        && compareCSSValuePtr(m_imageValue, other.m_imageValue);
}

void CSSCursorImageValue::traceAfterDispatch(Visitor* visitor)
{
    visitor->trace(m_imageValue);
    CSSValue::traceAfterDispatch(visitor);
}

} // namespace blink
