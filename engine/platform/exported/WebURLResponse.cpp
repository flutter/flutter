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

#include "sky/engine/public/platform/WebURLResponse.h"

#include "sky/engine/platform/exported/WebURLResponsePrivate.h"
#include "sky/engine/platform/network/ResourceLoadTiming.h"
#include "sky/engine/platform/network/ResourceResponse.h"
#include "sky/engine/public/platform/WebHTTPHeaderVisitor.h"
#include "sky/engine/public/platform/WebHTTPLoadInfo.h"
#include "sky/engine/public/platform/WebString.h"
#include "sky/engine/public/platform/WebURL.h"
#include "sky/engine/public/platform/WebURLLoadTiming.h"
#include "sky/engine/wtf/RefPtr.h"

namespace blink {

namespace {

class ExtraDataContainer : public ResourceResponse::ExtraData {
public:
    static PassRefPtr<ExtraDataContainer> create(WebURLResponse::ExtraData* extraData) { return adoptRef(new ExtraDataContainer(extraData)); }

    virtual ~ExtraDataContainer() { }

    WebURLResponse::ExtraData* extraData() const { return m_extraData.get(); }

private:
    explicit ExtraDataContainer(WebURLResponse::ExtraData* extraData)
        : m_extraData(adoptPtr(extraData))
    {
    }

    OwnPtr<WebURLResponse::ExtraData> m_extraData;
};

} // namespace

// The standard implementation of WebURLResponsePrivate, which maintains
// ownership of a ResourceResponse instance.
class WebURLResponsePrivateImpl : public WebURLResponsePrivate {
public:
    WebURLResponsePrivateImpl()
    {
        m_resourceResponse = &m_resourceResponseAllocation;
    }

    WebURLResponsePrivateImpl(const WebURLResponsePrivate* p)
        : m_resourceResponseAllocation(*p->m_resourceResponse)
    {
        m_resourceResponse = &m_resourceResponseAllocation;
    }

    virtual void dispose() { delete this; }

private:
    virtual ~WebURLResponsePrivateImpl() { }

    ResourceResponse m_resourceResponseAllocation;
};

void WebURLResponse::initialize()
{
    assign(new WebURLResponsePrivateImpl());
}

void WebURLResponse::reset()
{
    assign(0);
}

void WebURLResponse::assign(const WebURLResponse& r)
{
    if (&r != this)
        assign(r.m_private ? new WebURLResponsePrivateImpl(r.m_private) : 0);
}

bool WebURLResponse::isNull() const
{
    return !m_private || m_private->m_resourceResponse->isNull();
}

WebURL WebURLResponse::url() const
{
    return m_private->m_resourceResponse->url();
}

void WebURLResponse::setURL(const WebURL& url)
{
    m_private->m_resourceResponse->setURL(url);
}

unsigned WebURLResponse::connectionID() const
{
    return m_private->m_resourceResponse->connectionID();
}

void WebURLResponse::setConnectionID(unsigned connectionID)
{
    m_private->m_resourceResponse->setConnectionID(connectionID);
}

bool WebURLResponse::connectionReused() const
{
    return m_private->m_resourceResponse->connectionReused();
}

void WebURLResponse::setConnectionReused(bool connectionReused)
{
    m_private->m_resourceResponse->setConnectionReused(connectionReused);
}

WebURLLoadTiming WebURLResponse::loadTiming()
{
    return WebURLLoadTiming(m_private->m_resourceResponse->resourceLoadTiming());
}

void WebURLResponse::setLoadTiming(const WebURLLoadTiming& timing)
{
    RefPtr<ResourceLoadTiming> loadTiming = PassRefPtr<ResourceLoadTiming>(timing);
    m_private->m_resourceResponse->setResourceLoadTiming(loadTiming.release());
}

WebHTTPLoadInfo WebURLResponse::httpLoadInfo()
{
    return WebHTTPLoadInfo(m_private->m_resourceResponse->resourceLoadInfo());
}

void WebURLResponse::setHTTPLoadInfo(const WebHTTPLoadInfo& value)
{
    m_private->m_resourceResponse->setResourceLoadInfo(value);
}

double WebURLResponse::responseTime() const
{
    return m_private->m_resourceResponse->responseTime();
}

void WebURLResponse::setResponseTime(double responseTime)
{
    m_private->m_resourceResponse->setResponseTime(responseTime);
}

WebString WebURLResponse::mimeType() const
{
    return m_private->m_resourceResponse->mimeType();
}

void WebURLResponse::setMIMEType(const WebString& mimeType)
{
    m_private->m_resourceResponse->setMimeType(mimeType);
}

long long WebURLResponse::expectedContentLength() const
{
    return m_private->m_resourceResponse->expectedContentLength();
}

void WebURLResponse::setExpectedContentLength(long long expectedContentLength)
{
    m_private->m_resourceResponse->setExpectedContentLength(expectedContentLength);
}

WebString WebURLResponse::textEncodingName() const
{
    return m_private->m_resourceResponse->textEncodingName();
}

void WebURLResponse::setTextEncodingName(const WebString& textEncodingName)
{
    m_private->m_resourceResponse->setTextEncodingName(textEncodingName);
}

WebString WebURLResponse::suggestedFileName() const
{
    return m_private->m_resourceResponse->suggestedFilename();
}

void WebURLResponse::setSuggestedFileName(const WebString& suggestedFileName)
{
    m_private->m_resourceResponse->setSuggestedFilename(suggestedFileName);
}

WebURLResponse::HTTPVersion WebURLResponse::httpVersion() const
{
    return static_cast<HTTPVersion>(m_private->m_resourceResponse->httpVersion());
}

void WebURLResponse::setHTTPVersion(HTTPVersion version)
{
    m_private->m_resourceResponse->setHTTPVersion(static_cast<ResourceResponse::HTTPVersion>(version));
}

int WebURLResponse::httpStatusCode() const
{
    return m_private->m_resourceResponse->httpStatusCode();
}

void WebURLResponse::setHTTPStatusCode(int httpStatusCode)
{
    m_private->m_resourceResponse->setHTTPStatusCode(httpStatusCode);
}

WebString WebURLResponse::httpStatusText() const
{
    return m_private->m_resourceResponse->httpStatusText();
}

void WebURLResponse::setHTTPStatusText(const WebString& httpStatusText)
{
    m_private->m_resourceResponse->setHTTPStatusText(httpStatusText);
}

WebString WebURLResponse::httpHeaderField(const WebString& name) const
{
    return m_private->m_resourceResponse->httpHeaderField(name);
}

void WebURLResponse::setHTTPHeaderField(const WebString& name, const WebString& value)
{
    m_private->m_resourceResponse->setHTTPHeaderField(name, value);
}

void WebURLResponse::addHTTPHeaderField(const WebString& name, const WebString& value)
{
    if (name.isNull() || value.isNull())
        return;

    m_private->m_resourceResponse->addHTTPHeaderField(name, value);
}

void WebURLResponse::clearHTTPHeaderField(const WebString& name)
{
    m_private->m_resourceResponse->clearHTTPHeaderField(name);
}

void WebURLResponse::visitHTTPHeaderFields(WebHTTPHeaderVisitor* visitor) const
{
    const HTTPHeaderMap& map = m_private->m_resourceResponse->httpHeaderFields();
    for (HTTPHeaderMap::const_iterator it = map.begin(); it != map.end(); ++it)
        visitor->visitHeader(it->key, it->value);
}

double WebURLResponse::lastModifiedDate() const
{
    return static_cast<double>(m_private->m_resourceResponse->lastModifiedDate());
}

void WebURLResponse::setLastModifiedDate(double lastModifiedDate)
{
    m_private->m_resourceResponse->setLastModifiedDate(static_cast<time_t>(lastModifiedDate));
}

WebCString WebURLResponse::securityInfo() const
{
    // FIXME: getSecurityInfo is misnamed.
    return m_private->m_resourceResponse->getSecurityInfo();
}

void WebURLResponse::setSecurityInfo(const WebCString& securityInfo)
{
    m_private->m_resourceResponse->setSecurityInfo(securityInfo);
}

ResourceResponse& WebURLResponse::toMutableResourceResponse()
{
    ASSERT(m_private);
    ASSERT(m_private->m_resourceResponse);

    return *m_private->m_resourceResponse;
}

const ResourceResponse& WebURLResponse::toResourceResponse() const
{
    ASSERT(m_private);
    ASSERT(m_private->m_resourceResponse);

    return *m_private->m_resourceResponse;
}

bool WebURLResponse::wasCached() const
{
    return m_private->m_resourceResponse->wasCached();
}

void WebURLResponse::setWasCached(bool value)
{
    m_private->m_resourceResponse->setWasCached(value);
}

bool WebURLResponse::wasFetchedViaSPDY() const
{
    return m_private->m_resourceResponse->wasFetchedViaSPDY();
}

void WebURLResponse::setWasFetchedViaSPDY(bool value)
{
    m_private->m_resourceResponse->setWasFetchedViaSPDY(value);
}

bool WebURLResponse::wasNpnNegotiated() const
{
    return m_private->m_resourceResponse->wasNpnNegotiated();
}

void WebURLResponse::setWasNpnNegotiated(bool value)
{
    m_private->m_resourceResponse->setWasNpnNegotiated(value);
}

bool WebURLResponse::wasAlternateProtocolAvailable() const
{
    return m_private->m_resourceResponse->wasAlternateProtocolAvailable();
}

void WebURLResponse::setWasAlternateProtocolAvailable(bool value)
{
    m_private->m_resourceResponse->setWasAlternateProtocolAvailable(value);
}

bool WebURLResponse::wasFetchedViaProxy() const
{
    return m_private->m_resourceResponse->wasFetchedViaProxy();
}

void WebURLResponse::setWasFetchedViaProxy(bool value)
{
    m_private->m_resourceResponse->setWasFetchedViaProxy(value);
}

bool WebURLResponse::wasFetchedViaServiceWorker() const
{
    return false;
}

void WebURLResponse::setWasFetchedViaServiceWorker(bool value)
{
}

bool WebURLResponse::isMultipartPayload() const
{
    return m_private->m_resourceResponse->isMultipartPayload();
}

void WebURLResponse::setIsMultipartPayload(bool value)
{
    m_private->m_resourceResponse->setIsMultipartPayload(value);
}

WebString WebURLResponse::downloadFilePath() const
{
    return m_private->m_resourceResponse->downloadedFilePath();
}

void WebURLResponse::setDownloadFilePath(const WebString& downloadFilePath)
{
    m_private->m_resourceResponse->setDownloadedFilePath(downloadFilePath);
}

WebString WebURLResponse::remoteIPAddress() const
{
    return m_private->m_resourceResponse->remoteIPAddress();
}

void WebURLResponse::setRemoteIPAddress(const WebString& remoteIPAddress)
{
    m_private->m_resourceResponse->setRemoteIPAddress(remoteIPAddress);
}

unsigned short WebURLResponse::remotePort() const
{
    return m_private->m_resourceResponse->remotePort();
}

void WebURLResponse::setRemotePort(unsigned short remotePort)
{
    m_private->m_resourceResponse->setRemotePort(remotePort);
}

WebURLResponse::ExtraData* WebURLResponse::extraData() const
{
    RefPtr<ResourceResponse::ExtraData> data = m_private->m_resourceResponse->extraData();
    if (!data)
        return 0;
    return static_cast<ExtraDataContainer*>(data.get())->extraData();
}

void WebURLResponse::setExtraData(WebURLResponse::ExtraData* extraData)
{
    m_private->m_resourceResponse->setExtraData(ExtraDataContainer::create(extraData));
}

void WebURLResponse::assign(WebURLResponsePrivate* p)
{
    // Subclasses may call this directly so a self-assignment check is needed
    // here as well as in the public assign method.
    if (m_private == p)
        return;
    if (m_private)
        m_private->dispose();
    m_private = p;
}

} // namespace blink
