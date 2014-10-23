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
#include "core/animation/AnimationClock.h"

#include "wtf/OwnPtr.h"
#include <gtest/gtest.h>

using namespace blink;

namespace {

class AnimationAnimationClockTest : public ::testing::Test {
public:
    AnimationAnimationClockTest()
        : animationClock(mockTimeFunction)
    { }
protected:
    virtual void SetUp()
    {
        mockTime = 0;
        animationClock.resetTimeForTesting();
    }

    static double mockTimeFunction()
    {
        return mockTime;
    }

    static double mockTime;
    AnimationClock animationClock;
};

double AnimationAnimationClockTest::mockTime;

TEST_F(AnimationAnimationClockTest, TimeIsGreaterThanZeroForUnitTests)
{
    AnimationClock clock;
    // unit tests outside core/animation shouldn't need to do anything to get
    // a non-zero currentTime().
    EXPECT_GT(clock.currentTime(), 0);
}

TEST_F(AnimationAnimationClockTest, TimeDoesNotChange)
{
    animationClock.updateTime(100);
    EXPECT_EQ(100, animationClock.currentTime());
    EXPECT_EQ(100, animationClock.currentTime());
}

TEST_F(AnimationAnimationClockTest, TimeAdvancesWhenUpdated)
{
    animationClock.updateTime(100);
    EXPECT_EQ(100, animationClock.currentTime());

    animationClock.updateTime(200);
    EXPECT_EQ(200, animationClock.currentTime());
}

TEST_F(AnimationAnimationClockTest, TimeAdvancesToTaskTime)
{
    animationClock.updateTime(100);
    EXPECT_EQ(100, animationClock.currentTime());

    mockTime = 150;
    AnimationClock::notifyTaskStart();
    EXPECT_GE(animationClock.currentTime(), mockTime);
}

TEST_F(AnimationAnimationClockTest, TimeAdvancesToTaskTimeOnlyWhenRequired)
{
    animationClock.updateTime(100);
    EXPECT_EQ(100, animationClock.currentTime());

    AnimationClock::notifyTaskStart();
    animationClock.updateTime(125);
    EXPECT_EQ(125, animationClock.currentTime());
}

TEST_F(AnimationAnimationClockTest, UpdateTimeIsMonotonic)
{
    animationClock.updateTime(100);
    EXPECT_EQ(100, animationClock.currentTime());

    // Update can't go backwards.
    animationClock.updateTime(50);
    EXPECT_EQ(100, animationClock.currentTime());

    mockTime = 50;
    AnimationClock::notifyTaskStart();
    EXPECT_EQ(100, animationClock.currentTime());

    mockTime = 150;
    AnimationClock::notifyTaskStart();
    EXPECT_GE(animationClock.currentTime(), mockTime);

    // Update can't go backwards after advance to estimate.
    animationClock.updateTime(100);
    EXPECT_GE(animationClock.currentTime(), mockTime);
}

TEST_F(AnimationAnimationClockTest, CurrentTimeUpdatesTask)
{
    animationClock.updateTime(100);
    EXPECT_EQ(100, animationClock.currentTime());

    mockTime = 100;
    AnimationClock::notifyTaskStart();
    EXPECT_EQ(100, animationClock.currentTime());

    mockTime = 150;
    EXPECT_EQ(100, animationClock.currentTime());
}

}
