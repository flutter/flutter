// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_ANIMATION_SLIDE_ANIMATION_H_
#define UI_GFX_ANIMATION_SLIDE_ANIMATION_H_

#include "ui/gfx/animation/linear_animation.h"
#include "ui/gfx/animation/tween.h"

namespace gfx {

// Slide Animation
//
// Used for reversible animations and as a general helper class. Typical usage:
//
// #include "ui/gfx/animation/slide_animation.h"
//
// class MyClass : public AnimationDelegate {
//  public:
//   MyClass() {
//     animation_.reset(new SlideAnimation(this));
//     animation_->SetSlideDuration(500);
//   }
//   void OnMouseOver() {
//     animation_->Show();
//   }
//   void OnMouseOut() {
//     animation_->Hide();
//   }
//   void AnimationProgressed(const Animation* animation) {
//     if (animation == animation_.get()) {
//       Layout();
//       SchedulePaint();
//     } else if (animation == other_animation_.get()) {
//       ...
//     }
//   }
//   void Layout() {
//     if (animation_->is_animating()) {
//       hover_image_.SetOpacity(animation_->GetCurrentValue());
//     }
//   }
//  private:
//   scoped_ptr<SlideAnimation> animation_;
// }
class GFX_EXPORT SlideAnimation : public LinearAnimation {
 public:
  explicit SlideAnimation(AnimationDelegate* target);
  ~SlideAnimation() override;

  // Set the animation back to the 0 state.
  virtual void Reset();
  virtual void Reset(double value);

  // Begin a showing animation or reverse a hiding animation in progress.
  virtual void Show();

  // Begin a hiding animation or reverse a showing animation in progress.
  virtual void Hide();

  // Sets the time a slide will take. Note that this isn't actually
  // the amount of time an animation will take as the current value of
  // the slide is considered.
  virtual void SetSlideDuration(int duration);
  int GetSlideDuration() const { return slide_duration_; }
  void SetTweenType(Tween::Type tween_type) { tween_type_ = tween_type; }

  double GetCurrentValue() const override;
  bool IsShowing() const { return showing_; }
  bool IsClosing() const { return !showing_ && value_end_ < value_current_; }

  class TestApi;

 private:
  // Overridden from Animation.
  void AnimateToState(double state) override;

  AnimationDelegate* target_;

  Tween::Type tween_type_;

  // Used to determine which way the animation is going.
  bool showing_;

  // Animation values. These are a layer on top of Animation::state_ to
  // provide the reversability.
  double value_start_;
  double value_end_;
  double value_current_;

  // How long a hover in/out animation will last for. This defaults to
  // kHoverFadeDurationMS, but can be overridden with SetDuration.
  int slide_duration_;

  DISALLOW_COPY_AND_ASSIGN(SlideAnimation);
};

}  // namespace gfx

#endif  // UI_GFX_ANIMATION_SLIDE_ANIMATION_H_
