// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/memory/scoped_ptr.h"
#include "sky/viewer/cc/web_animation_impl.h"
#include "sky/viewer/cc/web_float_animation_curve_impl.h"
#include "testing/gtest/include/gtest/gtest.h"

using blink::WebCompositorAnimation;
using blink::WebCompositorAnimationCurve;
using blink::WebFloatAnimationCurve;

namespace sky_viewer_cc {
namespace {

TEST(WebCompositorAnimationTest, DefaultSettings) {
  scoped_ptr<WebCompositorAnimationCurve> curve(
      new WebFloatAnimationCurveImpl());
  scoped_ptr<WebCompositorAnimation> animation(new WebCompositorAnimationImpl(
      *curve, WebCompositorAnimation::TargetPropertyOpacity, 1, 0));

  // Ensure that the defaults are correct.
  EXPECT_EQ(1, animation->iterations());
  EXPECT_EQ(0, animation->startTime());
  EXPECT_EQ(0, animation->timeOffset());
#if WEB_ANIMATION_SUPPORTS_FULL_DIRECTION
  EXPECT_EQ(WebCompositorAnimation::DirectionNormal, animation->direction());
#else
  EXPECT_FALSE(animation->alternatesDirection());
#endif
}

TEST(WebCompositorAnimationTest, ModifiedSettings) {
  scoped_ptr<WebFloatAnimationCurve> curve(new WebFloatAnimationCurveImpl());
  scoped_ptr<WebCompositorAnimation> animation(new WebCompositorAnimationImpl(
      *curve, WebCompositorAnimation::TargetPropertyOpacity, 1, 0));
  animation->setIterations(2);
  animation->setStartTime(2);
  animation->setTimeOffset(2);
#if WEB_ANIMATION_SUPPORTS_FULL_DIRECTION
  animation->setDirection(WebCompositorAnimation::DirectionReverse);
#else
  animation->setAlternatesDirection(true);
#endif

  EXPECT_EQ(2, animation->iterations());
  EXPECT_EQ(2, animation->startTime());
  EXPECT_EQ(2, animation->timeOffset());
#if WEB_ANIMATION_SUPPORTS_FULL_DIRECTION
  EXPECT_EQ(WebCompositorAnimation::DirectionReverse, animation->direction());
#else
  EXPECT_TRUE(animation->alternatesDirection());
  animation->setAlternatesDirection(false);
  EXPECT_FALSE(animation->alternatesDirection());
#endif
}

}  // namespace
}  // namespace sky_viewer_cc
