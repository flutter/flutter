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

#ifndef Timing_h
#define Timing_h

#include "platform/animation/TimingFunction.h"
#include "wtf/MathExtras.h"
#include "wtf/RefPtr.h"

namespace blink {

struct Timing {
    enum FillMode {
        FillModeAuto,
        FillModeNone,
        FillModeForwards,
        FillModeBackwards,
        FillModeBoth
    };

    enum PlaybackDirection {
        PlaybackDirectionNormal,
        PlaybackDirectionReverse,
        PlaybackDirectionAlternate,
        PlaybackDirectionAlternateReverse
    };

    static const Timing& defaults()
    {
        DEFINE_STATIC_LOCAL(Timing, timing, ());
        return timing;
    }

    Timing()
        : startDelay(0)
        , endDelay(0)
        , fillMode(FillModeAuto)
        , iterationStart(0)
        , iterationCount(1)
        , iterationDuration(std::numeric_limits<double>::quiet_NaN())
        , playbackRate(1)
        , direction(PlaybackDirectionNormal)
        , timingFunction(LinearTimingFunction::shared())
    {
    }

    void assertValid() const
    {
        ASSERT(std::isfinite(startDelay));
        ASSERT(std::isfinite(endDelay));
        ASSERT(std::isfinite(iterationStart));
        ASSERT(iterationStart >= 0);
        ASSERT(iterationCount >= 0);
        ASSERT(std::isnan(iterationDuration) || iterationDuration >= 0);
        ASSERT(std::isfinite(playbackRate));
        ASSERT(timingFunction);
    }

    double startDelay;
    double endDelay;
    FillMode fillMode;
    double iterationStart;
    double iterationCount;
    double iterationDuration;
    double playbackRate;
    PlaybackDirection direction;
    RefPtr<TimingFunction> timingFunction;
};

} // namespace blink

#endif
