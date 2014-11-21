/*
 * Copyright (C) 2007, 2010 Apple Inc. All rights reserved.
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

#include "sky/engine/config.h"
#include "sky/engine/core/css/CSSFontFaceSrcValue.h"

#include "gen/sky/core/FetchInitiatorTypeNames.h"
#include "sky/engine/core/css/StyleSheetContents.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Node.h"
#include "sky/engine/core/fetch/FetchRequest.h"
#include "sky/engine/core/fetch/FontResource.h"
#include "sky/engine/core/fetch/ResourceFetcher.h"
#include "sky/engine/platform/fonts/FontCache.h"
#include "sky/engine/platform/fonts/FontCustomPlatformData.h"
#include "sky/engine/wtf/text/StringBuilder.h"

namespace blink {

bool CSSFontFaceSrcValue::isSupportedFormat() const
{
    // Normally we would just check the format, but in order to avoid conflicts with the old WinIE style of font-face,
    // we will also check to see if the URL ends with .eot.  If so, we'll go ahead and assume that we shouldn't load it.
    if (m_format.isEmpty()) {
        // Check for .eot.
        if (!m_resource.startsWith("data:", false) && m_resource.endsWith(".eot", false))
            return false;
        return true;
    }

    if (FontCustomPlatformData::supportsFormat(m_format))
        return true;

    // We have removed SVG font support on non-gdi platforms. For details, see:
    // https://groups.google.com/a/chromium.org/d/msg/blink-dev/pYbbUcYvlYY/LQvFvM8KZZEJ
    return false;
}

String CSSFontFaceSrcValue::customCSSText() const
{
    StringBuilder result;
    if (isLocal())
        result.appendLiteral("local(");
    else
        result.appendLiteral("url(");
    result.append(m_resource);
    result.append(')');
    if (!m_format.isEmpty()) {
        result.appendLiteral(" format(");
        result.append(m_format);
        result.append(')');
    }
    return result.toString();
}

bool CSSFontFaceSrcValue::hasFailedOrCanceledSubresources() const
{
    if (!m_fetched)
        return false;
    return m_fetched->loadFailedOrCanceled();
}

FontResource* CSSFontFaceSrcValue::fetch(Document* document)
{
    if (!m_fetched) {
        FetchRequest request(ResourceRequest(document->completeURL(m_resource)), FetchInitiatorTypeNames::css);
        request.mutableResourceRequest().setHTTPReferrer(m_referrer);
        m_fetched = document->fetcher()->fetchFont(request);
    } else {
        // FIXME: CSSFontFaceSrcValue::fetch is invoked when @font-face rule
        // is processed by StyleResolver / StyleEngine.
        restoreCachedResourceIfNeeded(document);
    }
    return m_fetched.get();
}

void CSSFontFaceSrcValue::restoreCachedResourceIfNeeded(Document* document)
{
    ASSERT(m_fetched);
    ASSERT(document && document->fetcher());

    const String resourceURL = document->completeURL(m_resource);
    if (document->fetcher()->cachedResource(KURL(ParsedURLString, resourceURL)))
        return;

    FetchRequest request(ResourceRequest(resourceURL), FetchInitiatorTypeNames::css);
    document->fetcher()->requestLoadStarted(m_fetched.get(), request, ResourceFetcher::ResourceLoadingFromCache);
}

bool CSSFontFaceSrcValue::equals(const CSSFontFaceSrcValue& other) const
{
    return m_isLocal == other.m_isLocal && m_format == other.m_format && m_resource == other.m_resource;
}

}
