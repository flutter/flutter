// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <optional>
#include "impeller/entity/contents/filters/filter_contents.h"

namespace impeller {

/// Performs a bidirectional Gaussian blur.
///
/// This is accomplished by rendering multiple passes in multiple directions.
/// Note: This will replace `DirectionalGaussianBlurFilterContents`.
class GaussianBlurFilterContents final : public FilterContents {
 public:
  explicit GaussianBlurFilterContents(Scalar sigma = 0.0f);

  Scalar GetSigma() const { return sigma_; }

  // |FilterContents|
  std::optional<Rect> GetFilterSourceCoverage(
      const Matrix& effect_transform,
      const Rect& output_limit) const override;

  // |FilterContents|
  std::optional<Rect> GetFilterCoverage(
      const FilterInput::Vector& inputs,
      const Entity& entity,
      const Matrix& effect_transform) const override;

  /// Given a sigma (standard deviation) calculate the blur radius (1/2 the
  /// kernel size).
  static Scalar CalculateBlurRadius(Scalar sigma);

  /// Calculate the UV coordinates for rendering the filter_input.
  /// @param filter_input The FilterInput that should be rendered.
  /// @param entity The associated entity for the filter_input.
  /// @param texture_size The size of the texture_size the uvs will be used for.
  static Quad CalculateUVs(const std::shared_ptr<FilterInput>& filter_input,
                           const Entity& entity,
                           const ISize& pass_size);

 private:
  // |FilterContents|
  std::optional<Entity> RenderFilter(
      const FilterInput::Vector& input_textures,
      const ContentContext& renderer,
      const Entity& entity,
      const Matrix& effect_transform,
      const Rect& coverage,
      const std::optional<Rect>& coverage_hint) const override;

  const Scalar sigma_ = 0.0;
};

}  // namespace impeller
