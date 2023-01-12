// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/animation/animation_player.h"

#include <memory>
#include <unordered_map>

#include "flutter/fml/time/time_point.h"
#include "impeller/base/timing.h"
#include "impeller/scene/node.h"

namespace impeller {
namespace scene {

AnimationPlayer::AnimationPlayer() = default;
AnimationPlayer::~AnimationPlayer() = default;

AnimationPlayer::AnimationPlayer(AnimationPlayer&&) = default;
AnimationPlayer& AnimationPlayer::operator=(AnimationPlayer&&) = default;

AnimationClip* AnimationPlayer::AddAnimation(
    const std::shared_ptr<Animation>& animation,
    Node* bind_target) {
  if (!animation) {
    VALIDATION_LOG << "Cannot add null animation.";
    return nullptr;
  }

  AnimationClip clip(animation, bind_target);

  // Record all of the unique default transforms that this AnimationClip
  // will mutate.
  for (const auto& binding : clip.bindings_) {
    auto decomp = binding.node->GetLocalTransform().Decompose();
    if (!decomp.has_value()) {
      continue;
    }
    target_transforms_.insert(
        {binding.node, AnimationTransforms{.bind_pose = decomp.value()}});
  }

  auto result = clips_.insert({animation->GetName(), std::move(clip)});
  return &result.first->second;
}

AnimationClip* AnimationPlayer::GetClip(const std::string& name) const {
  auto result = clips_.find(name);
  if (result == clips_.end()) {
    return nullptr;
  }
  return const_cast<AnimationClip*>(&result->second);
}

void AnimationPlayer::Update() {
  if (!previous_time_.has_value()) {
    previous_time_ = Clock::now();
  }
  auto new_time = Clock::now();
  auto delta_time = new_time - previous_time_.value();
  previous_time_ = new_time;

  // Reset the animated pose state.
  for (auto& [node, transforms] : target_transforms_) {
    transforms.animated_pose = transforms.bind_pose;
  }

  // Compute a weight multiplier for normalizing the animation.
  Scalar total_weight = 0;
  for (auto& [_, clip] : clips_) {
    total_weight += clip.GetWeight();
  }
  Scalar weight_multiplier = total_weight > 1 ? 1 / total_weight : 1;

  // Update and apply all clips to the animation pose state.
  for (auto& [_, clip] : clips_) {
    clip.Advance(delta_time);
    clip.ApplyToBindings(target_transforms_, weight_multiplier);
  }

  // Apply the animated pose to the bound joints.
  for (auto& [node, transforms] : target_transforms_) {
    node->SetLocalTransform(Matrix(transforms.animated_pose));
  }
}

}  // namespace scene
}  // namespace impeller
