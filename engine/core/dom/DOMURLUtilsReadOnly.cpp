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

#include "sky/engine/config.h"
#include "sky/engine/core/dom/DOMURLUtilsReadOnly.h"

#include "sky/engine/platform/weborigin/KnownPorts.h"

namespace blink {

String DOMURLUtilsReadOnly::href()
{
    const KURL& kurl = url();
    if (kurl.isNull())
        return input();
    return kurl.string();
}

String DOMURLUtilsReadOnly::origin(const KURL& kurl)
{
    // FIXME(sky): Remove.
    return "";
}

String DOMURLUtilsReadOnly::host(const KURL& kurl)
{
    if (kurl.hostEnd() == kurl.pathStart())
        return kurl.host();
    if (isDefaultPortForProtocol(kurl.port(), kurl.protocol()))
        return kurl.host();
    return kurl.host() + ":" + String::number(kurl.port());
}

String DOMURLUtilsReadOnly::port(const KURL& kurl)
{
    if (kurl.hasPort())
        return String::number(kurl.port());

    return emptyString();
}

String DOMURLUtilsReadOnly::search(const KURL& kurl)
{
    String query = kurl.query();
    return query.isEmpty() ? emptyString() : "?" + query;
}

String DOMURLUtilsReadOnly::hash(const KURL& kurl)
{
    String fragmentIdentifier = kurl.fragmentIdentifier();
    if (fragmentIdentifier.isEmpty())
        return emptyString();
    return AtomicString(String("#" + fragmentIdentifier));
}

} // namespace blink
