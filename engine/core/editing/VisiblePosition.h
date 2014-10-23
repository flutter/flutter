/*
 * Copyright (C) 2004, 2008 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef VisiblePosition_h
#define VisiblePosition_h

#include "core/editing/EditingBoundary.h"
#include "core/editing/PositionWithAffinity.h"
#include "platform/heap/Handle.h"
#include "platform/text/TextDirection.h"

namespace blink {

// VisiblePosition default affinity is downstream because
// the callers do not really care (they just want the
// deep position without regard to line position), and this
// is cheaper than UPSTREAM
#define VP_DEFAULT_AFFINITY DOWNSTREAM

// Callers who do not know where on the line the position is,
// but would like UPSTREAM if at a line break or DOWNSTREAM
// otherwise, need a clear way to specify that.  The
// constructors auto-correct UPSTREAM to DOWNSTREAM if the
// position is not at a line break.
#define VP_UPSTREAM_IF_POSSIBLE UPSTREAM

class InlineBox;
class Node;
class Range;

class VisiblePosition FINAL {
    DISALLOW_ALLOCATION();
public:
    // NOTE: UPSTREAM affinity will be used only if pos is at end of a wrapped line,
    // otherwise it will be converted to DOWNSTREAM
    VisiblePosition() : m_affinity(VP_DEFAULT_AFFINITY) { }
    explicit VisiblePosition(const Position&, EAffinity = VP_DEFAULT_AFFINITY);
    explicit VisiblePosition(const PositionWithAffinity&);

    void clear() { m_deepPosition.clear(); }

    bool isNull() const { return m_deepPosition.isNull(); }
    bool isNotNull() const { return m_deepPosition.isNotNull(); }
    bool isOrphan() const { return m_deepPosition.isOrphan(); }

    Position deepEquivalent() const { return m_deepPosition; }
    EAffinity affinity() const { ASSERT(m_affinity == UPSTREAM || m_affinity == DOWNSTREAM); return m_affinity; }
    void setAffinity(EAffinity affinity) { m_affinity = affinity; }

    // FIXME: Change the following functions' parameter from a boolean to StayInEditableContent.

    // next() and previous() will increment/decrement by a character cluster.
    VisiblePosition next(EditingBoundaryCrossingRule = CanCrossEditingBoundary) const;
    VisiblePosition previous(EditingBoundaryCrossingRule = CanCrossEditingBoundary) const;
    VisiblePosition honorEditingBoundaryAtOrBefore(const VisiblePosition&) const;
    VisiblePosition honorEditingBoundaryAtOrAfter(const VisiblePosition&) const;
    VisiblePosition skipToStartOfEditingBoundary(const VisiblePosition&) const;
    VisiblePosition skipToEndOfEditingBoundary(const VisiblePosition&) const;

    VisiblePosition left(bool stayInEditableContent = false) const;
    VisiblePosition right(bool stayInEditableContent = false) const;

    UChar32 characterAfter() const;
    UChar32 characterBefore() const { return previous().characterAfter(); }

    // FIXME: This does not handle [table, 0] correctly.
    Element* rootEditableElement() const { return m_deepPosition.isNotNull() ? m_deepPosition.deprecatedNode()->rootEditableElement() : 0; }

    void getInlineBoxAndOffset(InlineBox*& inlineBox, int& caretOffset) const
    {
        m_deepPosition.getInlineBoxAndOffset(m_affinity, inlineBox, caretOffset);
    }

    // Rect is local to the returned renderer
    LayoutRect localCaretRect(RenderObject*&) const;
    // Bounds of (possibly transformed) caret in absolute coords
    IntRect absoluteCaretBounds() const;
    // Abs x/y position of the caret ignoring transforms.
    // FIXME: navigation with transforms should be smarter.
    int lineDirectionPointForBlockDirectionNavigation() const;

    void trace(Visitor*);

#ifndef NDEBUG
    void debugPosition(const char* msg = "") const;
    void formatForDebugger(char* buffer, unsigned length) const;
    void showTreeForThis() const;
#endif

private:
    void init(const Position&, EAffinity);
    Position canonicalPosition(const Position&);

    Position leftVisuallyDistinctCandidate() const;
    Position rightVisuallyDistinctCandidate() const;

    Position m_deepPosition;
    EAffinity m_affinity;
};

// FIXME: This shouldn't ignore affinity.
inline bool operator==(const VisiblePosition& a, const VisiblePosition& b)
{
    return a.deepEquivalent() == b.deepEquivalent();
}

inline bool operator!=(const VisiblePosition& a, const VisiblePosition& b)
{
    return !(a == b);
}

PassRefPtrWillBeRawPtr<Range> makeRange(const VisiblePosition&, const VisiblePosition&);
bool setStart(Range*, const VisiblePosition&);
bool setEnd(Range*, const VisiblePosition&);
VisiblePosition startVisiblePosition(const Range*, EAffinity);

Element* enclosingBlockFlowElement(const VisiblePosition&);

bool isFirstVisiblePositionInNode(const VisiblePosition&, const ContainerNode*);
bool isLastVisiblePositionInNode(const VisiblePosition&, const ContainerNode*);

} // namespace blink

#ifndef NDEBUG
// Outside the WebCore namespace for ease of invocation from gdb.
void showTree(const blink::VisiblePosition*);
void showTree(const blink::VisiblePosition&);
#endif

#endif // VisiblePosition_h
