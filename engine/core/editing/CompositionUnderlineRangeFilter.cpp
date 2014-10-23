// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/editing/CompositionUnderlineRangeFilter.h"

namespace blink {

CompositionUnderlineRangeFilter::CompositionUnderlineRangeFilter(const Vector<CompositionUnderline>& underlines, size_t indexLo, size_t indexHi)
    : m_underlines(underlines)
    , m_indexLo(indexLo)
    , m_indexHi(indexHi)
    , m_theEnd(this, kNotFound) { }

size_t CompositionUnderlineRangeFilter::seekValidIndex(size_t index)
{
    if (index == kNotFound)
        return kNotFound;

    size_t numUnderlines = m_underlines.size();
    while (index < numUnderlines) {
        const CompositionUnderline& underline = m_underlines[index];

        if (underline.endOffset <= m_indexLo) {
            // |underline| lies  before the query range: keep on looking.
            ++index;
        } else if (underline.startOffset <= m_indexHi) {
            // |underline| intersects with the query range: valid, so return.
            return index;
        } else {
            // |underline| is completely after the query range: bail.
            break;
        }
    }
    return kNotFound;
}

} // namespace blink
