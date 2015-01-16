// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/events/PointerEvent.h"

namespace blink {

PointerEvent::~PointerEvent()
{
}

PointerEvent::PointerEvent()
    : PointerEvent(AtomicString(), PointerEventInit())
{
}

PointerEvent::PointerEvent(const AtomicString& type, const PointerEventInit& initializer)
    : m_pointer(initializer.pointer)
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
