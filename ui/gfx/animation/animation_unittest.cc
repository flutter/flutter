// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gfx/animation/animation_delegate.h"
#include "ui/gfx/animation/linear_animation.h"
#include "ui/gfx/animation/test_animation_delegate.h"

namespace gfx {

class AnimationTest: public testing::Test {
 private:
  base::MessageLoopForUI message_loop_;
};

namespace {

///////////////////////////////////////////////////////////////////////////////
// RunAnimation

class RunAnimation : public LinearAnimation {
 public:
  RunAnimation(int frame_rate, AnimationDelegate* delegate)
      : LinearAnimation(frame_rate, delegate) {
  }

  void AnimateToState(double state) override {
    EXPECT_LE(0.0, state);
    EXPECT_GE(1.0, state);
  }
};

///////////////////////////////////////////////////////////////////////////////
// CancelAnimation

class CancelAnimation : public LinearAnimation {
 public:
  CancelAnimation(int duration, int frame_rate, AnimationDelegate* delegate)
      : LinearAnimation(duration, frame_rate, delegate) {
  }

  void AnimateToState(double state) override {
    if (state >= 0.5)
      Stop();
  }
};

///////////////////////////////////////////////////////////////////////////////
// EndAnimation

class EndAnimation : public LinearAnimation {
 public:
  EndAnimation(int duration, int frame_rate, AnimationDelegate* delegate)
      : LinearAnimation(duration, frame_rate, delegate) {
  }

  void AnimateToState(double state) override {
    if (state >= 0.5)
      End();
  }
};

///////////////////////////////////////////////////////////////////////////////
// DeletingAnimationDelegate

// AnimationDelegate implementation that deletes the animation in ended.
class DeletingAnimationDelegate : public AnimationDelegate {
 public:
  void AnimationEnded(const Animation* animation) override {
    delete animation;
    base::MessageLoop::current()->Quit();
  }
};

}  // namespace

///////////////////////////////////////////////////////////////////////////////
// LinearCase

TEST_F(AnimationTest, RunCase) {
  TestAnimationDelegate ad;
  RunAnimation a1(150, &ad);
  a1.SetDuration(2000);
  a1.Start();
  base::MessageLoop::current()->Run();

  EXPECT_TRUE(ad.finished());
  EXPECT_FALSE(ad.canceled());
}

TEST_F(AnimationTest, CancelCase) {
  TestAnimationDelegate ad;
  CancelAnimation a2(2000, 150, &ad);
  a2.Start();
  base::MessageLoop::current()->Run();

  EXPECT_TRUE(ad.finished());
  EXPECT_TRUE(ad.canceled());
}

// Lets an animation run, invoking End part way through and make sure we get the
// right delegate methods invoked.
TEST_F(AnimationTest, EndCase) {
  TestAnimationDelegate ad;
  EndAnimation a2(2000, 150, &ad);
  a2.Start();
  base::MessageLoop::current()->Run();

  EXPECT_TRUE(ad.finished());
  EXPECT_FALSE(ad.canceled());
}

// Runs an animation with a delegate that deletes the animation in end.
TEST_F(AnimationTest, DeleteFromEnd) {
  DeletingAnimationDelegate delegate;
  RunAnimation* animation = new RunAnimation(150, &delegate);
  animation->Start();
  base::MessageLoop::current()->Run();
  // delegate should have deleted animation.
}

TEST_F(AnimationTest, ShouldRenderRichAnimation) {
  EXPECT_TRUE(Animation::ShouldRenderRichAnimation());
}

// Test that current value is always 0 after Start() is called.
TEST_F(AnimationTest, StartState) {
  LinearAnimation animation(100, 60, NULL);
  EXPECT_EQ(0.0, animation.GetCurrentValue());
  animation.Start();
  EXPECT_EQ(0.0, animation.GetCurrentValue());
  animation.End();
  EXPECT_EQ(1.0, animation.GetCurrentValue());
  animation.Start();
  EXPECT_EQ(0.0, animation.GetCurrentValue());
}

}  // namespace gfx
