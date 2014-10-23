/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
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
#include "core/dom/custom/CustomElementUpgradeCandidateMap.h"

#include "core/dom/Element.h"

namespace blink {

PassOwnPtrWillBeRawPtr<CustomElementUpgradeCandidateMap> CustomElementUpgradeCandidateMap::create()
{
    return adoptPtrWillBeNoop(new CustomElementUpgradeCandidateMap());
}

CustomElementUpgradeCandidateMap::~CustomElementUpgradeCandidateMap()
{
#if !ENABLE(OILPAN)
    // With Oilpan enabled, the observer table keeps a weak reference to the
    // element; no need for explicit removal.
    UpgradeCandidateMap::const_iterator::Keys end = m_upgradeCandidates.end().keys();
    for (UpgradeCandidateMap::const_iterator::Keys it = m_upgradeCandidates.begin().keys(); it != end; ++it)
        unobserve(*it);
#endif
}

void CustomElementUpgradeCandidateMap::add(const CustomElementDescriptor& descriptor, Element* element)
{
    observe(element);

    UpgradeCandidateMap::AddResult result = m_upgradeCandidates.add(element, descriptor);
    ASSERT_UNUSED(result, result.isNewEntry);

    UnresolvedDefinitionMap::iterator it = m_unresolvedDefinitions.find(descriptor);
    ElementSet* elements;
    if (it == m_unresolvedDefinitions.end())
        elements = m_unresolvedDefinitions.add(descriptor, adoptPtrWillBeNoop(new ElementSet())).storedValue->value.get();
    else
        elements = it->value.get();
    elements->add(element);
}

void CustomElementUpgradeCandidateMap::elementWasDestroyed(Element* element)
{
    CustomElementObserver::elementWasDestroyed(element);
    UpgradeCandidateMap::iterator candidate = m_upgradeCandidates.find(element);
    ASSERT_WITH_SECURITY_IMPLICATION(candidate != m_upgradeCandidates.end());

    UnresolvedDefinitionMap::iterator elements = m_unresolvedDefinitions.find(candidate->value);
    ASSERT_WITH_SECURITY_IMPLICATION(elements != m_unresolvedDefinitions.end());
    elements->value->remove(element);
    m_upgradeCandidates.remove(candidate);
}

void CustomElementUpgradeCandidateMap::elementDidFinishParsingChildren(Element* element)
{
    // An upgrade candidate finished parsing; reorder so that eventual
    // upgrade order matches finished-parsing order.
    moveToEnd(element);
}

void CustomElementUpgradeCandidateMap::moveToEnd(Element* element)
{
    UpgradeCandidateMap::iterator candidate = m_upgradeCandidates.find(element);
    ASSERT_WITH_SECURITY_IMPLICATION(candidate != m_upgradeCandidates.end());

    UnresolvedDefinitionMap::iterator elements = m_unresolvedDefinitions.find(candidate->value);
    ASSERT_WITH_SECURITY_IMPLICATION(elements != m_unresolvedDefinitions.end());
    elements->value->appendOrMoveToLast(element);
}

PassOwnPtrWillBeRawPtr<CustomElementUpgradeCandidateMap::ElementSet> CustomElementUpgradeCandidateMap::takeUpgradeCandidatesFor(const CustomElementDescriptor& descriptor)
{
    OwnPtrWillBeRawPtr<ElementSet> candidates = m_unresolvedDefinitions.take(descriptor);

    if (!candidates)
        return nullptr;

    for (ElementSet::const_iterator candidate = candidates->begin(); candidate != candidates->end(); ++candidate) {
        unobserve(*candidate);
        m_upgradeCandidates.remove(*candidate);
    }
    return candidates.release();
}

void CustomElementUpgradeCandidateMap::trace(Visitor* visitor)
{
#if ENABLE(OILPAN)
    visitor->trace(m_upgradeCandidates);
    visitor->trace(m_unresolvedDefinitions);
#endif
    CustomElementObserver::trace(visitor);
}

}
