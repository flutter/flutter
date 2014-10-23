/*
 * Copyright (c) 2013, Google Inc. All rights reserved.
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

#include "core/animation/CompositorAnimations.h"

#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

// FIXME: Remove once https://codereview.chromium.org/50603011/ lands.
#define EXPECT_REFV_EQ(a, b) EXPECT_EQ(*(a.get()), *(b.get()))
#define EXPECT_REFV_NE(a, b) EXPECT_NE(*(a.get()), *(b.get()))

namespace {

using namespace blink;

class AnimationCompositorAnimationsTimingFunctionReverserTest : public ::testing::Test {
protected:

public:
    PassRefPtr<TimingFunction> reverse(const RefPtr<TimingFunction>& timefunc)
    {
        return CompositorAnimationsTimingFunctionReverser::reverse(*timefunc);
    }
};

TEST_F(AnimationCompositorAnimationsTimingFunctionReverserTest, LinearReverse)
{
    RefPtr<TimingFunction> linearTiming = LinearTimingFunction::shared();
    EXPECT_REFV_EQ(linearTiming, reverse(linearTiming));
}

TEST_F(AnimationCompositorAnimationsTimingFunctionReverserTest, CubicReverse)
{
    RefPtr<TimingFunction> cubicEaseInTiming = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseIn);
    RefPtr<TimingFunction> cubicEaseOutTiming = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseOut);
    RefPtr<TimingFunction> cubicEaseInOutTiming = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseInOut);

    EXPECT_REFV_EQ(cubicEaseOutTiming, reverse(cubicEaseInTiming));
    EXPECT_REFV_EQ(cubicEaseInTiming, reverse(cubicEaseOutTiming));
    EXPECT_REFV_EQ(cubicEaseInOutTiming, reverse(cubicEaseInOutTiming));

    RefPtr<TimingFunction> cubicCustomTiming = CubicBezierTimingFunction::create(0.17, 0.67, 1, -1.73);
    // Due to floating point, 1.0-(-1.73) != 2.73
    RefPtr<TimingFunction> cubicCustomTimingReversed = CubicBezierTimingFunction::create(0, 1.0 - (-1.73), 1.0 - 0.17, 1.0 - 0.67);
    EXPECT_REFV_EQ(cubicCustomTimingReversed, reverse(cubicCustomTiming));

    RefPtr<TimingFunction> cubicEaseTiming = CubicBezierTimingFunction::preset(CubicBezierTimingFunction::Ease);
    RefPtr<TimingFunction> cubicEaseTimingReversed = CubicBezierTimingFunction::create(1.0 - 0.25, 0.0, 1.0 - 0.25, 1.0 - 0.1);
    EXPECT_REFV_EQ(cubicEaseTimingReversed, reverse(cubicEaseTiming));
}

} // namespace
