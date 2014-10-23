/*
 * Copyright (C) 2010 Google Inc. All Rights Reserved.
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
 *
 */

#ifndef DOMWindowEventQueue_h
#define DOMWindowEventQueue_h

#include "core/events/EventQueue.h"
#include "wtf/HashSet.h"
#include "wtf/ListHashSet.h"
#include "wtf/OwnPtr.h"
#include "wtf/RefCounted.h"

namespace blink {

class Event;
class DOMWindowEventQueueTimer;
class Node;
class ExecutionContext;

#if ENABLE(OILPAN)
#define DOMWINDOWEVENTQUEUE_BASE_CLASSES public EventQueue
#else
#define DOMWINDOWEVENTQUEUE_BASE_CLASSES public RefCounted<DOMWindowEventQueue>, public EventQueue
#endif

class DOMWindowEventQueue FINAL : DOMWINDOWEVENTQUEUE_BASE_CLASSES {
public:
    static PassRefPtrWillBeRawPtr<DOMWindowEventQueue> create(ExecutionContext*);
    virtual ~DOMWindowEventQueue();

    // EventQueue
    virtual void trace(Visitor*) OVERRIDE;
    virtual bool enqueueEvent(PassRefPtrWillBeRawPtr<Event>) OVERRIDE;
    virtual bool cancelEvent(Event*) OVERRIDE;
    virtual void close() OVERRIDE;

private:
    explicit DOMWindowEventQueue(ExecutionContext*);

    void pendingEventTimerFired();
    void dispatchEvent(PassRefPtrWillBeRawPtr<Event>);

    OwnPtrWillBeMember<DOMWindowEventQueueTimer> m_pendingEventTimer;
    WillBeHeapListHashSet<RefPtrWillBeMember<Event>, 16> m_queuedEvents;
    bool m_isClosed;

    friend class DOMWindowEventQueueTimer;
};

}

#endif // DOMWindowEventQueue_h
