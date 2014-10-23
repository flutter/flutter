/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
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
 *
 */

#include "config.h"
#include "core/html/LinkRelAttribute.h"

#include "platform/RuntimeEnabledFeatures.h"

namespace blink {

LinkRelAttribute::LinkRelAttribute(const String& rel)
    : m_isStyleSheet(false)
    , m_isLinkPrefetch(false)
    , m_isLinkSubresource(false)
    , m_isLinkNext(false)
    , m_isImport(false)
    , m_isManifest(false)
{
    if (rel.isEmpty())
        return;
    String relCopy = rel;
    relCopy.replace('\n', ' ');
    Vector<String> list;
    relCopy.split(' ', list);
    Vector<String>::const_iterator end = list.end();
    for (Vector<String>::const_iterator it = list.begin(); it != end; ++it) {
        if (equalIgnoringCase(*it, "stylesheet")) {
            if (!m_isImport)
                m_isStyleSheet = true;
        } else if (equalIgnoringCase(*it, "import")) {
            if (!m_isStyleSheet)
                m_isImport = true;
        } else if (equalIgnoringCase(*it, "prefetch")) {
            m_isLinkPrefetch = true;
        } else if (equalIgnoringCase(*it, "subresource")) {
            m_isLinkSubresource = true;
        } else if (equalIgnoringCase(*it, "next")) {
            m_isLinkNext = true;
        } else if (equalIgnoringCase(*it, "manifest")) {
            m_isManifest = true;
        }
    }
}

}
