/*
    Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public License
    along with this library; see the file COPYING.LIB.  If not, write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110-1301, USA.
*/

#ifndef PlatformTouchEvent_h
#define PlatformTouchEvent_h

#include "platform/PlatformEvent.h"
#include "platform/PlatformTouchPoint.h"
#include "wtf/Vector.h"

namespace blink {

class PlatformTouchEvent : public PlatformEvent {
public:
    PlatformTouchEvent()
        : PlatformEvent(PlatformEvent::TouchStart)
        , m_cancelable(true)
    {
    }

    const Vector<PlatformTouchPoint>& touchPoints() const { return m_touchPoints; }

    bool cancelable() const { return m_cancelable; }

protected:
    Vector<PlatformTouchPoint> m_touchPoints;
    bool m_cancelable;
};

}

#endif // PlatformTouchEvent_h
