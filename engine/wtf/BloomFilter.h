/*
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef BloomFilter_h
#define BloomFilter_h

#include "wtf/Compiler.h"
#include "wtf/text/AtomicString.h"

namespace WTF {

// Counting bloom filter with k=2 and 8 bit counters. Uses 2^keyBits bytes of memory.
// False positive rate is approximately (1-e^(-2n/m))^2, where n is the number of unique
// keys and m is the table size (==2^keyBits).
template <unsigned keyBits>
class BloomFilter {
public:
    COMPILE_ASSERT(keyBits <= 16, bloom_filter_key_size);

    static const size_t tableSize = 1 << keyBits;
    static const unsigned keyMask = (1 << keyBits) - 1;
    static uint8_t maximumCount() { return std::numeric_limits<uint8_t>::max(); }

    BloomFilter() { clear(); }

    void add(unsigned hash);
    void remove(unsigned hash);

    // The filter may give false positives (claim it may contain a key it doesn't)
    // but never false negatives (claim it doesn't contain a key it does).
    bool mayContain(unsigned hash) const { return firstSlot(hash) && secondSlot(hash); }

    // The filter must be cleared before reuse even if all keys are removed.
    // Otherwise overflowed keys will stick around.
    void clear();

    void add(const AtomicString& string) { add(string.impl()->existingHash()); }
    void add(const String& string) { add(string.impl()->hash()); }
    void remove(const AtomicString& string) { remove(string.impl()->existingHash()); }
    void remove(const String& string) { remove(string.impl()->hash()); }

    bool mayContain(const AtomicString& string) const { return mayContain(string.impl()->existingHash()); }
    bool mayContain(const String& string) const { return mayContain(string.impl()->hash()); }

#if ENABLE(ASSERT)
    // Slow.
    bool likelyEmpty() const;
    bool isClear() const;
#endif

private:
    uint8_t& firstSlot(unsigned hash) { return m_table[hash & keyMask]; }
    uint8_t& secondSlot(unsigned hash) { return m_table[(hash >> 16) & keyMask]; }
    const uint8_t& firstSlot(unsigned hash) const { return m_table[hash & keyMask]; }
    const uint8_t& secondSlot(unsigned hash) const { return m_table[(hash >> 16) & keyMask]; }

    uint8_t m_table[tableSize];
};

template <unsigned keyBits>
inline void BloomFilter<keyBits>::add(unsigned hash)
{
    uint8_t& first = firstSlot(hash);
    uint8_t& second = secondSlot(hash);
    if (LIKELY(first < maximumCount()))
        ++first;
    if (LIKELY(second < maximumCount()))
        ++second;
}

template <unsigned keyBits>
inline void BloomFilter<keyBits>::remove(unsigned hash)
{
    uint8_t& first = firstSlot(hash);
    uint8_t& second = secondSlot(hash);
    ASSERT(first);
    ASSERT(second);
    // In case of an overflow, the slot sticks in the table until clear().
    if (LIKELY(first < maximumCount()))
        --first;
    if (LIKELY(second < maximumCount()))
        --second;
}

template <unsigned keyBits>
inline void BloomFilter<keyBits>::clear()
{
    memset(m_table, 0, tableSize);
}

#if ENABLE(ASSERT)
template <unsigned keyBits>
bool BloomFilter<keyBits>::likelyEmpty() const
{
    for (size_t n = 0; n < tableSize; ++n) {
        if (m_table[n] && m_table[n] != maximumCount())
            return false;
    }
    return true;
}

template <unsigned keyBits>
bool BloomFilter<keyBits>::isClear() const
{
    for (size_t n = 0; n < tableSize; ++n) {
        if (m_table[n])
            return false;
    }
    return true;
}
#endif

}

using WTF::BloomFilter;

#endif
