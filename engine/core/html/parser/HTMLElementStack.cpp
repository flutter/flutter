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

#include "sky/engine/config.h"
#include "sky/engine/core/html/parser/HTMLElementStack.h"

#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/html/HTMLElement.h"

namespace blink {

HTMLElementStack::ElementRecord::ElementRecord(PassRefPtr<ContainerNode> node, PassOwnPtr<ElementRecord> next)
    : m_node(node)
    , m_next(next)
{
    ASSERT(m_node);
}

HTMLElementStack::ElementRecord::~ElementRecord()
{
}

HTMLElementStack::HTMLElementStack()
    : m_rootNode(nullptr)
    , m_stackDepth(0)
{
}

HTMLElementStack::~HTMLElementStack()
{
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

void HTMLElementStack::pushRootNode(PassRefPtr<ContainerNode> root)
{
    ASSERT(!m_top);
    ASSERT(!m_rootNode);
    m_rootNode = root.get();
    pushCommon(root);
}

void HTMLElementStack::push(PassRefPtr<ContainerNode> node)
{
    ASSERT(m_rootNode);
    pushCommon(node);
}

HTMLElementStack::ElementRecord* HTMLElementStack::topRecord() const
{
    ASSERT(m_top);
    return m_top.get();
}

void HTMLElementStack::pushCommon(PassRefPtr<ContainerNode> node)
{
    ASSERT(m_rootNode);

    m_stackDepth++;
    m_top = adoptPtr(new ElementRecord(node, m_top.release()));
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

#ifndef NDEBUG

void HTMLElementStack::show()
{
    for (ElementRecord* record = m_top.get(); record; record = record->next())
        record->element()->showNode();
}

#endif

}
