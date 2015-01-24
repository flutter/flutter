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
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/editing/Editor.h"
#include "sky/engine/core/editing/FrameSelection.h"
#include "sky/engine/core/editing/TextIterator.h"
#include "sky/engine/core/editing/htmlediting.h"
#include "sky/engine/core/events/DOMWindowEventQueue.h"
#include "sky/engine/core/events/EventPath.h"
#include "sky/engine/core/events/KeyboardEvent.h"
#include "sky/engine/core/events/TextEvent.h"
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
#include "sky/engine/platform/PlatformKeyboardEvent.h"
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

// The amount of time to wait for a cursor update on style and layout changes
// Set to 50Hz, no need to be faster than common screen refresh rate
static const double cursorUpdateInterval = 0.02;

static const int maximumCursorSize = 128;

// It's pretty unlikely that a scale of less than one would ever be used. But all we really
// need to ensure here is that the scale isn't so small that integer overflow can occur when
// dividing cursor sizes (limited above) by the scale.
static const double minimumCursorScale = 0.001;

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

EventHandler::EventHandler(LocalFrame* frame)
    : m_frame(frame)
    , m_mousePressed(false)
    , m_capturesDragging(false)
    , m_mouseDownMayStartSelect(false)
    , m_mouseDownMayStartDrag(false)
    , m_selectionInitiationState(HaveNotStartedSelection)
    , m_hoverTimer(this, &EventHandler::hoverTimerFired)
    , m_cursorUpdateTimer(this, &EventHandler::cursorUpdateTimerFired)
    , m_mouseDownMayStartAutoscroll(false)
    , m_clickCount(0)
    , m_shouldOnlyFireDragOverEvent(false)
    , m_mousePositionIsUnknown(true)
    , m_maxMouseMovedDuration(0)
    , m_didStartDrag(false)
    , m_activeIntervalTimer(this, &EventHandler::activeIntervalTimerFired)
    , m_lastShowPressTimestamp(0)
{
}

EventHandler::~EventHandler()
{
}

void EventHandler::clear()
{
    m_hoverTimer.stop();
    m_cursorUpdateTimer.stop();
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
    m_mousePressNode = nullptr;
    m_mousePressed = false;
    m_capturesDragging = false;
    m_previousWheelScrolledNode = nullptr;
    m_maxMouseMovedDuration = 0;
    m_didStartDrag = false;
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
        && m_frame->selection().isCaretOrRange()) {
        return iBeam;
    }

    RenderObject* renderer = node ? node->renderer() : 0;
    if ((editable || (renderer && renderer->isText() && node->canStartSelection())) && !result.scrollbar())
        return iBeam;
    return pointerCursor();
}

ScrollableArea* EventHandler::associatedScrollableArea(const RenderLayer* layer) const
{
    if (RenderLayerScrollableArea* scrollableArea = layer->scrollableArea()) {
        if (scrollableArea->scrollsOverflow())
            return scrollableArea;
    }

    return 0;
}

void EventHandler::invalidateClick()
{
    m_clickCount = 0;
    m_clickNode = nullptr;
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
    }
}

void EventHandler::activeIntervalTimerFired(Timer<EventHandler>*)
{
    m_activeIntervalTimer.stop();
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

void EventHandler::focusDocumentView()
{
    Page* page = m_frame->page();
    if (!page)
        return;
    page->focusController().focusDocumentView(m_frame);
}

} // namespace blink
