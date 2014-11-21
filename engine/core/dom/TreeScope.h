/*
 * Copyright (C) 2011 Google Inc. All Rights Reserved.
 * Copyright (C) 2012 Apple Inc. All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef TreeScope_h
#define TreeScope_h

#include "sky/engine/core/dom/DocumentOrderedMap.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/text/AtomicString.h"

namespace blink {

class ContainerNode;
class DOMSelection;
class Document;
class Element;
class HitTestResult;
class ScopedStyleResolver;
class Node;

// A class which inherits both Node and TreeScope must call clearRareData() in its destructor
// so that the Node destructor no longer does problematic NodeList cache manipulation in
// the destructor.
class TreeScope {
public:
    TreeScope* parentTreeScope() const { return m_parentTreeScope; }

    TreeScope* olderShadowRootOrParentTreeScope() const;
    bool isInclusiveOlderSiblingShadowRootOrAncestorTreeScopeOf(const TreeScope&) const;

    Element* adjustedFocusedElement() const;
    Element* getElementById(const AtomicString&) const;
    void addElementById(const AtomicString& elementId, Element*);
    void removeElementById(const AtomicString& elementId, Element*);

    Document& document() const
    {
        ASSERT(m_document);
        return *m_document;
    }

    Node* ancestorInThisScope(Node*) const;

    Element* elementFromPoint(int x, int y) const;

    // For accessibility.
    bool shouldCacheLabelsByForAttribute() const { return m_labelsByForAttribute; }

    DOMSelection* getSelection() const;

    bool applyAuthorStyles() const;

    // Used by the basic DOM mutation methods (e.g., appendChild()).
    void adoptIfNeeded(Node&);

    ContainerNode& rootNode() const { return *m_rootNode; }


#if !ENABLE(OILPAN)
    // Nodes belonging to this scope hold guard references -
    // these are enough to keep the scope from being destroyed, but
    // not enough to keep it from removing its children. This allows a
    // node that outlives its scope to still have a valid document
    // pointer without introducing reference cycles.
    void guardRef()
    {
        ASSERT(!deletionHasBegun());
        ++m_guardRefCount;
    }

    void guardDeref()
    {
        ASSERT(m_guardRefCount > 0);
        ASSERT(!deletionHasBegun());
        --m_guardRefCount;
        if (!m_guardRefCount && !refCount() && !rootNodeHasTreeSharedParent()) {
            beginDeletion();
            delete this;
        }
    }
#endif

    void removedLastRefToScope();

    bool isInclusiveAncestorOf(const TreeScope&) const;
    unsigned short comparePosition(const TreeScope&) const;

    const TreeScope* commonAncestorTreeScope(const TreeScope& other) const;
    TreeScope* commonAncestorTreeScope(TreeScope& other);

    Element* getElementByAccessKey(const String& key) const;

    ScopedStyleResolver* scopedStyleResolver() const { return m_scopedStyleResolver.get(); }
    ScopedStyleResolver& ensureScopedStyleResolver();
    void clearScopedStyleResolver();

protected:
    TreeScope(ContainerNode&, Document&);
    explicit TreeScope(Document&);
    virtual ~TreeScope();

#if !ENABLE(OILPAN)
    void destroyTreeScopeData();
#endif

    void setDocument(Document& document) { m_document = &document; }
    void setParentTreeScope(TreeScope&);

#if !ENABLE(OILPAN)
    bool hasGuardRefCount() const { return m_guardRefCount; }
#endif

    void setNeedsStyleRecalcForViewportUnits();

private:
    virtual void dispose() { }

#if !ENABLE(OILPAN)
    int refCount() const;

#if ENABLE(SECURITY_ASSERT)
    bool deletionHasBegun();
    void beginDeletion();
#else
    bool deletionHasBegun() { return false; }
    void beginDeletion() { }
#endif
#endif

    bool rootNodeHasTreeSharedParent() const;

    RawPtr<ContainerNode> m_rootNode;
    RawPtr<Document> m_document;
    RawPtr<TreeScope> m_parentTreeScope;

#if !ENABLE(OILPAN)
    int m_guardRefCount;
#endif

    OwnPtr<DocumentOrderedMap> m_elementsById;
    OwnPtr<DocumentOrderedMap> m_imageMapsByName;
    OwnPtr<DocumentOrderedMap> m_labelsByForAttribute;

    OwnPtr<ScopedStyleResolver> m_scopedStyleResolver;

    mutable RefPtr<DOMSelection> m_selection;
};

DEFINE_COMPARISON_OPERATORS_WITH_REFERENCES(TreeScope)

HitTestResult hitTestInDocument(const Document*, int x, int y);
TreeScope* commonTreeScope(Node*, Node*);

} // namespace blink

#endif // TreeScope_h
