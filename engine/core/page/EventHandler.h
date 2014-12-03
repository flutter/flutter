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
#include "sky/engine/platform/PlatformMouseEvent.h"
#include "sky/engine/platform/Timer.h"
#include "sky/engine/platform/UserGestureIndicator.h"
#include "sky/engine/platform/geometry/LayoutPoint.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/platform/scroll/ScrollTypes.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/HashTraits.h"
#include "sky/engine/wtf/RefPtr.h"

namespace blink {

class AutoscrollController;
class Document;
class Element;
class Event;
class EventTarget;
template <typename EventType>
class EventWithHitTestResults;
class FloatPoint;
class FloatQuad;
class HitTestRequest;
class HitTestResult;
class KeyboardEvent;
class LocalFrame;
class Node;
class OptionalCursor;
class PlatformGestureEvent;
class PlatformKeyboardEvent;
class PlatformTouchEvent;
class PlatformWheelEvent;
class RenderLayer;
class RenderLayerScrollableArea;
class RenderObject;
class ScrollableArea;
class Scrollbar;
class TextEvent;
class TouchEvent;
class VisibleSelection;
class WheelEvent;
class Widget;

typedef EventWithHitTestResults<PlatformGestureEvent> GestureEventWithHitTestResults;
typedef EventWithHitTestResults<PlatformMouseEvent> MouseEventWithHitTestResults;

enum AppendTrailingWhitespace { ShouldAppendTrailingWhitespace, DontAppendTrailingWhitespace };
enum CheckDragHysteresis { ShouldCheckDragHysteresis, DontCheckDragHysteresis };

class EventHandler {
    WTF_MAKE_NONCOPYABLE(EventHandler);
public:
    explicit EventHandler(LocalFrame*);
    ~EventHandler();

    void clear();
    void nodeWillBeRemoved(Node&);

    void updateSelectionForMouseDrag();

    Node* mousePressNode() const;

    void stopAutoscroll();

    void dispatchFakeMouseMoveEventSoon();
    void dispatchFakeMouseMoveEventSoonInQuad(const FloatQuad&);

    HitTestResult hitTestResultAtPoint(const LayoutPoint&,
        HitTestRequest::HitTestRequestType hitType = HitTestRequest::ReadOnly | HitTestRequest::Active,
        const LayoutSize& padding = LayoutSize());

    bool mousePressed() const { return m_mousePressed; }
    void setMousePressed(bool pressed) { m_mousePressed = pressed; }

    void setCapturingMouseEventsNode(PassRefPtr<Node>); // A caller is responsible for resetting capturing node to 0.

    void scheduleHoverStateUpdate();
    void scheduleCursorUpdate();

    IntPoint lastKnownMousePosition() const;
    Cursor currentMouseCursor() const { return m_currentMouseCursor; }

    // Attempts to scroll the DOM tree. If that fails, scrolls the view.
    // If the view can't be scrolled either, recursively bubble to the parent frame.
    bool bubblingScroll(ScrollDirection, ScrollGranularity, Node* startingNode = 0);

    bool handleMouseMoveEvent(const PlatformMouseEvent&);
    void handleMouseLeaveEvent(const PlatformMouseEvent&);

    bool handleMousePressEvent(const PlatformMouseEvent&);
    bool handleMouseReleaseEvent(const PlatformMouseEvent&);
    bool handleWheelEvent(const PlatformWheelEvent&);
    void defaultWheelEventHandler(Node*, WheelEvent*);

    // Called on the local root frame exactly once per gesture event.
    bool handleGestureEvent(const PlatformGestureEvent&);

    // Hit-test the provided (non-scroll) gesture event, applying touch-adjustment and updating
    // hover/active state across all frames if necessary. This should be called at most once
    // per gesture event, and called on the local root frame.
    // Note: This is similar to (the less clearly named) prepareMouseEvent.
    // FIXME: Remove readOnly param when there is only ever a single call to this.
    GestureEventWithHitTestResults targetGestureEvent(const PlatformGestureEvent&, bool readOnly = false);

    // Handle the provided non-scroll gesture event. Should be called only on the inner frame.
    bool handleGestureEventInFrame(const GestureEventWithHitTestResults&);

    // Handle the provided scroll gesture event, propagating down to child frames as necessary.
    bool handleGestureScrollEvent(const PlatformGestureEvent&);
    bool handleGestureScrollEnd(const PlatformGestureEvent&);
    bool isScrollbarHandlingGestures() const;

    void setMouseDownMayStartAutoscroll() { m_mouseDownMayStartAutoscroll = true; }

    static unsigned accessKeyModifiers();
    bool handleAccessKey(const PlatformKeyboardEvent&);
    bool keyEvent(const PlatformKeyboardEvent&);
    void defaultKeyboardEventHandler(KeyboardEvent*);

    bool handleTextInputEvent(const String& text, Event* underlyingEvent = 0, TextEventInputType = TextEventInputKeyboard);
    void defaultTextInputEventHandler(TextEvent*);

    void focusDocumentView();

    void capsLockStateMayHaveChanged(); // Only called by FrameSelection

    bool handleTouchEvent(const PlatformTouchEvent&);

    bool useHandCursor(Node*, bool isOverLink);

    void notifyElementActivated();

    PassRefPtr<UserGestureToken> takeLastMouseDownGestureToken() { return m_lastMouseDownUserGestureToken.release(); }

private:
    bool updateSelectionForMouseDownDispatchingSelectStart(Node*, const VisibleSelection&, TextGranularity);
    void selectClosestWordFromHitTestResult(const HitTestResult&, AppendTrailingWhitespace);
    void selectClosestMisspellingFromHitTestResult(const HitTestResult&, AppendTrailingWhitespace);
    void selectClosestWordFromMouseEvent(const MouseEventWithHitTestResults&);
    void selectClosestMisspellingFromMouseEvent(const MouseEventWithHitTestResults&);
    void selectClosestWordOrLinkFromMouseEvent(const MouseEventWithHitTestResults&);

    bool handleMouseMoveOrLeaveEvent(const PlatformMouseEvent&, HitTestResult* hoveredNode = 0, bool onlyUpdateScrollbars = false);
    bool handleMousePressEvent(const MouseEventWithHitTestResults&);
    bool handleMousePressEventSingleClick(const MouseEventWithHitTestResults&);
    bool handleMousePressEventDoubleClick(const MouseEventWithHitTestResults&);
    bool handleMousePressEventTripleClick(const MouseEventWithHitTestResults&);
    bool handleMouseFocus(const PlatformMouseEvent&);
    bool handleMouseDraggedEvent(const MouseEventWithHitTestResults&);
    bool handleMouseReleaseEvent(const MouseEventWithHitTestResults&);

    bool handlePasteGlobalSelection(const PlatformMouseEvent&);

    HitTestRequest::HitTestRequestType getHitTypeForGestureType(PlatformEvent::Type);

    bool handleGestureTap(const GestureEventWithHitTestResults&);
    bool handleGestureLongPress(const GestureEventWithHitTestResults&);
    bool handleGestureLongTap(const GestureEventWithHitTestResults&);
    bool handleGestureScrollUpdate(const PlatformGestureEvent&);
    bool handleGestureScrollBegin(const PlatformGestureEvent&);
    void clearGestureScrollNodes();

    OptionalCursor selectCursor(const HitTestResult&);
    OptionalCursor selectAutoCursor(const HitTestResult&, Node*, const Cursor& iBeam);

    void hoverTimerFired(Timer<EventHandler>*);
    void cursorUpdateTimerFired(Timer<EventHandler>*);
    void activeIntervalTimerFired(Timer<EventHandler>*);

    bool mouseDownMayStartSelect() const { return m_mouseDownMayStartSelect; }

    void fakeMouseMoveEventTimerFired(Timer<EventHandler>*);
    void cancelFakeMouseMoveEvent();
    bool isCursorVisible() const;
    void updateCursor();

    bool isInsideScrollbar(const IntPoint&) const;

    ScrollableArea* associatedScrollableArea(const RenderLayer*) const;

    // Scrolls the elements of the DOM tree. Returns true if a node was scrolled.
    // False if we reached the root and couldn't scroll anything.
    // direction - The direction to scroll in. If this is a logicl direction, it will be
    //             converted to the physical direction based on a node's writing mode.
    // granularity - The units that the  scroll delta parameter is in.
    // startNode - The node to start bubbling the scroll from. If a node can't scroll,
    //             the scroll bubbles up to the containing block.
    // stopNode - On input, if provided and non-null, the node at which we should stop bubbling on input.
    //            On output, if provided and a node was scrolled stopNode will point to that node.
    // delta - The delta to scroll by, in the units of the granularity parameter. (e.g. pixels, lines, pages, etc.)
    // absolutePoint - For wheel scrolls - the location, in absolute coordinates, where the event occured.
    bool scroll(ScrollDirection, ScrollGranularity, Node* startNode = 0, Node** stopNode = 0, float delta = 1.0f, IntPoint absolutePoint = IntPoint());

    TouchAction intersectTouchAction(const TouchAction, const TouchAction);
    TouchAction computeEffectiveTouchAction(const Node&);

    HitTestResult hitTestResultInFrame(LocalFrame*, const LayoutPoint&, HitTestRequest::HitTestRequestType hitType = HitTestRequest::ReadOnly | HitTestRequest::Active);

    void invalidateClick();

    void updateMouseEventTargetNode(Node*, const PlatformMouseEvent&, bool fireMouseOverOut);

    MouseEventWithHitTestResults prepareMouseEvent(const HitTestRequest&, const PlatformMouseEvent&);

    bool dispatchMouseEvent(const AtomicString& eventType, Node* target, int clickCount, const PlatformMouseEvent&, bool setUnder);

    bool dragHysteresisExceeded(const FloatPoint&) const;
    bool dragHysteresisExceeded(const IntPoint&) const;

    bool passMousePressEventToScrollbar(MouseEventWithHitTestResults&);

    bool passWidgetMouseDownEventToWidget(const MouseEventWithHitTestResults&);

    bool passWheelEventToWidget(const PlatformWheelEvent&, Widget*);
    void defaultTabEventHandler(KeyboardEvent*);

    void updateSelectionForMouseDrag(const HitTestResult&);

    void updateLastScrollbarUnderMouse(Scrollbar*, bool);

    bool capturesDragging() const { return m_capturesDragging; }

    bool handleGestureShowPress();

    bool passScrollGestureEventToWidget(const PlatformGestureEvent&, RenderObject*);
    bool sendScrollEventToView(const PlatformGestureEvent&, const FloatSize&);

    AutoscrollController* autoscrollController() const;
    void setLastKnownMousePosition(const PlatformMouseEvent&);

    LocalFrame* const m_frame;

    bool m_mousePressed;
    bool m_capturesDragging;
    RefPtr<Node> m_mousePressNode;

    bool m_mouseDownMayStartSelect;
    bool m_mouseDownMayStartDrag;
    bool m_mouseDownWasSingleClickInSelection;
    enum SelectionInitiationState { HaveNotStartedSelection, PlacedCaret, ExtendedSelection };
    SelectionInitiationState m_selectionInitiationState;

    LayoutPoint m_dragStartPos;

    Timer<EventHandler> m_hoverTimer;
    Timer<EventHandler> m_cursorUpdateTimer;

    bool m_mouseDownMayStartAutoscroll;

    Timer<EventHandler> m_fakeMouseMoveEventTimer;

    RefPtr<Node> m_capturingMouseEventsNode;
    bool m_eventHandlerWillResetCapturingMouseEventsNode;

    RefPtr<Node> m_nodeUnderMouse;
    RefPtr<Node> m_lastNodeUnderMouse;
    RefPtr<Scrollbar> m_lastScrollbarUnderMouse;
    Cursor m_currentMouseCursor;

    int m_clickCount;
    RefPtr<Node> m_clickNode;

    RefPtr<Node> m_dragTarget;
    bool m_shouldOnlyFireDragOverEvent;

    bool m_mousePositionIsUnknown;
    IntPoint m_lastKnownMousePosition;
    IntPoint m_lastKnownMouseGlobalPosition;
    IntPoint m_mouseDownPos; // In our view's coords.
    double m_mouseDownTimestamp;
    PlatformMouseEvent m_mouseDown;
    RefPtr<UserGestureToken> m_lastMouseDownUserGestureToken;

    RefPtr<Node> m_latchedWheelEventNode;
    bool m_widgetIsLatched;

    RefPtr<Node> m_previousWheelScrolledNode;

    // The target of each active touch point indexed by the touch ID.
    typedef HashMap<unsigned, RefPtr<EventTarget>, DefaultHash<unsigned>::Hash, WTF::UnsignedWithZeroKeyHashTraits<unsigned> > TouchTargetMap;
    TouchTargetMap m_targetForTouchID;

    // If set, the document of the active touch sequence. Unset if no touch sequence active.
    RefPtr<Document> m_touchSequenceDocument;
    RefPtr<UserGestureToken> m_touchSequenceUserGestureToken;

    bool m_touchPressed;

    RefPtr<Node> m_scrollGestureHandlingNode;
    bool m_lastGestureScrollOverWidget;
    RefPtr<Node> m_previousGestureScrolledNode;
    RefPtr<Scrollbar> m_scrollbarHandlingScrollGesture;

    double m_maxMouseMovedDuration;
    bool m_didStartDrag;

    Timer<EventHandler> m_activeIntervalTimer;
    double m_lastShowPressTimestamp;
    RefPtr<Element> m_lastDeferredTapElement;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAGE_EVENTHANDLER_H_
