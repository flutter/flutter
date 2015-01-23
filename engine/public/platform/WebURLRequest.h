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

#ifndef SKY_ENGINE_PUBLIC_PLATFORM_WEBURLREQUEST_H_
#define SKY_ENGINE_PUBLIC_PLATFORM_WEBURLREQUEST_H_

#include "sky/engine/public/platform/WebCommon.h"
#include "sky/engine/public/platform/WebHTTPBody.h"
#include "sky/engine/public/platform/WebReferrerPolicy.h"

namespace blink {

class ResourceRequest;
class WebCString;
class WebHTTPBody;
class WebHTTPHeaderVisitor;
class WebString;
class WebURL;
class WebURLRequestPrivate;

class WebURLRequest {
public:
    enum CachePolicy {
        UseProtocolCachePolicy, // normal load
        ReloadIgnoringCacheData, // reload
        ReturnCacheDataElseLoad, // back/forward or encoding change - allow stale data
        ReturnCacheDataDontLoad, // results of a post - allow stale data and only use cache
        ReloadBypassingCache, // end-to-end reload
    };

    enum Priority {
        PriorityUnresolved = -1,
        PriorityVeryLow,
        PriorityLow,
        PriorityMedium,
        PriorityHigh,
        PriorityVeryHigh,
    };

    // Corresponds to Fetch's "context": http://fetch.spec.whatwg.org/#concept-request-context
    enum RequestContext {
        RequestContextUnspecified = 0,
        RequestContextAudio,
        RequestContextBeacon,
        RequestContextDownload,
        RequestContextEmbed,
        RequestContextFetch,
        RequestContextFont,
        RequestContextForm,
        RequestContextFrame,
        RequestContextHyperlink,
        RequestContextImage,
        RequestContextImageSet,
        RequestContextImport,
        RequestContextInternal,
        RequestContextLocation,
        RequestContextManifest,
        RequestContextObject,
        RequestContextPing,
        RequestContextPrefetch,
        RequestContextScript,
        RequestContextServiceWorker,
        RequestContextSharedWorker,
        RequestContextSubresource,
        RequestContextStyle,
        RequestContextTrack,
        RequestContextVideo,
        RequestContextWorker,
    };

    // Corresponds to Fetch's "context frame type": http://fetch.spec.whatwg.org/#concept-request-context-frame-type
    enum FrameType {
        FrameTypeAuxiliary,
        FrameTypeNested,
        FrameTypeNone,
        FrameTypeTopLevel
    };

    class ExtraData {
    public:
        virtual ~ExtraData() { }
    };

    ~WebURLRequest() { reset(); }

    WebURLRequest() : m_private(0) { }
    WebURLRequest(const WebURLRequest& r) : m_private(0) { assign(r); }
    WebURLRequest& operator=(const WebURLRequest& r)
    {
        assign(r);
        return *this;
    }

    explicit WebURLRequest(const WebURL& url) : m_private(0)
    {
        initialize();
        setURL(url);
    }

    BLINK_PLATFORM_EXPORT void initialize();
    BLINK_PLATFORM_EXPORT void reset();
    BLINK_PLATFORM_EXPORT void assign(const WebURLRequest&);

    BLINK_PLATFORM_EXPORT bool isNull() const;

    BLINK_PLATFORM_EXPORT WebURL url() const;
    BLINK_PLATFORM_EXPORT void setURL(const WebURL&);

    // Controls whether user name, password, and cookies may be sent with the
    // request. (If false, this overrides allowCookies.)
    BLINK_PLATFORM_EXPORT bool allowStoredCredentials() const;
    BLINK_PLATFORM_EXPORT void setAllowStoredCredentials(bool);

    BLINK_PLATFORM_EXPORT CachePolicy cachePolicy() const;
    BLINK_PLATFORM_EXPORT void setCachePolicy(CachePolicy);

    BLINK_PLATFORM_EXPORT WebString httpMethod() const;
    BLINK_PLATFORM_EXPORT void setHTTPMethod(const WebString&);

    BLINK_PLATFORM_EXPORT WebString httpHeaderField(const WebString& name) const;
    // It's not possible to set the referrer header using this method. Use setHTTPReferrer instead.
    BLINK_PLATFORM_EXPORT void setHTTPHeaderField(const WebString& name, const WebString& value);
    BLINK_PLATFORM_EXPORT void setHTTPReferrer(const WebString& referrer, WebReferrerPolicy);
    BLINK_PLATFORM_EXPORT void addHTTPHeaderField(const WebString& name, const WebString& value);
    BLINK_PLATFORM_EXPORT void clearHTTPHeaderField(const WebString& name);
    BLINK_PLATFORM_EXPORT void visitHTTPHeaderFields(WebHTTPHeaderVisitor*) const;

    BLINK_PLATFORM_EXPORT WebHTTPBody httpBody() const;
    BLINK_PLATFORM_EXPORT void setHTTPBody(const WebHTTPBody&);

    // Controls whether upload progress events are generated when a request
    // has a body.
    BLINK_PLATFORM_EXPORT bool reportUploadProgress() const;
    BLINK_PLATFORM_EXPORT void setReportUploadProgress(bool);

    // Controls whether actual headers sent and received for request are
    // collected and reported.
    BLINK_PLATFORM_EXPORT bool reportRawHeaders() const;
    BLINK_PLATFORM_EXPORT void setReportRawHeaders(bool);

    BLINK_PLATFORM_EXPORT RequestContext requestContext() const;
    BLINK_PLATFORM_EXPORT void setRequestContext(RequestContext);

    BLINK_PLATFORM_EXPORT FrameType frameType() const;
    BLINK_PLATFORM_EXPORT void setFrameType(FrameType);

    BLINK_PLATFORM_EXPORT WebReferrerPolicy referrerPolicy() const;

    // Adds an HTTP origin header if it is empty and the HTTP method of the
    // request requires it.
    BLINK_PLATFORM_EXPORT void addHTTPOriginIfNeeded(const WebString& origin);

    // A consumer controlled value intended to be used to identify the
    // requestor.
    BLINK_PLATFORM_EXPORT int requestorID() const;
    BLINK_PLATFORM_EXPORT void setRequestorID(int);

    // A consumer controlled value intended to be used to identify the
    // process of the requestor.
    BLINK_PLATFORM_EXPORT int requestorProcessID() const;
    BLINK_PLATFORM_EXPORT void setRequestorProcessID(int);

    // If true, the response body will be downloaded to a file managed by the
    // WebURLLoader. See WebURLResponse::downloadedFilePath.
    BLINK_PLATFORM_EXPORT bool downloadToFile() const;
    BLINK_PLATFORM_EXPORT void setDownloadToFile(bool);

    // True if the request should not be handled by the ServiceWorker.
    BLINK_PLATFORM_EXPORT bool skipServiceWorker() const;
    BLINK_PLATFORM_EXPORT void setSkipServiceWorker(bool);

    // Extra data associated with the underlying resource request. Resource
    // requests can be copied. If non-null, each copy of a resource requests
    // holds a pointer to the extra data, and the extra data pointer will be
    // deleted when the last resource request is destroyed. Setting the extra
    // data pointer will cause the underlying resource request to be
    // dissociated from any existing non-null extra data pointer.
    BLINK_PLATFORM_EXPORT ExtraData* extraData() const;
    BLINK_PLATFORM_EXPORT void setExtraData(ExtraData*);

    BLINK_PLATFORM_EXPORT Priority priority() const;
    BLINK_PLATFORM_EXPORT void setPriority(Priority);

#if INSIDE_BLINK
    BLINK_PLATFORM_EXPORT ResourceRequest& toMutableResourceRequest();
    BLINK_PLATFORM_EXPORT const ResourceRequest& toResourceRequest() const;
#endif

protected:
    BLINK_PLATFORM_EXPORT void assign(WebURLRequestPrivate*);

private:
    WebURLRequestPrivate* m_private;
};

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_PLATFORM_WEBURLREQUEST_H_
