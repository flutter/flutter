/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 * Copyright (C) 2012 Motorola Mobility Inc.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef DOMURLUtilsReadOnly_h
#define DOMURLUtilsReadOnly_h

#include "platform/weborigin/KURL.h"
#include "wtf/Forward.h"

namespace blink {

class DOMURLUtilsReadOnly {
public:
    virtual KURL url() const = 0;
    virtual String input() const = 0;
    virtual ~DOMURLUtilsReadOnly() { };

    String href();

    static String origin(const KURL&);
    String origin() { return origin(url()); }

    static String protocol(const KURL& url) { return url.protocol() + ":"; }
    String protocol() { return protocol(url()); }

    static String username(const KURL& url) { return url.user(); }
    String username() { return username(url()); }

    static String password(const KURL& url) { return url.pass(); }
    String password() { return password(url()); }

    static String host(const KURL&);
    String host() { return host(url()); }

    static String hostname(const KURL& url) { return url.host(); }
    String hostname() { return hostname(url()); }

    static String port(const KURL&);
    String port() { return port(url()); }

    static String pathname(const KURL& url) { return url.path(); }
    String pathname() { return pathname(url()); }

    static String search(const KURL&);
    String search() { return search(url()); }

    static String hash(const KURL&);
    String hash() { return hash(url()); }
};

} // namespace blink

#endif // DOMURLUtilsReadOnly_h
