// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/frame/NewEventHandler.h"

#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/NodeRenderingTraversal.h"
#include "sky/engine/core/editing/Editor.h"
#include "sky/engine/core/editing/FrameSelection.h"
#include "sky/engine/core/editing/htmlediting.h"
#include "sky/engine/core/events/GestureEvent.h"
#include "sky/engine/core/events/KeyboardEvent.h"
#include "sky/engine/core/events/PointerEvent.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/page/EventWithHitTestResults.h"
#include "sky/engine/core/rendering/RenderObject.h"
#include "sky/engine/core/rendering/RenderView.h"
#include "sky/engine/platform/KeyboardCodes.h"
#include "sky/engine/platform/geometry/FloatPoint.h"
#include "sky/engine/public/platform/WebInputEvent.h"

namespace blink {

static VisiblePosition visiblePositionForHitTestResult(const HitTestResult& hitTestResult)
{
    Node* innerNode = hitTestResult.innerNode();
    VisiblePosition position(innerNode->renderer()->positionForPoint(hitTestResult.localPoint()));
    if (!position.isNull())
        return position;
    return VisiblePosition(firstPositionInOrBeforeNode(innerNode), DOWNSTREAM);
}

template<typename EventType>
static LayoutPoint positionForEvent(const EventType& event)
{
    return roundedLayoutPoint(FloatPoint(event.x, event.y));
}

NewEventHandler::NewEventHandler(LocalFrame& frame)
    : m_frame(frame)
    , m_suppressNextCharEvent(false)
{
}

NewEventHandler::~NewEventHandler()
{
}

Node* NewEventHandler::targetForKeyboardEvent() const
{
    Document* document = m_frame.document();
    if (Node* focusedElement = document->focusedElement())
        return focusedElement;
    return document->documentElement();
}

Node* NewEventHandler::targetForHitTestResult(const HitTestResult& hitTestResult)
{
    Node* node = hitTestResult.innerNode();
    if (!node)
        return m_frame.document()->documentElement();
    if (node->isTextNode())
        return NodeRenderingTraversal::parent(node);
    return node;
}

HitTestResult NewEventHandler::performHitTest(const LayoutPoint& point)
{
    HitTestResult result(point);
    if (!m_frame.contentRenderer())
        return result;
    m_frame.contentRenderer()->hitTest(HitTestRequest(HitTestRequest::ReadOnly), result);
    return result;
}

bool NewEventHandler::dispatchPointerEvent(Node& target, const WebPointerEvent& event)
{
    RefPtr<PointerEvent> pointerEvent = PointerEvent::create(event);
    // TODO(abarth): Keep track of how many pointers are targeting the same node
    // and only mark the first one as primary.
    return target.dispatchEvent(pointerEvent.release());
}

bool NewEventHandler::dispatchGestureEvent(Node& target, const WebGestureEvent& event)
{
    RefPtr<GestureEvent> gestureEvent = GestureEvent::create(event);
    return target.dispatchEvent(gestureEvent.release());
}

bool NewEventHandler::dispatchKeyboardEvent(Node& target, const WebKeyboardEvent& event)
{
    RefPtr<KeyboardEvent> keyboardEvent = KeyboardEvent::create(event);
    return target.dispatchEvent(keyboardEvent.release());
}

bool NewEventHandler::dispatchClickEvent(Node& capturingTarget, const WebPointerEvent& event)
{
    ASSERT(event.type == WebInputEvent::PointerUp);
    HitTestResult hitTestResult = performHitTest(positionForEvent(event));
    Node* releaseTarget = targetForHitTestResult(hitTestResult);
    Node* clickTarget = NodeRenderingTraversal::commonAncestor(*releaseTarget, capturingTarget);
    if (!clickTarget)
        return true;
    // TODO(abarth): Make a proper gesture event that includes information from the event.
    return clickTarget->dispatchEvent(Event::createCancelableBubble(EventTypeNames::click));
}

void NewEventHandler::updateSelectionForPointerDown(const HitTestResult& hitTestResult, const WebPointerEvent& event)
{
    Node* innerNode = hitTestResult.innerNode();
    if (!innerNode->renderer())
        return;
    if (Position::nodeIsUserSelectNone(innerNode))
        return;
    if (!innerNode->dispatchEvent(Event::createCancelableBubble(EventTypeNames::selectstart)))
        return;
    VisiblePosition position = visiblePositionForHitTestResult(hitTestResult);
    // TODO(abarth): Can we change this to setSelectionIfNeeded?
    m_frame.selection().setNonDirectionalSelectionIfNeeded(VisibleSelection(position), CharacterGranularity);
}

bool NewEventHandler::handlePointerEvent(const WebPointerEvent& event)
{
    if (event.type == WebInputEvent::PointerDown)
        return handlePointerDownEvent(event);
    if (event.type == WebInputEvent::PointerUp)
        return handlePointerUpEvent(event);
    if (event.type == WebInputEvent::PointerMove)
        return handlePointerMoveEvent(event);
    ASSERT(event.type == WebInputEvent::PointerCancel);
    return handlePointerCancelEvent(event);
}

bool NewEventHandler::handleGestureEvent(const WebGestureEvent& event)
{
    HitTestResult hitTestResult = performHitTest(positionForEvent(event));
    RefPtr<Node> target = targetForHitTestResult(hitTestResult);
    return target && !dispatchGestureEvent(*target, event);
}

bool NewEventHandler::handleKeyboardEvent(const WebKeyboardEvent& event)
{
    bool shouldSuppressCharEvent = m_suppressNextCharEvent;
    m_suppressNextCharEvent = false;

    if (event.type == WebInputEvent::Char) {
        if (shouldSuppressCharEvent)
            return true;
        // Do we really need to suppress keypress events for these keys anymore?
        if (event.key == VKEY_BACK
            || event.key == VKEY_ESCAPE)
            return true;
    }

    RefPtr<Node> target = targetForKeyboardEvent();
    bool handled = target && !dispatchKeyboardEvent(*target, event);

    // If the keydown event was handled, we don't want to "generate" a keypress
    // event for that keystroke. However, we'll receive a Char event from the
    // embedder regardless, so we set m_suppressNextCharEvent, will will prevent
    // us from dispatching the keypress event when we receive that Char event.
    if (handled && event.type == WebInputEvent::KeyDown)
        m_suppressNextCharEvent = true;

    return handled;
}

bool NewEventHandler::handlePointerDownEvent(const WebPointerEvent& event)
{
    ASSERT(m_targetForPointer.find(event.pointer) == m_targetForPointer.end());
    HitTestResult hitTestResult = performHitTest(positionForEvent(event));
    RefPtr<Node> target = targetForHitTestResult(hitTestResult);
    if (!target)
        return false;
    m_targetForPointer[event.pointer] = target;
    bool eventSwallowed = !dispatchPointerEvent(*target, event);
    // TODO(abarth): Set the target for the pointer to something determined when
    // dispatching the event.
    updateSelectionForPointerDown(hitTestResult, event);
    return eventSwallowed;
}

bool NewEventHandler::handlePointerUpEvent(const WebPointerEvent& event)
{
    RefPtr<Node> target = m_targetForPointer[event.pointer];
    if (!target)
        return false;
    m_targetForPointer.erase(event.pointer);
    bool eventSwallowed = !dispatchPointerEvent(*target, event);
    // When the user releases the primary pointer, we need to dispatch a tap
    // event to the common ancestor for where the pointer went down and where
    // it came up.
    if (!dispatchClickEvent(*target, event))
        eventSwallowed = true;
    return eventSwallowed;
}

bool NewEventHandler::handlePointerMoveEvent(const WebPointerEvent& event)
{
    RefPtr<Node> target = m_targetForPointer[event.pointer];
    return target && dispatchPointerEvent(*target.get(), event);
}

bool NewEventHandler::handlePointerCancelEvent(const WebPointerEvent& event)
{
    RefPtr<Node> target = m_targetForPointer[event.pointer];
    return target && dispatchPointerEvent(*target, event);
}

}
