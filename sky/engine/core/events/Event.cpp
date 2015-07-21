/*
 * Copyright (C) 2001 Peter Kelly (pmk@post.com)
 * Copyright (C) 2001 Tobias Anton (anton@stud.fbi.fh-darmstadt.de)
 * Copyright (C) 2006 Samuel Weinig (sam.weinig@gmail.com)
 * Copyright (C) 2003, 2005, 2006, 2008 Apple Inc. All rights reserved.
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

#include "sky/engine/core/events/Event.h"

#include "gen/sky/core/EventHeaders.h"
#include "gen/sky/core/EventInterfaces.h"
#include "sky/engine/core/dom/StaticNodeList.h"
#include "sky/engine/wtf/CurrentTime.h"

namespace blink {

Event::Event()
    : m_timeStamp(currentTimeMS())
    , m_canBubble(false)
    , m_cancelable(false)
    , m_propagationStopped(false)
    , m_immediatePropagationStopped(false)
    , m_defaultPrevented(false)
    , m_defaultHandled(false)
    , m_cancelBubble(false)
    , m_eventPhase(0)
{
}

Event::Event(const AtomicString& eventType, bool canBubbleArg, bool cancelableArg)
    : m_timeStamp(currentTimeMS())
    , m_type(eventType)
    , m_canBubble(canBubbleArg)
    , m_cancelable(cancelableArg)
    , m_propagationStopped(false)
    , m_immediatePropagationStopped(false)
    , m_defaultPrevented(false)
    , m_defaultHandled(false)
    , m_cancelBubble(false)
    , m_eventPhase(0)
{
}

Event::Event(const AtomicString& eventType, const EventInit& initializer)
    : m_timeStamp(currentTimeMS())
    , m_type(eventType)
    , m_canBubble(initializer.bubbles)
    , m_cancelable(initializer.cancelable)
    , m_propagationStopped(false)
    , m_immediatePropagationStopped(false)
    , m_defaultPrevented(false)
    , m_defaultHandled(false)
    , m_cancelBubble(false)
    , m_eventPhase(0)
{
}

Event::~Event()
{
}

void Event::initEvent(const AtomicString& eventTypeArg, bool canBubbleArg, bool cancelableArg)
{
    m_propagationStopped = false;
    m_immediatePropagationStopped = false;
    m_defaultPrevented = false;

    m_type = eventTypeArg;
    m_canBubble = canBubbleArg;
    m_cancelable = cancelableArg;
}

bool Event::legacyReturnValue() const
{
    return !defaultPrevented();
}

void Event::setLegacyReturnValue(bool returnValue)
{
    setDefaultPrevented(!returnValue);
}

const AtomicString& Event::interfaceName() const
{
    return EventNames::Event;
}

bool Event::isUIEvent() const
{
    return false;
}

bool Event::isKeyboardEvent() const
{
    return false;
}

bool Event::isDragEvent() const
{
    return false;
}

bool Event::isClipboardEvent() const
{
    return false;
}

bool Event::isBeforeTextInsertedEvent() const
{
    return false;
}

void Event::setUnderlyingEvent(PassRefPtr<Event> ue)
{
    // Prohibit creation of a cycle -- just do nothing in that case.
    for (Event* e = ue.get(); e; e = e->underlyingEvent())
        if (e == this)
            return;
    m_underlyingEvent = ue;
}

} // namespace blink
