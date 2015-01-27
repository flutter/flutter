/*
 * Copyright (C) 2006, 2007, 2009, 2010, 2011 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_PAGE_EVENTHANDLER_H_
#define SKY_ENGINE_CORE_PAGE_EVENTHANDLER_H_

#include "sky/engine/core/editing/TextGranularity.h"
#include "sky/engine/core/events/TextEventInputType.h"
#include "sky/engine/core/page/FocusType.h"
#include "sky/engine/core/rendering/HitTestRequest.h"
#include "sky/engine/core/rendering/style/RenderStyleConstants.h"
#include "sky/engine/platform/Cursor.h"
#include "sky/engine/platform/Timer.h"
#include "sky/engine/platform/geometry/LayoutPoint.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/HashTraits.h"
#include "sky/engine/wtf/RefPtr.h"

namespace blink {

class Document;
class Element;
class Event;
class EventTarget;
class FloatPoint;
class FloatQuad;
class HitTestRequest;
class HitTestResult;
class KeyboardEvent;
class LocalFrame;
class Node;
class OptionalCursor;
class RenderLayer;
class RenderObject;
class TextEvent;
class VisibleSelection;
class Widget;

enum AppendTrailingWhitespace { ShouldAppendTrailingWhitespace, DontAppendTrailingWhitespace };
enum CheckDragHysteresis { ShouldCheckDragHysteresis, DontCheckDragHysteresis };

class EventHandler {
    WTF_MAKE_NONCOPYABLE(EventHandler);
public:
    explicit EventHandler(LocalFrame*);
    ~EventHandler();

    void clear();
    void nodeWillBeRemoved(Node&);

    HitTestResult hitTestResultAtPoint(const LayoutPoint&,
        HitTestRequest::HitTestRequestType hitType = HitTestRequest::ReadOnly | HitTestRequest::Active,
        const LayoutSize& padding = LayoutSize());

    void scheduleCursorUpdate();

    void defaultKeyboardEventHandler(KeyboardEvent*);

    bool handleTextInputEvent(const String& text, Event* underlyingEvent = 0, TextEventInputType = TextEventInputKeyboard);
    void defaultTextInputEventHandler(TextEvent*);

    void focusDocumentView();

    void capsLockStateMayHaveChanged(); // Only called by FrameSelection

    bool useHandCursor(Node*, bool isOverLink);

    void notifyElementActivated();

private:
    void selectClosestWordFromHitTestResult(const HitTestResult&, AppendTrailingWhitespace);
    void selectClosestMisspellingFromHitTestResult(const HitTestResult&, AppendTrailingWhitespace);

    OptionalCursor selectCursor(const HitTestResult&);
    OptionalCursor selectAutoCursor(const HitTestResult&, Node*, const Cursor& iBeam);

    void hoverTimerFired(Timer<EventHandler>*);
    void cursorUpdateTimerFired(Timer<EventHandler>*);
    void activeIntervalTimerFired(Timer<EventHandler>*);

    bool isCursorVisible() const;
    void updateCursor();

    TouchAction intersectTouchAction(const TouchAction, const TouchAction);
    TouchAction computeEffectiveTouchAction(const Node&);

    HitTestResult hitTestResultInFrame(LocalFrame*, const LayoutPoint&, HitTestRequest::HitTestRequestType hitType = HitTestRequest::ReadOnly | HitTestRequest::Active);

    void invalidateClick();

    bool dragHysteresisExceeded(const FloatPoint&) const;
    bool dragHysteresisExceeded(const IntPoint&) const;

    void defaultTabEventHandler(KeyboardEvent*);

    bool capturesDragging() const { return m_capturesDragging; }

    LocalFrame* const m_frame;

    bool m_capturesDragging;

    enum SelectionInitiationState { HaveNotStartedSelection, PlacedCaret, ExtendedSelection };
    SelectionInitiationState m_selectionInitiationState;

    LayoutPoint m_dragStartPos;

    Timer<EventHandler> m_cursorUpdateTimer;

    int m_clickCount;
    RefPtr<Node> m_clickNode;

    RefPtr<Node> m_dragTarget;
    bool m_shouldOnlyFireDragOverEvent;

    bool m_didStartDrag;

    Timer<EventHandler> m_activeIntervalTimer;
    double m_lastShowPressTimestamp;
    RefPtr<Element> m_lastDeferredTapElement;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAGE_EVENTHANDLER_H_
