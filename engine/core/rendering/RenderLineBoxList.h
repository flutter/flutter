/*
 * Copyright (C) 2009 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#ifndef RenderLineBoxList_h
#define RenderLineBoxList_h

#include "core/rendering/RenderObject.h"

namespace blink {

class RenderLineBoxList {
public:
    RenderLineBoxList()
        : m_firstLineBox(0)
        , m_lastLineBox(0)
    {
    }

#if ENABLE(ASSERT)
    ~RenderLineBoxList();
#endif

    InlineFlowBox* firstLineBox() const { return m_firstLineBox; }
    InlineFlowBox* lastLineBox() const { return m_lastLineBox; }

    void checkConsistency() const;

    void appendLineBox(InlineFlowBox*);

    void deleteLineBoxTree();
    void deleteLineBoxes();

    void extractLineBox(InlineFlowBox*);
    void attachLineBox(InlineFlowBox*);
    void removeLineBox(InlineFlowBox*);

    void dirtyLineBoxes();
    void dirtyLinesFromChangedChild(RenderObject* parent, RenderObject* child);

    void paint(RenderBoxModelObject*, PaintInfo&, const LayoutPoint&) const;
    bool hitTest(RenderBoxModelObject*, const HitTestRequest&, HitTestResult&, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset, HitTestAction) const;

private:
    bool anyLineIntersectsRect(RenderBoxModelObject*, const LayoutRect&, const LayoutPoint&) const;
    bool lineIntersectsDirtyRect(RenderBoxModelObject*, InlineFlowBox*, const PaintInfo&, const LayoutPoint&) const;
    bool rangeIntersectsRect(RenderBoxModelObject*, LayoutUnit logicalTop, LayoutUnit logicalBottom, const LayoutRect&, const LayoutPoint&) const;

    // For block flows, each box represents the root inline box for a line in the
    // paragraph.
    // For inline flows, each box represents a portion of that inline.
    InlineFlowBox* m_firstLineBox;
    InlineFlowBox* m_lastLineBox;
};


#if !ENABLE(ASSERT)
inline void RenderLineBoxList::checkConsistency() const
{
}
#endif

} // namespace blink

#endif // RenderFlow_h
