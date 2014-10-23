/*
 * Copyright (C) 2010 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef ProxyServer_h
#define ProxyServer_h

#include "platform/PlatformExport.h"
#include "wtf/Vector.h"
#include "wtf/text/WTFString.h"

namespace blink {

class KURL;
class NetworkingContext;

// Represents a single proxy server.
class PLATFORM_EXPORT ProxyServer {
public:
    enum Type {
        Direct,
        HTTP,
        HTTPS,
        SOCKS,
    };

    ProxyServer()
        : m_type(Direct)
        , m_port(-1)
    {
    }

    ProxyServer(Type type, const String& hostName, int port)
        : m_type(type)
        , m_hostName(hostName)
        , m_port(port)
    {
    }

    Type type() const { return m_type; }
    const String& hostName() const { return m_hostName; }
    int port() const { return m_port; }

private:
    Type m_type;
    String m_hostName;
    int m_port;
};

// Return a vector of proxy servers for the given URL.
PLATFORM_EXPORT Vector<ProxyServer> proxyServersForURL(const KURL&, const NetworkingContext*);

// Converts the given vector of proxy servers to a PAC string, as described in
// http://web.archive.org/web/20060424005037/wp.netscape.com/eng/mozilla/2.0/relnotes/demo/proxy-live.html
PLATFORM_EXPORT String toString(const Vector<ProxyServer>&);

} // namespace blink

#endif // ProxyServer_h
