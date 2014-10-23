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

#include "core/dom/DocumentSupplementable.h"
#include "core/fetch/RawResource.h"
#include "core/html/LinkResource.h"
#include "core/html/imports/HTMLImport.h"
#include "platform/Supplementable.h"
#include "platform/Timer.h"
#include "wtf/FastAllocBase.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/Vector.h"

namespace blink {

class FetchRequest;
class ExecutionContext;
class ResourceFetcher;
class HTMLImportChild;
class HTMLImportChildClient;
class HTMLImportLoader;
class HTMLImportTreeRoot;

class HTMLImportsController FINAL : public NoBaseWillBeGarbageCollectedFinalized<HTMLImportsController>, public DocumentSupplement {
    WILL_BE_USING_GARBAGE_COLLECTED_MIXIN(HTMLImportsController);
    WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
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

    virtual void trace(Visitor*);

private:
    HTMLImportChild* createChild(const KURL&, HTMLImportLoader*, HTMLImport* parent, HTMLImportChildClient*);

    OwnPtrWillBeMember<HTMLImportTreeRoot> m_root;
    typedef WillBeHeapVector<OwnPtrWillBeMember<HTMLImportLoader> > LoaderList;
    LoaderList m_loaders;
};

} // namespace blink

#endif // HTMLImportsController_h
