/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
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

#ifndef WebHTTPLoadInfo_h
#define WebHTTPLoadInfo_h

#include "WebCommon.h"
#include "WebPrivatePtr.h"

namespace blink {

class WebString;
struct ResourceLoadInfo;

class WebHTTPLoadInfo {
public:
    WebHTTPLoadInfo() { initialize(); }
    ~WebHTTPLoadInfo() { reset(); }
    WebHTTPLoadInfo(const WebHTTPLoadInfo& r) { assign(r); }
    WebHTTPLoadInfo& operator =(const WebHTTPLoadInfo& r)
    {
        assign(r);
        return *this;
    }

    BLINK_PLATFORM_EXPORT void initialize();
    BLINK_PLATFORM_EXPORT void reset();
    BLINK_PLATFORM_EXPORT void assign(const WebHTTPLoadInfo& r);

    BLINK_PLATFORM_EXPORT int httpStatusCode() const;
    BLINK_PLATFORM_EXPORT void setHTTPStatusCode(int);

    BLINK_PLATFORM_EXPORT WebString httpStatusText() const;
    BLINK_PLATFORM_EXPORT void setHTTPStatusText(const WebString&);

    BLINK_PLATFORM_EXPORT long long encodedDataLength() const;
    BLINK_PLATFORM_EXPORT void setEncodedDataLength(long long);

    BLINK_PLATFORM_EXPORT void addRequestHeader(const WebString& name, const WebString& value);
    BLINK_PLATFORM_EXPORT void addResponseHeader(const WebString& name, const WebString& value);

    BLINK_PLATFORM_EXPORT WebString requestHeadersText() const;
    BLINK_PLATFORM_EXPORT void setRequestHeadersText(const WebString&);

    BLINK_PLATFORM_EXPORT WebString responseHeadersText() const;
    BLINK_PLATFORM_EXPORT void setResponseHeadersText(const WebString&);

#if INSIDE_BLINK
    BLINK_PLATFORM_EXPORT WebHTTPLoadInfo(WTF::PassRefPtr<ResourceLoadInfo>);
    BLINK_PLATFORM_EXPORT operator WTF::PassRefPtr<ResourceLoadInfo>() const;
#endif

private:
    WebPrivatePtr<ResourceLoadInfo> m_private;
};

} // namespace blink

#endif
