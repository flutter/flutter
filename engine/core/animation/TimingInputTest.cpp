// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/animation/TimingInput.h"

#include "bindings/core/v8/Dictionary.h"
#include "core/animation/AnimationNodeTiming.h"
#include "core/animation/AnimationTestHelper.h"
#include <gtest/gtest.h>
#include <v8.h>

namespace blink {

class AnimationTimingInputTest : public ::testing::Test {
protected:
    AnimationTimingInputTest()
        : m_isolate(v8::Isolate::GetCurrent())
        , m_scope(m_isolate)
    {
    }

    Timing applyTimingInputNumber(String timingProperty, double timingPropertyValue)
    {
        v8::Handle<v8::Object> timingInput = v8::Object::New(m_isolate);
        setV8ObjectPropertyAsNumber(timingInput, timingProperty, timingPropertyValue);
        Dictionary timingInputDictionary = Dictionary(v8::Handle<v8::Value>::Cast(timingInput), m_isolate);
        return TimingInput::convert(timingInputDictionary);
    }

    Timing applyTimingInputString(String timingProperty, String timingPropertyValue)
    {
        v8::Handle<v8::Object> timingInput = v8::Object::New(m_isolate);
        setV8ObjectPropertyAsString(timingInput, timingProperty, timingPropertyValue);
        Dictionary timingInputDictionary = Dictionary(v8::Handle<v8::Value>::Cast(timingInput), m_isolate);
        return TimingInput::convert(timingInputDictionary);
    }

    v8::Isolate* m_isolate;

private:
    V8TestingScope m_scope;
};

TEST_F(AnimationTimingInputTest, TimingInputStartDelay)
{
    EXPECT_EQ(1.1, applyTimingInputNumber("delay", 1100).startDelay);
    EXPECT_EQ(-1, applyTimingInputNumber("delay", -1000).startDelay);
    EXPECT_EQ(1, applyTimingInputString("delay", "1000").startDelay);
    EXPECT_EQ(0, applyTimingInputString("delay", "1s").startDelay);
    EXPECT_EQ(0, applyTimingInputString("delay", "Infinity").startDelay);
    EXPECT_EQ(0, applyTimingInputString("delay", "-Infinity").startDelay);
    EXPECT_EQ(0, applyTimingInputString("delay", "NaN").startDelay);
    EXPECT_EQ(0, applyTimingInputString("delay", "rubbish").startDelay);
}

TEST_F(AnimationTimingInputTest, TimingInputEndDelay)
{
    EXPECT_EQ(10, applyTimingInputNumber("endDelay", 10000).endDelay);
    EXPECT_EQ(-2.5, applyTimingInputNumber("endDelay", -2500).endDelay);
}

TEST_F(AnimationTimingInputTest, TimingInputFillMode)
{
    Timing::FillMode defaultFillMode = Timing::FillModeAuto;

    EXPECT_EQ(Timing::FillModeAuto, applyTimingInputString("fill", "auto").fillMode);
    EXPECT_EQ(Timing::FillModeForwards, applyTimingInputString("fill", "forwards").fillMode);
    EXPECT_EQ(Timing::FillModeNone, applyTimingInputString("fill", "none").fillMode);
    EXPECT_EQ(Timing::FillModeBackwards, applyTimingInputString("fill", "backwards").fillMode);
    EXPECT_EQ(Timing::FillModeBoth, applyTimingInputString("fill", "both").fillMode);
    EXPECT_EQ(defaultFillMode, applyTimingInputString("fill", "everything!").fillMode);
    EXPECT_EQ(defaultFillMode, applyTimingInputString("fill", "backwardsandforwards").fillMode);
    EXPECT_EQ(defaultFillMode, applyTimingInputNumber("fill", 2).fillMode);
}

TEST_F(AnimationTimingInputTest, TimingInputIterationStart)
{
    EXPECT_EQ(1.1, applyTimingInputNumber("iterationStart", 1.1).iterationStart);
    EXPECT_EQ(0, applyTimingInputNumber("iterationStart", -1).iterationStart);
    EXPECT_EQ(0, applyTimingInputString("iterationStart", "Infinity").iterationStart);
    EXPECT_EQ(0, applyTimingInputString("iterationStart", "-Infinity").iterationStart);
    EXPECT_EQ(0, applyTimingInputString("iterationStart", "NaN").iterationStart);
    EXPECT_EQ(0, applyTimingInputString("iterationStart", "rubbish").iterationStart);
}

TEST_F(AnimationTimingInputTest, TimingInputIterationCount)
{
    EXPECT_EQ(2.1, applyTimingInputNumber("iterations", 2.1).iterationCount);
    EXPECT_EQ(0, applyTimingInputNumber("iterations", -1).iterationCount);

    Timing timing = applyTimingInputString("iterations", "Infinity");
    EXPECT_TRUE(std::isinf(timing.iterationCount));
    EXPECT_GT(timing.iterationCount, 0);

    EXPECT_EQ(0, applyTimingInputString("iterations", "-Infinity").iterationCount);
    EXPECT_EQ(1, applyTimingInputString("iterations", "NaN").iterationCount);
    EXPECT_EQ(1, applyTimingInputString("iterations", "rubbish").iterationCount);
}

TEST_F(AnimationTimingInputTest, TimingInputIterationDuration)
{
    EXPECT_EQ(1.1, applyTimingInputNumber("duration", 1100).iterationDuration);
    EXPECT_TRUE(std::isnan(applyTimingInputNumber("duration", -1000).iterationDuration));
    EXPECT_EQ(1, applyTimingInputString("duration", "1000").iterationDuration);

    Timing timing = applyTimingInputString("duration", "Infinity");
    EXPECT_TRUE(std::isinf(timing.iterationDuration));
    EXPECT_GT(timing.iterationDuration, 0);

    EXPECT_TRUE(std::isnan(applyTimingInputString("duration", "-Infinity").iterationDuration));
    EXPECT_TRUE(std::isnan(applyTimingInputString("duration", "NaN").iterationDuration));
    EXPECT_TRUE(std::isnan(applyTimingInputString("duration", "auto").iterationDuration));
    EXPECT_TRUE(std::isnan(applyTimingInputString("duration", "rubbish").iterationDuration));
}

TEST_F(AnimationTimingInputTest, TimingInputPlaybackRate)
{
    EXPECT_EQ(2.1, applyTimingInputNumber("playbackRate", 2.1).playbackRate);
    EXPECT_EQ(-1, applyTimingInputNumber("playbackRate", -1).playbackRate);
    EXPECT_EQ(1, applyTimingInputString("playbackRate", "Infinity").playbackRate);
    EXPECT_EQ(1, applyTimingInputString("playbackRate", "-Infinity").playbackRate);
    EXPECT_EQ(1, applyTimingInputString("playbackRate", "NaN").playbackRate);
    EXPECT_EQ(1, applyTimingInputString("playbackRate", "rubbish").playbackRate);
}

TEST_F(AnimationTimingInputTest, TimingInputDirection)
{
    Timing::PlaybackDirection defaultPlaybackDirection = Timing::PlaybackDirectionNormal;

    EXPECT_EQ(Timing::PlaybackDirectionNormal, applyTimingInputString("direction", "normal").direction);
    EXPECT_EQ(Timing::PlaybackDirectionReverse, applyTimingInputString("direction", "reverse").direction);
    EXPECT_EQ(Timing::PlaybackDirectionAlternate, applyTimingInputString("direction", "alternate").direction);
    EXPECT_EQ(Timing::PlaybackDirectionAlternateReverse, applyTimingInputString("direction", "alternate-reverse").direction);
    EXPECT_EQ(defaultPlaybackDirection, applyTimingInputString("direction", "rubbish").direction);
    EXPECT_EQ(defaultPlaybackDirection, applyTimingInputNumber("direction", 2).direction);
}

TEST_F(AnimationTimingInputTest, TimingInputTimingFunction)
{
    const RefPtr<TimingFunction> defaultTimingFunction = LinearTimingFunction::shared();

    EXPECT_EQ(*CubicBezierTimingFunction::preset(CubicBezierTimingFunction::Ease), *applyTimingInputString("easing", "ease").timingFunction);
    EXPECT_EQ(*CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseIn), *applyTimingInputString("easing", "ease-in").timingFunction);
    EXPECT_EQ(*CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseOut), *applyTimingInputString("easing", "ease-out").timingFunction);
    EXPECT_EQ(*CubicBezierTimingFunction::preset(CubicBezierTimingFunction::EaseInOut), *applyTimingInputString("easing", "ease-in-out").timingFunction);
    EXPECT_EQ(*LinearTimingFunction::shared(), *applyTimingInputString("easing", "linear").timingFunction);
    EXPECT_EQ(*StepsTimingFunction::preset(StepsTimingFunction::Start), *applyTimingInputString("easing", "step-start").timingFunction);
    EXPECT_EQ(*StepsTimingFunction::preset(StepsTimingFunction::Middle), *applyTimingInputString("easing", "step-middle").timingFunction);
    EXPECT_EQ(*StepsTimingFunction::preset(StepsTimingFunction::End), *applyTimingInputString("easing", "step-end").timingFunction);
    EXPECT_EQ(*CubicBezierTimingFunction::create(1, 1, 0.3, 0.3), *applyTimingInputString("easing", "cubic-bezier(1, 1, 0.3, 0.3)").timingFunction);
    EXPECT_EQ(*StepsTimingFunction::create(3, StepsTimingFunction::StepAtStart), *applyTimingInputString("easing", "steps(3, start)").timingFunction);
    EXPECT_EQ(*StepsTimingFunction::create(5, StepsTimingFunction::StepAtMiddle), *applyTimingInputString("easing", "steps(5, middle)").timingFunction);
    EXPECT_EQ(*StepsTimingFunction::create(5, StepsTimingFunction::StepAtEnd), *applyTimingInputString("easing", "steps(5, end)").timingFunction);
    EXPECT_EQ(*defaultTimingFunction, *applyTimingInputString("easing", "steps(5.6, end)").timingFunction);
    EXPECT_EQ(*defaultTimingFunction, *applyTimingInputString("easing", "cubic-bezier(2, 2, 0.3, 0.3)").timingFunction);
    EXPECT_EQ(*defaultTimingFunction, *applyTimingInputString("easing", "rubbish").timingFunction);
    EXPECT_EQ(*defaultTimingFunction, *applyTimingInputNumber("easing", 2).timingFunction);
    EXPECT_EQ(*defaultTimingFunction, *applyTimingInputString("easing", "initial").timingFunction);
}

TEST_F(AnimationTimingInputTest, TimingInputEmpty)
{
    Timing controlTiming;

    v8::Handle<v8::Object> timingInput = v8::Object::New(m_isolate);
    Dictionary timingInputDictionary = Dictionary(v8::Handle<v8::Value>::Cast(timingInput), m_isolate);
    Timing updatedTiming = TimingInput::convert(timingInputDictionary);

    EXPECT_EQ(controlTiming.startDelay, updatedTiming.startDelay);
    EXPECT_EQ(controlTiming.fillMode, updatedTiming.fillMode);
    EXPECT_EQ(controlTiming.iterationStart, updatedTiming.iterationStart);
    EXPECT_EQ(controlTiming.iterationCount, updatedTiming.iterationCount);
    EXPECT_TRUE(std::isnan(updatedTiming.iterationDuration));
    EXPECT_EQ(controlTiming.playbackRate, updatedTiming.playbackRate);
    EXPECT_EQ(controlTiming.direction, updatedTiming.direction);
    EXPECT_EQ(*controlTiming.timingFunction, *updatedTiming.timingFunction);
}

} // namespace blink
