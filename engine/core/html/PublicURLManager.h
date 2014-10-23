/*
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

#ifndef PublicURLManager_h
#define PublicURLManager_h

#include "core/dom/ActiveDOMObject.h"
#include "wtf/HashMap.h"
#include "wtf/HashSet.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/text/WTFString.h"

namespace blink {

class KURL;
class ExecutionContext;
class URLRegistry;
class URLRegistrable;

class PublicURLManager FINAL : public ActiveDOMObject {
    WTF_MAKE_FAST_ALLOCATED;
public:
    static PassOwnPtr<PublicURLManager> create(ExecutionContext*);

    void revoke(const KURL&);
    void revoke(const String& uuid);

    // ActiveDOMObject interface.
    virtual void stop() OVERRIDE;

private:
    PublicURLManager(ExecutionContext*);

    // One or more URLs can be associated with the same unique ID.
    // Objects need be revoked by unique ID in some cases.
    typedef String URLString;
    typedef HashMap<URLString, String> URLMap;
    typedef HashMap<URLRegistry*, URLMap> RegistryURLMap;

    RegistryURLMap m_registryToURL;
    bool m_isStopped;
};

} // namespace blink

#endif // PublicURLManager_h
