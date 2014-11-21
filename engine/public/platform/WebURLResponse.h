/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

#ifndef WebURLResponse_h
#define WebURLResponse_h

#include "sky/engine/public/platform/WebCommon.h"
#include "sky/engine/public/platform/WebPrivateOwnPtr.h"

namespace blink {

class ResourceResponse;
class WebCString;
class WebHTTPHeaderVisitor;
class WebHTTPLoadInfo;
class WebString;
class WebURL;
class WebURLLoadTiming;
class WebURLResponsePrivate;

class WebURLResponse {
public:
    enum HTTPVersion { Unknown, HTTP_0_9, HTTP_1_0, HTTP_1_1 };

    class ExtraData {
    public:
        virtual ~ExtraData() { }
    };

    ~WebURLResponse() { reset(); }

    WebURLResponse() : m_private(0) { }
    WebURLResponse(const WebURLResponse& r) : m_private(0) { assign(r); }
    WebURLResponse& operator=(const WebURLResponse& r)
    {
        assign(r);
        return *this;
    }

    explicit WebURLResponse(const WebURL& url) : m_private(0)
    {
        initialize();
        setURL(url);
    }

    BLINK_PLATFORM_EXPORT void initialize();
    BLINK_PLATFORM_EXPORT void reset();
    BLINK_PLATFORM_EXPORT void assign(const WebURLResponse&);

    BLINK_PLATFORM_EXPORT bool isNull() const;

    BLINK_PLATFORM_EXPORT WebURL url() const;
    BLINK_PLATFORM_EXPORT void setURL(const WebURL&);

    BLINK_PLATFORM_EXPORT unsigned connectionID() const;
    BLINK_PLATFORM_EXPORT void setConnectionID(unsigned);

    BLINK_PLATFORM_EXPORT bool connectionReused() const;
    BLINK_PLATFORM_EXPORT void setConnectionReused(bool);

    BLINK_PLATFORM_EXPORT WebURLLoadTiming loadTiming();
    BLINK_PLATFORM_EXPORT void setLoadTiming(const WebURLLoadTiming&);

    BLINK_PLATFORM_EXPORT WebHTTPLoadInfo httpLoadInfo();
    BLINK_PLATFORM_EXPORT void setHTTPLoadInfo(const WebHTTPLoadInfo&);

    BLINK_PLATFORM_EXPORT double responseTime() const;
    BLINK_PLATFORM_EXPORT void setResponseTime(double);

    BLINK_PLATFORM_EXPORT WebString mimeType() const;
    BLINK_PLATFORM_EXPORT void setMIMEType(const WebString&);

    BLINK_PLATFORM_EXPORT long long expectedContentLength() const;
    BLINK_PLATFORM_EXPORT void setExpectedContentLength(long long);

    BLINK_PLATFORM_EXPORT WebString textEncodingName() const;
    BLINK_PLATFORM_EXPORT void setTextEncodingName(const WebString&);

    BLINK_PLATFORM_EXPORT WebString suggestedFileName() const;
    BLINK_PLATFORM_EXPORT void setSuggestedFileName(const WebString&);

    BLINK_PLATFORM_EXPORT HTTPVersion httpVersion() const;
    BLINK_PLATFORM_EXPORT void setHTTPVersion(HTTPVersion);

    BLINK_PLATFORM_EXPORT int httpStatusCode() const;
    BLINK_PLATFORM_EXPORT void setHTTPStatusCode(int);

    BLINK_PLATFORM_EXPORT WebString httpStatusText() const;
    BLINK_PLATFORM_EXPORT void setHTTPStatusText(const WebString&);

    BLINK_PLATFORM_EXPORT WebString httpHeaderField(const WebString& name) const;
    BLINK_PLATFORM_EXPORT void setHTTPHeaderField(const WebString& name, const WebString& value);
    BLINK_PLATFORM_EXPORT void addHTTPHeaderField(const WebString& name, const WebString& value);
    BLINK_PLATFORM_EXPORT void clearHTTPHeaderField(const WebString& name);
    BLINK_PLATFORM_EXPORT void visitHTTPHeaderFields(WebHTTPHeaderVisitor*) const;

    BLINK_PLATFORM_EXPORT double lastModifiedDate() const;
    BLINK_PLATFORM_EXPORT void setLastModifiedDate(double);

    // A consumer controlled value intended to be used to record opaque
    // security info related to this request.
    BLINK_PLATFORM_EXPORT WebCString securityInfo() const;
    BLINK_PLATFORM_EXPORT void setSecurityInfo(const WebCString&);

#if INSIDE_BLINK
    BLINK_PLATFORM_EXPORT ResourceResponse& toMutableResourceResponse();
    BLINK_PLATFORM_EXPORT const ResourceResponse& toResourceResponse() const;
#endif

    // Flag whether this request was served from the disk cache entry.
    BLINK_PLATFORM_EXPORT bool wasCached() const;
    BLINK_PLATFORM_EXPORT void setWasCached(bool);

    // Flag whether this request was loaded via the SPDY protocol or not.
    // SPDY is an experimental web protocol, see http://dev.chromium.org/spdy
    BLINK_PLATFORM_EXPORT bool wasFetchedViaSPDY() const;
    BLINK_PLATFORM_EXPORT void setWasFetchedViaSPDY(bool);

    // Flag whether this request was loaded after the TLS/Next-Protocol-Negotiation was used.
    // This is related to SPDY.
    BLINK_PLATFORM_EXPORT bool wasNpnNegotiated() const;
    BLINK_PLATFORM_EXPORT void setWasNpnNegotiated(bool);

    // Flag whether this request was made when "Alternate-Protocol: xxx"
    // is present in server's response.
    BLINK_PLATFORM_EXPORT bool wasAlternateProtocolAvailable() const;
    BLINK_PLATFORM_EXPORT void setWasAlternateProtocolAvailable(bool);

    // Flag whether this request was loaded via an explicit proxy (HTTP, SOCKS, etc).
    BLINK_PLATFORM_EXPORT bool wasFetchedViaProxy() const;
    BLINK_PLATFORM_EXPORT void setWasFetchedViaProxy(bool);

    // Flag whether this request was loaded via a ServiceWorker.
    BLINK_PLATFORM_EXPORT bool wasFetchedViaServiceWorker() const;
    BLINK_PLATFORM_EXPORT void setWasFetchedViaServiceWorker(bool);

    // Flag whether this request is part of a multipart response.
    BLINK_PLATFORM_EXPORT bool isMultipartPayload() const;
    BLINK_PLATFORM_EXPORT void setIsMultipartPayload(bool);

    // This indicates the location of a downloaded response if the
    // WebURLRequest had the downloadToFile flag set to true. This file path
    // remains valid for the lifetime of the WebURLLoader used to create it.
    BLINK_PLATFORM_EXPORT WebString downloadFilePath() const;
    BLINK_PLATFORM_EXPORT void setDownloadFilePath(const WebString&);

    // Remote IP address of the socket which fetched this resource.
    BLINK_PLATFORM_EXPORT WebString remoteIPAddress() const;
    BLINK_PLATFORM_EXPORT void setRemoteIPAddress(const WebString&);

    // Remote port number of the socket which fetched this resource.
    BLINK_PLATFORM_EXPORT unsigned short remotePort() const;
    BLINK_PLATFORM_EXPORT void setRemotePort(unsigned short);

    // Extra data associated with the underlying resource response. Resource
    // responses can be copied. If non-null, each copy of a resource response
    // holds a pointer to the extra data, and the extra data pointer will be
    // deleted when the last resource response is destroyed. Setting the extra
    // data pointer will cause the underlying resource response to be
    // dissociated from any existing non-null extra data pointer.
    BLINK_PLATFORM_EXPORT ExtraData* extraData() const;
    BLINK_PLATFORM_EXPORT void setExtraData(ExtraData*);

protected:
    BLINK_PLATFORM_EXPORT void assign(WebURLResponsePrivate*);

private:
    WebURLResponsePrivate* m_private;
};

} // namespace blink

#endif
