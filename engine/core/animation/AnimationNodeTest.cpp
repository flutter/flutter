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
#include "core/animation/AnimationNode.h"

#include <gtest/gtest.h>

using namespace blink;

namespace {

class TestAnimationNodeEventDelegate : public AnimationNode::EventDelegate {
public:
    virtual void onEventCondition(const AnimationNode* animationNode) OVERRIDE
    {
        m_eventTriggered = true;

    }
    void reset()
    {
        m_eventTriggered = false;
    }
    bool eventTriggered() { return m_eventTriggered; }

private:
    bool m_eventTriggered;
};

class TestAnimationNode : public AnimationNode {
public:
    static PassRefPtrWillBeRawPtr<TestAnimationNode> create(const Timing& specified)
    {
        return adoptRefWillBeNoop(new TestAnimationNode(specified, new TestAnimationNodeEventDelegate()));
    }

    void updateInheritedTime(double time)
    {
        updateInheritedTime(time, TimingUpdateForAnimationFrame);
    }

    void updateInheritedTime(double time, TimingUpdateReason reason)
    {
        m_eventDelegate->reset();
        AnimationNode::updateInheritedTime(time, reason);
    }

    virtual void updateChildrenAndEffects() const OVERRIDE { }
    void willDetach() { }
    TestAnimationNodeEventDelegate* eventDelegate() { return m_eventDelegate.get(); }
    virtual double calculateTimeToEffectChange(bool forwards, double localTime, double timeToNextIteration) const OVERRIDE
    {
        m_localTime = localTime;
        m_timeToNextIteration = timeToNextIteration;
        return -1;
    }
    double takeLocalTime()
    {
        const double result = m_localTime;
        m_localTime = nullValue();
        return result;
    }

    double takeTimeToNextIteration()
    {
        const double result = m_timeToNextIteration;
        m_timeToNextIteration = nullValue();
        return result;
    }

    virtual void trace(Visitor* visitor) OVERRIDE
    {
        visitor->trace(m_eventDelegate);
        AnimationNode::trace(visitor);
    }

private:
    TestAnimationNode(const Timing& specified, TestAnimationNodeEventDelegate* eventDelegate)
        : AnimationNode(specified, adoptPtrWillBeNoop(eventDelegate))
        , m_eventDelegate(eventDelegate)
    {
    }

    RawPtrWillBeMember<TestAnimationNodeEventDelegate> m_eventDelegate;
    mutable double m_localTime;
    mutable double m_timeToNextIteration;
};

TEST(AnimationAnimationNodeTest, Sanity)
{
    Timing timing;
    timing.iterationDuration = 2;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    EXPECT_EQ(0, animationNode->startTime());

    animationNode->updateInheritedTime(0);

    EXPECT_EQ(AnimationNode::PhaseActive, animationNode->phase());
    EXPECT_TRUE(animationNode->isInPlay());
    EXPECT_TRUE(animationNode->isCurrent());
    EXPECT_TRUE(animationNode->isInEffect());
    EXPECT_EQ(0, animationNode->currentIteration());
    EXPECT_EQ(0, animationNode->startTime());
    EXPECT_EQ(2, animationNode->activeDurationInternal());
    EXPECT_EQ(0, animationNode->timeFraction());

    animationNode->updateInheritedTime(1);

    EXPECT_EQ(AnimationNode::PhaseActive, animationNode->phase());
    EXPECT_TRUE(animationNode->isInPlay());
    EXPECT_TRUE(animationNode->isCurrent());
    EXPECT_TRUE(animationNode->isInEffect());
    EXPECT_EQ(0, animationNode->currentIteration());
    EXPECT_EQ(0, animationNode->startTime());
    EXPECT_EQ(2, animationNode->activeDurationInternal());
    EXPECT_EQ(0.5, animationNode->timeFraction());

    animationNode->updateInheritedTime(2);

    EXPECT_EQ(AnimationNode::PhaseAfter, animationNode->phase());
    EXPECT_FALSE(animationNode->isInPlay());
    EXPECT_FALSE(animationNode->isCurrent());
    EXPECT_TRUE(animationNode->isInEffect());
    EXPECT_EQ(0, animationNode->currentIteration());
    EXPECT_EQ(0, animationNode->startTime());
    EXPECT_EQ(2, animationNode->activeDurationInternal());
    EXPECT_EQ(1, animationNode->timeFraction());

    animationNode->updateInheritedTime(3);

    EXPECT_EQ(AnimationNode::PhaseAfter, animationNode->phase());
    EXPECT_FALSE(animationNode->isInPlay());
    EXPECT_FALSE(animationNode->isCurrent());
    EXPECT_TRUE(animationNode->isInEffect());
    EXPECT_EQ(0, animationNode->currentIteration());
    EXPECT_EQ(0, animationNode->startTime());
    EXPECT_EQ(2, animationNode->activeDurationInternal());
    EXPECT_EQ(1, animationNode->timeFraction());
}

TEST(AnimationAnimationNodeTest, FillAuto)
{
    Timing timing;
    timing.iterationDuration = 1;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    animationNode->updateInheritedTime(-1);
    EXPECT_EQ(0, animationNode->timeFraction());

    animationNode->updateInheritedTime(2);
    EXPECT_EQ(1, animationNode->timeFraction());
}

TEST(AnimationAnimationNodeTest, FillForwards)
{
    Timing timing;
    timing.iterationDuration = 1;
    timing.fillMode = Timing::FillModeForwards;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    animationNode->updateInheritedTime(-1);
    EXPECT_TRUE(isNull(animationNode->timeFraction()));

    animationNode->updateInheritedTime(2);
    EXPECT_EQ(1, animationNode->timeFraction());
}

TEST(AnimationAnimationNodeTest, FillBackwards)
{
    Timing timing;
    timing.iterationDuration = 1;
    timing.fillMode = Timing::FillModeBackwards;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    animationNode->updateInheritedTime(-1);
    EXPECT_EQ(0, animationNode->timeFraction());

    animationNode->updateInheritedTime(2);
    EXPECT_TRUE(isNull(animationNode->timeFraction()));
}

TEST(AnimationAnimationNodeTest, FillBoth)
{
    Timing timing;
    timing.iterationDuration = 1;
    timing.fillMode = Timing::FillModeBoth;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    animationNode->updateInheritedTime(-1);
    EXPECT_EQ(0, animationNode->timeFraction());

    animationNode->updateInheritedTime(2);
    EXPECT_EQ(1, animationNode->timeFraction());
}

TEST(AnimationAnimationNodeTest, StartDelay)
{
    Timing timing;
    timing.iterationDuration = 1;
    timing.fillMode = Timing::FillModeForwards;
    timing.startDelay = 0.5;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    animationNode->updateInheritedTime(0);
    EXPECT_TRUE(isNull(animationNode->timeFraction()));

    animationNode->updateInheritedTime(0.5);
    EXPECT_EQ(0, animationNode->timeFraction());

    animationNode->updateInheritedTime(1.5);
    EXPECT_EQ(1, animationNode->timeFraction());
}

TEST(AnimationAnimationNodeTest, ZeroIteration)
{
    Timing timing;
    timing.iterationDuration = 1;
    timing.fillMode = Timing::FillModeForwards;
    timing.iterationCount = 0;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    animationNode->updateInheritedTime(-1);
    EXPECT_EQ(0, animationNode->activeDurationInternal());
    EXPECT_TRUE(isNull(animationNode->currentIteration()));
    EXPECT_TRUE(isNull(animationNode->timeFraction()));

    animationNode->updateInheritedTime(0);
    EXPECT_EQ(0, animationNode->activeDurationInternal());
    EXPECT_EQ(0, animationNode->currentIteration());
    EXPECT_EQ(0, animationNode->timeFraction());
}

TEST(AnimationAnimationNodeTest, InfiniteIteration)
{
    Timing timing;
    timing.iterationDuration = 1;
    timing.fillMode = Timing::FillModeForwards;
    timing.iterationCount = std::numeric_limits<double>::infinity();
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    animationNode->updateInheritedTime(-1);
    EXPECT_TRUE(isNull(animationNode->currentIteration()));
    EXPECT_TRUE(isNull(animationNode->timeFraction()));

    EXPECT_EQ(std::numeric_limits<double>::infinity(), animationNode->activeDurationInternal());

    animationNode->updateInheritedTime(0);
    EXPECT_EQ(0, animationNode->currentIteration());
    EXPECT_EQ(0, animationNode->timeFraction());
}

TEST(AnimationAnimationNodeTest, Iteration)
{
    Timing timing;
    timing.iterationCount = 2;
    timing.iterationDuration = 2;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    animationNode->updateInheritedTime(0);
    EXPECT_EQ(0, animationNode->currentIteration());
    EXPECT_EQ(0, animationNode->timeFraction());

    animationNode->updateInheritedTime(1);
    EXPECT_EQ(0, animationNode->currentIteration());
    EXPECT_EQ(0.5, animationNode->timeFraction());

    animationNode->updateInheritedTime(2);
    EXPECT_EQ(1, animationNode->currentIteration());
    EXPECT_EQ(0, animationNode->timeFraction());

    animationNode->updateInheritedTime(2);
    EXPECT_EQ(1, animationNode->currentIteration());
    EXPECT_EQ(0, animationNode->timeFraction());

    animationNode->updateInheritedTime(5);
    EXPECT_EQ(1, animationNode->currentIteration());
    EXPECT_EQ(1, animationNode->timeFraction());
}

TEST(AnimationAnimationNodeTest, IterationStart)
{
    Timing timing;
    timing.iterationStart = 1.2;
    timing.iterationCount = 2.2;
    timing.iterationDuration = 1;
    timing.fillMode = Timing::FillModeBoth;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    animationNode->updateInheritedTime(-1);
    EXPECT_EQ(1, animationNode->currentIteration());
    EXPECT_NEAR(0.2, animationNode->timeFraction(), 0.000000000000001);

    animationNode->updateInheritedTime(0);
    EXPECT_EQ(1, animationNode->currentIteration());
    EXPECT_NEAR(0.2, animationNode->timeFraction(), 0.000000000000001);

    animationNode->updateInheritedTime(10);
    EXPECT_EQ(3, animationNode->currentIteration());
    EXPECT_NEAR(0.4, animationNode->timeFraction(), 0.000000000000001);
}

TEST(AnimationAnimationNodeTest, IterationAlternate)
{
    Timing timing;
    timing.iterationCount = 10;
    timing.iterationDuration = 1;
    timing.direction = Timing::PlaybackDirectionAlternate;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    animationNode->updateInheritedTime(0.75);
    EXPECT_EQ(0, animationNode->currentIteration());
    EXPECT_EQ(0.75, animationNode->timeFraction());

    animationNode->updateInheritedTime(1.75);
    EXPECT_EQ(1, animationNode->currentIteration());
    EXPECT_EQ(0.25, animationNode->timeFraction());

    animationNode->updateInheritedTime(2.75);
    EXPECT_EQ(2, animationNode->currentIteration());
    EXPECT_EQ(0.75, animationNode->timeFraction());
}

TEST(AnimationAnimationNodeTest, IterationAlternateReverse)
{
    Timing timing;
    timing.iterationCount = 10;
    timing.iterationDuration = 1;
    timing.direction = Timing::PlaybackDirectionAlternateReverse;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    animationNode->updateInheritedTime(0.75);
    EXPECT_EQ(0, animationNode->currentIteration());
    EXPECT_EQ(0.25, animationNode->timeFraction());

    animationNode->updateInheritedTime(1.75);
    EXPECT_EQ(1, animationNode->currentIteration());
    EXPECT_EQ(0.75, animationNode->timeFraction());

    animationNode->updateInheritedTime(2.75);
    EXPECT_EQ(2, animationNode->currentIteration());
    EXPECT_EQ(0.25, animationNode->timeFraction());
}

TEST(AnimationAnimationNodeTest, ZeroDurationSanity)
{
    Timing timing;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    EXPECT_EQ(0, animationNode->startTime());

    animationNode->updateInheritedTime(0);

    EXPECT_EQ(AnimationNode::PhaseAfter, animationNode->phase());
    EXPECT_FALSE(animationNode->isInPlay());
    EXPECT_FALSE(animationNode->isCurrent());
    EXPECT_TRUE(animationNode->isInEffect());
    EXPECT_EQ(0, animationNode->currentIteration());
    EXPECT_EQ(0, animationNode->startTime());
    EXPECT_EQ(0, animationNode->activeDurationInternal());
    EXPECT_EQ(1, animationNode->timeFraction());

    animationNode->updateInheritedTime(1);

    EXPECT_EQ(AnimationNode::PhaseAfter, animationNode->phase());
    EXPECT_FALSE(animationNode->isInPlay());
    EXPECT_FALSE(animationNode->isCurrent());
    EXPECT_TRUE(animationNode->isInEffect());
    EXPECT_EQ(0, animationNode->currentIteration());
    EXPECT_EQ(0, animationNode->startTime());
    EXPECT_EQ(0, animationNode->activeDurationInternal());
    EXPECT_EQ(1, animationNode->timeFraction());
}

TEST(AnimationAnimationNodeTest, ZeroDurationFillForwards)
{
    Timing timing;
    timing.fillMode = Timing::FillModeForwards;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    animationNode->updateInheritedTime(-1);
    EXPECT_TRUE(isNull(animationNode->timeFraction()));

    animationNode->updateInheritedTime(0);
    EXPECT_EQ(1, animationNode->timeFraction());

    animationNode->updateInheritedTime(1);
    EXPECT_EQ(1, animationNode->timeFraction());
}

TEST(AnimationAnimationNodeTest, ZeroDurationFillBackwards)
{
    Timing timing;
    timing.fillMode = Timing::FillModeBackwards;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    animationNode->updateInheritedTime(-1);
    EXPECT_EQ(0, animationNode->timeFraction());

    animationNode->updateInheritedTime(0);
    EXPECT_TRUE(isNull(animationNode->timeFraction()));

    animationNode->updateInheritedTime(1);
    EXPECT_TRUE(isNull(animationNode->timeFraction()));
}

TEST(AnimationAnimationNodeTest, ZeroDurationFillBoth)
{
    Timing timing;
    timing.fillMode = Timing::FillModeBoth;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    animationNode->updateInheritedTime(-1);
    EXPECT_EQ(0, animationNode->timeFraction());

    animationNode->updateInheritedTime(0);
    EXPECT_EQ(1, animationNode->timeFraction());

    animationNode->updateInheritedTime(1);
    EXPECT_EQ(1, animationNode->timeFraction());
}

TEST(AnimationAnimationNodeTest, ZeroDurationStartDelay)
{
    Timing timing;
    timing.fillMode = Timing::FillModeForwards;
    timing.startDelay = 0.5;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    animationNode->updateInheritedTime(0);
    EXPECT_TRUE(isNull(animationNode->timeFraction()));

    animationNode->updateInheritedTime(0.5);
    EXPECT_EQ(1, animationNode->timeFraction());

    animationNode->updateInheritedTime(1.5);
    EXPECT_EQ(1, animationNode->timeFraction());
}

TEST(AnimationAnimationNodeTest, ZeroDurationIterationStartAndCount)
{
    Timing timing;
    timing.iterationStart = 0.1;
    timing.iterationCount = 0.2;
    timing.fillMode = Timing::FillModeBoth;
    timing.startDelay = 0.3;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    animationNode->updateInheritedTime(0);
    EXPECT_EQ(0.1, animationNode->timeFraction());

    animationNode->updateInheritedTime(0.3);
    EXPECT_DOUBLE_EQ(0.3, animationNode->timeFraction());

    animationNode->updateInheritedTime(1);
    EXPECT_DOUBLE_EQ(0.3, animationNode->timeFraction());
}

// FIXME: Needs specification work.
TEST(AnimationAnimationNodeTest, ZeroDurationInfiniteIteration)
{
    Timing timing;
    timing.fillMode = Timing::FillModeForwards;
    timing.iterationCount = std::numeric_limits<double>::infinity();
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    animationNode->updateInheritedTime(-1);
    EXPECT_EQ(0, animationNode->activeDurationInternal());
    EXPECT_TRUE(isNull(animationNode->currentIteration()));
    EXPECT_TRUE(isNull(animationNode->timeFraction()));

    animationNode->updateInheritedTime(0);
    EXPECT_EQ(0, animationNode->activeDurationInternal());
    EXPECT_EQ(std::numeric_limits<double>::infinity(), animationNode->currentIteration());
    EXPECT_EQ(1, animationNode->timeFraction());
}

TEST(AnimationAnimationNodeTest, ZeroDurationIteration)
{
    Timing timing;
    timing.fillMode = Timing::FillModeForwards;
    timing.iterationCount = 2;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    animationNode->updateInheritedTime(-1);
    EXPECT_TRUE(isNull(animationNode->currentIteration()));
    EXPECT_TRUE(isNull(animationNode->timeFraction()));

    animationNode->updateInheritedTime(0);
    EXPECT_EQ(1, animationNode->currentIteration());
    EXPECT_EQ(1, animationNode->timeFraction());

    animationNode->updateInheritedTime(1);
    EXPECT_EQ(1, animationNode->currentIteration());
    EXPECT_EQ(1, animationNode->timeFraction());
}

TEST(AnimationAnimationNodeTest, ZeroDurationIterationStart)
{
    Timing timing;
    timing.iterationStart = 1.2;
    timing.iterationCount = 2.2;
    timing.fillMode = Timing::FillModeBoth;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    animationNode->updateInheritedTime(-1);
    EXPECT_EQ(1, animationNode->currentIteration());
    EXPECT_NEAR(0.2, animationNode->timeFraction(), 0.000000000000001);

    animationNode->updateInheritedTime(0);
    EXPECT_EQ(3, animationNode->currentIteration());
    EXPECT_NEAR(0.4, animationNode->timeFraction(), 0.000000000000001);

    animationNode->updateInheritedTime(10);
    EXPECT_EQ(3, animationNode->currentIteration());
    EXPECT_NEAR(0.4, animationNode->timeFraction(), 0.000000000000001);
}

TEST(AnimationAnimationNodeTest, ZeroDurationIterationAlternate)
{
    Timing timing;
    timing.fillMode = Timing::FillModeForwards;
    timing.iterationCount = 2;
    timing.direction = Timing::PlaybackDirectionAlternate;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    animationNode->updateInheritedTime(-1);
    EXPECT_TRUE(isNull(animationNode->currentIteration()));
    EXPECT_TRUE(isNull(animationNode->timeFraction()));

    animationNode->updateInheritedTime(0);
    EXPECT_EQ(1, animationNode->currentIteration());
    EXPECT_EQ(0, animationNode->timeFraction());

    animationNode->updateInheritedTime(1);
    EXPECT_EQ(1, animationNode->currentIteration());
    EXPECT_EQ(0, animationNode->timeFraction());
}

TEST(AnimationAnimationNodeTest, ZeroDurationIterationAlternateReverse)
{
    Timing timing;
    timing.fillMode = Timing::FillModeForwards;
    timing.iterationCount = 2;
    timing.direction = Timing::PlaybackDirectionAlternateReverse;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    animationNode->updateInheritedTime(-1);
    EXPECT_TRUE(isNull(animationNode->currentIteration()));
    EXPECT_TRUE(isNull(animationNode->timeFraction()));

    animationNode->updateInheritedTime(0);
    EXPECT_EQ(1, animationNode->currentIteration());
    EXPECT_EQ(1, animationNode->timeFraction());

    animationNode->updateInheritedTime(1);
    EXPECT_EQ(1, animationNode->currentIteration());
    EXPECT_EQ(1, animationNode->timeFraction());
}

TEST(AnimationAnimationNodeTest, InfiniteDurationSanity)
{
    Timing timing;
    timing.iterationDuration = std::numeric_limits<double>::infinity();
    timing.iterationCount = 1;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    EXPECT_EQ(0, animationNode->startTime());

    animationNode->updateInheritedTime(0);

    EXPECT_EQ(std::numeric_limits<double>::infinity(), animationNode->activeDurationInternal());
    EXPECT_EQ(AnimationNode::PhaseActive, animationNode->phase());
    EXPECT_TRUE(animationNode->isInPlay());
    EXPECT_TRUE(animationNode->isCurrent());
    EXPECT_TRUE(animationNode->isInEffect());
    EXPECT_EQ(0, animationNode->currentIteration());
    EXPECT_EQ(0, animationNode->timeFraction());

    animationNode->updateInheritedTime(1);

    EXPECT_EQ(std::numeric_limits<double>::infinity(), animationNode->activeDurationInternal());
    EXPECT_EQ(AnimationNode::PhaseActive, animationNode->phase());
    EXPECT_TRUE(animationNode->isInPlay());
    EXPECT_TRUE(animationNode->isCurrent());
    EXPECT_TRUE(animationNode->isInEffect());
    EXPECT_EQ(0, animationNode->currentIteration());
    EXPECT_EQ(0, animationNode->timeFraction());
}

// FIXME: Needs specification work.
TEST(AnimationAnimationNodeTest, InfiniteDurationZeroIterations)
{
    Timing timing;
    timing.iterationDuration = std::numeric_limits<double>::infinity();
    timing.iterationCount = 0;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    EXPECT_EQ(0, animationNode->startTime());

    animationNode->updateInheritedTime(0);

    EXPECT_EQ(0, animationNode->activeDurationInternal());
    EXPECT_EQ(AnimationNode::PhaseAfter, animationNode->phase());
    EXPECT_FALSE(animationNode->isInPlay());
    EXPECT_FALSE(animationNode->isCurrent());
    EXPECT_TRUE(animationNode->isInEffect());
    EXPECT_EQ(0, animationNode->currentIteration());
    EXPECT_EQ(0, animationNode->timeFraction());

    animationNode->updateInheritedTime(1);

    EXPECT_EQ(AnimationNode::PhaseAfter, animationNode->phase());
    EXPECT_EQ(AnimationNode::PhaseAfter, animationNode->phase());
    EXPECT_FALSE(animationNode->isInPlay());
    EXPECT_FALSE(animationNode->isCurrent());
    EXPECT_TRUE(animationNode->isInEffect());
    EXPECT_EQ(0, animationNode->currentIteration());
    EXPECT_EQ(0, animationNode->timeFraction());
}

TEST(AnimationAnimationNodeTest, InfiniteDurationInfiniteIterations)
{
    Timing timing;
    timing.iterationDuration = std::numeric_limits<double>::infinity();
    timing.iterationCount = std::numeric_limits<double>::infinity();
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    EXPECT_EQ(0, animationNode->startTime());

    animationNode->updateInheritedTime(0);

    EXPECT_EQ(std::numeric_limits<double>::infinity(), animationNode->activeDurationInternal());
    EXPECT_EQ(AnimationNode::PhaseActive, animationNode->phase());
    EXPECT_TRUE(animationNode->isInPlay());
    EXPECT_TRUE(animationNode->isCurrent());
    EXPECT_TRUE(animationNode->isInEffect());
    EXPECT_EQ(0, animationNode->currentIteration());
    EXPECT_EQ(0, animationNode->timeFraction());

    animationNode->updateInheritedTime(1);

    EXPECT_EQ(std::numeric_limits<double>::infinity(), animationNode->activeDurationInternal());
    EXPECT_EQ(AnimationNode::PhaseActive, animationNode->phase());
    EXPECT_TRUE(animationNode->isInPlay());
    EXPECT_TRUE(animationNode->isCurrent());
    EXPECT_TRUE(animationNode->isInEffect());
    EXPECT_EQ(0, animationNode->currentIteration());
    EXPECT_EQ(0, animationNode->timeFraction());
}

TEST(AnimationAnimationNodeTest, InfiniteDurationZeroPlaybackRate)
{
    Timing timing;
    timing.iterationDuration = std::numeric_limits<double>::infinity();
    timing.playbackRate = 0;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    EXPECT_EQ(0, animationNode->startTime());

    animationNode->updateInheritedTime(0);

    EXPECT_EQ(std::numeric_limits<double>::infinity(), animationNode->activeDurationInternal());
    EXPECT_EQ(AnimationNode::PhaseActive, animationNode->phase());
    EXPECT_TRUE(animationNode->isInPlay());
    EXPECT_TRUE(animationNode->isCurrent());
    EXPECT_TRUE(animationNode->isInEffect());
    EXPECT_EQ(0, animationNode->currentIteration());
    EXPECT_EQ(0, animationNode->timeFraction());

    animationNode->updateInheritedTime(std::numeric_limits<double>::infinity());

    EXPECT_EQ(std::numeric_limits<double>::infinity(), animationNode->activeDurationInternal());
    EXPECT_EQ(AnimationNode::PhaseAfter, animationNode->phase());
    EXPECT_FALSE(animationNode->isInPlay());
    EXPECT_FALSE(animationNode->isCurrent());
    EXPECT_TRUE(animationNode->isInEffect());
    EXPECT_EQ(0, animationNode->currentIteration());
    EXPECT_EQ(0, animationNode->timeFraction());
}

TEST(AnimationAnimationNodeTest, EndTime)
{
    Timing timing;
    timing.startDelay = 1;
    timing.endDelay = 2;
    timing.iterationDuration = 4;
    timing.iterationCount = 2;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);
    EXPECT_EQ(11, animationNode->endTimeInternal());
}

TEST(AnimationAnimationNodeTest, Events)
{
    Timing timing;
    timing.iterationDuration = 1;
    timing.fillMode = Timing::FillModeForwards;
    timing.iterationCount = 2;
    timing.startDelay = 1;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    animationNode->updateInheritedTime(0.0, TimingUpdateOnDemand);
    EXPECT_FALSE(animationNode->eventDelegate()->eventTriggered());

    animationNode->updateInheritedTime(0.0, TimingUpdateForAnimationFrame);
    EXPECT_TRUE(animationNode->eventDelegate()->eventTriggered());

    animationNode->updateInheritedTime(1.5, TimingUpdateOnDemand);
    EXPECT_FALSE(animationNode->eventDelegate()->eventTriggered());

    animationNode->updateInheritedTime(1.5, TimingUpdateForAnimationFrame);
    EXPECT_TRUE(animationNode->eventDelegate()->eventTriggered());

}

TEST(AnimationAnimationNodeTest, TimeToEffectChange)
{
    Timing timing;
    timing.iterationDuration = 1;
    timing.fillMode = Timing::FillModeForwards;
    timing.iterationStart = 0.2;
    timing.iterationCount = 2.5;
    timing.startDelay = 1;
    timing.direction = Timing::PlaybackDirectionAlternate;
    RefPtrWillBeRawPtr<TestAnimationNode> animationNode = TestAnimationNode::create(timing);

    animationNode->updateInheritedTime(0);
    EXPECT_EQ(0, animationNode->takeLocalTime());
    EXPECT_TRUE(std::isinf(animationNode->takeTimeToNextIteration()));

    // Normal iteration.
    animationNode->updateInheritedTime(1.75);
    EXPECT_EQ(1.75, animationNode->takeLocalTime());
    EXPECT_NEAR(0.05, animationNode->takeTimeToNextIteration(), 0.000000000000001);

    // Reverse iteration.
    animationNode->updateInheritedTime(2.75);
    EXPECT_EQ(2.75, animationNode->takeLocalTime());
    EXPECT_NEAR(0.05, animationNode->takeTimeToNextIteration(), 0.000000000000001);

    // Item ends before iteration finishes.
    animationNode->updateInheritedTime(3.4);
    EXPECT_EQ(AnimationNode::PhaseActive, animationNode->phase());
    EXPECT_EQ(3.4, animationNode->takeLocalTime());
    EXPECT_TRUE(std::isinf(animationNode->takeTimeToNextIteration()));

    // Item has finished.
    animationNode->updateInheritedTime(3.5);
    EXPECT_EQ(AnimationNode::PhaseAfter, animationNode->phase());
    EXPECT_EQ(3.5, animationNode->takeLocalTime());
    EXPECT_TRUE(std::isinf(animationNode->takeTimeToNextIteration()));
}

}
