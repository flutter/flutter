/*
 * Copyright (C) 2012 Motorola Mobility Inc.
 * Copyright (C) 2013 Google Inc. All Rights Reserved.
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
#include "core/html/PublicURLManager.h"

#include "core/fetch/MemoryCache.h"
#include "core/html/URLRegistry.h"
#include "platform/weborigin/KURL.h"
#include "wtf/Vector.h"
#include "wtf/text/StringHash.h"

namespace blink {

PassOwnPtr<PublicURLManager> PublicURLManager::create(ExecutionContext* context)
{
    OwnPtr<PublicURLManager> publicURLManager(adoptPtr(new PublicURLManager(context)));
    publicURLManager->suspendIfNeeded();
    return publicURLManager.release();
}

PublicURLManager::PublicURLManager(ExecutionContext* context)
    : ActiveDOMObject(context)
    , m_isStopped(false)
{
}

void PublicURLManager::revoke(const KURL& url)
{
    for (RegistryURLMap::iterator i = m_registryToURL.begin(); i != m_registryToURL.end(); ++i) {
        if (i->value.contains(url.string())) {
            i->key->unregisterURL(url);
            i->value.remove(url.string());
            break;
        }
    }
}

void PublicURLManager::revoke(const String& uuid)
{
    // A linear scan; revoking by UUID is assumed rare.
    Vector<String> urlsToRemove;
    for (RegistryURLMap::iterator i = m_registryToURL.begin(); i != m_registryToURL.end(); ++i) {
        URLRegistry* registry = i->key;
        URLMap& registeredURLs = i->value;
        for (URLMap::iterator j = registeredURLs.begin(); j != registeredURLs.end(); ++j) {
            if (uuid == j->value) {
                KURL url(ParsedURLString, j->key);
                MemoryCache::removeURLFromCache(executionContext(), url);
                registry->unregisterURL(url);
                urlsToRemove.append(j->key);
            }
        }
        for (unsigned j = 0; j < urlsToRemove.size(); j++)
            registeredURLs.remove(urlsToRemove[j]);
        urlsToRemove.clear();
    }
}

void PublicURLManager::stop()
{
    if (m_isStopped)
        return;

    m_isStopped = true;
    for (RegistryURLMap::iterator i = m_registryToURL.begin(); i != m_registryToURL.end(); ++i) {
        for (URLMap::iterator j = i->value.begin(); j != i->value.end(); ++j)
            i->key->unregisterURL(KURL(ParsedURLString, j->key));
    }

    m_registryToURL.clear();
}

}
