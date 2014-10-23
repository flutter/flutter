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

#include "config.h"
#include "public/platform/WebHTTPLoadInfo.h"

#include "platform/network/ResourceLoadInfo.h"
#include "public/platform/WebHTTPHeaderVisitor.h"
#include "public/platform/WebString.h"

namespace blink {

void WebHTTPLoadInfo::initialize()
{
    m_private = adoptRef(new ResourceLoadInfo());
}

void WebHTTPLoadInfo::reset()
{
    m_private.reset();
}

void WebHTTPLoadInfo::assign(const WebHTTPLoadInfo& r)
{
    m_private = r.m_private;
}

WebHTTPLoadInfo::WebHTTPLoadInfo(WTF::PassRefPtr<ResourceLoadInfo> value)
    : m_private(value)
{
}

WebHTTPLoadInfo::operator WTF::PassRefPtr<ResourceLoadInfo>() const
{
    return m_private.get();
}

int WebHTTPLoadInfo::httpStatusCode() const
{
    ASSERT(!m_private.isNull());
    return m_private->httpStatusCode;
}

void WebHTTPLoadInfo::setHTTPStatusCode(int statusCode)
{
    ASSERT(!m_private.isNull());
    m_private->httpStatusCode = statusCode;
}

WebString WebHTTPLoadInfo::httpStatusText() const
{
    ASSERT(!m_private.isNull());
    return m_private->httpStatusText;
}

void WebHTTPLoadInfo::setHTTPStatusText(const WebString& statusText)
{
    ASSERT(!m_private.isNull());
    m_private->httpStatusText = statusText;
}

long long WebHTTPLoadInfo::encodedDataLength() const
{
    ASSERT(!m_private.isNull());
    return m_private->encodedDataLength;
}

void WebHTTPLoadInfo::setEncodedDataLength(long long encodedDataLength)
{
    ASSERT(!m_private.isNull());
    m_private->encodedDataLength = encodedDataLength;
}

static void addHeader(HTTPHeaderMap* map, const WebString& name, const WebString& value)
{
    HTTPHeaderMap::AddResult result = map->add(name, value);
    // It is important that values are separated by '\n', not comma, otherwise Set-Cookie header is not parseable.
    if (!result.isNewEntry)
        result.storedValue->value = result.storedValue->value + "\n" + String(value);
}

void WebHTTPLoadInfo::addRequestHeader(const WebString& name, const WebString& value)
{
    ASSERT(!m_private.isNull());
    addHeader(&m_private->requestHeaders, name, value);
}

void WebHTTPLoadInfo::addResponseHeader(const WebString& name, const WebString& value)
{
    ASSERT(!m_private.isNull());
    addHeader(&m_private->responseHeaders, name, value);
}

WebString WebHTTPLoadInfo::requestHeadersText() const
{
    ASSERT(!m_private.isNull());
    return m_private->requestHeadersText;
}

void WebHTTPLoadInfo::setRequestHeadersText(const WebString& headersText)
{
    ASSERT(!m_private.isNull());
    m_private->requestHeadersText = headersText;
}

WebString WebHTTPLoadInfo::responseHeadersText() const
{
    ASSERT(!m_private.isNull());
    return m_private->responseHeadersText;
}

void WebHTTPLoadInfo::setResponseHeadersText(const WebString& headersText)
{
    ASSERT(!m_private.isNull());
    m_private->responseHeadersText = headersText;
}

} // namespace blink
