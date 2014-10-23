/*
 * Copyright (C) 2006 Lars Knoll <lars@trolltech.com>
 * Copyright (C) 2007, 2011, 2012 Apple Inc. All rights reserved.
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
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

#ifndef TextBreakIterator_h
#define TextBreakIterator_h

#include "platform/PlatformExport.h"
#include "wtf/text/AtomicString.h"
#include "wtf/unicode/Unicode.h"

#include <unicode/brkiter.h>

namespace blink {

typedef icu::BreakIterator TextBreakIterator;

// Note: The returned iterator is good only until you get another iterator, with the exception of acquireLineBreakIterator.

// This is similar to character break iterator in most cases, but is subject to
// platform UI conventions. One notable example where this can be different
// from character break iterator is Thai prepend characters, see bug 24342.
// Use this for insertion point and selection manipulations.
PLATFORM_EXPORT TextBreakIterator* cursorMovementIterator(const UChar*, int length);

PLATFORM_EXPORT TextBreakIterator* wordBreakIterator(const String&, int start, int length);
PLATFORM_EXPORT TextBreakIterator* wordBreakIterator(const UChar*, int length);
PLATFORM_EXPORT TextBreakIterator* acquireLineBreakIterator(const LChar*, int length, const AtomicString& locale, const UChar* priorContext, unsigned priorContextLength);
PLATFORM_EXPORT TextBreakIterator* acquireLineBreakIterator(const UChar*, int length, const AtomicString& locale, const UChar* priorContext, unsigned priorContextLength);
PLATFORM_EXPORT void releaseLineBreakIterator(TextBreakIterator*);
PLATFORM_EXPORT TextBreakIterator* sentenceBreakIterator(const UChar*, int length);

PLATFORM_EXPORT bool isWordTextBreak(TextBreakIterator*);

const int TextBreakDone = -1;

class PLATFORM_EXPORT LazyLineBreakIterator {
public:
    LazyLineBreakIterator()
        : m_iterator(0)
        , m_cachedPriorContext(0)
        , m_cachedPriorContextLength(0)
    {
        resetPriorContext();
    }

    LazyLineBreakIterator(String string, const AtomicString& locale = AtomicString())
        : m_string(string)
        , m_locale(locale)
        , m_iterator(0)
        , m_cachedPriorContext(0)
        , m_cachedPriorContextLength(0)
    {
        resetPriorContext();
    }

    ~LazyLineBreakIterator()
    {
        if (m_iterator)
            releaseLineBreakIterator(m_iterator);
    }

    String string() const { return m_string; }

    UChar lastCharacter() const
    {
        COMPILE_ASSERT(WTF_ARRAY_LENGTH(m_priorContext) == 2, TextBreakIterator_unexpected_prior_context_length);
        return m_priorContext[1];
    }

    UChar secondToLastCharacter() const
    {
        COMPILE_ASSERT(WTF_ARRAY_LENGTH(m_priorContext) == 2, TextBreakIterator_unexpected_prior_context_length);
        return m_priorContext[0];
    }

    void setPriorContext(UChar last, UChar secondToLast)
    {
        COMPILE_ASSERT(WTF_ARRAY_LENGTH(m_priorContext) == 2, TextBreakIterator_unexpected_prior_context_length);
        m_priorContext[0] = secondToLast;
        m_priorContext[1] = last;
    }

    void updatePriorContext(UChar last)
    {
        COMPILE_ASSERT(WTF_ARRAY_LENGTH(m_priorContext) == 2, TextBreakIterator_unexpected_prior_context_length);
        m_priorContext[0] = m_priorContext[1];
        m_priorContext[1] = last;
    }

    void resetPriorContext()
    {
        COMPILE_ASSERT(WTF_ARRAY_LENGTH(m_priorContext) == 2, TextBreakIterator_unexpected_prior_context_length);
        m_priorContext[0] = 0;
        m_priorContext[1] = 0;
    }

    unsigned priorContextLength() const
    {
        unsigned priorContextLength = 0;
        COMPILE_ASSERT(WTF_ARRAY_LENGTH(m_priorContext) == 2, TextBreakIterator_unexpected_prior_context_length);
        if (m_priorContext[1]) {
            ++priorContextLength;
            if (m_priorContext[0])
                ++priorContextLength;
        }
        return priorContextLength;
    }

    // Obtain text break iterator, possibly previously cached, where this iterator is (or has been)
    // initialized to use the previously stored string as the primary breaking context and using
    // previously stored prior context if non-empty.
    TextBreakIterator* get(unsigned priorContextLength)
    {
        ASSERT(priorContextLength <= priorContextCapacity);
        const UChar* priorContext = priorContextLength ? &m_priorContext[priorContextCapacity - priorContextLength] : 0;
        if (!m_iterator) {
            if (m_string.is8Bit())
                m_iterator = acquireLineBreakIterator(m_string.characters8(), m_string.length(), m_locale, priorContext, priorContextLength);
            else
                m_iterator = acquireLineBreakIterator(m_string.characters16(), m_string.length(), m_locale, priorContext, priorContextLength);
            m_cachedPriorContext = priorContext;
            m_cachedPriorContextLength = priorContextLength;
        } else if (priorContext != m_cachedPriorContext || priorContextLength != m_cachedPriorContextLength) {
            this->resetStringAndReleaseIterator(m_string, m_locale);
            return this->get(priorContextLength);
        }
        return m_iterator;
    }

    void resetStringAndReleaseIterator(String string, const AtomicString& locale)
    {
        if (m_iterator)
            releaseLineBreakIterator(m_iterator);

        m_string = string;
        m_locale = locale;
        m_iterator = 0;
        m_cachedPriorContext = 0;
        m_cachedPriorContextLength = 0;
    }

private:
    static const unsigned priorContextCapacity = 2;
    String m_string;
    AtomicString m_locale;
    TextBreakIterator* m_iterator;
    UChar m_priorContext[priorContextCapacity];
    const UChar* m_cachedPriorContext;
    unsigned m_cachedPriorContextLength;
};

// Iterates over "extended grapheme clusters", as defined in UAX #29.
// Note that platform implementations may be less sophisticated - e.g. ICU prior to
// version 4.0 only supports "legacy grapheme clusters".
// Use this for general text processing, e.g. string truncation.

class PLATFORM_EXPORT NonSharedCharacterBreakIterator {
    WTF_MAKE_NONCOPYABLE(NonSharedCharacterBreakIterator);
public:
    explicit NonSharedCharacterBreakIterator(const String&);
    NonSharedCharacterBreakIterator(const UChar*, unsigned length);
    ~NonSharedCharacterBreakIterator();

    int next();
    int current();

    bool isBreak(int offset) const;
    int preceding(int offset) const;
    int following(int offset) const;

    bool operator!() const
    {
        return !m_is8Bit && !m_iterator;
    }

private:
    void createIteratorForBuffer(const UChar*, unsigned length);

    unsigned clusterLengthStartingAt(unsigned offset) const
    {
        ASSERT(m_is8Bit);
        // The only Latin-1 Extended Grapheme Cluster is CR LF
        return isCRBeforeLF(offset) ? 2 : 1;
    }

    bool isCRBeforeLF(unsigned offset) const
    {
        ASSERT(m_is8Bit);
        return m_charaters8[offset] == '\r' && offset + 1 < m_length && m_charaters8[offset + 1] == '\n';
    }

    bool isLFAfterCR(unsigned offset) const
    {
        ASSERT(m_is8Bit);
        return m_charaters8[offset] == '\n' && offset >= 1 && m_charaters8[offset - 1] == '\r';
    }

    bool m_is8Bit;

    // For 8 bit strings, we implement the iterator ourselves.
    const LChar* m_charaters8;
    unsigned m_offset;
    unsigned m_length;

    // For 16 bit strings, we use a TextBreakIterator.
    TextBreakIterator* m_iterator;
};

// Counts the number of grapheme clusters. A surrogate pair or a sequence
// of a non-combining character and following combining characters is
// counted as 1 grapheme cluster.
PLATFORM_EXPORT unsigned numGraphemeClusters(const String&);
// Returns the number of characters which will be less than or equal to
// the specified grapheme cluster length.
PLATFORM_EXPORT unsigned numCharactersInGraphemeClusters(const String&, unsigned);

}

#endif
