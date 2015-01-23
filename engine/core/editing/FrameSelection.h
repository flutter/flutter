/*
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_EDITING_FRAMESELECTION_H_
#define SKY_ENGINE_CORE_EDITING_FRAMESELECTION_H_

#include "sky/engine/core/dom/Range.h"
#include "sky/engine/core/editing/Caret.h"
#include "sky/engine/core/editing/EditingStyle.h"
#include "sky/engine/core/editing/VisibleSelection.h"
#include "sky/engine/core/rendering/ScrollAlignment.h"
#include "sky/engine/platform/Timer.h"
#include "sky/engine/platform/geometry/IntRect.h"
#include "sky/engine/platform/geometry/LayoutRect.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/Noncopyable.h"

namespace blink {

class CharacterData;
class LocalFrame;
class GraphicsContext;
class MutableStylePropertySet;
class RenderObject;
class RenderView;
class Settings;
class Text;
class VisiblePosition;

enum EUserTriggered { NotUserTriggered = 0, UserTriggered = 1 };

enum RevealExtentOption {
    RevealExtent,
    DoNotRevealExtent
};

class FrameSelection final : public VisibleSelection::ChangeObserver, private CaretBase {
    WTF_MAKE_NONCOPYABLE(FrameSelection);
    WTF_MAKE_FAST_ALLOCATED;
public:
    static PassOwnPtr<FrameSelection> create(LocalFrame* frame = 0)
    {
        return adoptPtr(new FrameSelection(frame));
    }
    virtual ~FrameSelection();

    enum EAlteration { AlterationMove, AlterationExtend };
    enum CursorAlignOnScroll { AlignCursorOnScrollIfNeeded,
                               AlignCursorOnScrollAlways };
    enum SetSelectionOption {
        // 1 << 0 is reserved for EUserTriggered
        CloseTyping = 1 << 1,
        ClearTypingStyle = 1 << 2,
        SpellCorrectionTriggered = 1 << 3,
        DoNotSetFocus = 1 << 4,
        DoNotUpdateAppearance = 1 << 5,
    };
    typedef unsigned SetSelectionOptions; // Union of values in SetSelectionOption and EUserTriggered
    static inline EUserTriggered selectionOptionsToUserTriggered(SetSelectionOptions options)
    {
        return static_cast<EUserTriggered>(options & UserTriggered);
    }

    enum DirectoinalOption {
        NonDirectional,
        Directional
    };
    enum ResetCaretBlinkOption {
        None,
        ResetCaretBlink
    };

    Element* rootEditableElement() const { return m_selection.rootEditableElement(); }
    Element* rootEditableElementOrDocumentElement() const;
    ContainerNode* rootEditableElementOrTreeScopeRootNode() const;

    bool hasEditableStyle() const { return m_selection.hasEditableStyle(); }
    bool isContentEditable() const { return m_selection.isContentEditable(); }
    bool isContentRichlyEditable() const { return m_selection.isContentRichlyEditable(); }

    void moveTo(const VisiblePosition&, EUserTriggered = NotUserTriggered, CursorAlignOnScroll = AlignCursorOnScrollIfNeeded);
    void moveTo(const VisiblePosition&, const VisiblePosition&, EUserTriggered = NotUserTriggered);
    void moveTo(const Position&, EAffinity, EUserTriggered = NotUserTriggered);

    const VisibleSelection& selection() const { return m_selection; }
    void setSelection(const VisibleSelection&, SetSelectionOptions = CloseTyping | ClearTypingStyle, CursorAlignOnScroll = AlignCursorOnScrollIfNeeded, TextGranularity = CharacterGranularity);
    void setSelection(const VisibleSelection& selection, TextGranularity granularity) { setSelection(selection, CloseTyping | ClearTypingStyle, AlignCursorOnScrollIfNeeded, granularity); }
    bool setSelectedRange(Range*, EAffinity, DirectoinalOption directional = NonDirectional, SetSelectionOptions = CloseTyping | ClearTypingStyle);
    void selectAll();
    void clear();
    void prepareForDestruction();

    // Call this after doing user-triggered selections to make it easy to delete the frame you entirely selected.
    void selectFrameElementInParentIfFullySelected();

    bool contains(const LayoutPoint&);

    SelectionType selectionType() const { return m_selection.selectionType(); }

    EAffinity affinity() const { return m_selection.affinity(); }

    bool modify(EAlteration, SelectionDirection, TextGranularity, EUserTriggered = NotUserTriggered);
    enum VerticalDirection { DirectionUp, DirectionDown };
    bool modify(EAlteration, unsigned verticalDistance, VerticalDirection, EUserTriggered = NotUserTriggered, CursorAlignOnScroll = AlignCursorOnScrollIfNeeded);

    TextGranularity granularity() const { return m_granularity; }

    void setStart(const VisiblePosition &, EUserTriggered = NotUserTriggered);
    void setEnd(const VisiblePosition &, EUserTriggered = NotUserTriggered);

    void setBase(const VisiblePosition&, EUserTriggered = NotUserTriggered);
    void setExtent(const VisiblePosition&, EUserTriggered = NotUserTriggered);

    Position base() const { return m_selection.base(); }
    Position extent() const { return m_selection.extent(); }
    Position start() const { return m_selection.start(); }
    Position end() const { return m_selection.end(); }

    // Return the renderer that is responsible for painting the caret (in the selection start node)
    RenderBlock* caretRenderer() const;

    // Bounds of (possibly transformed) caret in absolute coords
    IntRect absoluteCaretBounds();

    void didChangeFocus();
    void willBeModified(EAlteration, SelectionDirection);

    bool isNone() const { return m_selection.isNone(); }
    bool isCaret() const { return m_selection.isCaret(); }
    bool isRange() const { return m_selection.isRange(); }
    bool isCaretOrRange() const { return m_selection.isCaretOrRange(); }
    bool isInPasswordField() const;
    bool isDirectional() const { return m_selection.isDirectional(); }

    // If this FrameSelection has a logical range which is still valid, this function return its clone. Otherwise,
    // the return value from underlying VisibleSelection's firstRange() is returned.
    PassRefPtr<Range> firstRange() const;

    PassRefPtr<Range> toNormalizedRange() const { return m_selection.toNormalizedRange(); }

    void nodeWillBeRemoved(Node&);
    void didUpdateCharacterData(CharacterData*, unsigned offset, unsigned oldLength, unsigned newLength);
    void didMergeTextNodes(const Text& oldNode, unsigned offset);
    void didSplitTextNode(const Text& oldNode);

    void updateAppearance(ResetCaretBlinkOption = None);
    void setCaretVisible(bool caretIsVisible) { setCaretVisibility(caretIsVisible ? Visible : Hidden); }
    void setCaretRectNeedsUpdate();
    void paintCaret(GraphicsContext*, const LayoutPoint&, const LayoutRect& clipRect);
    bool ShouldPaintCaretForTesting() const { return m_shouldPaintCaret; }

    // Used to suspend caret blinking while the mouse is down.
    void setCaretBlinkingSuspended(bool suspended) { m_isCaretBlinkingSuspended = suspended; }
    bool isCaretBlinkingSuspended() const { return m_isCaretBlinkingSuspended; }

    // Focus
    void setFocused(bool);
    bool isFocused() const { return m_focused; }
    bool isFocusedAndActive() const;
    void pageActivationChanged();

#ifndef NDEBUG
    void formatForDebugger(char* buffer, unsigned length) const;
    void showTreeForThis() const;
#endif

    enum EndPointsAdjustmentMode { AdjustEndpointsAtBidiBoundary, DoNotAdjsutEndpoints };
    void setNonDirectionalSelectionIfNeeded(const VisibleSelection&, TextGranularity, EndPointsAdjustmentMode = DoNotAdjsutEndpoints);
    void setFocusedNodeIfNeeded();
    void notifyRendererOfSelectionChange(EUserTriggered);

    EditingStyle* typingStyle() const;
    void setTypingStyle(PassRefPtr<EditingStyle>);
    void clearTypingStyle();

    String selectedText() const;

    void revealSelection(const ScrollAlignment& = ScrollAlignment::alignCenterIfNeeded, RevealExtentOption = DoNotRevealExtent);
    void setSelectionFromNone();

    void setShouldShowBlockCursor(bool);

    // VisibleSelection::ChangeObserver interface.
    virtual void didChangeVisibleSelection() override;

private:
    explicit FrameSelection(LocalFrame*);

    enum EPositionType { START, END, BASE, EXTENT };

    void respondToNodeModification(Node&, bool baseRemoved, bool extentRemoved, bool startRemoved, bool endRemoved);
    TextDirection directionOfEnclosingBlock();
    TextDirection directionOfSelection();

    VisiblePosition positionForPlatform(bool isGetStart) const;
    VisiblePosition startForPlatform() const;
    VisiblePosition endForPlatform() const;
    VisiblePosition nextWordPositionForPlatform(const VisiblePosition&);

    VisiblePosition modifyExtendingRight(TextGranularity);
    VisiblePosition modifyExtendingForward(TextGranularity);
    VisiblePosition modifyMovingRight(TextGranularity);
    VisiblePosition modifyMovingForward(TextGranularity);
    VisiblePosition modifyExtendingLeft(TextGranularity);
    VisiblePosition modifyExtendingBackward(TextGranularity);
    VisiblePosition modifyMovingLeft(TextGranularity);
    VisiblePosition modifyMovingBackward(TextGranularity);

    LayoutUnit lineDirectionPointForBlockDirectionNavigation(EPositionType);

    void notifyAccessibilityForSelectionChange();

    void focusedOrActiveStateChanged();

    void caretBlinkTimerFired(Timer<FrameSelection>*);

    void setCaretVisibility(CaretVisibility);
    bool shouldBlinkCaret() const;

    bool dispatchSelectStart();

    void updateSelectionIfNeeded(const Position& base, const Position& extent, const Position& start, const Position& end);

    void startObservingVisibleSelectionChange();
    void stopObservingVisibleSelectionChangeIfNecessary();

    VisibleSelection validateSelection(const VisibleSelection&);

    LocalFrame* m_frame;

    LayoutUnit m_xPosForVerticalArrowNavigation;

    VisibleSelection m_selection;
    bool m_observingVisibleSelection;
    VisiblePosition m_originalBase; // Used to store base before the adjustment at bidi boundary
    TextGranularity m_granularity;

    // The range specified by the user, which may not be visually canonicalized (hence "logical").
    // This will be invalidated if the underlying VisibleSelection changes. If that happens, this variable will
    // become null, in which case logical positions == visible positions.
    RefPtr<Range> m_logicalRange;

    RefPtr<EditingStyle> m_typingStyle;

    Timer<FrameSelection> m_caretBlinkTimer;

    bool m_shouldPaintCaret : 1;
    bool m_isCaretBlinkingSuspended : 1;
    bool m_focused : 1;
    bool m_shouldShowBlockCursor : 1;
};

inline EditingStyle* FrameSelection::typingStyle() const
{
    return m_typingStyle.get();
}

inline void FrameSelection::clearTypingStyle()
{
    m_typingStyle.clear();
}

inline void FrameSelection::setTypingStyle(PassRefPtr<EditingStyle> style)
{
    m_typingStyle = style;
}
} // namespace blink

#ifndef NDEBUG
// Outside the WebCore namespace for ease of invocation from gdb.
void showTree(const blink::FrameSelection&);
void showTree(const blink::FrameSelection*);
#endif

#endif  // SKY_ENGINE_CORE_EDITING_FRAMESELECTION_H_
