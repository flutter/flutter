/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#ifndef HTMLImportChild_h
#define HTMLImportChild_h

#include "core/html/imports/HTMLImport.h"
#include "platform/heap/Handle.h"
#include "platform/weborigin/KURL.h"
#include "wtf/WeakPtr.h"

namespace blink {

class CustomElementMicrotaskImportStep;
class HTMLImportLoader;
class HTMLImportChildClient;
class HTMLLinkElement;

//
// An import tree node subclas to encapsulate imported document
// lifecycle. This class is owned by HTMLImportsController. The actual loading
// is done by HTMLImportLoader, which can be shared among multiple
// HTMLImportChild of same link URL.
//
class HTMLImportChild FINAL : public HTMLImport {
public:
    HTMLImportChild(const KURL&, HTMLImportLoader*, SyncMode);
    virtual ~HTMLImportChild();

    HTMLLinkElement* link() const;
    const KURL& url() const { return m_url; }

    void ownerInserted();
    void didShareLoader();
    void didStartLoading();
#if !ENABLE(OILPAN)
    void importDestroyed();
    WeakPtr<HTMLImportChild> weakPtr() { return m_weakFactory.createWeakPtr(); }
#endif

    // HTMLImport
    virtual Document* document() const OVERRIDE;
    virtual bool isDone() const OVERRIDE;
    virtual HTMLImportLoader* loader() const OVERRIDE;
    virtual void stateWillChange() OVERRIDE;
    virtual void stateDidChange() OVERRIDE;
    virtual void trace(Visitor*) OVERRIDE;

#if !defined(NDEBUG)
    virtual void showThis() OVERRIDE;
#endif

    void setClient(HTMLImportChildClient*);
#if !ENABLE(OILPAN)
    void clearClient();
#endif

    void didFinishLoading();
    void didFinishUpgradingCustomElements();
    void normalize();

private:
    void didFinish();
    void shareLoader();
    void createCustomElementMicrotaskStepIfNeeded();
    void invalidateCustomElementMicrotaskStep();

    KURL m_url;
    WeakPtrWillBeWeakMember<CustomElementMicrotaskImportStep> m_customElementMicrotaskStep;
#if !ENABLE(OILPAN)
    WeakPtrFactory<HTMLImportChild> m_weakFactory;
#endif
    RawPtrWillBeMember<HTMLImportLoader> m_loader;
    RawPtrWillBeMember<HTMLImportChildClient> m_client;
};

inline HTMLImportChild* toHTMLImportChild(HTMLImport* import)
{
    ASSERT(!import || !import->isRoot());
    return static_cast<HTMLImportChild*>(import);
}

} // namespace blink

#endif // HTMLImportChild_h
