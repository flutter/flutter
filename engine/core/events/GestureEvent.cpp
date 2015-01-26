// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/events/GestureEvent.h"
#include "sky/engine/wtf/text/AtomicString.h"

namespace blink {

static AtomicString stringForType(WebInputEvent::Type type)
{
    if (type == WebInputEvent::GestureScrollBegin)
        return EventTypeNames::gesturescrollstart;
    if (type == WebInputEvent::GestureScrollEnd)
        return EventTypeNames::gesturescrollend;
    if (type == WebInputEvent::GestureScrollUpdate)
        return EventTypeNames::gesturescrollupdate;
    if (type == WebInputEvent::GestureScrollUpdateWithoutPropagation)
        return EventTypeNames::gesturescrollupdate;
    if (type == WebInputEvent::GestureFlingStart)
        return EventTypeNames::gestureflingstart;
    if (type == WebInputEvent::GestureFlingCancel)
        return EventTypeNames::gestureflingcancel;
    if (type == WebInputEvent::GestureShowPress)
        return EventTypeNames::gestureshowpress;
    if (type == WebInputEvent::GestureTap)
        return EventTypeNames::gesturetap;
    if (type == WebInputEvent::GestureTapUnconfirmed)
        return EventTypeNames::gesturetapunconfirmed;
    if (type == WebInputEvent::GestureTapDown)
        return EventTypeNames::gesturetapdown;
    if (type == WebInputEvent::GestureTapCancel)
        return EventTypeNames::gesturetapcancel;
    if (type == WebInputEvent::GestureDoubleTap)
        return EventTypeNames::gesturedoubletap;
    if (type == WebInputEvent::GestureTwoFingerTap)
        return EventTypeNames::gesturetwofingertap;
    if (type == WebInputEvent::GestureLongPress)
        return EventTypeNames::gesturelongpress;
    if (type == WebInputEvent::GestureLongTap)
        return EventTypeNames::gesturelongtap;
    if (type == WebInputEvent::GesturePinchBegin)
        return EventTypeNames::gesturepinchstart;
    if (type == WebInputEvent::GesturePinchEnd)
        return EventTypeNames::gesturepinchend;
    if (type == WebInputEvent::GesturePinchUpdate)
        return EventTypeNames::gesturepinchupdate;
    ASSERT_NOT_REACHED();
    return AtomicString();
}

GestureEvent::~GestureEvent()
{
}

const AtomicString& GestureEvent::interfaceName() const
{
    return EventNames::GestureEvent;
}

GestureEvent::GestureEvent()
    : GestureEvent(AtomicString(), GestureEventInit())
{
}

GestureEvent::GestureEvent(const WebGestureEvent& event)
    : Event(stringForType(event.type), true, true)
    , m_x(event.x)
    , m_y(event.y)
    , m_dx(0)
    , m_dy(0)
    , m_velocityX(0)
    , m_velocityY(0)
{
    if (event.type == WebInputEvent::GestureFlingStart) {
        m_velocityX = event.data.flingStart.velocityX;
        m_velocityY = event.data.flingStart.velocityY;
    } else if (event.type == WebInputEvent::GestureScrollUpdate
            || event.type == WebInputEvent::GestureScrollUpdateWithoutPropagation) {
        m_dx = event.data.scrollUpdate.deltaX;
        m_dy = event.data.scrollUpdate.deltaY;
        m_velocityX = event.data.scrollUpdate.velocityX;
        m_velocityY = event.data.scrollUpdate.velocityY;
    }
}

GestureEvent::GestureEvent(const AtomicString& type, const GestureEventInit& initializer)
    : Event(type, initializer)
    , m_x(initializer.x)
    , m_y(initializer.y)
    , m_dx(initializer.dx)
    , m_dy(initializer.dy)
    , m_velocityX(initializer.velocityX)
    , m_velocityY(initializer.velocityY)
{
}

} // namespace blink
