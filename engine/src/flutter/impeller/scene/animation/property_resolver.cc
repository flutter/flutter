// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/animation/property_resolver.h"

#include <algorithm>
#include <iterator>
#include <memory>

#include "impeller/geometry/matrix_decomposition.h"
#include "impeller/geometry/point.h"
#include "impeller/scene/node.h"

namespace impeller {
namespace scene {

std::unique_ptr<TranslationTimelineResolver>
PropertyResolver::MakeTranslationTimeline(std::vector<Scalar> times,
                                          std::vector<Vector3> values) {
  FML_DCHECK(times.size() == values.size());
  auto result = std::unique_ptr<TranslationTimelineResolver>(
      new TranslationTimelineResolver());
  result->times_ = std::move(times);
  result->values_ = std::move(values);
  return result;
}

std::unique_ptr<RotationTimelineResolver>
PropertyResolver::MakeRotationTimeline(std::vector<Scalar> times,
                                       std::vector<Quaternion> values) {
  FML_DCHECK(times.size() == values.size());
  auto result =
      std::unique_ptr<RotationTimelineResolver>(new RotationTimelineResolver());
  result->times_ = std::move(times);
  result->values_ = std::move(values);
  return result;
}

std::unique_ptr<ScaleTimelineResolver> PropertyResolver::MakeScaleTimeline(
    std::vector<Scalar> times,
    std::vector<Vector3> values) {
  FML_DCHECK(times.size() == values.size());
  auto result =
      std::unique_ptr<ScaleTimelineResolver>(new ScaleTimelineResolver());
  result->times_ = std::move(times);
  result->values_ = std::move(values);
  return result;
}

PropertyResolver::~PropertyResolver() = default;

TimelineResolver::~TimelineResolver() = default;

SecondsF TimelineResolver::GetEndTime() {
  if (times_.empty()) {
    return SecondsF::zero();
  }
  return SecondsF(times_.back());
}

TimelineResolver::TimelineKey TimelineResolver::GetTimelineKey(SecondsF time) {
  if (times_.size() <= 1 || time.count() <= times_.front()) {
    return {.index = 0, .lerp = 1};
  }
  if (time.count() >= times_.back()) {
    return {.index = times_.size() - 1, .lerp = 1};
  }
  auto it = std::lower_bound(times_.begin(), times_.end(), time.count());
  size_t index = std::distance(times_.begin(), it);

  Scalar previous_time = *(it - 1);
  Scalar next_time = *it;
  return {.index = index,
          .lerp = (time.count() - previous_time) / (next_time - previous_time)};
}

TranslationTimelineResolver::TranslationTimelineResolver() = default;

TranslationTimelineResolver::~TranslationTimelineResolver() = default;

void TranslationTimelineResolver::Apply(AnimationTransforms& target,
                                        SecondsF time,
                                        Scalar weight) {
  if (values_.empty()) {
    return;
  }
  auto key = GetTimelineKey(time);
  auto value = values_[key.index];
  if (key.lerp < 1) {
    value = values_[key.index - 1].Lerp(value, key.lerp);
  }

  target.animated_pose.translation +=
      (value - target.bind_pose.translation) * weight;
}

RotationTimelineResolver::RotationTimelineResolver() = default;

RotationTimelineResolver::~RotationTimelineResolver() = default;

void RotationTimelineResolver::Apply(AnimationTransforms& target,
                                     SecondsF time,
                                     Scalar weight) {
  if (values_.empty()) {
    return;
  }
  auto key = GetTimelineKey(time);
  auto value = values_[key.index];
  if (key.lerp < 1) {
    value = values_[key.index - 1].Slerp(value, key.lerp);
  }

  target.animated_pose.rotation =
      target.animated_pose.rotation *
      Quaternion().Slerp(target.bind_pose.rotation.Invert() * value, weight);
}

ScaleTimelineResolver::ScaleTimelineResolver() = default;

ScaleTimelineResolver::~ScaleTimelineResolver() = default;

void ScaleTimelineResolver::Apply(AnimationTransforms& target,
                                  SecondsF time,
                                  Scalar weight) {
  if (values_.empty()) {
    return;
  }
  auto key = GetTimelineKey(time);
  auto value = values_[key.index];
  if (key.lerp < 1) {
    value = values_[key.index - 1].Lerp(value, key.lerp);
  }

  target.animated_pose.scale *=
      Vector3(1, 1, 1).Lerp(value / target.bind_pose.scale, weight);
}

}  // namespace scene
}  // namespace impeller
