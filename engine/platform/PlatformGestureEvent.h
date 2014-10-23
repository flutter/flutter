/*
 * Copyright (C) 2011 Apple Inc.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef PlatformGestureEvent_h
#define PlatformGestureEvent_h

#include "platform/PlatformEvent.h"
#include "platform/geometry/FloatPoint.h"
#include "platform/geometry/IntPoint.h"
#include "platform/geometry/IntSize.h"
#include "wtf/Assertions.h"
#include <string.h>

namespace blink {

class PlatformGestureEvent : public PlatformEvent {
public:
    PlatformGestureEvent()
        : PlatformEvent(PlatformEvent::GestureScrollBegin)
    {
        memset(&m_data, 0, sizeof(m_data));
    }

    PlatformGestureEvent(Type type, const IntPoint& position, const IntPoint& globalPosition, const IntSize& area, double timestamp, bool shiftKey, bool ctrlKey, bool altKey, bool metaKey, float deltaX, float deltaY, float velocityX, float velocityY)
        : PlatformEvent(type, shiftKey, ctrlKey, altKey, metaKey, timestamp)
        , m_position(position)
        , m_globalPosition(globalPosition)
        , m_area(area)
    {
        memset(&m_data, 0, sizeof(m_data));
        if (type == PlatformEvent::GestureScrollBegin
            || type == PlatformEvent::GestureScrollEnd
            || type == PlatformEvent::GestureScrollUpdate
            || type == PlatformEvent::GestureScrollUpdateWithoutPropagation) {
            m_data.m_scrollUpdate.m_deltaX = deltaX;
            m_data.m_scrollUpdate.m_deltaY = deltaY;
            m_data.m_scrollUpdate.m_velocityX = velocityX;
            m_data.m_scrollUpdate.m_velocityY = velocityY;
        }
    }

    const IntPoint& position() const { return m_position; } // PlatformWindow coordinates.
    const IntPoint& globalPosition() const { return m_globalPosition; } // Screen coordinates.

    const IntSize& area() const { return m_area; }

    float deltaX() const
    {
        ASSERT(m_type == PlatformEvent::GestureScrollUpdate
            || m_type == PlatformEvent::GestureScrollUpdateWithoutPropagation);
        return m_data.m_scrollUpdate.m_deltaX;
    }

    float deltaY() const
    {
        ASSERT(m_type == PlatformEvent::GestureScrollUpdate
            || m_type == PlatformEvent::GestureScrollUpdateWithoutPropagation);
        return m_data.m_scrollUpdate.m_deltaY;
    }

    int tapCount() const
    {
        ASSERT(m_type == PlatformEvent::GestureTap);
        return m_data.m_tap.m_tapCount;
    }

    float velocityX() const
    {
        ASSERT(m_type == PlatformEvent::GestureScrollUpdate
            || m_type == PlatformEvent::GestureScrollUpdateWithoutPropagation);
        return m_data.m_scrollUpdate.m_velocityX;
    }

    float velocityY() const
    {
        ASSERT(m_type == PlatformEvent::GestureScrollUpdate
            || m_type == PlatformEvent::GestureScrollUpdateWithoutPropagation);
        return m_data.m_scrollUpdate.m_velocityY;
    }

    float scale() const
    {
        ASSERT(m_type == PlatformEvent::GesturePinchUpdate);
        return m_data.m_pinchUpdate.m_scale;
    }

    void applyTouchAdjustment(const IntPoint& adjustedPosition)
    {
        // Update the window-relative position of the event so that the node that was
        // ultimately hit is under this point (i.e. elementFromPoint for the client
        // co-ordinates in a 'click' event should yield the target). The global
        // position is intentionally left unmodified because it's intended to reflect
        // raw co-ordinates unrelated to any content.
        m_position = adjustedPosition;
    }

    bool isScrollEvent() const
    {
        switch (m_type) {
        case GestureScrollBegin:
        case GestureScrollEnd:
        case GestureScrollUpdate:
        case GestureScrollUpdateWithoutPropagation:
        case GestureFlingStart:
        case GesturePinchBegin:
        case GesturePinchEnd:
        case GesturePinchUpdate:
            return true;
        case GestureTap:
        case GestureTapUnconfirmed:
        case GestureTapDown:
        case GestureShowPress:
        case GestureTapDownCancel:
        case GestureTwoFingerTap:
        case GestureLongPress:
        case GestureLongTap:
            return false;
        default:
            ASSERT_NOT_REACHED();
            return false;
        }
    }

protected:
    IntPoint m_position;
    IntPoint m_globalPosition;
    IntSize m_area;

    union {
        struct {
            int m_tapCount;
        } m_tap;

        struct {
            float m_deltaX;
            float m_deltaY;
            float m_velocityX;
            float m_velocityY;
        } m_scrollUpdate;

        struct {
            float m_scale;
        } m_pinchUpdate;
    } m_data;
};

} // namespace blink

#endif // PlatformGestureEvent_h
