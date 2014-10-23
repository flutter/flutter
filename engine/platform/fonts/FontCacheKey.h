/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer
 *    in the documentation and/or other materials provided with the
 *    distribution.
 * 3. Neither the name of Google Inc. nor the names of its contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
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

#ifndef FontCacheKey_h
#define FontCacheKey_h

#include "FontFaceCreationParams.h"
#include "wtf/HashMap.h"
#include "wtf/HashTableDeletedValueType.h"
#include "wtf/text/AtomicStringHash.h"
#include "wtf/text/StringHash.h"

namespace blink {

// Multiplying the floating point size by 100 gives two decimal point
// precision which should be sufficient.
static const unsigned s_fontSizePrecisionMultiplier = 100;

struct FontCacheKey {
    WTF_MAKE_FAST_ALLOCATED;
public:
    FontCacheKey()
        : m_creationParams()
        , m_fontSize(0)
        , m_options(0) { }
    FontCacheKey(FontFaceCreationParams creationParams, float fontSize, unsigned options)
        : m_creationParams(creationParams)
        , m_fontSize(fontSize * s_fontSizePrecisionMultiplier)
        , m_options(options) { }
    FontCacheKey(WTF::HashTableDeletedValueType)
        : m_fontSize(hashTableDeletedSize()) { }

    unsigned hash() const
    {
        unsigned hashCodes[3] = {
            m_creationParams.hash(),
            m_fontSize,
            m_options
        };
        return StringHasher::hashMemory<sizeof(hashCodes)>(hashCodes);
    }

    bool operator==(const FontCacheKey& other) const
    {
        return m_creationParams == other.m_creationParams
            && m_fontSize == other.m_fontSize
            && m_options == other.m_options;
    }

    bool isHashTableDeletedValue() const
    {
        return m_fontSize == hashTableDeletedSize();
    }

    static unsigned precisionMultiplier()
    {
        return s_fontSizePrecisionMultiplier;
    }

private:
    static unsigned hashTableDeletedSize()
    {
        return 0xFFFFFFFFU;
    }

    FontFaceCreationParams m_creationParams;
    unsigned m_fontSize;
    unsigned m_options;
};

struct FontCacheKeyHash {
    static unsigned hash(const FontCacheKey& key)
    {
        return key.hash();
    }

    static bool equal(const FontCacheKey& a, const FontCacheKey& b)
    {
        return a == b;
    }

    static const bool safeToCompareToEmptyOrDeleted = true;
};

struct FontCacheKeyTraits : WTF::SimpleClassHashTraits<FontCacheKey> { };

} // namespace blink

#endif // FontCacheKey_h
