/*
 * Copyright (C) 2012 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef EventSender_h
#define EventSender_h

#include "platform/Timer.h"
#include "wtf/Vector.h"
#include "wtf/text/AtomicString.h"

namespace blink {

template<typename T> class EventSender {
    WTF_MAKE_NONCOPYABLE(EventSender); WTF_MAKE_FAST_ALLOCATED;
public:
    explicit EventSender(const AtomicString& eventType);

    const AtomicString& eventType() const { return m_eventType; }
    void dispatchEventSoon(T*);
    void cancelEvent(T*);
    void dispatchPendingEvents();

#if ENABLE(ASSERT)
    bool hasPendingEvents(T* sender) const
    {
        return m_dispatchSoonList.find(sender) != kNotFound || m_dispatchingList.find(sender) != kNotFound;
    }
#endif

private:
    void timerFired(Timer<EventSender<T> >*) { dispatchPendingEvents(); }

    AtomicString m_eventType;
    Timer<EventSender<T> > m_timer;
    WillBePersistentHeapVector<RawPtrWillBeMember<T> > m_dispatchSoonList;
    WillBePersistentHeapVector<RawPtrWillBeMember<T> > m_dispatchingList;
};

template<typename T> EventSender<T>::EventSender(const AtomicString& eventType)
    : m_eventType(eventType)
    , m_timer(this, &EventSender::timerFired)
{
}

template<typename T> void EventSender<T>::dispatchEventSoon(T* sender)
{
    m_dispatchSoonList.append(sender);
    if (!m_timer.isActive())
        m_timer.startOneShot(0, FROM_HERE);
}

template<typename T> void EventSender<T>::cancelEvent(T* sender)
{
    // Remove instances of this sender from both lists.
    // Use loops because we allow multiple instances to get into the lists.
    size_t size = m_dispatchSoonList.size();
    for (size_t i = 0; i < size; ++i) {
        if (m_dispatchSoonList[i] == sender)
            m_dispatchSoonList[i] = nullptr;
    }
    size = m_dispatchingList.size();
    for (size_t i = 0; i < size; ++i) {
        if (m_dispatchingList[i] == sender)
            m_dispatchingList[i] = nullptr;
    }
}

template<typename T> void EventSender<T>::dispatchPendingEvents()
{
    // Need to avoid re-entering this function; if new dispatches are
    // scheduled before the parent finishes processing the list, they
    // will set a timer and eventually be processed.
    if (!m_dispatchingList.isEmpty())
        return;

    m_timer.stop();

    m_dispatchingList.swap(m_dispatchSoonList);
    size_t size = m_dispatchingList.size();
    for (size_t i = 0; i < size; ++i) {
        if (T* sender = m_dispatchingList[i]) {
            m_dispatchingList[i] = nullptr;
            sender->dispatchPendingEvent(this);
        }
    }
    m_dispatchingList.clear();
}

} // namespace blink

#endif // EventSender_h
