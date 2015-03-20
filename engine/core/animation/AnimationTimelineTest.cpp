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

#include "sky/engine/config.h"
#include "sky/engine/core/animation/AnimationTimeline.h"

#include "sky/engine/core/animation/Animation.h"
#include "sky/engine/core/animation/AnimationClock.h"
#include "sky/engine/core/animation/AnimationNode.h"
#include "sky/engine/core/animation/KeyframeEffectModel.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/QualifiedName.h"
#include "sky/engine/platform/weborigin/KURL.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

namespace blink {

class MockPlatformTiming : public AnimationTimeline::PlatformTiming {
public:

    MOCK_METHOD1(wakeAfter, void(double));
    MOCK_METHOD0(cancelWake, void());
    MOCK_METHOD0(serviceOnNextFrame, void());

    /**
     * AnimationTimelines should do one of the following things after servicing animations:
     *  - cancel the timer and not request to be woken again (expectNoMoreActions)
     *  - cancel the timer and request to be woken on the next frame (expectNextFrameAction)
     *  - cancel the timer and request to be woken at some point in the future (expectDelayedAction)
     */

    void expectNoMoreActions()
    {
        EXPECT_CALL(*this, cancelWake());
    }

    void expectNextFrameAction()
    {
        ::testing::Sequence sequence;
        EXPECT_CALL(*this, cancelWake()).InSequence(sequence);
        EXPECT_CALL(*this, serviceOnNextFrame()).InSequence(sequence);
    }

    void expectDelayedAction(double when)
    {
        ::testing::Sequence sequence;
        EXPECT_CALL(*this, cancelWake()).InSequence(sequence);
        EXPECT_CALL(*this, wakeAfter(when)).InSequence(sequence);
    }
};

class AnimationAnimationTimelineTest : public ::testing::Test {
protected:
    virtual void SetUp()
    {
        document = Document::create();
        document->animationClock().resetTimeForTesting();
        element = Element::create(nullName, document.get());
        platformTiming = new MockPlatformTiming;
        timeline = AnimationTimeline::create(document.get(), adoptPtr(platformTiming));
        ASSERT_EQ(0, timeline->currentTimeInternal());
    }

    virtual void TearDown()
    {
        document.release();
        element.release();
        timeline.release();
    }

    void updateClockAndService(double time)
    {
        document->animationClock().updateTime(time);
        document->pendingAnimations().update(false);
        timeline->serviceAnimations(TimingUpdateForAnimationFrame);
    }

    RefPtr<Document> document;
    RefPtr<Element> element;
    RefPtr<AnimationTimeline> timeline;
    Timing timing;
    MockPlatformTiming* platformTiming;

    void wake()
    {
        timeline->wake();
    }

    double minimumDelay()
    {
        return AnimationTimeline::s_minimumDelay;
    }
};

TEST_F(AnimationAnimationTimelineTest, HasStarted)
{
    timeline = AnimationTimeline::create(document.get());
}

TEST_F(AnimationAnimationTimelineTest, EmptyKeyframeAnimation)
{
    RefPtr<AnimatableValueKeyframeEffectModel> effect = AnimatableValueKeyframeEffectModel::create(AnimatableValueKeyframeVector());
    RefPtr<Animation> anim = Animation::create(element.get(), effect, timing);

    timeline->play(anim.get());

    platformTiming->expectNoMoreActions();
    updateClockAndService(0);
    EXPECT_FLOAT_EQ(0, timeline->currentTimeInternal());
    EXPECT_FALSE(anim->isInEffect());

    platformTiming->expectNoMoreActions();
    updateClockAndService(100);
    EXPECT_FLOAT_EQ(100, timeline->currentTimeInternal());
}

TEST_F(AnimationAnimationTimelineTest, EmptyForwardsKeyframeAnimation)
{
    RefPtr<AnimatableValueKeyframeEffectModel> effect = AnimatableValueKeyframeEffectModel::create(AnimatableValueKeyframeVector());
    timing.fillMode = Timing::FillModeForwards;
    RefPtr<Animation> anim = Animation::create(element.get(), effect, timing);

    timeline->play(anim.get());

    platformTiming->expectNoMoreActions();
    updateClockAndService(0);
    EXPECT_FLOAT_EQ(0, timeline->currentTimeInternal());
    EXPECT_TRUE(anim->isInEffect());

    platformTiming->expectNoMoreActions();
    updateClockAndService(100);
    EXPECT_FLOAT_EQ(100, timeline->currentTimeInternal());
}

TEST_F(AnimationAnimationTimelineTest, ZeroTime)
{
    timeline = AnimationTimeline::create(document.get());
    bool isNull;

    document->animationClock().updateTime(100);
    EXPECT_EQ(100, timeline->currentTimeInternal());
    EXPECT_EQ(100, timeline->currentTimeInternal(isNull));
    EXPECT_FALSE(isNull);

    document->animationClock().updateTime(200);
    EXPECT_EQ(200, timeline->currentTimeInternal());
    EXPECT_EQ(200, timeline->currentTimeInternal(isNull));
    EXPECT_FALSE(isNull);
}

TEST_F(AnimationAnimationTimelineTest, DelayBeforeAnimationStart)
{
    timing.iterationDuration = 2;
    timing.startDelay = 5;

    RefPtr<Animation> anim = Animation::create(element.get(), nullptr, timing);

    timeline->play(anim.get());

    // TODO: Put the player startTime in the future when we add the capability to change player startTime
    platformTiming->expectDelayedAction(timing.startDelay - minimumDelay());
    updateClockAndService(0);

    platformTiming->expectDelayedAction(timing.startDelay - minimumDelay() - 1.5);
    updateClockAndService(1.5);

    EXPECT_CALL(*platformTiming, serviceOnNextFrame());
    wake();

    platformTiming->expectNextFrameAction();
    updateClockAndService(4.98);
}

TEST_F(AnimationAnimationTimelineTest, PlayAfterDocumentDeref)
{
    timing.iterationDuration = 2;
    timing.startDelay = 5;

    timeline = &document->timeline();
    element = nullptr;
    document = nullptr;

    RefPtr<Animation> anim = Animation::create(0, nullptr, timing);
    // Test passes if this does not crash.
    timeline->play(anim.get());
}

TEST_F(AnimationAnimationTimelineTest, UseAnimationPlayerAfterTimelineDeref)
{
    RefPtr<AnimationPlayer> player = timeline->createAnimationPlayer(0);
    timeline.clear();
    // Test passes if this does not crash.
    player->setStartTime(0);
}

}
