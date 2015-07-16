// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/events/WheelEvent.h"

namespace blink {

WheelEvent::~WheelEvent()
{
}

const AtomicString& WheelEvent::interfaceName() const
{
    return EventNames::WheelEvent;
}

WheelEvent::WheelEvent()
    : WheelEvent(AtomicString(), WheelEventInit())
{
}

WheelEvent::WheelEvent(const WebWheelEvent& event)
    : Event(EventTypeNames::wheel, true, true)
    , m_x(event.x)
    , m_y(event.y)
    , m_offsetX(event.offsetX)
    , m_offsetY(event.offsetY)
{
    m_timeStamp = event.timeStampMS;
}

WheelEvent::WheelEvent(const AtomicString& type, const WheelEventInit& initializer)
    : Event(type, initializer)
    , m_x(initializer.x)
    , m_y(initializer.y)
    , m_offsetX(initializer.offsetX)
    , m_offsetY(initializer.offsetY)
{
}

} // namespace blink
