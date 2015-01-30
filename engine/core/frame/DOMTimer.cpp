/*
 * Copyright (C) 2008 Apple Inc. All Rights Reserved.
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

#include "sky/engine/config.h"
#include "sky/engine/core/frame/DOMTimer.h"

#include "sky/engine/core/dom/ExecutionContext.h"
#include "sky/engine/platform/Logging.h"
#include "sky/engine/platform/TraceEvent.h"
#include "sky/engine/wtf/CurrentTime.h"

namespace blink {

static const int maxTimerNestingLevel = 5;
static const double oneMillisecond = 0.001;
// Chromium uses a minimum timer interval of 4ms. We'd like to go
// lower; however, there are poorly coded websites out there which do
// create CPU-spinning loops.  Using 4ms prevents the CPU from
// spinning too busily and provides a balance between CPU spinning and
// the smallest possible interval timer.
static const double minimumInterval = 0.004;

static int timerNestingLevel = 0;

double DOMTimer::hiddenPageAlignmentInterval()
{
    // Timers on hidden pages are aligned so that they fire once per
    // second at most.
    return 1.0;
}

double DOMTimer::visiblePageAlignmentInterval()
{
    // Alignment does not apply to timers on visible pages.
    return 0;
}

int DOMTimer::install(ExecutionContext* context, PassOwnPtr<ScheduledAction> action, int timeout, bool singleShot)
{
    int timeoutID = context->installNewTimeout(action, timeout, singleShot);
    WTF_LOG(Timers, "DOMTimer::install: timeoutID = %d, timeout = %d, singleShot = %d", timeoutID, timeout, singleShot ? 1 : 0);
    return timeoutID;
}

void DOMTimer::removeByID(ExecutionContext* context, int timeoutID)
{
    WTF_LOG(Timers, "DOMTimer::removeByID: timeoutID = %d", timeoutID);
    context->removeTimeoutByID(timeoutID);
}

DOMTimer::DOMTimer(ExecutionContext* context, PassOwnPtr<ScheduledAction> action, int interval, bool singleShot, int timeoutID)
    : SuspendableTimer(context)
    , m_timeoutID(timeoutID)
    , m_nestingLevel(timerNestingLevel + 1)
    , m_action(action)
{
    ASSERT(timeoutID > 0);

    double intervalMilliseconds = std::max(oneMillisecond, interval * oneMillisecond);
    if (intervalMilliseconds < minimumInterval && m_nestingLevel >= maxTimerNestingLevel)
        intervalMilliseconds = minimumInterval;
    if (singleShot)
        startOneShot(intervalMilliseconds, FROM_HERE);
    else
        startRepeating(intervalMilliseconds, FROM_HERE);
}

DOMTimer::~DOMTimer()
{
}

int DOMTimer::timeoutID() const
{
    return m_timeoutID;
}

void DOMTimer::fired()
{
    ExecutionContext* context = executionContext();
    timerNestingLevel = m_nestingLevel;
    ASSERT(!context->activeDOMObjectsAreSuspended());

    // Simple case for non-one-shot timers.
    if (isActive()) {
        if (repeatInterval() && repeatInterval() < minimumInterval) {
            m_nestingLevel++;
            if (m_nestingLevel >= maxTimerNestingLevel)
                augmentRepeatInterval(minimumInterval - repeatInterval());
        }

        WTF_LOG(Timers, "DOMTimer::fired: m_timeoutID = %d, repeatInterval = %f, m_action = %p", m_timeoutID, repeatInterval(), m_action.get());

        // No access to member variables after this point, it can delete the timer.
        m_action->execute(context);
        return;
    }

    WTF_LOG(Timers, "DOMTimer::fired: m_timeoutID = %d, one-shot, m_action = %p", m_timeoutID, m_action.get());

    // Delete timer before executing the action for one-shot timers.
    OwnPtr<ScheduledAction> action = m_action.release();

    // This timer is being deleted; no access to member variables allowed after this point.
    context->removeTimeoutByID(m_timeoutID);

    action->execute(context);

    timerNestingLevel = 0;
}

void DOMTimer::contextDestroyed()
{
    SuspendableTimer::contextDestroyed();
}

void DOMTimer::stop()
{
    SuspendableTimer::stop();
    // Need to release JS objects potentially protected by ScheduledAction
    // because they can form circular references back to the ExecutionContext
    // which will cause a memory leak.
    m_action.clear();
}

double DOMTimer::alignedFireTime(double fireTime) const
{
    double alignmentInterval = executionContext()->timerAlignmentInterval();
    if (alignmentInterval) {
        double currentTime = monotonicallyIncreasingTime();
        if (fireTime <= currentTime)
            return fireTime;

        // When a repeating timer is scheduled for exactly the
        // background page alignment interval, because it's impossible
        // for the timer to be rescheduled instantaneously, it misses
        // every other fire time. Avoid this by looking at the next
        // fire time rounded both down and up.

        double alignedTimeRoundedDown = floor(fireTime / alignmentInterval) * alignmentInterval;
        double alignedTimeRoundedUp = ceil(fireTime / alignmentInterval) * alignmentInterval;

        // If the version rounded down is in the past, discard it
        // immediately.

        if (alignedTimeRoundedDown <= currentTime)
            return alignedTimeRoundedUp;

        // Only use the rounded-down time if it's within a certain
        // tolerance of the fire time. This avoids speeding up timers
        // on background pages in the common case.

        if (fireTime - alignedTimeRoundedDown < minimumInterval)
            return alignedTimeRoundedDown;

        return alignedTimeRoundedUp;
    }

    return fireTime;
}

} // namespace blink
