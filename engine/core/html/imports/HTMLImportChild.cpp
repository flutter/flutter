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

#include "config.h"
#include "core/html/imports/HTMLImportChild.h"

#include "core/dom/Document.h"
#include "core/dom/custom/CustomElement.h"
#include "core/dom/custom/CustomElementMicrotaskImportStep.h"
#include "core/dom/custom/CustomElementSyncMicrotaskQueue.h"
#include "core/html/imports/HTMLImportChildClient.h"
#include "core/html/imports/HTMLImportLoader.h"
#include "core/html/imports/HTMLImportTreeRoot.h"
#include "core/html/imports/HTMLImportsController.h"

namespace blink {

HTMLImportChild::HTMLImportChild(const KURL& url, HTMLImportLoader* loader, SyncMode sync)
    : HTMLImport(sync)
    , m_url(url)
#if !ENABLE(OILPAN)
    , m_weakFactory(this)
#endif
    , m_loader(loader)
    , m_client(nullptr)
{
}

HTMLImportChild::~HTMLImportChild()
{
#if !ENABLE(OILPAN)
    // importDestroyed() should be called before the destruction.
    ASSERT(!m_loader);

    if (m_client)
        m_client->importChildWasDestroyed(this);
#endif
}

void HTMLImportChild::ownerInserted()
{
    if (!m_loader->isDone())
        return;
    root()->document()->styleResolverChanged();
}

void HTMLImportChild::didShareLoader()
{
    createCustomElementMicrotaskStepIfNeeded();
    stateWillChange();
}

void HTMLImportChild::didStartLoading()
{
    createCustomElementMicrotaskStepIfNeeded();
}

void HTMLImportChild::didFinish()
{
    if (m_client)
        m_client->didFinish();
}

void HTMLImportChild::didFinishLoading()
{
    stateWillChange();
    CustomElement::didFinishLoadingImport(*(root()->document()));
}

void HTMLImportChild::didFinishUpgradingCustomElements()
{
    stateWillChange();
    m_customElementMicrotaskStep.clear();
}

#if !ENABLE(OILPAN)
void HTMLImportChild::importDestroyed()
{
    if (parent())
        parent()->removeChild(this);

    ASSERT(m_loader);
    m_loader->removeImport(this);
    m_loader = nullptr;
}
#endif

Document* HTMLImportChild::document() const
{
    ASSERT(m_loader);
    return m_loader->document();
}

void HTMLImportChild::stateWillChange()
{
    toHTMLImportTreeRoot(root())->scheduleRecalcState();
}

void HTMLImportChild::stateDidChange()
{
    HTMLImport::stateDidChange();

    if (state().isReady())
        didFinish();
}

void HTMLImportChild::invalidateCustomElementMicrotaskStep()
{
    if (!m_customElementMicrotaskStep)
        return;
    m_customElementMicrotaskStep->invalidate();
    m_customElementMicrotaskStep.clear();
}

void HTMLImportChild::createCustomElementMicrotaskStepIfNeeded()
{
    ASSERT(!m_customElementMicrotaskStep);

    if (!isDone() && !formsCycle()) {
#if ENABLE(OILPAN)
        m_customElementMicrotaskStep = CustomElement::didCreateImport(this);
#else
        m_customElementMicrotaskStep = CustomElement::didCreateImport(this)->weakPtr();
#endif
    }
}

bool HTMLImportChild::isDone() const
{
    ASSERT(m_loader);

    return m_loader->isDone() && m_loader->microtaskQueue()->isEmpty() && !m_customElementMicrotaskStep;
}

HTMLImportLoader* HTMLImportChild::loader() const
{
    // This should never be called after importDestroyed.
    ASSERT(m_loader);
    return m_loader;
}

void HTMLImportChild::setClient(HTMLImportChildClient* client)
{
    ASSERT(client);
    ASSERT(!m_client);
    m_client = client;
}

#if !ENABLE(OILPAN)
void HTMLImportChild::clearClient()
{
    // Doesn't check m_client nullity because we allow
    // clearClient() to reenter.
    m_client = nullptr;
}
#endif

HTMLLinkElement* HTMLImportChild::link() const
{
    if (!m_client)
        return 0;
    return m_client->link();
}

// Ensuring following invariants against the import tree:
// - HTMLImportChild::firstImport() is the "first import" of the DFS order of the import tree.
// - The "first import" manages all the children that is loaded by the document.
void HTMLImportChild::normalize()
{
    if (!loader()->isFirstImport(this) && this->precedes(loader()->firstImport())) {
        HTMLImportChild* oldFirst = loader()->firstImport();
        loader()->moveToFirst(this);
        takeChildrenFrom(oldFirst);
    }

    for (HTMLImportChild* child = toHTMLImportChild(firstChild()); child; child = toHTMLImportChild(child->next())) {
        if (child->formsCycle())
            child->invalidateCustomElementMicrotaskStep();
        child->normalize();
    }
}

#if !defined(NDEBUG)
void HTMLImportChild::showThis()
{
    bool isFirst = loader() ? loader()->isFirstImport(this) : false;
    HTMLImport::showThis();
    fprintf(stderr, " loader=%p first=%d, step=%p sync=%s url=%s",
        m_loader.get(),
        isFirst,
        m_customElementMicrotaskStep.get(),
        isSync() ? "Y" : "N",
        url().string().utf8().data());
}
#endif

void HTMLImportChild::trace(Visitor* visitor)
{
    visitor->trace(m_customElementMicrotaskStep);
    visitor->trace(m_loader);
    visitor->trace(m_client);
    HTMLImport::trace(visitor);
}

} // namespace blink
