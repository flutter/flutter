// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/frame/NewEventHandler.h"

#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/NodeRenderingTraversal.h"
#include "sky/engine/core/editing/Editor.h"
#include "sky/engine/core/editing/FrameSelection.h"
#include "sky/engine/core/editing/htmlediting.h"
#include "sky/engine/core/events/GestureEvent.h"
#include "sky/engine/core/events/KeyboardEvent.h"
#include "sky/engine/core/events/PointerEvent.h"
#include "sky/engine/core/events/WheelEvent.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/FrameView.h"
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
    return document;
}

Node* NewEventHandler::targetForHitTestResult(const HitTestResult& hitTestResult)
{
    Node* node = hitTestResult.innerNode();
    if (!node)
        return m_frame.document();
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

bool NewEventHandler::dispatchPointerEvent(PointerState& state, const WebPointerEvent& event)
{
    RefPtr<PointerEvent> pointerEvent = PointerEvent::create(event);
    pointerEvent->setDx(event.x - state.x);
    pointerEvent->setDy(event.y - state.y);
    state.x = event.x;
    state.y = event.y;
    // TODO(abarth): Keep track of how many pointers are targeting the same node
    // and only mark the first one as primary.
    return state.target->dispatchEvent(pointerEvent.release());
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

bool NewEventHandler::dispatchWheelEvent(Node& target, const WebWheelEvent& event)
{
    RefPtr<WheelEvent> wheelEvent = WheelEvent::create(event);
    return target.dispatchEvent(wheelEvent.release());
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
    if (!innerNode || !innerNode->renderer())
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

bool NewEventHandler::handleWheelEvent(const WebWheelEvent& event)
{
    HitTestResult hitTestResult = performHitTest(positionForEvent(event));
    RefPtr<Node> target = targetForHitTestResult(hitTestResult);
    return target && !dispatchWheelEvent(*target, event);
}

bool NewEventHandler::handlePointerDownEvent(const WebPointerEvent& event)
{
    // In principle, we shouldn't get another pointer down for the same
    // pointer ID, but for mice, we don't get a pointer cancel when you
    // drag outside the window frame on Linux. For now, send the pointer
    // cancel at this point.
    bool alreadyDown = m_stateForPointer.find(event.pointer) != m_stateForPointer.end();
    if (event.kind == WebPointerEvent::Mouse && alreadyDown) {
        WebPointerEvent fakeCancel = event;
        fakeCancel.type = WebInputEvent::PointerCancel;
        handlePointerCancelEvent(fakeCancel);
    }

    DCHECK(!alreadyDown) << "Pointer id " << event.pointer << "already down!";
    HitTestResult hitTestResult = performHitTest(positionForEvent(event));
    RefPtr<Node> target = targetForHitTestResult(hitTestResult);
    if (!target)
        return false;
    PointerState& state = m_stateForPointer[event.pointer];
    state.target = target;
    bool eventSwallowed = !dispatchPointerEvent(state, event);
    // TODO(abarth): Set the target for the pointer to something determined when
    // dispatching the event.
    updateSelectionForPointerDown(hitTestResult, event);
    return eventSwallowed;
}

bool NewEventHandler::handlePointerUpEvent(const WebPointerEvent& event)
{
    auto it = m_stateForPointer.find(event.pointer);
    if (it == m_stateForPointer.end())
        return false;
    PointerState stateCopy = it->second;
    m_stateForPointer.erase(it);
    ASSERT(stateCopy.target);
    bool eventSwallowed = !dispatchPointerEvent(stateCopy, event);
    // When the user releases the primary pointer, we need to dispatch a tap
    // event to the common ancestor for where the pointer went down and where
    // it came up.
    if (!eventSwallowed && !dispatchClickEvent(*stateCopy.target, event))
        eventSwallowed = true;
    return eventSwallowed;
}

bool NewEventHandler::handlePointerMoveEvent(const WebPointerEvent& event)
{
    auto it = m_stateForPointer.find(event.pointer);
    if (it == m_stateForPointer.end())
        return false;
    PointerState& state = it->second;
    ASSERT(state.target);
    return dispatchPointerEvent(state, event);
}

bool NewEventHandler::handlePointerCancelEvent(const WebPointerEvent& event)
{
    auto it = m_stateForPointer.find(event.pointer);
    if (it == m_stateForPointer.end())
        return false;
    PointerState stateCopy = it->second;
    m_stateForPointer.erase(it);
    ASSERT(stateCopy.target);
    return dispatchPointerEvent(stateCopy, event);
}

}
