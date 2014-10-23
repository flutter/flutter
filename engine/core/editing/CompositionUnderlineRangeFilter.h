// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CompositionUnderlineRangeFilter_h
#define CompositionUnderlineRangeFilter_h

#include "core/editing/CompositionUnderline.h"
#include "wtf/NotFound.h"
#include "wtf/Vector.h"

namespace blink {

// A visitor class to yield elements of a sorted (by startOffset) list of
// underlines, visiting only elements that intersect with specified *inclusive*
// range [indexLo, indexHi].
class CompositionUnderlineRangeFilter {
    WTF_MAKE_NONCOPYABLE(CompositionUnderlineRangeFilter);
public:
    class ConstIterator {
    public:
        ConstIterator(): m_filter(nullptr), m_index(0) { }
        const CompositionUnderline& operator*()
        {
            ASSERT(m_index != kNotFound);
            return m_filter->m_underlines[m_index];
        }
        ConstIterator& operator++()
        {
            if (m_index != kNotFound)
                m_index = m_filter->seekValidIndex(m_index + 1);
            return *this;
        }
        const CompositionUnderline* operator->()
        {
            ASSERT(m_index != kNotFound);
            return &m_filter->m_underlines[m_index];
        }
        bool operator==(const ConstIterator& other)
        {
            return other.m_index == m_index && other.m_filter == m_filter;
        }
        bool operator!=(const ConstIterator& other) { return !operator==(other); }

    private:
        friend class CompositionUnderlineRangeFilter;

        ConstIterator(CompositionUnderlineRangeFilter* filter, size_t index)
            : m_filter(filter)
            , m_index(index) { }
        CompositionUnderlineRangeFilter* m_filter;
        size_t m_index;
    };

    CompositionUnderlineRangeFilter(const Vector<CompositionUnderline>& underlines, size_t indexLo, size_t indexHi);

    ConstIterator begin() { return ConstIterator(this, seekValidIndex(0)); }
    const ConstIterator& end() { return m_theEnd; }

private:
    friend class ConstIterator;

    // Returns |index| if |m_underlines[index]| intersects with range
    // [m_indexLo, m_indexHi]. Otherwise returns the index of the next
    // intersecting interval, or END if there are none left.
    size_t seekValidIndex(size_t index);

    // Assume that elements of |m_underlines| are sorted by |.startOffset|.
    const Vector<CompositionUnderline>& m_underlines;
    // The "query range" is the inclusive range [m_indexLo, m_indexHi].
    const size_t m_indexLo;
    const size_t m_indexHi;
    const ConstIterator m_theEnd;
};

} // namespace blink

#endif
