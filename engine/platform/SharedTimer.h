/*
 * Copyright (C) 2006 Apple Computer, Inc.  All rights reserved.
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

#ifndef SharedTimer_h
#define SharedTimer_h

#include "platform/PlatformExport.h"
#include "wtf/FastAllocBase.h"
#include "wtf/Noncopyable.h"

namespace blink {

// Each thread has its own single instance of shared timer, which implements this interface.
// This instance is shared by all timers in the thread.
// Not intended to be used directly; use the Timer class instead.
class PLATFORM_EXPORT SharedTimer {
    WTF_MAKE_NONCOPYABLE(SharedTimer); WTF_MAKE_FAST_ALLOCATED;
public:
    SharedTimer() { }
    virtual ~SharedTimer() {}
    virtual void setFiredFunction(void (*)()) = 0;

    // The fire interval is in seconds relative to the current monotonic clock time.
    virtual void setFireInterval(double) = 0;
    virtual void stop() = 0;
};


PLATFORM_EXPORT void setSharedTimerFiredFunction(void (*)());
PLATFORM_EXPORT void setSharedTimerFireInterval(double);
PLATFORM_EXPORT void stopSharedTimer();

class PLATFORM_EXPORT MainThreadSharedTimer : public SharedTimer {
public:
    virtual void setFiredFunction(void (*function)()) override
    {
        setSharedTimerFiredFunction(function);
    }

    virtual void setFireInterval(double interval) override
    {
        setSharedTimerFireInterval(interval);
    }

    virtual void stop() override
    {
        stopSharedTimer();
    }
};

} // namespace blink

#endif // SharedTimer_h
