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

#include "core/html/parser/HTMLStackItem.h"
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

    class ElementRecord FINAL : public NoBaseWillBeGarbageCollected<ElementRecord> {
        WTF_MAKE_NONCOPYABLE(ElementRecord); WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
    public:
#if !ENABLE(OILPAN)
        ~ElementRecord(); // Public for ~PassOwnPtr()
#endif

        Element* element() const { return m_item->element(); }
        ContainerNode* node() const { return m_item->node(); }
        PassRefPtrWillBeRawPtr<HTMLStackItem> stackItem() const { return m_item; }

        ElementRecord* next() const { return m_next.get(); }

        void trace(Visitor*);
    private:
        friend class HTMLElementStack;

        ElementRecord(PassRefPtrWillBeRawPtr<HTMLStackItem>, PassOwnPtrWillBeRawPtr<ElementRecord>);

        PassOwnPtrWillBeRawPtr<ElementRecord> releaseNext() { return m_next.release(); }
        void setNext(PassOwnPtrWillBeRawPtr<ElementRecord> next) { m_next = next; }

        RefPtrWillBeMember<HTMLStackItem> m_item;
        OwnPtrWillBeMember<ElementRecord> m_next;
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

    HTMLStackItem* topStackItem() const
    {
        ASSERT(m_top->stackItem());
        return m_top->stackItem().get();
    }

    HTMLStackItem* oneBelowTop() const;
    ElementRecord* topRecord() const;
    ElementRecord* find(Element*) const;
    ElementRecord* topmost(const AtomicString& tagName) const;

    void insertAbove(PassRefPtrWillBeRawPtr<HTMLStackItem>, ElementRecord*);

    void push(PassRefPtrWillBeRawPtr<HTMLStackItem>);
    void pushRootNode(PassRefPtrWillBeRawPtr<HTMLStackItem>);

    void pop();
    void popUntil(const AtomicString& tagName);
    void popUntil(Element*);
    void popUntilPopped(Element*);
    void popAll();

    void remove(Element*);

    bool contains(Element*) const;
    bool contains(const AtomicString& tagName) const;

    bool inScope(Element*) const;

    bool hasOnlyOneElement() const;

    ContainerNode* rootNode() const;

    void trace(Visitor*);

#ifndef NDEBUG
    void show();
#endif

private:
    void pushCommon(PassRefPtrWillBeRawPtr<HTMLStackItem>);
    void popCommon();
    void removeNonTopCommon(Element*);

    OwnPtrWillBeMember<ElementRecord> m_top;

    // We remember the root node, <head> and <body> as they are pushed. Their
    // ElementRecords keep them alive. The root node is never popped.
    // FIXME: We don't currently require type-specific information about
    // these elements so we haven't yet bothered to plumb the types all the
    // way down through createElement, etc.
    RawPtrWillBeMember<ContainerNode> m_rootNode;
    unsigned m_stackDepth;
};

} // namespace blink

#endif // HTMLElementStack_h
