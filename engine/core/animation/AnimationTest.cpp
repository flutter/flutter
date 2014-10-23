// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/animation/Animation.h"

#include "bindings/core/v8/Dictionary.h"
#include "bindings/core/v8/Nullable.h"
#include "core/animation/AnimationClock.h"
#include "core/animation/AnimationHelpers.h"
#include "core/animation/AnimationNodeTiming.h"
#include "core/animation/AnimationTestHelper.h"
#include "core/animation/AnimationTimeline.h"
#include "core/animation/KeyframeEffectModel.h"
#include "core/animation/Timing.h"
#include "core/dom/Document.h"
#include "core/testing/DummyPageHolder.h"
#include <gtest/gtest.h>
#include <v8.h>

namespace blink {

class AnimationAnimationTest : public ::testing::Test {
protected:
    AnimationAnimationTest()
        : pageHolder(DummyPageHolder::create())
        , document(pageHolder->document())
        , element(document.createElement("foo", ASSERT_NO_EXCEPTION))
    {
        document.animationClock().resetTimeForTesting();
        EXPECT_EQ(0, document.timeline().currentTime());
    }

    OwnPtr<DummyPageHolder> pageHolder;
    Document& document;
    RefPtrWillBePersistent<Element> element;
    TrackExceptionState exceptionState;
};

class AnimationAnimationV8Test : public AnimationAnimationTest {
protected:
    AnimationAnimationV8Test()
        : m_isolate(v8::Isolate::GetCurrent())
        , m_scope(m_isolate)
    {
    }

    template<typename T>
    static PassRefPtrWillBeRawPtr<Animation> createAnimation(Element* element, Vector<Dictionary> keyframeDictionaryVector, T timingInput, ExceptionState& exceptionState)
    {
        return Animation::create(element, EffectInput::convert(element, keyframeDictionaryVector, exceptionState), timingInput);
    }
    static PassRefPtrWillBeRawPtr<Animation> createAnimation(Element* element, Vector<Dictionary> keyframeDictionaryVector, ExceptionState& exceptionState)
    {
        return Animation::create(element, EffectInput::convert(element, keyframeDictionaryVector, exceptionState));
    }

    v8::Isolate* m_isolate;

private:
    V8TestingScope m_scope;
};

TEST_F(AnimationAnimationV8Test, CanCreateAnAnimation)
{
    Vector<Dictionary> jsKeyframes;
    v8::Handle<v8::Object> keyframe1 = v8::Object::New(m_isolate);
    v8::Handle<v8::Object> keyframe2 = v8::Object::New(m_isolate);

    setV8ObjectPropertyAsString(keyframe1, "width", "100px");
    setV8ObjectPropertyAsString(keyframe1, "offset", "0");
    setV8ObjectPropertyAsString(keyframe1, "easing", "ease-in-out");
    setV8ObjectPropertyAsString(keyframe2, "width", "0px");
    setV8ObjectPropertyAsString(keyframe2, "offset", "1");
    setV8ObjectPropertyAsString(keyframe2, "easing", "cubic-bezier(1, 1, 0.3, 0.3)");

    jsKeyframes.append(Dictionary(keyframe1, m_isolate));
    jsKeyframes.append(Dictionary(keyframe2, m_isolate));

    String value1;
    ASSERT_TRUE(DictionaryHelper::get(jsKeyframes[0], "width", value1));
    ASSERT_EQ("100px", value1);

    String value2;
    ASSERT_TRUE(DictionaryHelper::get(jsKeyframes[1], "width", value2));
    ASSERT_EQ("0px", value2);

    RefPtrWillBeRawPtr<Animation> animation = createAnimation(element.get(), jsKeyframes, 0, exceptionState);

    Element* target = animation->target();
    EXPECT_EQ(*element.get(), *target);

    const KeyframeVector keyframes = toKeyframeEffectModelBase(animation->effect())->getFrames();

    EXPECT_EQ(0, keyframes[0]->offset());
    EXPECT_EQ(1, keyframes[1]->offset());

    const CSSValue* keyframe1Width = toStringKeyframe(keyframes[0].get())->propertyValue(CSSPropertyWidth);
    const CSSValue* keyframe2Width = toStringKeyframe(keyframes[1].get())->propertyValue(CSSPropertyWidth);
    ASSERT(keyframe1Width);
    ASSERT(keyframe2Width);

    EXPECT_EQ("100px", keyframe1Width->cssText());
    EXPECT_EQ("0px", keyframe2Width->cssText());

    EXPECT_EQ(*(CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseInOut)), keyframes[0]->easing());
    EXPECT_EQ(*(CubicBezierTimingFunction::create(1, 1, 0.3, 0.3).get()), keyframes[1]->easing());
}

TEST_F(AnimationAnimationV8Test, CanSetDuration)
{
    Vector<Dictionary, 0> jsKeyframes;
    double duration = 2000;

    RefPtrWillBeRawPtr<Animation> animation = createAnimation(element.get(), jsKeyframes, duration, exceptionState);

    EXPECT_EQ(duration / 1000, animation->specifiedTiming().iterationDuration);
}

TEST_F(AnimationAnimationV8Test, CanOmitSpecifiedDuration)
{
    Vector<Dictionary, 0> jsKeyframes;
    RefPtrWillBeRawPtr<Animation> animation = createAnimation(element.get(), jsKeyframes, exceptionState);
    EXPECT_TRUE(std::isnan(animation->specifiedTiming().iterationDuration));
}

TEST_F(AnimationAnimationV8Test, NegativeDurationIsAuto)
{
    Vector<Dictionary, 0> jsKeyframes;
    RefPtrWillBeRawPtr<Animation> animation = createAnimation(element.get(), jsKeyframes, -2, exceptionState);
    EXPECT_TRUE(std::isnan(animation->specifiedTiming().iterationDuration));
}

TEST_F(AnimationAnimationV8Test, MismatchedKeyframePropertyRaisesException)
{
    Vector<Dictionary> jsKeyframes;
    v8::Handle<v8::Object> keyframe1 = v8::Object::New(m_isolate);
    v8::Handle<v8::Object> keyframe2 = v8::Object::New(m_isolate);

    setV8ObjectPropertyAsString(keyframe1, "width", "100px");
    setV8ObjectPropertyAsString(keyframe1, "offset", "0");

    // Height property appears only in keyframe2
    setV8ObjectPropertyAsString(keyframe2, "height", "100px");
    setV8ObjectPropertyAsString(keyframe2, "width", "0px");
    setV8ObjectPropertyAsString(keyframe2, "offset", "1");

    jsKeyframes.append(Dictionary(keyframe1, m_isolate));
    jsKeyframes.append(Dictionary(keyframe2, m_isolate));

    createAnimation(element.get(), jsKeyframes, 0, exceptionState);

    EXPECT_TRUE(exceptionState.hadException());
    EXPECT_EQ(NotSupportedError, exceptionState.code());
}

TEST_F(AnimationAnimationV8Test, MissingOffsetZeroRaisesException)
{
    Vector<Dictionary> jsKeyframes;
    v8::Handle<v8::Object> keyframe1 = v8::Object::New(m_isolate);
    v8::Handle<v8::Object> keyframe2 = v8::Object::New(m_isolate);

    setV8ObjectPropertyAsString(keyframe1, "width", "100px");
    setV8ObjectPropertyAsString(keyframe1, "offset", "0.1");
    setV8ObjectPropertyAsString(keyframe2, "width", "0px");
    setV8ObjectPropertyAsString(keyframe2, "offset", "1");

    jsKeyframes.append(Dictionary(keyframe1, m_isolate));
    jsKeyframes.append(Dictionary(keyframe2, m_isolate));

    createAnimation(element.get(), jsKeyframes, 0, exceptionState);

    EXPECT_TRUE(exceptionState.hadException());
    EXPECT_EQ(NotSupportedError, exceptionState.code());
}

TEST_F(AnimationAnimationV8Test, MissingOffsetOneRaisesException)
{
    Vector<Dictionary> jsKeyframes;
    v8::Handle<v8::Object> keyframe1 = v8::Object::New(m_isolate);
    v8::Handle<v8::Object> keyframe2 = v8::Object::New(m_isolate);

    setV8ObjectPropertyAsString(keyframe1, "width", "100px");
    setV8ObjectPropertyAsString(keyframe1, "offset", "0");
    setV8ObjectPropertyAsString(keyframe2, "width", "0px");
    setV8ObjectPropertyAsString(keyframe2, "offset", "0.1");

    jsKeyframes.append(Dictionary(keyframe1, m_isolate));
    jsKeyframes.append(Dictionary(keyframe2, m_isolate));

    createAnimation(element.get(), jsKeyframes, 0, exceptionState);

    EXPECT_TRUE(exceptionState.hadException());
    EXPECT_EQ(NotSupportedError, exceptionState.code());
}

TEST_F(AnimationAnimationV8Test, MissingOffsetZeroAndOneRaisesException)
{
    Vector<Dictionary> jsKeyframes;
    v8::Handle<v8::Object> keyframe1 = v8::Object::New(m_isolate);
    v8::Handle<v8::Object> keyframe2 = v8::Object::New(m_isolate);

    setV8ObjectPropertyAsString(keyframe1, "width", "100px");
    setV8ObjectPropertyAsString(keyframe1, "offset", "0.1");
    setV8ObjectPropertyAsString(keyframe2, "width", "0px");
    setV8ObjectPropertyAsString(keyframe2, "offset", "0.2");

    jsKeyframes.append(Dictionary(keyframe1, m_isolate));
    jsKeyframes.append(Dictionary(keyframe2, m_isolate));

    createAnimation(element.get(), jsKeyframes, 0, exceptionState);

    EXPECT_TRUE(exceptionState.hadException());
    EXPECT_EQ(NotSupportedError, exceptionState.code());
}

TEST_F(AnimationAnimationV8Test, SpecifiedGetters)
{
    Vector<Dictionary, 0> jsKeyframes;

    v8::Handle<v8::Object> timingInput = v8::Object::New(m_isolate);
    setV8ObjectPropertyAsNumber(timingInput, "delay", 2);
    setV8ObjectPropertyAsNumber(timingInput, "endDelay", 0.5);
    setV8ObjectPropertyAsString(timingInput, "fill", "backwards");
    setV8ObjectPropertyAsNumber(timingInput, "iterationStart", 2);
    setV8ObjectPropertyAsNumber(timingInput, "iterations", 10);
    setV8ObjectPropertyAsNumber(timingInput, "playbackRate", 2);
    setV8ObjectPropertyAsString(timingInput, "direction", "reverse");
    setV8ObjectPropertyAsString(timingInput, "easing", "step-start");
    Dictionary timingInputDictionary = Dictionary(v8::Handle<v8::Value>::Cast(timingInput), m_isolate);

    RefPtrWillBeRawPtr<Animation> animation = createAnimation(element.get(), jsKeyframes, timingInputDictionary, exceptionState);

    RefPtrWillBeRawPtr<AnimationNodeTiming> specified = animation->timing();
    EXPECT_EQ(2, specified->delay());
    EXPECT_EQ(0.5, specified->endDelay());
    EXPECT_EQ("backwards", specified->fill());
    EXPECT_EQ(2, specified->iterationStart());
    EXPECT_EQ(10, specified->iterations());
    EXPECT_EQ(2, specified->playbackRate());
    EXPECT_EQ("reverse", specified->direction());
    EXPECT_EQ("step-start", specified->easing());
}

TEST_F(AnimationAnimationV8Test, SpecifiedDurationGetter)
{
    Vector<Dictionary, 0> jsKeyframes;

    v8::Handle<v8::Object> timingInputWithDuration = v8::Object::New(m_isolate);
    setV8ObjectPropertyAsNumber(timingInputWithDuration, "duration", 2.5);
    Dictionary timingInputDictionaryWithDuration = Dictionary(v8::Handle<v8::Value>::Cast(timingInputWithDuration), m_isolate);

    RefPtrWillBeRawPtr<Animation> animationWithDuration = createAnimation(element.get(), jsKeyframes, timingInputDictionaryWithDuration, exceptionState);

    RefPtrWillBeRawPtr<AnimationNodeTiming> specifiedWithDuration = animationWithDuration->timing();
    Nullable<double> numberDuration;
    String stringDuration;
    specifiedWithDuration->getDuration("duration", numberDuration, stringDuration);
    EXPECT_FALSE(numberDuration.isNull());
    EXPECT_EQ(2.5, numberDuration.get());
    EXPECT_TRUE(stringDuration.isNull());


    v8::Handle<v8::Object> timingInputNoDuration = v8::Object::New(m_isolate);
    Dictionary timingInputDictionaryNoDuration = Dictionary(v8::Handle<v8::Value>::Cast(timingInputNoDuration), m_isolate);

    RefPtrWillBeRawPtr<Animation> animationNoDuration = createAnimation(element.get(), jsKeyframes, timingInputDictionaryNoDuration, exceptionState);

    RefPtrWillBeRawPtr<AnimationNodeTiming> specifiedNoDuration = animationNoDuration->timing();
    Nullable<double> numberDuration2;
    String stringDuration2;
    specifiedNoDuration->getDuration("duration", numberDuration2, stringDuration2);
    EXPECT_TRUE(numberDuration2.isNull());
    EXPECT_FALSE(stringDuration2.isNull());
    EXPECT_EQ("auto", stringDuration2);
}

TEST_F(AnimationAnimationV8Test, SpecifiedSetters)
{
    Vector<Dictionary, 0> jsKeyframes;
    v8::Handle<v8::Object> timingInput = v8::Object::New(m_isolate);
    Dictionary timingInputDictionary = Dictionary(v8::Handle<v8::Value>::Cast(timingInput), m_isolate);
    RefPtrWillBeRawPtr<Animation> animation = createAnimation(element.get(), jsKeyframes, timingInputDictionary, exceptionState);

    RefPtrWillBeRawPtr<AnimationNodeTiming> specified = animation->timing();

    EXPECT_EQ(0, specified->delay());
    specified->setDelay(2);
    EXPECT_EQ(2, specified->delay());

    EXPECT_EQ(0, specified->endDelay());
    specified->setEndDelay(0.5);
    EXPECT_EQ(0.5, specified->endDelay());

    EXPECT_EQ("auto", specified->fill());
    specified->setFill("backwards");
    EXPECT_EQ("backwards", specified->fill());

    EXPECT_EQ(0, specified->iterationStart());
    specified->setIterationStart(2);
    EXPECT_EQ(2, specified->iterationStart());

    EXPECT_EQ(1, specified->iterations());
    specified->setIterations(10);
    EXPECT_EQ(10, specified->iterations());

    EXPECT_EQ(1, specified->playbackRate());
    specified->setPlaybackRate(2);
    EXPECT_EQ(2, specified->playbackRate());

    EXPECT_EQ("normal", specified->direction());
    specified->setDirection("reverse");
    EXPECT_EQ("reverse", specified->direction());

    EXPECT_EQ("linear", specified->easing());
    specified->setEasing("step-start");
    EXPECT_EQ("step-start", specified->easing());
}

TEST_F(AnimationAnimationV8Test, SetSpecifiedDuration)
{
    Vector<Dictionary, 0> jsKeyframes;
    v8::Handle<v8::Object> timingInput = v8::Object::New(m_isolate);
    Dictionary timingInputDictionary = Dictionary(v8::Handle<v8::Value>::Cast(timingInput), m_isolate);
    RefPtrWillBeRawPtr<Animation> animation = createAnimation(element.get(), jsKeyframes, timingInputDictionary, exceptionState);

    RefPtrWillBeRawPtr<AnimationNodeTiming> specified = animation->timing();

    Nullable<double> numberDuration;
    String stringDuration;
    specified->getDuration("duration", numberDuration, stringDuration);
    EXPECT_TRUE(numberDuration.isNull());
    EXPECT_FALSE(stringDuration.isNull());
    EXPECT_EQ("auto", stringDuration);

    specified->setDuration("duration", 2.5);
    Nullable<double> numberDuration2;
    String stringDuration2;
    specified->getDuration("duration", numberDuration2, stringDuration2);
    EXPECT_FALSE(numberDuration2.isNull());
    EXPECT_EQ(2.5, numberDuration2.get());
    EXPECT_TRUE(stringDuration2.isNull());
}

TEST_F(AnimationAnimationTest, TimeToEffectChange)
{
    Timing timing;
    timing.iterationDuration = 100;
    timing.startDelay = 100;
    timing.endDelay = 100;
    timing.fillMode = Timing::FillModeNone;
    RefPtrWillBeRawPtr<Animation> animation = Animation::create(0, nullptr, timing);
    RefPtrWillBeRawPtr<AnimationPlayer> player = document.timeline().play(animation.get());
    double inf = std::numeric_limits<double>::infinity();

    EXPECT_EQ(100, animation->timeToForwardsEffectChange());
    EXPECT_EQ(inf, animation->timeToReverseEffectChange());

    player->setCurrentTimeInternal(100);
    EXPECT_EQ(0, animation->timeToForwardsEffectChange());
    EXPECT_EQ(0, animation->timeToReverseEffectChange());

    player->setCurrentTimeInternal(199);
    EXPECT_EQ(0, animation->timeToForwardsEffectChange());
    EXPECT_EQ(0, animation->timeToReverseEffectChange());

    player->setCurrentTimeInternal(200);
    // End-exclusive.
    EXPECT_EQ(inf, animation->timeToForwardsEffectChange());
    EXPECT_EQ(0, animation->timeToReverseEffectChange());

    player->setCurrentTimeInternal(300);
    EXPECT_EQ(inf, animation->timeToForwardsEffectChange());
    EXPECT_EQ(100, animation->timeToReverseEffectChange());
}

TEST_F(AnimationAnimationTest, TimeToEffectChangeWithPlaybackRate)
{
    Timing timing;
    timing.iterationDuration = 100;
    timing.startDelay = 100;
    timing.endDelay = 100;
    timing.playbackRate = 2;
    timing.fillMode = Timing::FillModeNone;
    RefPtrWillBeRawPtr<Animation> animation = Animation::create(0, nullptr, timing);
    RefPtrWillBeRawPtr<AnimationPlayer> player = document.timeline().play(animation.get());
    double inf = std::numeric_limits<double>::infinity();

    EXPECT_EQ(100, animation->timeToForwardsEffectChange());
    EXPECT_EQ(inf, animation->timeToReverseEffectChange());

    player->setCurrentTimeInternal(100);
    EXPECT_EQ(0, animation->timeToForwardsEffectChange());
    EXPECT_EQ(0, animation->timeToReverseEffectChange());

    player->setCurrentTimeInternal(149);
    EXPECT_EQ(0, animation->timeToForwardsEffectChange());
    EXPECT_EQ(0, animation->timeToReverseEffectChange());

    player->setCurrentTimeInternal(150);
    // End-exclusive.
    EXPECT_EQ(inf, animation->timeToForwardsEffectChange());
    EXPECT_EQ(0, animation->timeToReverseEffectChange());

    player->setCurrentTimeInternal(200);
    EXPECT_EQ(inf, animation->timeToForwardsEffectChange());
    EXPECT_EQ(50, animation->timeToReverseEffectChange());
}

TEST_F(AnimationAnimationTest, TimeToEffectChangeWithNegativePlaybackRate)
{
    Timing timing;
    timing.iterationDuration = 100;
    timing.startDelay = 100;
    timing.endDelay = 100;
    timing.playbackRate = -2;
    timing.fillMode = Timing::FillModeNone;
    RefPtrWillBeRawPtr<Animation> animation = Animation::create(0, nullptr, timing);
    RefPtrWillBeRawPtr<AnimationPlayer> player = document.timeline().play(animation.get());
    double inf = std::numeric_limits<double>::infinity();

    EXPECT_EQ(100, animation->timeToForwardsEffectChange());
    EXPECT_EQ(inf, animation->timeToReverseEffectChange());

    player->setCurrentTimeInternal(100);
    EXPECT_EQ(0, animation->timeToForwardsEffectChange());
    EXPECT_EQ(0, animation->timeToReverseEffectChange());

    player->setCurrentTimeInternal(149);
    EXPECT_EQ(0, animation->timeToForwardsEffectChange());
    EXPECT_EQ(0, animation->timeToReverseEffectChange());

    player->setCurrentTimeInternal(150);
    EXPECT_EQ(inf, animation->timeToForwardsEffectChange());
    EXPECT_EQ(0, animation->timeToReverseEffectChange());

    player->setCurrentTimeInternal(200);
    EXPECT_EQ(inf, animation->timeToForwardsEffectChange());
    EXPECT_EQ(50, animation->timeToReverseEffectChange());
}

TEST_F(AnimationAnimationTest, ElementDestructorClearsAnimationTarget)
{
    // This test expects incorrect behaviour should be removed once Element
    // and Animation are moved to Oilpan. See crbug.com/362404 for context.
    Timing timing;
    timing.iterationDuration = 5;
    RefPtrWillBeRawPtr<Animation> animation = Animation::create(element.get(), nullptr, timing);
    EXPECT_EQ(element.get(), animation->target());
    document.timeline().play(animation.get());
    pageHolder.clear();
    element.clear();
#if !ENABLE(OILPAN)
    EXPECT_EQ(0, animation->target());
#endif
}

} // namespace blink
