/*
 * Copyright (C) 2005, 2008 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/editing/SplitElementCommand.h"

#include "bindings/core/v8/ExceptionState.h"
#include "bindings/core/v8/ExceptionStatePlaceholder.h"
#include "core/HTMLNames.h"
#include "core/dom/Element.h"
#include "wtf/Assertions.h"

namespace blink {

SplitElementCommand::SplitElementCommand(PassRefPtrWillBeRawPtr<Element> element, PassRefPtrWillBeRawPtr<Node> atChild)
    : SimpleEditCommand(element->document())
    , m_element2(element)
    , m_atChild(atChild)
{
    ASSERT(m_element2);
    ASSERT(m_atChild);
    ASSERT(m_atChild->parentNode() == m_element2);
}

void SplitElementCommand::executeApply()
{
    if (m_atChild->parentNode() != m_element2)
        return;

    WillBeHeapVector<RefPtrWillBeMember<Node> > children;
    for (Node* node = m_element2->firstChild(); node != m_atChild; node = node->nextSibling())
        children.append(node);

    TrackExceptionState exceptionState;

    ContainerNode* parent = m_element2->parentNode();
    if (!parent || !parent->hasEditableStyle())
        return;
    parent->insertBefore(m_element1.get(), m_element2.get(), exceptionState);
    if (exceptionState.hadException())
        return;

    // Delete id attribute from the second element because the same id cannot be used for more than one element
    m_element2->removeAttribute(HTMLNames::idAttr);

    size_t size = children.size();
    for (size_t i = 0; i < size; ++i)
        m_element1->appendChild(children[i], exceptionState);
}

void SplitElementCommand::doApply()
{
    m_element1 = m_element2->cloneElementWithoutChildren();

    executeApply();
}

void SplitElementCommand::doUnapply()
{
    if (!m_element1 || !m_element1->hasEditableStyle() || !m_element2->hasEditableStyle())
        return;

    NodeVector children;
    getChildNodes(*m_element1, children);

    RefPtrWillBeRawPtr<Node> refChild = m_element2->firstChild();

    size_t size = children.size();
    for (size_t i = 0; i < size; ++i)
        m_element2->insertBefore(children[i].get(), refChild.get(), IGNORE_EXCEPTION);

    // Recover the id attribute of the original element.
    const AtomicString& id = m_element1->getAttribute(HTMLNames::idAttr);
    if (!id.isNull())
        m_element2->setAttribute(HTMLNames::idAttr, id);

    m_element1->remove(IGNORE_EXCEPTION);
}

void SplitElementCommand::doReapply()
{
    if (!m_element1)
        return;

    executeApply();
}

void SplitElementCommand::trace(Visitor* visitor)
{
    visitor->trace(m_element1);
    visitor->trace(m_element2);
    visitor->trace(m_atChild);
    SimpleEditCommand::trace(visitor);
}

} // namespace blink
