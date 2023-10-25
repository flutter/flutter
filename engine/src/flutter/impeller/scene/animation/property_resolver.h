// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <string>
#include <vector>

#include "flutter/fml/hash_combine.h"
#include "flutter/fml/macros.h"
#include "impeller/base/timing.h"
#include "impeller/geometry/matrix_decomposition.h"
#include "impeller/geometry/quaternion.h"
#include "impeller/geometry/scalar.h"
#include "impeller/geometry/vector.h"
#include "impeller/scene/animation/animation_transforms.h"

namespace impeller {
namespace scene {

class Node;
class TranslationTimelineResolver;
class RotationTimelineResolver;
class ScaleTimelineResolver;

class PropertyResolver {
 public:
  static std::unique_ptr<TranslationTimelineResolver> MakeTranslationTimeline(
      std::vector<Scalar> times,
      std::vector<Vector3> values);

  static std::unique_ptr<RotationTimelineResolver> MakeRotationTimeline(
      std::vector<Scalar> times,
      std::vector<Quaternion> values);

  static std::unique_ptr<ScaleTimelineResolver> MakeScaleTimeline(
      std::vector<Scalar> times,
      std::vector<Vector3> values);

  virtual ~PropertyResolver();

  virtual SecondsF GetEndTime() = 0;

  /// @brief  Resolve and apply the property value to a target node. This
  ///         operation is additive; a given node property may be amended by
  ///         many different PropertyResolvers prior to rendering. For example,
  ///         an AnimationPlayer may blend multiple Animations together by
  ///         applying several AnimationClips.
  virtual void Apply(AnimationTransforms& target,
                     SecondsF time,
                     Scalar weight) = 0;
};

class TimelineResolver : public PropertyResolver {
 public:
  virtual ~TimelineResolver();

  // |Resolver|
  SecondsF GetEndTime();

 protected:
  struct TimelineKey {
    /// The index of the closest previous keyframe.
    size_t index = 0;
    /// Used to interpolate between the resolved values for `timeline_index - 1`
    /// and `timeline_index`. The range of this value should always be `0>N>=1`.
    Scalar lerp = 1;
  };
  TimelineKey GetTimelineKey(SecondsF time);

  std::vector<Scalar> times_;
};

class TranslationTimelineResolver final : public TimelineResolver {
 public:
  ~TranslationTimelineResolver();

  // |Resolver|
  void Apply(AnimationTransforms& target,
             SecondsF time,
             Scalar weight) override;

 private:
  TranslationTimelineResolver();

  std::vector<Vector3> values_;

  TranslationTimelineResolver(const TranslationTimelineResolver&) = delete;

  TranslationTimelineResolver& operator=(const TranslationTimelineResolver&) =
      delete;

  friend PropertyResolver;
};

class RotationTimelineResolver final : public TimelineResolver {
 public:
  ~RotationTimelineResolver();

  // |Resolver|
  void Apply(AnimationTransforms& target,
             SecondsF time,
             Scalar weight) override;

 private:
  RotationTimelineResolver();

  std::vector<Quaternion> values_;

  RotationTimelineResolver(const RotationTimelineResolver&) = delete;

  RotationTimelineResolver& operator=(const RotationTimelineResolver&) = delete;

  friend PropertyResolver;
};

class ScaleTimelineResolver final : public TimelineResolver {
 public:
  ~ScaleTimelineResolver();

  // |Resolver|
  void Apply(AnimationTransforms& target,
             SecondsF time,
             Scalar weight) override;

 private:
  ScaleTimelineResolver();

  std::vector<Vector3> values_;

  ScaleTimelineResolver(const ScaleTimelineResolver&) = delete;

  ScaleTimelineResolver& operator=(const ScaleTimelineResolver&) = delete;

  friend PropertyResolver;
};

}  // namespace scene
}  // namespace impeller
