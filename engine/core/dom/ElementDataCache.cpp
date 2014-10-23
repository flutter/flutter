/*
 * Copyright (C) 2012, 2013 Apple Inc. All Rights Reserved.
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
 *
 */

#include "config.h"
#include "core/dom/ElementDataCache.h"

#include "core/dom/ElementData.h"

namespace blink {

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(ElementDataCache)

inline unsigned attributeHash(const Vector<Attribute>& attributes)
{
    return StringHasher::hashMemory(attributes.data(), attributes.size() * sizeof(Attribute));
}

inline bool hasSameAttributes(const Vector<Attribute>& attributes, ShareableElementData& elementData)
{
    if (attributes.size() != elementData.attributes().size())
        return false;
    return !memcmp(attributes.data(), elementData.m_attributeArray, attributes.size() * sizeof(Attribute));
}

PassRefPtrWillBeRawPtr<ShareableElementData> ElementDataCache::cachedShareableElementDataWithAttributes(const Vector<Attribute>& attributes)
{
    ASSERT(!attributes.isEmpty());

    ShareableElementDataCache::ValueType* it = m_shareableElementDataCache.add(attributeHash(attributes), nullptr).storedValue;

    // FIXME: This prevents sharing when there's a hash collision.
    if (it->value && !hasSameAttributes(attributes, *it->value))
        return ShareableElementData::createWithAttributes(attributes);

    if (!it->value)
        it->value = ShareableElementData::createWithAttributes(attributes);

    return it->value.get();
}

ElementDataCache::ElementDataCache()
{
}

void ElementDataCache::trace(Visitor* visitor)
{
#if ENABLE(OILPAN)
    visitor->trace(m_shareableElementDataCache);
#endif
}

}
