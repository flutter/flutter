// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/memory/scoped_ptr.h"
#include "cc/animation/timing_function.h"
#include "sky/viewer/cc/web_float_animation_curve_impl.h"
#include "testing/gtest/include/gtest/gtest.h"

using blink::WebCompositorAnimationCurve;
using blink::WebFloatAnimationCurve;
using blink::WebFloatKeyframe;

namespace sky_viewer_cc {
namespace {

// Tests that a float animation with one keyframe works as expected.
TEST(WebFloatAnimationCurveTest, OneFloatKeyframe) {
  scoped_ptr<WebFloatAnimationCurve> curve(new WebFloatAnimationCurveImpl);
  curve->add(WebFloatKeyframe(0, 2),
             WebCompositorAnimationCurve::TimingFunctionTypeLinear);
  EXPECT_FLOAT_EQ(2, curve->getValue(-1));
  EXPECT_FLOAT_EQ(2, curve->getValue(0));
  EXPECT_FLOAT_EQ(2, curve->getValue(0.5));
  EXPECT_FLOAT_EQ(2, curve->getValue(1));
  EXPECT_FLOAT_EQ(2, curve->getValue(2));
}

// Tests that a float animation with two keyframes works as expected.
TEST(WebFloatAnimationCurveTest, TwoFloatKeyframe) {
  scoped_ptr<WebFloatAnimationCurve> curve(new WebFloatAnimationCurveImpl);
  curve->add(WebFloatKeyframe(0, 2),
             WebCompositorAnimationCurve::TimingFunctionTypeLinear);
  curve->add(WebFloatKeyframe(1, 4),
             WebCompositorAnimationCurve::TimingFunctionTypeLinear);
  EXPECT_FLOAT_EQ(2, curve->getValue(-1));
  EXPECT_FLOAT_EQ(2, curve->getValue(0));
  EXPECT_FLOAT_EQ(3, curve->getValue(0.5));
  EXPECT_FLOAT_EQ(4, curve->getValue(1));
  EXPECT_FLOAT_EQ(4, curve->getValue(2));
}

// Tests that a float animation with three keyframes works as expected.
TEST(WebFloatAnimationCurveTest, ThreeFloatKeyframe) {
  scoped_ptr<WebFloatAnimationCurve> curve(new WebFloatAnimationCurveImpl);
  curve->add(WebFloatKeyframe(0, 2),
             WebCompositorAnimationCurve::TimingFunctionTypeLinear);
  curve->add(WebFloatKeyframe(1, 4),
             WebCompositorAnimationCurve::TimingFunctionTypeLinear);
  curve->add(WebFloatKeyframe(2, 8),
             WebCompositorAnimationCurve::TimingFunctionTypeLinear);
  EXPECT_FLOAT_EQ(2, curve->getValue(-1));
  EXPECT_FLOAT_EQ(2, curve->getValue(0));
  EXPECT_FLOAT_EQ(3, curve->getValue(0.5));
  EXPECT_FLOAT_EQ(4, curve->getValue(1));
  EXPECT_FLOAT_EQ(6, curve->getValue(1.5));
  EXPECT_FLOAT_EQ(8, curve->getValue(2));
  EXPECT_FLOAT_EQ(8, curve->getValue(3));
}

// Tests that a float animation with multiple keys at a given time works sanely.
TEST(WebFloatAnimationCurveTest, RepeatedFloatKeyTimes) {
  scoped_ptr<WebFloatAnimationCurve> curve(new WebFloatAnimationCurveImpl);
  curve->add(WebFloatKeyframe(0, 4),
             WebCompositorAnimationCurve::TimingFunctionTypeLinear);
  curve->add(WebFloatKeyframe(1, 4),
             WebCompositorAnimationCurve::TimingFunctionTypeLinear);
  curve->add(WebFloatKeyframe(1, 6),
             WebCompositorAnimationCurve::TimingFunctionTypeLinear);
  curve->add(WebFloatKeyframe(2, 6),
             WebCompositorAnimationCurve::TimingFunctionTypeLinear);

  EXPECT_FLOAT_EQ(4, curve->getValue(-1));
  EXPECT_FLOAT_EQ(4, curve->getValue(0));
  EXPECT_FLOAT_EQ(4, curve->getValue(0.5));

  // There is a discontinuity at 1. Any value between 4 and 6 is valid.
  float value = curve->getValue(1);
  EXPECT_TRUE(value >= 4 && value <= 6);

  EXPECT_FLOAT_EQ(6, curve->getValue(1.5));
  EXPECT_FLOAT_EQ(6, curve->getValue(2));
  EXPECT_FLOAT_EQ(6, curve->getValue(3));
}

// Tests that the keyframes may be added out of order.
TEST(WebFloatAnimationCurveTest, UnsortedKeyframes) {
  scoped_ptr<WebFloatAnimationCurve> curve(new WebFloatAnimationCurveImpl);
  curve->add(WebFloatKeyframe(2, 8),
             WebCompositorAnimationCurve::TimingFunctionTypeLinear);
  curve->add(WebFloatKeyframe(0, 2),
             WebCompositorAnimationCurve::TimingFunctionTypeLinear);
  curve->add(WebFloatKeyframe(1, 4),
             WebCompositorAnimationCurve::TimingFunctionTypeLinear);

  EXPECT_FLOAT_EQ(2, curve->getValue(-1));
  EXPECT_FLOAT_EQ(2, curve->getValue(0));
  EXPECT_FLOAT_EQ(3, curve->getValue(0.5));
  EXPECT_FLOAT_EQ(4, curve->getValue(1));
  EXPECT_FLOAT_EQ(6, curve->getValue(1.5));
  EXPECT_FLOAT_EQ(8, curve->getValue(2));
  EXPECT_FLOAT_EQ(8, curve->getValue(3));
}

// Tests that a cubic bezier timing function works as expected.
TEST(WebFloatAnimationCurveTest, CubicBezierTimingFunction) {
  scoped_ptr<WebFloatAnimationCurve> curve(new WebFloatAnimationCurveImpl);
  curve->add(WebFloatKeyframe(0, 0), 0.25, 0, 0.75, 1);
  curve->add(WebFloatKeyframe(1, 1),
             WebCompositorAnimationCurve::TimingFunctionTypeLinear);

  EXPECT_FLOAT_EQ(0, curve->getValue(0));
  EXPECT_LT(0, curve->getValue(0.25));
  EXPECT_GT(0.25, curve->getValue(0.25));
  EXPECT_NEAR(curve->getValue(0.5), 0.5, 0.00015);
  EXPECT_LT(0.75, curve->getValue(0.75));
  EXPECT_GT(1, curve->getValue(0.75));
  EXPECT_FLOAT_EQ(1, curve->getValue(1));
}

// Tests that an ease timing function works as expected.
TEST(WebFloatAnimationCurveTest, EaseTimingFunction) {
  scoped_ptr<WebFloatAnimationCurve> curve(new WebFloatAnimationCurveImpl);
  curve->add(WebFloatKeyframe(0, 0),
             WebCompositorAnimationCurve::TimingFunctionTypeEase);
  curve->add(WebFloatKeyframe(1, 1),
             WebCompositorAnimationCurve::TimingFunctionTypeLinear);

  scoped_ptr<cc::TimingFunction> timing_function(
      cc::EaseTimingFunction::Create());
  for (int i = 0; i <= 4; ++i) {
    const double time = i * 0.25;
    EXPECT_FLOAT_EQ(timing_function->GetValue(time), curve->getValue(time));
  }
}

// Tests using a linear timing function.
TEST(WebFloatAnimationCurveTest, LinearTimingFunction) {
  scoped_ptr<WebFloatAnimationCurve> curve(new WebFloatAnimationCurveImpl);
  curve->add(WebFloatKeyframe(0, 0),
             WebCompositorAnimationCurve::TimingFunctionTypeLinear);
  curve->add(WebFloatKeyframe(1, 1),
             WebCompositorAnimationCurve::TimingFunctionTypeLinear);

  for (int i = 0; i <= 4; ++i) {
    const double time = i * 0.25;
    EXPECT_FLOAT_EQ(time, curve->getValue(time));
  }
}

// Tests that an ease in timing function works as expected.
TEST(WebFloatAnimationCurveTest, EaseInTimingFunction) {
  scoped_ptr<WebFloatAnimationCurve> curve(new WebFloatAnimationCurveImpl);
  curve->add(WebFloatKeyframe(0, 0),
             WebCompositorAnimationCurve::TimingFunctionTypeEaseIn);
  curve->add(WebFloatKeyframe(1, 1),
             WebCompositorAnimationCurve::TimingFunctionTypeLinear);

  scoped_ptr<cc::TimingFunction> timing_function(
      cc::EaseInTimingFunction::Create());
  for (int i = 0; i <= 4; ++i) {
    const double time = i * 0.25;
    EXPECT_FLOAT_EQ(timing_function->GetValue(time), curve->getValue(time));
  }
}

// Tests that an ease in timing function works as expected.
TEST(WebFloatAnimationCurveTest, EaseOutTimingFunction) {
  scoped_ptr<WebFloatAnimationCurve> curve(new WebFloatAnimationCurveImpl);
  curve->add(WebFloatKeyframe(0, 0),
             WebCompositorAnimationCurve::TimingFunctionTypeEaseOut);
  curve->add(WebFloatKeyframe(1, 1),
             WebCompositorAnimationCurve::TimingFunctionTypeLinear);

  scoped_ptr<cc::TimingFunction> timing_function(
      cc::EaseOutTimingFunction::Create());
  for (int i = 0; i <= 4; ++i) {
    const double time = i * 0.25;
    EXPECT_FLOAT_EQ(timing_function->GetValue(time), curve->getValue(time));
  }
}

// Tests that an ease in timing function works as expected.
TEST(WebFloatAnimationCurveTest, EaseInOutTimingFunction) {
  scoped_ptr<WebFloatAnimationCurve> curve(new WebFloatAnimationCurveImpl);
  curve->add(WebFloatKeyframe(0, 0),
             WebCompositorAnimationCurve::TimingFunctionTypeEaseInOut);
  curve->add(WebFloatKeyframe(1, 1),
             WebCompositorAnimationCurve::TimingFunctionTypeLinear);

  scoped_ptr<cc::TimingFunction> timing_function(
      cc::EaseInOutTimingFunction::Create());
  for (int i = 0; i <= 4; ++i) {
    const double time = i * 0.25;
    EXPECT_FLOAT_EQ(timing_function->GetValue(time), curve->getValue(time));
  }
}

// Tests that an ease in timing function works as expected.
TEST(WebFloatAnimationCurveTest, CustomBezierTimingFunction) {
  scoped_ptr<WebFloatAnimationCurve> curve(new WebFloatAnimationCurveImpl);
  double x1 = 0.3;
  double y1 = 0.2;
  double x2 = 0.8;
  double y2 = 0.7;
  curve->add(WebFloatKeyframe(0, 0), x1, y1, x2, y2);
  curve->add(WebFloatKeyframe(1, 1),
             WebCompositorAnimationCurve::TimingFunctionTypeLinear);

  scoped_ptr<cc::TimingFunction> timing_function(
      cc::CubicBezierTimingFunction::Create(x1, y1, x2, y2));
  for (int i = 0; i <= 4; ++i) {
    const double time = i * 0.25;
    EXPECT_FLOAT_EQ(timing_function->GetValue(time), curve->getValue(time));
  }
}

// Tests that the default timing function is indeed ease.
TEST(WebFloatAnimationCurveTest, DefaultTimingFunction) {
  scoped_ptr<WebFloatAnimationCurve> curve(new WebFloatAnimationCurveImpl);
  curve->add(WebFloatKeyframe(0, 0));
  curve->add(WebFloatKeyframe(1, 1),
             WebCompositorAnimationCurve::TimingFunctionTypeLinear);

  scoped_ptr<cc::TimingFunction> timing_function(
      cc::EaseTimingFunction::Create());
  for (int i = 0; i <= 4; ++i) {
    const double time = i * 0.25;
    EXPECT_FLOAT_EQ(timing_function->GetValue(time), curve->getValue(time));
  }
}

}  // namespace
}  // namespace sky_viewer_cc
