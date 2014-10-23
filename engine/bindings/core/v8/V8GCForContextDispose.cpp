/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
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

#include "config.h"
#include "bindings/core/v8/V8GCForContextDispose.h"

#include "bindings/core/v8/V8PerIsolateData.h"
#include "wtf/StdLibExtras.h"
#include <v8.h>

namespace blink {

V8GCForContextDispose::V8GCForContextDispose()
    : m_pseudoIdleTimer(this, &V8GCForContextDispose::pseudoIdleTimerFired)
    , m_didDisposeContextForMainFrame(false)
{
}

void V8GCForContextDispose::notifyContextDisposed()
{
    m_didDisposeContextForMainFrame = true;
    V8PerIsolateData::mainThreadIsolate()->ContextDisposedNotification();
    if (!m_pseudoIdleTimer.isActive())
        m_pseudoIdleTimer.startOneShot(0.8, FROM_HERE);
}

void V8GCForContextDispose::notifyIdleSooner(double maximumFireInterval)
{
    if (m_pseudoIdleTimer.isActive()) {
        double nextFireInterval = m_pseudoIdleTimer.nextFireInterval();
        if (nextFireInterval > maximumFireInterval) {
            m_pseudoIdleTimer.stop();
            m_pseudoIdleTimer.startOneShot(maximumFireInterval, FROM_HERE);
        }
    }
}

V8GCForContextDispose& V8GCForContextDispose::instanceTemplate()
{
    DEFINE_STATIC_LOCAL(V8GCForContextDispose, staticInstance, ());
    return staticInstance;
}

void V8GCForContextDispose::pseudoIdleTimerFired(Timer<V8GCForContextDispose>*)
{
    const int longIdlePauseInMs = 100;
    const int shortIdlePauseInMs = 10;
    int hint = m_didDisposeContextForMainFrame ? longIdlePauseInMs : shortIdlePauseInMs;
    V8PerIsolateData::mainThreadIsolate()->IdleNotification(hint);
    m_didDisposeContextForMainFrame = false;
}

} // namespace blink
