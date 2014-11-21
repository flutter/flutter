/*
 * Copyright (C) 2008 Apple Inc. All rights reserved.
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

#ifndef CSSSelectorList_h
#define CSSSelectorList_h

#include "sky/engine/core/css/CSSSelector.h"

namespace blink {

class CSSParserSelector;

class CSSSelectorList {
    WTF_MAKE_FAST_ALLOCATED;
public:
    CSSSelectorList() : m_selectorArray(0) { }
    CSSSelectorList(const CSSSelectorList&);

    ~CSSSelectorList();

    void adopt(CSSSelectorList& list);
    void adoptSelectorVector(Vector<OwnPtr<CSSParserSelector> >& selectorVector);

    bool isValid() const { return !!m_selectorArray; }
    const CSSSelector* first() const { return m_selectorArray; }
    static const CSSSelector* next(const CSSSelector&);
    bool hasOneSelector() const { return m_selectorArray && !next(*m_selectorArray); }
    const CSSSelector& selectorAt(size_t index) const { return m_selectorArray[index]; }

    size_t indexOfNextSelectorAfter(size_t index) const
    {
        const CSSSelector& current = selectorAt(index);
        const CSSSelector* next = this->next(current);
        if (!next)
            return kNotFound;
        return next - m_selectorArray;
    }

    String selectorsText() const;

private:
    unsigned length() const;
    void deleteSelectors();

    // Hide.
    CSSSelectorList& operator=(const CSSSelectorList&);

    // End of a multipart selector is indicated by m_isLastInTagHistory bit in the last item.
    // End of the array is indicated by m_isLastInSelectorList bit in the last item.
    CSSSelector* m_selectorArray;
};

inline const CSSSelector* CSSSelectorList::next(const CSSSelector& current)
{
    // Skip subparts of compound selectors.
    const CSSSelector* last = &current;
    while (!last->isLastInTagHistory())
        last++;
    return last->isLastInSelectorList() ? 0 : last + 1;
}

} // namespace blink

#endif // CSSSelectorList_h
