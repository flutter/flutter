/*
 * Copyright (C) 2011 Google Inc. All Rights Reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS ``AS IS'' AND ANY
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

#include "sky/engine/core/fetch/RawResource.h"

#include "sky/engine/core/fetch/ResourceClientWalker.h"
#include "sky/engine/core/fetch/ResourceFetcher.h"
#include "sky/engine/core/fetch/ResourceLoader.h"
#include "sky/engine/platform/SharedBuffer.h"

namespace blink {

RawResource::RawResource(const ResourceRequest& resourceRequest, Type type)
    : Resource(resourceRequest, type)
{
}

void RawResource::appendData(const char* data, int length)
{
    Resource::appendData(data, length);

    ResourcePtr<RawResource> protect(this);
    ResourceClientWalker<RawResourceClient> w(m_clients);
    while (RawResourceClient* c = w.next())
        c->dataReceived(this, data, length);
}

void RawResource::didAddClient(ResourceClient* c)
{
    if (!hasClient(c))
        return;
    // The calls to the client can result in events running, potentially causing
    // this resource to be evicted from the cache and all clients to be removed,
    // so a protector is necessary.
    ResourcePtr<RawResource> protect(this);
    RawResourceClient* client = static_cast<RawResourceClient*>(c);

    if (!m_response.isNull())
        client->responseReceived(this, m_response);
    if (!hasClient(c))
        return;
    if (m_data)
        client->dataReceived(this, m_data->data(), m_data->size());
    if (!hasClient(c))
        return;
    Resource::didAddClient(client);
}

void RawResource::willSendRequest(ResourceRequest& request, const ResourceResponse& response)
{
    Resource::willSendRequest(request, response);
}

void RawResource::updateRequest(const ResourceRequest& request)
{
    ResourcePtr<RawResource> protect(this);
    ResourceClientWalker<RawResourceClient> w(m_clients);
    while (RawResourceClient* c = w.next())
        c->updateRequest(this, request);
}

void RawResource::responseReceived(const ResourceResponse& response)
{
    InternalResourcePtr protect(this);
    Resource::responseReceived(response);
    ResourceClientWalker<RawResourceClient> w(m_clients);
    while (RawResourceClient* c = w.next())
        c->responseReceived(this, m_response);
}

void RawResource::didSendData(unsigned long long bytesSent, unsigned long long totalBytesToBeSent)
{
    ResourceClientWalker<RawResourceClient> w(m_clients);
    while (RawResourceClient* c = w.next())
        c->dataSent(this, bytesSent, totalBytesToBeSent);
}

void RawResource::didDownloadData(int dataLength)
{
    ResourceClientWalker<RawResourceClient> w(m_clients);
    while (RawResourceClient* c = w.next())
        c->dataDownloaded(this, dataLength);
}

static bool shouldIgnoreHeaderForCacheReuse(AtomicString headerName)
{
    // FIXME: This list of headers that don't affect cache policy almost certainly isn't complete.
    DEFINE_STATIC_LOCAL(HashSet<AtomicString>, m_headers, ());
    if (m_headers.isEmpty()) {
        m_headers.add("Cache-Control");
        m_headers.add("If-Modified-Since");
        m_headers.add("If-None-Match");
        m_headers.add("Origin");
        m_headers.add("Pragma");
        m_headers.add("Purpose");
        m_headers.add("Referer");
        m_headers.add("User-Agent");
    }
    return m_headers.contains(headerName);
}

static bool isCacheableHTTPMethod(const AtomicString& method)
{
    // Per http://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html#sec13.10,
    // these methods always invalidate the cache entry.
    return method != "POST" && method != "PUT" && method != "DELETE";
}

bool RawResource::canReuse(const ResourceRequest& newRequest) const
{
    if (m_options.dataBufferingPolicy == DoNotBufferData)
        return false;

    if (!isCacheableHTTPMethod(m_resourceRequest.httpMethod()))
        return false;
    if (m_resourceRequest.httpMethod() != newRequest.httpMethod())
        return false;

    if (m_resourceRequest.httpBody() != newRequest.httpBody())
        return false;

    if (m_resourceRequest.allowStoredCredentials() != newRequest.allowStoredCredentials())
        return false;

    // Ensure most headers match the existing headers before continuing.
    // Note that the list of ignored headers includes some headers explicitly related to caching.
    // A more detailed check of caching policy will be performed later, this is simply a list of
    // headers that we might permit to be different and still reuse the existing Resource.
    const HTTPHeaderMap& newHeaders = newRequest.httpHeaderFields();
    const HTTPHeaderMap& oldHeaders = m_resourceRequest.httpHeaderFields();

    HTTPHeaderMap::const_iterator end = newHeaders.end();
    for (HTTPHeaderMap::const_iterator i = newHeaders.begin(); i != end; ++i) {
        AtomicString headerName = i->key;
        if (!shouldIgnoreHeaderForCacheReuse(headerName) && i->value != oldHeaders.get(headerName))
            return false;
    }

    end = oldHeaders.end();
    for (HTTPHeaderMap::const_iterator i = oldHeaders.begin(); i != end; ++i) {
        AtomicString headerName = i->key;
        if (!shouldIgnoreHeaderForCacheReuse(headerName) && i->value != newHeaders.get(headerName))
            return false;
    }

    return true;
}

} // namespace blink
