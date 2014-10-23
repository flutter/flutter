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

#ifndef WebURLLoadTiming_h
#define WebURLLoadTiming_h

#include "WebCommon.h"
#include "WebPrivatePtr.h"

namespace blink {

class ResourceLoadTiming;
class WebString;

class WebURLLoadTiming {
public:
    ~WebURLLoadTiming() { reset(); }

    WebURLLoadTiming() { }
    WebURLLoadTiming(const WebURLLoadTiming& d) { assign(d); }
    WebURLLoadTiming& operator=(const WebURLLoadTiming& d)
    {
        assign(d);
        return *this;
    }

    BLINK_PLATFORM_EXPORT void initialize();
    BLINK_PLATFORM_EXPORT void reset();
    BLINK_PLATFORM_EXPORT void assign(const WebURLLoadTiming&);

    bool isNull() const { return m_private.isNull(); }

    BLINK_PLATFORM_EXPORT double requestTime() const;
    BLINK_PLATFORM_EXPORT void setRequestTime(double);

    BLINK_PLATFORM_EXPORT double proxyStart() const;
    BLINK_PLATFORM_EXPORT void setProxyStart(double);

    BLINK_PLATFORM_EXPORT double proxyEnd() const;
    BLINK_PLATFORM_EXPORT void setProxyEnd(double);

    BLINK_PLATFORM_EXPORT double dnsStart() const;
    BLINK_PLATFORM_EXPORT void setDNSStart(double);

    BLINK_PLATFORM_EXPORT double dnsEnd() const;
    BLINK_PLATFORM_EXPORT void setDNSEnd(double);

    BLINK_PLATFORM_EXPORT double connectStart() const;
    BLINK_PLATFORM_EXPORT void setConnectStart(double);

    BLINK_PLATFORM_EXPORT double connectEnd() const;
    BLINK_PLATFORM_EXPORT void setConnectEnd(double);

    BLINK_PLATFORM_EXPORT double sendStart() const;
    BLINK_PLATFORM_EXPORT void setSendStart(double);

    BLINK_PLATFORM_EXPORT double sendEnd() const;
    BLINK_PLATFORM_EXPORT void setSendEnd(double);

    BLINK_PLATFORM_EXPORT double receiveHeadersEnd() const;
    BLINK_PLATFORM_EXPORT void setReceiveHeadersEnd(double);

    BLINK_PLATFORM_EXPORT double sslStart() const;
    BLINK_PLATFORM_EXPORT void setSSLStart(double);

    BLINK_PLATFORM_EXPORT double sslEnd() const;
    BLINK_PLATFORM_EXPORT void setSSLEnd(double);

#if INSIDE_BLINK
    BLINK_PLATFORM_EXPORT WebURLLoadTiming(const WTF::PassRefPtr<ResourceLoadTiming>&);
    BLINK_PLATFORM_EXPORT WebURLLoadTiming& operator=(const WTF::PassRefPtr<ResourceLoadTiming>&);
    BLINK_PLATFORM_EXPORT operator WTF::PassRefPtr<ResourceLoadTiming>() const;
#endif

private:
    WebPrivatePtr<ResourceLoadTiming> m_private;
};

} // namespace blink

#endif
