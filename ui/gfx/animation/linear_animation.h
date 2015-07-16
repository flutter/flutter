// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_ANIMATION_LINEAR_ANIMATION_H_
#define UI_GFX_ANIMATION_LINEAR_ANIMATION_H_

#include "base/time/time.h"
#include "ui/gfx/animation/animation.h"

namespace gfx {

class AnimationDelegate;

// Linear time bounded animation. As the animation progresses AnimateToState is
// invoked.
class GFX_EXPORT LinearAnimation : public Animation {
 public:
  // Initializes everything except the duration.
  //
  // Caller must make sure to call SetDuration() if they use this
  // constructor; it is preferable to use the full one, but sometimes
  // duration can change between calls to Start() and we need to
  // expose this interface.
  LinearAnimation(int frame_rate, AnimationDelegate* delegate);

  // Initializes all fields.
  LinearAnimation(int duration, int frame_rate, AnimationDelegate* delegate);

  // Gets the value for the current state, according to the animation curve in
  // use. This class provides only for a linear relationship, however subclasses
  // can override this to provide others.
  double GetCurrentValue() const override;

  // Change the current state of the animation to |new_value|.
  void SetCurrentValue(double new_value);

  // Skip to the end of the current animation.
  void End();

  // Changes the length of the animation. This resets the current
  // state of the animation to the beginning.
  void SetDuration(int duration);

 protected:
  // Called when the animation progresses. Subclasses override this to
  // efficiently update their state.
  virtual void AnimateToState(double state) {}

  // Invoked by the AnimationContainer when the animation is running to advance
  // the animation. Use |time_now| rather than Time::Now to avoid multiple
  // animations running at the same time diverging.
  void Step(base::TimeTicks time_now) override;

  // Overriden to initialize state.
  void AnimationStarted() override;

  // Overriden to advance to the end (if End was invoked).
  void AnimationStopped() override;

  // Overriden to return true if state is not 1.
  bool ShouldSendCanceledFromStop() override;

 private:
  base::TimeDelta duration_;

  // Current state, on a scale from 0.0 to 1.0.
  double state_;

  // If true, we're in end. This is used to determine if the animation should
  // be advanced to the end from AnimationStopped.
  bool in_end_;

  DISALLOW_COPY_AND_ASSIGN(LinearAnimation);
};

}  // namespace gfx

#endif  // APP_LINEAR_ANIMATION_H_
