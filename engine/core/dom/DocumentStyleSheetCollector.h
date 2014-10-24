/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
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

#ifndef DocumentStyleSheetCollector_h
#define DocumentStyleSheetCollector_h

#include "platform/heap/Handle.h"
#include "wtf/HashSet.h"
#include "wtf/RefPtr.h"
#include "wtf/Vector.h"

namespace blink {

class CSSStyleSheet;
class Document;
class StyleSheet;
class StyleSheetCollection;

class DocumentStyleSheetCollector {
    // This class contains references to two on-heap collections, therefore
    // it's unhealthy to have it anywhere but on the stack, where stack
    // scanning will keep them alive.
    STACK_ALLOCATED();
public:
    friend class ImportedDocumentStyleSheetCollector;

    DocumentStyleSheetCollector(WillBeHeapVector<RefPtrWillBeMember<StyleSheet> >& sheetsForList, WillBeHeapVector<RefPtrWillBeMember<CSSStyleSheet> >& activeList, WillBeHeapHashSet<RawPtrWillBeMember<Document> >&);
    ~DocumentStyleSheetCollector();

    void appendActiveStyleSheets(const WillBeHeapVector<RefPtrWillBeMember<CSSStyleSheet> >&);
    void appendActiveStyleSheet(CSSStyleSheet*);
    void appendSheetForList(StyleSheet*);

    bool hasVisited(Document* document) const { return m_visitedDocuments.contains(document); }
    void willVisit(Document* document) { m_visitedDocuments.add(document); }

private:
    WillBeHeapVector<RefPtrWillBeMember<StyleSheet> >& m_styleSheetsForStyleSheetList;
    WillBeHeapVector<RefPtrWillBeMember<CSSStyleSheet> >& m_activeAuthorStyleSheets;
    WillBeHeapHashSet<RawPtrWillBeMember<Document> >& m_visitedDocuments;
};

class ActiveDocumentStyleSheetCollector final : public DocumentStyleSheetCollector {
public:
    ActiveDocumentStyleSheetCollector(StyleSheetCollection&);
private:
    WillBeHeapHashSet<RawPtrWillBeMember<Document> > m_visitedDocuments;
};

class ImportedDocumentStyleSheetCollector final : public DocumentStyleSheetCollector {
public:
    ImportedDocumentStyleSheetCollector(DocumentStyleSheetCollector&, WillBeHeapVector<RefPtrWillBeMember<StyleSheet> >&);
};

} // namespace blink

#endif // DocumentStyleSheetCollector_h
