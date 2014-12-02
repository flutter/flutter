// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/animation/AnimationStack.h"

#include <gtest/gtest.h>
#include "sky/engine/core/animation/ActiveAnimations.h"
#include "sky/engine/core/animation/AnimationClock.h"
#include "sky/engine/core/animation/AnimationTimeline.h"
#include "sky/engine/core/animation/KeyframeEffectModel.h"
#include "sky/engine/core/animation/LegacyStyleInterpolation.h"
#include "sky/engine/core/animation/animatable/AnimatableDouble.h"

namespace blink {

class AnimationAnimationStackTest : public ::testing::Test {
protected:
    virtual void SetUp()
    {
        document = Document::create();
        document->animationClock().resetTimeForTesting();
        timeline = AnimationTimeline::create(document.get());
        element = document->createElement("foo", ASSERT_NO_EXCEPTION);
    }

    AnimationPlayer* play(Animation* animation, double startTime)
    {
        AnimationPlayer* player = timeline->createAnimationPlayer(animation);
        player->setStartTimeInternal(startTime);
        player->update(TimingUpdateOnDemand);
        return player;
    }

    void updateTimeline(double time)
    {
        document->animationClock().updateTime(time);
        timeline->serviceAnimations(TimingUpdateForAnimationFrame);
    }

    const Vector<OwnPtr<SampledEffect> >& effects()
    {
        return element->ensureActiveAnimations().defaultStack().m_effects;
    }

    PassRefPtr<AnimationEffect> makeAnimationEffect(CSSPropertyID id, PassRefPtr<AnimatableValue> value)
    {
        AnimatableValueKeyframeVector keyframes(2);
        keyframes[0] = AnimatableValueKeyframe::create();
        keyframes[0]->setOffset(0.0);
        keyframes[0]->setPropertyValue(id, value.get());
        keyframes[1] = AnimatableValueKeyframe::create();
        keyframes[1]->setOffset(1.0);
        keyframes[1]->setPropertyValue(id, value.get());
        return AnimatableValueKeyframeEffectModel::create(keyframes);
    }

    PassRefPtr<InertAnimation> makeInertAnimation(PassRefPtr<AnimationEffect> effect)
    {
        Timing timing;
        timing.fillMode = Timing::FillModeBoth;
        return InertAnimation::create(effect, timing, false);
    }

    PassRefPtr<Animation> makeAnimation(PassRefPtr<AnimationEffect> effect, double duration = 10)
    {
        Timing timing;
        timing.fillMode = Timing::FillModeBoth;
        timing.iterationDuration = duration;
        return Animation::create(element.get(), effect, timing);
    }

    AnimatableValue* interpolationValue(Interpolation* interpolation)
    {
        return toLegacyStyleInterpolation(interpolation)->currentValue().get();
    }

    RefPtr<Document> document;
    RefPtr<AnimationTimeline> timeline;
    RefPtr<Element> element;
};

TEST_F(AnimationAnimationStackTest, ActiveAnimationsSorted)
{
    play(makeAnimation(makeAnimationEffect(CSSPropertyFontSize, AnimatableDouble::create(1))).get(), 10);
    play(makeAnimation(makeAnimationEffect(CSSPropertyFontSize, AnimatableDouble::create(2))).get(), 15);
    play(makeAnimation(makeAnimationEffect(CSSPropertyFontSize, AnimatableDouble::create(3))).get(), 5);
    HashMap<CSSPropertyID, RefPtr<Interpolation> > result = AnimationStack::activeInterpolations(&element->activeAnimations()->defaultStack(), 0, 0, Animation::DefaultPriority, 0);
    EXPECT_EQ(1u, result.size());
    EXPECT_TRUE(interpolationValue(result.get(CSSPropertyFontSize))->equals(AnimatableDouble::create(3).get()));
}

TEST_F(AnimationAnimationStackTest, NewAnimations)
{
    play(makeAnimation(makeAnimationEffect(CSSPropertyFontSize, AnimatableDouble::create(1))).get(), 15);
    play(makeAnimation(makeAnimationEffect(CSSPropertyZIndex, AnimatableDouble::create(2))).get(), 10);
    Vector<RawPtr<InertAnimation> > newAnimations;
    RefPtr<InertAnimation> inert1 = makeInertAnimation(makeAnimationEffect(CSSPropertyFontSize, AnimatableDouble::create(3)));
    RefPtr<InertAnimation> inert2 = makeInertAnimation(makeAnimationEffect(CSSPropertyZIndex, AnimatableDouble::create(4)));
    newAnimations.append(inert1.get());
    newAnimations.append(inert2.get());
    HashMap<CSSPropertyID, RefPtr<Interpolation> > result = AnimationStack::activeInterpolations(&element->activeAnimations()->defaultStack(), &newAnimations, 0, Animation::DefaultPriority, 10);
    EXPECT_EQ(2u, result.size());
    EXPECT_TRUE(interpolationValue(result.get(CSSPropertyFontSize))->equals(AnimatableDouble::create(3).get()));
    EXPECT_TRUE(interpolationValue(result.get(CSSPropertyZIndex))->equals(AnimatableDouble::create(4).get()));
}

TEST_F(AnimationAnimationStackTest, CancelledAnimationPlayers)
{
    HashSet<RawPtr<const AnimationPlayer> > cancelledAnimationPlayers;
    RefPtr<AnimationPlayer> player = play(makeAnimation(makeAnimationEffect(CSSPropertyFontSize, AnimatableDouble::create(1))).get(), 0);
    cancelledAnimationPlayers.add(player.get());
    play(makeAnimation(makeAnimationEffect(CSSPropertyZIndex, AnimatableDouble::create(2))).get(), 0);
    HashMap<CSSPropertyID, RefPtr<Interpolation> > result = AnimationStack::activeInterpolations(&element->activeAnimations()->defaultStack(), 0, &cancelledAnimationPlayers, Animation::DefaultPriority, 0);
    EXPECT_EQ(1u, result.size());
    EXPECT_TRUE(interpolationValue(result.get(CSSPropertyZIndex))->equals(AnimatableDouble::create(2).get()));
}

TEST_F(AnimationAnimationStackTest, ForwardsFillDiscarding)
{
    play(makeAnimation(makeAnimationEffect(CSSPropertyFontSize, AnimatableDouble::create(1))).get(), 2);
    play(makeAnimation(makeAnimationEffect(CSSPropertyFontSize, AnimatableDouble::create(2))).get(), 6);
    play(makeAnimation(makeAnimationEffect(CSSPropertyFontSize, AnimatableDouble::create(3))).get(), 4);
    document->pendingAnimations().update();
    HashMap<CSSPropertyID, RefPtr<Interpolation> > interpolations;

    updateTimeline(11);
    interpolations = AnimationStack::activeInterpolations(&element->activeAnimations()->defaultStack(), 0, 0, Animation::DefaultPriority, 0);
    EXPECT_TRUE(interpolationValue(interpolations.get(CSSPropertyFontSize))->equals(AnimatableDouble::create(3).get()));
    EXPECT_EQ(3u, effects().size());
    EXPECT_EQ(1u, interpolations.size());

    updateTimeline(13);
    interpolations = AnimationStack::activeInterpolations(&element->activeAnimations()->defaultStack(), 0, 0, Animation::DefaultPriority, 0);
    EXPECT_TRUE(interpolationValue(interpolations.get(CSSPropertyFontSize))->equals(AnimatableDouble::create(3).get()));
    EXPECT_EQ(3u, effects().size());

    updateTimeline(15);
    interpolations = AnimationStack::activeInterpolations(&element->activeAnimations()->defaultStack(), 0, 0, Animation::DefaultPriority, 0);
    EXPECT_TRUE(interpolationValue(interpolations.get(CSSPropertyFontSize))->equals(AnimatableDouble::create(3).get()));
    EXPECT_EQ(2u, effects().size());

    updateTimeline(17);
    interpolations = AnimationStack::activeInterpolations(&element->activeAnimations()->defaultStack(), 0, 0, Animation::DefaultPriority, 0);
    EXPECT_TRUE(interpolationValue(interpolations.get(CSSPropertyFontSize))->equals(AnimatableDouble::create(3).get()));
    EXPECT_EQ(1u, effects().size());
}

}
