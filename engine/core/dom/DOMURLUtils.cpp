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

#include "config.h"
#include "core/dom/DOMURLUtils.h"

#include "platform/weborigin/KnownPorts.h"

namespace blink {

void DOMURLUtils::setHref(const String& value)
{
    setInput(value);
}

void DOMURLUtils::setProtocol(const String& value)
{
    KURL kurl = url();
    if (kurl.isNull())
        return;
    kurl.setProtocol(value);
    setURL(kurl);
}

void DOMURLUtils::setUsername(const String& value)
{
    KURL kurl = url();
    if (kurl.isNull())
        return;
    kurl.setUser(value);
    setURL(kurl);
}

void DOMURLUtils::setPassword(const String& value)
{
    KURL kurl = url();
    if (kurl.isNull())
        return;
    kurl.setPass(value);
    setURL(kurl);
}

void DOMURLUtils::setHost(const String& value)
{
    if (value.isEmpty())
        return;

    KURL kurl = url();
    if (!kurl.canSetHostOrPort())
        return;

    kurl.setHostAndPort(value);
    setURL(kurl);
}

void DOMURLUtils::setHostname(const String& value)
{
    KURL kurl = url();
    if (!kurl.canSetHostOrPort())
        return;

    // Before setting new value:
    // Remove all leading U+002F SOLIDUS ("/") characters.
    unsigned i = 0;
    unsigned hostLength = value.length();
    while (value[i] == '/')
        i++;

    if (i == hostLength)
        return;

    kurl.setHost(value.substring(i));

    setURL(kurl);
}

void DOMURLUtils::setPort(const String& value)
{
    KURL kurl = url();
    if (!kurl.canSetHostOrPort())
        return;

    kurl.setPort(value);
    setURL(kurl);
}

void DOMURLUtils::setPathname(const String& value)
{
    KURL kurl = url();
    if (!kurl.canSetPathname())
        return;
    kurl.setPath(value);
    setURL(kurl);
}

void DOMURLUtils::setSearch(const String& value)
{
    KURL kurl = url();
    if (!kurl.isValid())
        return;
    kurl.setQuery(value);
    setURL(kurl);
}

void DOMURLUtils::setHash(const String& value)
{
    KURL kurl = url();
    if (kurl.isNull())
        return;

    if (value[0] == '#')
        kurl.setFragmentIdentifier(value.substring(1));
    else
        kurl.setFragmentIdentifier(value);

    setURL(kurl);
}

} // namespace blink
