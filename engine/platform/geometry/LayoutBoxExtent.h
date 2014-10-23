/*
 * Copyright (c) 2012, Google Inc. All rights reserved.
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

#ifndef LayoutBoxExtent_h
#define LayoutBoxExtent_h

#include "platform/LayoutUnit.h"
#include "platform/PlatformExport.h"
#include "platform/text/TextDirection.h"
#include "platform/text/WritingMode.h"

namespace blink {

class PLATFORM_EXPORT LayoutBoxExtent {
public:
    LayoutBoxExtent() : m_top(0), m_right(0), m_bottom(0), m_left(0) { }
    LayoutBoxExtent(LayoutUnit top, LayoutUnit right, LayoutUnit bottom, LayoutUnit left)
        : m_top(top), m_right(right), m_bottom(bottom), m_left(left) { }

    inline LayoutUnit top() const { return m_top; }
    inline LayoutUnit right() const { return m_right; }
    inline LayoutUnit bottom() const { return m_bottom; }
    inline LayoutUnit left() const { return m_left; }

    inline void setTop(LayoutUnit value) { m_top = value; }
    inline void setRight(LayoutUnit value) { m_right = value; }
    inline void setBottom(LayoutUnit value) { m_bottom = value; }
    inline void setLeft(LayoutUnit value) { m_left = value; }

    LayoutUnit logicalTop(WritingMode) const;
    LayoutUnit logicalBottom(WritingMode) const;
    LayoutUnit logicalLeft(WritingMode) const;
    LayoutUnit logicalRight(WritingMode) const;

    LayoutUnit before(WritingMode) const;
    LayoutUnit after(WritingMode) const;
    LayoutUnit start(WritingMode, TextDirection) const;
    LayoutUnit end(WritingMode, TextDirection) const;

    void setBefore(WritingMode, LayoutUnit);
    void setAfter(WritingMode, LayoutUnit);
    void setStart(WritingMode, TextDirection, LayoutUnit);
    void setEnd(WritingMode, TextDirection, LayoutUnit);

    LayoutUnit& mutableLogicalLeft(WritingMode);
    LayoutUnit& mutableLogicalRight(WritingMode);

    LayoutUnit& mutableBefore(WritingMode);
    LayoutUnit& mutableAfter(WritingMode);

private:
    LayoutUnit m_top;
    LayoutUnit m_right;
    LayoutUnit m_bottom;
    LayoutUnit m_left;
};

} // namespace blink

#endif // LayoutBoxExtent_h
