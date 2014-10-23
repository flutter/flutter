/*
 * Copyright (C) 2012 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef WidthCache_h
#define WidthCache_h

#include "platform/geometry/IntRectExtent.h"
#include "platform/text/TextRun.h"
#include "wtf/Forward.h"
#include "wtf/HashFunctions.h"
#include "wtf/HashSet.h"
#include "wtf/HashTableDeletedValueType.h"
#include "wtf/StringHasher.h"

namespace blink {

struct WidthCacheEntry {
    WidthCacheEntry()
    {
        width = std::numeric_limits<float>::quiet_NaN();
    }
    bool isValid() const { return !std::isnan(width); }
    float width;
    IntRectExtent glyphBounds;
};

class WidthCache {
private:
    // Used to optimize small strings as hash table keys. Avoids malloc'ing an out-of-line StringImpl.
    class SmallStringKey {
    public:
        static unsigned capacity() { return s_capacity; }

        SmallStringKey()
            : m_length(s_emptyValueLength)
        {
        }

        SmallStringKey(WTF::HashTableDeletedValueType)
            : m_length(s_deletedValueLength)
        {
        }

        template<typename CharacterType> SmallStringKey(CharacterType* characters, unsigned short length)
            : m_length(length)
        {
            ASSERT(length <= s_capacity);

            StringHasher hasher;

            bool remainder = length & 1;
            length >>= 1;

            unsigned i = 0;
            while (length--) {
                m_characters[i] = characters[i];
                m_characters[i + 1] = characters[i + 1];
                hasher.addCharactersAssumingAligned(characters[i], characters[i + 1]);
                i += 2;
            }

            if (remainder) {
                m_characters[i] = characters[i];
                hasher.addCharacter(characters[i]);
            }

            m_hash = hasher.hash();
        }

        const UChar* characters() const { return m_characters; }
        unsigned short length() const { return m_length; }
        unsigned hash() const { return m_hash; }

        bool isHashTableDeletedValue() const { return m_length == s_deletedValueLength; }
        bool isHashTableEmptyValue() const { return m_length == s_emptyValueLength; }

    private:
        static const unsigned s_capacity = 15;
        static const unsigned s_emptyValueLength = s_capacity + 1;
        static const unsigned s_deletedValueLength = s_capacity + 2;

        unsigned m_hash;
        unsigned short m_length;
        UChar m_characters[s_capacity];
    };

    struct SmallStringKeyHash {
        static unsigned hash(const SmallStringKey& key) { return key.hash(); }
        static bool equal(const SmallStringKey& a, const SmallStringKey& b) { return a == b; }
        static const bool safeToCompareToEmptyOrDeleted = true; // Empty and deleted values have lengths that are not equal to any valid length.
    };

    struct SmallStringKeyHashTraits : WTF::SimpleClassHashTraits<SmallStringKey> {
        static const bool hasIsEmptyValueFunction = true;
        static bool isEmptyValue(const SmallStringKey& key) { return key.isHashTableEmptyValue(); }
        static const bool needsDestruction = false;
        static const unsigned minimumTableSize = 16;
    };

    friend bool operator==(const SmallStringKey&, const SmallStringKey&);

public:
    WidthCache()
        : m_interval(s_maxInterval)
        , m_countdown(m_interval)
    {
    }

    WidthCacheEntry* add(const TextRun& run, WidthCacheEntry entry)
    {
        if (static_cast<unsigned>(run.length()) > SmallStringKey::capacity())
            return 0;

        if (m_countdown > 0) {
            --m_countdown;
            return 0;
        }

        return addSlowCase(run, entry);
    }

    void clear()
    {
        m_singleCharMap.clear();
        m_map.clear();
    }

private:
    WidthCacheEntry* addSlowCase(const TextRun& run, WidthCacheEntry entry)
    {
        int length = run.length();
        bool isNewEntry;
        WidthCacheEntry *value;
        if (length == 1) {
            SingleCharMap::AddResult addResult = m_singleCharMap.add(run[0], entry);
            isNewEntry = addResult.isNewEntry;
            value = &addResult.storedValue->value;
        } else {
            SmallStringKey smallStringKey;
            if (run.is8Bit())
                smallStringKey = SmallStringKey(run.characters8(), length);
            else
                smallStringKey = SmallStringKey(run.characters16(), length);

            Map::AddResult addResult = m_map.add(smallStringKey, entry);
            isNewEntry = addResult.isNewEntry;
            value = &addResult.storedValue->value;
        }

        // Cache hit: ramp up by sampling the next few words.
        if (!isNewEntry) {
            m_interval = s_minInterval;
            return value;
        }

        // Cache miss: ramp down by increasing our sampling interval.
        if (m_interval < s_maxInterval)
            ++m_interval;
        m_countdown = m_interval;

        if ((m_singleCharMap.size() + m_map.size()) < s_maxSize)
            return value;

        // No need to be fancy: we're just trying to avoid pathological growth.
        m_singleCharMap.clear();
        m_map.clear();
        return 0;
    }

    typedef HashMap<SmallStringKey, WidthCacheEntry, SmallStringKeyHash, SmallStringKeyHashTraits> Map;
    typedef HashMap<uint32_t, WidthCacheEntry, DefaultHash<uint32_t>::Hash, WTF::UnsignedWithZeroKeyHashTraits<uint32_t> > SingleCharMap;
    static const int s_minInterval = -3; // A cache hit pays for about 3 cache misses.
    static const int s_maxInterval = 20; // Sampling at this interval has almost no overhead.
    static const unsigned s_maxSize = 500000; // Just enough to guard against pathological growth.

    int m_interval;
    int m_countdown;
    SingleCharMap m_singleCharMap;
    Map m_map;
};

inline bool operator==(const WidthCache::SmallStringKey& a, const WidthCache::SmallStringKey& b)
{
    if (a.length() != b.length())
        return false;
    return WTF::equal(a.characters(), b.characters(), a.length());
}

} // namespace blink

#endif // WidthCache_h
