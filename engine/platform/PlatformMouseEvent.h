/*
 * Copyright (C) 2004, 2005, 2006, 2009 Apple Inc. All rights reserved.
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

#ifndef PlatformMouseEvent_h
#define PlatformMouseEvent_h

#include "platform/PlatformEvent.h"
#include "platform/geometry/IntPoint.h"

namespace blink {

// These button numbers match the ones used in the DOM API, 0 through 2, except for NoButton which isn't specified.
enum MouseButton { NoButton = -1, LeftButton, MiddleButton, RightButton };

class PlatformMouseEvent : public PlatformEvent {
public:
    enum SyntheticEventType {
        // Real mouse input events or synthetic events that behave just like real events
        RealOrIndistinguishable,
        // Mouse events derived from touch input
        FromTouch,
    };

    PlatformMouseEvent()
        : PlatformEvent(PlatformEvent::MouseMoved)
        , m_button(NoButton)
        , m_clickCount(0)
        , m_synthesized(RealOrIndistinguishable)
        , m_modifierFlags(0)
    {
    }

    PlatformMouseEvent(const IntPoint& position, const IntPoint& globalPosition, MouseButton button, PlatformEvent::Type type, int clickCount, Modifiers modifiers, double timestamp)
        : PlatformEvent(type, modifiers, timestamp)
        , m_position(position)
        , m_globalPosition(globalPosition)
        , m_button(button)
        , m_clickCount(clickCount)
        , m_synthesized(RealOrIndistinguishable)
        , m_modifierFlags(0)
    {
    }

    PlatformMouseEvent(const IntPoint& position, const IntPoint& globalPosition, MouseButton button, PlatformEvent::Type type, int clickCount, Modifiers modifiers, SyntheticEventType synthesized, double timestamp)
        : PlatformEvent(type, modifiers, timestamp)
        , m_position(position)
        , m_globalPosition(globalPosition)
        , m_button(button)
        , m_clickCount(clickCount)
        , m_synthesized(synthesized)
        , m_modifierFlags(0)
    {
    }

    PlatformMouseEvent(const IntPoint& position, const IntPoint& globalPosition, MouseButton button, PlatformEvent::Type type, int clickCount, bool shiftKey, bool ctrlKey, bool altKey, bool metaKey, SyntheticEventType synthesized, double timestamp)
        : PlatformEvent(type, shiftKey, ctrlKey, altKey, metaKey, timestamp)
        , m_position(position)
        , m_globalPosition(globalPosition)
        , m_button(button)
        , m_clickCount(clickCount)
        , m_synthesized(synthesized)
        , m_modifierFlags(0)
    {
    }

    const IntPoint& position() const { return m_position; }
    const IntPoint& globalPosition() const { return m_globalPosition; }
    const IntPoint& movementDelta() const { return m_movementDelta; }

    MouseButton button() const { return m_button; }
    int clickCount() const { return m_clickCount; }
    unsigned modifierFlags() const { return m_modifierFlags; }
    bool fromTouch() const { return m_synthesized == FromTouch; }
    SyntheticEventType syntheticEventType() const { return m_synthesized; }

protected:
    IntPoint m_position;
    IntPoint m_globalPosition;
    IntPoint m_movementDelta;
    MouseButton m_button;
    int m_clickCount;
    SyntheticEventType m_synthesized;
    unsigned m_modifierFlags;
};

} // namespace blink

#endif // PlatformMouseEvent_h
