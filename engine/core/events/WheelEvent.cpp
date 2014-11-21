/*
 * Copyright (C) 2001 Peter Kelly (pmk@post.com)
 * Copyright (C) 2001 Tobias Anton (anton@stud.fbi.fh-darmstadt.de)
 * Copyright (C) 2006 Samuel Weinig (sam.weinig@gmail.com)
 * Copyright (C) 2003, 2005, 2006, 2008, 2010 Apple Inc. All rights reserved.
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
 */

#include "sky/engine/config.h"
#include "sky/engine/core/events/WheelEvent.h"

#include "sky/engine/platform/PlatformMouseEvent.h"
#include "sky/engine/platform/PlatformWheelEvent.h"

namespace blink {

WheelEventInit::WheelEventInit()
    : deltaX(0)
    , deltaY(0)
    , deltaZ(0)
    , wheelDeltaX(0)
    , wheelDeltaY(0)
    , deltaMode(WheelEvent::DOM_DELTA_PIXEL)
{
}

WheelEvent::WheelEvent()
    : m_deltaX(0)
    , m_deltaY(0)
    , m_deltaZ(0)
    , m_deltaMode(DOM_DELTA_PIXEL)
{
}

WheelEvent::WheelEvent(const AtomicString& type, const WheelEventInit& initializer)
    : MouseEvent(type, initializer)
    , m_wheelDelta(initializer.wheelDeltaX ? initializer.wheelDeltaX : -initializer.deltaX, initializer.wheelDeltaY ? initializer.wheelDeltaY : -initializer.deltaY)
    , m_deltaX(initializer.deltaX ? initializer.deltaX : -initializer.wheelDeltaX)
    , m_deltaY(initializer.deltaY ? initializer.deltaY : -initializer.wheelDeltaY)
    , m_deltaZ(initializer.deltaZ)
    , m_deltaMode(initializer.deltaMode)
{
}

WheelEvent::WheelEvent(const FloatPoint& wheelTicks, const FloatPoint& rawDelta, unsigned deltaMode,
    PassRefPtr<AbstractView> view, const IntPoint& screenLocation, const IntPoint& pageLocation,
    bool ctrlKey, bool altKey, bool shiftKey, bool metaKey)
    : MouseEvent(EventTypeNames::wheel, true, true, view, 0, screenLocation.x(), screenLocation.y(),
        pageLocation.x(), pageLocation.y(), 0, 0, ctrlKey, altKey, shiftKey, metaKey, 0,
        nullptr, false, PlatformMouseEvent::RealOrIndistinguishable)
    , m_wheelDelta(wheelTicks.x() * TickMultiplier, wheelTicks.y() * TickMultiplier)
    , m_deltaX(-rawDelta.x())
    , m_deltaY(-rawDelta.y())
    , m_deltaZ(0)
    , m_deltaMode(deltaMode)
{
}

const AtomicString& WheelEvent::interfaceName() const
{
    return EventNames::WheelEvent;
}

bool WheelEvent::isMouseEvent() const
{
    return false;
}

bool WheelEvent::isWheelEvent() const
{
    return true;
}

inline static unsigned deltaMode(const PlatformWheelEvent& event)
{
    return event.granularity() == ScrollByPageWheelEvent ? WheelEvent::DOM_DELTA_PAGE : WheelEvent::DOM_DELTA_PIXEL;
}

PassRefPtr<WheelEventDispatchMediator> WheelEventDispatchMediator::create(const PlatformWheelEvent& event, PassRefPtr<AbstractView> view)
{
    return adoptRef(new WheelEventDispatchMediator(event, view));
}

WheelEventDispatchMediator::WheelEventDispatchMediator(const PlatformWheelEvent& event, PassRefPtr<AbstractView> view)
{
    if (!(event.deltaX() || event.deltaY()))
        return;

    setEvent(WheelEvent::create(FloatPoint(event.wheelTicksX(), event.wheelTicksY()), FloatPoint(event.deltaX(), event.deltaY()),
        deltaMode(event), view, event.globalPosition(), event.position(),
        event.ctrlKey(), event.altKey(), event.shiftKey(), event.metaKey()));
}

WheelEvent* WheelEventDispatchMediator::event() const
{
    return toWheelEvent(EventDispatchMediator::event());
}

bool WheelEventDispatchMediator::dispatchEvent(EventDispatcher* dispatcher) const
{
    ASSERT(event());
    return EventDispatchMediator::dispatchEvent(dispatcher) && !event()->defaultHandled();
}

} // namespace blink
