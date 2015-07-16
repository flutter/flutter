// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_EVENTS_GESTUREEVENT_H_
#define SKY_ENGINE_CORE_EVENTS_GESTUREEVENT_H_

#include "sky/engine/core/events/Event.h"
#include "sky/engine/public/platform/WebInputEvent.h"

namespace blink {

struct GestureEventInit : public EventInit {
    int primaryPointer = 0;
    double x = 0;
    double y = 0;
    double dx = 0;
    double dy = 0;
    double velocityX = 0;
    double velocityY = 0;
};

class GestureEvent : public Event {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<GestureEvent> create()
    {
        return adoptRef(new GestureEvent);
    }
    static PassRefPtr<GestureEvent> create(const WebGestureEvent& event)
    {
        return adoptRef(new GestureEvent(event));
    }
    static PassRefPtr<GestureEvent> create(const AtomicString& type, const GestureEventInit& initializer)
    {
        return adoptRef(new GestureEvent(type, initializer));
    }

    ~GestureEvent() override;
    const AtomicString& interfaceName() const override;

    int primaryPointer() const { return m_primaryPointer; }
    float x() const { return m_x; }
    float y() const { return m_y; }
    float dx() const { return m_dx; }
    float dy() const { return m_dy; }
    float velocityX() const { return m_velocityX; }
    float velocityY() const { return m_velocityY; }

private:
    GestureEvent();
    explicit GestureEvent(const WebGestureEvent&);
    GestureEvent(const AtomicString& type, const GestureEventInit&);

    int m_primaryPointer;
    float m_x;
    float m_y;
    float m_dx;
    float m_dy;
    float m_velocityX;
    float m_velocityY;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_EVENTS_GESTUREEVENT_H_
