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
#include "core/animation/AnimationPlayer.h"

#include "core/animation/ActiveAnimations.h"
#include "core/animation/Animation.h"
#include "core/animation/AnimationClock.h"
#include "core/animation/AnimationTimeline.h"
#include "core/dom/Document.h"
#include "core/dom/QualifiedName.h"
#include "platform/weborigin/KURL.h"
#include <gtest/gtest.h>

using namespace blink;

namespace {

class AnimationAnimationPlayerTest : public ::testing::Test {
protected:
    virtual void SetUp()
    {
        setUpWithoutStartingTimeline();
        startTimeline();
    }

    void setUpWithoutStartingTimeline()
    {
        document = Document::create();
        document->animationClock().resetTimeForTesting();
        timeline = AnimationTimeline::create(document.get());
        player = timeline->createAnimationPlayer(0);
        player->setStartTime(0);
        player->setSource(makeAnimation().get());
    }

    void startTimeline()
    {
        simulateFrame(0);
    }

    PassRefPtrWillBeRawPtr<Animation> makeAnimation(double duration = 30, double playbackRate = 1)
    {
        Timing timing;
        timing.iterationDuration = duration;
        timing.playbackRate = playbackRate;
        return Animation::create(0, nullptr, timing);
    }

    bool simulateFrame(double time)
    {
        document->animationClock().updateTime(time);
        document->compositorPendingAnimations().update(false);
        // The timeline does not know about our player, so we have to explicitly call update().
        return player->update(TimingUpdateForAnimationFrame);
    }

    RefPtrWillBePersistent<Document> document;
    RefPtrWillBePersistent<AnimationTimeline> timeline;
    RefPtrWillBePersistent<AnimationPlayer> player;
    TrackExceptionState exceptionState;
};

TEST_F(AnimationAnimationPlayerTest, InitialState)
{
    setUpWithoutStartingTimeline();
    player = timeline->createAnimationPlayer(0);
    EXPECT_EQ(AnimationPlayer::Pending, player->playStateInternal());
    EXPECT_EQ(0, player->currentTimeInternal());
    EXPECT_FALSE(player->paused());
    EXPECT_EQ(1, player->playbackRate());
    EXPECT_FALSE(player->hasStartTime());
    EXPECT_TRUE(isNull(player->startTimeInternal()));

    startTimeline();
    EXPECT_EQ(AnimationPlayer::Finished, player->playStateInternal());
    EXPECT_EQ(0, timeline->currentTimeInternal());
    EXPECT_EQ(0, player->currentTimeInternal());
    EXPECT_FALSE(player->paused());
    EXPECT_EQ(1, player->playbackRate());
    EXPECT_EQ(0, player->startTimeInternal());
    EXPECT_TRUE(player->hasStartTime());
}


TEST_F(AnimationAnimationPlayerTest, CurrentTimeDoesNotSetOutdated)
{
    EXPECT_FALSE(player->outdated());
    EXPECT_EQ(0, player->currentTimeInternal());
    EXPECT_FALSE(player->outdated());
    // FIXME: We should split simulateFrame into a version that doesn't update
    // the player and one that does, as most of the tests don't require update()
    // to be called.
    document->animationClock().updateTime(10);
    EXPECT_EQ(10, player->currentTimeInternal());
    EXPECT_FALSE(player->outdated());
}

TEST_F(AnimationAnimationPlayerTest, SetCurrentTime)
{
    EXPECT_EQ(AnimationPlayer::Running, player->playStateInternal());
    player->setCurrentTimeInternal(10);
    EXPECT_EQ(AnimationPlayer::Running, player->playStateInternal());
    EXPECT_EQ(10, player->currentTimeInternal());
    simulateFrame(10);
    EXPECT_EQ(AnimationPlayer::Running, player->playStateInternal());
    EXPECT_EQ(20, player->currentTimeInternal());
}

TEST_F(AnimationAnimationPlayerTest, SetCurrentTimeNegative)
{
    player->setCurrentTimeInternal(-10);
    EXPECT_EQ(AnimationPlayer::Running, player->playStateInternal());
    EXPECT_EQ(-10, player->currentTimeInternal());
    simulateFrame(20);
    EXPECT_EQ(10, player->currentTimeInternal());

    player->setPlaybackRate(-2);
    player->setCurrentTimeInternal(-10);
    EXPECT_EQ(AnimationPlayer::Pending, player->playStateInternal());
    EXPECT_EQ(-10, player->currentTimeInternal());
    simulateFrame(40);
    EXPECT_EQ(AnimationPlayer::Finished, player->playStateInternal());
    EXPECT_EQ(-10, player->currentTimeInternal());
}

TEST_F(AnimationAnimationPlayerTest, SetCurrentTimeNegativeWithoutSimultaneousPlaybackRateChange)
{
    simulateFrame(20);
    EXPECT_EQ(20, player->currentTimeInternal());
    EXPECT_EQ(AnimationPlayer::Running, player->playStateInternal());
    player->setPlaybackRate(-1);
    EXPECT_EQ(AnimationPlayer::Pending, player->playStateInternal());
    simulateFrame(30);
    EXPECT_EQ(20, player->currentTimeInternal());
    EXPECT_EQ(AnimationPlayer::Running, player->playStateInternal());
    player->setCurrentTimeInternal(-10);
    EXPECT_EQ(AnimationPlayer::Finished, player->playStateInternal());
}

TEST_F(AnimationAnimationPlayerTest, SetCurrentTimePastContentEnd)
{
    player->setCurrentTimeInternal(50);
    EXPECT_EQ(AnimationPlayer::Finished, player->playStateInternal());
    EXPECT_EQ(50, player->currentTimeInternal());
    simulateFrame(20);
    EXPECT_EQ(AnimationPlayer::Finished, player->playStateInternal());
    EXPECT_EQ(50, player->currentTimeInternal());

    player->setPlaybackRate(-2);
    player->setCurrentTimeInternal(50);
    EXPECT_EQ(AnimationPlayer::Pending, player->playStateInternal());
    EXPECT_EQ(50, player->currentTimeInternal());
    simulateFrame(20);
    EXPECT_EQ(AnimationPlayer::Running, player->playStateInternal());
    simulateFrame(40);
    EXPECT_EQ(10, player->currentTimeInternal());
}

TEST_F(AnimationAnimationPlayerTest, SetCurrentTimeBeforeTimelineStarted)
{
    setUpWithoutStartingTimeline();
    player->setCurrentTimeInternal(5);
    EXPECT_EQ(5, player->currentTimeInternal());
    startTimeline();
    simulateFrame(10);
    EXPECT_EQ(15, player->currentTimeInternal());
}

TEST_F(AnimationAnimationPlayerTest, SetCurrentTimePastContentEndBeforeTimelineStarted)
{
    setUpWithoutStartingTimeline();
    player->setCurrentTimeInternal(250);
    EXPECT_EQ(250, player->currentTimeInternal());
    startTimeline();
    simulateFrame(10);
    EXPECT_EQ(250, player->currentTimeInternal());
}

TEST_F(AnimationAnimationPlayerTest, SetCurrentTimeMax)
{
    player->setCurrentTimeInternal(std::numeric_limits<double>::max());
    EXPECT_EQ(std::numeric_limits<double>::max(), player->currentTimeInternal());
    simulateFrame(100);
    EXPECT_EQ(std::numeric_limits<double>::max(), player->currentTimeInternal());
}

TEST_F(AnimationAnimationPlayerTest, SetCurrentTimeUnrestrictedDouble)
{
    simulateFrame(10);
    player->setCurrentTime(nullValue());
    EXPECT_EQ(10, player->currentTimeInternal());
    player->setCurrentTime(std::numeric_limits<double>::infinity());
    EXPECT_EQ(10, player->currentTimeInternal());
    player->setCurrentTime(-std::numeric_limits<double>::infinity());
    EXPECT_EQ(10, player->currentTimeInternal());
}


TEST_F(AnimationAnimationPlayerTest, SetCurrentTimeSetsStartTime)
{
    EXPECT_EQ(0, player->startTime());
    player->setCurrentTime(1000);
    EXPECT_EQ(-1000, player->startTime());
    simulateFrame(1);
    EXPECT_EQ(-1000, player->startTime());
    EXPECT_EQ(2000, player->currentTime());
}

TEST_F(AnimationAnimationPlayerTest, SetStartTime)
{
    simulateFrame(20);
    EXPECT_EQ(AnimationPlayer::Running, player->playStateInternal());
    EXPECT_EQ(0, player->startTimeInternal());
    EXPECT_EQ(20, player->currentTimeInternal());
    player->setStartTime(10 * 1000);
    EXPECT_EQ(AnimationPlayer::Running, player->playStateInternal());
    EXPECT_EQ(10, player->startTimeInternal());
    EXPECT_EQ(10, player->currentTimeInternal());
    simulateFrame(30);
    EXPECT_EQ(10, player->startTimeInternal());
    EXPECT_EQ(20, player->currentTimeInternal());
    player->setStartTime(-20 * 1000);
    EXPECT_EQ(AnimationPlayer::Finished, player->playStateInternal());
}

TEST_F(AnimationAnimationPlayerTest, SetStartTimeLimitsAnimationPlayer)
{
    player->setStartTime(-50 * 1000);
    EXPECT_EQ(AnimationPlayer::Finished, player->playStateInternal());
    EXPECT_EQ(30, player->currentTimeInternal());
    player->setPlaybackRate(-1);
    EXPECT_EQ(AnimationPlayer::Pending, player->playStateInternal());
    player->setStartTime(-100 * 1000);
    EXPECT_EQ(AnimationPlayer::Finished, player->playStateInternal());
    EXPECT_EQ(0, player->currentTimeInternal());
    EXPECT_TRUE(player->finished());
}

TEST_F(AnimationAnimationPlayerTest, SetStartTimeOnLimitedAnimationPlayer)
{
    simulateFrame(30);
    player->setStartTime(-10 * 1000);
    EXPECT_EQ(AnimationPlayer::Finished, player->playStateInternal());
    EXPECT_EQ(30, player->currentTimeInternal());
    player->setCurrentTimeInternal(50);
    player->setStartTime(-40 * 1000);
    EXPECT_EQ(30, player->currentTimeInternal());
    EXPECT_EQ(AnimationPlayer::Finished, player->playStateInternal());
    EXPECT_TRUE(player->finished());
}

TEST_F(AnimationAnimationPlayerTest, StartTimePauseFinish)
{
    player->pause();
    EXPECT_EQ(AnimationPlayer::Pending, player->playStateInternal());
    EXPECT_TRUE(std::isnan(player->startTime()));
    player->finish(exceptionState);
    EXPECT_EQ(AnimationPlayer::Pending, player->playStateInternal());
    EXPECT_TRUE(std::isnan(player->startTime()));
}

TEST_F(AnimationAnimationPlayerTest, PauseBeatsFinish)
{
    player->pause();
    EXPECT_EQ(AnimationPlayer::Pending, player->playStateInternal());
    simulateFrame(10);
    EXPECT_EQ(AnimationPlayer::Paused, player->playStateInternal());
    player->finish(exceptionState);
    EXPECT_EQ(AnimationPlayer::Paused, player->playStateInternal());
}

TEST_F(AnimationAnimationPlayerTest, StartTimeFinishPause)
{
    double startTime = player->startTime();
    player->finish(exceptionState);
    EXPECT_EQ(startTime, player->startTime());
    player->pause();
    EXPECT_TRUE(std::isnan(player->startTime()));
}

TEST_F(AnimationAnimationPlayerTest, StartTimeWithZeroPlaybackRate)
{
    player->setPlaybackRate(0);
    EXPECT_EQ(AnimationPlayer::Pending, player->playStateInternal());
    EXPECT_TRUE(std::isnan(player->startTime()));
    simulateFrame(10);
    EXPECT_EQ(AnimationPlayer::Running, player->playStateInternal());
}

TEST_F(AnimationAnimationPlayerTest, PausePlay)
{
    simulateFrame(10);
    player->pause();
    EXPECT_EQ(AnimationPlayer::Pending, player->playStateInternal());
    EXPECT_TRUE(player->paused());
    EXPECT_EQ(10, player->currentTimeInternal());
    simulateFrame(20);
    EXPECT_EQ(AnimationPlayer::Paused, player->playStateInternal());
    player->play();
    EXPECT_EQ(AnimationPlayer::Pending, player->playStateInternal());
    simulateFrame(20);
    EXPECT_EQ(AnimationPlayer::Running, player->playStateInternal());
    EXPECT_FALSE(player->paused());
    EXPECT_EQ(10, player->currentTimeInternal());
    simulateFrame(30);
    EXPECT_EQ(20, player->currentTimeInternal());
}

TEST_F(AnimationAnimationPlayerTest, PauseBeforeTimelineStarted)
{
    setUpWithoutStartingTimeline();
    player->pause();
    EXPECT_TRUE(player->paused());
    player->play();
    EXPECT_FALSE(player->paused());

    player->pause();
    startTimeline();
    simulateFrame(100);
    EXPECT_TRUE(player->paused());
    EXPECT_EQ(0, player->currentTimeInternal());
}

TEST_F(AnimationAnimationPlayerTest, PlayRewindsToStart)
{
    player->setCurrentTimeInternal(30);
    player->play();
    EXPECT_EQ(0, player->currentTimeInternal());

    player->setCurrentTimeInternal(40);
    player->play();
    EXPECT_EQ(0, player->currentTimeInternal());
    EXPECT_EQ(AnimationPlayer::Pending, player->playStateInternal());
    simulateFrame(10);
    EXPECT_EQ(AnimationPlayer::Running, player->playStateInternal());

    player->setCurrentTimeInternal(-10);
    EXPECT_EQ(AnimationPlayer::Running, player->playStateInternal());
    player->play();
    EXPECT_EQ(0, player->currentTimeInternal());
    EXPECT_EQ(AnimationPlayer::Running, player->playStateInternal());
}

TEST_F(AnimationAnimationPlayerTest, PlayRewindsToEnd)
{
    player->setPlaybackRate(-1);
    player->play();
    EXPECT_EQ(30, player->currentTimeInternal());

    player->setCurrentTimeInternal(40);
    EXPECT_EQ(AnimationPlayer::Pending, player->playStateInternal());
    player->play();
    EXPECT_EQ(30, player->currentTimeInternal());
    EXPECT_EQ(AnimationPlayer::Pending, player->playStateInternal());
    simulateFrame(10);
    EXPECT_EQ(AnimationPlayer::Running, player->playStateInternal());

    player->setCurrentTimeInternal(-10);
    player->play();
    EXPECT_EQ(30, player->currentTimeInternal());
    EXPECT_EQ(AnimationPlayer::Pending, player->playStateInternal());
    simulateFrame(20);
    EXPECT_EQ(AnimationPlayer::Running, player->playStateInternal());
}

TEST_F(AnimationAnimationPlayerTest, PlayWithPlaybackRateZeroDoesNotSeek)
{
    player->setPlaybackRate(0);
    player->play();
    EXPECT_EQ(0, player->currentTimeInternal());

    player->setCurrentTimeInternal(40);
    player->play();
    EXPECT_EQ(40, player->currentTimeInternal());

    player->setCurrentTimeInternal(-10);
    player->play();
    EXPECT_EQ(-10, player->currentTimeInternal());
}

TEST_F(AnimationAnimationPlayerTest, PlayAfterPauseWithPlaybackRateZeroUpdatesPlayState)
{
    player->pause();
    player->setPlaybackRate(0);
    simulateFrame(1);
    EXPECT_EQ(AnimationPlayer::Paused, player->playStateInternal());
    player->play();
    EXPECT_EQ(AnimationPlayer::Running, player->playStateInternal());
}

TEST_F(AnimationAnimationPlayerTest, Reverse)
{
    player->setCurrentTimeInternal(10);
    player->pause();
    player->reverse();
    EXPECT_FALSE(player->paused());
    EXPECT_EQ(-1, player->playbackRate());
    EXPECT_EQ(10, player->currentTimeInternal());
}

TEST_F(AnimationAnimationPlayerTest, ReverseDoesNothingWithPlaybackRateZero)
{
    player->setCurrentTimeInternal(10);
    player->setPlaybackRate(0);
    player->pause();
    player->reverse();
    EXPECT_TRUE(player->paused());
    EXPECT_EQ(0, player->playbackRate());
    EXPECT_EQ(10, player->currentTimeInternal());
}

TEST_F(AnimationAnimationPlayerTest, ReverseDoesNotSeekWithNoSource)
{
    player->setSource(0);
    player->setCurrentTimeInternal(10);
    player->reverse();
    EXPECT_EQ(10, player->currentTimeInternal());
}

TEST_F(AnimationAnimationPlayerTest, ReverseSeeksToStart)
{
    player->setCurrentTimeInternal(-10);
    player->setPlaybackRate(-1);
    player->reverse();
    EXPECT_EQ(0, player->currentTimeInternal());
}

TEST_F(AnimationAnimationPlayerTest, ReverseSeeksToEnd)
{
    player->setCurrentTimeInternal(40);
    player->reverse();
    EXPECT_EQ(30, player->currentTimeInternal());
}

TEST_F(AnimationAnimationPlayerTest, ReverseLimitsAnimationPlayer)
{
    player->setCurrentTimeInternal(40);
    player->setPlaybackRate(-1);
    player->reverse();
    EXPECT_TRUE(player->finished());
    EXPECT_EQ(40, player->currentTimeInternal());

    player->setCurrentTimeInternal(-10);
    player->reverse();
    EXPECT_TRUE(player->finished());
    EXPECT_EQ(-10, player->currentTimeInternal());
}


TEST_F(AnimationAnimationPlayerTest, Finish)
{
    player->finish(exceptionState);
    EXPECT_EQ(30, player->currentTimeInternal());
    EXPECT_TRUE(player->finished());

    player->setPlaybackRate(-1);
    player->finish(exceptionState);
    EXPECT_EQ(0, player->currentTimeInternal());
    EXPECT_TRUE(player->finished());

    EXPECT_FALSE(exceptionState.hadException());
}

TEST_F(AnimationAnimationPlayerTest, FinishAfterSourceEnd)
{
    player->setCurrentTimeInternal(40);
    player->finish(exceptionState);
    EXPECT_EQ(30, player->currentTimeInternal());
}

TEST_F(AnimationAnimationPlayerTest, FinishBeforeStart)
{
    player->setCurrentTimeInternal(-10);
    player->setPlaybackRate(-1);
    player->finish(exceptionState);
    EXPECT_EQ(0, player->currentTimeInternal());
}

TEST_F(AnimationAnimationPlayerTest, FinishDoesNothingWithPlaybackRateZero)
{
    player->setCurrentTimeInternal(10);
    player->setPlaybackRate(0);
    player->finish(exceptionState);
    EXPECT_EQ(10, player->currentTimeInternal());
}

TEST_F(AnimationAnimationPlayerTest, FinishRaisesException)
{
    Timing timing;
    timing.iterationDuration = 1;
    timing.iterationCount = std::numeric_limits<double>::infinity();
    player->setSource(Animation::create(0, nullptr, timing).get());
    player->setCurrentTimeInternal(10);

    player->finish(exceptionState);
    EXPECT_EQ(10, player->currentTimeInternal());
    EXPECT_TRUE(exceptionState.hadException());
    EXPECT_EQ(InvalidStateError, exceptionState.code());
}


TEST_F(AnimationAnimationPlayerTest, LimitingAtSourceEnd)
{
    simulateFrame(30);
    EXPECT_EQ(30, player->currentTimeInternal());
    EXPECT_TRUE(player->finished());
    simulateFrame(40);
    EXPECT_EQ(30, player->currentTimeInternal());
    EXPECT_FALSE(player->paused());
}

TEST_F(AnimationAnimationPlayerTest, LimitingAtStart)
{
    simulateFrame(30);
    player->setPlaybackRate(-2);
    simulateFrame(30);
    simulateFrame(45);
    EXPECT_EQ(0, player->currentTimeInternal());
    EXPECT_TRUE(player->finished());
    simulateFrame(60);
    EXPECT_EQ(0, player->currentTimeInternal());
    EXPECT_FALSE(player->paused());
}

TEST_F(AnimationAnimationPlayerTest, LimitingWithNoSource)
{
    player->setSource(0);
    EXPECT_TRUE(player->finished());
    simulateFrame(30);
    EXPECT_EQ(0, player->currentTimeInternal());
}


TEST_F(AnimationAnimationPlayerTest, SetPlaybackRate)
{
    player->setPlaybackRate(2);
    simulateFrame(0);
    EXPECT_EQ(2, player->playbackRate());
    EXPECT_EQ(0, player->currentTimeInternal());
    simulateFrame(10);
    EXPECT_EQ(20, player->currentTimeInternal());
}

TEST_F(AnimationAnimationPlayerTest, SetPlaybackRateBeforeTimelineStarted)
{
    setUpWithoutStartingTimeline();
    player->setPlaybackRate(2);
    EXPECT_EQ(2, player->playbackRate());
    EXPECT_EQ(0, player->currentTimeInternal());
    startTimeline();
    simulateFrame(10);
    EXPECT_EQ(20, player->currentTimeInternal());
}

TEST_F(AnimationAnimationPlayerTest, SetPlaybackRateWhilePaused)
{
    simulateFrame(10);
    player->pause();
    player->setPlaybackRate(2);
    simulateFrame(20);
    player->play();
    EXPECT_EQ(10, player->currentTimeInternal());
    simulateFrame(20);
    simulateFrame(25);
    EXPECT_EQ(20, player->currentTimeInternal());
}

TEST_F(AnimationAnimationPlayerTest, SetPlaybackRateWhileLimited)
{
    simulateFrame(40);
    EXPECT_EQ(30, player->currentTimeInternal());
    player->setPlaybackRate(2);
    simulateFrame(50);
    EXPECT_EQ(30, player->currentTimeInternal());
    player->setPlaybackRate(-2);
    simulateFrame(50);
    simulateFrame(60);
    EXPECT_FALSE(player->finished());
    EXPECT_EQ(10, player->currentTimeInternal());
}

TEST_F(AnimationAnimationPlayerTest, SetPlaybackRateZero)
{
    simulateFrame(0);
    simulateFrame(10);
    player->setPlaybackRate(0);
    simulateFrame(10);
    EXPECT_EQ(10, player->currentTimeInternal());
    simulateFrame(20);
    EXPECT_EQ(10, player->currentTimeInternal());
    player->setCurrentTimeInternal(20);
    EXPECT_EQ(20, player->currentTimeInternal());
}

TEST_F(AnimationAnimationPlayerTest, SetPlaybackRateMax)
{
    player->setPlaybackRate(std::numeric_limits<double>::max());
    simulateFrame(0);
    EXPECT_EQ(std::numeric_limits<double>::max(), player->playbackRate());
    EXPECT_EQ(0, player->currentTimeInternal());
    simulateFrame(1);
    EXPECT_EQ(30, player->currentTimeInternal());
}


TEST_F(AnimationAnimationPlayerTest, SetSource)
{
    player = timeline->createAnimationPlayer(0);
    player->setStartTime(0);
    RefPtrWillBeRawPtr<AnimationNode> source1 = makeAnimation();
    RefPtrWillBeRawPtr<AnimationNode> source2 = makeAnimation();
    player->setSource(source1.get());
    EXPECT_EQ(source1, player->source());
    EXPECT_EQ(0, player->currentTimeInternal());
    player->setCurrentTimeInternal(15);
    player->setSource(source2.get());
    EXPECT_EQ(15, player->currentTimeInternal());
    EXPECT_EQ(0, source1->player());
    EXPECT_EQ(player.get(), source2->player());
    EXPECT_EQ(source2, player->source());
}

TEST_F(AnimationAnimationPlayerTest, SetSourceLimitsAnimationPlayer)
{
    player->setCurrentTimeInternal(20);
    player->setSource(makeAnimation(10).get());
    EXPECT_EQ(20, player->currentTimeInternal());
    EXPECT_TRUE(player->finished());
    simulateFrame(10);
    EXPECT_EQ(20, player->currentTimeInternal());
}

TEST_F(AnimationAnimationPlayerTest, SetSourceUnlimitsAnimationPlayer)
{
    player->setCurrentTimeInternal(40);
    player->setSource(makeAnimation(60).get());
    EXPECT_FALSE(player->finished());
    EXPECT_EQ(40, player->currentTimeInternal());
    simulateFrame(10);
    EXPECT_EQ(50, player->currentTimeInternal());
}


TEST_F(AnimationAnimationPlayerTest, EmptyAnimationPlayersDontUpdateEffects)
{
    player = timeline->createAnimationPlayer(0);
    player->update(TimingUpdateOnDemand);
    EXPECT_EQ(std::numeric_limits<double>::infinity(), player->timeToEffectChange());

    simulateFrame(1234);
    EXPECT_EQ(std::numeric_limits<double>::infinity(), player->timeToEffectChange());
}

TEST_F(AnimationAnimationPlayerTest, AnimationPlayersDisassociateFromSource)
{
    AnimationNode* animationNode = player->source();
    AnimationPlayer* player2 = timeline->createAnimationPlayer(animationNode);
    EXPECT_EQ(0, player->source());
    player->setSource(animationNode);
    EXPECT_EQ(0, player2->source());
}

TEST_F(AnimationAnimationPlayerTest, AnimationPlayersReturnTimeToNextEffect)
{
    Timing timing;
    timing.startDelay = 1;
    timing.iterationDuration = 1;
    timing.endDelay = 1;
    RefPtrWillBeRawPtr<Animation> animation = Animation::create(0, nullptr, timing);
    player = timeline->createAnimationPlayer(animation.get());
    player->setStartTime(0);

    simulateFrame(0);
    EXPECT_EQ(1, player->timeToEffectChange());

    simulateFrame(0.5);
    EXPECT_EQ(0.5, player->timeToEffectChange());

    simulateFrame(1);
    EXPECT_EQ(0, player->timeToEffectChange());

    simulateFrame(1.5);
    EXPECT_EQ(0, player->timeToEffectChange());

    simulateFrame(2);
    EXPECT_EQ(std::numeric_limits<double>::infinity(), player->timeToEffectChange());

    simulateFrame(3);
    EXPECT_EQ(std::numeric_limits<double>::infinity(), player->timeToEffectChange());

    player->setCurrentTimeInternal(0);
    simulateFrame(3);
    EXPECT_EQ(1, player->timeToEffectChange());

    player->setPlaybackRate(2);
    simulateFrame(3);
    EXPECT_EQ(0.5, player->timeToEffectChange());

    player->setPlaybackRate(0);
    player->update(TimingUpdateOnDemand);
    EXPECT_EQ(std::numeric_limits<double>::infinity(), player->timeToEffectChange());

    player->setCurrentTimeInternal(3);
    player->setPlaybackRate(-1);
    player->update(TimingUpdateOnDemand);
    simulateFrame(3);
    EXPECT_EQ(1, player->timeToEffectChange());

    player->setPlaybackRate(-2);
    player->update(TimingUpdateOnDemand);
    simulateFrame(3);
    EXPECT_EQ(0.5, player->timeToEffectChange());
}

TEST_F(AnimationAnimationPlayerTest, TimeToNextEffectWhenPaused)
{
    EXPECT_EQ(0, player->timeToEffectChange());
    player->pause();
    player->update(TimingUpdateOnDemand);
    EXPECT_EQ(std::numeric_limits<double>::infinity(), player->timeToEffectChange());
}

TEST_F(AnimationAnimationPlayerTest, TimeToNextEffectWhenCancelledBeforeStart)
{
    EXPECT_EQ(0, player->timeToEffectChange());
    player->setCurrentTimeInternal(-8);
    player->setPlaybackRate(2);
    player->cancel();
    player->update(TimingUpdateOnDemand);
    simulateFrame(0);
    EXPECT_EQ(4, player->timeToEffectChange());
}

TEST_F(AnimationAnimationPlayerTest, TimeToNextEffectWhenCancelledBeforeStartReverse)
{
    EXPECT_EQ(0, player->timeToEffectChange());
    player->setCurrentTimeInternal(9);
    player->setPlaybackRate(-3);
    player->cancel();
    player->update(TimingUpdateOnDemand);
    simulateFrame(0);
    EXPECT_EQ(3, player->timeToEffectChange());
}

TEST_F(AnimationAnimationPlayerTest, AttachedAnimationPlayers)
{
    RefPtrWillBePersistent<Element> element = document->createElement("foo", ASSERT_NO_EXCEPTION);

    Timing timing;
    RefPtrWillBeRawPtr<Animation> animation = Animation::create(element.get(), nullptr, timing);
    RefPtrWillBeRawPtr<AnimationPlayer> player = timeline->createAnimationPlayer(animation.get());
    simulateFrame(0);
    timeline->serviceAnimations(TimingUpdateForAnimationFrame);
    EXPECT_EQ(1U, element->activeAnimations()->players().find(player.get())->value);

    player.release();
    Heap::collectAllGarbage();
    EXPECT_TRUE(element->activeAnimations()->players().isEmpty());
}

TEST_F(AnimationAnimationPlayerTest, HasLowerPriority)
{
    RefPtrWillBeRawPtr<AnimationPlayer> player1 = timeline->createAnimationPlayer(0);
    RefPtrWillBeRawPtr<AnimationPlayer> player2 = timeline->createAnimationPlayer(0);
    EXPECT_TRUE(AnimationPlayer::hasLowerPriority(player1.get(), player2.get()));
}

}
