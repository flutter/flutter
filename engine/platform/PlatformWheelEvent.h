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

#ifndef PlatformWheelEvent_h
#define PlatformWheelEvent_h

#include "platform/PlatformEvent.h"
#include "platform/geometry/IntPoint.h"

namespace blink {

// Wheel events come in two flavors:
// The ScrollByPixelWheelEvent is a fine-grained event that specifies the precise number of pixels to scroll. It is sent directly by MacBook touchpads on OS X,
// and synthesized in other cases where platforms generate line-by-line scrolling events.
// The ScrollByPageWheelEvent indicates that the wheel event should scroll an entire page. In this case WebCore's built in paging behavior is used to page
// up and down (you get the same behavior as if the user was clicking in a scrollbar track to page up or page down).
enum PlatformWheelEventGranularity {
    ScrollByPageWheelEvent,
    ScrollByPixelWheelEvent,
};

#if OS(MACOSX)
enum PlatformWheelEventPhase {
    PlatformWheelEventPhaseNone        = 0,
    PlatformWheelEventPhaseBegan       = 1 << 0,
    PlatformWheelEventPhaseStationary  = 1 << 1,
    PlatformWheelEventPhaseChanged     = 1 << 2,
    PlatformWheelEventPhaseEnded       = 1 << 3,
    PlatformWheelEventPhaseCancelled   = 1 << 4,
    PlatformWheelEventPhaseMayBegin    = 1 << 5,
};
#endif

class PlatformWheelEvent : public PlatformEvent {
public:
    PlatformWheelEvent()
        : PlatformEvent(PlatformEvent::Wheel)
        , m_deltaX(0)
        , m_deltaY(0)
        , m_wheelTicksX(0)
        , m_wheelTicksY(0)
        , m_granularity(ScrollByPixelWheelEvent)
        , m_hasPreciseScrollingDeltas(false)
#if OS(MACOSX)
        , m_phase(PlatformWheelEventPhaseNone)
        , m_momentumPhase(PlatformWheelEventPhaseNone)
        , m_scrollCount(0)
        , m_unacceleratedScrollingDeltaX(0)
        , m_unacceleratedScrollingDeltaY(0)
        , m_canRubberbandLeft(true)
        , m_canRubberbandRight(true)
#endif
    {
    }

    PlatformWheelEvent(IntPoint position, IntPoint globalPosition, float deltaX, float deltaY, float wheelTicksX, float wheelTicksY, PlatformWheelEventGranularity granularity, bool shiftKey, bool ctrlKey, bool altKey, bool metaKey)
        : PlatformEvent(PlatformEvent::Wheel, shiftKey, ctrlKey, altKey, metaKey, 0)
        , m_position(position)
        , m_globalPosition(globalPosition)
        , m_deltaX(deltaX)
        , m_deltaY(deltaY)
        , m_wheelTicksX(wheelTicksX)
        , m_wheelTicksY(wheelTicksY)
        , m_granularity(granularity)
        , m_hasPreciseScrollingDeltas(false)
#if OS(MACOSX)
        , m_phase(PlatformWheelEventPhaseNone)
        , m_momentumPhase(PlatformWheelEventPhaseNone)
        , m_scrollCount(0)
        , m_unacceleratedScrollingDeltaX(0)
        , m_unacceleratedScrollingDeltaY(0)
        , m_canRubberbandLeft(true)
        , m_canRubberbandRight(true)
#endif
    {
    }

    const IntPoint& position() const { return m_position; } // PlatformWindow coordinates.
    const IntPoint& globalPosition() const { return m_globalPosition; } // Screen coordinates.

    float deltaX() const { return m_deltaX; }
    float deltaY() const { return m_deltaY; }

    float wheelTicksX() const { return m_wheelTicksX; }
    float wheelTicksY() const { return m_wheelTicksY; }

    PlatformWheelEventGranularity granularity() const { return m_granularity; }

    bool hasPreciseScrollingDeltas() const { return m_hasPreciseScrollingDeltas; }
    void setHasPreciseScrollingDeltas(bool b) { m_hasPreciseScrollingDeltas = b; }
#if OS(MACOSX)
    PlatformWheelEventPhase phase() const { return m_phase; }
    PlatformWheelEventPhase momentumPhase() const { return m_momentumPhase; }
    unsigned scrollCount() const { return m_scrollCount; }
    float unacceleratedScrollingDeltaX() const { return m_unacceleratedScrollingDeltaX; }
    float unacceleratedScrollingDeltaY() const { return m_unacceleratedScrollingDeltaY; }
    bool useLatchedEventNode() const { return m_momentumPhase == PlatformWheelEventPhaseBegan || m_momentumPhase == PlatformWheelEventPhaseChanged; }
    bool canRubberbandLeft() const { return m_canRubberbandLeft; }
    bool canRubberbandRight() const { return m_canRubberbandRight; }
#else
    bool useLatchedEventNode() const { return false; }
#endif

protected:
    IntPoint m_position;
    IntPoint m_globalPosition;
    float m_deltaX;
    float m_deltaY;
    float m_wheelTicksX;
    float m_wheelTicksY;
    PlatformWheelEventGranularity m_granularity;
    bool m_hasPreciseScrollingDeltas;
#if OS(MACOSX)
    PlatformWheelEventPhase m_phase;
    PlatformWheelEventPhase m_momentumPhase;
    unsigned m_scrollCount;
    float m_unacceleratedScrollingDeltaX;
    float m_unacceleratedScrollingDeltaY;
    bool m_canRubberbandLeft;
    bool m_canRubberbandRight;
#endif
};

} // namespace blink

#endif // PlatformWheelEvent_h
