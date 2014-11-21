/*
 * Copyright (C) 2007 Apple Inc.  All rights reserved.
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

#ifndef LayoutState_h
#define LayoutState_h

#include "sky/engine/platform/geometry/LayoutRect.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/Noncopyable.h"

namespace blink {

class ForceHorriblySlowRectMapping;
class RenderBox;
class RenderObject;
class RenderInline;
class RenderView;

class LayoutState {
    WTF_MAKE_NONCOPYABLE(LayoutState);
public:
    // Constructor for root LayoutState created by RenderView
    explicit LayoutState(RenderView&);
    // Constructor for sub-tree Layout and RenderTableSections
    explicit LayoutState(RenderObject& root);

    LayoutState(RenderBox&, const LayoutSize& offset, bool containingBlockLogicalWidthChanged = false);
    LayoutState(RenderInline&);

    ~LayoutState();

    const LayoutSize& layoutOffset() const { return m_layoutOffset; }
    bool containingBlockLogicalWidthChanged() const { return m_containingBlockLogicalWidthChanged; }

    LayoutState* next() const { return m_next; }

    RenderObject& renderer() const { return m_renderer; }

private:
    friend class ForceHorriblySlowRectMapping;

    bool m_containingBlockLogicalWidthChanged : 1;

    LayoutState* m_next;

    // x/y offset from container. Does not include relative positioning or scroll offsets.
    LayoutSize m_layoutOffset;

    RenderObject& m_renderer;
};

} // namespace blink

#endif // LayoutState_h
