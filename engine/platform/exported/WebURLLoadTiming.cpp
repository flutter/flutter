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
#include "public/platform/WebURLLoadTiming.h"

#include "platform/network/ResourceLoadTiming.h"
#include "public/platform/WebString.h"

namespace blink {

void WebURLLoadTiming::initialize()
{
    m_private = ResourceLoadTiming::create();
}

void WebURLLoadTiming::reset()
{
    m_private.reset();
}

void WebURLLoadTiming::assign(const WebURLLoadTiming& other)
{
    m_private = other.m_private;
}

double WebURLLoadTiming::requestTime() const
{
    return m_private->requestTime;
}

void WebURLLoadTiming::setRequestTime(double time)
{
    m_private->requestTime = time;
}

double WebURLLoadTiming::proxyStart() const
{
    return m_private->proxyStart;
}

void WebURLLoadTiming::setProxyStart(double start)
{
    m_private->proxyStart = start;
}

double WebURLLoadTiming::proxyEnd() const
{
    return m_private->proxyEnd;
}

void WebURLLoadTiming::setProxyEnd(double end)
{
    m_private->proxyEnd = end;
}

double WebURLLoadTiming::dnsStart() const
{
    return m_private->dnsStart;
}

void WebURLLoadTiming::setDNSStart(double start)
{
    m_private->dnsStart = start;
}

double WebURLLoadTiming::dnsEnd() const
{
    return m_private->dnsEnd;
}

void WebURLLoadTiming::setDNSEnd(double end)
{
    m_private->dnsEnd = end;
}

double WebURLLoadTiming::connectStart() const
{
    return m_private->connectStart;
}

void WebURLLoadTiming::setConnectStart(double start)
{
    m_private->connectStart = start;
}

double WebURLLoadTiming::connectEnd() const
{
    return m_private->connectEnd;
}

void WebURLLoadTiming::setConnectEnd(double end)
{
    m_private->connectEnd = end;
}

double WebURLLoadTiming::sendStart() const
{
    return m_private->sendStart;
}

void WebURLLoadTiming::setSendStart(double start)
{
    m_private->sendStart = start;
}

double WebURLLoadTiming::sendEnd() const
{
    return m_private->sendEnd;
}

void WebURLLoadTiming::setSendEnd(double end)
{
    m_private->sendEnd = end;
}

double WebURLLoadTiming::receiveHeadersEnd() const
{
    return m_private->receiveHeadersEnd;
}

void WebURLLoadTiming::setReceiveHeadersEnd(double end)
{
    m_private->receiveHeadersEnd = end;
}

double WebURLLoadTiming::sslStart() const
{
    return m_private->sslStart;
}

void WebURLLoadTiming::setSSLStart(double start)
{
    m_private->sslStart = start;
}

double WebURLLoadTiming::sslEnd() const
{
    return m_private->sslEnd;
}

void WebURLLoadTiming::setSSLEnd(double end)
{
    m_private->sslEnd = end;
}

WebURLLoadTiming::WebURLLoadTiming(const PassRefPtr<ResourceLoadTiming>& value)
    : m_private(value)
{
}

WebURLLoadTiming& WebURLLoadTiming::operator=(const PassRefPtr<ResourceLoadTiming>& value)
{
    m_private = value;
    return *this;
}

WebURLLoadTiming::operator PassRefPtr<ResourceLoadTiming>() const
{
    return m_private.get();
}

} // namespace blink
