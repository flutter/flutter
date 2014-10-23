/*
 * Copyright (C) 2006 Apple Computer, Inc.  All rights reserved.
 * Copyright (C) 2013 Google Inc.  All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef ResourceError_h
#define ResourceError_h

#include "platform/PlatformExport.h"
#include "wtf/text/WTFString.h"

namespace blink {

PLATFORM_EXPORT extern const char errorDomainBlinkInternal[]; // Used for errors that won't be exposed to clients.

class PLATFORM_EXPORT ResourceError {
public:
    static ResourceError cancelledError(const String& failingURL);

    ResourceError()
        : m_errorCode(0)
        , m_isNull(true)
        , m_isCancellation(false)
        , m_isTimeout(false)
        , m_staleCopyInCache(false)
    {
    }

    ResourceError(const String& domain, int errorCode, const String& failingURL, const String& localizedDescription)
        : m_domain(domain)
        , m_errorCode(errorCode)
        , m_failingURL(failingURL)
        , m_localizedDescription(localizedDescription)
        , m_isNull(false)
        , m_isCancellation(false)
        , m_isTimeout(false)
        , m_staleCopyInCache(false)
    {
    }

    // Makes a deep copy. Useful for when you need to use a ResourceError on another thread.
    ResourceError copy() const;

    bool isNull() const { return m_isNull; }

    const String& domain() const { return m_domain; }
    int errorCode() const { return m_errorCode; }
    const String& failingURL() const { return m_failingURL; }
    const String& localizedDescription() const { return m_localizedDescription; }

    void setIsCancellation(bool isCancellation) { m_isCancellation = isCancellation; }
    bool isCancellation() const { return m_isCancellation; }

    void setIsTimeout(bool isTimeout) { m_isTimeout = isTimeout; }
    bool isTimeout() const { return m_isTimeout; }
    void setStaleCopyInCache(bool staleCopyInCache) { m_staleCopyInCache = staleCopyInCache; }
    bool staleCopyInCache() const { return m_staleCopyInCache; }

    static bool compare(const ResourceError&, const ResourceError&);

private:
    String m_domain;
    int m_errorCode;
    String m_failingURL;
    String m_localizedDescription;
    bool m_isNull;
    bool m_isCancellation;
    bool m_isTimeout;
    bool m_staleCopyInCache;
};

inline bool operator==(const ResourceError& a, const ResourceError& b) { return ResourceError::compare(a, b); }
inline bool operator!=(const ResourceError& a, const ResourceError& b) { return !(a == b); }

} // namespace blink

#endif // ResourceError_h
