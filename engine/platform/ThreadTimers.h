/*
 * Copyright (C) 2006 Apple Computer, Inc.  All rights reserved.
 * Copyright (C) 2009 Google Inc.  All rights reserved.
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

#ifndef ThreadTimers_h
#define ThreadTimers_h

#include "platform/PlatformExport.h"
#include "wtf/Noncopyable.h"
#include "wtf/HashSet.h"
#include "wtf/Vector.h"

namespace blink {

class SharedTimer;
class TimerBase;

// A collection of timers per thread. Kept in PlatformThreadData.
class PLATFORM_EXPORT ThreadTimers {
    WTF_MAKE_NONCOPYABLE(ThreadTimers); WTF_MAKE_FAST_ALLOCATED;
public:
    ThreadTimers();

    // On a thread different then main, we should set the thread's instance of the SharedTimer.
    void setSharedTimer(SharedTimer*);

    Vector<TimerBase*>& timerHeap() { return m_timerHeap; }

    void updateSharedTimer();
    void fireTimersInNestedEventLoop();

private:
    static void sharedTimerFired();

    void sharedTimerFiredInternal();
    void fireTimersInNestedEventLoopInternal();

    Vector<TimerBase*> m_timerHeap;
    SharedTimer* m_sharedTimer; // External object, can be a run loop on a worker thread. Normally set/reset by worker thread.
    bool m_firingTimers; // Reentrancy guard.
    double m_pendingSharedTimerFireTime;
};

}

#endif
