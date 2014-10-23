/*
   Copyright (C) 2000 Simon Hausmann <hausmann@kde.org>
   Copyright (C) 2006 Apple Computer, Inc.

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

#ifndef EventWithHitTestResults_h
#define EventWithHitTestResults_h

#include "core/rendering/HitTestResult.h"
#include "platform/PlatformEvent.h"
#include "platform/PlatformGestureEvent.h"
#include "platform/PlatformMouseEvent.h"

namespace blink {

class Scrollbar;

template <typename EventType>
class EventWithHitTestResults {
    STACK_ALLOCATED();

public:
    EventWithHitTestResults(const EventType& event, const HitTestResult& hitTestResult)
        : m_event(event)
        , m_hitTestResult(hitTestResult)
    {
    }

    const EventType& event() const { return m_event; }
    const HitTestResult& hitTestResult() const { return m_hitTestResult; }
    LayoutPoint localPoint() const { return m_hitTestResult.localPoint(); }
    Scrollbar* scrollbar() const { return m_hitTestResult.scrollbar(); }
    bool isOverLink() const { return m_hitTestResult.isOverLink(); }
    bool isOverWidget() const { return m_hitTestResult.isOverWidget(); }
    Node* targetNode() const { return m_hitTestResult.targetNode(); }

private:
    EventType m_event;
    HitTestResult m_hitTestResult;
};

typedef EventWithHitTestResults<PlatformMouseEvent> MouseEventWithHitTestResults;

typedef EventWithHitTestResults<PlatformGestureEvent> GestureEventWithHitTestResults;

} // namespace blink

#endif // EventWithHitTestResults_h
