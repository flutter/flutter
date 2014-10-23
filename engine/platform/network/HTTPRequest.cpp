/*
 * Copyright (C) 2011 Apple Inc. All Rights Reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/network/HTTPRequest.h"

#include "wtf/text/CString.h"

namespace blink {

PassRefPtr<HTTPRequest> HTTPRequest::parseHTTPRequestFromBuffer(const char* data, size_t length, String& failureReason)
{
    if (!length) {
        failureReason = "No data to parse.";
        return nullptr;
    }

    // Request we will be building.
    RefPtr<HTTPRequest> request = HTTPRequest::create();

    // Advance a pointer through the data as needed.
    const char* pos = data;
    size_t remainingLength = length;

    // 1. Parse Method + URL.
    size_t requestLineLength = request->parseRequestLine(pos, remainingLength, failureReason);
    if (!requestLineLength)
        return nullptr;
    pos += requestLineLength;
    remainingLength -= requestLineLength;

    // 2. Parse HTTP Headers.
    size_t headersLength = request->parseHeaders(pos, remainingLength, failureReason);
    if (!headersLength)
        return nullptr;
    pos += headersLength;
    remainingLength -= headersLength;

    // 3. Parse HTTP Data.
    size_t dataLength = request->parseRequestBody(pos, remainingLength);
    remainingLength -= dataLength;

    // We should have processed the entire input.
    ASSERT(!remainingLength);
    return request.release();
}

size_t HTTPRequest::parseRequestLine(const char* data, size_t length, String& failureReason)
{
    String url;
    size_t result = parseHTTPRequestLine(data, length, failureReason, m_requestMethod, url, m_httpVersion);
    m_url = KURL(KURL(), url);
    return result;
}

size_t HTTPRequest::parseHeaders(const char* data, size_t length, String& failureReason)
{
    const char* p = data;
    const char* end = data + length;
    AtomicString name;
    AtomicString value;
    while (p < data + length) {
        size_t consumedLength = parseHTTPHeader(p, end - p, failureReason, name, value);
        if (!consumedLength)
            return 0;
        p += consumedLength;
        if (name.isEmpty())
            break;
        m_headerFields.add(name, value);
    }
    return p - data;
}

size_t HTTPRequest::parseRequestBody(const char* data, size_t length)
{
    return parseHTTPRequestBody(data, length, m_body);
}

HTTPRequest::HTTPRequest()
    : m_httpVersion(Unknown)
{
}

HTTPRequest::HTTPRequest(const String& requestMethod, const KURL& url, HTTPVersion version)
    : m_url(url)
    , m_httpVersion(version)
    , m_requestMethod(requestMethod)
{
}

HTTPRequest::~HTTPRequest()
{
}

} // namespace blink
