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

#include "config.h"
#include "core/html/parser/HTMLElementStack.h"

#include "core/dom/Element.h"
#include "core/html/HTMLElement.h"

namespace blink {

HTMLElementStack::ElementRecord::ElementRecord(PassRefPtrWillBeRawPtr<HTMLStackItem> item, PassOwnPtrWillBeRawPtr<ElementRecord> next)
    : m_item(item)
    , m_next(next)
{
    ASSERT(m_item);
}

#if !ENABLE(OILPAN)
HTMLElementStack::ElementRecord::~ElementRecord()
{
}
#endif

void HTMLElementStack::ElementRecord::trace(Visitor* visitor)
{
#if ENABLE(OILPAN)
    visitor->trace(m_item);
    visitor->trace(m_next);
#endif
}

HTMLElementStack::HTMLElementStack()
    : m_rootNode(nullptr)
    , m_stackDepth(0)
{
}

HTMLElementStack::~HTMLElementStack()
{
}

bool HTMLElementStack::hasOnlyOneElement() const
{
    return !topRecord()->next();
}

void HTMLElementStack::popAll()
{
    m_rootNode = nullptr;
    m_stackDepth = 0;
    while (m_top) {
        Node& node = *topNode();
        if (node.isElementNode())
            toElement(node).finishParsingChildren();
        m_top = m_top->releaseNext();
    }
}

void HTMLElementStack::pop()
{
    popCommon();
}

void HTMLElementStack::popUntil(const AtomicString& tagName)
{
    while (!topStackItem()->hasLocalName(tagName)) {
        // pop() will ASSERT if a <body>, <head> or <html> will be popped.
        pop();
    }
}

void HTMLElementStack::popUntil(Element* element)
{
    while (top() != element)
        pop();
}

void HTMLElementStack::popUntilPopped(Element* element)
{
    popUntil(element);
    pop();
}

void HTMLElementStack::pushRootNode(PassRefPtrWillBeRawPtr<HTMLStackItem> rootItem)
{
    ASSERT(!m_top);
    ASSERT(!m_rootNode);
    m_rootNode = rootItem->node();
    pushCommon(rootItem);
}

void HTMLElementStack::push(PassRefPtrWillBeRawPtr<HTMLStackItem> item)
{
    ASSERT(m_rootNode);
    pushCommon(item);
}

void HTMLElementStack::insertAbove(PassRefPtrWillBeRawPtr<HTMLStackItem> item, ElementRecord* recordBelow)
{
    ASSERT(item);
    ASSERT(recordBelow);
    ASSERT(m_top);
    ASSERT(m_rootNode);
    if (recordBelow == m_top) {
        push(item);
        return;
    }

    for (ElementRecord* recordAbove = m_top.get(); recordAbove; recordAbove = recordAbove->next()) {
        if (recordAbove->next() != recordBelow)
            continue;

        m_stackDepth++;
        recordAbove->setNext(adoptPtrWillBeNoop(new ElementRecord(item, recordAbove->releaseNext())));
        recordAbove->next()->element()->beginParsingChildren();
        return;
    }
    ASSERT_NOT_REACHED();
}

HTMLElementStack::ElementRecord* HTMLElementStack::topRecord() const
{
    ASSERT(m_top);
    return m_top.get();
}

HTMLStackItem* HTMLElementStack::oneBelowTop() const
{
    // We should never call this if there are fewer than 2 elements on the stack.
    ASSERT(m_top);
    ASSERT(m_top->next());
    if (m_top->next()->stackItem()->isElementNode())
        return m_top->next()->stackItem().get();
    return 0;
}

void HTMLElementStack::remove(Element* element)
{
    if (m_top->element() == element) {
        pop();
        return;
    }
    removeNonTopCommon(element);
}

HTMLElementStack::ElementRecord* HTMLElementStack::find(Element* element) const
{
    for (ElementRecord* pos = m_top.get(); pos; pos = pos->next()) {
        if (pos->node() == element)
            return pos;
    }
    return 0;
}

HTMLElementStack::ElementRecord* HTMLElementStack::topmost(const AtomicString& tagName) const
{
    for (ElementRecord* pos = m_top.get(); pos; pos = pos->next()) {
        if (pos->stackItem()->hasLocalName(tagName))
            return pos;
    }
    return 0;
}

bool HTMLElementStack::contains(Element* element) const
{
    return !!find(element);
}

bool HTMLElementStack::contains(const AtomicString& tagName) const
{
    return !!topmost(tagName);
}

template <bool isMarker(HTMLStackItem*)>
bool inScopeCommon(HTMLElementStack::ElementRecord* top, const AtomicString& targetTag)
{
    for (HTMLElementStack::ElementRecord* pos = top; pos; pos = pos->next()) {
        HTMLStackItem* item = pos->stackItem().get();
        if (item->hasLocalName(targetTag))
            return true;
        if (isMarker(item))
            return false;
    }
    ASSERT_NOT_REACHED(); // <html> is always on the stack and is a scope marker.
    return false;
}

bool HTMLElementStack::inScope(Element* targetElement) const
{
    for (ElementRecord* pos = m_top.get(); pos; pos = pos->next()) {
        HTMLStackItem* item = pos->stackItem().get();
        if (item->node() == targetElement)
            return true;
    }
    ASSERT_NOT_REACHED(); // <html> is always on the stack and is a scope marker.
    return false;
}

ContainerNode* HTMLElementStack::rootNode() const
{
    ASSERT(m_rootNode);
    return m_rootNode;
}

void HTMLElementStack::pushCommon(PassRefPtrWillBeRawPtr<HTMLStackItem> item)
{
    ASSERT(m_rootNode);

    m_stackDepth++;
    m_top = adoptPtrWillBeNoop(new ElementRecord(item, m_top.release()));
}

void HTMLElementStack::popCommon()
{
    top()->finishParsingChildren();
    m_top = m_top->releaseNext();
    m_stackDepth--;
}

void HTMLElementStack::removeNonTopCommon(Element* element)
{
    ASSERT(top() != element);
    for (ElementRecord* pos = m_top.get(); pos; pos = pos->next()) {
        if (pos->next()->element() == element) {
            // FIXME: Is it OK to call finishParsingChildren()
            // when the children aren't actually finished?
            element->finishParsingChildren();
            pos->setNext(pos->next()->releaseNext());
            m_stackDepth--;
            return;
        }
    }
    ASSERT_NOT_REACHED();
}

void HTMLElementStack::trace(Visitor* visitor)
{
    visitor->trace(m_top);
    visitor->trace(m_rootNode);
}

#ifndef NDEBUG

void HTMLElementStack::show()
{
    for (ElementRecord* record = m_top.get(); record; record = record->next())
        record->element()->showNode();
}

#endif

}
