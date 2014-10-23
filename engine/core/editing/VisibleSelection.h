/*
 * Copyright (C) 2004 Apple Computer, Inc.  All rights reserved.
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

#ifndef VisibleSelection_h
#define VisibleSelection_h

#include "core/editing/SelectionType.h"
#include "core/editing/TextGranularity.h"
#include "core/editing/VisiblePosition.h"

namespace blink {

class LayoutPoint;
class Position;

const EAffinity SEL_DEFAULT_AFFINITY = DOWNSTREAM;
enum SelectionDirection { DirectionForward, DirectionBackward, DirectionRight, DirectionLeft };

class VisibleSelection {
    DISALLOW_ALLOCATION();
public:
    VisibleSelection();

    VisibleSelection(const Position&, EAffinity, bool isDirectional = false);
    VisibleSelection(const Position&, const Position&, EAffinity = SEL_DEFAULT_AFFINITY, bool isDirectional = false);

    explicit VisibleSelection(const Range*, EAffinity = SEL_DEFAULT_AFFINITY, bool isDirectional = false);

    explicit VisibleSelection(const VisiblePosition&, bool isDirectional = false);
    VisibleSelection(const VisiblePosition&, const VisiblePosition&, bool isDirectional = false);

    VisibleSelection(const VisibleSelection&);
    VisibleSelection& operator=(const VisibleSelection&);

    ~VisibleSelection();

    static VisibleSelection selectionFromContentsOfNode(Node*);

    SelectionType selectionType() const { return m_selectionType; }

    void setAffinity(EAffinity affinity) { m_affinity = affinity; }
    EAffinity affinity() const { return m_affinity; }

    void setBase(const Position&);
    void setBase(const VisiblePosition&);
    void setExtent(const Position&);
    void setExtent(const VisiblePosition&);

    Position base() const { return m_base; }
    Position extent() const { return m_extent; }
    Position start() const { return m_start; }
    Position end() const { return m_end; }

    VisiblePosition visibleStart() const { return VisiblePosition(m_start, isRange() ? DOWNSTREAM : affinity()); }
    VisiblePosition visibleEnd() const { return VisiblePosition(m_end, isRange() ? UPSTREAM : affinity()); }
    VisiblePosition visibleBase() const { return VisiblePosition(m_base, isRange() ? (isBaseFirst() ? UPSTREAM : DOWNSTREAM) : affinity()); }
    VisiblePosition visibleExtent() const { return VisiblePosition(m_extent, isRange() ? (isBaseFirst() ? DOWNSTREAM : UPSTREAM) : affinity()); }

    bool isNone() const { return selectionType() == NoSelection; }
    bool isCaret() const { return selectionType() == CaretSelection; }
    bool isRange() const { return selectionType() == RangeSelection; }
    bool isCaretOrRange() const { return selectionType() != NoSelection; }
    bool isNonOrphanedRange() const { return isRange() && !start().isOrphan() && !end().isOrphan(); }
    bool isNonOrphanedCaretOrRange() const { return isCaretOrRange() && !start().isOrphan() && !end().isOrphan(); }

    bool isBaseFirst() const { return m_baseIsFirst; }
    bool isDirectional() const { return m_isDirectional; }
    void setIsDirectional(bool isDirectional) { m_isDirectional = isDirectional; }

    void appendTrailingWhitespace();

    bool expandUsingGranularity(TextGranularity granularity);

    // We don't yet support multi-range selections, so we only ever have one range to return.
    PassRefPtrWillBeRawPtr<Range> firstRange() const;

    // FIXME: Most callers probably don't want this function, but are using it
    // for historical reasons.  toNormalizedRange contracts the range around
    // text, and moves the caret upstream before returning the range.
    PassRefPtrWillBeRawPtr<Range> toNormalizedRange() const;

    Element* rootEditableElement() const;
    bool isContentEditable() const;
    bool hasEditableStyle() const;
    bool isContentRichlyEditable() const;
    // Returns a shadow tree node for legacy shadow trees, a child of the
    // ShadowRoot node for new shadow trees, or 0 for non-shadow trees.
    Node* nonBoundaryShadowTreeRootNode() const;

    VisiblePosition visiblePositionRespectingEditingBoundary(const LayoutPoint& localPoint, Node* targetNode) const;

    void setWithoutValidation(const Position&, const Position&);

    // Listener of VisibleSelection modification. didChangeVisibleSelection() will be invoked when base, extent, start
    // or end is moved to a different position.
    //
    // Objects implementing |ChangeObserver| interface must outlive the VisibleSelection object.
    class ChangeObserver : public WillBeGarbageCollectedMixin {
        WTF_MAKE_NONCOPYABLE(ChangeObserver);
    public:
        ChangeObserver();
        virtual ~ChangeObserver();
        virtual void didChangeVisibleSelection() = 0;
        virtual void trace(Visitor*) { }
    };

    void setChangeObserver(ChangeObserver&);
    void clearChangeObserver();
    void didChange(); // Fire the change observer, if any.

    void trace(Visitor*);

    void validatePositionsIfNeeded();

#ifndef NDEBUG
    void debugPosition() const;
    void formatForDebugger(char* buffer, unsigned length) const;
    void showTreeForThis() const;
#endif

private:
    void validate(TextGranularity = CharacterGranularity);

    // Support methods for validate()
    void setBaseAndExtentToDeepEquivalents();
    void setStartAndEndFromBaseAndExtentRespectingGranularity(TextGranularity);
    void adjustSelectionToAvoidCrossingShadowBoundaries();
    void adjustSelectionToAvoidCrossingEditingBoundaries();
    void updateSelectionType();

    // We need to store these as Positions because VisibleSelection is
    // used to store values in editing commands for use when
    // undoing the command. We need to be able to create a selection that, while currently
    // invalid, will be valid once the changes are undone.

    Position m_base;   // Where the first click happened
    Position m_extent; // Where the end click happened
    Position m_start;  // Leftmost position when expanded to respect granularity
    Position m_end;    // Rightmost position when expanded to respect granularity

    EAffinity m_affinity;           // the upstream/downstream affinity of the caret

    // Oilpan: this reference has a lifetime that is at least as long
    // as this object.
    RawPtrWillBeMember<ChangeObserver> m_changeObserver;

    // these are cached, can be recalculated by validate()
    SelectionType m_selectionType; // None, Caret, Range
    bool m_baseIsFirst : 1; // True if base is before the extent
    bool m_isDirectional : 1; // Non-directional ignores m_baseIsFirst and selection always extends on shift + arrow key.
};

inline bool operator==(const VisibleSelection& a, const VisibleSelection& b)
{
    return a.start() == b.start() && a.end() == b.end() && a.affinity() == b.affinity() && a.isBaseFirst() == b.isBaseFirst()
        && a.isDirectional() == b.isDirectional();
}

inline bool operator!=(const VisibleSelection& a, const VisibleSelection& b)
{
    return !(a == b);
}

} // namespace blink

#ifndef NDEBUG
// Outside the WebCore namespace for ease of invocation from gdb.
void showTree(const blink::VisibleSelection&);
void showTree(const blink::VisibleSelection*);
#endif

#endif // VisibleSelection_h
