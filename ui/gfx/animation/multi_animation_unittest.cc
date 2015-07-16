// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/animation/multi_animation.h"

#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gfx/animation/animation_container_element.h"

namespace gfx {

TEST(MultiAnimationTest, Basic) {
  // Create a MultiAnimation with two parts.
  MultiAnimation::Parts parts;
  parts.push_back(MultiAnimation::Part(100, Tween::LINEAR));
  parts.push_back(MultiAnimation::Part(100, Tween::EASE_OUT));

  MultiAnimation animation(parts, MultiAnimation::GetDefaultTimerInterval());
  AnimationContainerElement* as_element =
      static_cast<AnimationContainerElement*>(&animation);
  as_element->SetStartTime(base::TimeTicks());

  // Step to 50, which is half way through the first part.
  as_element->Step(base::TimeTicks() + base::TimeDelta::FromMilliseconds(50));
  EXPECT_EQ(.5, animation.GetCurrentValue());

  // Step to 120, which is 20% through the second part.
  as_element->Step(base::TimeTicks() +
                   base::TimeDelta::FromMilliseconds(120));
  EXPECT_DOUBLE_EQ(Tween::CalculateValue(Tween::EASE_OUT, .2),
                   animation.GetCurrentValue());

  // Step to 320, which is 20% through the second part.
  as_element->Step(base::TimeTicks() +
                   base::TimeDelta::FromMilliseconds(320));
  EXPECT_DOUBLE_EQ(Tween::CalculateValue(Tween::EASE_OUT, .2),
                   animation.GetCurrentValue());
}

TEST(MultiAnimationTest, DifferingStartAndEnd) {
  // Create a MultiAnimation with two parts.
  MultiAnimation::Parts parts;
  parts.push_back(MultiAnimation::Part(200, Tween::LINEAR));
  parts[0].start_time_ms = 100;
  parts[0].end_time_ms = 400;

  MultiAnimation animation(parts, MultiAnimation::GetDefaultTimerInterval());
  AnimationContainerElement* as_element =
      static_cast<AnimationContainerElement*>(&animation);
  as_element->SetStartTime(base::TimeTicks());

  // Step to 0. Because the start_time is 100, this should be 100ms into the
  // animation
  as_element->Step(base::TimeTicks());
  EXPECT_EQ(.25, animation.GetCurrentValue());

  // Step to 100, which is effectively 200ms into the animation.
  as_element->Step(base::TimeTicks() + base::TimeDelta::FromMilliseconds(100));
  EXPECT_EQ(.5, animation.GetCurrentValue());
}

// Makes sure multi-animation stops if cycles is false.
TEST(MultiAnimationTest, DontCycle) {
  MultiAnimation::Parts parts;
  parts.push_back(MultiAnimation::Part(200, Tween::LINEAR));
  MultiAnimation animation(parts, MultiAnimation::GetDefaultTimerInterval());
  AnimationContainerElement* as_element =
      static_cast<AnimationContainerElement*>(&animation);
  as_element->SetStartTime(base::TimeTicks());
  animation.set_continuous(false);

  // Step to 300, which is greater than the cycle time.
  as_element->Step(base::TimeTicks() + base::TimeDelta::FromMilliseconds(300));
  EXPECT_EQ(1.0, animation.GetCurrentValue());
  EXPECT_FALSE(animation.is_animating());
}

// Makes sure multi-animation cycles correctly.
TEST(MultiAnimationTest, Cycle) {
  MultiAnimation::Parts parts;
  parts.push_back(MultiAnimation::Part(200, Tween::LINEAR));
  MultiAnimation animation(parts, MultiAnimation::GetDefaultTimerInterval());
  AnimationContainerElement* as_element =
      static_cast<AnimationContainerElement*>(&animation);
  as_element->SetStartTime(base::TimeTicks());

  // Step to 300, which is greater than the cycle time.
  as_element->Step(base::TimeTicks() + base::TimeDelta::FromMilliseconds(300));
  EXPECT_EQ(.5, animation.GetCurrentValue());
}

}  // namespace gfx
