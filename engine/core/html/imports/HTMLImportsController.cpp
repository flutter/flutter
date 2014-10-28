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
#include "core/html/imports/HTMLImportsController.h"

#include "core/dom/Document.h"
#include "core/fetch/ResourceFetcher.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/UseCounter.h"
#include "core/html/imports/HTMLImportChild.h"
#include "core/html/imports/HTMLImportChildClient.h"
#include "core/html/imports/HTMLImportLoader.h"
#include "core/html/imports/HTMLImportTreeRoot.h"

namespace blink {

const char* HTMLImportsController::supplementName()
{
    DEFINE_STATIC_LOCAL(const char*, name, ("HTMLImportsController"));
    return name;
}

void HTMLImportsController::provideTo(Document& master)
{
    OwnPtr<HTMLImportsController> controller = adoptPtr(new HTMLImportsController(master));
    master.setImportsController(controller.get());
    DocumentSupplement::provideTo(master, supplementName(), controller.release());
}

void HTMLImportsController::removeFrom(Document& master)
{
    static_cast<DocumentSupplementable&>(master).removeSupplement(supplementName());
    master.setImportsController(nullptr);
}

HTMLImportsController::HTMLImportsController(Document& master)
    : m_root(HTMLImportTreeRoot::create(&master))
{
    UseCounter::count(master, UseCounter::HTMLImports);
}

HTMLImportsController::~HTMLImportsController()
{
#if !ENABLE(OILPAN)
    m_root.clear();

    for (size_t i = 0; i < m_loaders.size(); ++i)
        m_loaders[i]->importDestroyed();
    m_loaders.clear();
#endif
}

static bool makesCycle(HTMLImport* parent, const KURL& url)
{
    for (HTMLImport* ancestor = parent; ancestor; ancestor = ancestor->parent()) {
        if (!ancestor->isRoot() && equalIgnoringFragmentIdentifier(toHTMLImportChild(parent)->url(), url))
            return true;
    }

    return false;
}

HTMLImportChild* HTMLImportsController::createChild(const KURL& url, HTMLImportLoader* loader, HTMLImport* parent, HTMLImportChildClient* client)
{
    HTMLImport::SyncMode mode = client->isSync() && !makesCycle(parent, url) ? HTMLImport::Sync : HTMLImport::Async;
    if (mode == HTMLImport::Async)
        UseCounter::count(root()->document(), UseCounter::HTMLImportsAsyncAttribute);

    OwnPtr<HTMLImportChild> child = adoptPtr(new HTMLImportChild(url, loader, mode));
    child->setClient(client);
    parent->appendImport(child.get());
    loader->addImport(child.get());
    return root()->add(child.release());
}

HTMLImportChild* HTMLImportsController::load(HTMLImport* parent, HTMLImportChildClient* client, FetchRequest request)
{
    ASSERT(!request.url().isEmpty() && request.url().isValid());
    ASSERT(parent == root() || toHTMLImportChild(parent)->loader()->isFirstImport(toHTMLImportChild(parent)));

    if (HTMLImportChild* childToShareWith = root()->find(request.url())) {
        HTMLImportLoader* loader = childToShareWith->loader();
        ASSERT(loader);
        HTMLImportChild* child = createChild(request.url(), loader, parent, client);
        child->didShareLoader();
        return child;
    }

    HTMLImportLoader* loader = createLoader();
    HTMLImportChild* child = createChild(request.url(), loader, parent, client);
    // We set resource after the import tree is built since
    // Resource::addClient() immediately calls back to feed the bytes when the resource is cached.
    loader->startLoading(request.url());
    child->didStartLoading();
    return child;
}

Document* HTMLImportsController::master() const
{
    return root()->document();
}

bool HTMLImportsController::shouldBlockScriptExecution(const Document& document) const
{
    ASSERT(document.importsController() == this);
    if (HTMLImportLoader* loader = loaderFor(document))
        return loader->shouldBlockScriptExecution();
    return root()->state().shouldBlockScriptExecution();
}

HTMLImportLoader* HTMLImportsController::createLoader()
{
    m_loaders.append(HTMLImportLoader::create(this));
    return m_loaders.last().get();
}

HTMLImportLoader* HTMLImportsController::loaderFor(const Document& document) const
{
    for (size_t i = 0; i < m_loaders.size(); ++i) {
        if (m_loaders[i]->document() == &document)
            return m_loaders[i].get();
    }

    return 0;
}

Document* HTMLImportsController::loaderDocumentAt(size_t i) const
{
    return loaderAt(i)->document();
}

} // namespace blink
