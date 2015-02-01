// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/platform/SharedTimer.h"

#include "base/time/time.h"
#include "base/timer/timer.h"
#include "sky/engine/wtf/CurrentTime.h"

namespace blink {
namespace {

class SharedTimerImpl {
    WTF_MAKE_NONCOPYABLE(SharedTimerImpl);
public:
    SharedTimerImpl()
        : m_sharedTimerFunction(nullptr)
        , m_sharedTimerFireTime(0)
    {
    }

    static SharedTimerImpl& instance()
    {
        DEFINE_STATIC_LOCAL(SharedTimerImpl, instance, ());
        return instance;
    }

    void setSharedTimerFiredFunction(void (*function)())
    {
        m_sharedTimerFunction = function;
    }

    void setSharedTimerFireInterval(double intervalSeconds)
    {
        double now = monotonicallyIncreasingTime();
        m_sharedTimerFireTime = intervalSeconds + now;

        // By converting between double and int64 representation, we run the risk
        // of losing precision due to rounding errors. Performing computations in
        // microseconds reduces this risk somewhat. But there still is the potential
        // of us computing a fire time for the timer that is shorter than what we
        // need.
        // As the event loop will check event deadlines prior to actually firing
        // them, there is a risk of needlessly rescheduling events and of
        // needlessly looping if sleep times are too short even by small amounts.
        // This results in measurable performance degradation unless we use ceil() to
        // always round up the sleep times.
        int64 interval = static_cast<int64>(ceil(intervalSeconds * base::Time::kMillisecondsPerSecond)
            * base::Time::kMicrosecondsPerMillisecond);

        if (interval < 0)
            interval = 0;

        m_sharedTimer.Stop();
        m_sharedTimer.Start(FROM_HERE,
            base::TimeDelta::FromMicroseconds(interval), this, &SharedTimerImpl::timerFired);
    }

    void stopSharedTimer()
    {
          m_sharedTimer.Stop();
    }

private:
    void timerFired()
    {
        if (m_sharedTimerFunction)
            m_sharedTimerFunction();
    }

    base::OneShotTimer<SharedTimerImpl> m_sharedTimer;
    void (*m_sharedTimerFunction)();
    double m_sharedTimerFireTime;
};

}

void setSharedTimerFiredFunction(void (*f)())
{
    SharedTimerImpl::instance().setSharedTimerFiredFunction(f);
}

void setSharedTimerFireInterval(double interval)
{
    SharedTimerImpl::instance().setSharedTimerFireInterval(interval);
}

void stopSharedTimer()
{
    SharedTimerImpl::instance().stopSharedTimer();
}

} // namespace blink
