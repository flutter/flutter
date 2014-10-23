/*
 * Copyright (C) 2012 Company 100, Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY GOOGLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL GOOGLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef HTMLStackItem_h
#define HTMLStackItem_h

#include "core/HTMLNames.h"
#include "core/dom/Element.h"
#include "core/html/parser/AtomicHTMLToken.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "wtf/RefCounted.h"
#include "wtf/RefPtr.h"
#include "wtf/text/AtomicString.h"

namespace blink {

class ContainerNode;

class HTMLStackItem : public RefCountedWillBeGarbageCollectedFinalized<HTMLStackItem> {
public:
    enum ItemType {
        ItemForContextElement,
        ItemForDocumentFragmentNode
    };

    // Used by document fragment node and context element.
    static PassRefPtrWillBeRawPtr<HTMLStackItem> create(PassRefPtrWillBeRawPtr<ContainerNode> node, ItemType type)
    {
        return adoptRefWillBeNoop(new HTMLStackItem(node, type));
    }

    // Used by HTMLElementStack.
    static PassRefPtrWillBeRawPtr<HTMLStackItem> create(PassRefPtrWillBeRawPtr<ContainerNode> node, AtomicHTMLToken* token)
    {
        return adoptRefWillBeNoop(new HTMLStackItem(node, token));
    }

    Element* element() const { return toElement(m_node.get()); }
    ContainerNode* node() const { return m_node.get(); }

    bool isDocumentFragmentNode() const { return m_isDocumentFragmentNode; }
    bool isElementNode() const { return !m_isDocumentFragmentNode; }

    const AtomicString& localName() const { return m_tokenLocalName; }

    bool hasLocalName(const AtomicString& name) const { return m_tokenLocalName == name; }

    void trace(Visitor* visitor) { visitor->trace(m_node); }

private:
    HTMLStackItem(PassRefPtrWillBeRawPtr<ContainerNode> node, ItemType type)
        : m_node(node)
    {
        switch (type) {
        case ItemForDocumentFragmentNode:
            m_isDocumentFragmentNode = true;
            break;
        case ItemForContextElement:
            m_tokenLocalName = m_node->localName();
            m_isDocumentFragmentNode = false;
            break;
        }
    }

    HTMLStackItem(PassRefPtrWillBeRawPtr<ContainerNode> node, AtomicHTMLToken* token)
        : m_node(node)
        , m_tokenLocalName(token->name())
        , m_isDocumentFragmentNode(false)
    {
    }

    RefPtrWillBeMember<ContainerNode> m_node;

    AtomicString m_tokenLocalName;
    bool m_isDocumentFragmentNode;
};

} // namespace blink

#endif // HTMLStackItem_h
