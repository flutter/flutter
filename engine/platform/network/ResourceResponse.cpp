/*
 * Copyright (C) 2006, 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2009 Google Inc. All rights reserved.
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
#include "platform/network/ResourceResponse.h"

#include "wtf/CurrentTime.h"
#include "wtf/StdLibExtras.h"

namespace blink {

ResourceResponse::ResourceResponse()
    : m_expectedContentLength(0)
    , m_httpStatusCode(0)
    , m_lastModifiedDate(0)
    , m_wasCached(false)
    , m_connectionID(0)
    , m_connectionReused(false)
    , m_isNull(true)
    , m_haveParsedAgeHeader(false)
    , m_haveParsedDateHeader(false)
    , m_haveParsedExpiresHeader(false)
    , m_haveParsedLastModifiedHeader(false)
    , m_age(0.0)
    , m_date(0.0)
    , m_expires(0.0)
    , m_lastModified(0.0)
    , m_httpVersion(Unknown)
    , m_isMultipartPayload(false)
    , m_wasFetchedViaSPDY(false)
    , m_wasNpnNegotiated(false)
    , m_wasAlternateProtocolAvailable(false)
    , m_wasFetchedViaProxy(false)
    , m_responseTime(0)
    , m_remotePort(0)
{
}

ResourceResponse::ResourceResponse(const KURL& url, const AtomicString& mimeType, long long expectedLength, const AtomicString& textEncodingName, const String& filename)
    : m_url(url)
    , m_mimeType(mimeType)
    , m_expectedContentLength(expectedLength)
    , m_textEncodingName(textEncodingName)
    , m_suggestedFilename(filename)
    , m_httpStatusCode(0)
    , m_lastModifiedDate(0)
    , m_wasCached(false)
    , m_connectionID(0)
    , m_connectionReused(false)
    , m_isNull(false)
    , m_haveParsedAgeHeader(false)
    , m_haveParsedDateHeader(false)
    , m_haveParsedExpiresHeader(false)
    , m_haveParsedLastModifiedHeader(false)
    , m_age(0.0)
    , m_date(0.0)
    , m_expires(0.0)
    , m_lastModified(0.0)
    , m_httpVersion(Unknown)
    , m_isMultipartPayload(false)
    , m_wasFetchedViaSPDY(false)
    , m_wasNpnNegotiated(false)
    , m_wasAlternateProtocolAvailable(false)
    , m_wasFetchedViaProxy(false)
    , m_responseTime(0)
    , m_remotePort(0)
{
}

bool ResourceResponse::isHTTP() const
{
    return m_url.protocolIsInHTTPFamily();
}

const KURL& ResourceResponse::url() const
{
    return m_url;
}

void ResourceResponse::setURL(const KURL& url)
{
    m_isNull = false;

    m_url = url;
}

const AtomicString& ResourceResponse::mimeType() const
{
    return m_mimeType;
}

void ResourceResponse::setMimeType(const AtomicString& mimeType)
{
    m_isNull = false;

    // FIXME: MIME type is determined by HTTP Content-Type header. We should update the header, so that it doesn't disagree with m_mimeType.
    m_mimeType = mimeType;
}

long long ResourceResponse::expectedContentLength() const
{
    return m_expectedContentLength;
}

void ResourceResponse::setExpectedContentLength(long long expectedContentLength)
{
    m_isNull = false;

    // FIXME: Content length is determined by HTTP Content-Length header. We should update the header, so that it doesn't disagree with m_expectedContentLength.
    m_expectedContentLength = expectedContentLength;
}

const AtomicString& ResourceResponse::textEncodingName() const
{
    return m_textEncodingName;
}

void ResourceResponse::setTextEncodingName(const AtomicString& encodingName)
{
    m_isNull = false;

    // FIXME: Text encoding is determined by HTTP Content-Type header. We should update the header, so that it doesn't disagree with m_textEncodingName.
    m_textEncodingName = encodingName;
}

// FIXME should compute this on the fly
const String& ResourceResponse::suggestedFilename() const
{
    return m_suggestedFilename;
}

void ResourceResponse::setSuggestedFilename(const String& suggestedName)
{
    m_isNull = false;

    // FIXME: Suggested file name is calculated based on other headers. There should not be a setter for it.
    m_suggestedFilename = suggestedName;
}

int ResourceResponse::httpStatusCode() const
{
    return m_httpStatusCode;
}

void ResourceResponse::setHTTPStatusCode(int statusCode)
{
    m_httpStatusCode = statusCode;
}

const AtomicString& ResourceResponse::httpStatusText() const
{
    return m_httpStatusText;
}

void ResourceResponse::setHTTPStatusText(const AtomicString& statusText)
{
    m_httpStatusText = statusText;
}

const AtomicString& ResourceResponse::httpHeaderField(const AtomicString& name) const
{
    return m_httpHeaderFields.get(name);
}

const AtomicString& ResourceResponse::httpHeaderField(const char* name) const
{
    return m_httpHeaderFields.get(name);
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

void ResourceResponse::updateHeaderParsedState(const AtomicString& name)
{
    DEFINE_STATIC_LOCAL(const AtomicString, ageHeader, ("age", AtomicString::ConstructFromLiteral));
    DEFINE_STATIC_LOCAL(const AtomicString, dateHeader, ("date", AtomicString::ConstructFromLiteral));
    DEFINE_STATIC_LOCAL(const AtomicString, expiresHeader, ("expires", AtomicString::ConstructFromLiteral));
    DEFINE_STATIC_LOCAL(const AtomicString, lastModifiedHeader, ("last-modified", AtomicString::ConstructFromLiteral));

    if (equalIgnoringCase(name, ageHeader))
        m_haveParsedAgeHeader = false;
    else if (equalIgnoringCase(name, cacheControlHeaderString()) || equalIgnoringCase(name, pragmaHeaderString()))
        m_cacheControlHeader = CacheControlHeader();
    else if (equalIgnoringCase(name, dateHeader))
        m_haveParsedDateHeader = false;
    else if (equalIgnoringCase(name, expiresHeader))
        m_haveParsedExpiresHeader = false;
    else if (equalIgnoringCase(name, lastModifiedHeader))
        m_haveParsedLastModifiedHeader = false;
}

void ResourceResponse::setHTTPHeaderField(const AtomicString& name, const AtomicString& value)
{
    updateHeaderParsedState(name);

    m_httpHeaderFields.set(name, value);
}

void ResourceResponse::addHTTPHeaderField(const AtomicString& name, const AtomicString& value)
{
    updateHeaderParsedState(name);

    HTTPHeaderMap::AddResult result = m_httpHeaderFields.add(name, value);
    if (!result.isNewEntry)
        result.storedValue->value = result.storedValue->value + ", " + value;
}

void ResourceResponse::clearHTTPHeaderField(const AtomicString& name)
{
    m_httpHeaderFields.remove(name);
}

const HTTPHeaderMap& ResourceResponse::httpHeaderFields() const
{
    return m_httpHeaderFields;
}

bool ResourceResponse::cacheControlContainsNoCache()
{
    if (!m_cacheControlHeader.parsed)
        m_cacheControlHeader = parseCacheControlDirectives(m_httpHeaderFields.get(cacheControlHeaderString()), m_httpHeaderFields.get(pragmaHeaderString()));
    return m_cacheControlHeader.containsNoCache;
}

bool ResourceResponse::cacheControlContainsNoStore()
{
    if (!m_cacheControlHeader.parsed)
        m_cacheControlHeader = parseCacheControlDirectives(m_httpHeaderFields.get(cacheControlHeaderString()), m_httpHeaderFields.get(pragmaHeaderString()));
    return m_cacheControlHeader.containsNoStore;
}

bool ResourceResponse::cacheControlContainsMustRevalidate()
{
    if (!m_cacheControlHeader.parsed)
        m_cacheControlHeader = parseCacheControlDirectives(m_httpHeaderFields.get(cacheControlHeaderString()), m_httpHeaderFields.get(pragmaHeaderString()));
    return m_cacheControlHeader.containsMustRevalidate;
}

bool ResourceResponse::hasCacheValidatorFields() const
{
    DEFINE_STATIC_LOCAL(const AtomicString, lastModifiedHeader, ("last-modified", AtomicString::ConstructFromLiteral));
    DEFINE_STATIC_LOCAL(const AtomicString, eTagHeader, ("etag", AtomicString::ConstructFromLiteral));
    return !m_httpHeaderFields.get(lastModifiedHeader).isEmpty() || !m_httpHeaderFields.get(eTagHeader).isEmpty();
}

double ResourceResponse::cacheControlMaxAge()
{
    if (!m_cacheControlHeader.parsed)
        m_cacheControlHeader = parseCacheControlDirectives(m_httpHeaderFields.get(cacheControlHeaderString()), m_httpHeaderFields.get(pragmaHeaderString()));
    return m_cacheControlHeader.maxAge;
}

static double parseDateValueInHeader(const HTTPHeaderMap& headers, const AtomicString& headerName)
{
    const AtomicString& headerValue = headers.get(headerName);
    if (headerValue.isEmpty())
        return std::numeric_limits<double>::quiet_NaN();
    // This handles all date formats required by RFC2616:
    // Sun, 06 Nov 1994 08:49:37 GMT  ; RFC 822, updated by RFC 1123
    // Sunday, 06-Nov-94 08:49:37 GMT ; RFC 850, obsoleted by RFC 1036
    // Sun Nov  6 08:49:37 1994       ; ANSI C's asctime() format
    double dateInMilliseconds = parseDate(headerValue);
    if (!std::isfinite(dateInMilliseconds))
        return std::numeric_limits<double>::quiet_NaN();
    return dateInMilliseconds / 1000;
}

double ResourceResponse::date() const
{
    if (!m_haveParsedDateHeader) {
        DEFINE_STATIC_LOCAL(const AtomicString, headerName, ("date", AtomicString::ConstructFromLiteral));
        m_date = parseDateValueInHeader(m_httpHeaderFields, headerName);
        m_haveParsedDateHeader = true;
    }
    return m_date;
}

double ResourceResponse::age() const
{
    if (!m_haveParsedAgeHeader) {
        DEFINE_STATIC_LOCAL(const AtomicString, headerName, ("age", AtomicString::ConstructFromLiteral));
        const AtomicString& headerValue = m_httpHeaderFields.get(headerName);
        bool ok;
        m_age = headerValue.toDouble(&ok);
        if (!ok)
            m_age = std::numeric_limits<double>::quiet_NaN();
        m_haveParsedAgeHeader = true;
    }
    return m_age;
}

double ResourceResponse::expires() const
{
    if (!m_haveParsedExpiresHeader) {
        DEFINE_STATIC_LOCAL(const AtomicString, headerName, ("expires", AtomicString::ConstructFromLiteral));
        m_expires = parseDateValueInHeader(m_httpHeaderFields, headerName);
        m_haveParsedExpiresHeader = true;
    }
    return m_expires;
}

double ResourceResponse::lastModified() const
{
    if (!m_haveParsedLastModifiedHeader) {
        DEFINE_STATIC_LOCAL(const AtomicString, headerName, ("last-modified", AtomicString::ConstructFromLiteral));
        m_lastModified = parseDateValueInHeader(m_httpHeaderFields, headerName);
        m_haveParsedLastModifiedHeader = true;
    }
    return m_lastModified;
}

bool ResourceResponse::isAttachment() const
{
    DEFINE_STATIC_LOCAL(const AtomicString, headerName, ("content-disposition", AtomicString::ConstructFromLiteral));
    String value = m_httpHeaderFields.get(headerName);
    size_t loc = value.find(';');
    if (loc != kNotFound)
        value = value.left(loc);
    value = value.stripWhiteSpace();
    DEFINE_STATIC_LOCAL(const AtomicString, attachmentString, ("attachment", AtomicString::ConstructFromLiteral));
    return equalIgnoringCase(value, attachmentString);
}

void ResourceResponse::setLastModifiedDate(time_t lastModifiedDate)
{
    m_lastModifiedDate = lastModifiedDate;
}

time_t ResourceResponse::lastModifiedDate() const
{
    return m_lastModifiedDate;
}

bool ResourceResponse::wasCached() const
{
    return m_wasCached;
}

void ResourceResponse::setWasCached(bool value)
{
    m_wasCached = value;
}

bool ResourceResponse::connectionReused() const
{
    return m_connectionReused;
}

void ResourceResponse::setConnectionReused(bool connectionReused)
{
    m_connectionReused = connectionReused;
}

unsigned ResourceResponse::connectionID() const
{
    return m_connectionID;
}

void ResourceResponse::setConnectionID(unsigned connectionID)
{
    m_connectionID = connectionID;
}

ResourceLoadTiming* ResourceResponse::resourceLoadTiming() const
{
    return m_resourceLoadTiming.get();
}

void ResourceResponse::setResourceLoadTiming(PassRefPtr<ResourceLoadTiming> resourceLoadTiming)
{
    m_resourceLoadTiming = resourceLoadTiming;
}

PassRefPtr<ResourceLoadInfo> ResourceResponse::resourceLoadInfo() const
{
    return m_resourceLoadInfo.get();
}

void ResourceResponse::setResourceLoadInfo(PassRefPtr<ResourceLoadInfo> loadInfo)
{
    m_resourceLoadInfo = loadInfo;
}

void ResourceResponse::setDownloadedFilePath(const String& downloadedFilePath)
{
    m_downloadedFilePath = downloadedFilePath;
}

bool ResourceResponse::compare(const ResourceResponse& a, const ResourceResponse& b)
{
    if (a.isNull() != b.isNull())
        return false;
    if (a.url() != b.url())
        return false;
    if (a.mimeType() != b.mimeType())
        return false;
    if (a.expectedContentLength() != b.expectedContentLength())
        return false;
    if (a.textEncodingName() != b.textEncodingName())
        return false;
    if (a.suggestedFilename() != b.suggestedFilename())
        return false;
    if (a.httpStatusCode() != b.httpStatusCode())
        return false;
    if (a.httpStatusText() != b.httpStatusText())
        return false;
    if (a.httpHeaderFields() != b.httpHeaderFields())
        return false;
    if (a.resourceLoadTiming() && b.resourceLoadTiming() && *a.resourceLoadTiming() == *b.resourceLoadTiming())
        return true;
    if (a.resourceLoadTiming() != b.resourceLoadTiming())
        return false;
    return true;
}

}
