// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/events/PointerEvent.h"

namespace blink {

static AtomicString stringForType(WebInputEvent::Type type)
{
    if (type == WebInputEvent::PointerDown)
        return EventTypeNames::pointerdown;
    if (type == WebInputEvent::PointerUp)
        return EventTypeNames::pointerup;
    if (type == WebInputEvent::PointerMove)
        return EventTypeNames::pointermove;
    if (type == WebInputEvent::PointerCancel)
        return EventTypeNames::pointercancel;
    ASSERT_NOT_REACHED();
    return AtomicString();
}

static String stringForKind(WebPointerEvent::Kind kind)
{
    switch (kind) {
    case WebPointerEvent::Touch:
        return "touch";
    case WebPointerEvent::Mouse:
        return "mouse";
    case WebPointerEvent::Stylus:
        return "stylus";
    }
    ASSERT_NOT_REACHED();
    return String();
}

PointerEvent::~PointerEvent()
{
}

const AtomicString& PointerEvent::interfaceName() const
{
    return EventNames::PointerEvent;
}

PointerEvent::PointerEvent()
    : PointerEvent(AtomicString(), PointerEventInit())
{
}

PointerEvent::PointerEvent(const WebPointerEvent& event)
    : Event(stringForType(event.type), true, true)
    , m_pointer(event.pointer)
    , m_kind(stringForKind(event.kind))
    , m_x(event.x)
    , m_y(event.y)
    , m_dx(event.dx)
    , m_dy(event.dy)
    , m_buttons(event.buttons)
    , m_down(false)
    , m_primary(false)
    , m_obscured(false)
    , m_pressure(event.pressure)
    , m_pressureMin(event.pressureMin)
    , m_pressureMax(event.pressureMax)
    , m_distance(event.distance)
    , m_distanceMin(event.distanceMin)
    , m_distanceMax(event.distanceMax)
    , m_radiusMajor(event.radiusMajor)
    , m_radiusMinor(event.radiusMinor)
    , m_radiusMin(event.radiusMin)
    , m_radiusMax(event.radiusMax)
    , m_orientation(event.orientation)
    , m_tilt(event.tilt)
{
}

PointerEvent::PointerEvent(const AtomicString& type, const PointerEventInit& initializer)
    : Event(type, initializer)
    , m_pointer(initializer.pointer)
    , m_kind(initializer.kind)
    , m_x(initializer.x)
    , m_y(initializer.y)
    , m_dx(initializer.dx)
    , m_dy(initializer.dy)
    , m_buttons(initializer.buttons)
    , m_down(initializer.down)
    , m_primary(initializer.primary)
    , m_obscured(initializer.obscured)
    , m_pressure(initializer.pressure)
    , m_pressureMin(initializer.pressureMin)
    , m_pressureMax(initializer.pressureMax)
    , m_distance(initializer.distance)
    , m_distanceMin(initializer.distanceMin)
    , m_distanceMax(initializer.distanceMax)
    , m_radiusMajor(initializer.radiusMajor)
    , m_radiusMinor(initializer.radiusMinor)
    , m_radiusMin(initializer.radiusMin)
    , m_radiusMax(initializer.radiusMax)
    , m_orientation(initializer.orientation)
    , m_tilt(initializer.tilt)
{
}

} // namespace blink
