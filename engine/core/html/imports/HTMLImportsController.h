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

#ifndef HTMLImportsController_h
#define HTMLImportsController_h

#include "sky/engine/core/dom/DocumentSupplementable.h"
#include "sky/engine/core/fetch/RawResource.h"
#include "sky/engine/core/html/imports/HTMLImport.h"
#include "sky/engine/platform/Supplementable.h"
#include "sky/engine/platform/Timer.h"
#include "sky/engine/wtf/FastAllocBase.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

class FetchRequest;
class ExecutionContext;
class ResourceFetcher;
class HTMLImportChild;
class HTMLImportChildClient;
class HTMLImportLoader;
class HTMLImportTreeRoot;

class HTMLImportsController final : public DocumentSupplement {
    WTF_MAKE_FAST_ALLOCATED;
public:
    static const char* supplementName();
    static void provideTo(Document&);
    static void removeFrom(Document&);

    explicit HTMLImportsController(Document&);
    virtual ~HTMLImportsController();

    HTMLImportTreeRoot* root() const { return m_root.get(); }

    bool shouldBlockScriptExecution(const Document&) const;
    HTMLImportChild* load(HTMLImport* parent, HTMLImportChildClient*, FetchRequest);

    Document* master() const;

    HTMLImportLoader* createLoader();

    size_t loaderCount() const { return m_loaders.size(); }
    HTMLImportLoader* loaderAt(size_t i) const { return m_loaders[i].get(); }
    Document* loaderDocumentAt(size_t) const;
    HTMLImportLoader* loaderFor(const Document&) const;

private:
    HTMLImportChild* createChild(const KURL&, HTMLImportLoader*, HTMLImport* parent, HTMLImportChildClient*);

    OwnPtr<HTMLImportTreeRoot> m_root;
    typedef Vector<OwnPtr<HTMLImportLoader> > LoaderList;
    LoaderList m_loaders;
};

} // namespace blink

#endif // HTMLImportsController_h
