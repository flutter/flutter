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

#ifndef ResourceResponse_h
#define ResourceResponse_h

#include "sky/engine/platform/PlatformExport.h"
#include "sky/engine/platform/network/HTTPHeaderMap.h"
#include "sky/engine/platform/network/HTTPParsers.h"
#include "sky/engine/platform/network/ResourceLoadInfo.h"
#include "sky/engine/platform/network/ResourceLoadTiming.h"
#include "sky/engine/platform/weborigin/KURL.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/text/CString.h"

namespace blink {

class PLATFORM_EXPORT ResourceResponse {
    WTF_MAKE_FAST_ALLOCATED;
public:
    enum HTTPVersion { Unknown, HTTP_0_9, HTTP_1_0, HTTP_1_1 };

    class ExtraData : public RefCounted<ExtraData> {
    public:
        virtual ~ExtraData() { }
    };

    ResourceResponse();
    ResourceResponse(const KURL&, const AtomicString& mimeType, long long expectedLength, const AtomicString& textEncodingName, const String& filename);

    bool isNull() const { return m_isNull; }
    bool isHTTP() const;

    const KURL& url() const;
    void setURL(const KURL&);

    const AtomicString& mimeType() const;
    void setMimeType(const AtomicString&);

    long long expectedContentLength() const;
    void setExpectedContentLength(long long);

    const AtomicString& textEncodingName() const;
    void setTextEncodingName(const AtomicString&);

    // FIXME: Should compute this on the fly.
    // There should not be a setter exposed, as suggested file name is determined based on other headers in a manner that WebCore does not necessarily know about.
    const String& suggestedFilename() const;
    void setSuggestedFilename(const String&);

    int httpStatusCode() const;
    void setHTTPStatusCode(int);

    const AtomicString& httpStatusText() const;
    void setHTTPStatusText(const AtomicString&);

    const AtomicString& httpHeaderField(const AtomicString& name) const;
    const AtomicString& httpHeaderField(const char* name) const;
    void setHTTPHeaderField(const AtomicString& name, const AtomicString& value);
    void addHTTPHeaderField(const AtomicString& name, const AtomicString& value);
    void clearHTTPHeaderField(const AtomicString& name);
    const HTTPHeaderMap& httpHeaderFields() const;

    bool isMultipart() const { return mimeType() == "multipart/x-mixed-replace"; }

    bool isAttachment() const;

    // FIXME: These are used by PluginStream on some platforms. Calculations may differ from just returning plain Last-Modified header.
    // Leaving it for now but this should go away in favor of generic solution.
    void setLastModifiedDate(time_t);
    time_t lastModifiedDate() const;

    // These functions return parsed values of the corresponding response headers.
    // NaN means that the header was not present or had invalid value.
    bool cacheControlContainsNoCache();
    bool cacheControlContainsNoStore();
    bool cacheControlContainsMustRevalidate();
    bool hasCacheValidatorFields() const;
    double cacheControlMaxAge();
    double date() const;
    double age() const;
    double expires() const;
    double lastModified() const;

    unsigned connectionID() const;
    void setConnectionID(unsigned);

    bool connectionReused() const;
    void setConnectionReused(bool);

    bool wasCached() const;
    void setWasCached(bool);

    ResourceLoadTiming* resourceLoadTiming() const;
    void setResourceLoadTiming(PassRefPtr<ResourceLoadTiming>);

    PassRefPtr<ResourceLoadInfo> resourceLoadInfo() const;
    void setResourceLoadInfo(PassRefPtr<ResourceLoadInfo>);

    HTTPVersion httpVersion() const { return m_httpVersion; }
    void setHTTPVersion(HTTPVersion version) { m_httpVersion = version; }

    const CString& getSecurityInfo() const { return m_securityInfo; }
    void setSecurityInfo(const CString& securityInfo) { m_securityInfo = securityInfo; }

    bool wasFetchedViaSPDY() const { return m_wasFetchedViaSPDY; }
    void setWasFetchedViaSPDY(bool value) { m_wasFetchedViaSPDY = value; }

    bool wasNpnNegotiated() const { return m_wasNpnNegotiated; }
    void setWasNpnNegotiated(bool value) { m_wasNpnNegotiated = value; }

    bool wasAlternateProtocolAvailable() const
    {
      return m_wasAlternateProtocolAvailable;
    }
    void setWasAlternateProtocolAvailable(bool value)
    {
      m_wasAlternateProtocolAvailable = value;
    }

    bool wasFetchedViaProxy() const { return m_wasFetchedViaProxy; }
    void setWasFetchedViaProxy(bool value) { m_wasFetchedViaProxy = value; }

    bool isMultipartPayload() const { return m_isMultipartPayload; }
    void setIsMultipartPayload(bool value) { m_isMultipartPayload = value; }

    double responseTime() const { return m_responseTime; }
    void setResponseTime(double responseTime) { m_responseTime = responseTime; }

    const AtomicString& remoteIPAddress() const { return m_remoteIPAddress; }
    void setRemoteIPAddress(const AtomicString& value) { m_remoteIPAddress = value; }

    unsigned short remotePort() const { return m_remotePort; }
    void setRemotePort(unsigned short value) { m_remotePort = value; }

    const String& downloadedFilePath() const { return m_downloadedFilePath; }
    void setDownloadedFilePath(const String&);

    // Extra data associated with this response.
    ExtraData* extraData() const { return m_extraData.get(); }
    void setExtraData(PassRefPtr<ExtraData> extraData) { m_extraData = extraData; }

    // The ResourceResponse subclass may "shadow" this method to provide platform-specific memory usage information
    unsigned memoryUsage() const
    {
        // average size, mostly due to URL and Header Map strings
        return 1280;
    }

    // This method doesn't compare the all members.
    static bool compare(const ResourceResponse&, const ResourceResponse&);

private:
    void updateHeaderParsedState(const AtomicString& name);

    KURL m_url;
    AtomicString m_mimeType;
    long long m_expectedContentLength;
    AtomicString m_textEncodingName;
    String m_suggestedFilename;
    int m_httpStatusCode;
    AtomicString m_httpStatusText;
    HTTPHeaderMap m_httpHeaderFields;
    time_t m_lastModifiedDate;
    bool m_wasCached : 1;
    unsigned m_connectionID;
    bool m_connectionReused : 1;
    RefPtr<ResourceLoadTiming> m_resourceLoadTiming;
    RefPtr<ResourceLoadInfo> m_resourceLoadInfo;

    bool m_isNull : 1;

    CacheControlHeader m_cacheControlHeader;

    mutable bool m_haveParsedAgeHeader : 1;
    mutable bool m_haveParsedDateHeader : 1;
    mutable bool m_haveParsedExpiresHeader : 1;
    mutable bool m_haveParsedLastModifiedHeader : 1;

    mutable double m_age;
    mutable double m_date;
    mutable double m_expires;
    mutable double m_lastModified;

    // An opaque value that contains some information regarding the security of
    // the connection for this request, such as SSL connection info (empty
    // string if not over HTTPS).
    CString m_securityInfo;

    // HTTP version used in the response, if known.
    HTTPVersion m_httpVersion;

    // Set to true if this is part of a multipart response.
    bool m_isMultipartPayload;

    // Was the resource fetched over SPDY.  See http://dev.chromium.org/spdy
    bool m_wasFetchedViaSPDY;

    // Was the resource fetched over a channel which used TLS/Next-Protocol-Negotiation (also SPDY related).
    bool m_wasNpnNegotiated;

    // Was the resource fetched over a channel which specified "Alternate-Protocol"
    // (e.g.: Alternate-Protocol: 443:npn-spdy/1).
    bool m_wasAlternateProtocolAvailable;

    // Was the resource fetched over an explicit proxy (HTTP, SOCKS, etc).
    bool m_wasFetchedViaProxy;

    // The time at which the response headers were received.  For cached
    // responses, this time could be "far" in the past.
    double m_responseTime;

    // Remote IP address of the socket which fetched this resource.
    AtomicString m_remoteIPAddress;

    // Remote port number of the socket which fetched this resource.
    unsigned short m_remotePort;

    // The downloaded file path if the load streamed to a file.
    String m_downloadedFilePath;

    // ExtraData associated with the response.
    RefPtr<ExtraData> m_extraData;
};

inline bool operator==(const ResourceResponse& a, const ResourceResponse& b) { return ResourceResponse::compare(a, b); }
inline bool operator!=(const ResourceResponse& a, const ResourceResponse& b) { return !(a == b); }

} // namespace blink

#endif // ResourceResponse_h
