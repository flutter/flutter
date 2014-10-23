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

#ifndef PlatformTouchPoint_h
#define PlatformTouchPoint_h

#include "platform/geometry/FloatPoint.h"

namespace blink {

class PlatformTouchPoint {
public:
    enum State {
        TouchReleased,
        TouchPressed,
        TouchMoved,
        TouchStationary,
        TouchCancelled,
        TouchStateEnd // Placeholder: must remain the last item.
    };

    // This is necessary for us to be able to build synthetic events.
    PlatformTouchPoint()
        : m_id(0)
        , m_rotationAngle(0)
        , m_force(0)
    {
    }

    unsigned id() const { return m_id; }
    State state() const { return m_state; }
    FloatPoint screenPos() const { return m_screenPos; }
    FloatPoint pos() const { return m_pos; }
    FloatSize radius() const { return m_radius; }
    float rotationAngle() const { return m_rotationAngle; }
    float force() const { return m_force; }

protected:
    unsigned m_id;
    State m_state;
    FloatPoint m_screenPos;
    FloatPoint m_pos;
    FloatSize m_radius;
    float m_rotationAngle;
    float m_force;
};

}

#endif // PlatformTouchPoint_h
