/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#include "config.h"
#include "core/dom/UserActionElementSet.h"

#include "core/dom/Element.h"
#include "core/dom/Node.h"

namespace blink {

UserActionElementSet::UserActionElementSet()
{
}

UserActionElementSet::~UserActionElementSet()
{
}

void UserActionElementSet::didDetach(Node* node)
{
    ASSERT(node->isUserActionElement());
    clearFlags(toElement(node), IsActiveFlag | InActiveChainFlag | IsHoveredFlag);
}

#if !ENABLE(OILPAN)
void UserActionElementSet::documentDidRemoveLastRef()
{
    m_elements.clear();
}
#endif

bool UserActionElementSet::hasFlags(const Node* node, unsigned flags) const
{
    ASSERT(node->isUserActionElement() && node->isElementNode());
    return hasFlags(toElement(node), flags);
}

void UserActionElementSet::setFlags(Node* node, unsigned flags)
{
    if (!node->isElementNode())
        return;
    return setFlags(toElement(node), flags);
}

void UserActionElementSet::clearFlags(Node* node, unsigned flags)
{
    if (!node->isElementNode())
        return;
    return clearFlags(toElement(node), flags);
}

inline bool UserActionElementSet::hasFlags(const Element* element, unsigned flags) const
{
    ASSERT(element->isUserActionElement());
    ElementFlagMap::const_iterator found = m_elements.find(const_cast<Element*>(element));
    if (found == m_elements.end())
        return false;
    return found->value & flags;
}

inline void UserActionElementSet::clearFlags(Element* element, unsigned flags)
{
    if (!element->isUserActionElement()) {
        ASSERT(m_elements.end() == m_elements.find(element));
        return;
    }

    ElementFlagMap::iterator found = m_elements.find(element);
    if (found == m_elements.end()) {
        element->setUserActionElement(false);
        return;
    }

    unsigned updated = found->value & ~flags;
    if (!updated) {
        element->setUserActionElement(false);
        m_elements.remove(found);
        return;
    }

    found->value = updated;
}

inline void UserActionElementSet::setFlags(Element* element, unsigned flags)
{
    ElementFlagMap::iterator result = m_elements.find(element);
    if (result != m_elements.end()) {
        ASSERT(element->isUserActionElement());
        result->value |= flags;
        return;
    }

    element->setUserActionElement(true);
    m_elements.add(element, flags);
}

void UserActionElementSet::trace(Visitor* visitor)
{
#if ENABLE(OILPAN)
    visitor->trace(m_elements);
#endif
}

}
