// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_EVENTS_POINTEREVENT_H_
#define SKY_ENGINE_CORE_EVENTS_POINTEREVENT_H_

#include "sky/engine/core/events/Event.h"
#include "sky/engine/core/events/EventDispatchMediator.h"
#include "sky/engine/core/frame/LocalDOMWindow.h"

namespace blink {

struct PointerEventInit : public EventInit {
    int pointer = 0;
    String kind;
    double x = 0;
    double y = 0;
    double dx = 0;
    double dy = 0;
    int buttons = 0;
    bool down = false;
    bool primary = false;
    bool obscured = false;
    double pressure = 0;
    double pressureMin = 0;
    double pressureMax = 0;
    double distance = 0;
    double distanceMin = 0;
    double distanceMax = 0;
    double radiusMajor = 0;
    double radiusMinor = 0;
    double radiusMin = 0;
    double radiusMax = 0;
    double orientation = 0;
    double tilt = 0;
};

class PointerEvent : public Event {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<PointerEvent> create()
    {
        return adoptRef(new PointerEvent);
    }
    static PassRefPtr<PointerEvent> create(const AtomicString& type, const PointerEventInit& initializer)
    {
        return adoptRef(new PointerEvent(type, initializer));
    }
    ~PointerEvent() override;

    int pointer() const { return m_pointer; }
    const String& kind() const { return m_kind; }
    double x() const { return m_x; }
    double y() const { return m_y; }
    double dx() const { return m_dx; }
    double dy() const { return m_dy; }
    int buttons() const { return m_buttons; }
    bool down() const { return m_down; }
    bool primary() const { return m_primary; }
    bool obscured() const { return m_obscured; }
    double pressure() const { return m_pressure; }
    double pressureMin() const { return m_pressureMin; }
    double pressureMax() const { return m_pressureMax; }
    double distance() const { return m_distance; }
    double distanceMin() const { return m_distanceMin; }
    double distanceMax() const { return m_distanceMax; }
    double radiusMajor() const { return m_radiusMajor; }
    double radiusMinor() const { return m_radiusMinor; }
    double radiusMin() const { return m_radiusMin; }
    double radiusMax() const { return m_radiusMax; }
    double orientation() const { return m_orientation; }
    double tilt() const { return m_tilt; }

protected:
    PointerEvent();
    PointerEvent(const AtomicString&, const PointerEventInit&);

private:
    int m_pointer;
    String m_kind;
    double m_x;
    double m_y;
    double m_dx;
    double m_dy;
    int m_buttons;
    bool m_down;
    bool m_primary;
    bool m_obscured;
    double m_pressure;
    double m_pressureMin;
    double m_pressureMax;
    double m_distance;
    double m_distanceMin;
    double m_distanceMax;
    double m_radiusMajor;
    double m_radiusMinor;
    double m_radiusMin;
    double m_radiusMax;
    double m_orientation;
    double m_tilt;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_EVENTS_POINTEREVENT_H_
