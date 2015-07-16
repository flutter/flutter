/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_PLATFORM_ASYNCMETHODRUNNER_H_
#define SKY_ENGINE_PLATFORM_ASYNCMETHODRUNNER_H_

#include "sky/engine/platform/Timer.h"
#include "sky/engine/wtf/FastAllocBase.h"
#include "sky/engine/wtf/Noncopyable.h"

namespace blink {

template <typename TargetClass>
class AsyncMethodRunner final {
    WTF_MAKE_NONCOPYABLE(AsyncMethodRunner);
    WTF_MAKE_FAST_ALLOCATED;
public:
    typedef void (TargetClass::*TargetMethod)();

    AsyncMethodRunner(TargetClass* object, TargetMethod method)
        : m_timer(this, &AsyncMethodRunner<TargetClass>::fired)
        , m_object(object)
        , m_method(method)
        , m_suspended(false)
        , m_runWhenResumed(false)
    {
    }

    // Schedules to run the method asynchronously. Do nothing if it's already
    // scheduled. If it's suspended, remember to schedule to run the method when
    // resume() is called.
    void runAsync()
    {
        if (m_suspended) {
            ASSERT(!m_timer.isActive());
            m_runWhenResumed = true;
            return;
        }

        // FIXME: runAsync should take a tracked_objects::Location and pass it to timer here.
        if (!m_timer.isActive())
            m_timer.startOneShot(0, FROM_HERE);
    }

    // If it's scheduled to run the method, cancel it and remember to schedule
    // it again when resume() is called. Mainly for implementing
    // ActiveDOMObject::suspend().
    void suspend()
    {
        if (m_suspended)
            return;
        m_suspended = true;

        if (!m_timer.isActive())
            return;

        m_timer.stop();
        m_runWhenResumed = true;
    }

    // Resumes pending method run.
    void resume()
    {
        if (!m_suspended)
            return;
        m_suspended = false;

        if (!m_runWhenResumed)
            return;

        m_runWhenResumed = false;
        // FIXME: resume should take a tracked_objects::Location and pass it to timer here.
        m_timer.startOneShot(0, FROM_HERE);
    }

    void stop()
    {
        if (m_suspended) {
            ASSERT(!m_timer.isActive());
            m_runWhenResumed = false;
            m_suspended = false;
            return;
        }

        ASSERT(!m_runWhenResumed);
        if (m_timer.isActive())
            m_timer.stop();
    }

    bool isActive() const
    {
        return m_timer.isActive();
    }

private:
    void fired(Timer<AsyncMethodRunner<TargetClass> >*) { (m_object->*m_method)(); }

    Timer<AsyncMethodRunner<TargetClass> > m_timer;

    TargetClass* m_object;
    TargetMethod m_method;

    bool m_suspended;
    bool m_runWhenResumed;
};

}

#endif  // SKY_ENGINE_PLATFORM_ASYNCMETHODRUNNER_H_
