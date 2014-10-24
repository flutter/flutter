/*
 * Copyright (C) 2001 Peter Kelly (pmk@post.com)
 * Copyright (C) 2001 Tobias Anton (anton@stud.fbi.fh-darmstadt.de)
 * Copyright (C) 2006 Samuel Weinig (sam.weinig@gmail.com)
 * Copyright (C) 2003, 2004, 2005, 2006, 2008, 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Samsung Electronics. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

#ifndef WheelEvent_h
#define WheelEvent_h

#include "core/events/EventDispatchMediator.h"
#include "core/events/MouseEvent.h"
#include "platform/geometry/FloatPoint.h"

namespace blink {

class PlatformWheelEvent;

struct WheelEventInit : public MouseEventInit {
    WheelEventInit();

    double deltaX;
    double deltaY;
    double deltaZ;
    int wheelDeltaX; // Deprecated.
    int wheelDeltaY; // Deprecated.
    unsigned deltaMode;
};

class WheelEvent final : public MouseEvent {
    DEFINE_WRAPPERTYPEINFO();
public:
    enum { TickMultiplier = 120 };

    enum DeltaMode {
        DOM_DELTA_PIXEL = 0,
        DOM_DELTA_LINE,
        DOM_DELTA_PAGE
    };

    static PassRefPtrWillBeRawPtr<WheelEvent> create()
    {
        return adoptRefWillBeNoop(new WheelEvent);
    }

    static PassRefPtrWillBeRawPtr<WheelEvent> create(const AtomicString& type, const WheelEventInit& initializer)
    {
        return adoptRefWillBeNoop(new WheelEvent(type, initializer));
    }

    static PassRefPtrWillBeRawPtr<WheelEvent> create(const FloatPoint& wheelTicks,
        const FloatPoint& rawDelta, unsigned deltaMode, PassRefPtrWillBeRawPtr<AbstractView> view,
        const IntPoint& screenLocation, const IntPoint& pageLocation,
        bool ctrlKey, bool altKey, bool shiftKey, bool metaKey)
    {
        return adoptRefWillBeNoop(new WheelEvent(wheelTicks, rawDelta, deltaMode, view,
        screenLocation, pageLocation, ctrlKey, altKey, shiftKey, metaKey));
    }

    double deltaX() const { return m_deltaX; } // Positive when scrolling right.
    double deltaY() const { return m_deltaY; } // Positive when scrolling down.
    double deltaZ() const { return m_deltaZ; }
    int wheelDelta() const { return wheelDeltaY() ? wheelDeltaY() : wheelDeltaX(); } // Deprecated.
    int wheelDeltaX() const { return m_wheelDelta.x(); } // Deprecated, negative when scrolling right.
    int wheelDeltaY() const { return m_wheelDelta.y(); } // Deprecated, negative when scrolling down.
    unsigned deltaMode() const { return m_deltaMode; }
    float ticksX() const { return static_cast<float>(m_wheelDelta.x()) / TickMultiplier; }
    float ticksY() const { return static_cast<float>(m_wheelDelta.y()) / TickMultiplier; }

    virtual const AtomicString& interfaceName() const override;
    virtual bool isMouseEvent() const override;
    virtual bool isWheelEvent() const override;

    virtual void trace(Visitor*) override;

private:
    WheelEvent();
    WheelEvent(const AtomicString&, const WheelEventInit&);
    WheelEvent(const FloatPoint& wheelTicks, const FloatPoint& rawDelta,
        unsigned, PassRefPtrWillBeRawPtr<AbstractView>, const IntPoint& screenLocation, const IntPoint& pageLocation,
        bool ctrlKey, bool altKey, bool shiftKey, bool metaKey);

    IntPoint m_wheelDelta;
    double m_deltaX;
    double m_deltaY;
    double m_deltaZ;
    unsigned m_deltaMode;
};

DEFINE_EVENT_TYPE_CASTS(WheelEvent);

class WheelEventDispatchMediator final : public EventDispatchMediator {
public:
    static PassRefPtrWillBeRawPtr<WheelEventDispatchMediator> create(const PlatformWheelEvent&, PassRefPtrWillBeRawPtr<AbstractView>);
private:
    WheelEventDispatchMediator(const PlatformWheelEvent&, PassRefPtrWillBeRawPtr<AbstractView>);
    WheelEvent* event() const;
    virtual bool dispatchEvent(EventDispatcher*) const override;
};

} // namespace blink

#endif // WheelEvent_h
