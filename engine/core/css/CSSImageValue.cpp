/*
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2008 Apple Inc. All rights reserved.
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
#include "core/css/CSSImageValue.h"

#include "gen/sky/core/FetchInitiatorTypeNames.h"
#include "core/css/CSSMarkup.h"
#include "core/dom/Document.h"
#include "core/fetch/FetchRequest.h"
#include "core/fetch/ImageResource.h"
#include "core/rendering/style/StyleFetchedImage.h"
#include "core/rendering/style/StylePendingImage.h"
#include "platform/weborigin/KURL.h"

namespace blink {

CSSImageValue::CSSImageValue(const String& rawValue, const KURL& url, StyleImage* image)
    : CSSValue(ImageClass)
    , m_relativeURL(rawValue)
    , m_absoluteURL(url.string())
    , m_image(image)
    , m_accessedImage(image)
{
}

CSSImageValue::~CSSImageValue()
{
}

StyleImage* CSSImageValue::cachedOrPendingImage()
{
    if (!m_image)
        m_image = StylePendingImage::create(this);

    return m_image.get();
}

StyleFetchedImage* CSSImageValue::cachedImage(ResourceFetcher* fetcher, const ResourceLoaderOptions& options)
{
    ASSERT(fetcher);

    if (!m_accessedImage) {
        m_accessedImage = true;

        FetchRequest request(ResourceRequest(m_absoluteURL), m_initiatorName.isEmpty() ? FetchInitiatorTypeNames::css : m_initiatorName, options);
        request.mutableResourceRequest().setHTTPReferrer(m_referrer);

        if (ResourcePtr<ImageResource> cachedImage = fetcher->fetchImage(request))
            m_image = StyleFetchedImage::create(cachedImage.get());
    }

    return (m_image && m_image->isImageResource()) ? toStyleFetchedImage(m_image) : 0;
}

void CSSImageValue::restoreCachedResourceIfNeeded(Document& document)
{
    if (!m_accessedImage || !m_image->isImageResource() || !document.fetcher())
        return;
    if (document.fetcher()->cachedResource(KURL(ParsedURLString, m_absoluteURL)))
        return;

    ImageResource* resource = m_image->cachedImage();
    if (!resource)
        return;

    FetchRequest request(ResourceRequest(m_absoluteURL), m_initiatorName.isEmpty() ? FetchInitiatorTypeNames::css : m_initiatorName, resource->options());
    document.fetcher()->requestLoadStarted(resource, request, ResourceFetcher::ResourceLoadingFromCache);
}

bool CSSImageValue::hasFailedOrCanceledSubresources() const
{
    if (!m_image || !m_image->isImageResource())
        return false;
    if (Resource* cachedResource = toStyleFetchedImage(m_image)->cachedImage())
        return cachedResource->loadFailedOrCanceled();
    return true;
}

bool CSSImageValue::equals(const CSSImageValue& other) const
{
    return m_absoluteURL == other.m_absoluteURL;
}

String CSSImageValue::customCSSText() const
{
    return "url(" + quoteCSSURLIfNeeded(m_absoluteURL) + ")";
}

PassRefPtr<CSSValue> CSSImageValue::cloneForCSSOM() const
{
    // NOTE: We expose CSSImageValues as URI primitive values in CSSOM to maintain old behavior.
    RefPtr<CSSPrimitiveValue> uriValue = CSSPrimitiveValue::create(m_absoluteURL, CSSPrimitiveValue::CSS_URI);
    uriValue->setCSSOMSafe();
    return uriValue.release();
}

bool CSSImageValue::knownToBeOpaque(const RenderObject* renderer) const
{
    return m_image ? m_image->knownToBeOpaque(renderer) : false;
}

void CSSImageValue::reResolveURL(const Document& document)
{
    KURL url = document.completeURL(m_relativeURL);
    if (url == m_absoluteURL)
        return;
    m_absoluteURL = url.string();
    m_accessedImage = false;
    m_image.clear();
}

} // namespace blink
