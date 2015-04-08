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
#include "sky/engine/bindings/exception_state_placeholder.h"
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
#include "sky/engine/core/page/ChromeClient.h"
#include "sky/engine/core/page/EditorClient.h"
#include "sky/engine/core/page/FocusController.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/rendering/HitTestRequest.h"
#include "sky/engine/core/rendering/HitTestResult.h"
#include "sky/engine/core/rendering/RenderLayer.h"
#include "sky/engine/core/rendering/RenderView.h"
#include "sky/engine/core/rendering/style/RenderStyle.h"
#include "sky/engine/platform/TraceEvent.h"
#include "sky/engine/platform/KeyboardCodes.h"
#include "sky/engine/platform/geometry/FloatPoint.h"
#include "sky/engine/platform/graphics/Image.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/Assertions.h"
#include "sky/engine/wtf/CurrentTime.h"
#include "sky/engine/wtf/StdLibExtras.h"
#include "sky/engine/wtf/TemporaryChange.h"

namespace blink {

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
    , m_capturesDragging(false)
    , m_selectionInitiationState(HaveNotStartedSelection)
    , m_clickCount(0)
    , m_shouldOnlyFireDragOverEvent(false)
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
    m_activeIntervalTimer.stop();
    m_clickCount = 0;
    m_clickNode = nullptr;
    m_dragTarget = nullptr;
    m_shouldOnlyFireDragOverEvent = false;
    m_capturesDragging = false;
    m_didStartDrag = false;
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

void EventHandler::invalidateClick()
{
    m_clickCount = 0;
    m_clickNode = nullptr;
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
        if (event->key() == VKEY_TAB)
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
    return false;
}

// TODO(abarth): This should just be targetForKeyboardEvent
static Node* eventTargetNodeForDocument(Document* document)
{
    if (Node* node = document->focusedElement())
        return node;
    return document;
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
