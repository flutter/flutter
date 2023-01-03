// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/animation/animation.h"

#include <algorithm>
#include <cstring>
#include <memory>
#include <vector>

#include "impeller/geometry/quaternion.h"
#include "impeller/scene/importer/scene_flatbuffers.h"
#include "impeller/scene/node.h"

namespace impeller {
namespace scene {

std::shared_ptr<Animation> Animation::MakeFromFlatbuffer(
    const fb::Animation& animation,
    const std::vector<std::shared_ptr<Node>>& scene_nodes) {
  auto result = std::shared_ptr<Animation>(new Animation());

  result->name_ = animation.name()->str();
  for (auto channel : *animation.channels()) {
    if (channel->node() < 0 ||
        static_cast<size_t>(channel->node()) >= scene_nodes.size() ||
        !channel->timeline()) {
      continue;
    }

    Animation::Channel out_channel;
    out_channel.bind_target.node_name = scene_nodes[channel->node()]->GetName();

    auto* times = channel->timeline();
    std::vector<Scalar> out_times;
    out_times.resize(channel->timeline()->size());
    std::copy(times->begin(), times->end(), out_times.begin());

    // TODO(bdero): Why are the entries in the keyframe value arrays not
    //              contiguous in the flatbuffer? We should be able to get rid
    //              of the subloops below and just memcpy instead.
    switch (channel->keyframes_type()) {
      case fb::Keyframes::TranslationKeyframes: {
        out_channel.bind_target.property = Animation::Property::kTranslation;
        auto* keyframes = channel->keyframes_as_TranslationKeyframes();
        if (!keyframes->values()) {
          continue;
        }
        std::vector<Vector3> out_values;
        out_values.resize(keyframes->values()->size());
        for (size_t value_i = 0; value_i < keyframes->values()->size();
             value_i++) {
          auto val = (*keyframes->values())[value_i];
          out_values[value_i] = Vector3(val->x(), val->y(), val->z());
        }
        out_channel.resolver = PropertyResolver::MakeTranslationTimeline(
            std::move(out_times), std::move(out_values));
        break;
      }
      case fb::Keyframes::RotationKeyframes: {
        out_channel.bind_target.property = Animation::Property::kRotation;
        auto* keyframes = channel->keyframes_as_RotationKeyframes();
        if (!keyframes->values()) {
          continue;
        }
        std::vector<Quaternion> out_values;
        out_values.resize(keyframes->values()->size());
        for (size_t value_i = 0; value_i < keyframes->values()->size();
             value_i++) {
          auto val = (*keyframes->values())[value_i];
          out_values[value_i] =
              Quaternion(val->x(), val->y(), val->z(), val->w());
        }
        out_channel.resolver = PropertyResolver::MakeRotationTimeline(
            std::move(out_times), std::move(out_values));
        break;
      }
      case fb::Keyframes::ScaleKeyframes: {
        out_channel.bind_target.property = Animation::Property::kScale;
        auto* keyframes = channel->keyframes_as_ScaleKeyframes();
        if (!keyframes->values()) {
          continue;
        }
        std::vector<Vector3> out_values;
        out_values.resize(keyframes->values()->size());
        for (size_t value_i = 0; value_i < keyframes->values()->size();
             value_i++) {
          auto val = (*keyframes->values())[value_i];
          out_values[value_i] = Vector3(val->x(), val->y(), val->z());
        }
        out_channel.resolver = PropertyResolver::MakeScaleTimeline(
            std::move(out_times), std::move(out_values));
        break;
      }
      case fb::Keyframes::NONE:
        continue;
    }

    result->end_time_ =
        std::max(result->end_time_, out_channel.resolver->GetEndTime());
    result->channels_.push_back(std::move(out_channel));
  }

  return result;
}

Animation::Animation() = default;

Animation::~Animation() = default;

const std::string& Animation::GetName() const {
  return name_;
}

const std::vector<Animation::Channel>& Animation::GetChannels() const {
  return channels_;
}

SecondsF Animation::GetEndTime() const {
  return end_time_;
}

}  // namespace scene
}  // namespace impeller
