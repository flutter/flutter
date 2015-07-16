// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_EVENTS_WHEELEVENT_H_
#define SKY_ENGINE_CORE_EVENTS_WHEELEVENT_H_

#include "sky/engine/core/events/Event.h"
#include "sky/engine/public/platform/WebInputEvent.h"

namespace blink {

struct WheelEventInit : public EventInit {
    double x = 0;
    double y = 0;
    double offsetX = 0;
    double offsetY = 0;
};

class WheelEvent : public Event {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<WheelEvent> create()
    {
        return adoptRef(new WheelEvent);
    }
    static PassRefPtr<WheelEvent> create(const WebWheelEvent& event)
    {
        return adoptRef(new WheelEvent(event));
    }
    static PassRefPtr<WheelEvent> create(const AtomicString& type, const WheelEventInit& initializer)
    {
        return adoptRef(new WheelEvent(type, initializer));
    }

    ~WheelEvent() override;
    const AtomicString& interfaceName() const override;

    double x() const { return m_x; }
    double y() const { return m_y; }
    double offsetX() const { return m_offsetX; }
    double offsetY() const { return m_offsetY; }

private:
    WheelEvent();
    explicit WheelEvent(const WebWheelEvent& event);
    WheelEvent(const AtomicString&, const WheelEventInit&);

    double m_x;
    double m_y;
    double m_offsetX;
    double m_offsetY;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_EVENTS_WHEELEVENT_H_
