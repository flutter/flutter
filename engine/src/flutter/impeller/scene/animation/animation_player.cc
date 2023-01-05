// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/animation/animation_player.h"

#include <memory>

#include "flutter/fml/time/time_point.h"
#include "impeller/base/timing.h"
#include "impeller/scene/node.h"

namespace impeller {
namespace scene {

AnimationPlayer::AnimationPlayer() = default;
AnimationPlayer::~AnimationPlayer() = default;

AnimationPlayer::AnimationPlayer(AnimationPlayer&&) = default;
AnimationPlayer& AnimationPlayer::operator=(AnimationPlayer&&) = default;

AnimationClip& AnimationPlayer::AddAnimation(
    std::shared_ptr<Animation> animation,
    Node* bind_target) {
  AnimationClip clip(std::move(animation), bind_target);

  // Record all of the unique default transforms that this AnimationClip
  // will mutate.
  for (const auto& binding : clip.bindings_) {
    default_target_transforms_.insert(
        {binding.node, binding.node->GetLocalTransform()});
  }

  clips_.push_back(std::move(clip));
  return clips_.back();
}

void AnimationPlayer::Update() {
  if (!previous_time_.has_value()) {
    previous_time_ = Clock::now();
  }
  auto new_time = Clock::now();
  auto delta_time = new_time - previous_time_.value();
  previous_time_ = new_time;

  Reset();

  // Update and apply all clips.
  for (auto& clip : clips_) {
    clip.Advance(delta_time);
    clip.ApplyToBindings();
  }
}

void AnimationPlayer::Reset() {
  for (auto& [node, transform] : default_target_transforms_) {
    node->SetLocalTransform(Matrix());
  }
}

}  // namespace scene
}  // namespace impeller
