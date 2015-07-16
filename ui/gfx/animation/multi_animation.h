// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_ANIMATION_MULTI_ANIMATION_H_
#define UI_GFX_ANIMATION_MULTI_ANIMATION_H_

#include <vector>

#include "ui/gfx/animation/animation.h"
#include "ui/gfx/animation/tween.h"

namespace gfx {

// MultiAnimation is an animation that consists of a number of sub animations.
// To create a MultiAnimation pass in the parts, invoke Start() and the delegate
// is notified as the animation progresses. By default MultiAnimation runs until
// Stop is invoked, see |set_continuous()| for details.
class GFX_EXPORT MultiAnimation : public Animation {
 public:
  // Defines part of the animation. Each part consists of the following:
  //
  // time_ms: the time of the part.
  // start_time_ms: the amount of time to offset this part by when calculating
  // the percented completed.
  // end_time_ms: the end time used to calculate the percentange completed.
  //
  // In most cases |start_time_ms| = 0 and |end_time_ms| = |time_ms|. But you
  // can adjust the start/end for different effects. For example, to run a part
  // for 200ms with a % between .25 and .75 use the following three values: 200,
  // 100, 400.
  struct Part {
    Part() : time_ms(0), start_time_ms(0), end_time_ms(0), type(Tween::ZERO) {}
    Part(int time_ms, Tween::Type type)
        : time_ms(time_ms),
          start_time_ms(0),
          end_time_ms(time_ms),
          type(type) {}

    int time_ms;
    int start_time_ms;
    int end_time_ms;
    Tween::Type type;
  };

  typedef std::vector<Part> Parts;

  MultiAnimation(const Parts& parts, base::TimeDelta timer_interval);
  ~MultiAnimation() override;

  // Default interval.
  static base::TimeDelta GetDefaultTimerInterval();

  // Sets whether the animation continues after it reaches the end. If true, the
  // animation runs until explicitly stopped. The default is true.
  void set_continuous(bool continuous) { continuous_ = continuous; }

  // Returns the current value. The current value for a MultiAnimation is
  // determined from the tween type of the current part.
  double GetCurrentValue() const override;

  // Returns the index of the current part.
  size_t current_part_index() const { return current_part_index_; }

 protected:
  // Animation overrides.
  void Step(base::TimeTicks time_now) override;
  void SetStartTime(base::TimeTicks start_time) override;

 private:
  // Returns the part containing the specified time. |time_ms| is reset to be
  // relative to the part containing the time and |part_index| the index of the
  // part.
  const Part& GetPart(int* time_ms, size_t* part_index);

  // The parts that make up the animation.
  const Parts parts_;

  // Total time of all the parts.
  const int cycle_time_ms_;

  // Current value for the animation.
  double current_value_;

  // Index of the current part.
  size_t current_part_index_;

  // See description above setter.
  bool continuous_;

  DISALLOW_COPY_AND_ASSIGN(MultiAnimation);
};

}  // namespace gfx

#endif  // UI_GFX_ANIMATION_MULTI_ANIMATION_H_
