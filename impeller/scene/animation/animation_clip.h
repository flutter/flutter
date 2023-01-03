// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/scene/animation/animation.h"

namespace impeller {
namespace scene {

class Node;
class AnimationPlayer;

class AnimationClip final {
 public:
  AnimationClip(std::shared_ptr<Animation> animation, Node* bind_target);
  ~AnimationClip();

  AnimationClip(AnimationClip&&);
  AnimationClip& operator=(AnimationClip&&);

  bool IsPlaying() const;

  void SetPlaying(bool playing);

  void Play();

  void Pause();

  void Stop();

  bool GetLoop() const;

  void SetLoop(bool looping);

  Scalar GetPlaybackTimeScale() const;

  /// @brief  Sets the animation playback speed. Negative values make the clip
  ///         play in reverse.
  void SetPlaybackTimeScale(Scalar playback_speed);

  Scalar GetWeight() const;

  void SetWeight(Scalar weight);

  /// @brief  Get the current playback time of the animation.
  Scalar GetPlaybackTime() const;

  /// @brief  Move the animation to the specified time. The given `time` is
  ///         clamped to the animation's playback range.
  void Seek(Scalar time);

  /// @brief  Advance the animation by `delta_time` seconds. Negative
  ///         `delta_time` values do nothing.
  void Advance(Scalar delta_time);

  /// @brief  Applies the animation to all binded properties in the scene.
  void ApplyToBindings() const;

 private:
  void BindToTarget(Node* node);

  struct ChannelBinding {
    const Animation::Channel& channel;
    Node* node;
  };

  std::shared_ptr<Animation> animation_;
  std::vector<ChannelBinding> bindings_;

  Scalar playback_time_ = 0;
  Scalar playback_time_scale_ = 1;  // Seconds multiplier, can be negative.
  Scalar weight_ = 1;
  bool playing_ = false;
  bool loop_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(AnimationClip);

  friend AnimationPlayer;
};

}  // namespace scene
}  // namespace impeller
