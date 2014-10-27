/*
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
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
#include "core/dom/DocumentOrderedMap.h"

#include "core/dom/Element.h"
#include "core/dom/ElementTraversal.h"
#include "core/dom/TreeScope.h"

namespace blink {

inline bool keyMatchesId(const AtomicString& key, const Element& element)
{
    return element.getIdAttribute() == key;
}

inline bool keyMatchesMapName(const AtomicString& key, const Element& element)
{
    return false;
}

inline bool keyMatchesLowercasedMapName(const AtomicString& key, const Element& element)
{
    return false;
}

inline bool keyMatchesLabelForAttribute(const AtomicString& key, const Element& element)
{
    return false;
}

PassOwnPtr<DocumentOrderedMap> DocumentOrderedMap::create()
{
    return adoptPtr(new DocumentOrderedMap());
}

void DocumentOrderedMap::add(const AtomicString& key, Element* element)
{
    ASSERT(key);
    ASSERT(element);

    Map::AddResult addResult = m_map.add(key, adoptPtr(new MapEntry(element)));
    if (addResult.isNewEntry)
        return;

    OwnPtr<MapEntry>& entry = addResult.storedValue->value;
    ASSERT(entry->count);
    entry->element = nullptr;
    entry->count++;
    entry->orderedList.clear();
}

void DocumentOrderedMap::remove(const AtomicString& key, Element* element)
{
    ASSERT(key);
    ASSERT(element);

    Map::iterator it = m_map.find(key);
    if (it == m_map.end())
        return;

    OwnPtr<MapEntry>& entry = it->value;
    ASSERT(entry->count);
    if (entry->count == 1) {
        ASSERT(!entry->element || entry->element == element);
        m_map.remove(it);
    } else {
        if (entry->element == element) {
            ASSERT(entry->orderedList.isEmpty() || entry->orderedList.first() == element);
            entry->element = entry->orderedList.size() > 1 ? entry->orderedList[1] : nullptr;
        }
        entry->count--;
        entry->orderedList.clear();
    }
}

template<bool keyMatches(const AtomicString&, const Element&)>
inline Element* DocumentOrderedMap::get(const AtomicString& key, const TreeScope* scope) const
{
    ASSERT(key);
    ASSERT(scope);

    MapEntry* entry = m_map.get(key);
    if (!entry)
        return 0;

    ASSERT(entry->count);
    if (entry->element)
        return entry->element;

    // We know there's at least one node that matches; iterate to find the first one.
    for (Element* element = ElementTraversal::firstWithin(scope->rootNode()); element; element = ElementTraversal::next(*element)) {
        if (!keyMatches(key, *element))
            continue;
        entry->element = element;
        return element;
    }
    ASSERT_NOT_REACHED();
    return 0;
}

Element* DocumentOrderedMap::getElementById(const AtomicString& key, const TreeScope* scope) const
{
    return get<keyMatchesId>(key, scope);
}

const Vector<RawPtr<Element> >& DocumentOrderedMap::getAllElementsById(const AtomicString& key, const TreeScope* scope) const
{
    ASSERT(key);
    ASSERT(scope);
    DEFINE_STATIC_LOCAL(OwnPtr<Vector<RawPtr<Element> > >, emptyVector, (adoptPtr(new Vector<RawPtr<Element> >())));

    Map::iterator it = m_map.find(key);
    if (it == m_map.end())
        return *emptyVector;

    OwnPtr<MapEntry>& entry = it->value;
    ASSERT(entry->count);

    if (entry->orderedList.isEmpty()) {
        entry->orderedList.reserveCapacity(entry->count);
        for (Element* element = entry->element ? entry->element.get() : ElementTraversal::firstWithin(scope->rootNode()); entry->orderedList.size() < entry->count; element = ElementTraversal::next(*element)) {
            ASSERT(element);
            if (!keyMatchesId(key, *element))
                continue;
            entry->orderedList.uncheckedAppend(element);
        }
        if (!entry->element)
            entry->element = entry->orderedList.first();
    }

    return entry->orderedList;
}

Element* DocumentOrderedMap::getElementByMapName(const AtomicString& key, const TreeScope* scope) const
{
    return get<keyMatchesMapName>(key, scope);
}

Element* DocumentOrderedMap::getElementByLowercasedMapName(const AtomicString& key, const TreeScope* scope) const
{
    return get<keyMatchesLowercasedMapName>(key, scope);
}

Element* DocumentOrderedMap::getElementByLabelForAttribute(const AtomicString& key, const TreeScope* scope) const
{
    return get<keyMatchesLabelForAttribute>(key, scope);
}

void DocumentOrderedMap::trace(Visitor* visitor)
{
#if ENABLE(OILPAN)
    visitor->trace(m_map);
#endif
}

void DocumentOrderedMap::MapEntry::trace(Visitor* visitor)
{
    visitor->trace(element);
#if ENABLE(OILPAN)
    visitor->trace(orderedList);
#endif
}

} // namespace blink
