/*
 * Copyright (C) 2001 Peter Kelly (pmk@post.com)
 * Copyright (C) 2001 Tobias Anton (anton@stud.fbi.fh-darmstadt.de)
 * Copyright (C) 2006 Samuel Weinig (sam.weinig@gmail.com)
 * Copyright (C) 2003, 2004, 2005, 2006 Apple Computer, Inc.
 * Copyright (C) 2013 Samsung Electronics.
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

#ifndef BeforeUnloadEvent_h
#define BeforeUnloadEvent_h

#include "core/events/Event.h"

namespace blink {

class BeforeUnloadEvent FINAL : public Event {
    DEFINE_WRAPPERTYPEINFO();
public:
    virtual ~BeforeUnloadEvent();

    static PassRefPtrWillBeRawPtr<BeforeUnloadEvent> create()
    {
        return adoptRefWillBeNoop(new BeforeUnloadEvent);
    }

    virtual bool isBeforeUnloadEvent() const OVERRIDE;

    void setReturnValue(const String& returnValue) { m_returnValue = returnValue; }
    String returnValue() const { return m_returnValue; }

    virtual const AtomicString& interfaceName() const OVERRIDE { return EventNames::BeforeUnloadEvent; }

    virtual void trace(Visitor*) OVERRIDE;

private:
    BeforeUnloadEvent();

    String m_returnValue;
};

DEFINE_EVENT_TYPE_CASTS(BeforeUnloadEvent);

} // namespace blink

#endif // BeforeUnloadEvent_h
