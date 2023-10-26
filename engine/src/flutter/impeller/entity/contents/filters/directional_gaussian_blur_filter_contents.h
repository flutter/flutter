// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <optional>
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"

namespace impeller {

/// A gaussian blur filter that performs the work for one dimension of a
/// multi-dimensional Gaussian blur.
///
/// This filter takes a snapshot of its provided FilterInput, creates a new
/// render pass and blurs the contents. Two of these are chained together to
/// perform a full 2D blur effect.
///
/// Example:
///
///       Input             Pass 1
///  +-------------+        +-----+
///  |             |        |     |
///  |             |        |     |        Pass 2
///  |             |        |     |        +----+
///  |             |        |     |        |    |
///  |             |  ->    |     |  ->    |    |
///  |             |        |     |        |    |
///  |             |        |     |        +----+
///  |             |        |     |        87x102
///  +-------------+        +-----+
///     586x678             97x678
///
/// The math for determining how much of the input should be processed for a
/// given sigma (aka radius) is found in `Sigma::operator Radius`. The math for
/// determining how much to scale down the input based on the radius is inside
/// the curve function in this implementation.
///
/// See also:
///   - `FilterContents::MakeGaussianBlur`
///   - //flutter/impeller/entity/shaders/gaussian_blur/gaussian_blur.glsl
///
class DirectionalGaussianBlurFilterContents final : public FilterContents {
 public:
  DirectionalGaussianBlurFilterContents();

  ~DirectionalGaussianBlurFilterContents() override;

  /// Set sigma (stddev) used for 'direction_'.
  void SetSigma(Sigma sigma);

  /// Set sigma (stddev) used for direction 90 degrees from 'direction_'.
  /// Not used if `!is_second_pass_`.
  void SetSecondarySigma(Sigma sigma);

  void SetDirection(Vector2 direction);

  void SetBlurStyle(BlurStyle blur_style);

  void SetTileMode(Entity::TileMode tile_mode);

  /// Determines if this filter represents the second pass in a chained
  /// 2D gaussian blur.
  /// If `is_second_pass_ == true` then the `secondary_sigma_` is used to
  /// determine the blur radius in the 90 degree rotation of direction_. Its
  /// output aspect-ratio will closely match the FilterInput snapshot at the
  /// beginning of the chain.
  void SetIsSecondPass(bool is_second_pass);

  // |FilterContents|
  std::optional<Rect> GetFilterCoverage(
      const FilterInput::Vector& inputs,
      const Entity& entity,
      const Matrix& effect_transform) const override;

 private:
  // |FilterContents|
  std::optional<Entity> RenderFilter(
      const FilterInput::Vector& input_textures,
      const ContentContext& renderer,
      const Entity& entity,
      const Matrix& effect_transform,
      const Rect& coverage,
      const std::optional<Rect>& coverage_hint) const override;
  Sigma blur_sigma_;
  Sigma secondary_blur_sigma_;
  Vector2 blur_direction_;
  BlurStyle blur_style_ = BlurStyle::kNormal;
  Entity::TileMode tile_mode_ = Entity::TileMode::kDecal;
  bool is_second_pass_ = false;

  DirectionalGaussianBlurFilterContents(
      const DirectionalGaussianBlurFilterContents&) = delete;

  DirectionalGaussianBlurFilterContents& operator=(
      const DirectionalGaussianBlurFilterContents&) = delete;
};

}  // namespace impeller
