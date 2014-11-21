/*
 * Copyright (C) 2003, 2006 Apple Computer, Inc.  All rights reserved.
 * Copyright (C) 2009, 2012 Google Inc. All rights reserved.
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
#include "sky/engine/platform/network/ResourceRequest.h"
#include "sky/engine/public/platform/WebURLRequest.h"

namespace blink {

double ResourceRequest::s_defaultTimeoutInterval = INT_MAX;

bool ResourceRequest::isEmpty() const
{
    return m_url.isEmpty();
}

bool ResourceRequest::isNull() const
{
    return m_url.isNull();
}

const KURL& ResourceRequest::url() const
{
    return m_url;
}

void ResourceRequest::setURL(const KURL& url)
{
    m_url = url;
}

void ResourceRequest::removeCredentials()
{
    if (m_url.user().isEmpty() && m_url.pass().isEmpty())
        return;

    m_url.setUser(String());
    m_url.setPass(String());
}

ResourceRequestCachePolicy ResourceRequest::cachePolicy() const
{
    return m_cachePolicy;
}

void ResourceRequest::setCachePolicy(ResourceRequestCachePolicy cachePolicy)
{
    m_cachePolicy = cachePolicy;
}

double ResourceRequest::timeoutInterval() const
{
    return m_timeoutInterval;
}

void ResourceRequest::setTimeoutInterval(double timeoutInterval)
{
    m_timeoutInterval = timeoutInterval;
}

const AtomicString& ResourceRequest::httpMethod() const
{
    return m_httpMethod;
}

void ResourceRequest::setHTTPMethod(const AtomicString& httpMethod)
{
    m_httpMethod = httpMethod;
}

const HTTPHeaderMap& ResourceRequest::httpHeaderFields() const
{
    return m_httpHeaderFields;
}

const AtomicString& ResourceRequest::httpHeaderField(const AtomicString& name) const
{
    return m_httpHeaderFields.get(name);
}

const AtomicString& ResourceRequest::httpHeaderField(const char* name) const
{
    return m_httpHeaderFields.get(name);
}

void ResourceRequest::setHTTPHeaderField(const AtomicString& name, const AtomicString& value)
{
    m_httpHeaderFields.set(name, value);
}

void ResourceRequest::setHTTPHeaderField(const char* name, const AtomicString& value)
{
    setHTTPHeaderField(AtomicString(name), value);
}

void ResourceRequest::clearHTTPAuthorization()
{
    m_httpHeaderFields.remove("Authorization");
}

void ResourceRequest::clearHTTPReferrer()
{
    m_httpHeaderFields.remove("Referer");
    m_referrerPolicy = ReferrerPolicyDefault;
}

void ResourceRequest::clearHTTPOrigin()
{
    m_httpHeaderFields.remove("Origin");
}

void ResourceRequest::addHTTPOriginIfNeeded(const AtomicString& origin)
{
    // FIXME(sky): Remove
}

FormData* ResourceRequest::httpBody() const
{
    return m_httpBody.get();
}

void ResourceRequest::setHTTPBody(PassRefPtr<FormData> httpBody)
{
    m_httpBody = httpBody;
}

bool ResourceRequest::allowStoredCredentials() const
{
    return m_allowStoredCredentials;
}

void ResourceRequest::setAllowStoredCredentials(bool allowCredentials)
{
    m_allowStoredCredentials = allowCredentials;
}

ResourceLoadPriority ResourceRequest::priority() const
{
    return m_priority;
}

void ResourceRequest::setPriority(ResourceLoadPriority priority, int intraPriorityValue)
{
    m_priority = priority;
    m_intraPriorityValue = intraPriorityValue;
}

void ResourceRequest::addHTTPHeaderField(const AtomicString& name, const AtomicString& value)
{
    HTTPHeaderMap::AddResult result = m_httpHeaderFields.add(name, value);
    if (!result.isNewEntry)
        result.storedValue->value = result.storedValue->value + ',' + value;
}

void ResourceRequest::addHTTPHeaderFields(const HTTPHeaderMap& headerFields)
{
    HTTPHeaderMap::const_iterator end = headerFields.end();
    for (HTTPHeaderMap::const_iterator it = headerFields.begin(); it != end; ++it)
        addHTTPHeaderField(it->key, it->value);
}

void ResourceRequest::clearHTTPHeaderField(const AtomicString& name)
{
    m_httpHeaderFields.remove(name);
}

bool equalIgnoringHeaderFields(const ResourceRequest& a, const ResourceRequest& b)
{
    if (a.url() != b.url())
        return false;

    if (a.cachePolicy() != b.cachePolicy())
        return false;

    if (a.timeoutInterval() != b.timeoutInterval())
        return false;

    if (a.httpMethod() != b.httpMethod())
        return false;

    if (a.allowStoredCredentials() != b.allowStoredCredentials())
        return false;

    if (a.priority() != b.priority())
        return false;

    if (a.referrerPolicy() != b.referrerPolicy())
        return false;

    FormData* formDataA = a.httpBody();
    FormData* formDataB = b.httpBody();

    if (!formDataA)
        return !formDataB;
    if (!formDataB)
        return !formDataA;

    if (*formDataA != *formDataB)
        return false;

    return true;
}

bool ResourceRequest::compare(const ResourceRequest& a, const ResourceRequest& b)
{
    if (!equalIgnoringHeaderFields(a, b))
        return false;

    if (a.httpHeaderFields() != b.httpHeaderFields())
        return false;

    return true;
}

bool ResourceRequest::isConditional() const
{
    return (m_httpHeaderFields.contains("If-Match")
        || m_httpHeaderFields.contains("If-Modified-Since")
        || m_httpHeaderFields.contains("If-None-Match")
        || m_httpHeaderFields.contains("If-Range")
        || m_httpHeaderFields.contains("If-Unmodified-Since"));
}


static const AtomicString& cacheControlHeaderString()
{
    DEFINE_STATIC_LOCAL(const AtomicString, cacheControlHeader, ("cache-control", AtomicString::ConstructFromLiteral));
    return cacheControlHeader;
}

static const AtomicString& pragmaHeaderString()
{
    DEFINE_STATIC_LOCAL(const AtomicString, pragmaHeader, ("pragma", AtomicString::ConstructFromLiteral));
    return pragmaHeader;
}

const CacheControlHeader& ResourceRequest::cacheControlHeader() const
{
    if (!m_cacheControlHeaderCache.parsed)
        m_cacheControlHeaderCache = parseCacheControlDirectives(m_httpHeaderFields.get(cacheControlHeaderString()), m_httpHeaderFields.get(pragmaHeaderString()));
    return m_cacheControlHeaderCache;
}

bool ResourceRequest::cacheControlContainsNoCache() const
{
    return cacheControlHeader().containsNoCache;
}

bool ResourceRequest::cacheControlContainsNoStore() const
{
    return cacheControlHeader().containsNoStore;
}

bool ResourceRequest::hasCacheValidatorFields() const
{
    DEFINE_STATIC_LOCAL(const AtomicString, lastModifiedHeader, ("last-modified", AtomicString::ConstructFromLiteral));
    DEFINE_STATIC_LOCAL(const AtomicString, eTagHeader, ("etag", AtomicString::ConstructFromLiteral));
    return !m_httpHeaderFields.get(lastModifiedHeader).isEmpty() || !m_httpHeaderFields.get(eTagHeader).isEmpty();
}

double ResourceRequest::defaultTimeoutInterval()
{
    return s_defaultTimeoutInterval;
}

void ResourceRequest::setDefaultTimeoutInterval(double timeoutInterval)
{
    s_defaultTimeoutInterval = timeoutInterval;
}

void ResourceRequest::initialize(const KURL& url, ResourceRequestCachePolicy cachePolicy)
{
    m_url = url;
    m_cachePolicy = cachePolicy;
    m_timeoutInterval = s_defaultTimeoutInterval;
    m_httpMethod = "GET";
    m_allowStoredCredentials = true;
    m_reportUploadProgress = false;
    m_reportRawHeaders = false;
    m_hasUserGesture = false;
    m_downloadToFile = false;
    m_priority = ResourceLoadPriorityLow;
    m_intraPriorityValue = 0;
    m_requestorID = 0;
    m_requestorProcessID = 0;
    m_requestContext = blink::WebURLRequest::RequestContextUnspecified;
    m_frameType = blink::WebURLRequest::FrameTypeNone;
    m_referrerPolicy = ReferrerPolicyDefault;
}

}
