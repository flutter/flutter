/*
 * Copyright (C) 2010 Google, Inc. All Rights Reserved.
 * Copyright (C) 2011 Apple Inc. All rights reserved.
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

#ifndef HTMLElementStack_h
#define HTMLElementStack_h

#include "core/dom/Element.h"
#include "wtf/Forward.h"
#include "wtf/Noncopyable.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/RefPtr.h"

namespace blink {

class ContainerNode;
class DocumentFragment;
class Element;
class QualifiedName;

// NOTE: The HTML5 spec uses a backwards (grows downward) stack.  We're using
// more standard (grows upwards) stack terminology here.
class HTMLElementStack {
    WTF_MAKE_NONCOPYABLE(HTMLElementStack);
    DISALLOW_ALLOCATION();
public:
    HTMLElementStack();
    ~HTMLElementStack();

    class ElementRecord {
        WTF_MAKE_NONCOPYABLE(ElementRecord); WTF_MAKE_FAST_ALLOCATED;
    public:
        ElementRecord(PassRefPtr<ContainerNode>, PassOwnPtr<ElementRecord>);
        ~ElementRecord();

        Element* element() const { return toElement(m_node.get()); }
        ContainerNode* node() const { return m_node.get(); }

        ElementRecord* next() const { return m_next.get(); }

        PassOwnPtr<ElementRecord> releaseNext() { return m_next.release(); }
        void setNext(PassOwnPtr<ElementRecord> next) { m_next = next; }

    private:
        RefPtr<ContainerNode> m_node;
        OwnPtr<ElementRecord> m_next;
    };

    unsigned stackDepth() const { return m_stackDepth; }

    // Inlining this function is a (small) performance win on the parsing
    // benchmark.
    Element* top() const
    {
        ASSERT(m_top->element());
        return m_top->element();
    }

    ContainerNode* topNode() const
    {
        ASSERT(m_top->node());
        return m_top->node();
    }

    ElementRecord* topRecord() const;

    void push(PassRefPtr<ContainerNode>);
    void pushRootNode(PassRefPtr<ContainerNode>);

    void pop();
    void popUntilPopped(Element*);
    void popAll();

#ifndef NDEBUG
    void show();
#endif

private:
    void popUntil(Element*);
    void pushCommon(PassRefPtr<ContainerNode>);
    void popCommon();
    void removeNonTopCommon(Element*);

    OwnPtr<ElementRecord> m_top;

    ContainerNode* m_rootNode;
    unsigned m_stackDepth;
};

} // namespace blink

#endif // HTMLElementStack_h
