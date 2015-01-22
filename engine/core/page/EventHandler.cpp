/*
 * Copyright (C) 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Alexey Proskuryakov (ap@webkit.org)
 * Copyright (C) 2012 Digia Plc. and/or its subsidiary(-ies)
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

#include "sky/engine/config.h"
#include "sky/engine/core/page/EventHandler.h"

#include "gen/sky/core/HTMLNames.h"
#include "gen/sky/platform/RuntimeEnabledFeatures.h"
#include "sky/engine/bindings/core/v8/ExceptionStatePlaceholder.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/DocumentMarkerController.h"
#include "sky/engine/core/dom/NodeRenderingTraversal.h"
#include "sky/engine/core/dom/TouchList.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/editing/Editor.h"
#include "sky/engine/core/editing/FrameSelection.h"
#include "sky/engine/core/editing/TextIterator.h"
#include "sky/engine/core/editing/htmlediting.h"
#include "sky/engine/core/events/DOMWindowEventQueue.h"
#include "sky/engine/core/events/EventPath.h"
#include "sky/engine/core/events/KeyboardEvent.h"
#include "sky/engine/core/events/MouseEvent.h"
#include "sky/engine/core/events/TextEvent.h"
#include "sky/engine/core/events/TouchEvent.h"
#include "sky/engine/core/events/WheelEvent.h"
#include "sky/engine/core/fetch/ImageResource.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/core/loader/FrameLoaderClient.h"
#include "sky/engine/core/page/AutoscrollController.h"
#include "sky/engine/core/page/Chrome.h"
#include "sky/engine/core/page/ChromeClient.h"
#include "sky/engine/core/page/EditorClient.h"
#include "sky/engine/core/page/EventWithHitTestResults.h"
#include "sky/engine/core/page/FocusController.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/rendering/HitTestRequest.h"
#include "sky/engine/core/rendering/HitTestResult.h"
#include "sky/engine/core/rendering/RenderLayer.h"
#include "sky/engine/core/rendering/RenderView.h"
#include "sky/engine/core/rendering/style/RenderStyle.h"
#include "sky/engine/platform/PlatformGestureEvent.h"
#include "sky/engine/platform/PlatformKeyboardEvent.h"
#include "sky/engine/platform/PlatformTouchEvent.h"
#include "sky/engine/platform/PlatformWheelEvent.h"
#include "sky/engine/platform/TraceEvent.h"
#include "sky/engine/platform/WindowsKeyboardCodes.h"
#include "sky/engine/platform/geometry/FloatPoint.h"
#include "sky/engine/platform/graphics/Image.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/platform/scroll/ScrollAnimator.h"
#include "sky/engine/platform/scroll/Scrollbar.h"
#include "sky/engine/wtf/Assertions.h"
#include "sky/engine/wtf/CurrentTime.h"
#include "sky/engine/wtf/StdLibExtras.h"
#include "sky/engine/wtf/TemporaryChange.h"

namespace blink {

// The amount of time to wait before sending a fake mouse event, triggered
// during a scroll. The short interval is used if the content responds to the mouse events quickly enough,
// otherwise the long interval is used.
static const double fakeMouseMoveShortInterval = 0.1;
static const double fakeMouseMoveLongInterval = 0.250;

// The amount of time to wait for a cursor update on style and layout changes
// Set to 50Hz, no need to be faster than common screen refresh rate
static const double cursorUpdateInterval = 0.02;

static const int maximumCursorSize = 128;

// It's pretty unlikely that a scale of less than one would ever be used. But all we really
// need to ensure here is that the scale isn't so small that integer overflow can occur when
// dividing cursor sizes (limited above) by the scale.
static const double minimumCursorScale = 0.001;

// The minimum amount of time an element stays active after a ShowPress
// This is roughly 9 frames, which should be long enough to be noticeable.
static const double minimumActiveInterval = 0.15;

enum NoCursorChangeType { NoCursorChange };

class OptionalCursor {
public:
    OptionalCursor(NoCursorChangeType) : m_isCursorChange(false) { }
    OptionalCursor(const Cursor& cursor) : m_isCursorChange(true), m_cursor(cursor) { }

    bool isCursorChange() const { return m_isCursorChange; }
    const Cursor& cursor() const { ASSERT(m_isCursorChange); return m_cursor; }

private:
    bool m_isCursorChange;
    Cursor m_cursor;
};

class MaximumDurationTracker {
public:
    explicit MaximumDurationTracker(double *maxDuration)
        : m_maxDuration(maxDuration)
        , m_start(monotonicallyIncreasingTime())
    {
    }

    ~MaximumDurationTracker()
    {
        *m_maxDuration = max(*m_maxDuration, monotonicallyIncreasingTime() - m_start);
    }

private:
    double* m_maxDuration;
    double m_start;
};

static inline ScrollGranularity wheelGranularityToScrollGranularity(unsigned deltaMode)
{
    switch (deltaMode) {
    case WheelEvent::DOM_DELTA_PAGE:
        return ScrollByPage;
    case WheelEvent::DOM_DELTA_LINE:
        return ScrollByLine;
    case WheelEvent::DOM_DELTA_PIXEL:
        return ScrollByPixel;
    default:
        return ScrollByPixel;
    }
}

EventHandler::EventHandler(LocalFrame* frame)
    : m_frame(frame)
    , m_mousePressed(false)
    , m_capturesDragging(false)
    , m_mouseDownMayStartSelect(false)
    , m_mouseDownMayStartDrag(false)
    , m_mouseDownWasSingleClickInSelection(false)
    , m_selectionInitiationState(HaveNotStartedSelection)
    , m_hoverTimer(this, &EventHandler::hoverTimerFired)
    , m_cursorUpdateTimer(this, &EventHandler::cursorUpdateTimerFired)
    , m_mouseDownMayStartAutoscroll(false)
    , m_fakeMouseMoveEventTimer(this, &EventHandler::fakeMouseMoveEventTimerFired)
    , m_eventHandlerWillResetCapturingMouseEventsNode(0)
    , m_clickCount(0)
    , m_shouldOnlyFireDragOverEvent(false)
    , m_mousePositionIsUnknown(true)
    , m_mouseDownTimestamp(0)
    , m_widgetIsLatched(false)
    , m_touchPressed(false)
    , m_scrollGestureHandlingNode(nullptr)
    , m_lastGestureScrollOverWidget(false)
    , m_maxMouseMovedDuration(0)
    , m_didStartDrag(false)
    , m_activeIntervalTimer(this, &EventHandler::activeIntervalTimerFired)
    , m_lastShowPressTimestamp(0)
{
}

EventHandler::~EventHandler()
{
    ASSERT(!m_fakeMouseMoveEventTimer.isActive());
}

void EventHandler::clear()
{
    m_hoverTimer.stop();
    m_cursorUpdateTimer.stop();
    m_fakeMouseMoveEventTimer.stop();
    m_activeIntervalTimer.stop();
    m_nodeUnderMouse = nullptr;
    m_lastNodeUnderMouse = nullptr;
    m_lastScrollbarUnderMouse = nullptr;
    m_clickCount = 0;
    m_clickNode = nullptr;
    m_dragTarget = nullptr;
    m_shouldOnlyFireDragOverEvent = false;
    m_mousePositionIsUnknown = true;
    m_lastKnownMousePosition = IntPoint();
    m_lastKnownMouseGlobalPosition = IntPoint();
    m_lastMouseDownUserGestureToken.clear();
    m_mousePressNode = nullptr;
    m_mousePressed = false;
    m_capturesDragging = false;
    m_capturingMouseEventsNode = nullptr;
    m_latchedWheelEventNode = nullptr;
    m_previousWheelScrolledNode = nullptr;
    m_targetForTouchID.clear();
    m_touchSequenceDocument.clear();
    m_touchSequenceUserGestureToken.clear();
    m_scrollGestureHandlingNode = nullptr;
    m_lastGestureScrollOverWidget = false;
    m_previousGestureScrolledNode = nullptr;
    m_scrollbarHandlingScrollGesture = nullptr;
    m_maxMouseMovedDuration = 0;
    m_didStartDrag = false;
    m_touchPressed = false;
    m_mouseDownMayStartSelect = false;
    m_mouseDownMayStartDrag = false;
    m_lastShowPressTimestamp = 0;
    m_lastDeferredTapElement = nullptr;
}

void EventHandler::nodeWillBeRemoved(Node& nodeToBeRemoved)
{
    if (!nodeToBeRemoved.containsIncludingShadowDOM(m_clickNode.get()))
        return;
    if (nodeToBeRemoved.isInShadowTree()) {
        m_clickNode = nodeToBeRemoved.parentOrShadowHostNode();
    } else {
        // We don't dispatch click events if the mousedown node is removed
        // before a mouseup event. It is compatible with IE and Firefox.
        m_clickNode = nullptr;
    }
}

static void setSelectionIfNeeded(FrameSelection& selection, const VisibleSelection& newSelection)
{
    if (selection.selection() != newSelection)
        selection.setSelection(newSelection);
}

static inline bool dispatchSelectStart(Node* node)
{
    if (!node || !node->renderer())
        return true;

    return node->dispatchEvent(Event::createCancelableBubble(EventTypeNames::selectstart));
}

static VisibleSelection expandSelectionToRespectUserSelectAll(Node* targetNode, const VisibleSelection& selection)
{
    Node* rootUserSelectAll = Position::rootUserSelectAllForNode(targetNode);
    if (!rootUserSelectAll)
        return selection;

    VisibleSelection newSelection(selection);
    newSelection.setBase(positionBeforeNode(rootUserSelectAll).upstream(CanCrossEditingBoundary));
    newSelection.setExtent(positionAfterNode(rootUserSelectAll).downstream(CanCrossEditingBoundary));

    return newSelection;
}

bool EventHandler::updateSelectionForMouseDownDispatchingSelectStart(Node* targetNode, const VisibleSelection& selection, TextGranularity granularity)
{
    if (Position::nodeIsUserSelectNone(targetNode))
        return false;

    if (!dispatchSelectStart(targetNode))
        return false;

    if (selection.isRange())
        m_selectionInitiationState = ExtendedSelection;
    else {
        granularity = CharacterGranularity;
        m_selectionInitiationState = PlacedCaret;
    }

    m_frame->selection().setNonDirectionalSelectionIfNeeded(selection, granularity);

    return true;
}

void EventHandler::selectClosestWordFromHitTestResult(const HitTestResult& result, AppendTrailingWhitespace appendTrailingWhitespace)
{
    Node* innerNode = result.targetNode();
    VisibleSelection newSelection;

    if (innerNode && innerNode->renderer()) {
        VisiblePosition pos(innerNode->renderer()->positionForPoint(result.localPoint()));
        if (pos.isNotNull()) {
            newSelection = VisibleSelection(pos);
            newSelection.expandUsingGranularity(WordGranularity);
        }

        if (appendTrailingWhitespace == ShouldAppendTrailingWhitespace && newSelection.isRange())
            newSelection.appendTrailingWhitespace();

        updateSelectionForMouseDownDispatchingSelectStart(innerNode, expandSelectionToRespectUserSelectAll(innerNode, newSelection), WordGranularity);
    }
}

void EventHandler::selectClosestMisspellingFromHitTestResult(const HitTestResult& result, AppendTrailingWhitespace appendTrailingWhitespace)
{
    Node* innerNode = result.targetNode();
    VisibleSelection newSelection;

    if (innerNode && innerNode->renderer()) {
        VisiblePosition pos(innerNode->renderer()->positionForPoint(result.localPoint()));
        Position start = pos.deepEquivalent();
        Position end = pos.deepEquivalent();
        if (pos.isNotNull()) {
            DocumentMarkerVector markers = innerNode->document().markers().markersInRange(makeRange(pos, pos).get(), DocumentMarker::MisspellingMarkers());
            if (markers.size() == 1) {
                start.moveToOffset(markers[0]->startOffset());
                end.moveToOffset(markers[0]->endOffset());
                newSelection = VisibleSelection(start, end);
            }
        }

        if (appendTrailingWhitespace == ShouldAppendTrailingWhitespace && newSelection.isRange())
            newSelection.appendTrailingWhitespace();

        updateSelectionForMouseDownDispatchingSelectStart(innerNode, expandSelectionToRespectUserSelectAll(innerNode, newSelection), WordGranularity);
    }
}

void EventHandler::selectClosestWordFromMouseEvent(const MouseEventWithHitTestResults& result)
{
    if (m_mouseDownMayStartSelect) {
        selectClosestWordFromHitTestResult(result.hitTestResult(), DontAppendTrailingWhitespace);
    }
}

void EventHandler::selectClosestMisspellingFromMouseEvent(const MouseEventWithHitTestResults& result)
{
    if (m_mouseDownMayStartSelect) {
        selectClosestMisspellingFromHitTestResult(result.hitTestResult(), DontAppendTrailingWhitespace);
    }
}

void EventHandler::selectClosestWordOrLinkFromMouseEvent(const MouseEventWithHitTestResults& result)
{
    if (!result.hitTestResult().isLiveLink())
        return selectClosestWordFromMouseEvent(result);

    Node* innerNode = result.targetNode();

    if (innerNode && innerNode->renderer() && m_mouseDownMayStartSelect) {
        VisibleSelection newSelection;
        Element* URLElement = result.hitTestResult().URLElement();
        VisiblePosition pos(innerNode->renderer()->positionForPoint(result.localPoint()));
        if (pos.isNotNull() && pos.deepEquivalent().deprecatedNode()->isDescendantOf(URLElement))
            newSelection = VisibleSelection::selectionFromContentsOfNode(URLElement);

        updateSelectionForMouseDownDispatchingSelectStart(innerNode, expandSelectionToRespectUserSelectAll(innerNode, newSelection), WordGranularity);
    }
}

bool EventHandler::handleMousePressEventDoubleClick(const MouseEventWithHitTestResults& event)
{
    TRACE_EVENT0("blink", "EventHandler::handleMousePressEventDoubleClick");

    if (event.event().button() != LeftButton)
        return false;

    if (m_frame->selection().isRange()) {
        // A double-click when range is already selected
        // should not change the selection.  So, do not call
        // selectClosestWordFromMouseEvent, but do set
        // m_beganSelectingText to prevent handleMouseReleaseEvent
        // from setting caret selection.
        m_selectionInitiationState = ExtendedSelection;
    } else {
        selectClosestWordFromMouseEvent(event);
    }
    return true;
}

bool EventHandler::handleMousePressEventTripleClick(const MouseEventWithHitTestResults& event)
{
    TRACE_EVENT0("blink", "EventHandler::handleMousePressEventTripleClick");

    if (event.event().button() != LeftButton)
        return false;

    Node* innerNode = event.targetNode();
    if (!(innerNode && innerNode->renderer() && m_mouseDownMayStartSelect))
        return false;

    VisibleSelection newSelection;
    VisiblePosition pos(innerNode->renderer()->positionForPoint(event.localPoint()));
    if (pos.isNotNull()) {
        newSelection = VisibleSelection(pos);
        newSelection.expandUsingGranularity(ParagraphGranularity);
    }

    return updateSelectionForMouseDownDispatchingSelectStart(innerNode, expandSelectionToRespectUserSelectAll(innerNode, newSelection), ParagraphGranularity);
}

static int textDistance(const Position& start, const Position& end)
{
    RefPtr<Range> range = Range::create(*start.document(), start, end);
    return TextIterator::rangeLength(range.get(), true);
}

bool EventHandler::handleMousePressEventSingleClick(const MouseEventWithHitTestResults& event)
{
    TRACE_EVENT0("blink", "EventHandler::handleMousePressEventSingleClick");

    m_frame->document()->updateLayout();
    Node* innerNode = event.targetNode();
    if (!(innerNode && innerNode->renderer() && m_mouseDownMayStartSelect))
        return false;

    // Extend the selection if the Shift key is down, unless the click is in a link.
    bool extendSelection = event.event().shiftKey() && !event.isOverLink();

    // Don't restart the selection when the mouse is pressed on an
    // existing selection so we can allow for text dragging.
    LayoutPoint vPoint = event.event().position();
    if (!extendSelection && m_frame->selection().contains(vPoint)) {
        m_mouseDownWasSingleClickInSelection = true;
        return false;
    }

    VisiblePosition visiblePos(innerNode->renderer()->positionForPoint(event.localPoint()));
    if (visiblePos.isNull())
        visiblePos = VisiblePosition(firstPositionInOrBeforeNode(innerNode), DOWNSTREAM);
    Position pos = visiblePos.deepEquivalent();

    VisibleSelection newSelection = m_frame->selection().selection();
    TextGranularity granularity = CharacterGranularity;

    if (extendSelection && newSelection.isCaretOrRange()) {
        VisibleSelection selectionInUserSelectAll(expandSelectionToRespectUserSelectAll(innerNode, VisibleSelection(VisiblePosition(pos))));
        if (selectionInUserSelectAll.isRange()) {
            if (comparePositions(selectionInUserSelectAll.start(), newSelection.start()) < 0)
                pos = selectionInUserSelectAll.start();
            else if (comparePositions(newSelection.end(), selectionInUserSelectAll.end()) < 0)
                pos = selectionInUserSelectAll.end();
        }

        if (!m_frame->editor().behavior().shouldConsiderSelectionAsDirectional()) {
            if (pos.isNotNull()) {
                // See <rdar://problem/3668157> REGRESSION (Mail): shift-click deselects when selection
                // was created right-to-left
                Position start = newSelection.start();
                Position end = newSelection.end();
                int distanceToStart = textDistance(start, pos);
                int distanceToEnd = textDistance(pos, end);
                if (distanceToStart <= distanceToEnd)
                    newSelection = VisibleSelection(end, pos);
                else
                    newSelection = VisibleSelection(start, pos);
            }
        } else
            newSelection.setExtent(pos);

        if (m_frame->selection().granularity() != CharacterGranularity) {
            granularity = m_frame->selection().granularity();
            newSelection.expandUsingGranularity(m_frame->selection().granularity());
        }
    } else {
        newSelection = expandSelectionToRespectUserSelectAll(innerNode, VisibleSelection(visiblePos));
    }

    // Updating the selection is considered side-effect of the event and so it doesn't impact the handled state.
    updateSelectionForMouseDownDispatchingSelectStart(innerNode, newSelection, granularity);
    return false;
}

static inline bool canMouseDownStartSelect(Node* node)
{
    if (!node || !node->renderer())
        return true;

    if (!node->canStartSelection())
        return false;

    return true;
}

bool EventHandler::handleMousePressEvent(const MouseEventWithHitTestResults& event)
{
    TRACE_EVENT0("blink", "EventHandler::handleMousePressEvent");

    cancelFakeMouseMoveEvent();

    m_frame->document()->updateLayout();

    bool singleClick = event.event().clickCount() <= 1;

    // If we got the event back, that must mean it wasn't prevented,
    // so it's allowed to start a drag or selection if it wasn't in a scrollbar.
    m_mouseDownMayStartSelect = canMouseDownStartSelect(event.targetNode()) && !event.scrollbar();

    m_mouseDownMayStartDrag = singleClick;

    m_mouseDownWasSingleClickInSelection = false;

    m_mouseDown = event.event();

    if (event.isOverWidget() && passWidgetMouseDownEventToWidget(event))
        return true;

    // We don't do this at the start of mouse down handling,
    // because we don't want to do it until we know we didn't hit a widget.
    if (singleClick)
        focusDocumentView();

    Node* innerNode = event.targetNode();

    m_mousePressNode = innerNode;
    m_dragStartPos = event.event().position();

    bool swallowEvent = false;
    m_mousePressed = true;
    m_selectionInitiationState = HaveNotStartedSelection;

    if (event.event().clickCount() == 2)
        swallowEvent = handleMousePressEventDoubleClick(event);
    else if (event.event().clickCount() >= 3)
        swallowEvent = handleMousePressEventTripleClick(event);
    else
        swallowEvent = handleMousePressEventSingleClick(event);

    m_mouseDownMayStartAutoscroll = m_mouseDownMayStartSelect
        || (m_mousePressNode && m_mousePressNode->renderBox() && m_mousePressNode->renderBox()->canBeProgramaticallyScrolled());

    return swallowEvent;
}

bool EventHandler::handleMouseDraggedEvent(const MouseEventWithHitTestResults& event)
{
    TRACE_EVENT0("blink", "EventHandler::handleMouseDraggedEvent");

    if (!m_mousePressed)
        return false;

    Node* targetNode = event.targetNode();
    if (event.event().button() != LeftButton || !targetNode)
        return false;

    RenderObject* renderer = targetNode->renderer();
    if (!renderer) {
        Node* parent = NodeRenderingTraversal::parent(targetNode);
        if (!parent)
            return false;

        renderer = parent->renderer();
        if (!renderer)
            return false;
    }

    m_mouseDownMayStartDrag = false;

    if (m_mouseDownMayStartAutoscroll) {
        if (AutoscrollController* controller = autoscrollController()) {
            controller->startAutoscrollForSelection(renderer);
            m_mouseDownMayStartAutoscroll = false;
        }
    }

    if (m_selectionInitiationState != ExtendedSelection) {
        HitTestRequest request(HitTestRequest::ReadOnly | HitTestRequest::Active);
        HitTestResult result(m_mouseDownPos);
        m_frame->document()->renderView()->hitTest(request, result);

        updateSelectionForMouseDrag(result);
    }
    updateSelectionForMouseDrag(event.hitTestResult());
    return true;
}

void EventHandler::updateSelectionForMouseDrag()
{
    FrameView* view = m_frame->view();
    if (!view)
        return;
    RenderView* renderer = m_frame->contentRenderer();
    if (!renderer)
        return;

    HitTestRequest request(HitTestRequest::ReadOnly | HitTestRequest::Active | HitTestRequest::Move);
    HitTestResult result(m_lastKnownMousePosition);
    renderer->hitTest(request, result);
    updateSelectionForMouseDrag(result);
}

void EventHandler::updateSelectionForMouseDrag(const HitTestResult& hitTestResult)
{
    if (!m_mouseDownMayStartSelect)
        return;

    Node* target = hitTestResult.targetNode();
    if (!target)
        return;

    VisiblePosition targetPosition = m_frame->selection().selection().visiblePositionRespectingEditingBoundary(hitTestResult.localPoint(), target);
    // Don't modify the selection if we're not on a node.
    if (targetPosition.isNull())
        return;

    // Restart the selection if this is the first mouse move. This work is usually
    // done in handleMousePressEvent, but not if the mouse press was on an existing selection.
    VisibleSelection newSelection = m_frame->selection().selection();

    if (m_selectionInitiationState == HaveNotStartedSelection && !dispatchSelectStart(target))
        return;

    if (m_selectionInitiationState != ExtendedSelection) {
        // Always extend selection here because it's caused by a mouse drag
        m_selectionInitiationState = ExtendedSelection;
        newSelection = VisibleSelection(targetPosition);
    }

    if (RuntimeEnabledFeatures::userSelectAllEnabled()) {
        Node* rootUserSelectAllForMousePressNode = Position::rootUserSelectAllForNode(m_mousePressNode.get());
        if (rootUserSelectAllForMousePressNode && rootUserSelectAllForMousePressNode == Position::rootUserSelectAllForNode(target)) {
            newSelection.setBase(positionBeforeNode(rootUserSelectAllForMousePressNode).upstream(CanCrossEditingBoundary));
            newSelection.setExtent(positionAfterNode(rootUserSelectAllForMousePressNode).downstream(CanCrossEditingBoundary));
        } else {
            // Reset base for user select all when base is inside user-select-all area and extent < base.
            if (rootUserSelectAllForMousePressNode && comparePositions(target->renderer()->positionForPoint(hitTestResult.localPoint()), m_mousePressNode->renderer()->positionForPoint(m_dragStartPos)) < 0)
                newSelection.setBase(positionAfterNode(rootUserSelectAllForMousePressNode).downstream(CanCrossEditingBoundary));

            Node* rootUserSelectAllForTarget = Position::rootUserSelectAllForNode(target);
            if (rootUserSelectAllForTarget && m_mousePressNode->renderer() && comparePositions(target->renderer()->positionForPoint(hitTestResult.localPoint()), m_mousePressNode->renderer()->positionForPoint(m_dragStartPos)) < 0)
                newSelection.setExtent(positionBeforeNode(rootUserSelectAllForTarget).upstream(CanCrossEditingBoundary));
            else if (rootUserSelectAllForTarget && m_mousePressNode->renderer())
                newSelection.setExtent(positionAfterNode(rootUserSelectAllForTarget).downstream(CanCrossEditingBoundary));
            else
                newSelection.setExtent(targetPosition);
        }
    } else {
        newSelection.setExtent(targetPosition);
    }

    if (m_frame->selection().granularity() != CharacterGranularity)
        newSelection.expandUsingGranularity(m_frame->selection().granularity());

    m_frame->selection().setNonDirectionalSelectionIfNeeded(newSelection, m_frame->selection().granularity(),
        FrameSelection::AdjustEndpointsAtBidiBoundary);
}

bool EventHandler::handleMouseReleaseEvent(const MouseEventWithHitTestResults& event)
{
    AutoscrollController* controller = autoscrollController();
    if (controller && controller->autoscrollInProgress())
        stopAutoscroll();

    // Used to prevent mouseMoveEvent from initiating a drag before
    // the mouse is pressed again.
    m_mousePressed = false;
    m_capturesDragging = false;
    m_mouseDownMayStartDrag = false;
    m_mouseDownMayStartSelect = false;
    m_mouseDownMayStartAutoscroll = false;

    bool handled = false;

    // Clear the selection if the mouse didn't move after the last mouse
    // press and it's not a context menu click.  We do this so when clicking
    // on the selection, the selection goes away.  However, if we are
    // editing, place the caret.
    if (m_mouseDownWasSingleClickInSelection && m_selectionInitiationState != ExtendedSelection
            && m_dragStartPos == event.event().position()
            && m_frame->selection().isRange()
            && event.event().button() != RightButton) {
        VisibleSelection newSelection;
        Node* node = event.targetNode();
        if (node && node->renderer() && node->hasEditableStyle()) {
            VisiblePosition pos = VisiblePosition(node->renderer()->positionForPoint(event.localPoint()));
            newSelection = VisibleSelection(pos);
        }

        setSelectionIfNeeded(m_frame->selection(), newSelection);

        handled = true;
    }

    m_frame->selection().notifyRendererOfSelectionChange(UserTriggered);

    m_frame->selection().selectFrameElementInParentIfFullySelected();

    if (event.event().button() == MiddleButton && !event.isOverLink()) {
        // Ignore handled, since we want to paste to where the caret was placed anyway.
        handled = handlePasteGlobalSelection(event.event()) || handled;
    }

    return handled;
}

AutoscrollController* EventHandler::autoscrollController() const
{
    if (Page* page = m_frame->page())
        return &page->autoscrollController();
    return 0;
}

HitTestResult EventHandler::hitTestResultAtPoint(const LayoutPoint& point, HitTestRequest::HitTestRequestType hitType, const LayoutSize& padding)
{
    TRACE_EVENT0("blink", "EventHandler::hitTestResultAtPoint");

    HitTestResult result(point, padding.height(), padding.width(), padding.height(), padding.width());

    // RenderView::hitTest causes a layout, and we don't want to hit that until the first
    // layout because until then, there is nothing shown on the screen - the user can't
    // have intentionally clicked on something belonging to this page. Furthermore,
    // mousemove events before the first layout should not lead to a premature layout()
    // happening, which could show a flash of white.
    // See also the similar code in Document::prepareMouseEvent.
    if (!m_frame->contentRenderer() || !m_frame->view() || !m_frame->view()->didFirstLayout())
        return result;

    // hitTestResultAtPoint is specifically used to hitTest into all frames, thus it always allows child frame content.
    HitTestRequest request(hitType);
    m_frame->contentRenderer()->hitTest(request, result);
    if (!request.readOnly())
        m_frame->document()->updateHoverActiveState(request, result.innerElement());

    return result;
}

void EventHandler::stopAutoscroll()
{
    if (AutoscrollController* controller = autoscrollController())
        controller->stopAutoscroll();
}

Node* EventHandler::mousePressNode() const
{
    return m_mousePressNode.get();
}

bool EventHandler::scroll(ScrollDirection direction, ScrollGranularity granularity, Node* startNode, Node** stopNode, float delta, IntPoint absolutePoint)
{
    if (!delta)
        return false;

    Node* node = startNode;

    if (!node)
        node = m_frame->document()->focusedElement();

    if (!node)
        node = m_mousePressNode.get();

    if (!node || !node->renderer())
        return false;

    RenderBox* curBox = node->renderer()->enclosingBox();
    while (curBox && !curBox->isRenderView()) {
        // If we're at the stopNode, we should try to scroll it but we shouldn't bubble past it
        bool shouldStopBubbling = stopNode && *stopNode && curBox->node() == *stopNode;
        bool didScroll = curBox->scroll(direction, granularity, delta);

        if (didScroll && stopNode)
            *stopNode = curBox->node();

        if (didScroll || shouldStopBubbling) {
            return true;
        }

        curBox = curBox->containingBlock();
    }

    return false;
}

bool EventHandler::bubblingScroll(ScrollDirection direction, ScrollGranularity granularity, Node* startingNode)
{
    // The layout needs to be up to date to determine if we can scroll. We may be
    // here because of an onLoad event, in which case the final layout hasn't been performed yet.
    m_frame->document()->updateLayout();
    if (scroll(direction, granularity, startingNode))
        return true;
    return false;
}

IntPoint EventHandler::lastKnownMousePosition() const
{
    return m_lastKnownMousePosition;
}

bool EventHandler::useHandCursor(Node* node, bool isOverLink)
{
    if (!node)
        return false;

    return isOverLink && !node->hasEditableStyle();
}

void EventHandler::cursorUpdateTimerFired(Timer<EventHandler>*)
{
    ASSERT(m_frame);
    ASSERT(m_frame->document());

    updateCursor();
}

void EventHandler::updateCursor()
{
    if (m_mousePositionIsUnknown)
        return;

    FrameView* view = m_frame->view();
    if (!view || !view->shouldSetCursor())
        return;

    RenderView* renderView = view->renderView();
    if (!renderView)
        return;

    m_frame->document()->updateLayout();

    HitTestRequest request(HitTestRequest::ReadOnly);
    HitTestResult result(m_lastKnownMousePosition);
    renderView->hitTest(request, result);

    OptionalCursor optionalCursor = selectCursor(result);
    if (optionalCursor.isCursorChange()) {
        m_currentMouseCursor = optionalCursor.cursor();
        view->setCursor(m_currentMouseCursor);
    }
}

OptionalCursor EventHandler::selectCursor(const HitTestResult& result)
{
    Page* page = m_frame->page();
    if (!page)
        return NoCursorChange;

    Node* node = result.innerPossiblyPseudoNode();
    if (!node)
        return selectAutoCursor(result, node, iBeamCursor());

    RenderObject* renderer = node->renderer();
    RenderStyle* style = renderer ? renderer->style() : 0;

    if (renderer) {
        Cursor overrideCursor;
        switch (renderer->getCursor(roundedIntPoint(result.localPoint()), overrideCursor)) {
        case SetCursorBasedOnStyle:
            break;
        case SetCursor:
            return overrideCursor;
        case DoNotSetCursor:
            return NoCursorChange;
        }
    }

    if (style && style->cursors()) {
        const CursorList* cursors = style->cursors();
        for (unsigned i = 0; i < cursors->size(); ++i) {
            StyleImage* styleImage = (*cursors)[i].image();
            if (!styleImage)
                continue;
            ImageResource* cachedImage = styleImage->cachedImage();
            if (!cachedImage)
                continue;
            float scale = styleImage->imageScaleFactor();
            // Get hotspot and convert from logical pixels to physical pixels.
            IntPoint hotSpot = (*cursors)[i].hotSpot();
            hotSpot.scale(scale, scale);
            IntSize size = cachedImage->imageForRenderer(renderer)->size();
            if (cachedImage->errorOccurred())
                continue;
            // Limit the size of cursors (in UI pixels) so that they cannot be
            // used to cover UI elements in chrome.
            size.scale(1 / scale);
            if (size.width() > maximumCursorSize || size.height() > maximumCursorSize)
                continue;

            Image* image = cachedImage->imageForRenderer(renderer);
            // Ensure no overflow possible in calculations above.
            if (scale < minimumCursorScale)
                continue;
            return Cursor(image, hotSpot, scale);
        }
    }

    switch (style ? style->cursor() : CURSOR_AUTO) {
    case CURSOR_AUTO: {
        const Cursor& iBeam = iBeamCursor();
        return selectAutoCursor(result, node, iBeam);
    }
    case CURSOR_CROSS:
        return crossCursor();
    case CURSOR_POINTER:
        return handCursor();
    case CURSOR_MOVE:
        return moveCursor();
    case CURSOR_ALL_SCROLL:
        return moveCursor();
    case CURSOR_E_RESIZE:
        return eastResizeCursor();
    case CURSOR_W_RESIZE:
        return westResizeCursor();
    case CURSOR_N_RESIZE:
        return northResizeCursor();
    case CURSOR_S_RESIZE:
        return southResizeCursor();
    case CURSOR_NE_RESIZE:
        return northEastResizeCursor();
    case CURSOR_SW_RESIZE:
        return southWestResizeCursor();
    case CURSOR_NW_RESIZE:
        return northWestResizeCursor();
    case CURSOR_SE_RESIZE:
        return southEastResizeCursor();
    case CURSOR_NS_RESIZE:
        return northSouthResizeCursor();
    case CURSOR_EW_RESIZE:
        return eastWestResizeCursor();
    case CURSOR_NESW_RESIZE:
        return northEastSouthWestResizeCursor();
    case CURSOR_NWSE_RESIZE:
        return northWestSouthEastResizeCursor();
    case CURSOR_COL_RESIZE:
        return columnResizeCursor();
    case CURSOR_ROW_RESIZE:
        return rowResizeCursor();
    case CURSOR_TEXT:
        return iBeamCursor();
    case CURSOR_WAIT:
        return waitCursor();
    case CURSOR_HELP:
        return helpCursor();
    case CURSOR_VERTICAL_TEXT:
        return verticalTextCursor();
    case CURSOR_CELL:
        return cellCursor();
    case CURSOR_CONTEXT_MENU:
        return contextMenuCursor();
    case CURSOR_PROGRESS:
        return progressCursor();
    case CURSOR_NO_DROP:
        return noDropCursor();
    case CURSOR_ALIAS:
        return aliasCursor();
    case CURSOR_COPY:
        return copyCursor();
    case CURSOR_NONE:
        return noneCursor();
    case CURSOR_NOT_ALLOWED:
        return notAllowedCursor();
    case CURSOR_DEFAULT:
        return pointerCursor();
    case CURSOR_ZOOM_IN:
        return zoomInCursor();
    case CURSOR_ZOOM_OUT:
        return zoomOutCursor();
    case CURSOR_WEBKIT_GRAB:
        return grabCursor();
    case CURSOR_WEBKIT_GRABBING:
        return grabbingCursor();
    }
    return pointerCursor();
}

OptionalCursor EventHandler::selectAutoCursor(const HitTestResult& result, Node* node, const Cursor& iBeam)
{
    bool editable = (node && node->hasEditableStyle());

    if (useHandCursor(node, result.isOverLink()))
        return handCursor();

    // During selection, use an I-beam no matter what we're over.
    // If a drag may be starting or we're capturing mouse events for a particular node, don't treat this as a selection.
    if (m_mousePressed && m_mouseDownMayStartSelect
        && !m_mouseDownMayStartDrag
        && m_frame->selection().isCaretOrRange()
        && !m_capturingMouseEventsNode) {
        return iBeam;
    }

    RenderObject* renderer = node ? node->renderer() : 0;
    if ((editable || (renderer && renderer->isText() && node->canStartSelection())) && !result.scrollbar())
        return iBeam;
    return pointerCursor();
}

static LayoutPoint documentPointForWindowPoint(LocalFrame* frame, const IntPoint& windowPoint)
{
    // FIXME(sky): remove
    return windowPoint;
}

bool EventHandler::handleMousePressEvent(const PlatformMouseEvent& mouseEvent)
{
    TRACE_EVENT0("blink", "EventHandler::handleMousePressEvent");

    RefPtr<FrameView> protector(m_frame->view());

    UserGestureIndicator gestureIndicator(DefinitelyProcessingUserGesture);
    m_frame->eventHandler().m_lastMouseDownUserGestureToken = gestureIndicator.currentToken();

    cancelFakeMouseMoveEvent();
    if (m_eventHandlerWillResetCapturingMouseEventsNode)
        m_capturingMouseEventsNode = nullptr;
    m_mousePressed = true;
    m_capturesDragging = true;
    setLastKnownMousePosition(mouseEvent);
    m_mouseDownTimestamp = mouseEvent.timestamp();
    m_mouseDownMayStartDrag = false;
    m_mouseDownMayStartSelect = false;
    m_mouseDownMayStartAutoscroll = false;
    if (m_frame->view())
        m_mouseDownPos = mouseEvent.position();
    else {
        // FIXME(sky): Why do we have this else block at all?
        invalidateClick();
        return false;
    }

    // Mouse events simulated from touch should not hit-test again.
    ASSERT(!mouseEvent.fromTouch());

    HitTestRequest request(HitTestRequest::Active);
    // Save the document point we generate in case the window coordinate is invalidated by what happens
    // when we dispatch the event.
    LayoutPoint documentPoint = documentPointForWindowPoint(m_frame, mouseEvent.position());
    MouseEventWithHitTestResults mev = m_frame->document()->prepareMouseEvent(request, documentPoint, mouseEvent);

    if (!mev.targetNode()) {
        invalidateClick();
        return false;
    }

    m_mousePressNode = mev.targetNode();

    m_clickCount = mouseEvent.clickCount();
    m_clickNode = mev.targetNode()->isTextNode() ?  NodeRenderingTraversal::parent(mev.targetNode()) : mev.targetNode();

    m_frame->selection().setCaretBlinkingSuspended(true);

    bool swallowEvent = !dispatchMouseEvent(EventTypeNames::mousedown, mev.targetNode(), m_clickCount, mouseEvent, true);
    swallowEvent = swallowEvent || handleMouseFocus(mouseEvent);
    m_capturesDragging = !swallowEvent || mev.scrollbar();

    // If the hit testing originally determined the event was in a scrollbar, refetch the MouseEventWithHitTestResults
    // in case the scrollbar widget was destroyed when the mouse event was handled.
    if (mev.scrollbar()) {
        const bool wasLastScrollBar = mev.scrollbar() == m_lastScrollbarUnderMouse.get();
        HitTestRequest request(HitTestRequest::ReadOnly | HitTestRequest::Active);
        mev = m_frame->document()->prepareMouseEvent(request, documentPoint, mouseEvent);
        if (wasLastScrollBar && mev.scrollbar() != m_lastScrollbarUnderMouse.get())
            m_lastScrollbarUnderMouse = nullptr;
    }

    if (swallowEvent) {
        // scrollbars should get events anyway, even disabled controls might be scrollable
        passMousePressEventToScrollbar(mev);
    } else {
        if (passMousePressEventToScrollbar(mev))
            swallowEvent = true;
        else
            swallowEvent = handleMousePressEvent(mev);
    }

    return swallowEvent;
}

static RenderLayer* layerForNode(Node* node)
{
    if (!node)
        return 0;

    RenderObject* renderer = node->renderer();
    if (!renderer)
        return 0;

    RenderLayer* layer = renderer->enclosingLayer();
    if (!layer)
        return 0;

    return layer;
}

ScrollableArea* EventHandler::associatedScrollableArea(const RenderLayer* layer) const
{
    if (RenderLayerScrollableArea* scrollableArea = layer->scrollableArea()) {
        if (scrollableArea->scrollsOverflow())
            return scrollableArea;
    }

    return 0;
}

bool EventHandler::handleMouseMoveEvent(const PlatformMouseEvent& event)
{
    TRACE_EVENT0("blink", "EventHandler::handleMouseMoveEvent");

    RefPtr<FrameView> protector(m_frame->view());
    MaximumDurationTracker maxDurationTracker(&m_maxMouseMovedDuration);

    HitTestResult hoveredNode = HitTestResult(LayoutPoint());
    bool result = handleMouseMoveOrLeaveEvent(event, &hoveredNode);

    Page* page = m_frame->page();
    if (!page)
        return result;

    if (RenderLayer* layer = layerForNode(hoveredNode.innerNode())) {
        if (ScrollableArea* layerScrollableArea = associatedScrollableArea(layer))
            layerScrollableArea->mouseMovedInContentArea();
    }

    page->chrome().mouseDidMoveOverElement(hoveredNode, event.modifierFlags());

    return result;
}

void EventHandler::handleMouseLeaveEvent(const PlatformMouseEvent& event)
{
    TRACE_EVENT0("blink", "EventHandler::handleMouseLeaveEvent");

    RefPtr<FrameView> protector(m_frame->view());
    handleMouseMoveOrLeaveEvent(event);
}

bool EventHandler::handleMouseMoveOrLeaveEvent(const PlatformMouseEvent& mouseEvent, HitTestResult* hoveredNode, bool onlyUpdateScrollbars)
{
    ASSERT(m_frame);
    ASSERT(m_frame->view());

    setLastKnownMousePosition(mouseEvent);

    if (m_hoverTimer.isActive())
        m_hoverTimer.stop();

    m_cursorUpdateTimer.stop();

    cancelFakeMouseMoveEvent();

    // Send events right to a scrollbar if the mouse is pressed.
    if (m_lastScrollbarUnderMouse && m_mousePressed) {
        m_lastScrollbarUnderMouse->mouseMoved(mouseEvent);
        return true;
    }

    // Mouse events simulated from touch should not hit-test again.
    ASSERT(!mouseEvent.fromTouch());

    HitTestRequest::HitTestRequestType hitType = HitTestRequest::Move;
    if (m_mousePressed)
        hitType |= HitTestRequest::Active;
    else if (onlyUpdateScrollbars) {
        // Mouse events should be treated as "read-only" if we're updating only scrollbars. This
        // means that :hover and :active freeze in the state they were in, rather than updating
        // for nodes the mouse moves while the window is not key (which will be the case if
        // onlyUpdateScrollbars is true).
        hitType |= HitTestRequest::ReadOnly;
    }

    // Treat any mouse move events as readonly if the user is currently touching the screen.
    if (m_touchPressed)
        hitType |= HitTestRequest::Active | HitTestRequest::ReadOnly;
    HitTestRequest request(hitType);
    MouseEventWithHitTestResults mev = prepareMouseEvent(request, mouseEvent);
    if (hoveredNode)
        *hoveredNode = mev.hitTestResult();

    Scrollbar* scrollbar = mev.scrollbar();
    updateLastScrollbarUnderMouse(scrollbar, !m_mousePressed);
    if (onlyUpdateScrollbars)
        return true;

    bool swallowEvent = false;

    if (scrollbar && !m_mousePressed)
        scrollbar->mouseMoved(mouseEvent); // Handle hover effects on platforms that support visual feedback on scrollbar hovering.
    if (FrameView* view = m_frame->view()) {
        OptionalCursor optionalCursor = selectCursor(mev.hitTestResult());
        if (optionalCursor.isCursorChange()) {
            m_currentMouseCursor = optionalCursor.cursor();
            view->setCursor(m_currentMouseCursor);
        }
    }

    if (swallowEvent)
        return true;

    swallowEvent = !dispatchMouseEvent(EventTypeNames::mousemove, mev.targetNode(), 0, mouseEvent, true);
    if (!swallowEvent)
        swallowEvent = handleMouseDraggedEvent(mev);

    return swallowEvent;
}

void EventHandler::invalidateClick()
{
    m_clickCount = 0;
    m_clickNode = nullptr;
}

bool EventHandler::handleMouseReleaseEvent(const PlatformMouseEvent& mouseEvent)
{
    TRACE_EVENT0("blink", "EventHandler::handleMouseReleaseEvent");

    RefPtr<FrameView> protector(m_frame->view());

    m_frame->selection().setCaretBlinkingSuspended(false);

    OwnPtr<UserGestureIndicator> gestureIndicator;

    if (m_frame->eventHandler().m_lastMouseDownUserGestureToken)
        gestureIndicator = adoptPtr(new UserGestureIndicator(m_frame->eventHandler().m_lastMouseDownUserGestureToken.release()));
    else
        gestureIndicator = adoptPtr(new UserGestureIndicator(DefinitelyProcessingUserGesture));

    m_mousePressed = false;
    setLastKnownMousePosition(mouseEvent);

    if (m_lastScrollbarUnderMouse) {
        invalidateClick();
        m_lastScrollbarUnderMouse->mouseUp(mouseEvent);
        bool setUnder = false;
        return !dispatchMouseEvent(EventTypeNames::mouseup, m_lastNodeUnderMouse.get(), m_clickCount, mouseEvent, setUnder);
    }

    // Mouse events simulated from touch should not hit-test again.
    ASSERT(!mouseEvent.fromTouch());

    HitTestRequest::HitTestRequestType hitType = HitTestRequest::Release;
    HitTestRequest request(hitType);
    MouseEventWithHitTestResults mev = prepareMouseEvent(request, mouseEvent);
    if (m_eventHandlerWillResetCapturingMouseEventsNode)
        m_capturingMouseEventsNode = nullptr;

    bool swallowMouseUpEvent = !dispatchMouseEvent(EventTypeNames::mouseup, mev.targetNode(), m_clickCount, mouseEvent, false);

    bool swallowClickEvent = false;
    if (m_clickCount > 0 && mev.targetNode() && m_clickNode) {
        if (Node* clickTargetNode = NodeRenderingTraversal::commonAncestor(*mev.targetNode(), *m_clickNode))
            swallowClickEvent = !dispatchMouseEvent(EventTypeNames::click, clickTargetNode, m_clickCount, mouseEvent, true);
    }

    bool swallowMouseReleaseEvent = false;
    if (!swallowMouseUpEvent)
        swallowMouseReleaseEvent = handleMouseReleaseEvent(mev);

    invalidateClick();

    return swallowMouseUpEvent || swallowClickEvent || swallowMouseReleaseEvent;
}

bool EventHandler::handlePasteGlobalSelection(const PlatformMouseEvent& mouseEvent)
{
    // If the event was a middle click, attempt to copy global selection in after
    // the newly set caret position.
    //
    // This code is called from either the mouse up or mouse down handling. There
    // is some debate about when the global selection is pasted:
    //   xterm: pastes on up.
    //   GTK: pastes on down.
    //   Qt: pastes on up.
    //   Firefox: pastes on up.
    //   Chromium: pastes on up.
    //
    // There is something of a webcompat angle to this well, as highlighted by
    // crbug.com/14608. Pages can clear text boxes 'onclick' and, if we paste on
    // down then the text is pasted just before the onclick handler runs and
    // clears the text box. So it's important this happens after the event
    // handlers have been fired.
    if (mouseEvent.type() != PlatformEvent::MouseReleased)
        return false;

    if (!m_frame->page())
        return false;
    LocalFrame* focusFrame = m_frame->page()->focusController().focusedOrMainFrame();
    // Do not paste here if the focus was moved somewhere else.
    if (m_frame == focusFrame && m_frame->editor().behavior().supportsGlobalSelection())
        return m_frame->editor().command("PasteGlobalSelection").execute();

    return false;
}

void EventHandler::setCapturingMouseEventsNode(PassRefPtr<Node> n)
{
    m_capturingMouseEventsNode = n;
    m_eventHandlerWillResetCapturingMouseEventsNode = false;
}

MouseEventWithHitTestResults EventHandler::prepareMouseEvent(const HitTestRequest& request, const PlatformMouseEvent& mev)
{
    ASSERT(m_frame);
    ASSERT(m_frame->document());

    return m_frame->document()->prepareMouseEvent(request, documentPointForWindowPoint(m_frame, mev.position()), mev);
}

void EventHandler::updateMouseEventTargetNode(Node* targetNode, const PlatformMouseEvent& mouseEvent, bool fireMouseOverOut)
{
    Node* result = targetNode;

    // If we're capturing, we always go right to that node.
    if (m_capturingMouseEventsNode)
        result = m_capturingMouseEventsNode.get();
    else {
        // If the target node is a text node, dispatch on the parent node - rdar://4196646
        if (result && result->isTextNode())
            result = NodeRenderingTraversal::parent(result);
    }
    m_nodeUnderMouse = result;

    // Fire mouseout/mouseover if the mouse has shifted to a different node.
    if (fireMouseOverOut) {
        RenderLayer* layerForLastNode = layerForNode(m_lastNodeUnderMouse.get());
        RenderLayer* layerForNodeUnderMouse = layerForNode(m_nodeUnderMouse.get());
        Page* page = m_frame->page();

        if (page && (layerForLastNode && (!layerForNodeUnderMouse || layerForNodeUnderMouse != layerForLastNode))) {
            // The mouse has moved between layers.
            if (ScrollableArea* scrollableAreaForLastNode = associatedScrollableArea(layerForLastNode))
                scrollableAreaForLastNode->mouseExitedContentArea();
        }

        if (page && (layerForNodeUnderMouse && (!layerForLastNode || layerForNodeUnderMouse != layerForLastNode))) {
            // The mouse has moved between layers.
            if (ScrollableArea* scrollableAreaForNodeUnderMouse = associatedScrollableArea(layerForNodeUnderMouse))
                scrollableAreaForNodeUnderMouse->mouseEnteredContentArea();
        }

        if (m_lastNodeUnderMouse && m_lastNodeUnderMouse->document() != m_frame->document()) {
            m_lastNodeUnderMouse = nullptr;
            m_lastScrollbarUnderMouse = nullptr;
        }

        if (m_lastNodeUnderMouse != m_nodeUnderMouse) {
            // send mouseout event to the old node
            if (m_lastNodeUnderMouse)
                m_lastNodeUnderMouse->dispatchMouseEvent(mouseEvent, EventTypeNames::mouseout, 0, m_nodeUnderMouse.get());
            // send mouseover event to the new node
            if (m_nodeUnderMouse)
                m_nodeUnderMouse->dispatchMouseEvent(mouseEvent, EventTypeNames::mouseover, 0, m_lastNodeUnderMouse.get());
        }
        m_lastNodeUnderMouse = m_nodeUnderMouse;
    }
}

// The return value means 'continue default handling.'
bool EventHandler::dispatchMouseEvent(const AtomicString& eventType, Node* targetNode, int clickCount, const PlatformMouseEvent& mouseEvent, bool setUnder)
{
    updateMouseEventTargetNode(targetNode, mouseEvent, setUnder);
    return !m_nodeUnderMouse || m_nodeUnderMouse->dispatchMouseEvent(mouseEvent, eventType, clickCount);
}

// The return value means 'swallow event' (was handled), as for other handle* functions.
bool EventHandler::handleMouseFocus(const PlatformMouseEvent& mouseEvent)
{
    // The layout needs to be up to date to determine if an element is focusable.
    m_frame->document()->updateLayout();

    Element* element = 0;
    if (m_nodeUnderMouse)
        element = m_nodeUnderMouse->isElementNode() ? toElement(m_nodeUnderMouse) : m_nodeUnderMouse->parentOrShadowHostElement();
    for (; element; element = element->parentOrShadowHostElement()) {
        if (element->isFocusable() && element->focused())
            return false;
        if (element->isMouseFocusable())
            break;
    }
    ASSERT(!element || element->isMouseFocusable());

    // To fix <rdar://problem/4895428> Can't drag selected ToDo, we don't focus
    // a node on mouse down if it's selected and inside a focused node. It will
    // be focused if the user does a mouseup over it, however, because the
    // mouseup will set a selection inside it, which will call
    // FrameSelection::setFocusedNodeIfNeeded.
    if (element
        && m_frame->selection().isRange()
        && m_frame->selection().toNormalizedRange()->compareNode(element, IGNORE_EXCEPTION) == Range::NODE_INSIDE
        && element->isDescendantOf(m_frame->document()->focusedElement()))
        return false;

    // Only change the focus when clicking scrollbars if it can transfered to a
    // mouse focusable node.
    if (!element && isInsideScrollbar(mouseEvent.position()))
        return true;

    if (Page* page = m_frame->page()) {
        // If focus shift is blocked, we eat the event. Note we should never
        // clear swallowEvent if the page already set it (e.g., by canceling
        // default behavior).
        if (element) {
            if (!page->focusController().setFocusedElement(element, m_frame, FocusTypeMouse))
                return true;
        } else {
            // We call setFocusedElement even with !element in order to blur
            // current focus element when a link is clicked; this is expected by
            // some sites that rely on onChange handlers running from form
            // fields before the button click is processed.
            if (!page->focusController().setFocusedElement(0, m_frame))
                return true;
        }
    }

    return false;
}

bool EventHandler::isInsideScrollbar(const IntPoint& windowPoint) const
{
    if (RenderView* renderView = m_frame->contentRenderer()) {
        HitTestRequest request(HitTestRequest::ReadOnly);
        HitTestResult result(windowPoint);
        renderView->hitTest(request, result);
        return result.scrollbar();
    }

    return false;
}

bool EventHandler::handleWheelEvent(const PlatformWheelEvent& event)
{
    Document* doc = m_frame->document();

    if (!doc->renderView())
        return false;

    RefPtr<FrameView> protector(m_frame->view());

    FrameView* view = m_frame->view();
    if (!view)
        return false;

    LayoutPoint vPoint = event.position();

    HitTestRequest request(HitTestRequest::ReadOnly);
    HitTestResult result(vPoint);
    doc->renderView()->hitTest(request, result);

    Node* node = result.innerNode();
    // Wheel events should not dispatch to text nodes.
    if (node && node->isTextNode())
        node = NodeRenderingTraversal::parent(node);

    bool isOverWidget;
    if (event.useLatchedEventNode()) {
        if (!m_latchedWheelEventNode) {
            m_latchedWheelEventNode = node;
            m_widgetIsLatched = result.isOverWidget();
        } else
            node = m_latchedWheelEventNode.get();

        isOverWidget = m_widgetIsLatched;
    } else {
        if (m_latchedWheelEventNode)
            m_latchedWheelEventNode = nullptr;
        if (m_previousWheelScrolledNode)
            m_previousWheelScrolledNode = nullptr;

        isOverWidget = result.isOverWidget();
    }

    if (node) {
        if (node && !node->dispatchWheelEvent(event))
            return true;
    }

    // We do another check on the frame view because the event handler can run JS which results in the frame getting destroyed.
    view = m_frame->view();
    if (!view || !view->wheelEvent(event))
        return false;

    return true;
}

void EventHandler::defaultWheelEventHandler(Node* startNode, WheelEvent* wheelEvent)
{
    if (!startNode || !wheelEvent)
        return;

    // Ctrl + scrollwheel is reserved for triggering zoom in/out actions in Chromium.
    if (wheelEvent->ctrlKey())
        return;

    Node* stopNode = m_previousWheelScrolledNode.get();
    ScrollGranularity granularity = wheelGranularityToScrollGranularity(wheelEvent->deltaMode());

    // Break up into two scrolls if we need to.  Diagonal movement on
    // a MacBook pro is an example of a 2-dimensional mouse wheel event (where both deltaX and deltaY can be set).
    if (scroll(ScrollRight, granularity, startNode, &stopNode, wheelEvent->deltaX(), roundedIntPoint(wheelEvent->absoluteLocation())))
        wheelEvent->setDefaultHandled();

    if (scroll(ScrollDown, granularity, startNode, &stopNode, wheelEvent->deltaY(), roundedIntPoint(wheelEvent->absoluteLocation())))
        wheelEvent->setDefaultHandled();

    if (!m_latchedWheelEventNode)
        m_previousWheelScrolledNode = stopNode;
}

bool EventHandler::handleGestureShowPress()
{
    m_lastShowPressTimestamp = WTF::currentTime();

    FrameView* view = m_frame->view();
    if (!view)
        return false;
    const FrameView::ScrollableAreaSet* areas = view->scrollableAreas();
    if (!areas)
        return false;
    for (FrameView::ScrollableAreaSet::const_iterator it = areas->begin(); it != areas->end(); ++it) {
        ScrollableArea* sa = *it;
        ScrollAnimator* animator = sa->existingScrollAnimator();
        if (animator)
            animator->cancelAnimations();
    }
    return false;
}

bool EventHandler::handleGestureEvent(const PlatformGestureEvent& gestureEvent)
{
    TRACE_EVENT0("input", "EventHandler::handleGestureEvent");

    // Scrolling-related gesture events invoke EventHandler recursively for each frame down
    // the chain, doing a single-frame hit-test per frame. This matches handleWheelEvent.
    // Perhaps we could simplify things by rewriting scroll handling to work inner frame
    // out, and then unify with other gesture events.
    if (gestureEvent.isScrollEvent())
        return handleGestureScrollEvent(gestureEvent);

    // Non-scrolling related gesture events instead do a single cross-frame hit-test and
    // jump directly to the inner most frame. This matches handleMousePressEvent etc.

    // Hit test across all frames and do touch adjustment as necessary for the event type.
    GestureEventWithHitTestResults targetedEvent = targetGestureEvent(gestureEvent);

    // Route to the correct frame.
    if (LocalFrame* innerFrame = targetedEvent.hitTestResult().innerNodeFrame())
        return innerFrame->eventHandler().handleGestureEventInFrame(targetedEvent);

    // No hit test result, handle in root instance. Perhaps we should just return false instead?
    return handleGestureEventInFrame(targetedEvent);
}

bool EventHandler::handleGestureEventInFrame(const GestureEventWithHitTestResults& targetedEvent)
{
    ASSERT(!targetedEvent.event().isScrollEvent());

    RefPtr<Node> eventTarget = targetedEvent.hitTestResult().targetNode();
    RefPtr<Scrollbar> scrollbar = targetedEvent.hitTestResult().scrollbar();
    const PlatformGestureEvent& gestureEvent = targetedEvent.event();

    if (scrollbar) {
        bool eventSwallowed = scrollbar->gestureEvent(gestureEvent);
        if (gestureEvent.type() == PlatformEvent::GestureTapDown && eventSwallowed)
            m_scrollbarHandlingScrollGesture = scrollbar;
        if (eventSwallowed)
            return true;
    }

    if (eventTarget && eventTarget->dispatchGestureEvent(gestureEvent))
        return true;

    switch (gestureEvent.type()) {
    case PlatformEvent::GestureTwoFingerTap: // FIXME(sky): Remove this.
    case PlatformEvent::GestureTap:
        return handleGestureTap(targetedEvent);
    case PlatformEvent::GestureShowPress:
        return handleGestureShowPress();
    case PlatformEvent::GestureLongPress:
        return handleGestureLongPress(targetedEvent);
    case PlatformEvent::GestureLongTap:
        return handleGestureLongTap(targetedEvent);
    case PlatformEvent::GestureTapDown:
    case PlatformEvent::GesturePinchBegin:
    case PlatformEvent::GesturePinchEnd:
    case PlatformEvent::GesturePinchUpdate:
    case PlatformEvent::GestureTapDownCancel:
    case PlatformEvent::GestureTapUnconfirmed:
        break;
    default:
        ASSERT_NOT_REACHED();
    }

    return false;
}

bool EventHandler::handleGestureScrollEvent(const PlatformGestureEvent& gestureEvent)
{
    RefPtr<Node> eventTarget = nullptr;
    RefPtr<Scrollbar> scrollbar;
    if (gestureEvent.type() != PlatformEvent::GestureScrollBegin) {
        scrollbar = m_scrollbarHandlingScrollGesture.get();
        eventTarget = m_scrollGestureHandlingNode.get();
    }

    if (!eventTarget) {
        Document* document = m_frame->document();
        if (!document->renderView())
            return false;

        LayoutPoint viewPoint = gestureEvent.position();
        HitTestRequest request(HitTestRequest::ReadOnly);
        HitTestResult result(viewPoint);
        document->renderView()->hitTest(request, result);

        eventTarget = result.innerNode();

        m_lastGestureScrollOverWidget = result.isOverWidget();
        m_scrollGestureHandlingNode = eventTarget;
        m_previousGestureScrolledNode = nullptr;

        if (!scrollbar)
            scrollbar = result.scrollbar();
    }

    if (scrollbar) {
        bool eventSwallowed = scrollbar->gestureEvent(gestureEvent);
        if (gestureEvent.type() == PlatformEvent::GestureScrollEnd
            || gestureEvent.type() == PlatformEvent::GestureFlingStart
            || !eventSwallowed) {
            m_scrollbarHandlingScrollGesture = nullptr;
        }
        if (eventSwallowed)
            return true;
    }

    if (eventTarget && eventTarget->dispatchGestureEvent(gestureEvent))
        return true;

    switch (gestureEvent.type()) {
    case PlatformEvent::GestureScrollBegin:
        return handleGestureScrollBegin(gestureEvent);
    case PlatformEvent::GestureScrollUpdate:
    case PlatformEvent::GestureScrollUpdateWithoutPropagation:
        return handleGestureScrollUpdate(gestureEvent);
    case PlatformEvent::GestureScrollEnd:
        return handleGestureScrollEnd(gestureEvent);
    case PlatformEvent::GestureFlingStart:
    case PlatformEvent::GesturePinchBegin:
    case PlatformEvent::GesturePinchEnd:
    case PlatformEvent::GesturePinchUpdate:
        return false;
    default:
        ASSERT_NOT_REACHED();
        return false;
    }
}

bool EventHandler::handleGestureTap(const GestureEventWithHitTestResults& targetedEvent)
{
    RefPtr<FrameView> protector(m_frame->view());
    const PlatformGestureEvent& gestureEvent = targetedEvent.event();

    UserGestureIndicator gestureIndicator(DefinitelyProcessingUserGesture);

    unsigned modifierFlags = 0;
    if (gestureEvent.altKey())
        modifierFlags |= PlatformEvent::AltKey;
    if (gestureEvent.ctrlKey())
        modifierFlags |= PlatformEvent::CtrlKey;
    if (gestureEvent.metaKey())
        modifierFlags |= PlatformEvent::MetaKey;
    if (gestureEvent.shiftKey())
        modifierFlags |= PlatformEvent::ShiftKey;
    PlatformEvent::Modifiers modifiers = static_cast<PlatformEvent::Modifiers>(modifierFlags);

    HitTestResult currentHitTest = targetedEvent.hitTestResult();

    // We use the adjusted position so the application isn't surprised to see a event with
    // co-ordinates outside the target's bounds.
    IntPoint adjustedPoint = gestureEvent.position();

    PlatformMouseEvent fakeMouseMove(adjustedPoint, gestureEvent.globalPosition(),
        NoButton, PlatformEvent::MouseMoved, /* clickCount */ 0,
        modifiers, PlatformMouseEvent::FromTouch, gestureEvent.timestamp());
    dispatchMouseEvent(EventTypeNames::mousemove, currentHitTest.innerNode(), 0, fakeMouseMove, true);

    // Do a new hit-test in case the mousemove event changed the DOM.
    // Note that if the original hit test wasn't over an element (eg. was over a scrollbar) we
    // don't want to re-hit-test because it may be in the wrong frame (and there's no way the page
    // could have seen the event anyway).
    // FIXME: Use a hit-test cache to avoid unnecessary hit tests. http://crbug.com/398920
    if (currentHitTest.innerNode())
        currentHitTest = hitTestResultInFrame(m_frame, adjustedPoint, HitTestRequest::ReadOnly);
    m_clickNode = currentHitTest.innerNode();
    if (m_clickNode && m_clickNode->isTextNode())
        m_clickNode = NodeRenderingTraversal::parent(m_clickNode.get());

    PlatformMouseEvent fakeMouseDown(adjustedPoint, gestureEvent.globalPosition(),
        LeftButton, PlatformEvent::MousePressed, gestureEvent.tapCount(),
        modifiers, PlatformMouseEvent::FromTouch,  gestureEvent.timestamp());
    bool swallowMouseDownEvent = !dispatchMouseEvent(EventTypeNames::mousedown, currentHitTest.innerNode(), gestureEvent.tapCount(), fakeMouseDown, true);
    if (!swallowMouseDownEvent)
        swallowMouseDownEvent = handleMouseFocus(fakeMouseDown);
    if (!swallowMouseDownEvent)
        swallowMouseDownEvent = handleMousePressEvent(MouseEventWithHitTestResults(fakeMouseDown, currentHitTest));

    // FIXME: Use a hit-test cache to avoid unnecessary hit tests. http://crbug.com/398920
    if (currentHitTest.innerNode())
        currentHitTest = hitTestResultInFrame(m_frame, adjustedPoint, HitTestRequest::ReadOnly);
    PlatformMouseEvent fakeMouseUp(adjustedPoint, gestureEvent.globalPosition(),
        LeftButton, PlatformEvent::MouseReleased, gestureEvent.tapCount(),
        modifiers, PlatformMouseEvent::FromTouch,  gestureEvent.timestamp());
    bool swallowMouseUpEvent = !dispatchMouseEvent(EventTypeNames::mouseup, currentHitTest.innerNode(), gestureEvent.tapCount(), fakeMouseUp, false);

    bool swallowClickEvent = false;
    if (m_clickNode) {
        if (currentHitTest.innerNode()) {
            Node* clickTargetNode = NodeRenderingTraversal::commonAncestor(*currentHitTest.innerNode(), *m_clickNode);
            swallowClickEvent = !dispatchMouseEvent(EventTypeNames::click, clickTargetNode, gestureEvent.tapCount(), fakeMouseUp, true);
        }
        m_clickNode = nullptr;
    }

    if (!swallowMouseUpEvent)
        swallowMouseUpEvent = handleMouseReleaseEvent(MouseEventWithHitTestResults(fakeMouseUp, currentHitTest));

    return swallowMouseDownEvent | swallowMouseUpEvent | swallowClickEvent;
}

bool EventHandler::handleGestureLongPress(const GestureEventWithHitTestResults& targetedEvent)
{
    const PlatformGestureEvent& gestureEvent = targetedEvent.event();

    // FIXME: Ideally we should try to remove the extra mouse-specific hit-tests here (re-using the
    // supplied HitTestResult), but that will require some overhaul of the touch drag-and-drop code
    // and LongPress is such a special scenario that it's unlikely to matter much in practice.

#if OS(ANDROID)
    bool shouldLongPressSelectWord = true;
#else
    bool shouldLongPressSelectWord = m_frame->settings() && m_frame->settings()->touchEditingEnabled();
#endif
    if (shouldLongPressSelectWord) {
        IntPoint hitTestPoint = gestureEvent.position();
        HitTestResult result = hitTestResultAtPoint(hitTestPoint);
        Node* innerNode = result.targetNode();
        if (!result.isLiveLink() && innerNode && (innerNode->isContentEditable() || innerNode->isTextNode())) {
            selectClosestWordFromHitTestResult(result, DontAppendTrailingWhitespace);
            if (m_frame->selection().isRange()) {
                focusDocumentView();
                return true;
            }
        }
    }
    return true;
}

bool EventHandler::handleGestureLongTap(const GestureEventWithHitTestResults& targetedEvent)
{
    return false;
}

bool EventHandler::passScrollGestureEventToWidget(const PlatformGestureEvent& gestureEvent, RenderObject* renderer)
{
    ASSERT(gestureEvent.isScrollEvent());

    // FIXME(sky): Remove this.
    return false;
}

bool EventHandler::handleGestureScrollEnd(const PlatformGestureEvent& gestureEvent) {
    RefPtr<Node> node = m_scrollGestureHandlingNode;
    clearGestureScrollNodes();

    if (node)
        passScrollGestureEventToWidget(gestureEvent, node->renderer());

    return false;
}

bool EventHandler::handleGestureScrollBegin(const PlatformGestureEvent& gestureEvent)
{
    Document* document = m_frame->document();
    if (!document->renderView())
        return false;

    FrameView* view = m_frame->view();
    if (!view)
        return false;

    // If there's no renderer on the node, send the event to the nearest ancestor with a renderer.
    // Needed for <option> and <optgroup> elements so we can touch scroll <select>s
    while (m_scrollGestureHandlingNode && !m_scrollGestureHandlingNode->renderer())
        m_scrollGestureHandlingNode = m_scrollGestureHandlingNode->parentOrShadowHostNode();

    if (!m_scrollGestureHandlingNode)
        return false;

    passScrollGestureEventToWidget(gestureEvent, m_scrollGestureHandlingNode->renderer());

    return true;
}

bool EventHandler::handleGestureScrollUpdate(const PlatformGestureEvent& gestureEvent)
{
    FloatSize delta(gestureEvent.deltaX(), gestureEvent.deltaY());
    if (delta.isZero())
        return false;

    Node* node = m_scrollGestureHandlingNode.get();
    if (!node)
        return sendScrollEventToView(gestureEvent, delta);

    // Ignore this event if the targeted node does not have a valid renderer.
    RenderObject* renderer = node->renderer();
    if (!renderer)
        return false;

    RefPtr<FrameView> protector(m_frame->view());

    Node* stopNode = 0;
    bool scrollShouldNotPropagate = gestureEvent.type() == PlatformEvent::GestureScrollUpdateWithoutPropagation;

    // Try to send the event to the correct view.
    if (passScrollGestureEventToWidget(gestureEvent, renderer)) {
        if(scrollShouldNotPropagate)
              m_previousGestureScrolledNode = m_scrollGestureHandlingNode;

        return true;
    }

    if (scrollShouldNotPropagate)
        stopNode = m_previousGestureScrolledNode.get();

    // First try to scroll the closest scrollable RenderBox ancestor of |node|.
    ScrollGranularity granularity = ScrollByPixel;
    bool horizontalScroll = scroll(ScrollLeft, granularity, node, &stopNode, delta.width());
    bool verticalScroll = scroll(ScrollUp, granularity, node, &stopNode, delta.height());

    if (scrollShouldNotPropagate)
        m_previousGestureScrolledNode = stopNode;

    if (horizontalScroll || verticalScroll) {
        return true;
    }

    // Otherwise try to scroll the view.
    return sendScrollEventToView(gestureEvent, delta);
}

bool EventHandler::sendScrollEventToView(const PlatformGestureEvent& gestureEvent, const FloatSize& scaledDelta)
{
    FrameView* view = m_frame->view();
    if (!view)
        return false;

    const float tickDivisor = static_cast<float>(WheelEvent::TickMultiplier);
    IntPoint point(gestureEvent.position().x(), gestureEvent.position().y());
    IntPoint globalPoint(gestureEvent.globalPosition().x(), gestureEvent.globalPosition().y());
    PlatformWheelEvent syntheticWheelEvent(point, globalPoint,
        scaledDelta.width(), scaledDelta.height(),
        scaledDelta.width() / tickDivisor, scaledDelta.height() / tickDivisor,
        ScrollByPixelWheelEvent,
        gestureEvent.shiftKey(), gestureEvent.ctrlKey(), gestureEvent.altKey(), gestureEvent.metaKey());
    syntheticWheelEvent.setHasPreciseScrollingDeltas(true);

    bool scrolledFrame = view->wheelEvent(syntheticWheelEvent);
    return scrolledFrame;
}

void EventHandler::clearGestureScrollNodes()
{
    m_scrollGestureHandlingNode = nullptr;
    m_previousGestureScrolledNode = nullptr;
}

bool EventHandler::isScrollbarHandlingGestures() const
{
    return m_scrollbarHandlingScrollGesture.get();
}

GestureEventWithHitTestResults EventHandler::targetGestureEvent(const PlatformGestureEvent& gestureEvent, bool readOnly)
{
    // Scrolling events get hit tested per frame (like wheel events do).
    ASSERT(!gestureEvent.isScrollEvent());

    HitTestRequest::HitTestRequestType hitType = getHitTypeForGestureType(gestureEvent.type());
    double activeInterval = 0;
    bool shouldKeepActiveForMinInterval = false;
    if (readOnly) {
        hitType |= HitTestRequest::ReadOnly;
    } else if (gestureEvent.type() == PlatformEvent::GestureTap) {
        // If the Tap is received very shortly after ShowPress, we want to
        // delay clearing of the active state so that it's visible to the user
        // for at least a couple of frames.
        activeInterval = WTF::currentTime() - m_lastShowPressTimestamp;
        shouldKeepActiveForMinInterval = m_lastShowPressTimestamp && activeInterval < minimumActiveInterval;
        if (shouldKeepActiveForMinInterval)
            hitType |= HitTestRequest::ReadOnly;
    }

    // Perform the rect-based hit-test. Note that we don't yet apply hover/active state here
    // because we need to resolve touch adjustment first so that we apply hover/active it to
    // the final adjusted node.
    IntPoint hitTestPoint = gestureEvent.position();
    IntSize touchRadius = gestureEvent.area();
    touchRadius.scale(1.f / 2);
    // FIXME: We should not do a rect-based hit-test if touch adjustment is disabled.
    HitTestResult hitTestResult = hitTestResultAtPoint(hitTestPoint, hitType | HitTestRequest::ReadOnly, touchRadius);

    // Now apply hover/active state to the final target.
    // FIXME: This is supposed to send mouseenter/mouseleave events, but doesn't because we
    // aren't passing a PlatformMouseEvent.
    HitTestRequest request(hitType);
    if (!request.readOnly())
        m_frame->document()->updateHoverActiveState(request, hitTestResult.innerElement());

    if (shouldKeepActiveForMinInterval) {
        m_lastDeferredTapElement = hitTestResult.innerElement();
        m_activeIntervalTimer.startOneShot(minimumActiveInterval - activeInterval, FROM_HERE);
    }

    return GestureEventWithHitTestResults(gestureEvent, hitTestResult);
}

HitTestRequest::HitTestRequestType EventHandler::getHitTypeForGestureType(PlatformEvent::Type type)
{
    HitTestRequest::HitTestRequestType hitType = HitTestRequest::TouchEvent;
    switch (type) {
    case PlatformEvent::GestureShowPress:
    case PlatformEvent::GestureTapUnconfirmed:
        return hitType | HitTestRequest::Active;
    case PlatformEvent::GestureTapDownCancel:
        // A TapDownCancel received when no element is active shouldn't really be changing hover state.
        if (!m_frame->document()->activeHoverElement())
            hitType |= HitTestRequest::ReadOnly;
        return hitType | HitTestRequest::Release;
    case PlatformEvent::GestureTap:
        return hitType | HitTestRequest::Release;
    case PlatformEvent::GestureTapDown:
    case PlatformEvent::GestureLongPress:
    case PlatformEvent::GestureLongTap:
    case PlatformEvent::GestureTwoFingerTap:
        // FIXME: Shouldn't LongTap and TwoFingerTap clear the Active state?
        return hitType | HitTestRequest::Active | HitTestRequest::ReadOnly;
    default:
        ASSERT_NOT_REACHED();
        return hitType | HitTestRequest::Active | HitTestRequest::ReadOnly;
    }
}

void EventHandler::scheduleHoverStateUpdate()
{
    if (!m_hoverTimer.isActive())
        m_hoverTimer.startOneShot(0, FROM_HERE);
}

void EventHandler::scheduleCursorUpdate()
{
    if (!m_cursorUpdateTimer.isActive())
        m_cursorUpdateTimer.startOneShot(cursorUpdateInterval, FROM_HERE);
}

void EventHandler::dispatchFakeMouseMoveEventSoon()
{
    if (m_mousePressed)
        return;

    if (m_mousePositionIsUnknown)
        return;

    Settings* settings = m_frame->settings();
    if (settings && !settings->deviceSupportsMouse())
        return;

    // If the content has ever taken longer than fakeMouseMoveShortInterval we
    // reschedule the timer and use a longer time. This will cause the content
    // to receive these moves only after the user is done scrolling, reducing
    // pauses during the scroll.
    if (m_maxMouseMovedDuration > fakeMouseMoveShortInterval) {
        if (m_fakeMouseMoveEventTimer.isActive())
            m_fakeMouseMoveEventTimer.stop();
        m_fakeMouseMoveEventTimer.startOneShot(fakeMouseMoveLongInterval, FROM_HERE);
    } else {
        if (!m_fakeMouseMoveEventTimer.isActive())
            m_fakeMouseMoveEventTimer.startOneShot(fakeMouseMoveShortInterval, FROM_HERE);
    }
}

void EventHandler::dispatchFakeMouseMoveEventSoonInQuad(const FloatQuad& quad)
{
    FrameView* view = m_frame->view();
    if (!view)
        return;

    if (!quad.containsPoint(m_lastKnownMousePosition))
        return;

    dispatchFakeMouseMoveEventSoon();
}

void EventHandler::fakeMouseMoveEventTimerFired(Timer<EventHandler>* timer)
{
    ASSERT_UNUSED(timer, timer == &m_fakeMouseMoveEventTimer);
    ASSERT(!m_mousePressed);

    Settings* settings = m_frame->settings();
    if (settings && !settings->deviceSupportsMouse())
        return;

    FrameView* view = m_frame->view();
    if (!view)
        return;

    if (!m_frame->page() || !m_frame->page()->focusController().isActive())
        return;

    // Don't dispatch a synthetic mouse move event if the mouse cursor is not visible to the user.
    if (!isCursorVisible())
        return;

    bool shiftKey;
    bool ctrlKey;
    bool altKey;
    bool metaKey;
    PlatformKeyboardEvent::getCurrentModifierState(shiftKey, ctrlKey, altKey, metaKey);
    PlatformMouseEvent fakeMouseMoveEvent(m_lastKnownMousePosition, m_lastKnownMouseGlobalPosition, NoButton, PlatformEvent::MouseMoved, 0, shiftKey, ctrlKey, altKey, metaKey, PlatformMouseEvent::RealOrIndistinguishable, currentTime());
    handleMouseMoveEvent(fakeMouseMoveEvent);
}

void EventHandler::cancelFakeMouseMoveEvent()
{
    m_fakeMouseMoveEventTimer.stop();
}

bool EventHandler::isCursorVisible() const
{
    return m_frame->page()->isCursorVisible();
}

void EventHandler::hoverTimerFired(Timer<EventHandler>*)
{
    m_hoverTimer.stop();

    ASSERT(m_frame);
    ASSERT(m_frame->document());

    if (RenderView* renderer = m_frame->contentRenderer()) {
        HitTestRequest request(HitTestRequest::Move);
        HitTestResult result(m_lastKnownMousePosition);
        renderer->hitTest(request, result);
        m_frame->document()->updateHoverActiveState(request, result.innerElement());
    }
}

void EventHandler::activeIntervalTimerFired(Timer<EventHandler>*)
{
    m_activeIntervalTimer.stop();

    if (m_frame
        && m_frame->document()
        && m_lastDeferredTapElement) {
        // FIXME: Enable condition when http://crbug.com/226842 lands
        // m_lastDeferredTapElement.get() == m_frame->document()->activeElement()
        HitTestRequest request(HitTestRequest::TouchEvent | HitTestRequest::Release);
        m_frame->document()->updateHoverActiveState(request, m_lastDeferredTapElement.get());
    }
    m_lastDeferredTapElement = nullptr;
}

void EventHandler::notifyElementActivated()
{
    // Since another element has been set to active, stop current timer and clear reference.
    if (m_activeIntervalTimer.isActive())
        m_activeIntervalTimer.stop();
    m_lastDeferredTapElement = nullptr;
}

bool EventHandler::keyEvent(const PlatformKeyboardEvent& initialKeyEvent)
{
    RefPtr<FrameView> protector(m_frame->view());

    if (initialKeyEvent.windowsVirtualKeyCode() == VK_CAPITAL)
        capsLockStateMayHaveChanged();

    // Check for cases where we are too early for events -- possible unmatched key up
    // from pressing return in the location bar.
    RefPtr<Node> node = eventTargetNodeForDocument(m_frame->document());
    if (!node)
        return false;

    UserGestureIndicator gestureIndicator(DefinitelyProcessingUserGesture);

    // FIXME: it would be fair to let an input method handle KeyUp events before DOM dispatch.
    if (initialKeyEvent.type() == PlatformEvent::KeyUp || initialKeyEvent.type() == PlatformEvent::Char)
        return !node->dispatchKeyEvent(initialKeyEvent);

    PlatformKeyboardEvent keyDownEvent = initialKeyEvent;
    if (keyDownEvent.type() != PlatformEvent::RawKeyDown)
        keyDownEvent.disambiguateKeyDownEvent(PlatformEvent::RawKeyDown);
    RefPtr<KeyboardEvent> keydown = KeyboardEvent::create(keyDownEvent, m_frame->document()->domWindow());

    keydown->setTarget(node);

    if (initialKeyEvent.type() == PlatformEvent::RawKeyDown) {
        node->dispatchEvent(keydown, IGNORE_EXCEPTION);
        // If frame changed as a result of keydown dispatch, then return true to avoid sending a subsequent keypress message to the new frame.
        bool changedFocusedFrame = m_frame->page() && m_frame != m_frame->page()->focusController().focusedOrMainFrame();
        return keydown->defaultHandled() || keydown->defaultPrevented() || changedFocusedFrame;
    }

    node->dispatchEvent(keydown, IGNORE_EXCEPTION);
    // If frame changed as a result of keydown dispatch, then return early to avoid sending a subsequent keypress message to the new frame.
    bool changedFocusedFrame = m_frame->page() && m_frame != m_frame->page()->focusController().focusedOrMainFrame();
    bool keydownResult = keydown->defaultHandled() || keydown->defaultPrevented() || changedFocusedFrame;
    if (keydownResult)
        return keydownResult;

    // Focus may have changed during keydown handling, so refetch node.
    // But if we are dispatching a fake backward compatibility keypress, then we pretend that the keypress happened on the original node.
    node = eventTargetNodeForDocument(m_frame->document());
    if (!node)
        return false;

    PlatformKeyboardEvent keyPressEvent = initialKeyEvent;
    keyPressEvent.disambiguateKeyDownEvent(PlatformEvent::Char);
    if (keyPressEvent.text().isEmpty())
        return keydownResult;
    RefPtr<KeyboardEvent> keypress = KeyboardEvent::create(keyPressEvent, m_frame->document()->domWindow());
    keypress->setTarget(node);
    if (keydownResult)
        keypress->setDefaultPrevented(true);
    node->dispatchEvent(keypress, IGNORE_EXCEPTION);

    return keydownResult || keypress->defaultPrevented() || keypress->defaultHandled();
}

void EventHandler::defaultKeyboardEventHandler(KeyboardEvent* event)
{
    if (event->type() == EventTypeNames::keydown) {
        // Clear caret blinking suspended state to make sure that caret blinks
        // when we type again after long pressing on an empty input field.
        if (m_frame && m_frame->selection().isCaretBlinkingSuspended())
            m_frame->selection().setCaretBlinkingSuspended(false);

        m_frame->editor().handleKeyboardEvent(event);
        if (event->defaultHandled())
            return;
        if (event->keyIdentifier() == "U+0009")
            defaultTabEventHandler(event);
    }
    if (event->type() == EventTypeNames::keypress) {
        m_frame->editor().handleKeyboardEvent(event);
        if (event->defaultHandled())
            return;
    }
}

bool EventHandler::dragHysteresisExceeded(const FloatPoint& floatDragViewportLocation) const
{
    return dragHysteresisExceeded(flooredIntPoint(floatDragViewportLocation));
}

bool EventHandler::dragHysteresisExceeded(const IntPoint& dragViewportLocation) const
{
    FrameView* view = m_frame->view();
    if (!view)
        return false;
    IntPoint dragLocation = dragViewportLocation;
    IntSize delta = dragLocation - m_mouseDownPos;

    int threshold = 3;

    return abs(delta.width()) >= threshold || abs(delta.height()) >= threshold;
}

bool EventHandler::handleTextInputEvent(const String& text, Event* underlyingEvent, TextEventInputType inputType)
{
    // Platforms should differentiate real commands like selectAll from text input in disguise (like insertNewline),
    // and avoid dispatching text input events from keydown default handlers.
    ASSERT(!underlyingEvent || !underlyingEvent->isKeyboardEvent() || toKeyboardEvent(underlyingEvent)->type() == EventTypeNames::keypress);

    if (!m_frame)
        return false;

    EventTarget* target;
    if (underlyingEvent)
        target = underlyingEvent->target();
    else
        target = eventTargetNodeForDocument(m_frame->document());
    if (!target)
        return false;

    RefPtr<TextEvent> event = TextEvent::create(m_frame->domWindow(), text, inputType);
    event->setUnderlyingEvent(underlyingEvent);

    target->dispatchEvent(event, IGNORE_EXCEPTION);
    return event->defaultHandled();
}

void EventHandler::defaultTextInputEventHandler(TextEvent* event)
{
    if (m_frame->editor().handleTextEvent(event))
        event->setDefaultHandled();
}

void EventHandler::defaultTabEventHandler(KeyboardEvent* event)
{
}

void EventHandler::capsLockStateMayHaveChanged()
{
}

bool EventHandler::passMousePressEventToScrollbar(MouseEventWithHitTestResults& mev)
{
    // FIXME(sky): Remove
    return false;
}

// If scrollbar (under mouse) is different from last, send a mouse exited. Set
// last to scrollbar if setLast is true; else set last to 0.
void EventHandler::updateLastScrollbarUnderMouse(Scrollbar* scrollbar, bool setLast)
{
    if (m_lastScrollbarUnderMouse != scrollbar) {
        // Send mouse exited to the old scrollbar.
        if (m_lastScrollbarUnderMouse)
            m_lastScrollbarUnderMouse->mouseExited();

        // Send mouse entered if we're setting a new scrollbar.
        if (scrollbar && setLast)
            scrollbar->mouseEntered();

        m_lastScrollbarUnderMouse = setLast ? scrollbar : 0;
    }
}

static const AtomicString& eventNameForTouchPointState(PlatformTouchPoint::State state)
{
    switch (state) {
    case PlatformTouchPoint::TouchReleased:
        return EventTypeNames::touchend;
    case PlatformTouchPoint::TouchCancelled:
        return EventTypeNames::touchcancel;
    case PlatformTouchPoint::TouchPressed:
        return EventTypeNames::touchstart;
    case PlatformTouchPoint::TouchMoved:
        return EventTypeNames::touchmove;
    case PlatformTouchPoint::TouchStationary:
        // TouchStationary state is not converted to touch events, so fall through to assert.
    default:
        ASSERT_NOT_REACHED();
        return emptyAtom;
    }
}

HitTestResult EventHandler::hitTestResultInFrame(LocalFrame* frame, const LayoutPoint& point, HitTestRequest::HitTestRequestType hitType)
{
    HitTestResult result(point);

    if (!frame || !frame->contentRenderer())
        return result;
    if (frame->view()) {
        IntRect rect = frame->view()->visibleContentRect();
        if (!rect.contains(roundedIntPoint(point)))
            return result;
    }
    frame->contentRenderer()->hitTest(HitTestRequest(hitType), result);
    return result;
}

bool EventHandler::handleTouchEvent(const PlatformTouchEvent& event)
{
    TRACE_EVENT0("blink", "EventHandler::handleTouchEvent");

    const Vector<PlatformTouchPoint>& points = event.touchPoints();

    unsigned i;
    bool freshTouchEvents = true;
    bool allTouchReleased = true;
    for (i = 0; i < points.size(); ++i) {
        const PlatformTouchPoint& point = points[i];
        if (point.state() != PlatformTouchPoint::TouchPressed)
            freshTouchEvents = false;
        if (point.state() != PlatformTouchPoint::TouchReleased && point.state() != PlatformTouchPoint::TouchCancelled)
            allTouchReleased = false;
    }
    if (freshTouchEvents) {
        // Ideally we'd ASSERT !m_touchSequenceDocument here since we should
        // have cleared the active document when we saw the last release. But we
        // have some tests that violate this, ClusterFuzz could trigger it, and
        // there may be cases where the browser doesn't reliably release all
        // touches. http://crbug.com/345372 tracks this.
        m_touchSequenceDocument.clear();
        m_touchSequenceUserGestureToken.clear();
    }

    OwnPtr<UserGestureIndicator> gestureIndicator;

    if (m_touchSequenceUserGestureToken)
        gestureIndicator = adoptPtr(new UserGestureIndicator(m_touchSequenceUserGestureToken.release()));
    else
        gestureIndicator = adoptPtr(new UserGestureIndicator(DefinitelyProcessingUserGesture));

    m_touchSequenceUserGestureToken = gestureIndicator->currentToken();

    ASSERT(m_frame->view());
    if (m_touchSequenceDocument && (!m_touchSequenceDocument->frame() || !m_touchSequenceDocument->frame()->view())) {
        // If the active touch document has no frame or view, it's probably being destroyed
        // so we can't dispatch events.
        return false;
    }

    // First do hit tests for any new touch points.
    for (i = 0; i < points.size(); ++i) {
        const PlatformTouchPoint& point = points[i];

        // Touch events implicitly capture to the touched node, and don't change
        // active/hover states themselves (Gesture events do). So we only need
        // to hit-test on touchstart, and it can be read-only.
        if (point.state() == PlatformTouchPoint::TouchPressed) {
            HitTestRequest::HitTestRequestType hitType = HitTestRequest::TouchEvent | HitTestRequest::ReadOnly | HitTestRequest::Active;
            LayoutPoint pagePoint = roundedLayoutPoint(point.pos());
            HitTestResult result;
            if (!m_touchSequenceDocument) {
                result = hitTestResultAtPoint(pagePoint, hitType);
            } else if (m_touchSequenceDocument->frame()) {
                LayoutPoint framePoint = roundedLayoutPoint(point.pos());
                result = hitTestResultInFrame(m_touchSequenceDocument->frame(), framePoint, hitType);
            } else
                continue;

            Node* node = result.innerNode();
            if (!node)
                continue;

            // Touch events should not go to text nodes
            if (node->isTextNode())
                node = NodeRenderingTraversal::parent(node);

            if (!m_touchSequenceDocument) {
                // Keep track of which document should receive all touch events
                // in the active sequence. This must be a single document to
                // ensure we don't leak Nodes between documents.
                m_touchSequenceDocument = &(result.innerNode()->document());
                ASSERT(m_touchSequenceDocument->frame()->view());
            }

            // Ideally we'd ASSERT(!m_targetForTouchID.contains(point.id())
            // since we shouldn't get a touchstart for a touch that's already
            // down. However EventSender allows this to be violated and there's
            // some tests that take advantage of it. There may also be edge
            // cases in the browser where this happens.
            // See http://crbug.com/345372.
            m_targetForTouchID.set(point.id(), node);

            TouchAction effectiveTouchAction = computeEffectiveTouchAction(*node);
            if (effectiveTouchAction != TouchActionAuto)
                m_frame->page()->chrome().client().setTouchAction(effectiveTouchAction);
        }
    }

    m_touchPressed = !allTouchReleased;

    // If there's no document receiving touch events,  then we can skip all the
    // rest of this work.
    if (!m_touchSequenceDocument || !m_touchSequenceDocument->frame()) {
        if (allTouchReleased) {
            m_touchSequenceDocument.clear();
            m_touchSequenceUserGestureToken.clear();
        }
        return false;
    }

    // Build up the lists to use for the 'touches', 'targetTouches' and
    // 'changedTouches' attributes in the JS event. See
    // http://www.w3.org/TR/touch-events/#touchevent-interface for how these
    // lists fit together.

    // Holds the complete set of touches on the screen.
    RefPtr<TouchList> touches = TouchList::create();

    // A different view on the 'touches' list above, filtered and grouped by
    // event target. Used for the 'targetTouches' list in the JS event.
    typedef HashMap<EventTarget*, RefPtr<TouchList> > TargetTouchesHeapMap;
    TargetTouchesHeapMap touchesByTarget;

    // Array of touches per state, used to assemble the 'changedTouches' list.
    typedef HashSet<RefPtr<EventTarget> > EventTargetSet;
    struct {
        // The touches corresponding to the particular change state this struct
        // instance represents.
        RefPtr<TouchList> m_touches;
        // Set of targets involved in m_touches.
        EventTargetSet m_targets;
    } changedTouches[PlatformTouchPoint::TouchStateEnd];

    for (i = 0; i < points.size(); ++i) {
        const PlatformTouchPoint& point = points[i];
        PlatformTouchPoint::State pointState = point.state();
        RefPtr<EventTarget> touchTarget = nullptr;

        if (pointState == PlatformTouchPoint::TouchReleased || pointState == PlatformTouchPoint::TouchCancelled) {
            // The target should be the original target for this touch, so get
            // it from the hashmap. As it's a release or cancel we also remove
            // it from the map.
            touchTarget = m_targetForTouchID.take(point.id());
        } else {
            // No hittest is performed on move or stationary, since the target
            // is not allowed to change anyway.
            touchTarget = m_targetForTouchID.get(point.id());
        }

        LocalFrame* targetFrame = 0;
        bool knownTarget = false;
        if (touchTarget) {
            Document& doc = touchTarget->toNode()->document();
            // If the target node has moved to a new document while it was being touched,
            // we can't send events to the new document because that could leak nodes
            // from one document to another. See http://crbug.com/394339.
            if (&doc == m_touchSequenceDocument.get()) {
                targetFrame = doc.frame();
                knownTarget = true;
            }
        }
        if (!knownTarget) {
            // If we don't have a target registered for the point it means we've
            // missed our opportunity to do a hit test for it (due to some
            // optimization that prevented blink from ever seeing the
            // touchstart), or that the touch started outside the active touch
            // sequence document. We should still include the touch in the
            // Touches list reported to the application (eg. so it can
            // differentiate between a one and two finger gesture), but we won't
            // actually dispatch any events for it. Set the target to the
            // Document so that there's some valid node here. Perhaps this
            // should really be LocalDOMWindow, but in all other cases the target of
            // a Touch is a Node so using the window could be a breaking change.
            // Since we know there was no handler invoked, the specific target
            // should be completely irrelevant to the application.
            touchTarget = m_touchSequenceDocument;
            targetFrame = m_touchSequenceDocument->frame();
        }
        ASSERT(targetFrame);

        RefPtr<Touch> touch = Touch::create(
            targetFrame, touchTarget.get(), point.id(), point.screenPos(), point.pos(), point.radius(), point.rotationAngle(), point.force());

        // Ensure this target's touch list exists, even if it ends up empty, so
        // it can always be passed to TouchEvent::Create below.
        TargetTouchesHeapMap::iterator targetTouchesIterator = touchesByTarget.find(touchTarget.get());
        if (targetTouchesIterator == touchesByTarget.end()) {
            touchesByTarget.set(touchTarget.get(), TouchList::create());
            targetTouchesIterator = touchesByTarget.find(touchTarget.get());
        }

        // touches and targetTouches should only contain information about
        // touches still on the screen, so if this point is released or
        // cancelled it will only appear in the changedTouches list.
        if (pointState != PlatformTouchPoint::TouchReleased && pointState != PlatformTouchPoint::TouchCancelled) {
            touches->append(touch);
            targetTouchesIterator->value->append(touch);
        }

        // Now build up the correct list for changedTouches.
        // Note that  any touches that are in the TouchStationary state (e.g. if
        // the user had several points touched but did not move them all) should
        // never be in the changedTouches list so we do not handle them
        // explicitly here. See https://bugs.webkit.org/show_bug.cgi?id=37609
        // for further discussion about the TouchStationary state.
        if (pointState != PlatformTouchPoint::TouchStationary && knownTarget) {
            ASSERT(pointState < PlatformTouchPoint::TouchStateEnd);
            if (!changedTouches[pointState].m_touches)
                changedTouches[pointState].m_touches = TouchList::create();
            changedTouches[pointState].m_touches->append(touch);
            changedTouches[pointState].m_targets.add(touchTarget);
        }
    }
    if (allTouchReleased) {
        m_touchSequenceDocument.clear();
        m_touchSequenceUserGestureToken.clear();
    }

    // Now iterate the changedTouches list and m_targets within it, sending
    // events to the targets as required.
    bool swallowedEvent = false;
    for (unsigned state = 0; state != PlatformTouchPoint::TouchStateEnd; ++state) {
        if (!changedTouches[state].m_touches)
            continue;

        const AtomicString& stateName(eventNameForTouchPointState(static_cast<PlatformTouchPoint::State>(state)));
        const EventTargetSet& targetsForState = changedTouches[state].m_targets;
        for (EventTargetSet::const_iterator it = targetsForState.begin(); it != targetsForState.end(); ++it) {
            EventTarget* touchEventTarget = it->get();
            RefPtr<TouchEvent> touchEvent = TouchEvent::create(
                touches.get(), touchesByTarget.get(touchEventTarget), changedTouches[state].m_touches.get(),
                stateName, touchEventTarget->toNode()->document().domWindow(),
                event.ctrlKey(), event.altKey(), event.shiftKey(), event.metaKey(), event.cancelable());
            touchEventTarget->toNode()->dispatchTouchEvent(touchEvent.get());
            swallowedEvent = swallowedEvent || touchEvent->defaultPrevented() || touchEvent->defaultHandled();
        }
    }

    return swallowedEvent;
}

TouchAction EventHandler::intersectTouchAction(TouchAction action1, TouchAction action2)
{
    if (action1 == TouchActionNone || action2 == TouchActionNone)
        return TouchActionNone;
    if (action1 == TouchActionAuto)
        return action2;
    if (action2 == TouchActionAuto)
        return action1;
    if (!(action1 & action2))
        return TouchActionNone;
    return action1 & action2;
}

TouchAction EventHandler::computeEffectiveTouchAction(const Node& node)
{
    // Start by permitting all actions, then walk the elements supporting
    // touch-action from the target node up to the nearest scrollable ancestor
    // and exclude any prohibited actions.
    TouchAction effectiveTouchAction = TouchActionAuto;
    for (const Node* curNode = &node; curNode; curNode = NodeRenderingTraversal::parent(curNode)) {
        if (RenderObject* renderer = curNode->renderer()) {
            if (renderer->supportsTouchAction()) {
                TouchAction action = renderer->style()->touchAction();
                effectiveTouchAction = intersectTouchAction(action, effectiveTouchAction);
                if (effectiveTouchAction == TouchActionNone)
                    break;
            }

            // If we've reached an ancestor that supports a touch action, search no further.
            if (renderer->isBox() && toRenderBox(renderer)->scrollsOverflow())
                break;
        }
    }
    return effectiveTouchAction;
}

void EventHandler::setLastKnownMousePosition(const PlatformMouseEvent& event)
{
    m_mousePositionIsUnknown = false;
    m_lastKnownMousePosition = event.position();
    m_lastKnownMouseGlobalPosition = event.globalPosition();
}

bool EventHandler::passWheelEventToWidget(const PlatformWheelEvent& wheelEvent, Widget* widget)
{
    // We can sometimes get a null widget!  EventHandlerMac handles a null
    // widget by returning false, so we do the same.
    if (!widget)
        return false;

    // If not a FrameView, then probably a plugin widget.  Those will receive
    // the event via an EventTargetNode dispatch when this returns false.
    if (!widget->isFrameView())
        return false;

    return toFrameView(widget)->frame().eventHandler().handleWheelEvent(wheelEvent);
}

// TODO(esprehn): Remove this.
bool EventHandler::passWidgetMouseDownEventToWidget(const MouseEventWithHitTestResults& event)
{
    return false;
}

void EventHandler::focusDocumentView()
{
    Page* page = m_frame->page();
    if (!page)
        return;
    page->focusController().focusDocumentView(m_frame);
}

} // namespace blink
