/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
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

#ifndef RenderedPosition_h
#define RenderedPosition_h

#include "core/editing/TextAffinity.h"
#include "core/rendering/InlineBox.h"

namespace blink {

class LayoutUnit;
class Position;
class RenderObject;
class VisiblePosition;

class RenderedPosition {
public:
    RenderedPosition();
    explicit RenderedPosition(const VisiblePosition&);
    explicit RenderedPosition(const Position&, EAffinity);
    bool isEquivalent(const RenderedPosition&) const;

    bool isNull() const { return !m_renderer; }
    RootInlineBox* rootBox() { return m_inlineBox ? &m_inlineBox->root() : 0; }

    unsigned char bidiLevelOnLeft() const;
    unsigned char bidiLevelOnRight() const;
    RenderedPosition leftBoundaryOfBidiRun(unsigned char bidiLevelOfRun);
    RenderedPosition rightBoundaryOfBidiRun(unsigned char bidiLevelOfRun);

    enum ShouldMatchBidiLevel { MatchBidiLevel, IgnoreBidiLevel };
    bool atLeftBoundaryOfBidiRun() const { return atLeftBoundaryOfBidiRun(IgnoreBidiLevel, 0); }
    bool atRightBoundaryOfBidiRun() const { return atRightBoundaryOfBidiRun(IgnoreBidiLevel, 0); }
    // The following two functions return true only if the current position is at the end of the bidi run
    // of the specified bidi embedding level.
    bool atLeftBoundaryOfBidiRun(unsigned char bidiLevelOfRun) const { return atLeftBoundaryOfBidiRun(MatchBidiLevel, bidiLevelOfRun); }
    bool atRightBoundaryOfBidiRun(unsigned char bidiLevelOfRun) const { return atRightBoundaryOfBidiRun(MatchBidiLevel, bidiLevelOfRun); }

    Position positionAtLeftBoundaryOfBiDiRun() const;
    Position positionAtRightBoundaryOfBiDiRun() const;

    IntRect absoluteRect(LayoutUnit* extraWidthToEndOfLine = 0) const;

private:
    bool operator==(const RenderedPosition&) const { return false; }
    explicit RenderedPosition(RenderObject*, InlineBox*, int offset);

    InlineBox* prevLeafChild() const;
    InlineBox* nextLeafChild() const;
    bool atLeftmostOffsetInBox() const { return m_inlineBox && m_offset == m_inlineBox->caretLeftmostOffset(); }
    bool atRightmostOffsetInBox() const { return m_inlineBox && m_offset == m_inlineBox->caretRightmostOffset(); }
    bool atLeftBoundaryOfBidiRun(ShouldMatchBidiLevel, unsigned char bidiLevelOfRun) const;
    bool atRightBoundaryOfBidiRun(ShouldMatchBidiLevel, unsigned char bidiLevelOfRun) const;

    RenderObject* m_renderer;
    InlineBox* m_inlineBox;
    int m_offset;

    static InlineBox* uncachedInlineBox() { return reinterpret_cast<InlineBox*>(1); }
    // Needs to be different form 0 so pick 1 because it's also on the null page.

    mutable InlineBox* m_prevLeafChild;
    mutable InlineBox* m_nextLeafChild;
};

inline RenderedPosition::RenderedPosition()
    : m_renderer(0)
    , m_inlineBox(0)
    , m_offset(0)
    , m_prevLeafChild(uncachedInlineBox())
    , m_nextLeafChild(uncachedInlineBox())
{
}

inline RenderedPosition::RenderedPosition(RenderObject* renderer, InlineBox* box, int offset)
    : m_renderer(renderer)
    , m_inlineBox(box)
    , m_offset(offset)
    , m_prevLeafChild(uncachedInlineBox())
    , m_nextLeafChild(uncachedInlineBox())
{
}

bool renderObjectContainsPosition(RenderObject*, const Position&);

};

#endif // RenderedPosition_h
