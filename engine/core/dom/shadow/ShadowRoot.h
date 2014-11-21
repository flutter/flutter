/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
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

#ifndef ShadowRoot_h
#define ShadowRoot_h

#include "sky/engine/core/dom/ContainerNode.h"
#include "sky/engine/core/dom/DocumentFragment.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/TreeScope.h"
#include "sky/engine/wtf/DoublyLinkedList.h"

namespace blink {

class Document;
class ElementShadow;
class ExceptionState;
class InsertionPoint;
class ShadowRootRareData;
class StyleSheetList;

class ShadowRoot final : public DocumentFragment, public TreeScope, public DoublyLinkedListNode<ShadowRoot> {
    DEFINE_WRAPPERTYPEINFO();
    friend class WTF::DoublyLinkedListNode<ShadowRoot>;
public:

    static PassRefPtr<ShadowRoot> create(Document& document)
    {
        return adoptRef(new ShadowRoot(document));
    }

    void recalcStyle(StyleRecalcChange);

    // Disambiguate between Node and TreeScope hierarchies; TreeScope's implementation is simpler.
    using TreeScope::document;
    using TreeScope::getElementById;

    Element* host() const { return toElement(parentOrShadowHostNode()); }
    ElementShadow* owner() const { return host() ? host()->shadow() : 0; }

    ShadowRoot* youngerShadowRoot() const { return prev(); }

    bool isYoungest() const { return !youngerShadowRoot(); }
    bool isOldest() const { return !olderShadowRoot(); }
    bool isOldestAuthorShadowRoot() const;

    virtual InsertionNotificationRequest insertedInto(ContainerNode*) override;
    virtual void removedFrom(ContainerNode*) override;

    void registerScopedHTMLStyleChild();
    void unregisterScopedHTMLStyleChild();

    bool containsContentElements() const;
    bool containsInsertionPoints() const { return containsContentElements(); }
    bool containsShadowRoots() const;

    // For Internals, don't use this.
    unsigned childShadowRootCount() const;
    unsigned numberOfStyles() const { return m_numberOfStyles; }

    void didAddInsertionPoint(InsertionPoint*);
    void didRemoveInsertionPoint(InsertionPoint*);
    const Vector<RefPtr<InsertionPoint> >& descendantInsertionPoints();

    // Make protected methods from base class public here.
    using TreeScope::setDocument;
    using TreeScope::setParentTreeScope;

public:
    Element* activeElement() const;

    ShadowRoot* olderShadowRoot() const { return next(); }

    PassRefPtr<Node> cloneNode(bool, ExceptionState&);
    PassRefPtr<Node> cloneNode(ExceptionState& exceptionState) { return cloneNode(true, exceptionState); }

    StyleSheetList* styleSheets();

private:
    ShadowRoot(Document&);
    virtual ~ShadowRoot();

#if !ENABLE(OILPAN)
    virtual void dispose() override;
#endif

    ShadowRootRareData* ensureShadowRootRareData();

    void addChildShadowRoot();
    void removeChildShadowRoot();
    void invalidateDescendantInsertionPoints();

    // ShadowRoots should never be cloned.
    virtual PassRefPtr<Node> cloneNode(bool) override { return nullptr; }

    // FIXME: This shouldn't happen. https://bugs.webkit.org/show_bug.cgi?id=88834
    bool isOrphan() const { return !host(); }

    RawPtr<ShadowRoot> m_prev;
    RawPtr<ShadowRoot> m_next;
    OwnPtr<ShadowRootRareData> m_shadowRootRareData;
    unsigned m_numberOfStyles : 27;
    unsigned m_registeredWithParentShadowRoot : 1;
    unsigned m_descendantInsertionPointsIsValid : 1;
};

inline Element* ShadowRoot::activeElement() const
{
    return adjustedFocusedElement();
}

DEFINE_NODE_TYPE_CASTS(ShadowRoot, isShadowRoot());
DEFINE_TYPE_CASTS(ShadowRoot, TreeScope, treeScope, treeScope->rootNode().isShadowRoot(), treeScope.rootNode().isShadowRoot());

} // namespace blink

#endif // ShadowRoot_h
