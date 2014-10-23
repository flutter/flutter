/*
 * Copyright (C) 2007 David Smith (catfish.man@gmail.com)
 * Copyright (C) 2007, 2008, 2011, 2012 Apple Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#include "config.h"
#include "core/dom/SpaceSplitString.h"

#include "core/html/parser/HTMLParserIdioms.h"
#include "wtf/ASCIICType.h"
#include "wtf/HashMap.h"
#include "wtf/text/AtomicStringHash.h"

using namespace WTF;

namespace blink {

template <typename CharacterType>
static inline bool hasNonASCIIOrUpper(const CharacterType* characters, unsigned length)
{
    bool hasUpper = false;
    CharacterType ored = 0;
    for (unsigned i = 0; i < length; i++) {
        CharacterType c = characters[i];
        hasUpper |= isASCIIUpper(c);
        ored |= c;
    }
    return hasUpper || (ored & ~0x7F);
}

static inline bool hasNonASCIIOrUpper(const String& string)
{
    unsigned length = string.length();

    if (string.is8Bit())
        return hasNonASCIIOrUpper(string.characters8(), length);
    return hasNonASCIIOrUpper(string.characters16(), length);
}

template <typename CharacterType>
inline void SpaceSplitString::Data::createVector(const CharacterType* characters, unsigned length)
{
    unsigned start = 0;
    while (true) {
        while (start < length && isHTMLSpace<CharacterType>(characters[start]))
            ++start;
        if (start >= length)
            break;
        unsigned end = start + 1;
        while (end < length && isNotHTMLSpace<CharacterType>(characters[end]))
            ++end;

        m_vector.append(AtomicString(characters + start, end - start));

        start = end + 1;
    }
}

void SpaceSplitString::Data::createVector(const String& string)
{
    unsigned length = string.length();

    if (string.is8Bit()) {
        createVector(string.characters8(), length);
        return;
    }

    createVector(string.characters16(), length);
}

bool SpaceSplitString::Data::containsAll(Data& other)
{
    if (this == &other)
        return true;

    size_t thisSize = m_vector.size();
    size_t otherSize = other.m_vector.size();
    for (size_t i = 0; i < otherSize; ++i) {
        const AtomicString& name = other.m_vector[i];
        size_t j;
        for (j = 0; j < thisSize; ++j) {
            if (m_vector[j] == name)
                break;
        }
        if (j == thisSize)
            return false;
    }
    return true;
}

void SpaceSplitString::Data::add(const AtomicString& string)
{
    ASSERT(hasOneRef());
    ASSERT(!contains(string));
    m_vector.append(string);
}

void SpaceSplitString::Data::remove(unsigned index)
{
    ASSERT(hasOneRef());
    m_vector.remove(index);
}

void SpaceSplitString::add(const AtomicString& string)
{
    // FIXME: add() does not allow duplicates but createVector() does.
    if (contains(string))
        return;
    ensureUnique();
    if (m_data)
        m_data->add(string);
}

bool SpaceSplitString::remove(const AtomicString& string)
{
    if (!m_data)
        return false;
    unsigned i = 0;
    bool changed = false;
    while (i < m_data->size()) {
        if ((*m_data)[i] == string) {
            if (!changed)
                ensureUnique();
            m_data->remove(i);
            changed = true;
            continue;
        }
        ++i;
    }
    return changed;
}

SpaceSplitString::DataMap& SpaceSplitString::sharedDataMap()
{
    DEFINE_STATIC_LOCAL(DataMap, map, ());
    return map;
}

void SpaceSplitString::set(const AtomicString& inputString, bool shouldFoldCase)
{
    if (inputString.isNull()) {
        clear();
        return;
    }

    String string(inputString.string());
    if (shouldFoldCase && hasNonASCIIOrUpper(string))
        string = string.foldCase();

    m_data = Data::create(AtomicString(string));
}

SpaceSplitString::Data::~Data()
{
    if (!m_keyString.isNull())
        sharedDataMap().remove(m_keyString);
}

PassRefPtr<SpaceSplitString::Data> SpaceSplitString::Data::create(const AtomicString& string)
{
    Data*& data = sharedDataMap().add(string, 0).storedValue->value;
    if (!data) {
        data = new Data(string);
        return adoptRef(data);
    }
    return data;
}

PassRefPtr<SpaceSplitString::Data> SpaceSplitString::Data::createUnique(const Data& other)
{
    return adoptRef(new SpaceSplitString::Data(other));
}

SpaceSplitString::Data::Data(const AtomicString& string)
    : m_keyString(string)
{
    ASSERT(!string.isNull());
    createVector(string);
}

SpaceSplitString::Data::Data(const SpaceSplitString::Data& other)
    : RefCounted<Data>()
    , m_vector(other.m_vector)
{
    // Note that we don't copy m_keyString to indicate to the destructor that there's nothing
    // to be removed from the sharedDataMap().
}

} // namespace blink
